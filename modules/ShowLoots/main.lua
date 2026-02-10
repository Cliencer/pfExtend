PfExtend_Database["ShowLoots"] = {
    ["LootData"] = {},
    ["itemQualityData"] = {},
    ["updated"] = false,
    ["version"] = nil
};

PFEXShowLoots = {
    LootListShown = {},
    focus_name = nil,
    isBrowse = false,
    closeTime = 0
}


local isShown = false;
local compat = pfExtendCompat;




PFEXShowLoots.UpdateDatabase = function()
    if pfDB == nil or pfDB["items"]["data"] == nil then
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF8080"..pfExtend_Loc["Update_Error_Hint"]);
        return false;
    end
    local db = {}
    for itemId, itemData in pairs(pfDB["items"]["data"]) do
        for lootType, LootData in pairs(itemData) do
            for from, probability in pairs(LootData) do
                if probability > 0 then
                    if lootType == "U" or lootType == "O" then
                        if db[lootType] == nil then
                            db[lootType] = {};
                        end
                        if db[lootType][from] == nil then
                            db[lootType][from] = {};
                        end

                        db[lootType][from][itemId] = probability;
                    elseif lootType == "R" then
                        if pfDB["refloot"]["data"][from] then
                            for refLootType, refLootData in pairs(pfDB["refloot"]["data"][from]) do
                                for refFrom, refProbability in pairs(refLootData) do
                                    if db[refLootType] == nil then
                                        db[refLootType] = {};
                                    end
                                    if db[refLootType][refFrom] == nil then
                                        db[refLootType][refFrom] = {};
                                    end
                                    db[refLootType][refFrom][itemId] = probability;
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    PfExtend_Database["ShowLoots"]["LootData"] = db;
    PfExtend_Database["ShowLoots"]["updated"] = true;
    DEFAULT_CHAT_FRAME:AddMessage("|cFFFF8080"..pfExtend_Loc["Update_Success_Hint"])
    return true;
end




PFEXShowLoots.ModifyTooltip = function()
    local focus = GetMouseFocus();
    local ret = {};
    local db = PfExtend_Database["ShowLoots"]["LootData"]
    if focus and focus.title then return end
    if focus and focus.GetName and strsub((focus:GetName() or ""), 0, 10) == "QuestTimer" then return end
    PFEXShowLoots.focus_name = getglobal("GameTooltipTextLeft1") and getglobal("GameTooltipTextLeft1"):GetText() or
        "__NONE__"
    local focus_zone = pfMap:GetMapID(GetCurrentMapContinent(), GetCurrentMapZone())
    PFEXShowLoots.focus_name = string.gsub(PFEXShowLoots.focus_name, "|c%x%x%x%x%x%x%x%x", "");
    PFEXShowLoots.focus_name = string.gsub(PFEXShowLoots.focus_name, "|r", "");
    for id in pairs(pfDatabase:GetIDByName(PFEXShowLoots.focus_name, "units")) do
        for _, data in pairs(pfDB["units"]["data"][id]["coords"]) do
            local x, y, zone, respawn = unpack(data)
            if zone == focus_zone and type(db["U"][id]) == "table" then
                local lootList = db["U"][id]
                local sortLootList = table.shallowCopy(lootList)
                for itemid, chance in pairs(sortLootList) do
                    if pfBrowser_fav and pfBrowser_fav["items"] and pfBrowser_fav["items"][itemid] then
                        sortLootList[itemid] = chance + 100;
                    end
                end

                for _, v in ipairs(PfExtend_Global.sortKeyValueTable(sortLootList, "value", true)) do
                    if v.value > 100 then
                        v.value = v.value - 100;
                    end
                    local r, g, b = pfMap.tooltip:GetColor(tonumber(v.value), 100)
                    table.insert(ret, { v.key, v.value, r, g, b })
                    --GameTooltip:AddLine(itemLink ..  " |cff555555[|r" .. v.value .. "%|cff555555]", r,g,b)
                end
                break
            end
        end
    end
    return ret;
end





local altKey = CreateFrame("Frame", "pfQuestShowLootsAltKey", UIParent)
altKey:SetScript("OnUpdate", function()
    altKey.pressed = false;
    if not isShown then return end
    if PFEXShowLoots.isBrowse then return end
    if (this.throttle or .05) > GetTime() then return else this.throttle = GetTime() + .05 end
    if GameTooltip:IsShown() and GetTime() - PFEXShowLoots.closeTime > .2 then
        altKey.pressed = IsAltKeyDown() and IsControlKeyDown()
    end
end)

