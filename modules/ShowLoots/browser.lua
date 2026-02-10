local compat = pfExtendCompat;
local tooltip_limit = 5;


-- add database shortcuts
local items = pfDB["items"]["data"]
local units = pfDB["units"]["data"]
local objects = pfDB["objects"]["data"]
local refloot = pfDB["refloot"]["data"]
local quests = pfDB["quests"]["data"]
local zones = pfDB["zones"]["loc"]
local openTime = nil;
local windowWidthWithoutID = 400;
local windowWidth = 0;
if PfExtend_Global.ReadSetting("ShowLoots","showIds") then windowWidth = windowWidthWithoutID+60 else windowWidth = windowWidthWithoutID end
    


local function ResultButtonEnter()
    this.tex:SetTexture(1, 1, 1, .1)

    GameTooltip:SetOwner(this, "ANCHOR_LEFT", -10, -5)
    GameTooltip:SetHyperlink("item:" .. this.id .. compat.itemsuffix)
    GameTooltip:Show()
end

local function ResultButtonUpdate()
    this.refreshCount = this.refreshCount + 1

    if not this.itemColor then
        GameTooltip:SetHyperlink("item:" .. this.id .. compat.itemsuffix)
        GameTooltip:Hide()

        local _, _, itemQuality = GetItemInfo(this.id)
        if itemQuality then
            PfExtend_Database["ShowLoots"]["itemQualityData"][this.id] = itemQuality
            local r = ceil(ITEM_QUALITY_COLORS[itemQuality].r * 255)
            local g = ceil(ITEM_QUALITY_COLORS[itemQuality].g * 255)
            local b = ceil(ITEM_QUALITY_COLORS[itemQuality].b * 255)
            this.itemColor = "|c" .. string.format("ff%02x%02x%02x", r, g, b)
        end
    end

    if this.itemColor then
        local custom = pfQuest_server["items"][this.id] and " [|cff33ffcc!|r]" or ""
        this.text:SetText(this.itemColor ..
            "|Hitem:" .. this.id .. compat.itemsuffix .. "|h[" .. this.name .. "]|h|r" .. custom)
        this.text:SetWidth(this.text:GetStringWidth())
    end

    if this.refreshCount > 10 or this.itemColor then
        this:SetScript("OnUpdate", nil)
    end
end

local function ResultButtonClick()
    local link = "item:" .. this.id .. compat.itemsuffix
    local text = (this.itemColor or "|cffffffff") .. "|H" .. link .. "|h[" .. this.name .. "]|h|r"
    SetItemRef(link, text, arg1)
end

local function ResultButtonClickFav()
    local parent = this:GetParent()
    if pfBrowser_fav["items"][parent.id] then
        pfBrowser_fav["items"][parent.id] = nil
        this.icon:SetVertexColor(1, 1, 1, .1)
    else
        pfBrowser_fav["items"][parent.id] = parent.name
        this.icon:SetVertexColor(1, 1, 1, 1)
    end
end

local function ResultButtonLeave()
    if PFEXShowLoots.Browser.selectState then
        PFEXShowLoots.Browser.selectState = "clean"
    end

    if compat.mod(this:GetID(), 2) == 1 then
        this.tex:SetTexture(1, 1, 1, .02)
    else
        this.tex:SetTexture(1, 1, 1, .04)
    end
    GameTooltip:Hide()
end

local function ResultButtonClickSpecial()
    local param = this:GetParent()[this.parameter]
    local meta = { ["addon"] = "PFDB" }
    local maps = {}
    if this.buttonType == "O" or this.buttonType == "U" then
        if this.selectState then
            maps = pfDatabase:SearchItem(this:GetParent().name, meta)
        else
            maps = pfDatabase:SearchItemID(param, meta, nil, { [this.buttonType] = true })
        end
    elseif this.buttonType == "V" then
        maps = pfDatabase:SearchVendor(param, meta)
    end
    pfMap:UpdateNodes()
    pfMap:ShowMapID(pfDatabase:GetBestMap(maps))
end

