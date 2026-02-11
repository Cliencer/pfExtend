local sampleData = {
    {
        id = 2854,
        flag = {},
        children = {
            {
                id = 2854,
                flag = {},
                children = {
                    id = 2854,
                    children = {

                    }
                }
            },
        }

    },
    {
        id = 2854,
        flag = {},
        children = {
            id = 2854,
            children = {

            }
        }
    },
}



local items, units, objects, quests, zones, refloot, itemreq, areatrigger, professions

items = pfDB["items"]["data"]
units = pfDB["units"]["data"]
objects = pfDB["objects"]["data"]
quests = pfDB["quests"]["data"]
zones = pfDB["zones"]["data"]
refloot = pfDB["refloot"]["data"]
itemreq = pfDB["quests-itemreq"]["data"]
areatrigger = pfDB["areatrigger"]["data"]
professions = pfDB["professions"]["loc"]





PFEXQuestHelper.Browser = CreateFrame("Frame", "QuestHelperBrowser", WorldMapFrame)
PFEXQuestHelper.Browser:Hide()
PFEXQuestHelper.Browser:SetWidth(500)
-- PFEXQuestHelper.Browser:SetHeight(WorldMapFrame:GetHeight())
PFEXQuestHelper.Browser:SetPoint("TOPLEFT", WorldMapFrame, "TOPRIGHT", 0, 0)
PFEXQuestHelper.Browser:SetPoint("BOTTOMLEFT", WorldMapFrame, "BOTTOMRIGHT", 0, 0)
PFEXQuestHelper.Browser:SetFrameStrata("FULLSCREEN_DIALOG")

PFEXQuestHelper.Browser:SetScript("OnHide", function()
    PFEXQuestHelper.MapToggleButton:Show()
end)
PFEXQuestHelper.Browser:SetScript("OnShow", function()
    PFEXQuestHelper.Browser:BuildTree(PFEXQuestHelper.TreeData)
end)
pfUI.api.CreateBackdrop(PFEXQuestHelper.Browser, nil, true, 0.75)

PFEXQuestHelper.Browser.title = PFEXQuestHelper.Browser:CreateFontString("Status", "LOW", "GameFontNormal")
PFEXQuestHelper.Browser.title:SetFontObject(GameFontWhite)
PFEXQuestHelper.Browser.title:SetPoint("TOP", PFEXQuestHelper.Browser, "TOP", 0, -8)
PFEXQuestHelper.Browser.title:SetJustifyH("LEFT")
PFEXQuestHelper.Browser.title:SetFont(pfUI.font_default, 14)
PFEXQuestHelper.Browser.title:SetText("|cff33ffccpf|rExtend-" .. pfExtend_Loc["windowTitle_QuestHelper"])

PFEXQuestHelper.Browser.close = CreateFrame("Button", "QuestHelperBrowserClose", PFEXQuestHelper.Browser)
PFEXQuestHelper.Browser.close:SetPoint("TOPRIGHT", -5, -5)
PFEXQuestHelper.Browser.close:SetHeight(20)
PFEXQuestHelper.Browser.close:SetWidth(20)
PFEXQuestHelper.Browser.close.texture = PFEXQuestHelper.Browser.close:CreateTexture("pfQuestionDialogCloseTex")
PFEXQuestHelper.Browser.close.texture:SetTexture(pfExtend_Path .. "\\compat\\close")
PFEXQuestHelper.Browser.close.texture:ClearAllPoints()
PFEXQuestHelper.Browser.close.texture:SetVertexColor(1, .25, .25, 1)
PFEXQuestHelper.Browser.close.texture:SetPoint("TOPLEFT", PFEXQuestHelper.Browser.close, "TOPLEFT", 4, -4)
PFEXQuestHelper.Browser.close.texture:SetPoint("BOTTOMRIGHT", PFEXQuestHelper.Browser.close, "BOTTOMRIGHT", -4, 4)
PFEXQuestHelper.Browser.close:SetScript("OnClick", function()
    this:GetParent():Hide()
end)
EnableTooltips(PFEXQuestHelper.Browser.close, {
    pfExtend_Loc["Close"],
    pfExtend_Loc["Hide browser window"],
})
pfUI.api.SkinButton(PFEXQuestHelper.Browser.close, 1, .5, .5)


PFEXQuestHelper.Browser.setting = CreateFrame("Button", "QuestHelperSettingOpen", PFEXQuestHelper.Browser)
PFEXQuestHelper.Browser.setting:SetPoint("TOPRIGHT", -30, -5)
PFEXQuestHelper.Browser.setting:SetHeight(20)
PFEXQuestHelper.Browser.setting:SetWidth(20)
PFEXQuestHelper.Browser.setting.texture = PFEXQuestHelper.Browser.setting:CreateTexture("QuestHelperSettingOpenTex")
PFEXQuestHelper.Browser.setting.texture:SetTexture(pfExtend_Path .. "\\compat\\tracker_settings")
PFEXQuestHelper.Browser.setting.texture:ClearAllPoints()
PFEXQuestHelper.Browser.setting.texture:SetPoint("TOPLEFT", PFEXQuestHelper.Browser.setting, "TOPLEFT", 2, -2)
PFEXQuestHelper.Browser.setting.texture:SetPoint("BOTTOMRIGHT", PFEXQuestHelper.Browser.setting, "BOTTOMRIGHT", -2, 2)
PFEXQuestHelper.Browser.setting:SetScript("OnClick", function()
    WorldMapFrame:Hide()
    pfExtendConfig:Show()
    CaptionClick("QuestHelper")
end)
EnableTooltips(PFEXQuestHelper.Browser.setting, {
    pfExtend_Loc["Setting"],
    pfExtend_Loc["Open Config Window"],
})
pfUI.api.SkinButton(PFEXQuestHelper.Browser.setting)





