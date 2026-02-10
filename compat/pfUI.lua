-- Initialize pfUI core table for non-pfUI environments
if not pfUI then
  pfUI = {
    ["api"] = {},
    ["cache"] = {},
    ["backdrop"] = {
      bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
      edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
      tile = true, tileSize = 16, edgeSize = 16,
      insets = { left = 3, right = 3, top = 3, bottom = 3 }
    },
    ["backdrop_small"] = {
      bgFile = "Interface\\BUTTONS\\WHITE8X8", tile = false, tileSize = 0,
      edgeFile = "Interface\\BUTTONS\\WHITE8X8", edgeSize = 1,
      insets = {left = 0, right = 0, top = 0, bottom = 0},
    },
    ["font_default"] = STANDARD_TEXT_FONT,
   }

  pfUI_config = {
    ["appearance"] = {
      ["border"] = {
        ["default"] = "3",
      }
    },
    ["global"] = {
      ["font_size"] = 12
    },
    -- fix for old questie releases
    ["disabled"] = {
      ["minimap"] = "1"
    }
  }

  pfUI.api.emulated = true
end

pfUI.api.SetButtonFont = pfUI.api.SetButtonFont or function(button, font, size, flags)
  if button.SetFont then
    -- vanilla + tbc
    button:SetFont(font, size, flags)
  else
    -- wotlk
    local buttonText = button:GetFontString()
    if buttonText then
      buttonText:SetFont(font, size, flags)
    else
      -- create new font string if not existing
      buttonText = button:CreateFontString(nil, "OVERLAY")
      buttonText:SetFont(font, size, flags)
      buttonText:SetPoint("CENTER", button, "CENTER")
      button:SetFontString(buttonText)
    end
  end
end

pfUI.api.SetButtonFontColor = pfUI.api.SetButtonFontColor or function(button, r, g, b, a)
  if button.SetTextColor then
    -- vanilla + tbc
    button:SetTextColor(r, g, b, a)
  else
    -- wotlk
    local buttonText = button:GetFontString()
    if buttonText then buttonText:SetTextColor(r, g, b, a) end
  end
end


pfUI.api.strsplit = pfUI.api.strsplit or function(delimiter, subject)
  if not subject then return nil end
  local delimiter, fields = delimiter or ":", {}
  local pattern = string.format("([^%s]+)", delimiter)
  string.gsub(subject, pattern, function(c) fields[table.getn(fields)+1] = c end)
  return unpack(fields)
end

local sanitize_cache = {}
pfUI.api.SanitizePattern = pfUI.api.SanitizePattern or function(pattern, dbg)
  if not sanitize_cache[pattern] then
    local ret = pattern
    -- escape magic characters
    ret = gsub(ret, "([%+%-%*%(%)%?%[%]%^])", "%%%1")
    -- remove capture indexes
    ret = gsub(ret, "%d%$","")
    -- catch all characters
    ret = gsub(ret, "(%%%a)","%(%1+%)")
    -- convert all %s to .+
    ret = gsub(ret, "%%s%+",".+")
    -- set priority to numbers over strings
    ret = gsub(ret, "%(.%+%)%(%%d%+%)","%(.-%)%(%%d%+%)")
    -- cache it
    sanitize_cache[pattern] = ret
  end

  return sanitize_cache[pattern]
end

