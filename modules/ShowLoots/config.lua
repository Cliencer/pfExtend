ItemQuality={
    ["Poor"]=0,
    ["Common"]=1,
    ["Uncommon"]=2,
    ["Rare"]=3,
    ["Epic"]=4,
    ["Legendary"]=5,
    ["Artifact"]=6,
    ["Heirloom"]=7,
    ["WowToken"]=8
}
PfExtend_Config["ShowLoots"]={}
PfExtend_Config_Index["ShowLoots"]={"enable","showNum","itemQualityFilter","showIds","updateData"}
PfExtend_Config_Template["ShowLoots"] = {
    ["enable"] = true,
    ["showNum"] = 5,
    ["showIds"] = true,
    ["itemQualityFilter"] = {
        ["selectTable"] = {
            ItemQuality.Poor,
            ItemQuality.Common,
            ItemQuality.Uncommon,
            ItemQuality.Rare,
            ItemQuality.Epic,
            ItemQuality.Legendary },
        ["select"] = ItemQuality.Poor
    },
    ["updateData"] = function()
        return {
            text = pfExtend_Loc["Btn_updateData"],
            func = function()
                if PFEXShowLoots.UpdateDatabase() then
                    return pfExtend_Loc["Btn_updateSuccess"]
                else
                    return pfExtend_Loc["Btn_updateFailed"]
                end
            end
        }
    end
}