PFEXQuestHelper.Browser.scroll = pfUI.api.CreateScrollFrame("QuestHelperBrowserScroll", PFEXQuestHelper.Browser)
PFEXQuestHelper.Browser.scroll:SetPoint("TOPLEFT", PFEXQuestHelper.Browser, "TOPLEFT", 10, -65)
PFEXQuestHelper.Browser.scroll:SetPoint("BOTTOMRIGHT", PFEXQuestHelper.Browser, "BOTTOMRIGHT", -10, 10)
PFEXQuestHelper.Browser.scroll:Show()
PFEXQuestHelper.Browser.scroll.buttons = {}
PFEXQuestHelper.Browser.scroll.backdrop = CreateFrame("Frame", "QuestHelperBrowserScrollBackdrop",
    PFEXQuestHelper.Browser.scroll)
PFEXQuestHelper.Browser.scroll.backdrop:SetFrameLevel(1)
PFEXQuestHelper.Browser.scroll.backdrop:SetPoint("TOPLEFT", PFEXQuestHelper.Browser.scroll, "TOPLEFT", -5, 5)
PFEXQuestHelper.Browser.scroll.backdrop:SetPoint("BOTTOMRIGHT", PFEXQuestHelper.Browser.scroll, "BOTTOMRIGHT", 5, -5)
pfUI.api.CreateBackdrop(PFEXQuestHelper.Browser.scroll.backdrop, nil, true)

PFEXQuestHelper.Browser.content = pfUI.api.CreateScrollChild("QuestHelperBrowserScrollScroll",
    PFEXQuestHelper.Browser.scroll)
PFEXQuestHelper.Browser.content:SetWidth(PFEXQuestHelper.Browser:GetWidth() - 30)
PFEXQuestHelper.Browser.content:SetHeight(PFEXQuestHelper.Browser:GetHeight() - 75)

PFEXQuestHelper.Browser.nodes = {}      -- 所有节点
PFEXQuestHelper.Browser.rootNodes = {}  -- 根节点
PFEXQuestHelper.Browser.lineHeight = 20 -- 行高
PFEXQuestHelper.Browser.indent = 20     -- 缩进宽度
PFEXQuestHelper.Browser.pinTitles = {}
PFEXQuestHelper.nodes = {}
PFEXQuestHelper.pins = {}
function PFEXQuestHelper.Browser:InitFramePool()
    -- Frame 池
    self.framePool = {
        buttons = {}, -- 主按钮池
        toggles = {}, -- 切换按钮池
        icons = {},   -- 图标池
        inUse = {},   -- 正在使用的 Frame
    }

    -- 预创建一些 Frame
    for i = 1, 50 do
        self:CreatePooledButton(i)
    end
end

-- 创建池化按钮
function PFEXQuestHelper.Browser:CreatePooledButton(index)
    -- 主按钮
    local button = CreateFrame("Button", nil, self.content)
    button:SetHeight(self.lineHeight)
    pfUI.api.SkinButton(button)

    button.tex = button:CreateTexture("BACKGROUND")
    button.tex:SetAllPoints()
    button.tex:SetTexture(1, 1, 1, .05)
    button.tex:Hide()


    button.texClickable = button:CreateTexture("BACKGROUND")
    button.texClickable:SetAllPoints()
    button.texClickable:SetTexture(1, 0.84, 0, .5)
    button.texClickable:Hide()
    -- 切换按钮
    local toggle = CreateFrame("Button", nil, button)
    toggle:SetWidth(16)
    toggle:SetHeight(16)

    toggle.tex = toggle:CreateTexture(nil, "ARTWORK")
    toggle.tex:SetAllPoints()

    -- 文本
    button.text = button:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    button.text:SetPoint("LEFT", toggle, "RIGHT", 5, 0)

    -- 图标（可选，需要时动态创建）
    button.icon = nil

    -- 存入池中
    button:Hide()
    toggle:Hide()

    table.insert(self.framePool.buttons, {
        button = button,
        toggle = toggle,
        used = false,
        nodeRef = nil, -- 关联的 node
    })
end

-- 从池中获取 Frame
function PFEXQuestHelper.Browser:AcquireFrame()
    -- 查找未使用的
    for _, pooled in ipairs(self.framePool.buttons) do
        if not pooled.used then
            pooled.used = true
            pooled.button:Show()
            pooled.toggle:Show()
            return pooled
        end
    end

    -- 池已满，创建新的
    self:CreatePooledButton(table.countNum(self.framePool.buttons) + 1)
    local pooled = self.framePool.buttons[table.countNum(self.framePool.buttons)]
    pooled.used = true
    pooled.button:Show()
    pooled.toggle:Show()
    return pooled
