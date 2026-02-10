pfExtendConfig = CreateFrame("Frame", "pfExtendConfig", UIParent)
pfExtendConfig.Captions = { "About", "ShowLoots", "QuestHelper" }
local Captions = {}
local compat = pfExtendCompat;
local Tabs = {}
local change = {}




ShowTooltip = function()
    if not this.tooltips then return end
    GameTooltip_SetDefaultAnchor(GameTooltip, this)
    GameTooltip:ClearLines()
    for k, v in pairs(this.tooltips) do
        if k == 1 then
            GameTooltip:AddLine(v, 1, 1, 1)
        else
            GameTooltip:AddLine(v)
        end
    end
    GameTooltip:Show()
end
EnableTooltips = function(frame, tooltips)
    frame.tooltips = tooltips
    frame:SetScript("OnEnter", ShowTooltip)
    frame:SetScript("OnLeave", function() GameTooltip:Hide() end)
end








pfExtendConfig:Hide()
pfExtendConfig:SetWidth(600)
pfExtendConfig:SetHeight(400)
pfExtendConfig:SetPoint("CENTER", 0, 0)
pfExtendConfig:SetFrameStrata("DIALOG")
pfExtendConfig:SetMovable(true)
pfExtendConfig:EnableMouse(true)
pfExtendConfig:RegisterEvent("PLAYER_ENTERING_WORLD")


pfUI.api.CreateBackdrop(pfExtendConfig, nil, true, 0.75)
--table.insert(UISpecialFrames, "pfExtendConfig")

pfExtendConfig.title = pfExtendConfig:CreateFontString("Status", "LOW", "GameFontNormal")
pfExtendConfig.title:SetFontObject(GameFontWhite)
pfExtendConfig.title:SetPoint("TOP", pfExtendConfig, "TOP", 0, -8)
pfExtendConfig.title:SetJustifyH("LEFT")
pfExtendConfig.title:SetFont(pfUI.font_default, 18)
pfExtendConfig.title:SetText("|cff33ffccpf|rExtend-" .. pfExtend_Loc["windowTitle_Config"])

pfExtendConfig.close = CreateFrame("Button", "pfExtendConfigClose", pfExtendConfig)
pfExtendConfig.close:SetPoint("TOPRIGHT", -5, -5)
pfExtendConfig.close:SetHeight(20)
pfExtendConfig.close:SetWidth(20)
pfExtendConfig.close.texture = pfExtendConfig.close:CreateTexture("pfExtendConfigCloseTex")
pfExtendConfig.close.texture:SetTexture(pfExtend_Path .. "\\compat\\close")
pfExtendConfig.close.texture:ClearAllPoints()
pfExtendConfig.close.texture:SetVertexColor(1, .25, .25, 1)
pfExtendConfig.close.texture:SetPoint("TOPLEFT", pfExtendConfig.close, "TOPLEFT", 4, -4)
pfExtendConfig.close.texture:SetPoint("BOTTOMRIGHT", pfExtendConfig.close, "BOTTOMRIGHT", -4, 4)
pfExtendConfig.close:SetScript("OnClick", function()
    this:GetParent():Hide()
end)
EnableTooltips(pfExtendConfig.close, {
    pfExtend_Loc["Close"],
    pfExtend_Loc["Hide browser window"],
})
pfUI.api.SkinButton(pfExtendConfig.close, 1, .5, .5)

pfExtendConfig.CaptionsFrame = pfUI.api.CreateScrollFrame("pfExtendConfigCaptions", pfExtendConfig)
pfExtendConfig.CaptionsFrame:SetPoint("TOPLEFT", pfExtendConfig, "TOPLEFT", 10, -40)
pfExtendConfig.CaptionsFrame:SetPoint("BOTTOMRIGHT", pfExtendConfig, "BOTTOM", -100, 10)
pfExtendConfig.CaptionsFrame:Show()
pfExtendConfig.CaptionsFrame.backdrop = CreateFrame("Frame", "pfExtendConfigCaptionsBackdrop",
    pfExtendConfig.CaptionsFrame)
pfExtendConfig.CaptionsFrame.backdrop:SetFrameLevel(1)
pfExtendConfig.CaptionsFrame.backdrop:SetPoint("TOPLEFT", pfExtendConfig.CaptionsFrame, "TOPLEFT", -5, 5)
pfExtendConfig.CaptionsFrame.backdrop:SetPoint("BOTTOMRIGHT", pfExtendConfig.CaptionsFrame, "BOTTOMRIGHT", 5, -5)
pfUI.api.CreateBackdrop(pfExtendConfig.CaptionsFrame.backdrop, nil, true)
pfExtendConfig.CaptionsFrame.backdrop:SetBackdropColor(0, 0, 0, 0.75)
pfExtendConfig.CaptionsFrame.list = pfUI.api.CreateScrollChild("pfExtendConfigCaptionsScroll",
    pfExtendConfig.CaptionsFrame)
