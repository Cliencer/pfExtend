PFEXQuestHelper = {
    PANEL_WIDTH = 250,     -- 侧边面板宽度
    BUTTON_SIZE = 32,      -- 按钮大小
    BUTTON_OFFSET_X = -40, -- 按钮相对于地图右上角的X偏移
    BUTTON_OFFSET_Y = -25, -- 按钮相对于地图右上角的Y偏移
    panel = nil,
    mapButton = nil,
    isPanelOpen = false,
    TreeData = {},
    plevel = nil,
    pclass = nil,
    prace = nil,
    pfaction = nil,
    expandToId = nil,
    zone = nil
}




local items, units, objects, quests, zones, refloot, itemreq, areatrigger, professions
PFEXQuestHelper.Reload = function()
    items = pfDB["items"]["data"]
    units = pfDB["units"]["data"]
    objects = pfDB["objects"]["data"]
    quests = pfDB["quests"]["data"]
    zones = pfDB["zones"]["data"]
    refloot = pfDB["refloot"]["data"]
    itemreq = pfDB["quests-itemreq"]["data"]
    areatrigger = pfDB["areatrigger"]["data"]
    professions = pfDB["professions"]["loc"]
    if PfExtend_Database["QuestHelper"] == nil then
        PfExtend_Database["QuestHelper"] = {
            ["QuestZoneData"] = {},
            ["ZoneQuestData"] = {},
            ["QuestAfter"] = {},
            ["updated"] = false,
            ["version"] = nil,
        };
    end
    if PfExtend_Database["QuestHelper"]["QuestAfter"] == nil then
        PfExtend_Database["QuestHelper"]["QuestAfter"] = {}
    end
end

PFEXQuestHelper.Reload()

PFEXQuestHelper.GetPlayerData = function()
    PFEXQuestHelper.plevel = UnitLevel("player")
    local pfaction = UnitFactionGroup("player")
    if pfaction == "Horde" then
        PFEXQuestHelper.pfaction = "H"
    elseif pfaction == "Alliance" then
        PFEXQuestHelper.pfaction = "A"
    else
        PFEXQuestHelper.pfaction = "GM"
    end
    local _, race = UnitRace("player")
    PFEXQuestHelper.prace = pfDatabase:GetBitByRace(race)
    local _, class = UnitClass("player")
    PFEXQuestHelper.pclass = pfDatabase:GetBitByClass(class)
end

PFEXQuestHelper.FindPreUndo = function(id)
    if quests[id]["pre"] then
        local one_complete = nil
        local level = 0
        local thislevel = 0
        for _, prequest in pairs(quests[id]["pre"]) do
            thislevel = 1
            if not pfQuest_history[prequest] then
                local flag = PFEXQuestHelper.QuestFilter(prequest)
                thislevel = 2
                if not flag.WRONGRACE and not flag.WRONGCLASS then
                    thislevel = 3
                end
            end
            if thislevel>level then
                one_complete = prequest
                level = thislevel
            end
        end
        if one_complete and PfExtend_Database["QuestHelper"]["QuestZoneData"][one_complete] ~= {} then
            return one_complete, PfExtend_Database["QuestHelper"]["QuestZoneData"][one_complete][1]
        end
    end
end



