#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
OctoWow (octowow.st/db) 任务奖励数据抓取脚本 —— pfExtend 插件数据生成器

用法:
    python scrape.py catalog            阶段A: 抓分类菜单 + 分类列表页 -> catalog.json
                                        (任务ID/名称/等级/阵营/经验/固定奖励物品/自选奖励物品)
    python scrape.py build              汇总 catalog.json -> rewards_data.lua (pfExtend 数据文件)
    python scrape.py all                catalog + build  (完整流程, 约110次请求)
    python scrape.py rewards [--limit N] [--ids 1,2,3]
                                        (可选) 阶段B: 逐任务抓详情页补充满级折算金钱(mml)
                                        -> cache/quests/<id>.json (断点续传)

说明: 分类列表页本身已包含经验(xp)与物品奖励(itemrewards/itemchoices),
      且 xp 与详情页 Gains 展示值一致, 因此阶段B不是必须的;
      详情页 Quick Facts 的 RewXP 字段与展示值存在偏差, 不采用。

工作目录结构:
    questGaindb/
      scrape.py            本脚本
      cookies.txt          BlazingFast 通行 Cookie (7天有效, 过期自动重新挑战)
      catalog.json         阶段A产物: 全部任务目录 {id: {name,level,reqlevel,side,xp,category,...}}
      cache/
        categories/        每个分类列表页解析结果 <parent>_<child>.json
        quests/            每个任务页解析结果 <id>.json
        html/              任务页原始HTML <id>.html (便于离线重解析)
      rewards_data.lua     最终产物: pfExtend 任务奖励数据文件