pfExtendConfig.CaptionsFrame.list:SetWidth(180)






local function ButtonLeave()
    if pfExtendConfig.selectState then
        pfExtendConfig.selectState = "clean"
    end
    if compat.mod(this:GetID(), 2) == 1 then
        this.tex:SetTexture(1, 1, 1, .02)
    else
        this.tex:SetTexture(1, 1, 1, .04)
    end
    GameTooltip:Hide()
end

local function ButtonEnter()
    this.tex:SetTexture(1, 1, 1, .1)
end


CaptionClick = function(caption)
    for id, frame in pairs(pfExtendConfig.tabs) do
        frame:Hide()
    end
    for c, frame in pairs(Captions) do
        frame.text:SetTextColor(1, 1, 1, .7)
    end
    Captions[caption].text:SetTextColor(.2, 1, .8, 1)
    Captions[caption]:Hide()
    Captions[caption]:Show()
    pfExtendConfig.tabs[caption]:Show()
end



local function RefreshCaption(i, caption)
    if Tabs[caption] == nil then
        Captions[caption] = CreateFrame("Button", nil, pfExtendConfig.CaptionsFrame.list)
        Captions[caption]:SetPoint("TOPLEFT", pfExtendConfig.CaptionsFrame.list, "TOPLEFT", 5, -i * 25 + 15)
        Captions[caption]:SetPoint("BOTTOMRIGHT", pfExtendConfig.CaptionsFrame.list, "TOPRIGHT", 5, -i * 25 - 5)
        Captions[caption]:SetID(i)
        Captions[caption].caption = caption;
        Captions[caption].tex = Captions[caption]:CreateTexture("BACKGROUND")
        Captions[caption].tex:SetAllPoints(Captions[caption])
        Captions[caption].tex:SetTexture(1, 1, 1, (compat.mod(i, 2) == 1 and .02 or .04))
        -- text properties
        Captions[caption].text = Captions[caption]:CreateFontString("Caption", "LOW", "GameFontWhite")
        Captions[caption].text:SetFont(pfUI.font_default, pfUI_config.global.font_size, "OUTLINE")
        Captions[caption].text:SetPoint("LEFT", Captions[caption], "LEFT", 20, 0)
        Captions[caption].text:SetText(pfExtend_Loc["Config_" .. caption])
        pfUI.api.SkinButton(Captions[caption])
        Captions[caption]:SetScript("OnLeave", ButtonLeave)
        Captions[caption]:SetScript("OnEnter", ButtonEnter)

        Captions[caption]:SetScript("OnClick", function()
            CaptionClick(caption)
        end)
        Captions[caption]:Show()
    end
end





CreateTabsWindow = function(fname)
    if not pfExtendConfig.tabs then pfExtendConfig.tabs = {} end
    pfExtendConfig.tabs[fname] = pfUI.api.CreateScrollFrame("pfExtendConfig" .. fname, pfExtendConfig)
    pfExtendConfig.tabs[fname]:SetPoint("TOPLEFT", pfExtendConfig, "TOP", -80, -40)
    pfExtendConfig.tabs[fname]:SetPoint("BOTTOMRIGHT", pfExtendConfig, "BOTTOMRIGHT", -10, 10)
    pfExtendConfig.tabs[fname]:Hide()
    pfExtendConfig.tabs[fname].buttons = {}

    pfExtendConfig.tabs[fname].backdrop = CreateFrame("Frame", "pfExtendConfig" .. fname .. "Backdrop",
        pfExtendConfig.tabs[fname])
    pfExtendConfig.tabs[fname].backdrop:SetFrameLevel(1)
    pfExtendConfig.tabs[fname].backdrop:SetPoint("TOPLEFT", pfExtendConfig.tabs[fname], "TOPLEFT", -5, 5)
    pfExtendConfig.tabs[fname].backdrop:SetPoint("BOTTOMRIGHT", pfExtendConfig.tabs[fname], "BOTTOMRIGHT", 5, -5)
    pfUI.api.CreateBackdrop(pfExtendConfig.tabs[fname].backdrop, nil, true)

    pfExtendConfig.tabs[fname].list = pfUI.api.CreateScrollChild("pfExtendConfig" .. fname .. "Scroll",
        pfExtendConfig.tabs[fname])
    pfExtendConfig.tabs[fname].list:SetWidth(360)
    return pfExtendConfig.tabs[fname]
end