end

-- 释放 Frame 回池中
function PFEXQuestHelper.Browser:ReleaseFrame(pooled)
    pooled.used = false
    pooled.nodeRef = nil
    pooled.button:Hide()
    pooled.button.tex:Hide()
    pooled.button.texClickable:Hide()
    pooled.toggle:Hide()

    -- 清理脚本
    pooled.button:SetScript("OnClick", nil)
    pooled.button:SetScript("OnEnter", nil)
    pooled.button:SetScript("OnLeave", nil)
    pooled.toggle:SetScript("OnClick", nil)
    pooled.toggle:SetScript("OnDoubleClick", nil)

    -- 清理图标
    if pooled.button.icon then
        pooled.button.icon:Hide()
    end
end

-- 释放所有 Frame
function PFEXQuestHelper.Browser:ReleaseAllFrames()
    for _, pooled in ipairs(self.framePool.buttons) do
        if pooled.used then
            self:ReleaseFrame(pooled)
        end
    end
end

-- ==========================================
-- 修改后的 CreateNode（复用 Frame）
-- ==========================================

function PFEXQuestHelper.Browser:CreateNode(data, parentNode, level, pooledFrame)
    -- 尝试复用旧 node 的 Frame（如果存在）
    local pooled = pooledFrame or self:AcquireFrame()

    local node = {
        data = data,
        parent = parentNode,
        level = level or 0,
        expanded = false,
        children = {},
        visible = true,
        pooled = pooled, -- 关联的 Frame 池对象
        clickType = nil,
        mapNode = false,
        mapNodeTitle = nil,
    }

    pooled.nodeRef = node
    node.clickTimer = nil

    -- 设置 Frame 位置和大小
    local button = pooled.button
    local toggle = pooled.toggle

    button:SetWidth(self.content:GetWidth() - (level * self.indent))
    toggle:SetPoint("LEFT", 5 + (level * self.indent), 0)

    -- 设置文本
    local flag = data.flag
    local color, tag, text = nil, "", nil

    if flag.UNKNOWN then
        text = "|cff9d9d9dUnknown|r"
    elseif flag.FINISHED and not flag.AFTERFINISHED then
        color = "|cffffff2b"
        tag = pfExtend_Loc["QuestHelper_FLAG_Finished"]
    elseif flag.FINISHED and flag.AFTERFINISHED then
        color = "|cff5a5a5a"
        tag = pfExtend_Loc["QuestHelper_FLAG_Finished"]
    elseif flag.DOING then
        color = "|cff3eff2b"
        tag = pfExtend_Loc["QuestHelper_FLAG_Active"]
    elseif flag.WRONGRACE then
        color = "|cff5a5a5a"
        tag = pfExtend_Loc["QuestHelper_FLAG_Race"]
    elseif flag.WRONGCLASS then
        color = "|cff5a5a5a"
        tag = pfExtend_Loc["QuestHelper_FLAG_Class"]
    elseif flag.WRONGSKILL then
        color = "|cff5a5a5a"
        tag = pfExtend_Loc["QuestHelper_FLAG_Skill"]
    elseif flag.EVENT then
        color = "|cff2b3eff"
        tag = pfExtend_Loc["QuestHelper_FLAG_Event"]
    elseif flag.UNDOPRE then
        color = "|cffff2b2b"
        tag = pfExtend_Loc["QuestHelper_FLAG_Prereq"]
    elseif flag.LOWLEVEL then
        color = "|cffff2b2b"
        tag = pfExtend_Loc["QuestHelper_FLAG_High-Level"]
    elseif flag.STARTITEM then
        color = "|cffffff2b"
        tag = pfExtend_Loc["QuestHelper_FLAG_Hidden"]
    else
        color = "|cffffff2b"
        tag = pfExtend_Loc["QuestHelper_FLAG_Available"]
    end

    if text == nil and pfDB["quests"]["loc"] then
        text = color .. tag .. "  " .. pfDB["quests"]["loc"][data.id]["T"]
    else
        text = "|cff9d9d9dUnknown|r"
    end
    button.text:SetText(text)

    if flag.HASPRE and node.level == 0 then
        node.clickType = "FINDPRE"
    end
    if flag.HASPRE and PfExtend_Database["QuestHelper"]["ZoneQuestData"][PFEXQuestHelper.zone][data.id] == nil then
        node.clickType = "OTHERZONE"
    end

    -- 点击事件
    toggle:SetScript("OnClick", function()
        if node.clickTimer then
            node.clickTimer:Cancel()
            node.clickTimer = nil
            return
        end
        node.clickTimer = C_Timer.NewTimer(0.2, function()
            node.clickTimer = nil
            self:ToggleNode(node)
        end)
    end)

    toggle:SetScript("OnDoubleClick", function()
        if node.clickTimer then
            node.clickTimer:Cancel()
            node.clickTimer = nil
        end
        self:ToggleNodeAll(node)
    end)

    button:SetScript("OnClick", function()
        if IsControlKeyDown() and node.clickType == "FINDPRE" then
            local preId, preZone = PFEXQuestHelper.FindPreUndo(node.data.id)

            PFEXQuestHelper.expandToId = data.id
            pfMap:SetMapByID(preZone)
        elseif node.clickType == "OTHERZONE" then
            if PfExtend_Database["QuestHelper"]["QuestZoneData"][data.id] then
                PFEXQuestHelper.expandToId = data.id
                pfMap:SetMapByID(PfExtend_Database["QuestHelper"]["QuestZoneData"][data.id][1])
            end
        else
            node.mapNode = not node.mapNode
            if node.mapNode then
                node.mapNodeTitle = PFEXQuestHelper.AddMapNode(data.id, true)
                PFEXQuestHelper.Browser.pinTitles[node.mapNodeTitle] = true
            else
                pfMap:DeleteNode("PFEX", node.mapNodeTitle)
                PFEXQuestHelper.Browser.pinTitles[node.mapNodeTitle] = false
            end
        end
    end)
    button:SetScript("OnEnter", function()
        if node.clickType then button.texClickable:Show() else button.tex:Show() end
        pfDatabase:ShowExtendedTooltip(data.id, GameTooltip, button, "ANCHOR_RIGHT", 0, 0)
        GameTooltip:AddLine(" ", 0.55, 0.55, 0.55);
        if node.clickType == "FINDPRE" then
            GameTooltip:AddLine(pfExtend_Loc["Click to fix on the map"], 0.55, 0.55, 0.55);
            GameTooltip:AddLine(pfExtend_Loc["Hold <Ctrl> and Click to track Pre-quest on the other map"], 0.55, 0.55,
            0.55);
            GameTooltip:SetHeight(GameTooltip:GetHeight() + 42);
        elseif node.clickType == "OTHERZONE" then
            GameTooltip:AddLine(pfExtend_Loc["Click to track the quest on the other map"], 0.55, 0.55, 0.55);
            GameTooltip:SetHeight(GameTooltip:GetHeight() + 28);
        else
            GameTooltip:AddLine(pfExtend_Loc["Click to fix on the map"], 0.55, 0.55, 0.55);
            GameTooltip:SetHeight(GameTooltip:GetHeight() + 28);
        end
        local width = 0
        for line = 1, GameTooltip:NumLines() do
            width = math.max(width, getglobal(GameTooltip:GetName() .. "TextLeft" .. line):GetWidth())
        end
        GameTooltip:SetWidth(20 + width);
        if not node.mapNode then
            for i, pin in pairs(PFEXQuestHelper.pins) do
                if pin.title == node.mapNodeTitle then
                    pin:Show()
                end
            end
        end
        pfMap.highlight = node.mapNodeTitle
    end)

    button:SetScript("OnLeave", function()
        button.tex:Hide()
        button.texClickable:Hide()
        GameTooltip:Hide()
        --隐藏节点
        pfMap.highlight = nil
        for i, pin in pairs(PFEXQuestHelper.pins) do
            if pin.title == node.mapNodeTitle then
                pin:Hide()
            end
        end
    end)

    -- 存储 node
    table.insert(self.nodes, node)
    if parentNode then
        table.insert(parentNode.children, node)
    else
        table.insert(self.rootNodes, node)
    end

    -- 递归创建子节点
    if data.children then
        for _, childData in ipairs(data.children) do
            self:CreateNode(childData, node, level + 1)
        end
    end

    -- 展开到指定 ID
    if PFEXQuestHelper.expandToId and data.id == PFEXQuestHelper.expandToId then
        local pnode = node
        for i = level, 0, -1 do
            pnode.expanded = true
            pnode = pnode.parent or pnode
        end
        button.texClickable:Show()
        PFEXQuestHelper.expandToId = nil
        PFEXQuestHelper.expandToRootId = pnode.data.id
    end


    node.mapNodeTitle = PFEXQuestHelper.AddMapNode(data.id, false)
    if self.pinTitles[node.mapNodeTitle] then
        node.mapNode = true
    end
    -- local needAdd = true
    -- for i, pin in pairs(PFEXQuestHelper.pins) do
    --     if pin.title == node.mapNodeTitle then
    --         needAdd = false
    --     end
    -- end

    self:UpdateNodeVisual(node)
    return node