pfMap.tooltip:SetScript("OnUpdate", function()
    if not PfExtend_Global.ReadSetting("ShowLoots", "enable") then return end
    local num = table.getn(PFEXShowLoots.LootListShown);
    if not isShown then
        local i = 0;
        local j = 0;
        local miniq = PfExtend_Global.ReadSetting("ShowLoots", "itemQualityFilter")
        local showlines = {}
        for _, l in ipairs(PFEXShowLoots.LootListShown) do
            local id, chance, r, g, b = unpack(l)


            local itemQuality = PfExtend_Database["ShowLoots"]["itemQualityData"][id];
            if itemQuality == nil then
                local _, _, iq = GetItemInfo(id);
                itemQuality = iq;
            end
            local itemLink;
            if type(itemQuality) == "number" then
                PfExtend_Database["ShowLoots"]["itemQualityData"][id] = itemQuality;
                local itemColor                                       = "|c" .. string.format("%02x%02x%02x%02x", 255,
                    ITEM_QUALITY_COLORS[itemQuality].r * 255,
                    ITEM_QUALITY_COLORS[itemQuality].g * 255,
                    ITEM_QUALITY_COLORS[itemQuality].b * 255)
                itemLink                                              = itemColor ..
                    "|Hitem:" .. id .. compat.itemsuffix .. "|h[" .. pfDB.items.loc[id] .. "]|h|r"
            end
            if type(itemQuality) ~= "number" or itemQuality >= miniq then
                if i < tonumber(PfExtend_Global.ReadSetting("ShowLoots", "showNum")) then
                    itemLink = itemLink or "[" .. pfDB.items.loc[id] .. "]"
                    table.insert(showlines,
                        { ["itemLink"] = itemLink, ["chance"] = chance, ["r"] = r, ["g"] = g, ["b"] = b })
                    i = i + 1;
                end
                j = j + 1;
            end
        end
        if num == 0 then
            GameTooltip:AddLine(pfExtend_Loc["No loots"], 0.55, 0.55, 0.55);
        elseif miniq > 0 and i == 0 then
            GameTooltip:AddLine(
                string.format(pfExtend_Loc["No %s or better loots"],
                    pfExtend_Loc["Config_ShowLoots_itemQualityFilter_" .. miniq] .. "|r"), 0.55, 0.55, 0.55);
        elseif miniq > 0 and i > 0 then
            GameTooltip:AddLine(
                string.format(pfExtend_Loc["%d %s or better loots(of %d)"], j,
                    pfExtend_Loc["Config_ShowLoots_itemQualityFilter_" .. miniq] .. "|r", num), 0.55, 0.55, 0.55);
        elseif miniq == 0 then
            GameTooltip:AddLine(string.format(pfExtend_Loc["All %d loots"], num), 0.55, 0.55, 0.55);
        end
        GameTooltip:SetHeight(GameTooltip:GetHeight() + 14);
        for _, line in pairs(showlines) do
            GameTooltip:AddLine(
                line.itemLink .. " |cff555555[|r" .. string.format("%.2f", line.chance) .. "%|cff555555]", line.r, line
                .g,
                line.b)
            GameTooltip:SetHeight(GameTooltip:GetHeight() + 14);
        end
        if num - i > 0 then
            GameTooltip:AddLine(string.format(pfExtend_Loc["... %d loots hidden ..."], num - i), 0.55, 0.55, 0.55)
            GameTooltip:SetHeight(GameTooltip:GetHeight() + 14);
        end
        if num > 0 then
            GameTooltip:AddLine(pfExtend_Loc["Press <Alt> for details"], 0.55, 0.55, 0.55);
            GameTooltip:SetHeight(GameTooltip:GetHeight() + 14);
        end
        local width = 0
        for line = 1, GameTooltip:NumLines() do
            width = math.max(width, getglobal(GameTooltip:GetName() .. "TextLeft" .. line):GetWidth())
        end
        GameTooltip:SetWidth(20 + width);

        isShown = true;
    end
    if altKey.pressed and isShown and not PFEXShowLoots.isBrowse and num > 0 then
        if PFEXShowLoots.Browser then PFEXShowLoots.Browser:Show() end
    end
end)

function PFEXShowLoots.OnLoad()

end

function PFEXShowLoots.OnEvent(event, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9)
    if not PfExtend_Global.ReadSetting("ShowLoots", "enable") then return end
    if (event == "PLAYER_ENTERING_WORLD") then
        if PfExtend_Database["ShowLoots"]["updated"] ~= true or PfExtend_Database["ShowLoots"]["version"] ~= PfExtend_Config_Template["About"].Version() then
            PFEXShowLoots.UpdateDatabase();
            PfExtend_Database["ShowLoots"]["version"] = PfExtend_Config_Template["About"].Version()
        end
    elseif (event == "UPDATE_MOUSEOVER_UNIT") then
        PFEXShowLoots.LootListShown = {}
        isShown = false;
        if (UnitExists("mouseover") and not UnitPlayerControlled("mouseover")) then
            PFEXShowLoots.LootListShown = PFEXShowLoots.ModifyTooltip();
        end
    end
end
