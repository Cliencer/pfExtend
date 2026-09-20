# detailviewer.lua 模拟环境功能测试
import sys
from lupa import LuaRuntime

lua = LuaRuntime()
lua.execute('unpack = table.unpack')  # WoW 全局函数, Lua5.4中已更名
lua.execute(r'''
-- ============ WoW UI 模拟 ============
CreatedTexts = {}   -- 所有文本控件 {text=, y=}
CreatedIcons = {}   -- 所有图标行 {itemid=, name=, count=}

local function MockTexture(parent)
    local t = { parent = parent }
    function t:SetTexture(...) end
    function t:SetAllPoints(...) end
    function t:SetPoint(...) end
    function t:SetVertexColor(...) end
    function t:ClearAllPoints() end
    function t:SetWidth(w) end
    function t:SetHeight(h) end
    function t:Show() end
    function t:Hide() end
    return t
end

local function MockFontString(parent)
    local fs = { parent = parent, text = "", y = 0 }
    function fs:SetFont(...) end
    function fs:SetFontObject(...) end
    function fs:SetPoint(_, _, _, _, yy) fs.y = yy or 0 end
    function fs:SetJustifyH(_) end
    function fs:SetWidth(_) end
    function fs:SetText(t) fs.text = t or "" end
    function fs:SetTextColor(...) end
    function fs:GetHeight()
        local _, lines = string.gsub(fs.text, "\n", "\n")
        return (lines + 1) * 13
    end
    function fs:ClearAllPoints() end
    function fs:Show()
        if fs.parent and fs.parent.isContent then
            table.insert(CreatedTexts, fs)
        end
    end
    function fs:Hide() end
    return fs
end

local function MockFrame(name, parent)
    local f = { name = name, parent = parent, scripts = {}, children = {} }
    function f:Hide() self.hidden = true end
    function f:Show() self.hidden = false end
    function f:SetWidth(w) end
    function f:SetHeight(h) end
    function f:SetPoint(...) end
    function f:ClearAllPoints() end
    function f:SetFrameStrata(_) end
    function f:SetToplevel(_) end
    function f:SetClampedToScreen(_) end
    function f:SetMovable(_) end
    function f:EnableMouse(_) end
    function f:SetScript(k, fn) self.scripts[k] = fn end
    function f:StartMoving() end
    function f:StopMovingOrSizing() end
    function f:SetVerticalScroll(_) end
    function f:IsShown() return false end
    function f:Insert(_) end
    function f:CreateFontString(_, _, _) return MockFontString(f) end
    function f:CreateTexture(_, _) return MockTexture(f) end
    return f
end

function CreateFrame(_, name, parent)
    local f = MockFrame(name, parent)
    if name == "PFEXQuestDetailFrameScrollChild" then f.isContent = true end
    if name == "PFEXQuestDetailFrame" then DETAIL_FRAME = f end
    return f
end

pfUI = {
    font_default = "Fonts\\FRIZQT__.TTF",
    api = {
        CreateBackdrop = function() end,
        SkinButton = function() end,
        CreateScrollFrame = function(name, parent) return MockFrame(name, parent) end,
        CreateScrollChild = function(name, parent)
            local f = MockFrame(name, parent); f.isContent = true; return f
        end,
    },
}
pfUI_config = { global = { font_size = 12 } }
pfExtend_Path = "pfExtend"
pfExtendCompat = {
    itemsuffix = ":0:0:0",
    mod = function(a, b) return a % b end,
    GetQuestLogTitle = function(i)
        if i == 1 then return "Darker than Iron", nil, nil, false end
        return nil
    end,
}
pfExtend_Loc = setmetatable({}, { __index = function(t, k) return k end })

pfDB = {
    quests = {
        loc = {
            [41677] = {
                T = "Darker than Iron",
                O = "Destroy 5 Dark Iron Powder Kegs.",
                D = "The Dark Irons brought powder kegs.$B$B$Blow those kegs up, $N!",
            },
        },
        data = { [41677] = { lvl = 32, min = 29 } },
    },
    items = { loc = { [58031] = "Amberwood Bracers", [58032] = "Dark Iron Gloves" } },
}
PfExtend_QuestRewards = {
    [41677] = { xp = 2150, mml = 12900, choice = { 58031, { 58032, 2 } } },
}
pfDatabase = {
    GetQuestIDs = function(self, i) if i == 1 then return { "41677" } end return {} end,
}
PFEXQuestHelper = {}

GetNumQuestLogEntries = function() return 1 end
GetNumQuestLeaderBoards = function(i) return 1 end
GetQuestLogLeaderBoard = function(j, i) return "Dark Iron Powder Keg destroyed: 2/5", "item", false end
GetQuestDifficultyColor = function(lvl) return { r = 1, g = 0.5, b = 0.25 } end
GetItemInfo = function(id)
    if id == 58031 then return "Amberwood Bracers", "|Hitem:58031|h[Amberwood Bracers]|h", 2, 10, "", "", 1, "", "Interface\\Icons\\INV_Bracer_07" end
    if id == 58032 then return "Dark Iron Gloves", "|Hitem:58032|h[Dark Iron Gloves]|h", 2, 10, "", "", 1, "", "Interface\\Icons\\INV_Gauntlets_04" end
    return nil
end
ITEM_QUALITY_COLORS = { [2] = { r = 0.12, g = 1, b = 0 } }
UnitName = function() return "Tester" end
UnitClass = function() return "Warrior", "WARRIOR" end
UnitRace = function() return "Orc", "Orc" end
IsShiftKeyDown = function() return false end
GameTooltip = { SetOwner = function() end, SetHyperlink = function() end, SetText = function() end, Show = function() end, Hide = function() end }
ChatFrameEditBox = MockFrame("editbox")
UISpecialFrames = {}
''')

lua.execute(open('modules/QuestHelper/detailviewer.lua', encoding='utf-8').read())

# icon行Show时需要被记录 —— 在运行后通过 frame.content 子控件拿不到,
# 改为让 detailviewer 的 AddIconRow 路径直接校验: 注入钩子
lua.execute(r'''
-- 包装 AddIconRow 不可行(local), 改为直接检查 ShowQuestDetail 后的文本输出
PFEXQuestHelper.ShowQuestDetail(41677)
''')

texts = lua.eval('CreatedTexts')
print('=== 详情窗口文本行 (按y排序) ===')
rows = sorted(texts.values(), key=lambda fs: fs.y)
for fs in rows:
    print('  y=%4d  %s' % (fs.y, fs.text.replace('\n', ' ⏎ ')))
print()
print('窗口标题:', lua.eval('DETAIL_FRAME and "已创建" or "缺失"'))
print('Esc注册(UISpecialFrames):', list(lua.eval('UISpecialFrames').values()))
