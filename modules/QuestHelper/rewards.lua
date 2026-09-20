-- 任务奖励 tooltip 注入：在 pfQuest 的任务扩展 tooltip 之后追加
-- 经验 / 满级金钱 / 物品奖励信息
-- 数据来源：questGaindb/rewards_data.lua (PfExtend_QuestRewards)

local compat = pfExtendCompat

-- 金钱(铜) -> "x金 y银 z铜"
local function FormatMoney(copper)
    local gold = math.floor(copper / 10000)
    local silver = math.floor(compat.mod(copper, 10000) / 100)
    local cop = compat.mod(copper, 100)
    local parts = {}
    if gold > 0 then table.insert(parts, gold .. pfExtend_Loc["QuestHelper_Gold"]) end
    if silver > 0 then table.insert(parts, silver .. pfExtend_Loc["QuestHelper_Silver"]) end
    if cop > 0 then table.insert(parts, cop .. pfExtend_Loc["QuestHelper_Copper"]) end
    return table.concat(parts, " ")
end

-- 物品ID -> 带品质颜色的物品链接文本 (复用ShowLoots的品质缓存与回退逻辑)
local function GetItemLinkText(itemid)
    local quality = PfExtend_Database["ShowLoots"]["itemQualityData"][itemid]
    if quality == nil then
        local _, _, iq = GetItemInfo(itemid)
        quality = iq
        if type(quality) == "number" then
            PfExtend_Database["ShowLoots"]["itemQualityData"][itemid] = quality
        end
    end
    local name = pfDB.items.loc[itemid] or ("item:" .. itemid)
    if type(quality) == "number" then
        local color = "|c" .. string.format("%02x%02x%02x%02x", 255,
            math.floor(ITEM_QUALITY_COLORS[quality].r * 255),
            math.floor(ITEM_QUALITY_COLORS[quality].g * 255),
            math.floor(ITEM_QUALITY_COLORS[quality].b * 255))
        return color .. "|Hitem:" .. itemid .. compat.itemsuffix .. "|h[" .. name .. "]|h|r"
    end
    return "[" .. name .. "]"
end

local function AddItemLines(tooltip, items, header)
    tooltip:AddLine(header, 1, 0.82, 0)
    for _, entry in ipairs(items) do
        local itemid, count
        if type(entry) == "table" then
            itemid, count = entry[1], entry[2]
        else
            itemid, count = entry, 1
        end
        local text = "  " .. GetItemLinkText(itemid)
        if count and count > 1 then
            text = text .. " |cff555555x" .. count .. "|r"
        end
        tooltip:AddLine(text)
    end
end

PFEXQuestHelper.AppendRewards = function(tooltip, questid)
    if not PfExtend_Global.ReadSetting("QuestHelper", "enable") then return end
    if not PfExtend_Global.ReadSetting("QuestHelper", "showRewards") then return end
    local data = PfExtend_QuestRewards and PfExtend_QuestRewards[questid]
    if not data then return end

    local added = false
    if data.xp and data.xp > 0 then
        tooltip:AddLine(" ", 0.55, 0.55, 0.55)
        tooltip:AddLine(string.format(pfExtend_Loc["QuestHelper_RewardXP"], data.xp), 1, 1, 1)
        added = true
    end
    if data.mml and data.mml > 0 then
        if not added then tooltip:AddLine(" ", 0.55, 0.55, 0.55) end
        tooltip:AddLine(string.format(pfExtend_Loc["QuestHelper_RewardMoney"], FormatMoney(data.mml)), 1, 1, 1)
        added = true
    end
    if data.reward then
        AddItemLines(tooltip, data.reward, pfExtend_Loc["QuestHelper_RewardItems"])
        added = true
    end
    if data.choice then
        AddItemLines(tooltip, data.choice, pfExtend_Loc["QuestHelper_RewardChoice"])
        added = true
    end
    if added then
        tooltip:Show() -- 追加行后触发布局重算
    end
end

-- hook pfQuest 的任务扩展 tooltip (QuestHelper浏览器/任务链窗口/pfQuest自身均走此函数)
local pfExHook_ShowExtendedTooltip = pfDatabase.ShowExtendedTooltip
pfDatabase.ShowExtendedTooltip = function(self, id, tooltip, parent, anchor, x, y)
    pfExHook_ShowExtendedTooltip(self, id, tooltip, parent, anchor, x, y)
    if tooltip and id then
        PFEXQuestHelper.AppendRewards(tooltip, id)
    end
end
