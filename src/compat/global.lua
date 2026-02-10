pfExtend_Locales = {}
PfExtend_Database = {}
PfExtend_Config = {}
PfExtend_Config_Template = {}
PfExtend_Config_Index = {}
PfExtend_Global = {}
pfExtend_Path = "Interface\\AddOns\\pfExtend"


function table.shallowCopy(original)
    local copy = {}
    for key, value in pairs(original) do
        if type(value) == "table" then
            copy[key] = value["select"]
        else
            copy[key] = value
        end
    end
    return copy
end

PfExtend_Global.ReadSetting = function(module, config)
    if PfExtend_Config[module] == nil then
        PfExtend_Config[module] = table.shallowCopy(PfExtend_Config_Template[module])
        return PfExtend_Config_Template[module][config]
    end
    if PfExtend_Config[module][config] == nil then
        if type(PfExtend_Config_Template[module][config]) == "table" then
            PfExtend_Config[module][config] = PfExtend_Config_Template[module][config]["select"]
        else
            PfExtend_Config[module][config] = PfExtend_Config_Template[module][config]
        end
    end
    return PfExtend_Config[module][config]
end

PfExtend_Global.sortKeyValueTable = function(t, sortBy, descending)
    sortBy = sortBy or "key"
    descending = descending or false

    -- 转换为键值对数组
    local arr = {}
    for k, v in pairs(t) do
        table.insert(arr, { key = k, value = v })
    end

    -- 排序比较函数
    local cmp
    if sortBy == "key" then
        cmp = function(a, b)
            if descending then
                return a.key > b.key
            else
                return a.key < b.key
            end
        end
    else -- sortBy == "value"
        cmp = function(a, b)
            if descending then
                return a.value > b.value
            else
                return a.value < b.value
            end
        end
    end

    table.sort(arr, cmp)
    return arr
end

--去重
table.unique = function(t)
    local seen = {}
    local result = {}

    for _, v in ipairs(t) do
        if not seen[v] then
            seen[v] = true
            table.insert(result, v)
        end
    end

    return result
end
--合并
table.add = function(t1, t2)
    for _, v in ipairs(t2) do
        table.insert(t1, v)
    end
    return t1
end

table.countNum = function(t)
    local ret = 0

    for k, v in pairs(t) do
        ret = ret + 1
    end

    return ret
end

table.contain = function(table, value)
    if table == nil then return false end
    for _, v in pairs(table) do
        if v == value then
            return true
        end
    end
    return false
end
table.IsEmpty = function(tabl)
  for k,v in pairs(tabl) do
    return false
  end
  return true
end