local function ResultButtonEnterSpecial()
    local id = this:GetParent().id
    local count = 0
    local skip = false

    GameTooltip:SetOwner(PFEXShowLoots.Browser, "ANCHOR_CURSOR")

    -- unit
    if this.buttonType == "U" then
        if items[id]["U"] then
            GameTooltip:SetText(pfExtend_Loc["Looted from"], .3, 1, .8)
            for unitID, chance in pairs(items[id]["U"]) do
                count = count + 1
                if count > tooltip_limit then
                    skip = true
                end
                if units[unitID] and not skip then
                    local name = pfDB.units.loc[unitID]
                    local zone = nil
                    if units[unitID].coords and units[unitID].coords[1] then
                        zone = units[unitID].coords[1][3]
                    end
                    GameTooltip:AddDoubleLine(name, (zone and pfMap:GetMapNameByID(zone) or UNKNOWN), 1, 1, 1, .5, .5, .5)
                end
            end

            -- reference tables
            if items[id]["R"] then
                for ref, chance in pairs(items[id]["R"]) do
                    if refloot[ref] and refloot[ref]["U"] then
                        for unit in pairs(refloot[ref]["U"]) do
                            count = count + 1
                            if count > tooltip_limit then
                                skip = true
                            end
                            if units[unit] and not skip then
                                local name = pfDB.units.loc[unit]
                                local zone = nil
                                if units[unit].coords and units[unit].coords[1] then
                                    zone = units[unit].coords[1][3]
                                end
                                GameTooltip:AddDoubleLine(name, (zone and pfMap:GetMapNameByID(zone) or UNKNOWN), 1, 1, 1,
                                    .5, .5, .5)
                            end
                        end
                    end
                end
            end
        end

        -- object
    elseif this.buttonType == "O" then
        if items[id]["O"] then
            GameTooltip:SetText(pfExtend_Loc["Looted from"], .3, 1, .8)
            for objectID, chance in pairs(items[id]["O"]) do
                count = count + 1
                if count > tooltip_limit then
                    skip = true
                end
                if objects[objectID] and not skip then
                    local name = pfDB.objects.loc[objectID] or objectID
                    local zone = nil
                    if objects[objectID].coords and objects[objectID].coords[1] then
                        zone = objects[objectID].coords[1][3]
                    end
                    GameTooltip:AddDoubleLine(name, (zone and pfMap:GetMapNameByID(zone) or UNKNOWN), 1, 1, 1, .5, .5, .5)
                end
            end

            -- reference tables
            if items[id]["R"] then
                for ref, chance in pairs(items[id]["R"]) do
                    if refloot[ref] and refloot[ref]["O"] then
                        for unit in pairs(refloot[ref]["O"]) do
                            count = count + 1
                            if count > tooltip_limit then
                                skip = true
                            end
                            if objects[unit] and not skip then
                                local name = pfDB.objects.loc[unit]
                                local zone = nil
                                if objects[unit].coords and objects[unit].coords[1] then
                                    zone = objects[unit].coords[1][3]
                                end
                                GameTooltip:AddDoubleLine(name, (zone and pfMap:GetMapNameByID(zone) or UNKNOWN), 1, 1, 1,
                                    .5, .5, .5)
                            end
                        end
                    end
                end
            end
        end

        -- vendor
    elseif this.buttonType == "V" then
        if items[id]["V"] then
            GameTooltip:SetText(pfExtend_Loc["Sold by"], .3, 1, .8)
            for unitID, sellcount in pairs(items[id]["V"]) do
                count = count + 1
                if count > tooltip_limit then
                    skip = true
                end
                if units[unitID] and not skip then
                    local name = pfDB.units.loc[unitID]
                    if sellcount ~= 0 then name = name .. " (" .. sellcount .. ")" end
                    local zone = units[unitID].coords and units[unitID].coords[1] and units[unitID].coords[1][3]
                    GameTooltip:AddDoubleLine(name, (zone and pfMap:GetMapNameByID(zone) or UNKNOWN), 1, 1, 1, .5, .5, .5)
                end
            end
        end
    end

    if count > tooltip_limit then
        GameTooltip:AddLine("\n" .. pfExtend_Loc["ToolTips_and"] .. " " .. (count - tooltip_limit) .. " " .. pfExtend_Loc["ToolTips_others"],
            .8, .8, .8)
    end
    GameTooltip:Show()