PFEXQuestHelper.QuestFilter = function(id)
    local ret = {
        min = 999,             --最低等级
        lvl = 999,             --等级
        DOING = false,         --正在做的
        FINISHED = false,      --完成的
        AFTERFINISHED = false, --后续全部完成或无后续任务的
        UNKNOWN = false,       --数据损坏的或未知的
        HASPRE = false,        --有前置
        UNDOPRE = false,       --前置没做
        WRONGRACE = false,     --种族不对
        WRONGCLASS = false,    --职业不对
        WRONGSKILL = false,    --专业不对
        WRONGFACTION = false,  --阵营不对
        LOWLEVEL = false,      --等级不够
        EVENT = false,         --事件任务
        STARTUNIT = false,     --从生物接取
        STARTOBJECT = false,   --从实体单位接取
        STARTITEM = false,     --从物品接取
    }
    
    if quests[id]["lvl"] then ret.lvl = quests[id]["lvl"] end
    if quests[id]["min"] then ret.min = quests[id]["min"] end
    if pfQuest.questlog[id] then ret.DOING = true end
    if pfQuest_history[id] then ret.FINISHED = true end
    if not pfDB.quests.loc[id] or not pfDB.quests.loc[id].T then ret.UNKNOWN = true end
    if quests[id]["pre"] then
        ret.HASPRE = true
        local one_complete = nil
        for _, prequest in pairs(quests[id]["pre"]) do
            if pfQuest_history[prequest] then
                one_complete = true
            end
        end
        if not one_complete then ret.UNDOPRE = true end
    end
    if quests[id]["race"] and not (bit.band(quests[id]["race"], PFEXQuestHelper.prace) == PFEXQuestHelper.prace) then ret.WRONGRACE = true end
    if quests[id]["class"] and not (bit.band(quests[id]["class"], PFEXQuestHelper.pclass) == PFEXQuestHelper.pclass) then ret.WRONGCLASS = true end
    if quests[id]["skill"] and not pfDatabase:GetPlayerSkill(quests[id]["skill"]) then ret.WRONGCLASS = true end
    if quests[id]["min"] and quests[id]["min"] > PFEXQuestHelper.plevel then ret.LOWLEVEL = true end
    if quests[id]["event"] then ret.EVENT = true end
    if quests[id]["start"] then
        if quests[id]["start"]["U"] then
            for _, unit in pairs(quests[id]["start"]["U"]) do
                if units[unit] and units[unit]["fac"] and not strfind(units[unit]["fac"], PFEXQuestHelper.pfaction) then
                    ret.WRONGFACTION = true;
                end
            end
            ret.STARTUNIT = true;
        end
        if quests[id]["start"]["O"] then
            for _, object in pairs(quests[id]["start"]["O"]) do
                if objects[object] and objects[object]["fac"] and strfind(objects[object]["fac"], PFEXQuestHelper.pfaction) then
                    ret.WRONGFACTION = true;
                end
            end
            ret.STARTOBJECT = true;
        end
        if quests[id]["start"]["I"] then
            ret.STARTITEM = true;
        end
    end
    return ret
end

PFEXQuestHelper.ReadCoords = function(id, type)
    local ret = {};
    local data = {
        ["U"] = units,
        ["V"] = units,
        ["O"] = objects
    };

    if data[type][id] and data[type][id]["coords"] then
        for k, v in pairs(data[type][id]["coords"]) do
            table.insert(ret, v[3])
        end
    end
    return table.unique(ret)
end

PFEXQuestHelper.GetStartZones = function(id)
    local ret = {}
    if quests[id]["start"] then
        if quests[id]["start"]["U"] then
            for _, unit in pairs(quests[id]["start"]["U"]) do
                for _, v in ipairs(PFEXQuestHelper.ReadCoords(unit, "U")) do
                    table.insert(ret, v)
                end
            end
        end
        if quests[id]["start"]["O"] then
            for _, object in pairs(quests[id]["start"]["O"]) do
                for _, v in ipairs(PFEXQuestHelper.ReadCoords(object, "O")) do
                    table.insert(ret, v)
                end
            end
        end
        if quests[id]["start"]["I"] then
            for _, item in pairs(quests[id]["start"]["I"]) do --V,U,O,R
                if items[item] then
                    for lootType, lootSources in pairs(items[item]) do
                        if lootType == "R" then
                            for id, chance in pairs(lootSources) do
                                if refloot[id] then
                                    for refLootType, refLootSources in pairs(refloot[id]) do
                                        for refId, _ in pairs(refLootSources) do
                                            for _, v in ipairs(PFEXQuestHelper.ReadCoords(refId, refLootType)) do
                                                table.insert(ret, v)
                                            end
                                        end
                                    end
                                end
                            end
                        end
                        if lootType == "V" or lootType == "U" or lootType == "O" then
                            for id, chance in pairs(lootSources) do
                                for _, v in ipairs(PFEXQuestHelper.ReadCoords(id, lootType)) do
                                    table.insert(ret, v)
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    return table.unique(ret)
end

