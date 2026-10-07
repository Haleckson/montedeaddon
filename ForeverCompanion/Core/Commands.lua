--[[
  Forever Companion - Core/Commands.lua
  Slash commands: /fc, /fcj, /forevercompanion
]]

local _, FC = ...

local Commands = FC:NewModule("Commands")

local L = FC.L
local U = FC.Utils

local HELP = {
    { "/fc", "HELP_TOGGLE" },
    { "/fc journal [page]", "HELP_JOURNAL" },
    { "/fc add", "HELP_ADD" },
    { "/fc map", "HELP_MAP" },
    { "/fc zone", "HELP_ZONE" },
    { "/fc quests", "HELP_QUESTS" },
    { "/fc rescan", "HELP_RESCAN" },
    { "/fc search <text>", "HELP_SEARCH" },
    { "/fc settings", "HELP_SETTINGS" },
    { "/fc sync [status|ping]", "HELP_SYNC" },
    { "/fc export | import", "HELP_EXPORT" },
    { "/fc profile <name>", "HELP_PROFILE" },
    { "/fc minimap", "HELP_MINIMAP" },
    { "/fc reset window", "HELP_RESET" },
    { "/fc debug", "HELP_DEBUG" },
}

function Commands:PrintHelp()
    FC:Print(L.HELP_HEADER, FC.version)
    for _, entry in ipairs(HELP) do
        DEFAULT_CHAT_FRAME:AddMessage("  |cffd8b25c" .. entry[1] .. "|r  " .. L[entry[2]])
    end
end

function Commands:SyncStatus()
    local status = FC.Sync:Status()
    FC:Print(L.SYNC_STATUS_LINE,
        status.enabled and L.ON or L.OFF,
        status.channel and (L["CHANNEL_" .. status.channel] or status.channel) or L.NONE,
        status.peers, status.queue, status.stats.sent, status.stats.received, status.stats.dropped,
        status.lastOnline and U.TimeAgo(status.lastOnline) or L.NEVER)
end

function Commands:Run(input)
    input = U.Trim(input or "")
    local command, rest = input:match("^(%S*)%s*(.-)$")
    command = (command or ""):lower()

    if command == "" or command == "toggle" then
        FC.MainWindow:Toggle()
    elseif command == "journal" or command == "j" or command == "open" then
        FC.MainWindow:Show(rest ~= "" and rest:lower() or nil)
    elseif command == "add" or command == "new" or command == "capture" then
        FC.Editor:OpenNew(rest ~= "" and rest:lower() or nil)
    elseif command == "map" then
        FC.MainWindow:OpenMap()
    elseif command == "zone" or command == "guide" then
        FC.ZoneGuide:Toggle()
    elseif command == "quests" or command == "completed" or command == "questlog" then
        FC.MainWindow:ShowQuestLog()
    elseif command == "rescan" or command == "repair" or command == "recover" then
        -- reads again what the game remembers; nothing in the journal is deleted
        FC.QuestHistory:Rescan()
    elseif command == "search" or command == "find" then
        FC.MainWindow:SetSearch(rest)
    elseif command == "settings" or command == "config" or command == "options" then
        FC.SettingsWindow:Show(rest ~= "" and rest:lower() or nil)
    elseif command == "sync" then
        local sub = rest:lower()
        if sub == "status" then
            self:SyncStatus()
        elseif sub == "ping" then
            if FC.Sync:Ping() then
                FC:Print(L.SYNC_PING_SENT)
                C_Timer.After(3, function()
                    local pongs = FC.Sync.pongs or {}
                    FC:Print(L.SYNC_PING_RESULT, #pongs)
                    for _, pong in ipairs(pongs) do
                        DEFAULT_CHAT_FRAME:AddMessage("  " .. U.ShortName(pong.sender) .. "  " .. pong.ms .. " ms")
                    end
                end)
            else
                FC:Print(L.MSG_SYNC_DISABLED)
            end
        elseif FC.Sync:Resync() then
            FC:Print(L.SYNC_STARTED)
        else
            FC:Print(L.MSG_SYNC_DISABLED)
        end
    elseif command == "export" then
        local text, count = FC.ImportExport:ExportBackup()
        if text then FC.UI.TextDialog(string.format(L.DATA_EXPORT_TITLE, count or 0), text, true) end
    elseif command == "import" then
        FC.UI.TextDialog(L.DATA_IMPORT, "", false, function(text)
            local result, err = FC.ImportExport:Import(text)
            FC:Print(result and FC.ImportExport:Describe(result) or string.format(L.IMPORT_FAILED, err or "?"))
        end)
    elseif command == "profile" then
        if rest == "" then
            FC:Print(L.SETTINGS_PROFILE, FC.Profiles:GetActive())
        elseif FC.Profiles:Exists(rest) then
            FC.Profiles:Activate(rest)
        else
            FC:Print(L.PROFILE_NOT_FOUND)
        end
    elseif command == "minimap" then
        FC.Config:Set("general.minimap.show", not FC.P.general.minimap.show)
    elseif command == "reset" and rest:lower() == "window" then
        local w = FC.P.appearance.window
        w.point, w.relPoint, w.x, w.y = nil, nil, nil, nil
        w.width, w.height = 1100, 660
        FC.Config:Set("appearance.window", w)
        FC:Print(L.MSG_WINDOW_RESET)
    elseif command == "debug" then
        FC.DevTools:Command(rest)
    elseif command == "help" or command == "?" then
        self:PrintHelp()
    else
        FC:Print(L.MSG_UNKNOWN_COMMAND, command)
        self:PrintHelp()
    end
end

function Commands:OnInitialize()
    SLASH_FOREVERCOMPANION1 = "/fc"
    SLASH_FOREVERCOMPANION2 = "/fcj"
    SLASH_FOREVERCOMPANION3 = "/forevercompanion"
    SlashCmdList.FOREVERCOMPANION = function(input)
        if not FC.enabled then return end
        FC:SafeCall("command", self.Run, self, input)
    end
end