end

local function ResultButtonLeaveSpecial()
    GameTooltip:Hide()
end


local function ResultButtonReload(self)
    self.btype = "items";
    self.idText:SetText("ID: " .. self.id)
    local chanceColor = "|c" .. string.format("%02x%02x%02x%02x", 255,
        self.chanceR * 255,
        self.chanceG * 255,
        self.chanceB * 255)
    self.chanceText:SetText(" |cff555555[" .. chanceColor .. string.format("%.2f", self.chance) .. "%|cff555555]")
    if PfExtend_Global.ReadSetting("ShowLoots","showIds")then
        self.idText:Show()
    else
        self.idText:Hide()
    end

    self.itemColor = nil


    -- activate fav buttons if needed
    if pfBrowser_fav and pfBrowser_fav[self.btype] and pfBrowser_fav[self.btype][self.id] then
        self.fav.icon:SetVertexColor(1, 1, 1, 1)
    else
        self.fav.icon:SetVertexColor(1, 1, 1, .1)
    end


    for _, key in ipairs({ "U", "O", "V" }) do
        if items[self.id] and items[self.id][key] then
            self[key]:Show()
        else
            self[key]:Hide()
        end
    end

    self.text:SetText("|cffff5555[?] |cffffffff" .. self.name)

    self.refreshCount = 0
    self:SetScript("OnUpdate", ResultButtonUpdate)


    self.text:SetWidth(self.text:GetStringWidth())
    self:Show()
end



local function RefreshView(i)
    PFEXShowLoots.Browser.scroll.list:Hide()
    PFEXShowLoots.Browser.scroll.list:SetHeight(i * 30)
    PFEXShowLoots.Browser.scroll.list:Show()
    PFEXShowLoots.Browser.scroll.list:GetParent():SetScrollChild(PFEXShowLoots.Browser.scroll.list)
    PFEXShowLoots.Browser.scroll.list:GetParent():SetVerticalScroll(0)

    for j = i + 1, table.getn(PFEXShowLoots.Browser.scroll.buttons) do
        if PFEXShowLoots.Browser.scroll.buttons[j] then
            PFEXShowLoots.Browser.scroll.buttons[j]:Hide()
            PFEXShowLoots.Browser.scroll.buttons[j].id = nil
            PFEXShowLoots.Browser.scroll.buttons[j].name = nil
        end
    end
end