PFEXQuestHelper.UpdateDatabase = function()
    if pfDB == nil or (pfDB["zones"]["data"] == nil and pfDB["quests"]["data"] == nil) then
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF8080" .. pfExtend_Loc["Update_Error_Hint"]);
        return false;
    end

    for questId, data in pairs(quests) do
        local questInWhatZone = PFEXQuestHelper.GetStartZones(questId)
        local multiNum = table.getn(questInWhatZone);
        PfExtend_Database["QuestHelper"]["QuestZoneData"][questId] = questInWhatZone;
        for _, zone in pairs(questInWhatZone) do
            if PfExtend_Database["QuestHelper"]["ZoneQuestData"][zone] == nil then
                PfExtend_Database["QuestHelper"]["ZoneQuestData"][zone] = {}
            end
            PfExtend_Database["QuestHelper"]["ZoneQuestData"][zone][questId] = multiNum;
        end
        if PfExtend_Database["QuestHelper"]["QuestAfter"][questId] == nil then PfExtend_Database["QuestHelper"]["QuestAfter"][questId] = {} end
        if data["pre"] then
            for _, pre in pairs(data["pre"]) do
                if PfExtend_Database["QuestHelper"]["QuestAfter"][pre] == nil then PfExtend_Database["QuestHelper"]["QuestAfter"][pre] = {} end
                if not table.contain(PfExtend_Database["QuestHelper"]["QuestAfter"][pre], questId) then
                    table.insert(PfExtend_Database["QuestHelper"]["QuestAfter"][pre], questId)
                end
            end
        end
    end
    PfExtend_Database["QuestHelper"]["LootData"] = db;
    PfExtend_Database["QuestHelper"]["updated"] = true;
    DEFAULT_CHAT_FRAME:AddMessage("|cFFFF8080" .. pfExtend_Loc["Update_Success_Hint"])
    return true;
end



PFEXQuestHelper.findZoneByLocation = function(location)
    if zones[location] then
        return zones[location][1]
    end
end
PFEXQuestHelper.findLocationByZone = function(Zone)
    local ret = {}
    for k, v in pairs(zones) do
        if v[1] == Zone then
            table.insert(ret, k)
        end
    end
    return table.unique(ret)
end


















local function MapToggleButtonOnClick()

end







PFEXQuestHelper.MapToggleButton = CreateFrame("Button", "PFEXQuestHelperMapToggleButton", WorldMapFrame,
    "UIPanelButtonTemplate")
PFEXQuestHelper.MapToggleButton:SetWidth(40)
PFEXQuestHelper.MapToggleButton:SetHeight(40)
PFEXQuestHelper.MapToggleButton:SetFont(STANDARD_TEXT_FONT, 24)
PFEXQuestHelper.MapToggleButton:SetPoint("TOPLEFT", WorldMapFrame, "TOPRIGHT", 0, 0)
PFEXQuestHelper.MapToggleButton:SetText("QH")
PFEXQuestHelper.MapToggleButton:Show()
PFEXQuestHelper.MapToggleButton:SetScript("OnClick", function()
    PFEXQuestHelper.Browser:Show()
    PFEXQuestHelper.MapToggleButton:Hide()
end)
pfUI.api.SkinButton("PFEXQuestHelperMapToggleButton")


