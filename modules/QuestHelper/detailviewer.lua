-- 任务详情查看窗口：右键点击任务(任务助手浏览器/任务链窗口)后打开，
-- 显示任务目标、描述文本与奖励(经验/金钱/物品图标)
-- 文本数据来自 pfDB.quests.loc (T标题/O目标/D描述)，奖励来自 PfExtend_QuestRewards

local compat = pfExtendCompat

local ICON_SIZE = 30
local ROW_HEIGHT = 36
local CONTENT_WIDTH = 300
local GOLD = { 1, 0.82, 0 }
local WHITE = { 1, 1, 1 }
local GRAY = { 0.75, 0.75, 0.75 }
local GREEN = { 0.25, 1, 0.25 }

-- ============================================================
-- 窗口框架
-- ============================================================
local frame = CreateFrame("Frame", "PFEXQuestDetailFrame", UIParent)
frame:Hide()
frame:SetWidth(340)
frame:SetHeight(480)
frame:SetPoint("CENTER", 0, 0)
frame:SetFrameStrata("FULLSCREEN_DIALOG")
frame:SetToplevel(true)
frame:SetClampedToScreen(true)
frame:SetMovable(true)
frame:EnableMouse(true)
pfUI.api.CreateBackdrop(frame, nil, true, 0.85)
table.insert(UISpecialFrames, "PFEXQuestDetailFrame") -- Esc关闭

frame:SetScript("OnMouseDown", function() this:StartMoving() end)
frame:SetScript("OnMouseUp", function() this:StopMovingOrSizing() end)

frame.title = frame:CreateFontString("Status", "LOW", "GameFontNormal")
frame.title:SetFontObject(GameFontWhite)
frame.title:SetPoint("TOP", frame, "TOP", 0, -10)
frame.title:SetJustifyH("LEFT")
frame.title:SetFont(pfUI.font_default, 15)
frame.title:SetWidth(280)

frame.close = CreateFrame("Button", "PFEXQuestDetailFrameClose", frame)
frame.close:SetPoint("TOPRIGHT", -5, -5)
frame.close:SetHeight(20)
frame.close:SetWidth(20)
frame.close.texture = frame.close:CreateTexture("PFEXQuestDetailFrameCloseTex")
frame.close.texture:SetTexture(pfExtend_Path .. "\\compat\\close")
frame.close.texture:ClearAllPoints()
frame.close.texture:SetVertexColor(1, .25, .25, 1)
frame.close.texture:SetPoint("TOPLEFT", frame.close, "TOPLEFT", 4, -4)
frame.close.texture:SetPoint("BOTTOMRIGHT", frame.close, "BOTTOMRIGHT", -4, 4)
frame.close:SetScript("OnClick", function()
    this:GetParent():Hide()
end)
pfUI.api.SkinButton(frame.close, 1, .5, .5)

frame.scroll = pfUI.api.CreateScrollFrame("PFEXQuestDetailFrameScroll", frame)
frame.scroll:SetPoint("TOPLEFT", frame, "TOPLEFT", 12, -36)
frame.scroll:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -12, 12)
frame.scroll:Show()

frame.content = pfUI.api.CreateScrollChild("PFEXQuestDetailFrameScrollChild", frame.scroll)
frame.content:SetWidth(CONTENT_WIDTH)
frame.content:SetHeight(1)

-- ============================================================
-- 控件池 (文本行 / 物品图标行)
-- ============================================================
local textPool = {}
local iconPool = {}

local function GetTextRow(index)
    if textPool[index] then return textPool[index] end
    local fs = frame.content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    fs:SetFont(pfUI.font_default, tonumber(pfUI_config.global.font_size) or 12)
    fs:SetWidth(CONTENT_WIDTH)
    fs:SetJustifyH("LEFT")
    textPool[index] = fs
    return fs
end

