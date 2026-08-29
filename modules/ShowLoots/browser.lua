local compat = pfExtendCompat;
local tooltip_limit = 5;
local currentSortBy = "chance"; -- 当前排序方式: chance, id, quality
local currentSortOrder = "desc"; -- 当前排序顺序: asc(升序), desc(降序)

-- The rows the window is currently showing. Captured when the window opens so
-- the display survives the cursor leaving the mob: PFEXShowLoots.LootListShown
-- is rebuilt from the live mouseover and is emptied the moment you look away.
-- Assignment there replaces the table rather than clearing it, so holding this
-- reference is enough to keep the snapshot intact.
local shownLootList = {}

-- Forward declaration: the sort buttons are created before this is defined.
local PopulateLootList


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

-- 更新排序按钮的文本和状态
local function UpdateSortButtonText(btn)
    local baseText = pfExtend_Loc["Sort_" .. btn.sortByKey]
    if btn.sortBy == currentSortBy then
        -- 当前选中的按钮显示排序方向箭头
        local arrow = currentSortOrder == "asc" and "↑" or "↓"
        btn.text:SetText(baseText .. " " .. arrow)
    else
        btn.text:SetText(baseText)
    end
end

-- 创建排序按钮
local function CreateSortButton(name, textKey, sortBy, xOffset)
    local btn = CreateFrame("Button", nil, PFEXShowLoots.Browser)
    btn:SetPoint("TOPLEFT", PFEXShowLoots.Browser, "TOPLEFT", 15 + xOffset, -55)
    btn:SetHeight(20)
    btn:SetWidth(65)
    
    btn.text = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    btn.text:SetFont(pfUI.font_default, 12, "OUTLINE")
    btn.text:SetPoint("CENTER", btn, "CENTER", 0, 0)
    
    btn.sortBy = sortBy
    btn.sortByKey = textKey
    
    -- 高亮背景
    btn.tex = btn:CreateTexture("BACKGROUND")
    btn.tex:SetAllPoints(btn)
    btn.tex:SetTexture(1, 1, 1, 0.1)
    
    pfUI.api.SkinButton(btn)
    
    btn:SetScript("OnClick", function()
        if currentSortBy == sortBy then
            -- 如果点击的是当前排序方式，则切换排序顺序
            currentSortOrder = (currentSortOrder == "desc") and "asc" or "desc"
        else
            -- 切换到新的排序方式，默认掉率降序，ID升序，品质降序
            currentSortBy = sortBy
            if sortBy == "chance" or sortBy == "quality" then
                currentSortOrder = "desc"
            else
                currentSortOrder = "asc"
            end
        end
        
        -- 刷新所有按钮的显示状态和文本
        for _, button in ipairs({"sortByChance", "sortById", "sortByQuality"}) do
            local b = PFEXShowLoots.Browser[button]
            if b then
                b.tex:SetTexture(1, 1, 1, b.sortBy == currentSortBy and 0.3 or 0.1)
                UpdateSortButtonText(b)
            end
        end
        
        -- 重新显示当前掉落列表
        -- Repopulate in place. This used to Hide() then Show() to re-trigger
        -- OnShow, which also re-read the live mouseover list -- by then empty.
        PopulateLootList()
    end)
    
    return btn
end

-- 创建三个排序按钮
PFEXShowLoots.Browser.sortByChance = CreateSortButton("sortByChance", "Chance", "chance", 0)
PFEXShowLoots.Browser.sortById = CreateSortButton("sortById", "ID", "id", 70)
PFEXShowLoots.Browser.sortByQuality = CreateSortButton("sortByQuality", "Quality", "quality", 140)

-- 排序函数
local function SortLootList(lootList)
    -- 首先分离star物品和非star物品
    local starred = {}
    local normal = {}

    if not lootList then return {} end

    for _, l in ipairs(lootList) do
        local id = l[1]
        if pfBrowser_fav and pfBrowser_fav["items"] and pfBrowser_fav["items"][id] then
            table.insert(starred, l)
        else
            table.insert(normal, l)
        end
    end
    
    -- 根据当前排序方式排序普通物品
    local sortFunc
    if currentSortBy == "chance" then
        if currentSortOrder == "desc" then
            -- 按掉率降序
            sortFunc = function(a, b)
                return a[2] > b[2]
            end
        else
            -- 按掉率升序
            sortFunc = function(a, b)
                return a[2] < b[2]
            end
        end
    elseif currentSortBy == "id" then
        if currentSortOrder == "asc" then
            -- 按ID升序
            sortFunc = function(a, b)
                return a[1] < b[1]
            end
        else
            -- 按ID降序
            sortFunc = function(a, b)
                return a[1] > b[1]
            end
        end
    elseif currentSortBy == "quality" then
        -- 按品质排序
        sortFunc = function(a, b)
            local _, _, qualityA = GetItemInfo(a[1])
            local _, _, qualityB = GetItemInfo(b[1])
            -- 如果缓存中没有，尝试从数据库获取
            if qualityA == nil then
                qualityA = PfExtend_Database["ShowLoots"]["itemQualityData"][a[1]]
            end
            if qualityB == nil then
                qualityB = PfExtend_Database["ShowLoots"]["itemQualityData"][b[1]]
            end
            -- 如果都没有，默认为0（灰色）
            qualityA = qualityA or 0
            qualityB = qualityB or 0
            
            if currentSortOrder == "desc" then
                return qualityA > qualityB
            else
                return qualityA < qualityB
            end
        end
    end
    
    -- 排序star物品（使用相同的排序方式）
    table.sort(starred, sortFunc)
    table.sort(normal, sortFunc)
    
    -- 合并结果：star物品在前，普通物品在后
    local result = {}
    for _, l in ipairs(starred) do
        table.insert(result, l)
    end
    for _, l in ipairs(normal) do
        table.insert(result, l)
    end
    
    return result
end

-- Sort and draw the snapshot. Called on open and again after every sort click;
-- deliberately does not touch PFEXShowLoots.LootListShown, which by then
-- reflects wherever the cursor happens to be rather than the mob on display.
PopulateLootList = function()
    -- 更新排序按钮高亮状态和文本
    for _, button in ipairs({"sortByChance", "sortById", "sortByQuality"}) do
        local b = PFEXShowLoots.Browser[button]
        if b then
            b.tex:SetTexture(1, 1, 1, b.sortBy == currentSortBy and 0.3 or 0.1)
            UpdateSortButtonText(b)
        end
    end

    -- 排序掉落列表
    local sortedLootList = SortLootList(shownLootList)

    local i = 0
    for _, l in ipairs(sortedLootList) do
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
end

PFEXShowLoots.Browser:SetScript("OnShow", function()
    PFEXShowLoots.isBrowse = true;
    openTime = GetTime();
    PFEXShowLoots.Browser.MobName:SetText(PFEXShowLoots.focus_name)

    -- Take the snapshot here, while the mouseover that produced the list is
    -- still the one under the cursor.
    shownLootList = PFEXShowLoots.LootListShown or {}

    PopulateLootList()
end)