end

function PFEXQuestHelper.Browser:BuildTree(dataList)
    -- 初始化 Frame 池（如果还没有）
    if not self.framePool then
        self:InitFramePool()
    end
    -- 释放所有旧 Frame 回池中
    self:ReleaseAllFrames()

    -- 清空 node 数据
    wipe(self.nodes)
    wipe(self.rootNodes)

    --清除pins
    PFEXQuestHelper.nodes = {}



    -- 构建新树（会自动从池中获取 Frame）
    for _, data in ipairs(dataList) do
        self:CreateNode(data, nil, 0)
    end
    self:RefreshLayout()
    if PFEXQuestHelper.expandToRootId then
        local i = 0
        local quit = false
        for _, rootNode in ipairs(self.rootNodes) do
            if rootNode.data.id == PFEXQuestHelper.expandToRootId then
                quit = true
            end
            if not quit then i = i + 1 end
        end
        self.scroll:SetVerticalScroll(math.min(i * self.lineHeight,
            math.max(self.content:GetHeight() - self:GetHeight() + 76, 0))) --无语。。得手动算scroll高度。。内置函数有延迟

        PFEXQuestHelper.expandToRootId = nil
    else
        self.scroll:SetVerticalScroll(0)
    end

    PFEXQuestHelper.UpdateNodes()