local function GetIconRow(index)
    if iconPool[index] then return iconPool[index] end
    local row = CreateFrame("Button", nil, frame.content)
    row:SetHeight(ROW_HEIGHT)
    row:SetWidth(CONTENT_WIDTH)

    row.bg = row:CreateTexture(nil, "BACKGROUND")
    row.bg:SetAllPoints()
    row.bg:SetTexture(0, 0, 0, 0.4)

    row.icon = row:CreateTexture(nil, "ARTWORK")
    row.icon:SetWidth(ICON_SIZE)
    row.icon:SetHeight(ICON_SIZE)
    row.icon:SetPoint("LEFT", row, "LEFT", 3, 0)

    row.count = row:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
    row.count:SetPoint("BOTTOMRIGHT", row.icon, "BOTTOMRIGHT", 0, 0)

    row.name = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    row.name:SetFont(pfUI.font_default, tonumber(pfUI_config.global.font_size) or 12)
    row.name:SetPoint("LEFT", row.icon, "RIGHT", 8, 0)
    row.name:SetWidth(CONTENT_WIDTH - ICON_SIZE - 14)
    row.name:SetJustifyH("LEFT")

    row:SetScript("OnEnter", function()
        row.bg:SetTexture(1, 1, 1, 0.08)
        if not row.itemid then return end
        GameTooltip:SetOwner(row, "ANCHOR_RIGHT")
        if GetItemInfo(row.itemid) then
            -- 仅对已缓存物品使用超链接, 避免1.12客户端查询未缓存物品掉线
            GameTooltip:SetHyperlink("item:" .. row.itemid .. compat.itemsuffix)
        else
            GameTooltip:SetText(row.itemname or ("item:" .. row.itemid))
        end
        GameTooltip:Show()
    end)
    row:SetScript("OnLeave", function()
        row.bg:SetTexture(0, 0, 0, 0.4)
        GameTooltip:Hide()
    end)
    row:SetScript("OnClick", function()
        -- Shift+点击: 物品链接插入聊天框
        if IsShiftKeyDown() and row.itemid and ChatFrameEditBox:IsShown() then
            local name, link = GetItemInfo(row.itemid)
            if link then ChatFrameEditBox:Insert(link) end
        end
    end)

    iconPool[index] = row
    return row
end

local function HideAll()
    for _, fs in pairs(textPool) do fs:Hide() end
    for _, row in pairs(iconPool) do row:Hide() end
end

-- ============================================================
-- 数据辅助
-- ============================================================
-- 任务文本占位符替换: $B换行 $N玩家名 $C职业 $R种族
local function QuestText(text)
    if not text then return nil end
    text = string.gsub(text, "%$B", "\n")
    text = string.gsub(text, "%$N", UnitName("player") or "")
    text = string.gsub(text, "%$C", UnitClass("player") or "")
    text = string.gsub(text, "%$R", UnitRace("player") or "")
    return text
end

-- 任务在任务日志中的目标进度 (不在日志中返回nil)
local function GetLeaderBoard(questid)
    for i = 1, GetNumQuestLogEntries() do
        local title, _, _, isHeader = pfExtendCompat.GetQuestLogTitle(i)
        if title and not isHeader then
            local ids = pfDatabase:GetQuestIDs(i)
            for _, id in ipairs(ids or {}) do
                if tonumber(id) == questid then
                    local lines = {}
                    for j = 1, GetNumQuestLeaderBoards(i) do
                        local text, _, finished = GetQuestLogLeaderBoard(j, i)
                        if text then
                            table.insert(lines, { text = text, finished = finished })
                        end
                    end
                    return lines
                end
            end
        end
    end
    return nil
end

-- 任务等级着色 (失败时白色)
local function LevelColor(level)
    if level and GetQuestDifficultyColor then
        local ok, c = pcall(GetQuestDifficultyColor, level)
        if ok and c then return c.r, c.g, c.b end
    end
    return 1, 1, 1
end

-- ============================================================
-- 内容构建
-- ============================================================
local ti, ii, y -- 文本池/图标池索引与当前纵坐标

local function AddText(text, color, indent, spacing)
    ti = ti + 1
    local fs = GetTextRow(ti)
    fs:ClearAllPoints()
    fs:SetPoint("TOPLEFT", frame.content, "TOPLEFT", indent or 0, -y)
    fs:SetText(text)
    fs:SetTextColor(unpack(color or WHITE))
    fs:Show()
    y = y + fs:GetHeight() + (spacing or 6)
    return fs
end