local function ResultButtonCreate(i)
    local f = CreateFrame("Button", nil, PFEXShowLoots.Browser.scroll.list)
    f:SetPoint("TOPLEFT", PFEXShowLoots.Browser.scroll.list, "TOPLEFT", 10, -i * 30 + 5)
    f:SetPoint("BOTTOMRIGHT", PFEXShowLoots.Browser.scroll.list, "TOPRIGHT", 10, -i * 30 - 15)
    f:Hide()
    f:SetID(i)

    f.btype = "items"
    f.pfResultButton = true

    f.tex = f:CreateTexture("BACKGROUND")
    f.tex:SetAllPoints(f)
    f.tex:SetTexture(1, 1, 1, (compat.mod(i, 2) == 1 and .02 or .04))

    -- text properties
    

    

    -- favourite button
    f.fav = CreateFrame("Button", nil, f)
    f.fav:SetHitRectInsets(-3, -3, -3, -3)
    f.fav:SetPoint("LEFT", 0, 0)
    f.fav:SetWidth(16)
    f.fav:SetHeight(16)
    f.fav.icon = f.fav:CreateTexture("OVERLAY")
    f.fav.icon:SetTexture(pfExtend_Path .. "\\compat\\fav")
    f.fav.icon:SetAllPoints(f.fav)

    f.idText = f:CreateFontString("ID", "LOW", "GameFontDisable")
    f.idText:SetPoint("LEFT", f.fav, "RIGHT", 14, 0)

    f.text = f:CreateFontString("Caption", "LOW", "GameFontWhite")
    f.text:SetFont(pfUI.font_default, pfUI_config.global.font_size, "OUTLINE")
    --f.text:SetAllPoints(f)
    if PfExtend_Global.ReadSetting("ShowLoots","showIds") then
        f.text:SetPoint("LEFT", f.fav, "RIGHT", 74, 0)
    else
        f.text:SetPoint("LEFT", f.fav, "RIGHT", 14, 0)
    end
    
    f.chanceText = f:CreateFontString("Chance", "LOW", "GameFontWhite")
    f.chanceText:SetPoint("RIGHT", f, "RIGHT", -62, 0)
    local buttons = {
        ["U"] = { ["offset"] = -5, ["icon"] = "icon_npc", ["parameter"] = "id", },
        ["O"] = { ["offset"] = -24, ["icon"] = "icon_object", ["parameter"] = "id", },
        ["V"] = { ["offset"] = -43, ["icon"] = "icon_vendor", ["parameter"] = "name", },
    }

    for button, settings in pairs(buttons) do
        f[button] = CreateFrame("Button", nil, f)
        f[button]:SetHitRectInsets(-3, -3, -3, -3)
        f[button]:SetPoint("RIGHT", settings.offset, 0)
        f[button]:SetWidth(16)
        f[button]:SetHeight(16)

        f[button].buttonType = button
        f[button].parameter = settings.parameter

        f[button].icon = f[button]:CreateTexture("OVERLAY")
        f[button].icon:SetAllPoints(f[button])
        f[button].icon:SetTexture(pfExtend_Path .. "\\compat\\" .. settings.icon)

        f[button]:SetScript("OnEnter", ResultButtonEnterSpecial)
        f[button]:SetScript("OnLeave", ResultButtonLeaveSpecial)
        f[button]:SetScript("OnClick", ResultButtonClickSpecial)
    end
    

    -- bind functions
    f.Reload = ResultButtonReload
    f:SetScript("OnLeave", ResultButtonLeave)
    f:SetScript("OnEnter", ResultButtonEnter)
    f:SetScript("OnClick", ResultButtonClick)
    f.fav:SetScript("OnClick", ResultButtonClickFav)

    return f
end




PFEXShowLoots.Browser = CreateFrame("Frame", "showLootsBrowser", UIParent)
PFEXShowLoots.Browser:Hide()
PFEXShowLoots.Browser:SetWidth(windowWidth)
PFEXShowLoots.Browser:SetHeight(480)
PFEXShowLoots.Browser:SetPoint("CENTER", 0, 0)
PFEXShowLoots.Browser:SetFrameStrata("FULLSCREEN_DIALOG")
PFEXShowLoots.Browser:SetMovable(true)
PFEXShowLoots.Browser:EnableMouse(true)
PFEXShowLoots.Browser:RegisterEvent("PLAYER_ENTERING_WORLD")


PFEXShowLoots.Browser:SetScript("OnHide", function()
    PFEXShowLoots.isBrowse = false;
    PFEXShowLoots.closeTime = GetTime();
end)
PFEXShowLoots.Browser:SetScript("OnMouseDown", function()
    this:StartMoving()

end)

PFEXShowLoots.Browser:SetScript("OnMouseUp", function()
    this:StopMovingOrSizing()
end)

PFEXShowLoots.Browser:SetScript("OnUpdate", function()
    PFEXShowLoots.Browser.altPressed = false;
    if not PFEXShowLoots.isBrowse then return end
    if (this.throttle or .05) > GetTime() then return else this.throttle = GetTime() + .05 end
    if GetTime() - openTime > .2 then
        PFEXShowLoots.Browser.altPressed = IsAltKeyDown() and IsControlKeyDown()
    end
    if PFEXShowLoots.Browser.altPressed then this:Hide() end
end)

pfUI.api.CreateBackdrop(PFEXShowLoots.Browser, nil, true, 0.75)