end

function PFEXQuestHelper.Browser:UpdateNodeVisual(node)
    local toggle = node.pooled.toggle

    if table.countNum(node.children) > 0 then
        toggle.tex:SetTexture(node.expanded
            and "Interface\\Buttons\\UI-MinusButton-Up"
            or "Interface\\Buttons\\UI-PlusButton-Up")
        toggle:SetHighlightTexture(node.expanded
            and "Interface\\Buttons\\UI-MinusButton-Hilight"
            or "Interface\\Buttons\\UI-PlusButton-Hilight")
        toggle:Show()
    else
        toggle.tex:SetTexture("Interface\\Buttons\\UI-Panel-Button-Down")
        -- toggle:SetHeight(16)
        -- toggle:SetWidth(16)
    end

    -- 递归更新子节点
    for _, child in ipairs(node.children) do
        child.visible = node.expanded and node.visible
        if child.visible then
            child.pooled.button:Show()
        else
            child.pooled.button:Hide()
        end
        self:UpdateNodeVisual(child)
    end
end

function PFEXQuestHelper.Browser:RefreshLayout()
    local visibleNodes = {}

    local function CollectVisible(nodes)
        for _, node in ipairs(nodes) do
            if node.visible then
                table.insert(visibleNodes, node)
                if node.expanded then
                    CollectVisible(node.children)
                end
            end
        end
    end

    CollectVisible(self.rootNodes)

    -- 设置位置
    for i, node in ipairs(visibleNodes) do
        local button = node.pooled.button
        button:ClearAllPoints()
        button:SetPoint("TOPLEFT", self.content, "TOPLEFT", 0, -(i - 1) * self.lineHeight)
        button:SetPoint("TOPRIGHT", self.content, "TOPRIGHT", 0, -(i - 1) * self.lineHeight)
    end

    local totalHeight = table.countNum(visibleNodes) * self.lineHeight

    self.content:SetHeight(math.max(totalHeight, self:GetHeight() - 76))
    self.scroll:SetScrollChild(self.content)
end

-- 展开/收起节点
function PFEXQuestHelper.Browser:ToggleNode(node)
    if table.countNum(node.children) == 0 then return end

    node.expanded = not node.expanded
    self:UpdateNodeVisual(node)
    self:RefreshLayout()
end

-- 展开/收起节点全部
function PFEXQuestHelper.Browser:ToggleNodeAll(node)
    if table.countNum(node.children) == 0 then return end

    node.expanded = not node.expanded


    local function setChildren(node)
        for _, child in ipairs(node.children) do
            if table.countNum(child.children) > 0 then
                child.expanded = node.expanded
                setChildren(child)
            end
        end
    end
    setChildren(node)

    self:UpdateNodeVisual(node)
    self:RefreshLayout()
end

---------地图标点部分-------------
local best, neighbors = { index = 1, neighbors = 0 }, 0
local cache, cacheindex = {}
local ymin, ymax, xmin, ymax
local layers = {
    -- regular icons
    [pfQuestConfig.path .. "\\img\\available"]         = 1,
    [pfQuestConfig.path .. "\\img\\available_c"]       = 2,
    [pfQuestConfig.path .. "\\img\\complete"]          = 3,
    [pfQuestConfig.path .. "\\img\\complete_c"]        = 4,
    [pfQuestConfig.path .. "\\img\\startendstart"]     = 5,
    [pfQuestConfig.path .. "\\img\\icon_vendor"]       = 5,
    [pfQuestConfig.path .. "\\img\\fav"]               = 6,

    -- cluster textures
    [pfQuestConfig.path .. "\\img\\cluster_item"]      = 9,
    [pfQuestConfig.path .. "\\img\\cluster_mob"]       = 9,
    [pfQuestConfig.path .. "\\img\\cluster_misc"]      = 9,
    [pfQuestConfig.path .. "\\img\\cluster_mob_mono"]  = 9,
    [pfQuestConfig.path .. "\\img\\cluster_item_mono"] = 9,
    [pfQuestConfig.path .. "\\img\\cluster_misc_mono"] = 9,
}

local function GetLayerByTexture(tex)
    if layers[tex] then return layers[tex] else return 1 end
end
local function getcluster(tbl, name)
    local count = 0
    best.index, best.neighbors = 1, 0
    cacheindex = string.format("%s:%s", name, table.getn(tbl))

    -- calculate new cluster if nothing is cached
    if not cache[cacheindex] then
        for index, data in pairs(tbl) do
            -- precalculate the limits, and compare directly.
            -- This way is much faster than the math.abs function.
            xmin, xmax = data[1] - 5, data[1] + 5
            ymin, ymax = data[2] - 5, data[2] + 5
            neighbors = 0
            count = count + 1

            for _, compare in pairs(tbl) do
                if compare[1] > xmin and compare[1] < xmax and compare[2] > ymin and compare[2] < ymax then
                    neighbors = neighbors + 1
                end
            end

            if neighbors > best.neighbors then
                best.neighbors = neighbors
                best.index = index
            end
        end

        cache[cacheindex] = { tbl[best.index][1] + .001, tbl[best.index][2] + .001, count }
    end

    return cache[cacheindex][1], cache[cacheindex][2], cache[cacheindex][3]
