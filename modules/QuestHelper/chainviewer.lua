-- 任务日志"任务链"功能：在每个已接取且有后续的任务行上显示链条按钮，
-- 点击后弹出该任务的后续环节查看窗口

DEFAULT_CHAT_FRAME:AddMessage("|cff33ffccpfExtend: chainviewer.lua 已加载") -- 调试标记，确认后删除

local LINE_HEIGHT = 18
local INDENT = 16

-- ============================================================
-- 任务链查看窗口
-- ============================================================
-- 注意：部分客户端在插件加载阶段尚未创建QuestLogFrame，这里用UIParent兜底，
-- 首次显示时再通过AnchorToQuestLog重新挂靠
local frame = CreateFrame("Frame", "PFEXQuestChainFrame", QuestLogFrame or UIParent)
frame:Hide()
frame:SetWidth(300)
frame:SetFrameStrata("DIALOG")
frame:EnableMouse(1)
pfUI.api.CreateBackdrop(frame, nil, true, 0.75)

local function AnchorToQuestLog()
    if not QuestLogFrame then return end
    if frame:GetParent() ~= QuestLogFrame then
        frame:SetParent(QuestLogFrame)
    end
    frame:ClearAllPoints()
    frame:SetPoint("TOPLEFT", QuestLogFrame, "TOPRIGHT", 2, 0)
    frame:SetPoint("BOTTOMLEFT", QuestLogFrame, "BOTTOMRIGHT", 2, 0)
end

if QuestLogFrame then
    AnchorToQuestLog()
else
    frame:SetPoint("LEFT", UIParent, "CENTER", 200, 0)
    frame:SetHeight(400)
    DEFAULT_CHAT_FRAME:AddMessage("|cFFFF8080pfExtend: 加载时QuestLogFrame尚未创建，已延迟挂靠")
end

frame.title = frame:CreateFontString("Status", "LOW", "GameFontNormal")
frame.title:SetFontObject(GameFontWhite)
frame.title:SetPoint("TOP", frame, "TOP", 0, -8)
frame.title:SetJustifyH("LEFT")
frame.title:SetFont(pfUI.font_default, 13)
frame.title:SetWidth(260)

frame.close = CreateFrame("Button", "PFEXQuestChainFrameClose", frame)
frame.close:SetPoint("TOPRIGHT", -5, -5)
frame.close:SetHeight(20)
frame.close:SetWidth(20)
frame.close.texture = frame.close:CreateTexture("PFEXQuestChainFrameCloseTex")
frame.close.texture:SetTexture(pfExtend_Path .. "\\compat\\close")
frame.close.texture:ClearAllPoints()
frame.close.texture:SetVertexColor(1, .25, .25, 1)
frame.close.texture:SetPoint("TOPLEFT", frame.close, "TOPLEFT", 4, -4)
frame.close.texture:SetPoint("BOTTOMRIGHT", frame.close, "BOTTOMRIGHT", -4, 4)
frame.close:SetScript("OnClick", function()
    this:GetParent():Hide()
end)
pfUI.api.SkinButton(frame.close, 1, .5, .5)

frame.scroll = pfUI.api.CreateScrollFrame("PFEXQuestChainFrameScroll", frame)
frame.scroll:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, -30)
frame.scroll:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -10, 10)
frame.scroll:Show()

frame.content = pfUI.api.CreateScrollChild("PFEXQuestChainFrameScrollChild", frame.scroll)
frame.content:SetWidth(260)
frame.content:SetHeight(1)

-- 行池
local chainRows = {}

local function GetChainRow(index)
    if chainRows[index] then return chainRows[index] end

    local row = CreateFrame("Button", nil, frame.content)
    row:SetHeight(LINE_HEIGHT)
    row:SetPoint("TOPLEFT", frame.content, "TOPLEFT", 0, -(index - 1) * LINE_HEIGHT)
    row:SetPoint("TOPRIGHT", frame.content, "TOPRIGHT", 0, -(index - 1) * LINE_HEIGHT)

    row.hl = row:CreateTexture(nil, "BACKGROUND")
    row.hl:SetAllPoints()
    row.hl:SetTexture(1, 1, 1, .05)
    row.hl:Hide()

    row.text = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    row.text:SetFont(pfUI.font_default, tonumber(pfUI_config.global.font_size) or 12)
    row.text:SetPoint("LEFT", 0, 0)
    row.text:SetJustifyH("LEFT")

    -- 单击：打开世界地图并定位；Shift+单击：插入任务链接
    row:SetScript("OnClick", function()
        local questid = row.questid
        if not questid then return end
        if IsShiftKeyDown() then
            pfExtendCompat.InsertQuestLink(questid)
            return
        end
        local zones = PfExtend_Database["QuestHelper"]["QuestZoneData"][questid]
        if zones and zones[1] then
            PFEXQuestHelper.expandToId[questid] = true
            PFEXQuestHelper.cacheKey = nil -- 强制重建以使展开生效
            if not WorldMapFrame:IsShown() then ToggleWorldMap() end
            pfMap:SetMapByID(zones[1])
            PFEXQuestHelper.Browser:Show()
            PFEXQuestHelper.MapToggleButton:Hide()
            -- 若SetMapByID未触发重建（区域未变），手动触发一次
            PFEXQuestHelper.OnMapChange()
        end
    end)
    row:SetScript("OnEnter", function()
        row.hl:Show()
        if row.questid then
            pfDatabase:ShowExtendedTooltip(row.questid, GameTooltip, row, "ANCHOR_RIGHT", 0, 0)
        end
    end)
    row:SetScript("OnLeave", function()
        row.hl:Hide()
        GameTooltip:Hide()
    end)

    chainRows[index] = row
    return row