function EntryUpdate()
    -- detect and skip during dropdowns
    local focus = GetMouseFocus()
    if focus and focus.parent and focus.parent.menu then
        if this.over then
            this.tex:Hide()
            this.over = nil
        end
        return
    end

    if MouseIsOver(this) and not this.over then
        this.tex:Show()
        this.over = true
    elseif not MouseIsOver(this) and this.over then
        this.tex:Hide()
        this.over = nil
    end
end

RefreshTabs = function(caption, i, tab)
    if Tabs[caption] == nil then Tabs[caption] = {} end
    if Tabs[caption][tab] == nil then
        if type(PfExtend_Config_Template[caption][tab]) == "nil" then return end

        Tabs[caption][tab] = CreateFrame("Button", nil, pfExtendConfig.tabs[caption].list)
        Tabs[caption][tab]:SetPoint("TOPLEFT", pfExtendConfig.tabs[caption].list, "TOPLEFT", 5, -i * 25 + 15)
        Tabs[caption][tab]:SetPoint("BOTTOMRIGHT", pfExtendConfig.tabs[caption].list, "TOPRIGHT", 5, -i * 25 - 5)
        Tabs[caption][tab]:SetID(i)
        Tabs[caption][tab].saveType = type(PfExtend_Config_Template[caption][tab]);

        Tabs[caption][tab].caption = caption;
        Tabs[caption][tab].tab = tab;

        --Tabs[caption][tab]:SetScript("OnUpdate", EntryUpdate)
        Tabs[caption][tab].tex = Tabs[caption][tab]:CreateTexture("BACKGROUND")
        Tabs[caption][tab].tex:SetAllPoints()
        Tabs[caption][tab].tex:SetTexture(1, 1, 1, .05)
        Tabs[caption][tab].tex:Hide()
        -- text properties
        Tabs[caption][tab].text = Tabs[caption][tab]:CreateFontString("Caption", "LOW", "GameFontWhite")
        Tabs[caption][tab].text:SetFont(pfUI.font_default, pfUI_config.global.font_size, "OUTLINE")
        Tabs[caption][tab].text:SetPoint("LEFT", Tabs[caption][tab], "LEFT", 20, 0)
        Tabs[caption][tab].text:SetText(pfExtend_Loc["Config_" .. caption .. "_" .. tab])





        if Tabs[caption][tab].saveType == "number" or Tabs[caption][tab].saveType == "string" then
            Tabs[caption][tab].input = CreateFrame("EditBox", nil, Tabs[caption][tab])
            Tabs[caption][tab].input:SetTextColor(.2, 1, .8, 1)
            Tabs[caption][tab].input:SetJustifyH("RIGHT")
            Tabs[caption][tab].input:SetTextInsets(5, 5, 5, 5)
            Tabs[caption][tab].input:SetWidth(100)
            Tabs[caption][tab].input:SetHeight(16)
            Tabs[caption][tab].input:SetPoint("RIGHT", -20, 0)
            Tabs[caption][tab].input:SetFontObject(GameFontNormal)
            Tabs[caption][tab].input:SetAutoFocus(false)
            Tabs[caption][tab].input:SetScript("OnEscapePressed", function(self)
                this:ClearFocus()
            end)

            Tabs[caption][tab].input:SetText(PfExtend_Global.ReadSetting(caption, tab))

            Tabs[caption][tab].input:SetScript("OnTextChanged", function(self)
                if change[caption] == nil then change[caption] = {} end
                if Tabs[caption][tab].saveType == "number" and tonumber(this:GetText()) then
                    change[caption][tab] = math.max(0, math.floor(tonumber(this:GetText())))
                end
            end)

            pfUI.api.CreateBackdrop(Tabs[caption][tab].input, nil, true)
        elseif Tabs[caption][tab].saveType == "boolean" then
            Tabs[caption][tab].input = CreateFrame("CheckButton", nil, Tabs[caption][tab], "UICheckButtonTemplate")
            Tabs[caption][tab]:SetNormalTexture("")
            Tabs[caption][tab]:SetPushedTexture("")
            Tabs[caption][tab]:SetHighlightTexture("")
            pfUI.api.CreateBackdrop(Tabs[caption][tab].input, nil, true)
            Tabs[caption][tab].input:SetWidth(16)
            Tabs[caption][tab].input:SetHeight(16)
            Tabs[caption][tab].input:SetPoint("RIGHT", -20, 0)

            if PfExtend_Global.ReadSetting(caption, tab) == true then
                Tabs[caption][tab].input:SetChecked()
            end
            Tabs[caption][tab].input:SetScript("OnClick", function()
                if change[caption] == nil then change[caption] = {} end

                if this:GetChecked() then
                    change[caption][tab] = true;
                else
                    change[caption][tab] = false;
                end
            end)
        elseif Tabs[caption][tab].saveType == "table" then
            print(1)
            Tabs[caption][tab].input = pfUI.api.CreateDropDownButton("Config_DropDown_" .. caption .. "_" .. tab,
                Tabs[caption][tab])
            print(2)
            Tabs[caption][tab].input:SetBackdrop(nil)
            Tabs[caption][tab].input.menuframe:SetParent(pfExtendConfig)

            Tabs[caption][tab].input:SetPoint("RIGHT", -20, 0)
            Tabs[caption][tab].input:SetWidth(180)
            Tabs[caption][tab].input:SetMenu(function()
                local menu = {}
                for i, k in ipairs(PfExtend_Config_Template[caption][tab]["selectTable"]) do
                    local entry = {}
                    entry.text = pfExtend_Loc["Config_" .. caption .. "_" .. tab .. "_" .. k]
                    entry.func = function()
                        pfExtend_change_callback(caption, tab,
                            PfExtend_Config_Template[caption][tab]["selectTable"][this.id])
                    end
                    if PfExtend_Global.ReadSetting(caption, tab) == k then
                        Tabs[caption][tab].input.current = i
                    end
                    table.insert(menu, entry)
                end
                return menu
            end)
            Tabs[caption][tab].input:SetSelection(Tabs[caption][tab].input.current)
        elseif Tabs[caption][tab].saveType == "function" and type(PfExtend_Config_Template[caption][tab]()) == "table" then
            if PfExtend_Config_Template[caption][tab]()["func"] == nil then
                Tabs[caption][tab].input = Tabs[caption][tab]:CreateFontString("Caption", "LOW", "GameFontWhite")
                Tabs[caption][tab].input:SetFont(pfUI.font_default, pfUI_config.global.font_size, "OUTLINE")
                Tabs[caption][tab].input:SetTextColor(.2, 1, .8, 1)
                Tabs[caption][tab].input:SetPoint("RIGHT", -20, 0)
                Tabs[caption][tab].input:SetText(PfExtend_Config_Template[caption][tab]()["text"])
            else
                Tabs[caption][tab].input = CreateFrame("Button", nil, Tabs[caption][tab])
                Tabs[caption][tab].input:SetPoint("RIGHT", -20, 0)

                Tabs[caption][tab].input:SetHeight(16)
                Tabs[caption][tab].input.text = Tabs[caption][tab].input:CreateFontString("Caption", "LOW",
                    "GameFontWhite")
                Tabs[caption][tab].input.text:SetFont(pfUI.font_default, pfUI_config.global.font_size, "OUTLINE")
                Tabs[caption][tab].input.text:SetPoint("CENTER", 0, 0)
                Tabs[caption][tab].input.text:SetText(PfExtend_Config_Template[caption][tab]()["text"])
                Tabs[caption][tab].input:SetWidth(Tabs[caption][tab].input.text:GetWidth() + 20)
                Tabs[caption][tab].input:SetScript("OnClick", function()
                    this:Disable()
                    local text = PfExtend_Config_Template[caption][tab]()["func"]()
                    if text then
                        this.text:SetText(text)
                        this:SetWidth(this.text:GetWidth() + 20)
                    end
                    this:Enable()
                end)
                pfUI.api.SkinButton(Tabs[caption][tab].input)
            end
        end


        pfUI.api.SkinButton(Tabs[caption][tab])
        Tabs[caption][tab]:SetScript("OnLeave", ButtonLeave)
        Tabs[caption][tab]:SetScript("OnEnter", ButtonEnter)
        Tabs[caption][tab]:Show()
    end
end


pfExtendConfig:SetScript("OnHide", function()
    if change == {} then return end
    for caption, tabs in pairs(change) do
        for tab, value in pairs(tabs) do
            PfExtend_Config[caption][tab] = value
        end
    end
    change = {}
end)

pfExtendConfig:SetScript("OnMouseDown", function()
    this:StartMoving()
end)

pfExtendConfig:SetScript("OnMouseUp", function()
    this:StopMovingOrSizing()
end)

pfExtendConfig:SetScript("OnUpdate", function()

end)

pfExtendConfig:SetScript("OnShow", function()
    change = {}
    for i, caption in ipairs(pfExtendConfig.Captions) do
        RefreshCaption(i, caption)
        CreateTabsWindow(caption)
        if type(PfExtend_Config_Index[caption]) == "table" then
            for j, k in ipairs(PfExtend_Config_Index[caption]) do
                RefreshTabs(caption, j, k)
            end
        end
    end
    CaptionClick("About")
end)



pfExtend_change_callback = function(caption, tab, value)
    if change[caption] == nil then change[caption] = {} end
    change[caption][tab] = value
end