local er, eg, eb, ea = .4,.4,.4,1
local br, bg, bb, ba = 0,0,0,1
pfUI.api.CreateBackdrop = pfUI.api.CreateBackdrop or function(f, inset, legacy, transp)
  -- exit if now frame was given
  if not f then return end

  -- use default inset if nothing is given
  local border = inset
  if not border then
    border = tonumber(pfUI_config.appearance.border.default)
  end

  if transp then ba = transp end

  -- use legacy backdrop handling
  if legacy then
    f:SetBackdrop(pfUI.backdrop)
    f:SetBackdropColor(br, bg, bb, ba)
    f:SetBackdropBorderColor(er, eg, eb , ea)
    return
  end

  -- increase clickable area if available
  if f.SetHitRectInsets then
    f:SetHitRectInsets(-border,-border,-border,-border)
  end

  -- use new backdrop behaviour
  if not f.backdrop then
    f:SetBackdrop(nil)

    local border = tonumber(border) - 1
    local backdrop = pfUI.backdrop
    if border < 1 then backdrop = pfUI.backdrop_small end
  	local b = CreateFrame("Frame", nil, f)
  	b:SetPoint("TOPLEFT", f, "TOPLEFT", -border, border)
  	b:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", border, -border)

    local level = f:GetFrameLevel()
    if level < 1 then
  	  --f:SetFrameLevel(level + 1)
      b:SetFrameLevel(level)
    else
      b:SetFrameLevel(level - 1)
    end

    f.backdrop = b
    b:SetBackdrop(backdrop)
  end

  local b = f.backdrop
  b:SetBackdropColor(br, bg, bb, ba)
  b:SetBackdropBorderColor(er, eg, eb , ea)
end

pfUI.api.SkinArrowButton = pfUI.api.SkinArrowButton or function(button, dir, size)
  if not button then return end

  SkinButton(button)

  button:SetHitRectInsets(-3,-3,-3,-3)

  button:SetNormalTexture(nil)
  button:SetPushedTexture(nil)
  button:SetHighlightTexture(nil)
  button:SetDisabledTexture(nil)

  if size then
    button:SetWidth(size)
    button:SetHeight(size)
  end

  if not button.icon then
    button.icon = button:CreateTexture(nil, "ARTWORK")
    button.icon:SetAlpha(.8)
    SetAllPointsOffset(button.icon, button, 3)
  end

  button.icon:SetTexture(pfUI.media["img:"..dir])

  if not button.pficonfade then
    local button, state = button, nil
    button.pficonfade = CreateFrame("Frame", nil, button)
    button.pficonfade:SetScript("OnUpdate", function()
      if state == button:IsEnabled() then return end
      state = button:IsEnabled()

      if state > 0 then
        button.icon:SetVertexColor(.8,.8,.8,1)
      else
        button.icon:SetVertexColor(.2,.2,.2,1)
      end
    end)
  end
end

pfUI.api.SkinButton = pfUI.api.SkinButton or function(button, cr, cg, cb)
  local b = getglobal(button)
  if not b then b = button end
  if not b then return end
  if not cr or not cg or not cb then
    _, class = UnitClass("player")
    local color = RAID_CLASS_COLORS[class]
    cr, cg, cb = color.r , color.g, color.b
  end
  pfUI.api.CreateBackdrop(b, nil, true)
  b:SetNormalTexture(nil)
  b:SetHighlightTexture(nil)
  b:SetPushedTexture(nil)
  b:SetDisabledTexture(nil)
  local funce = b:GetScript("OnEnter")
  local funcl = b:GetScript("OnLeave")
  b:SetScript("OnEnter", function()
    if funce then funce() end
    pfUI.api.CreateBackdrop(b, nil, true)
    b:SetBackdropBorderColor(cr,cg,cb,1)
  end)
  b:SetScript("OnLeave", function()
    if funcl then funcl() end
    pfUI.api.CreateBackdrop(b, nil, true)
  end)
  pfUI.api.SetButtonFont(b, pfUI.font_default, pfUI_config.global.font_size, "OUTLINE")
end

