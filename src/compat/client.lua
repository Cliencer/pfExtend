-- some abstraction to allow multi-client code
local _, _, _, client = GetBuildInfo()
client = client or 11200

local _G = client == 11200 and getfenv(0) or _G
local gfind = string.gmatch or string.gfind

pfExtendCompat = {}
pfExtendCompat.mod = mod or math.mod
pfExtendCompat.gfind = string.gmatch or string.gfind
pfExtendCompat.itemsuffix = client > 11200 and ":0:0:0:0:0:0:0" or ":0:0:0"
pfExtendCompat.rotateMinimap = client > 11200 and GetCVar("rotateMinimap") ~= "0" and true or nil
pfExtendCompat.client = client

-- addon-compat: use and cache the original function if CTMod overwrites global API calls
local GetQuestLogTitle = CT_QuestLevels_oldGetQuestLogTitle or GetQuestLogTitle

-- tbc+wotlk: change behaviour of later expansions to the vanilla one
pfExtendCompat.GetQuestLogTitle = function(id)
  local title, level, tag, group, header, collapsed, complete, daily, _
  if client <= 11200 then    -- vanilla
    title, level, tag, header, collapsed, complete = GetQuestLogTitle(id)
  elseif client > 11200 then -- tbc & wotlk
    title, level, tag, group, header, collapsed, complete, daily = GetQuestLogTitle(id)
  end

  return title, level, tag, header, collapsed, complete
end

-- wotlk: changed from GetDifficultyColor to GetQuestDifficultyColor in 3.2
pfExtendCompat.GetDifficultyColor = GetQuestDifficultyColor or GetDifficultyColor

-- wotlk: changed from QuestWatchFrame to WatchFrame in 3.3
pfExtendCompat.QuestWatchFrame = QuestWatchFrame or WatchFrame

-- wotlk: changed questlog related frame names in 3.3
pfExtendCompat.QuestLogQuestTitle = QuestLogQuestTitle or QuestInfoTitleHeader
pfExtendCompat.QuestLogObjectivesText = QuestLogObjectivesText or QuestInfoObjectivesText
pfExtendCompat.QuestLogQuestDescription = QuestLogQuestDescription or QuestInfoDescriptionText
pfExtendCompat.QuestLogDescriptionTitle = QuestLogDescriptionTitle or QuestInfoDescriptionHeader

-- wotlk: disable builtin quest progress tooltips
if client >= 30300 then
  SetCVar("showQuestTrackingTooltips", 0)
end

-- vanilla+tbc+wotlk: base function to insert quest links to the chat
pfExtendCompat.InsertQuestLink = function(questid, name)
  local questid = questid or 0
  local fallback = name or UNKNOWN
  local level = pfDB["quests"]["data"][questid] and pfDB["quests"]["data"][questid]["lvl"] or 0
  local name = pfDB["quests"]["loc"][questid] and pfDB["quests"]["loc"][questid]["T"] or fallback
  local hex = pfUI.api.rgbhex(pfExtendCompat.GetDifficultyColor(level))

  ChatFrameEditBox:Show()
  if pfQuest_config["questlinks"] == "1" then
    ChatFrameEditBox:Insert(hex .. "|Hquest:" .. questid .. ":" .. level .. "|h[" .. name .. "]|h|r")
  else
    ChatFrameEditBox:Insert("[" .. name .. "]")
  end
end

-- vanilla+tbc: do the best to detect the minimap arrow
local minimaparrow = ({ Minimap:GetChildren() })[9]
for k, v in pairs({ Minimap:GetChildren() }) do
  if v:IsObjectType("Model") and not v:GetName() then
    if string.find(strlower(v:GetModel()), "interface\\minimap\\minimaparrow") then
      minimaparrow = v
      break
    end
  end
end

-- vanilla+tbc: return the player facing based on the minimap arrow
pfExtendCompat.GetPlayerFacing = GetPlayerFacing or function()
  if pfExtendCompat.rotateMinimap then
    return (MiniMapCompassRing:GetFacing() * -1)
  else
    return minimaparrow:GetFacing()
  end
end