local function AddIconRow(entry)
    local itemid, count
    if type(entry) == "table" then
        itemid, count = entry[1], entry[2]
    else
        itemid, count = entry, 1
    end
    ii = ii + 1
    local row = GetIconRow(ii)
    row:ClearAllPoints()
    row:SetPoint("TOPLEFT", frame.content, "TOPLEFT", 0, -y)
    row.itemid = itemid

    local name, _, quality, _, _, _, _, _, texture = GetItemInfo(itemid)
    name = name or (pfDB.items.loc[itemid] or ("item:" .. itemid))
    row.itemname = name
    row.icon:SetTexture(texture or "Interface\\Icons\\INV_Misc_QuestionMark")
    if count and count > 1 then
        row.count:SetText(count)
    else
        row.count:SetText("")
    end
    if quality and ITEM_QUALITY_COLORS[quality] then
        local c = ITEM_QUALITY_COLORS[quality]
        row.name:SetTextColor(c.r, c.g, c.b)
    else
        row.name:SetTextColor(1, 1, 1)
    end
    row.name:SetText(name)
    row:Show()
    y = y + ROW_HEIGHT + 2
end

local function FormatMoneyText(copper)
    local gold = math.floor(copper / 10000)
    local silver = math.floor(compat.mod(copper, 10000) / 100)
    local cop = compat.mod(copper, 100)
    local parts = {}
    if gold > 0 then table.insert(parts, gold .. pfExtend_Loc["QuestHelper_Gold"]) end
    if silver > 0 then table.insert(parts, silver .. pfExtend_Loc["QuestHelper_Silver"]) end
    if cop > 0 then table.insert(parts, cop .. pfExtend_Loc["QuestHelper_Copper"]) end
    return table.concat(parts, " ")
end

local function BuildContent(questid)
    ti, ii, y = 0, 0, 4
    HideAll()

    local loc = pfDB["quests"]["loc"] and pfDB["quests"]["loc"][questid]
    local data = pfDB["quests"]["data"] and pfDB["quests"]["data"][questid]
    local rewards = PfExtend_QuestRewards and PfExtend_QuestRewards[questid]

    -- 标题 (含等级, 按难度着色)
    local title = (loc and loc.T) or ("quest:" .. questid)
    frame.title:SetText(title)
    if data and data.lvl then
        local r, g, b = LevelColor(data.lvl)
        frame.title:SetTextColor(r, g, b)
        frame.title:SetText("|cffffffff[" .. data.lvl .. "]|r " .. title)
    else
        frame.title:SetTextColor(1, 1, 1)
    end

    -- 目标 (O文本)
    local objective = QuestText(loc and loc.O)
    if objective then
        AddText(objective, WHITE)
    end

    -- 目标进度 (仅任务日志中的任务)
    local boards = GetLeaderBoard(questid)
    if boards then
        for _, line in ipairs(boards) do
            AddText(line.text, line.finished and GREEN or GRAY, 8, 2)
        end
        y = y + 4
    end

    -- 描述 (D文本)
    local desc = QuestText(loc and loc.D)
    if desc then
        AddText(pfExtend_Loc["QuestHelper_DetailDesc"], GOLD, 0, 4)
        AddText(desc, GRAY)
    end

    -- 奖励
    if rewards then
        AddText(pfExtend_Loc["QuestHelper_DetailRewards"], GOLD, 0, 4)
        if rewards.xp and rewards.xp > 0 then
            AddText(string.format(pfExtend_Loc["QuestHelper_RewardXP"], rewards.xp), WHITE, 8, 2)
        end
        if rewards.mml and rewards.mml > 0 then
            AddText(string.format(pfExtend_Loc["QuestHelper_RewardMoney"],
                FormatMoneyText(rewards.mml)), WHITE, 8, 2)
        end
        if rewards.reward then
            AddText(pfExtend_Loc["QuestHelper_RewardYouGet"], WHITE, 8, 2)
            for _, entry in ipairs(rewards.reward) do
                AddIconRow(entry)
            end
        end
        if rewards.choice then
            AddText(pfExtend_Loc["QuestHelper_RewardChoice"], WHITE, 8, 2)
            for _, entry in ipairs(rewards.choice) do
                AddIconRow(entry)
            end
        end
    end

    frame.content:SetHeight(math.max(y, 1))
    frame.scroll:SetVerticalScroll(0)
end

function PFEXQuestHelper.ShowQuestDetail(questid)
    if not questid then return end
    if not pfDB or not pfDB["quests"] then return end
    BuildContent(questid)
    frame:Show()
end
