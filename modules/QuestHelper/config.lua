PfExtend_Config["QuestHelper"] = {}
PfExtend_Config_Index["QuestHelper"] = { "enable", "updateData" }
PfExtend_Config_Template["QuestHelper"] = {
    ["enable"] = true,
    ["updateData"] = function()
        return {
            text = pfExtend_Loc["Btn_updateData"],
            func = function()
                if PFEXQuestHelper.UpdateDatabase() then
                    return pfExtend_Loc["Btn_updateSuccess"]
                else
                    return pfExtend_Loc["Btn_updateFailed"]
                end
            end
        }
    end
}
