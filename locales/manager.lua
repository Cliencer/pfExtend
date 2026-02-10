
pfExtend_Loc = setmetatable(pfExtend_Locales[GetLocale()] or {}, {
    __index = function(tab, key)
        local value = pfExtend_Locales["enUS"][key]
        rawset(tab, key, value )
        return value
    end
})



