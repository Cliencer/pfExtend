# ShowLoots 防御修复验证: 含毒数据不再中断重建 + 存档不再被登录重置
import sys
from lupa import LuaRuntime

lua = LuaRuntime()
lua.execute('unpack = table.unpack')
lua.execute(r'''
-- ===== 模拟 WoW 环境 =====
DEFAULT_CHAT_FRAME = { msgs = {} }
DEFAULT_CHAT_FRAME.AddMessage = function(self, t) table.insert(self.msgs, t) end
pfExtend_Loc = setmetatable({}, { __index = function(t, k) return k end })
pfExtendCompat = { itemsuffix = ":0:0:0", mod = function(a,b) return a % b end }
pfMap = { tooltip = { SetScript = function() end },
          GetColor = function() return 1, 1, 1 end,
          GetMapID = function() return 1 end }
function CreateFrame() return { SetScript = function() end, Show = function() end, Hide = function() end } end
GetCurrentMapContinent = function() return 1 end
GetCurrentMapZone = function() return 1 end
GetTime = function() return 0 end
GetMouseFocus = function() return nil end
GetItemInfo = function() return nil end
UnitExists = function() return false end
UnitPlayerControlled = function() return false end
IsAltKeyDown = function() return false end
''')

lua.execute(r'''
IsControlKeyDown = function() return false end
GameTooltip = { IsShown = function() return false end, SetScript = function() end }
ITEM_QUALITY_COLORS = {}
pfBrowser_fav = nil
pfDatabase = { GetIDByName = function() return {} end }
PfExtend_Global = { ReadSetting = function() return true end,
                    sortKeyValueTable = function() return {} end }

-- 含毒物品数据: 覆盖报告中的布尔条目及各种边界
pfDB = {
  items = {
    data = {
      [1] = { ["U"] = { [100] = 2.5 } },            -- 正常
      [2] = true,                                    -- 布尔物品条目
      [3] = { ["U"] = true },                        -- 布尔LootData (本次报错)
      [4] = { ["U"] = { [100] = "bad" } },           -- 非数字掉率
      [5] = { ["R"] = { [7] = 3 } },                 -- 引用表(正常)
      [6] = { ["R"] = { [8] = 1 } },                 -- 引用表(目标损坏)
      [7] = { ["U"] = { [100] = 0 } },               -- 0掉率应跳过
    },
    loc = {},
  },
  refloot = {
    data = {
      [7] = { ["U"] = { [200] = 1 } },
      [8] = true,                                    -- 布尔refloot
    },
  },
}

-- 预置存档, 验证加载时不再被清空
PfExtend_Database = { ShowLoots = {
  LootData = { U = { [999] = { [42] = 1.5 } } },
  itemQualityData = { [42] = 3 },
  updated = true,
  version = "sentinel",
} }
''')

lua.execute(open('modules/ShowLoots/main.lua', encoding='utf-8').read())

lua.execute(r'''
-- 测试1: 存档保持
sl = PfExtend_Database["ShowLoots"]
persist_ok = sl.version == "sentinel"
  and sl.LootData.U[999][42] == 1.5
  and sl.itemQualityData[42] == 3
  and sl.updated == true

-- 测试2: 含毒数据重建
rebuild_ok, err = pcall(PFEXShowLoots.UpdateDatabase)
db = PfExtend_Database["ShowLoots"]["LootData"]
data_ok = rebuild_ok
  and db.U[100][1] == 2.5     -- 正常条目保留
  and db.U[200][5] == 3       -- 引用表展开保留
  and db.U[100][4] == nil     -- 非数字掉率跳过
  and db.U[100][7] == nil     -- 0掉率跳过
  and db.U[100][3] == nil     -- 布尔LootData条目整体跳过
''')

print('存档保持(登录不再重置):', lua.eval('persist_ok'))
print('重建未崩溃:', lua.eval('rebuild_ok'), lua.eval('err') or '')
print('数据正确性(好条目保留/坏条目跳过):', lua.eval('data_ok'))