end

-- 先序遍历，把树扁平化为带缩进层级的列表
local function FlattenTree(nodes, level, out)
    for _, node in ipairs(nodes) do
        table.insert(out, { data = node, level = level })
        if node.children then
            FlattenTree(node.children, level + 1, out)
        end
    end
end

function frame:ShowChain(questid)
    if not questid then return end
    AnchorToQuestLog()
    PFEXQuestHelper.GetPlayerData()

    local name = pfDB["quests"]["loc"][questid] and pfDB["quests"]["loc"][questid]["T"] or "?"
    self.title:SetText("|cff33ffcc" .. pfExtend_Loc["QuestHelper_ChainTitle"] .. "|r " .. name)

    local tree = PFEXQuestHelper.QuestChainBuilder({ questid })
    local list = {}
    FlattenTree(tree, 0, list)

    for i, entry in ipairs(list) do
        local row = GetChainRow(i)
        row.questid = entry.data.id
        row.text:ClearAllPoints()
        row.text:SetPoint("LEFT", 4 + entry.level * INDENT, 0)
        row.text:SetText(PFEXQuestHelper.FormatQuestText(entry.data.flag, entry.data.id))
        row:Show()
    end
    for j = table.getn(list) + 1, table.getn(chainRows) do
        chainRows[j]:Hide()
    end

    if table.getn(list) == 0 then
        local row = GetChainRow(1)
        row.questid = nil
        row.text:ClearAllPoints()
        row.text:SetPoint("LEFT", 4, 0)
        row.text:SetText("|cff9d9d9d" .. pfExtend_Loc["QuestHelper_ChainEmpty"] .. "|r")
        row:Show()
    end

    self.content:SetHeight(math.max(table.getn(list) * LINE_HEIGHT, self:GetHeight() - 40))
    self.scroll:SetVerticalScroll(0)
    self:Show()
end

-- ============================================================
-- 任务日志行内按钮
-- ============================================================
local chainButtons = {}

local function GetChainButton(rowButton)
    if not rowButton then return nil end
    if chainButtons[rowButton] then return chainButtons[rowButton] end

    local btn = CreateFrame("Button", nil, rowButton)
    btn:SetWidth(14)
    btn:SetHeight(14)
    btn:SetPoint("RIGHT", rowButton, "RIGHT", -2, 0)
    btn:SetFrameLevel(rowButton:GetFrameLevel() + 2)

    btn.icon = btn:CreateTexture(nil, "ARTWORK")
    btn.icon:SetAllPoints()
    btn.icon:SetTexture(pfExtend_Path .. "\\compat\\track")
    btn.icon:SetVertexColor(1, .84, 0)

    btn:SetScript("OnClick", function()
        if btn.questid then
            frame:ShowChain(btn.questid)
        end
    end)
    btn:SetScript("OnEnter", function()
        btn.icon:SetVertexColor(1, 1, 1)
        GameTooltip:SetOwner(btn, "ANCHOR_RIGHT")
        GameTooltip:SetText(pfExtend_Loc["QuestHelper_ChainTip"], 1, 1, 1)
        GameTooltip:Show()
    end)
    btn:SetScript("OnLeave", function()
        btn.icon:SetVertexColor(1, .84, 0)
        GameTooltip:Hide()
    end)
    btn:Hide()

    chainButtons[rowButton] = btn
    return btn
end

-- 刷新所有可见行的链条按钮
local function UpdateChainButtons()
    local enabled = PfExtend_Global.ReadSetting("QuestHelper", "enable") and
        PfExtend_Global.ReadSetting("QuestHelper", "questlogChain")
    local questAfter = PfExtend_Database["QuestHelper"] and
        PfExtend_Database["QuestHelper"]["QuestAfter"]

    local function UpdateRow(rowButton, qlogid)
        local btn = GetChainButton(rowButton)
        if not btn then return end

        local questid
        if qlogid then
            local title, _, _, header = pfExtendCompat.GetQuestLogTitle(qlogid)
            if title and not header then
                local ids = pfDatabase:GetQuestIDs(qlogid)
                questid = ids and ids[1] and tonumber(ids[1])
            end
        end

        if enabled and questid and questAfter and questAfter[questid] and
            table.getn(questAfter[questid]) > 0 then
            btn.questid = questid
            btn:Show()
        else
            btn:Hide()
        end
    end

    if pfExtendCompat.client >= 30300 then
        -- wotlk: 3.3 后任务日志行结构改变
        for _, rowButton in pairs(QuestLogScrollFrame.buttons) do
            UpdateRow(rowButton, rowButton:GetID())
        end
    else
        -- vanilla/tbc
        local offset = FauxScrollFrame_GetOffset(QuestLogListScrollFrame)
        for i = 1, QUESTS_DISPLAYED do
            UpdateRow(getglobal("QuestLogTitle" .. i), i + offset)
        end
    end
end

-- hook QuestLog_Update（pfQuest也hook了它，此处在其之后执行）
local pfExHook_QuestLog_Update = QuestLog_Update
QuestLog_Update = function()
    pfExHook_QuestLog_Update()
    UpdateChainButtons()
end