"""

import argparse
import json
import os
import random
import re
import subprocess
import sys
import time

BASE = "https://octowow.st/db/"
SITE = "https://octowow.st/"   # 挑战相关资源在站点根路径
UA = ("Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 "
      "(KHTML, like Gecko) Chrome/120.0 Safari/537.36")

WORKDIR = os.path.dirname(os.path.abspath(__file__))
COOKIE_FILE = os.path.join(WORKDIR, "cookies.txt")
CATALOG_FILE = os.path.join(WORKDIR, "catalog.json")
LUA_FILE = os.path.join(WORKDIR, "rewards_data.lua")
DIR_CATEGORIES = os.path.join(WORKDIR, "cache", "categories")
DIR_QUESTS = os.path.join(WORKDIR, "cache", "quests")
DIR_HTML = os.path.join(WORKDIR, "cache", "html")

MIN_INTERVAL = 1.0   # 请求最小间隔(秒)
JITTER = 0.5         # 随机抖动上限(秒)
MAX_RETRIES = 5      # 单请求最大重试次数


# ---------------------------------------------------------------- 站点会话

def _find_curl():
    for cand in ("curl", "curl.exe"):
        try:
            subprocess.run([cand, "--version"], capture_output=True, check=True)
            return cand
        except (OSError, subprocess.CalledProcessError):
            continue
    sys.exit("未找到 curl。请安装 curl 或在含 curl 的环境中运行 "
             "(Windows 10+ 自带 curl.exe, Git Bash 自带 curl)")

CURL = _find_curl()


class Resp:
    def __init__(self, status, text):
        self.status_code = status
        self.text = text


class OctoSession:
    """基于 curl 子进程的 HTTP 会话。

    为什么不用 requests: BlazingFast 防护按 TLS 指纹识别客户端,
    Python requests 的每次请求都会被重新挑战(实测), 而 curl 通过挑战后
    服务端会按 IP+Cookie 放行。因此全部流量经 curl 收发。
    Cookie 以 Netscape 格式存于 cookies.txt, 7 天有效。
    """

    def __init__(self):
        self.last_request = 0.0

    def has_clearance(self):
        if not os.path.exists(COOKIE_FILE):
            return False
        with open(COOKIE_FILE, encoding="utf-8", errors="replace") as f:
            return "__bf_clearance_v2" in f.read()

    def _curl(self, args):
        return subprocess.run(
            [CURL, "-s", "--compressed", "--max-time", "40",
             "-b", COOKIE_FILE, "-c", COOKIE_FILE, "-A", UA] + args,
            capture_output=True)

    def _curl_body(self, args):
        p = self._curl(args)
        if p.returncode != 0:
            raise RuntimeError("curl 退出码 %d: %s"
                               % (p.returncode, p.stderr.decode("utf-8", "replace")[:200]))
        return p.stdout.decode("utf-8", "replace")

    @staticmethod
    def _solve_expr(expr):
        """计算挑战算术表达式, 已观测格式: a+b*c (乘法优先)"""
        m = re.fullmatch(r"\s*(\d+)\s*\+\s*(\d+)\s*\*\s*(\d+)\s*", expr)
        if m:
            a, b, c = (int(x) for x in m.groups())
            return a + b * c
        m = re.fullmatch(r"\s*(\d+)\s*\*\s*(\d+)\s*\+\s*(\d+)\s*", expr)
        if m:
            a, b, c = (int(x) for x in m.groups())
            return a * b + c
        raise ValueError("未知挑战表达式: %r" % expr)

    def solve_challenge(self, html, referer):
        chal = re.search(r'name="bf_challenge" value="([0-9a-f]{64})"', html).group(1)
        bfu = re.search(r'name="bfu" value="([^"]*)"', html).group(1)
        expr = re.search(r'bf-v2-answer"\)\.value=([^;]+)', html).group(1)
        answer = self._solve_expr(expr)
        # 服务端要求先拉取挑战脚本资源(站点根路径), 否则 409 challenge_asset_missing
        self._curl(["-e", referer, SITE + "bf.jquery.max.js?bf_challenge=" + chal,
                    "-o", os.devnull])
        time.sleep(6)  # 官方页面本身延迟5.1秒提交, 必须模仿
        self._curl(["-e", referer, "-X", "POST", SITE + "blzgfst-shark/",
                    "--data-urlencode", "bf_challenge=" + chal,
                    "--data-urlencode", "bfu=" + bfu,
                    "--data-urlencode", "blazing_answer=" + str(answer),
                    "-o", os.devnull])
        if not self.has_clearance():
            raise RuntimeError("挑战失败, 未获得通行 Cookie")
        print("[challenge] 已通过 BlazingFast 挑战")

    def get(self, url):
        """限速 + 挑战重试的 GET, 返回 Resp"""
        for attempt in range(MAX_RETRIES):
            wait = MIN_INTERVAL + random.random() * JITTER - (time.time() - self.last_request)
            if wait > 0:
                time.sleep(wait)
            self.last_request = time.time()
            try:
                out = self._curl_body(["-L", "-w", "\n%{http_code}", url])
                body, _, code = out.rpartition("\n")
                status = int(code)
            except (RuntimeError, ValueError) as e:
                print("[net] %s (第%d次)" % (e, attempt + 1))
                time.sleep(min(120, 5 * 2 ** attempt))
                continue
            if 'name="bf_challenge"' in body:
                self.solve_challenge(body, url)
                continue
            if status == 200:
                return Resp(200, body)
            print("[http] %s -> %d (第%d次)" % (url, status, attempt + 1))
            time.sleep(min(120, 5 * 2 ** attempt))
        raise RuntimeError("请求失败(重试%d次): %s" % (MAX_RETRIES, url))


# ---------------------------------------------------------------- 阶段A: 目录

def parse_menu(js_text):
    """解析 locale_enus.js 中的 mn_quests 分类树
    返回 [(parent_id, parent_name, [(child_id, child_name), ...] or None), ...]"""
    i = js_text.find("var mn_quests")
    if i < 0:
        raise ValueError("未找到 mn_quests")
    start = js_text.index("[", i)
    depth, end = 0, start
    for end in range(start, len(js_text)):
        if js_text[end] == "[":
            depth += 1
        elif js_text[end] == "]":
            depth -= 1
            if depth == 0:
                break
    body = js_text[start + 1:end]  # 根数组内部

    # 按深度0处的逗号切分顶层条目 (嵌套数组内的逗号不受影响)
    entries, depth, last = [], 0, 0
    for idx, c in enumerate(body):
        if c == "[":
            depth += 1
        elif c == "]":
            depth -= 1
        elif c == "," and depth == 0:
            entries.append(body[last:idx])
            last = idx + 1
    entries.append(body[last:])

    head_re = re.compile(r'\[\s*(-?\d+)\s*,\s*"([^"]+)"')
    pair_re = re.compile(r'\[\s*(-?\d+)\s*,\s*"([^"]+)"\s*\]')
    menu = []
    for e in entries:
        e = e.strip()
        if not e:
            continue
        h = head_re.search(e)
        if not h:
            continue
        children = [(int(a), b) for a, b in pair_re.findall(e[h.end():])]
        menu.append((int(h.group(1)), h.group(2), children if children else None))
    return menu


ENTRY_RE = re.compile(r"\{id:\s*'(\d+)',([^{}]*)\}")
FIELD_RES = {
    "name": re.compile(r"name:\s*'((?:[^'\\]|\\.)*)'"),
    "level": re.compile(r"level:\s*'(\d+)'"),
    "reqlevel": re.compile(r"reqlevel:(\d+)"),
    "side": re.compile(r"side:\s*'(\d+)'"),
    "xp": re.compile(r"xp:(-?\d+)"),
    "category": re.compile(r"category:(-?\d+)"),
    "category2": re.compile(r"category2:(-?\d+)"),
    "type": re.compile(r"type:(-?\d+)"),
}
ITEMS_RE = re.compile(r"item(rewards|choices):(\[\[[0-9,\[\]]*\]\])")
PAIR_RE = re.compile(r"\[(\d+),(\d+)\]")


def parse_quest_list(html):
    """解析分类列表页内嵌 Listview 数据 (含可选的 itemrewards/itemchoices 字段)"""
    out = []
    for m in ENTRY_RE.finditer(html):
        body = m.group(2)
        q = {"id": int(m.group(1))}
        for key, pat in FIELD_RES.items():
            mm = pat.search(body)
            if not mm:
                continue
            v = mm.group(1)
            if key == "name":
                q[key] = v.replace("\\'", "'").replace("\\\\", "\\").strip()
            else:
                q[key] = int(v)
        for kind, arr in ITEMS_RE.findall(body):
            items = [[int(a), int(b)] for a, b in PAIR_RE.findall(arr)]
            if items:
                q["reward" if kind == "rewards" else "choice"] = items
        out.append(q)
    return out


def cmd_catalog(sess, force=False):
    os.makedirs(DIR_CATEGORIES, exist_ok=True)
    r = sess.get(BASE + "templates/wowhead/js/locale_enus.js")
    menu = parse_menu(r.text)

    jobs = []  # (cache_name, url, desc)
    for pid, pname, children in menu:
        if children is None:
            jobs.append(("%d" % pid, "%s?quests=%d" % (BASE, pid),
                         "%d %s" % (pid, pname)))
        else:
            for cid, cname in children:
                jobs.append(("%d_%d" % (pid, cid), "%s?quests=%d.%d" % (BASE, pid, cid),
                             "%d.%d %s/%s" % (pid, cid, pname, cname)))

    catalog = {}
    done = skipped = 0
    for idx, (cache_name, url, desc) in enumerate(jobs, 1):
        cache_path = os.path.join(DIR_CATEGORIES, cache_name + ".json")
        if os.path.exists(cache_path) and not force:
            quests = json.load(open(cache_path, encoding="utf-8"))
            skipped += 1
        else:
            r = sess.get(url)
            quests = parse_quest_list(r.text)
            json.dump(quests, open(cache_path, "w", encoding="utf-8"),
                      ensure_ascii=False, indent=1)
            print("[catalog] (%d/%d) %s -> %d 个任务" % (idx, len(jobs), desc, len(quests)))
            done += 1
        for q in quests:
            catalog.setdefault(q["id"], q)

    json.dump(catalog, open(CATALOG_FILE, "w", encoding="utf-8"),
              ensure_ascii=False, indent=1, sort_keys=True)
    print("[catalog] 完成: 新抓 %d 个分类, 复用缓存 %d 个, 目录共 %d 个任务"
          % (done, skipped, len(catalog)))
    return catalog


# ---------------------------------------------------------------- 阶段B: 奖励

REWARD_SECTION_RE = re.compile(r"<h3>Reward</h3>(.*?)(?=<h3>|<h2>)", re.S)
PAGEINFO_RE = re.compile(r"g_pageInfo\s*=\s*\{type:\s*(\d+),\s*typeId:\s*(\d+)")
ITEM_LINK_RE = re.compile(r"\?item=(\d+)")
MONEY_TEXT_RE = re.compile(r"also receive[^0-9]*([\d,]+)\s*(Gold|Silver|Copper)", re.I)


def _extract_items(segment):
    return [int(x) for x in ITEM_LINK_RE.findall(segment)]


def parse_quest_page(html, quest_id):
    """解析任务详情页 -> dict (验证失败返回 None)"""
    m = PAGEINFO_RE.search(html)
    if not m or int(m.group(2)) != quest_id:
        return None
    info = {"id": quest_id}

    m = re.search(r"RewXP:\s*(\d+)", html)
    if m:
        info["xp"] = int(m.group(1))
    m = re.search(r"RewMoneyMaxLevel:\s*(\d+)", html)
    if m:
        info["mml"] = int(m.group(1))

    sec = REWARD_SECTION_RE.search(html)
    if sec:
        body = sec.group(1)
        # 标记点: 固定奖励 / 自选奖励 / 法术奖励
        marks = []
        for label, pat in (("reward", r"You will receive"),
                           ("choice", r"choose one of these awards"),
                           ("spell", r"The following spell")):
            mm = re.search(pat, body)
            if mm:
                marks.append((mm.start(), label))
        marks.sort()
        for i, (pos, label) in enumerate(marks):
            if label == "spell":
                continue
            end = marks[i + 1][0] if i + 1 < len(marks) else len(body)
            items = _extract_items(body[pos:end])
            if items:
                info[label] = items
    return info


def cmd_rewards(sess, limit=None, ids=None):
    os.makedirs(DIR_QUESTS, exist_ok=True)
    os.makedirs(DIR_HTML, exist_ok=True)
    if ids:
        queue = ids
    else:
        if not os.path.exists(CATALOG_FILE):
            sys.exit("缺少 catalog.json, 请先运行: python scrape.py catalog")
        catalog = json.load(open(CATALOG_FILE, encoding="utf-8"))
        queue = sorted(int(qid) for qid in catalog.keys())

    todo = [qid for qid in queue
            if not os.path.exists(os.path.join(DIR_QUESTS, "%d.json" % qid))]
    if limit:
        todo = todo[:limit]
    print("[rewards] 待抓取 %d 个任务 (已完成 %d 个)" % (len(todo), len(queue) - len(todo)))

    consecutive_fail = 0
    for idx, qid in enumerate(todo, 1):
        url = "%s?quest=%d" % (BASE, qid)
        try:
            r = sess.get(url)
        except RuntimeError as e:
            print("[rewards] %s" % e)
            consecutive_fail += 1
            if consecutive_fail >= 5:
                sys.exit("连续失败5次, 中止 (可重新运行续传)")
            continue

        info = parse_quest_page(r.text, qid)
        if info is None:
            info = {"id": qid, "missing": True}
            print("[rewards] (%d/%d) 任务 %d 页面无效, 标记 missing" % (idx, len(todo), qid))
        json.dump(info, open(os.path.join(DIR_QUESTS, "%d.json" % qid), "w",
                             encoding="utf-8"), ensure_ascii=False)
        with open(os.path.join(DIR_HTML, "%d.html" % qid), "w", encoding="utf-8") as f:
            f.write(r.text)
        consecutive_fail = 0
        if idx % 25 == 0 or idx == len(todo):
            print("[rewards] 进度 %d/%d (最近: %d)" % (idx, len(todo), qid))
    print("[rewards] 本轮完成")


# ---------------------------------------------------------------- 汇总输出

def _fmt_items(items):
    """[[id,count],...] -> Lua 片段; count为1时写裸ID以压缩体积"""
    parts = []
    for iid, count in items:
        parts.append(str(iid) if count == 1 else "{ %d, %d }" % (iid, count))
    return "{ %s }" % ", ".join(parts)


def cmd_build():
    if not os.path.exists(CATALOG_FILE):
        sys.exit("缺少 catalog.json, 请先运行: python scrape.py catalog")
    catalog = json.load(open(CATALOG_FILE, encoding="utf-8"))

    entries = {}
    stats = {"total": 0, "with_reward": 0, "with_choice": 0, "with_xp": 0,
             "with_mml": 0}
    for qid_str, q in catalog.items():
        qid = int(qid_str)
        stats["total"] += 1
        entry = {}
        if q.get("xp"):
            entry["xp"] = q["xp"]
            stats["with_xp"] += 1
        if q.get("reward"):
            entry["reward"] = q["reward"]
            stats["with_reward"] += 1
        if q.get("choice"):
            entry["choice"] = q["choice"]
            stats["with_choice"] += 1
        # 可选: 阶段B详情页缓存中的满级折算金钱
        page_path = os.path.join(DIR_QUESTS, "%d.json" % qid)
        if os.path.exists(page_path):
            page = json.load(open(page_path, encoding="utf-8"))
            if page.get("mml"):
                entry["mml"] = page["mml"]
                stats["with_mml"] += 1
        if entry:
            entries[qid] = entry

    lines = [
        "-- pfExtend 任务奖励数据 (物品奖励/经验)",
        "-- 数据来源: https://octowow.st/db/ (分类列表页批量抓取)",
        "-- 生成时间: %s" % time.strftime("%Y-%m-%d %H:%M:%S"),
        "-- 任务数: %d (含固定奖励 %d, 含自选奖励 %d, 含经验 %d)"
        % (len(entries), stats["with_reward"], stats["with_choice"], stats["with_xp"]),
        "-- 物品格式: 单数量写裸ID, 多数量写 { ID, 数量 }",
        "PfExtend_QuestRewards = {",
    ]
    for qid in sorted(entries):
        e = entries[qid]
        parts = []
        if "xp" in e:
            parts.append("xp = %d" % e["xp"])
        if "reward" in e:
            parts.append("reward = %s" % _fmt_items(e["reward"]))
        if "choice" in e:
            parts.append("choice = %s" % _fmt_items(e["choice"]))
        if "mml" in e:
            parts.append("mml = %d" % e["mml"])
        lines.append("    [%d] = { %s }," % (qid, ", ".join(parts)))
    lines.append("}")
    with open(LUA_FILE, "w", encoding="utf-8") as f:
        f.write("\n".join(lines) + "\n")

    print("[build] %s 已生成: %d 条数据, %.1f KB" %
          (LUA_FILE, len(entries), os.path.getsize(LUA_FILE) / 1024))
    print("[build] 统计: 目录 %d, 含固定奖励 %d, 含自选奖励 %d, 含经验 %d, 含满级金钱 %d"
          % (stats["total"], stats["with_reward"], stats["with_choice"],
             stats["with_xp"], stats["with_mml"]))

    # 同步到插件目录 (pfExtend 通过 init/modules.xml 加载)
    deploy = os.path.join(WORKDIR, "..", "modules", "QuestHelper", "rewards_data.lua")
    try:
        import shutil
        shutil.copyfile(LUA_FILE, deploy)
        print("[build] 已同步到插件: %s" % os.path.abspath(deploy))
    except OSError as e:
        print("[build] 同步到插件目录失败: %s" % e)


# ---------------------------------------------------------------- 入口

def main():
    ap = argparse.ArgumentParser(description="OctoWow 任务奖励抓取")
    ap.add_argument("cmd", choices=["catalog", "rewards", "build", "all"])
    ap.add_argument("--limit", type=int, default=None, help="阶段B本轮最多抓取数(调试用)")
    ap.add_argument("--ids", type=str, default=None, help="只抓指定任务ID, 逗号分隔")
    ap.add_argument("--force", action="store_true", help="忽略缓存强制重抓(阶段A)")
    args = ap.parse_args()

    sess = OctoSession()
    if args.cmd in ("catalog", "all"):
        cmd_catalog(sess, force=args.force)
    if args.cmd == "rewards":
        ids = [int(x) for x in args.ids.split(",")] if args.ids else None
        cmd_rewards(sess, limit=args.limit, ids=ids)
    if args.cmd in ("build", "all"):
        cmd_build()


if __name__ == "__main__":
    main()