PFEXShowLoots.Browser.title = PFEXShowLoots.Browser:CreateFontString("Status", "LOW", "GameFontNormal")
PFEXShowLoots.Browser.title:SetFontObject(GameFontWhite)
PFEXShowLoots.Browser.title:SetPoint("TOP", PFEXShowLoots.Browser, "TOP", 0, -8)
PFEXShowLoots.Browser.title:SetJustifyH("LEFT")
PFEXShowLoots.Browser.title:SetFont(pfUI.font_default, 14)
PFEXShowLoots.Browser.title:SetText("|cff33ffccpf|rExtend-"..pfExtend_Loc["windowTitle_ShowLoots"])

PFEXShowLoots.Browser.MobName = PFEXShowLoots.Browser:CreateFontString("Status", "LOW", "GameFontNormal")
PFEXShowLoots.Browser.MobName:SetFontObject(GameFontWhite)
PFEXShowLoots.Browser.MobName:SetPoint("TOP", PFEXShowLoots.Browser, "TOP", 0, -32)
PFEXShowLoots.Browser.MobName:SetJustifyH("CENTER")
PFEXShowLoots.Browser.MobName:SetFont(pfUI.font_default, 18)

PFEXShowLoots.Browser.close = CreateFrame("Button", "showLootsBrowserClose", PFEXShowLoots.Browser)
PFEXShowLoots.Browser.close:SetPoint("TOPRIGHT", -5, -5)
PFEXShowLoots.Browser.close:SetHeight(20)
PFEXShowLoots.Browser.close:SetWidth(20)
PFEXShowLoots.Browser.close.texture = PFEXShowLoots.Browser.close:CreateTexture("pfQuestionDialogCloseTex")
PFEXShowLoots.Browser.close.texture:SetTexture(pfExtend_Path .. "\\compat\\close")
PFEXShowLoots.Browser.close.texture:ClearAllPoints()
PFEXShowLoots.Browser.close.texture:SetVertexColor(1, .25, .25, 1)
PFEXShowLoots.Browser.close.texture:SetPoint("TOPLEFT", PFEXShowLoots.Browser.close, "TOPLEFT", 4, -4)
PFEXShowLoots.Browser.close.texture:SetPoint("BOTTOMRIGHT", PFEXShowLoots.Browser.close, "BOTTOMRIGHT", -4, 4)
PFEXShowLoots.Browser.close:SetScript("OnClick", function()
    this:GetParent():Hide()
end)
EnableTooltips(PFEXShowLoots.Browser.close, {
    pfExtend_Loc["Close"],
    pfExtend_Loc["Hide browser window"],
})
pfUI.api.SkinButton(PFEXShowLoots.Browser.close, 1, .5, .5)

PFEXShowLoots.Browser.search = CreateFrame("Button", "showLootsSearchOpen", PFEXShowLoots.Browser)
PFEXShowLoots.Browser.search:SetPoint("TOPRIGHT", -30, -5)
PFEXShowLoots.Browser.search:SetHeight(20)
PFEXShowLoots.Browser.search:SetWidth(20)
PFEXShowLoots.Browser.search.texture = PFEXShowLoots.Browser.search:CreateTexture("showLootsSearchOpenTex")
PFEXShowLoots.Browser.search.texture:SetTexture(pfExtend_Path .. "\\compat\\tracker_search")
PFEXShowLoots.Browser.search.texture:ClearAllPoints()
PFEXShowLoots.Browser.search.texture:SetPoint("TOPLEFT", PFEXShowLoots.Browser.search, "TOPLEFT", 2, -2)
PFEXShowLoots.Browser.search.texture:SetPoint("BOTTOMRIGHT", PFEXShowLoots.Browser.search, "BOTTOMRIGHT", -2, 2)
PFEXShowLoots.Browser.search:SetScript("OnClick", function()
    PFEXShowLoots.Browser:Hide()
    pfBrowser:Show()
end)
EnableTooltips(PFEXShowLoots.Browser.search, {
    pfExtend_Loc["Search"],
    pfExtend_Loc["Show pfQuest Browser"],
})
pfUI.api.SkinButton(PFEXShowLoots.Browser.search)