pfUI.api.CreateScrollFrame = pfUI.api.CreateScrollFrame or function(name, parent)
  local f = CreateFrame("ScrollFrame", name, parent)

  -- create slider
  f.slider = CreateFrame("Slider", nil, f)
  f.slider:SetOrientation('VERTICAL')
  f.slider:SetPoint("TOPLEFT", f, "TOPRIGHT", -7, 0)
  f.slider:SetPoint("BOTTOMRIGHT", 0, 0)
  f.slider:SetThumbTexture("Interface\\BUTTONS\\WHITE8X8")
  f.slider.thumb = f.slider:GetThumbTexture()
  f.slider.thumb:SetHeight(50)
  f.slider.thumb:SetTexture(.3,1,.8,.5)

  local selfevent = false
  f.slider:SetScript("OnValueChanged", function()
    if selfevent then return end
    selfevent = true
    f:SetVerticalScroll(this:GetValue())
    f.UpdateScrollState()
    selfevent = false
  end)

  f.UpdateScrollState = function()
    f.slider:SetMinMaxValues(0, f:GetVerticalScrollRange())
    f.slider:SetValue(f:GetVerticalScroll())

    local m = f:GetHeight()+f:GetVerticalScrollRange()
    local v = f:GetHeight()
    local ratio = v / m

    if ratio < 1 then
      local size = math.floor(v * ratio)
      f.slider.thumb:SetHeight(size)
      f.slider:Show()
    else
      f.slider:Hide()
    end
  end

  f.Scroll = function(self, step)
    local step = step or 0

    local current = f:GetVerticalScroll()
    local max = f:GetVerticalScrollRange()
    local new = current - step

    if new >= max then
      f:SetVerticalScroll(max)
    elseif new <= 0 then
      f:SetVerticalScroll(0)
    else
      f:SetVerticalScroll(new)
    end

    f:UpdateScrollState()
  end

  f:EnableMouseWheel(1)
  f:SetScript("OnMouseWheel", function()
    this:Scroll(arg1*10)
  end)

  return f
end

pfUI.api.CreateScrollChild = pfUI.api.CreateScrollChild or function(name, parent)
  local f = CreateFrame("Frame", name, parent)

  -- dummy values required
  f:SetWidth(1)
  f:SetHeight(1)
  f:SetAllPoints(parent)

  parent:SetScrollChild(f)

  f:SetScript("OnUpdate", function()
    this:GetParent():UpdateScrollState()
  end)

  return f
end

-- [ round ]
-- Rounds a float number into specified places after comma.
-- 'input'      [float]         the number that should be rounded.
-- 'places'     [int]           amount of places after the comma.
-- returns:     [float]         rounded number.
pfUI.api.round = pfUI.api.round or function(input, places)
  if not places then places = 0 end
  if type(input) == "number" and type(places) == "number" then
    local pow = 1
    for i = 1, places do pow = pow * 10 end
    return floor(input * pow + 0.5) / pow
  end
end

-- [ rgbhex ]
-- Returns color format from color info
-- 'r'          [table or number]  color table or r color component
-- 'g'          [number] optional g color component
-- 'b'          [number] optional b color component
-- 'a'          [number] optional alpha component
-- returns color string in the form of '|caaxxyyzz'
local hexcolor_cache = {}
pfUI.api.rgbhex = pfUI.api.rgbhex or function(r, g, b, a)
  local key
  if type(r)=="table" then
    local _r,_g,_b,_a
    if r.r then
      _r,_g,_b,_a = r.r, r.g, r.b, r.a or 1
    elseif table.getn(r) >= 3 then
      _r,_g,_b,_a = r[1], r[2], r[3], r[4] or 1
    end
    if _r and _g and _b and _a then
      key = string.format("%s%s%s%s",_r,_g,_b,_a)
      if hexcolor_cache[key] == nil then
        hexcolor_cache[key] = string.format("|c%02x%02x%02x%02x", _a*255, _r*255, _g*255, _b*255)
      end
    end
  elseif tonumber(r) and g and b then
    a = a or 1
    key = string.format("%s%s%s%s",r,g,b,a)
    if hexcolor_cache[key] == nil then
      hexcolor_cache[key] = string.format("|c%02x%02x%02x%02x", a*255, r*255, g*255, b*255)
    end
  end
  return hexcolor_cache[key] or ""
end