end

local unifiedcache = {}
local similar_nodes = {}
function PFEXQuestHelper.AddMapNode(id, ispfDB)
    local meta = { ["addon"] = "PFEX" }
    local maps = maps or {}
    local quests = pfDB["quests"]["data"]
    meta["questid"] = id
    meta["quest"] = pfDB.quests.loc[id] and pfDB.quests.loc[id].T
    meta["quest"] = meta["quest"] .. " (" .. id .. ")"
    meta["qlvl"] = quests[id]["lvl"]
    meta["qmin"] = quests[id]["min"]
    if meta.quest then
        unifiedcache[meta.quest] = {}
    end


    -- search quest-starter
    if quests[id]["start"] then
        -- units
        if quests[id]["start"]["U"] then
            for _, unit in pairs(quests[id]["start"]["U"]) do
                meta["QTYPE"] = "NPC_START"
                meta["layer"] = meta["layer"] or 4
                meta["texture"] = pfQuestConfig.path .. "\\img\\available_c"
                if ispfDB then
                    maps = pfDatabase:SearchMobID(unit, meta, maps, 0)
                else
                    maps = PFEXQuestHelper.SearchMobID(unit, meta, maps, 0)
                end
            end
        end

        -- objects
        if quests[id]["start"]["O"] then
            for _, object in pairs(quests[id]["start"]["O"]) do
                meta["QTYPE"] = "OBJECT_START"
                meta["texture"] = pfQuestConfig.path .. "\\img\\available_c"
                if ispfDB then
                    maps = pfDatabase:SearchObjectID(object, meta, maps, 0)
                else
                    maps = PFEXQuestHelper.SearchObjectID(object, meta, maps, 0)
                end
            end
        end
        -- items
        if quests[id]["start"]["I"] then
            for _, object in pairs(quests[id]["start"]["I"]) do
                meta["QTYPE"] = "ITEM_OBJECTIVE_LOOT"
                --meta["texture"] = pfQuestConfig.path .. "\\img\\available_c"
                if ispfDB then
                    local tempv = pfQuest_config.mindropchance
                    pfQuest_config.mindropchance = 0
                    maps = pfDatabase:SearchItemID(object, meta, maps, { ["U"] = true, ["I"] = true })
                    pfQuest_config.mindropchance = tempv
                else
                    maps = PFEXQuestHelper.SearchItemID(object, meta, maps, { ["U"] = true, ["I"] = true })
                end
            end
        end
    end

    if not ispfDB then
        -- search quest-ender
        if quests[id]["end"] then
            -- units
            if quests[id]["end"]["U"] then
                for _, unit in pairs(quests[id]["end"]["U"]) do
                    if table.contain(quests[id]["start"]["U"], unit) then
                        meta["texture"] = pfQuestConfig.path .. "\\img\\startendstart"
                    else
                        meta["texture"] = pfQuestConfig.path .. "\\img\\complete"
                    end

                    meta["QTYPE"] = "NPC_END"
                    if ispfDB then
                        maps = pfDatabase:SearchMobID(unit, meta, maps, 0)
                    else
                        maps = PFEXQuestHelper.SearchMobID(unit, meta, maps, 0)
                    end
                end
            end

            -- objects
            if quests[id]["end"]["O"] then
                for _, object in pairs(quests[id]["end"]["O"]) do
                    if table.contain(quests[id]["start"]["O"], object) then
                        meta["texture"] = pfQuestConfig.path .. "\\img\\startendstart"
                    else
                        meta["texture"] = pfQuestConfig.path .. "\\img\\complete"
                    end
                    meta["QTYPE"] = "OBJECT_END"
                    if ispfDB then
                        maps = pfDatabase:SearchObjectID(object, meta, maps, 0)
                    else
                        maps = PFEXQuestHelper.SearchObjectID(object, meta, maps, 0)
                    end
                end
            end
        end
    end
    if PFEXQuestHelper.nodes["PFEX"] then
        for map in pairs(PFEXQuestHelper.nodes["PFEX"]) do
            if meta.quest and unifiedcache[meta.quest] and unifiedcache[meta.quest][map] then
                for hash, data in pairs(unifiedcache[meta.quest][map]) do
                    meta            = data.meta
                    meta["title"]   = meta["quest"]
                    meta["cluster"] = true
                    meta["zone"]    = map

                    local icon      = pfQuest_config["clustermono"] == "1" and "_mono" or ""

                    if meta.item then
                        meta["x"], meta["y"], meta["priority"] = getcluster(data.coords, meta["quest"] .. hash .. map)
                        meta["texture"] = pfQuestConfig.path .. "\\img\\cluster_item" .. icon
                    elseif meta.spawntype and meta.spawntype == pfQuest_Loc["Unit"] and meta.spawn and not meta.itemreq then
                        meta["x"], meta["y"], meta["priority"] = getcluster(data.coords, meta["quest"] .. hash .. map)
                        meta["texture"] = pfQuestConfig.path .. "\\img\\cluster_mob" .. icon
                    else
                        meta["x"], meta["y"], meta["priority"] = getcluster(data.coords, meta["quest"] .. hash .. map)
                        meta["texture"] = pfQuestConfig.path .. "\\img\\cluster_misc" .. icon
                    end
                    if ispfDB then
                        pfMap:AddNode(meta)
                    else
                        PFEXQuestHelper.AddNode(meta)
                    end
                end
            end
        end
    end

    return meta["quest"]