PFEXShowLoots.Browser.setting = CreateFrame("Button", "showLootsSettingOpen", PFEXShowLoots.Browser)
PFEXShowLoots.Browser.setting:SetPoint("TOPRIGHT", -55, -5)
PFEXShowLoots.Browser.setting:SetHeight(20)
PFEXShowLoots.Browser.setting:SetWidth(20)
PFEXShowLoots.Browser.setting.texture = PFEXShowLoots.Browser.setting:CreateTexture("showLootsSettingOpenTex")
PFEXShowLoots.Browser.setting.texture:SetTexture(pfExtend_Path .. "\\compat\\tracker_settings")
PFEXShowLoots.Browser.setting.texture:ClearAllPoints()
PFEXShowLoots.Browser.setting.texture:SetPoint("TOPLEFT", PFEXShowLoots.Browser.setting, "TOPLEFT", 2, -2)
PFEXShowLoots.Browser.setting.texture:SetPoint("BOTTOMRIGHT", PFEXShowLoots.Browser.setting, "BOTTOMRIGHT", -2, 2)
PFEXShowLoots.Browser.setting:SetScript("OnClick", function()
    PFEXShowLoots.Browser:Hide()
    pfExtendConfig:Show()
    CaptionClick("ShowLoots")
end)
EnableTooltips(PFEXShowLoots.Browser.setting, {
    pfExtend_Loc["Setting"],
    pfExtend_Loc["Open Config Window"],
})
pfUI.api.SkinButton(PFEXShowLoots.Browser.setting)

PFEXShowLoots.Browser.scroll = pfUI.api.CreateScrollFrame("showLootsBrowserScroll", PFEXShowLoots.Browser)
PFEXShowLoots.Browser.scroll:SetPoint("TOPLEFT", PFEXShowLoots.Browser, "TOPLEFT", 10, -65)
PFEXShowLoots.Browser.scroll:SetPoint("BOTTOMRIGHT", PFEXShowLoots.Browser, "BOTTOMRIGHT", -10, 10)
PFEXShowLoots.Browser.scroll:Show()
PFEXShowLoots.Browser.scroll.buttons = {}
PFEXShowLoots.Browser.scroll.backdrop = CreateFrame("Frame", "showLootsBrowserScrollBackdrop", PFEXShowLoots.Browser.scroll)
PFEXShowLoots.Browser.scroll.backdrop:SetFrameLevel(1)
PFEXShowLoots.Browser.scroll.backdrop:SetPoint("TOPLEFT", PFEXShowLoots.Browser.scroll, "TOPLEFT", -5, 5)
PFEXShowLoots.Browser.scroll.backdrop:SetPoint("BOTTOMRIGHT", PFEXShowLoots.Browser.scroll, "BOTTOMRIGHT", 5, -5)
pfUI.api.CreateBackdrop(PFEXShowLoots.Browser.scroll.backdrop, nil, true)
PFEXShowLoots.Browser.scroll.list = pfUI.api.CreateScrollChild("showLootsBrowserScrollScroll", PFEXShowLoots.Browser.scroll)
PFEXShowLoots.Browser.scroll.list:SetWidth(PFEXShowLoots.Browser:GetWidth()-40)

PFEXShowLoots.Browser:SetScript("OnShow", function()
    PFEXShowLoots.isBrowse = true;
    openTime = GetTime();
    PFEXShowLoots.Browser.MobName:SetText(PFEXShowLoots.focus_name)
    local i = 0
    for _, l in pairs(PFEXShowLoots.LootListShown) do
        local id, chance, r, g, b = unpack(l)
        i = i + 1
        PFEXShowLoots.Browser.scroll.buttons[i] = PFEXShowLoots.Browser.scroll.buttons[i] or ResultButtonCreate(i)
        PFEXShowLoots.Browser.scroll.buttons[i].id = id
        PFEXShowLoots.Browser.scroll.buttons[i].name = pfDB.items.loc[id]
        PFEXShowLoots.Browser.scroll.buttons[i].chance = chance
        PFEXShowLoots.Browser.scroll.buttons[i].chanceR = r
        PFEXShowLoots.Browser.scroll.buttons[i].chanceG = g
        PFEXShowLoots.Browser.scroll.buttons[i].chanceB = b
        PFEXShowLoots.Browser.scroll.buttons[i]:Reload()
    end
    RefreshView(i)
end)