-- [ GetColorGradient ] --
-- 'perc'     percentage (0-1)
-- return r,g,b and hexcolor
local gradientcolors = {}
pfUI.api.GetColorGradient = pfUI.api.GetColorGradient or function(perc)
  perc = perc > 1 and 1 or perc
  perc = perc < 0 and 0 or perc
  perc = floor(perc*100)/100

  local index = perc
  if not gradientcolors[index] then
    local r1, g1, b1, r2, g2, b2

    if perc <= 0.5 then
      perc = perc * 2
      r1, g1, b1 = 1, 0, 0
      r2, g2, b2 = 1, 1, 0
    else
      perc = perc * 2 - 1
      r1, g1, b1 = 1, 1, 0
      r2, g2, b2 = 0, 1, 0
    end

    local r = pfUI.api.round(r1 + (r2 - r1) * perc, 4)
    local g = pfUI.api.round(g1 + (g2 - g1) * perc, 4)
    local b = pfUI.api.round(b1 + (b2 - b1) * perc, 4)
    local h = pfUI.api.rgbhex(r,g,b)

    gradientcolors[index] = {}
    gradientcolors[index].r = r
    gradientcolors[index].g = g
    gradientcolors[index].b = b
    gradientcolors[index].h = h
  end

  return gradientcolors[index].r,
    gradientcolors[index].g,
    gradientcolors[index].b,
    gradientcolors[index].h
end


-- [ GetBestAnchor ]
-- Returns the best anchor of a frame, based on its position
-- 'self'       [frame]        the frame that should be checked
-- returns:     [string]       the name of the best anchor
pfUI.api.GetBestAnchor = pfUI.api.GetBestAnchor or function(self)
  local scale = self:GetScale()
  local x, y = self:GetCenter()
  local a = GetScreenWidth()  / scale / 3
  local b = GetScreenWidth()  / scale / 3 * 2
  local c = GetScreenHeight() / scale / 3 * 2
  local d = GetScreenHeight() / scale / 3
  if not x or not y then return end

  if x < a and y > c then
    return "TOPLEFT"
  elseif x > a and x < b and y > c then
    return "TOP"
  elseif x > b and y > c then
    return "TOPRIGHT"
  elseif x < a and y > d and y < c then
    return "LEFT"
  elseif x > a and x < b and y > d and y < c then
    return "CENTER"
  elseif x > b and y > d and y < c then
    return "RIGHT"
  elseif x < a and y < d then
    return "BOTTOMLEFT"
  elseif x > a and x < b and y < d then
    return "BOTTOM"
  elseif x > b and y < d then
    return "BOTTOMRIGHT"
  end
end

-- [ ConvertFrameAnchor ]
-- Converts a frame anchor into another one while preserving the frame position
-- 'self'       [frame]        the frame that should get another anchor.
-- 'anchor'     [string]       the new anchor that shall be used
-- returns:     anchor, x, y   can directly be used in SetPoint()
pfUI.api.ConvertFrameAnchor = pfUI.api.ConvertFrameAnchor or function(self, anchor)
  local scale, x, y, _ = self:GetScale(), nil, nil, nil

  if anchor == "CENTER" then
    x, y = self:GetCenter()
    x, y = x - GetScreenWidth()/2/scale, y - GetScreenHeight()/2/scale
  elseif anchor == "TOPLEFT" then
    x, y = self:GetLeft(), self:GetTop() - GetScreenHeight()/scale
  elseif anchor == "TOP" then
    x, _ = self:GetCenter()
    x, y = x - GetScreenWidth()/2/scale, self:GetTop() - GetScreenHeight()/scale
  elseif anchor == "TOPRIGHT" then
    x, y = self:GetRight() - GetScreenWidth()/scale, self:GetTop() - GetScreenHeight()/scale
  elseif anchor == "RIGHT" then
    _, y = self:GetCenter()
    x, y = self:GetRight() - GetScreenWidth()/scale, y - GetScreenHeight()/2/scale
  elseif anchor == "BOTTOMRIGHT" then
    x, y = self:GetRight() - GetScreenWidth()/scale, self:GetBottom()
  elseif anchor == "BOTTOM" then
    x, _ = self:GetCenter()
    x, y = x - GetScreenWidth()/2/scale, self:GetBottom()
  elseif anchor == "BOTTOMLEFT" then
    x, y = self:GetLeft(), self:GetBottom()
  elseif anchor == "LEFT" then
    _, y = self:GetCenter()
    x, y = self:GetLeft(), y - GetScreenHeight()/2/scale
  end

  return anchor, pfUI.api.round(x, 2), pfUI.api.round(y, 2)