function PFEXQuestHelper.QuestChainBuilder(questList)
    local QuestAfter = PfExtend_Database["QuestHelper"]["QuestAfter"]
    local processed = {}
    local roots = {}
    local hasParent = {}

    -- 第一遍：标记父节点
    local function MarkParents(id)
        if processed[id] then return end
        processed[id] = true

        local after = QuestAfter[id]
        if after then
            for _, nextId in ipairs(after) do
                hasParent[nextId] = true
                MarkParents(nextId)
            end
        end
    end

    for _, id in ipairs(questList) do
        MarkParents(id)
    end

    for _, id in ipairs(questList) do
        if not hasParent[id] then
            table.insert(roots, id)
        end
    end

    if table.countNum(roots) == 0 and table.countNum(questList) > 0 then
        table.insert(roots, questList[1])
    end

    wipe(processed)

    -- 构建树结构
    local function BuildNode(id)
    
        if processed[id] then
            return nil
        end

        processed[id] = true

        local node = {
            id = id,
            flag = PFEXQuestHelper.QuestFilter(id),
            children = {},
        }

        local after = QuestAfter[id]
        if after then
            for _, nextId in ipairs(after) do
                local child = BuildNode(nextId)
                if child then
                    table.insert(node.children, child)
                end
            end
        end

        return node
    end

    local result = {}
    for _, rootId in ipairs(roots) do
        wipe(processed)
        local tree = BuildNode(rootId)
        if tree then
            table.insert(result, tree)
        end
    end

    -- 自底向上计算 AFTERFINISHED
    local function CalculateAfterFinished(node)
        local allChildrenFinished = true
        local hasChildren = table.countNum(node.children) > 0

        for _, child in ipairs(node.children) do
            CalculateAfterFinished(child)
            if not child.flag.AFTERFINISHED then
                allChildrenFinished = false
            end
        end

        if not hasChildren then
            node.flag.AFTERFINISHED = node.flag.FINISHED or node.flag.WRONGSKILL or node.flag.WRONGCLASS or
                node.flag.WRONGRACE
        else
            node.flag.AFTERFINISHED = (node.flag.FINISHED or node.flag.WRONGSKILL or node.flag.WRONGCLASS or node.flag.WRONGRACE) and
                allChildrenFinished
        end
    end

    for _, tree in ipairs(result) do
        CalculateAfterFinished(tree)
    end

    -- 优先级位定义（从前到后，前面的优先级高，对应低位）
    local PRIORITY = {
        HAS_PRE     = 1,   -- 00000001  有前置（倒数第八）
        FINISHED    = 2,   -- 00000010  已完成（倒数第七）
        AFTER_FIN   = 4,   -- 00000100  后续全完成（倒数第六）
        EVENT       = 8,   -- 00001000  事件任务（倒数第五）
        WRONG_SKILL = 16,  -- 00010000  专业不对（倒数第四）
        WRONG_CLASS = 32,  -- 00100000  职业不对（倒数第三）
        WRONG_RACE  = 64,  -- 01000000  种族不对（倒数第二）
        UNKNOWN     = 128, -- 10000000  数据损坏（最后）
    }

    -- 计算优先级分数（位运算组合）
    local function GetPriorityScore(flag, hasPre)
        local score = 0

        if hasPre then
            score = bit.bor(score, PRIORITY.HAS_PRE)
        end
        if flag.FINISHED then
            score = bit.bor(score, PRIORITY.FINISHED)
        end
        if flag.AFTERFINISHED then
            score = bit.bor(score, PRIORITY.AFTER_FIN)
        end
        if flag.EVENT then
            score = bit.bor(score, PRIORITY.EVENT)
        end
        if flag.WRONGSKILL then
            score = bit.bor(score, PRIORITY.WRONG_SKILL)
        end
        if flag.WRONGCLASS then
            score = bit.bor(score, PRIORITY.WRONG_CLASS)
        end
        if flag.WRONGRACE then
            score = bit.bor(score, PRIORITY.WRONG_RACE)
        end
        if flag.UNKNOWN then
            score = bit.bor(score, PRIORITY.UNKNOWN)
        end

        return score
    end

    -- 对树进行层级排序
    local function SortTree(node, hasPre)
        -- 先递归排序子节点（子节点都有前置）
        for _, child in ipairs(node.children) do
            SortTree(child, true)
        end

        -- 对当前节点的子节点进行排序
        if table.countNum(node.children) > 1 then
            table.sort(node.children, function(a, b)
                local scoreA = GetPriorityScore(a.flag, true) -- 子节点都有前置
                local scoreB = GetPriorityScore(b.flag, true)

                -- 优先级不同，按优先级（分数小的在前）
                if scoreA ~= scoreB then
                    return scoreA < scoreB
                end

                -- 同优先级按等级从小到大
                local lvlA = a.flag.lvl or 999
                local lvlB = b.flag.lvl or 999
                return lvlA < lvlB
            end)
        end
    end

    -- 对所有树进行排序
    for _, tree in ipairs(result) do
        SortTree(tree, false)
    end

    -- 对根节点列表本身也进行排序（根节点没有前置）
    if table.countNum(result) > 1 then
        table.sort(result, function(a, b)
            local scoreA = GetPriorityScore(a.flag, false) -- 根节点无前置
            local scoreB = GetPriorityScore(b.flag, false)

            if scoreA ~= scoreB then
                return scoreA < scoreB
            end

            local lvlA = a.flag.lvl or 999
            local lvlB = b.flag.lvl or 999
            return lvlA < lvlB
        end)
    end

    return result
