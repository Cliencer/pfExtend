# questGaindb — 任务奖励数据抓取工作目录

从 [OctoWow Database](https://octowow.st/db/) 批量抓取任务奖励数据（固定奖励物品、
自选奖励物品、经验值），生成 pfExtend 插件的数据文件 `rewards_data.lua`。

## 使用方法

```bash
# 完整流程（约 110 次请求，几分钟完成）
python scrape.py all

# 或分步执行
python scrape.py catalog   # 阶段A: 分类菜单 + 分类列表页 -> catalog.json
python scrape.py build     # 汇总 -> rewards_data.lua

# 可选: 逐任务抓详情页，补充满级折算金钱(mml)字段 —— 非必需，约7000次请求
python scrape.py rewards              # 断点续传，可反复运行直到完成
python scrape.py rewards --limit 50   # 调试用，本轮只抓50个
python scrape.py rewards --ids 41677,41983
```

依赖: Python 3.8+（仅标准库）与 `curl`（Windows 10+ 自带 `curl.exe`，Git Bash 自带）。

> 为什么用 curl 而不是 requests：站点的 BlazingFast 防护按 TLS 指纹识别客户端，
> Python requests 的每次请求都会被重新挑战（实测），curl 通过挑战后按 IP+Cookie 放行。

## 数据来源与原理

站点使用 aowow 结构。任务分类列表页 `?quests=<父分类>.<子分类>` 一次返回该分类
全部任务的内嵌 Listview 数据，字段包括 `id, name, level, reqlevel, side, xp,
category, itemrewards, itemchoices` —— 奖励与经验无需逐任务抓取。

- 分类树来自 `templates/wowhead/js/locale_enus.js` 的 `mn_quests` 变量；
- `?quests=-44` 为乌龟服自定义任务全集；
- 经验值采用列表 `xp` 字段（与详情页 Gains 展示值一致；详情页 Quick Facts 的
  `RewXP` 字段与展示值有偏差，不采用）；
- 站点前置 BlazingFast DDoS 挑战（算术题），脚本自动完成并维持 7 天有效的
  通行 Cookie（`cookies.txt`），过期自动重新挑战。

## 目录结构

```
scrape.py            抓取脚本
cookies.txt          BlazingFast 通行 Cookie（自动生成）
catalog.json         全部任务目录（ID/名称/等级/阵营/经验/奖励物品）
cache/categories/    每个分类列表页的解析结果（删了会重抓）
cache/quests/        阶段B任务详情页解析结果（可选）
cache/html/          阶段B任务详情页原始HTML（可选，便于离线重解析）
rewards_data.lua     最终产物：pfExtend 任务奖励数据文件
```

## 输出格式（rewards_data.lua）

```lua
PfExtend_QuestRewards = {
    [451] = { xp = 210, reward = { 2458, 2459 }, choice = { 3451, 3582 } },
    [60142] = { xp = 2920, choice = { { 3239, 2 }, { 2862, 2 } } },  -- {ID, 数量}
}
```

物品数量为 1 时写裸 ID，大于 1 时写 `{ ID, 数量 }`。

## 维护

Turtle WoW 更新导致任务数据变化后，重新运行 `python scrape.py all` 即可；
分类缓存可加 `--force` 强制重抓。个别错误条目可在插件的 `dbOverwrite.lua`
中手工修正，无需重新全量抓取。