-- vanilla: overwrite the out-of-memory popup on vanilla clients, to provide some help
-- on how to increase the limits, and also displaying a link to an example.
if client <= 11200 then
  local memlimit = "插件占用的内存已经超过 %dMB 。\n\n" ..
      "在角色选择界面，点击左下角的'|cffffee55【插件】|r'按钮，将 '|cffffee55插件内存|r' 设置为 '|cffffee550|r' :"

  local striptex = function(frame)
    for _, v in ipairs({ frame:GetRegions() }) do
      if v.GetTexture and string.find(v:GetTexture(), "ChatInputBorder") then v:Hide() end
    end
  end

  _G.StaticPopupDialogs["MEMORY_EXHAUSTED"] = {
    text = TEXT(memlimit),
    button1 = TEXT(QUIT_NOW),
    button2 = TEXT(CANCEL),
    hasEditBox = 1,
    showAlert = 1,
    OnShow = function()
      pfUI.api.CreateBackdrop(getglobal(this:GetName() .. "EditBox"), 3, true)
      getglobal(this:GetName() .. "EditBox"):SetText("https://shagu.org/script-memory.jpg")
      getglobal(this:GetName() .. "EditBox"):SetTextInsets(5, 5, 5, 5)
      getglobal(this:GetName() .. "EditBox"):SetJustifyH("CENTER")
      getglobal(this:GetName() .. "EditBox"):SetWidth(220)
      getglobal(this:GetName() .. "EditBox"):SetFocus()
      getglobal(this:GetName() .. "Button2"):Disable()
      striptex(getglobal(this:GetName() .. "EditBox"))
    end,
    OnAccept = function()
      ForceQuit()
    end,
    timeout = 0,
    whileDead = 1,
  }
end

-- vanilla: add colors to quest links
if client <= 11200 then
  local ParseQuestLevels = function(frame, text, a1, a2, a3, a4, a5)
    if text then
      for oldhex, questid, level in gfind(text, "(|c%x+)|Hquest:(.-):(.-)|h") do
        local questid = tonumber(questid)
        local level = tonumber(level)

        if not level or level == 0 then
          level = pfDB["quests"]["data"][questid] and pfDB["quests"]["data"][questid]["lvl"] or 0
        end

        if level and level > 0 then
          local newhex = pfUI.api.rgbhex(pfExtendCompat.GetDifficultyColor(level))
          text = string.gsub(text, oldhex .. "|Hquest:" .. questid, newhex .. "|Hquest:" .. questid)
        end
      end
    end

    frame.pfQuestHookAddMessage(frame, text, a1, a2, a3, a4, a5)
  end

  for i = 1, NUM_CHAT_WINDOWS do
    _G["ChatFrame" .. i].pfQuestHookAddMessage = _G["ChatFrame" .. i].pfQuestHookAddMessage or
    _G["ChatFrame" .. i].AddMessage
    _G["ChatFrame" .. i].AddMessage = ParseQuestLevels
  end
end












--C_Timer库
if not C_Timer then
  -- 生成计时器函数
  local function GenerateTimer()
    local Timer = CreateFrame("Frame")
    local TimerObject = {}

    Timer.Infinite = 0 -- -1 无限循环，0 停止，1..n 循环 n 次
    Timer.ElapsedTime = 0

    function Timer:Start(duration, callback)
      if type(duration) ~= "number" then
        duration = 0
      end

      self:SetScript("OnUpdate", function()
        self.ElapsedTime = self.ElapsedTime + arg1

        if self.ElapsedTime >= duration and type(callback) == "function" then
          callback()
          self.ElapsedTime = 0

          if self.Infinite == 0 then
            self:SetScript("OnUpdate", nil)
          elseif self.Infinite > 0 then
            self.Infinite = self.Infinite - 1
          end
        end
      end)
    end

    function TimerObject:IsCancelled()
      return not Timer:GetScript("OnUpdate")
    end

    function TimerObject:Cancel()
      if Timer:GetScript("OnUpdate") then
        Timer:SetScript("OnUpdate", nil)
        Timer.Infinite = 0
        Timer.ElapsedTime = 0
      end
    end

    return Timer, TimerObject
  end

  C_Timer = {
    After = function(duration, callback)
      GenerateTimer():Start(duration, callback)
    end,
    NewTimer = function(duration, callback)
      local timer, timerObj = GenerateTimer()
      timer:Start(duration, callback)
      return timerObj
    end,
    NewTicker = function(duration, callback, ...)
      local timer, timerObj = GenerateTimer()
      local iterations = unpack(arg)

      if type(iterations) ~= "number" or iterations < 0 then
        iterations = 0         -- 无限循环
      end

      timer.Infinite = iterations - 1
      timer:Start(duration, callback)
      return timerObj
    end
  }
end