end

PFEXQuestHelper.OnMapChange = function()
    PFEXQuestHelper.GetPlayerData()
    local questList = {}
    PFEXQuestHelper.zone = pfMap:GetMapID(GetCurrentMapContinent(), GetCurrentMapZone())
    local q2z = PfExtend_Database["QuestHelper"]["QuestZoneData"]
    local z2q = PfExtend_Database["QuestHelper"]["ZoneQuestData"]
    if z2q[PFEXQuestHelper.zone] then
        for k, _ in pairs(z2q[PFEXQuestHelper.zone]) do
            table.insert(questList, k)
        end
    end
    local locations = PFEXQuestHelper.findLocationByZone(PFEXQuestHelper.zone)

    for _, location in pairs(locations) do
        if z2q[location] then
            for k, _ in pairs(z2q[PFEXQuestHelper.zone]) do
                table.insert(questList, k)
            end
        end
    end
    questList = table.unique(questList)
    PFEXQuestHelper.TreeData = PFEXQuestHelper.QuestChainBuilder(questList);
    if PFEXQuestHelper.Browser:IsShown() then
        PFEXQuestHelper.Browser:BuildTree(PFEXQuestHelper.TreeData)
    end
end





local frame = CreateFrame("Frame")
PFEXQuestHelper.OnLoad = function()

end
local zone, last_zone

PFEXQuestHelper.OnEvent = function(event, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9)
    if not PfExtend_Global.ReadSetting("QuestHelper", "enable") then
        if PFEXQuestHelper.MapToggleButton then
            PFEXQuestHelper.MapToggleButton:Hide()
        end
        if PFEXQuestHelper.Browser then
            PFEXQuestHelper.Browser:Hide()
        end
        return
    else
        if PFEXQuestHelper.MapToggleButton:IsShown() and PFEXQuestHelper.Browser:IsShown() then
            PFEXQuestHelper.MapToggleButton:Hide()
        elseif not (PFEXQuestHelper.MapToggleButton:IsShown() or PFEXQuestHelper.Browser:IsShown()) then
            PFEXQuestHelper.MapToggleButton:Show()
        end
    end
    zone = GetCurrentMapZone()
    if (event == "PLAYER_ENTERING_WORLD") then
        PFEXQuestHelper.Reload()
        PFEXQuestHelper.GetPlayerData()
        if PfExtend_Database["QuestHelper"]["updated"] ~= true or PfExtend_Database["QuestHelper"]["version"] ~= PfExtend_Config_Template["About"].Version() then
            PFEXQuestHelper.UpdateDatabase();
            PfExtend_Database["QuestHelper"]["version"] = PfExtend_Config_Template["About"].Version()
        end
    elseif (event == "WORLD_MAP_UPDATE" and last_zone ~= zone) then
        last_zone = zone;
        PFEXQuestHelper.OnMapChange()
    end
end