end

function PFEXQuestHelper.UpdateNodes()
    local color = pfQuest_config["spawncolors"] == "1" and "spawn" or "title"
    local map = pfMap:GetMapID(GetCurrentMapContinent(), GetCurrentMapZone())
    local i = 1

    -- reset tracker
    pfQuest.tracker.Reset()

    -- reset route
    pfQuest.route:Reset()

    -- refresh all nodes
    for addon, _ in pairs(PFEXQuestHelper.nodes) do
        if PFEXQuestHelper.nodes[addon][map] then
            for coords, node in pairs(PFEXQuestHelper.nodes[addon][map]) do
                for title, info in pairs(node) do
                    if not PFEXQuestHelper.pins[i] then
                        PFEXQuestHelper.pins[i] = pfMap:BuildNode("pfEXMapPin" .. i, WorldMapButton)
                    end
                    pfMap:UpdateNode(PFEXQuestHelper.pins[i], { [title] = info }, color)
                    -- set position
                    local _, _, x, y = strfind(coords, "(.*)|(.*)")

                    -- populate quest list on map
                    for title, node in pairs(PFEXQuestHelper.pins[i].node) do
                        pfQuest.tracker.ButtonAdd(title, node)
                    end

                    x = x / 100 * WorldMapButton:GetWidth()
                    y = y / 100 * WorldMapButton:GetHeight()
                    PFEXQuestHelper.pins[i]:ClearAllPoints()
                    PFEXQuestHelper.pins[i]:SetPoint("CENTER", WorldMapButton, "TOPLEFT", x, -y)
                    PFEXQuestHelper.pins[i]:Hide()
                    i = i + 1
                end
            end
        end
    end



    -- hide remaining pins
    for j = i, table.getn(PFEXQuestHelper.pins) do
        if PFEXQuestHelper.pins[j] then PFEXQuestHelper.pins[j]:Hide() end
    end
end

function PFEXQuestHelper.AddNode(meta)
    if not meta then return end
    if not meta["zone"] then return end
    if not meta["title"] then return end

    meta["description"] = pfDatabase:BuildQuestDescription(meta)

    local addon = meta["addon"] or "PFEX"
    local map = meta["zone"]
    local coords = meta["x"] .. "|" .. meta["y"]
    local title = meta["title"]
    local layer = GetLayerByTexture(meta["texture"])
    local spawn = meta["spawn"]
    local item = meta["item"]

    local sindex = string.format("%s:%s:%s:%s:%s:%s",
        (addon or ""), (map or ""), (coords or ""), (title or ""), (layer or ""), (spawn or ""), (item or ""))

    -- use prioritized clusters
    if layer >= 9 and meta["priority"] then
        layer = layer + (10 - min(meta["priority"], 10))
    end

    if not PFEXQuestHelper.nodes[addon] then PFEXQuestHelper.nodes[addon] = {} end
    if not PFEXQuestHelper.nodes[addon][map] then PFEXQuestHelper.nodes[addon][map] = {} end
    if not PFEXQuestHelper.nodes[addon][map][coords] then PFEXQuestHelper.nodes[addon][map][coords] = {} end

    -- skip early on existing nodes
    if PFEXQuestHelper.nodes[addon][map][coords][title] then
        if item and table.getn(PFEXQuestHelper.nodes[addon][map][coords][title].item) > 0 then
            -- check if item already exists
            for id, name in pairs(PFEXQuestHelper.nodes[addon][map][coords][title].item) do
                if name == item then return end
            end

            -- add new item and exit
            table.insert(PFEXQuestHelper.nodes[addon][map][coords][title].item, item)
            return
        end

        if PFEXQuestHelper.nodes[addon][map][coords][title] and PFEXQuestHelper.nodes[addon][map][coords][title].layer and layer and
            PFEXQuestHelper.nodes[addon][map][coords][title].layer >= layer then
            -- identical node already exists, exit here
            return
        end
    end

    -- create new combined data node from given meta data
    if not similar_nodes[sindex] then
        similar_nodes[sindex] = {}
        for key, val in pairs(meta) do similar_nodes[sindex][key] = val end
        similar_nodes[sindex].item = { [1] = item }
    end

    -- set current node to combined node
    PFEXQuestHelper.nodes[addon][map][coords][title] = similar_nodes[sindex]

    -- add node to unified cluster cache
    if not meta["cluster"] and not meta["texture"] then
        local node_index = meta.item or meta.spawn or UNKNOWN
        local x, y = tonumber(meta.x), tonumber(meta.y)

        -- create prerequisite table structure
        unifiedcache[title] = unifiedcache[title] or {}
        unifiedcache[title][map] = unifiedcache[title][map] or {}

        if not unifiedcache[title][map][node_index] then
            -- create new unified node from given meta data
            local unified_meta = {}
            for key, val in pairs(meta) do unified_meta[key] = val end

            -- save node to unified cache
            unifiedcache[title][map][node_index] = { meta = unified_meta, coords = {} }
        end

        -- append new coords to unified cache unified cache
        table.insert(unifiedcache[title][map][node_index].coords, { x, y })
    end