end

if pfUI.api.CreateDropDownButton == nil then
  local _, class = UnitClass("player")
  local color = RAID_CLASS_COLORS[class]

  local function ListEntryOnShow()
    if this.parent.id == this.id then
      this.icon:Show()
    else
      this.icon:Hide()
    end
  end

  local function ListEntryOnClick()
    this.parent:SetSelection(this.id)

    if this.parent.mode == "MULTISELECT" then
      this.parent:ShowMenu()
    else
      this.parent:HideMenu()
    end

    if this.parent.menu[this.id].func then
      this.parent.menu[this.id].func()
    end
  end

  local function ListEntryOnEnter()
    this.hover:Show()
  end

  local function ListEntryOnLeave()
    this.hover:Hide()
  end

  local function ListButtonOnClick()
    if this.ToggleMenu then
      this:ToggleMenu()
    else
      this:GetParent():ToggleMenu()
    end
  end

  local function MenuOnUpdate()
    if not MouseIsOver(this, 100, -100, -100, 100) then
      this.button:HideMenu()
    end
  end

  local function ListButtonOnEnter()
    this.button:SetBackdropBorderColor(this.button.cr,this.button.cg,this.button.cb,(this.button.ca or 1))
  end

  local function ListButtonOnLeave()
    this.button:SetBackdropBorderColor(this.button.rr,this.button.rg,this.button.rb,(this.button.ra or 1))
  end

  local handlers = {
    ["SetSelection"] = function(self, id)
      if id and self.menu and self.menu[id] then
        self.text:SetText(self.menu[id].text)
        self.id = id
      end
    end,
    ["SetSelectionByText"] = function(self, name)
      self:UpdateMenu()
      for id, entry in pairs(self.menu) do
        if entry.text == name then
          self:SetSelection(id)
          return true
        end
      end

      self.text:SetText(name)
      return nil
    end,
    ["GetSelection"] = function(self)
      self:UpdateMenu()
      if self.menu and self.menu[self.id] then
        return self.id, self.menu[self.id].text, self.menu[self.id].func
      end
    end,
    ["SetMenu"] = function(self, menu)
      if type(menu) == "function" then
        self.menu = menu()
        self.menufunc = menu
      else
        self.menu = menu
        self.menufunc = nil
      end
    end,
    ["GetMenu"] = function(self)
      self:UpdateMenu()
      return self.menu
    end,
    ["ShowMenu"] = function(self)
      self:UpdateMenu()
      self.menuframe:SetFrameLevel(self:GetFrameLevel() + 8)
      self.menuframe:SetHeight(table.getn(self.menu)*20+4)
      self.menuframe:Show()
    end,
    ["HideMenu"] = function(self)
      self.menuframe:Hide()
    end,
    ["ToggleMenu"] = function(self)
      if self.menuframe:IsShown() then
        self:HideMenu()
      else
        self:ShowMenu()
      end
    end,
    ["UpdateMenu"] = function(self)
      -- run/reload menu function if available
      if self.menufunc then self.menu = self.menufunc() end
      if not self.menu then return end

      -- set caption to the current value
      self.text:SetText(self.menu[self.id] and self.menu[self.id].text or "")

      -- refresh menu buttons
      for id, element in pairs(self.menuframe.elements) do
        element:Hide()
      end

      for id, data in pairs(self.menu) do
        self:CreateMenuEntry(id)
      end
    end,
    ["CreateMenuEntry"] = function(self, id)
      if not self.menu[id] then return end

      local frame, entry
      for count, existing in pairs(self.menuframe.elements) do
        if not existing:IsShown() then
          frame = existing
          entry = count
          break
        end
      end

      if not frame and not entry then
        entry = table.getn(self.menuframe.elements) + 1
        frame = CreateFrame("Button", nil, self.menuframe)
        frame:SetFrameStrata("FULLSCREEN")
        frame:ClearAllPoints()
        frame:SetPoint("TOPLEFT", self.menuframe, "TOPLEFT", 2, -(entry-1)*20-2)
        frame:SetPoint("TOPRIGHT", self.menuframe, "TOPRIGHT", -2, -(entry-1)*20-2)
        frame:SetHeight(20)
        frame.parent = self

        frame.icon = frame:CreateTexture(nil, "OVERLAY")
        frame.icon:SetPoint("RIGHT", frame, "RIGHT", -2, 0)
        frame.icon:SetHeight(16)
        frame.icon:SetWidth(16)
        frame.icon:SetTexture("Interface\\Buttons\\UI-CheckBox-Check")

        frame.text = frame:CreateFontString(nil, "OVERLAY")
        frame.text:SetFontObject(GameFontWhite)
        frame.text:SetFont(pfUI.font_default, pfUI_config.global.font_size-1, "OUTLINE")
        frame.text:SetJustifyH("RIGHT")
        frame.text:SetPoint("LEFT", frame, "LEFT", 2, 0)
        frame.text:SetPoint("RIGHT", frame.icon, "LEFT", -2, 0)

        frame.hover = frame:CreateTexture(nil, "BACKGROUND")
        frame.hover:SetAllPoints(frame)
        frame.hover:SetTexture(.4,.4,.4,.4)
        frame.hover:Hide()

        table.insert(self.menuframe.elements, frame)
      end

      frame.id = id
      frame.text:SetText(self.menu[id].text)

      frame:SetScript("OnShow",  ListEntryOnShow)
      frame:SetScript("OnClick", ListEntryOnClick)
      frame:SetScript("OnEnter", ListEntryOnEnter)
      frame:SetScript("OnLeave", ListEntryOnLeave)
      frame:Show()
    end,
  }
  function pfUI.api.CreateDropDownButton(name, parent)
    local frame = CreateFrame("Button", name, parent)
    frame:SetScript("OnEnter", ListButtonOnEnter)
    frame:SetScript("OnLeave", ListButtonOnLeave)
    frame:SetScript("OnClick", ListButtonOnClick)
    frame:SetHeight(20)
    frame.id = nil

    pfUI.api.CreateBackdrop(frame, nil, true)

    local button = CreateFrame("Button", nil, frame)
    button:SetPoint("RIGHT", frame, "RIGHT", -2, 0)
    button:SetWidth(16)
    button:SetHeight(16)
    button:SetScript("OnClick", ListButtonOnClick)
    pfUI.api.SkinArrowButton(button, "down")
    button.icon:SetVertexColor(1,.9,.1)

    local text = frame:CreateFontString(nil, "OVERLAY")
    text:SetFontObject(GameFontWhite)
    text:SetFont(pfUI.font_default, pfUI_config.global.font_size-1, "OUTLINE")
    text:SetPoint("RIGHT", button, "LEFT", -4, 0)
    text:SetJustifyH("RIGHT")

    local menuframe = CreateFrame("Frame", tostring(frame).."menu", parent)
    menuframe.button = frame
    menuframe.elements = {}
    menuframe:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", 0, -2)
    menuframe:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 2)
    menuframe:SetScript("OnUpdate", MenuOnUpdate)
    menuframe:Hide()
    pfUI.api.CreateBackdrop(menuframe, nil, true)

    for name, func in pairs(handlers) do
      frame[name] = func
    end

    frame.menuframe = menuframe
    frame.button = button
    frame.text = text

    return frame
  end
end