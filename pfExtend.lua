local function pfExtend_ChatCommandHandler(msg)
    pfExtendConfig:Show()
end


function pfExtend_OnLoad()
    this:RegisterEvent("PLAYER_ENTERING_WORLD");
    this:RegisterEvent("UPDATE_MOUSEOVER_UNIT");
    this:RegisterEvent("WORLD_MAP_UPDATE");
    SLASH_pfExtendCmd1 = "/pfex";
    SlashCmdList["pfExtendCmd"] = function(msg)
        pfExtend_ChatCommandHandler(msg);
    end


    PFEXShowLoots.OnLoad()
    PFEXQuestHelper.OnLoad()
end

function pfExtend_OnEvent(event, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9)
    PFEXShowLoots.OnEvent(event, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9)
    PFEXQuestHelper.OnEvent(event, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9)
end




-- function Showloots_ChatCommandHandler(msg)
--     local commandlist = {}
--     local command
--     for command in string.gmatch(msg, "[^ ]+") do
--         table.insert(commandlist, command)
--     end
--     local arg1, arg2 = commandlist[1], ""
--     for i in pairs(commandlist) do
--         if (i ~= 1) then
--             arg2 = arg2 .. commandlist[i]
--             if (commandlist[i + 1] ~= nil) then
--                 arg2 = arg2 .. " "
--             end
--         end
--     end
--     if arg1 == "u" or arg1 == "update" then
--         DEFAULT_CHAT_FRAME:AddMessage("|cFFFF8080正在从pfQuest更新数据库...|r");
--         Showloots_UpdateDatabase()
--     elseif arg1 == "l" or arg1 == "limit" then
--         if tonumber(arg2) then
--             arg2 = math.min(math.max(math.floor(tonumber(arg2)), 3), 30)
--             PfQuest_Showloots_Config.showNum = arg2
--             DEFAULT_CHAT_FRAME:AddMessage("|cFFFF8080已将显示条数更改为|r" .. arg2 .. "|cFFFF8080！");
--         else
--             DEFAULT_CHAT_FRAME:AddMessage("|cFFFF8080参数错误！");
--         end
--     else
--         DEFAULT_CHAT_FRAME:AddMessage("|cFFFF8080命令：|r -u(pdate)    --从pfQuest更新数据库");
--         DEFAULT_CHAT_FRAME:AddMessage("|cFFFF8080命令：|r -l(imit) %d  --更改显示条数为%d（范围3~30）");
--     end
-- end