end

function PFEXQuestHelper.SearchMobID(id, meta, maps, prio)
    if not units[id] or not units[id]["coords"] then return maps end
    local maps = maps or {}
    local prio = prio or 1
    for _, data in pairs(units[id]["coords"]) do
        local x, y, zone, respawn = unpack(data)

        if zone > 0 then
            -- add all gathered data
            meta              = meta or {}
            meta["spawn"]     = pfDB.units.loc[id]
            meta["spawnid"]   = id

            meta["title"]     = meta["quest"] or meta["item"] or meta["spawn"]
            meta["zone"]      = zone
            meta["x"]         = x
            meta["y"]         = y

            meta["level"]     = units[id]["lvl"] or UNKNOWN
            meta["spawntype"] = pfQuest_Loc["Unit"]
            meta["respawn"]   = respawn > 0 and SecondsToTime(respawn)

            maps[zone]        = maps[zone] and maps[zone] + prio or prio
            PFEXQuestHelper.AddNode(meta)
        end
    end
    return maps
end

function PFEXQuestHelper.SearchObjectID(id, meta, maps, prio)
    if not objects[id] or not objects[id]["coords"] then return maps end

    local skill, caption = pfDatabase:SearchObjectSkill(id)
    local maps = maps or {}
    local prio = prio or 1

    for _, data in pairs(objects[id]["coords"]) do
        local x, y, zone, respawn = unpack(data)

        if zone > 0 then
            -- add all gathered data
            meta              = meta or {}
            meta["spawn"]     = pfDB.objects.loc[id]
            meta["spawnid"]   = id

            meta["title"]     = meta["quest"] or meta["item"] or meta["spawn"]
            meta["zone"]      = zone
            meta["x"]         = x
            meta["y"]         = y

            meta["level"]     = skill and string.format("%s [%s]", skill, caption) or nil
            meta["spawntype"] = pfQuest_Loc["Object"]
            meta["respawn"]   = respawn and SecondsToTime(respawn)

            maps[zone]        = maps[zone] and maps[zone] + prio or prio
            PFEXQuestHelper.AddNode(meta)
        end
    end

    return maps
end

function PFEXQuestHelper.SearchItemID(id, meta, maps, allowedTypes)
    if not items[id] then return maps end

    local maps = maps or {}
    local meta = meta or {}

    meta["itemid"] = id
    meta["item"] = pfDB.items.loc[id]



    -- search unit drops
    if items[id]["U"] and ((not allowedTypes) or allowedTypes["U"]) then
        for unit, chance in pairs(items[id]["U"]) do
            if chance >= 0 then
                meta["texture"] = nil
                meta["droprate"] = chance
                meta["sellcount"] = nil
                maps = PFEXQuestHelper.SearchMobID(unit, meta, maps)
            end
        end
    end

    -- search object loot (veins, chests, ..)
    if items[id]["O"] and ((not allowedTypes) or allowedTypes["O"]) then
        for object, chance in pairs(items[id]["O"]) do
            if chance >= 0 and chance > 0 then
                meta["texture"] = nil
                meta["droprate"] = chance
                meta["sellcount"] = nil
                maps = PFEXQuestHelper.SearchObjectID(object, meta, maps)
            end
        end
    end

    -- search reference loot (objects, creatures)
    if items[id]["R"] then
        for ref, chance in pairs(items[id]["R"]) do
            if chance >= 0 and refloot[ref] then
                -- ref creatures
                if refloot[ref]["U"] and ((not allowedTypes) or allowedTypes["U"]) then
                    for unit in pairs(refloot[ref]["U"]) do
                        meta["texture"] = nil
                        meta["droprate"] = chance
                        meta["sellcount"] = nil
                        maps = PFEXQuestHelper.SearchMobID(unit, meta, maps)
                    end
                end

                -- ref objects
                if refloot[ref]["O"] and ((not allowedTypes) or allowedTypes["O"]) then
                    for object in pairs(refloot[ref]["O"]) do
                        meta["texture"] = nil
                        meta["droprate"] = chance
                        meta["sellcount"] = nil
                        maps = PFEXQuestHelper.SearchObjectID(object, meta, maps)
                    end
                end
            end
        end
    end

    -- search vendor goods
    if items[id]["V"] and ((not allowedTypes) or allowedTypes["V"]) then
        for unit, chance in pairs(items[id]["V"]) do
            meta["texture"] = pfQuestConfig.path .. "\\img\\icon_vendor"
            meta["droprate"] = nil
            meta["sellcount"] = chance
            maps = PFEXQuestHelper.SearchMobID(unit, meta, maps)
        end
    end

    return maps
end
