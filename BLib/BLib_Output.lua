-- BLib_Output.lua
-- A chat tab that carries nothing but addon output.
--
-- Probe output is meant to be copied out of the game, and in the main chat
-- frame it arrives shuffled together with trade spam and combat text. Pasting
-- a measurement then means picking our lines out of somebody selling a Minor
-- Mana Potion. A window with no message groups and no channels attached gets
-- nothing except what an addon puts there, so /cc copies a clean run.
--
--   /blib tab      make the window (or show it if it already exists)
--   /blib tab off  send output back to the default chat frame
--
-- Creating it is a deliberate command, never automatic -- it changes the
-- player's chat layout, and Blizzard saves that between sessions -- with one
-- exception, added in 1.4.1 and explained at the bottom of this file: the
-- OPT-IN is account-wide but the WINDOW is per-character, so a new character
-- inherits the preference without the tab it refers to.

BLib = BLib or {}

BLib.OUTPUT_TAB = "Addons"

-- ============================================================
-- FINDING THE WINDOW
-- ============================================================

local function FindWindow(name)
    local count = NUM_CHAT_WINDOWS or 10
    for i = 1, count do
        local windowName = GetChatWindowInfo and GetChatWindowInfo(i)
        if windowName and windowName ~= "" and windowName:lower() == name:lower() then
            return _G["ChatFrame" .. i], i
        end
    end
end

-- The frame addon output should go to: ours when it exists, the default frame
-- when it does not. Resolved per call, so an addon that printed before the tab
-- was made starts using it the moment it appears.
function BLib.OutputFrame()
    if BLibDB and BLibDB.outputTab == false then
        return DEFAULT_CHAT_FRAME
    end
    return (FindWindow(BLib.OUTPUT_TAB)) or DEFAULT_CHAT_FRAME
end

-- A continuation line: same frame, no prefix. Multi-line output that puts its
-- heading in one window and its body in another is worse than no tab at all,
-- which is exactly what Raidmaster's /rm status did before this existed.
function BLib.PrintLine(text)
    local frame = BLib.OutputFrame()
    if frame and frame.AddMessage then
        frame:AddMessage(tostring(text))
    else
        print(text)
    end
end

-- BLib.Print("Raidmaster", "text") -> "Raidmaster text", in the addon tab.
function BLib.Print(prefix, text)
    local frame = BLib.OutputFrame()
    local line = prefix
        and ("|cffffd100" .. prefix .. "|r " .. tostring(text))
        or tostring(text)

    if frame and frame.AddMessage then
        frame:AddMessage(line)
    else
        print(line)
    end
end

-- ============================================================
-- MAKING IT
--
-- FCF_* are FrameXML, not documented API, so every one of them is checked
-- before it is called rather than assumed to exist on this client.
-- ============================================================

function BLib.CreateOutputTab()
    local existing = FindWindow(BLib.OUTPUT_TAB)
    if existing then
        if existing.Show then existing:Show() end
        return existing, false
    end

    if type(FCF_OpenNewWindow) ~= "function" then
        return nil, false, "FCF_OpenNewWindow is missing on this client"
    end

    local ok, frame = pcall(FCF_OpenNewWindow, BLib.OUTPUT_TAB)
    if not ok then
        return nil, false, tostring(frame)
    end

    frame = frame or FindWindow(BLib.OUTPUT_TAB)
    if not frame then
        return nil, false, "the window was not created (ten windows already?)"
    end

    -- A fresh window inherits message groups on some clients. Strip everything,
    -- so the tab carries addon output and nothing else, which is the point.
    if type(ChatFrame_RemoveAllMessageGroups) == "function" then
        pcall(ChatFrame_RemoveAllMessageGroups, frame)
    end
    if type(ChatFrame_RemoveAllChannels) == "function" then
        pcall(ChatFrame_RemoveAllChannels, frame)
    end

    return frame, true
end

-- ============================================================
-- SLASH
-- ============================================================

SLASH_BLIB1 = "/blib"
SlashCmdList["BLIB"] = function(input)
    -- /blib profile ...: every addon's settings saved, loaded and shared (BLib_Profiles.lua, loaded after this
    -- file). Before the lowercasing below, so a profile's name keeps its case and its spaces.
    local rest = (input or ""):match("^%s*[Pp][Rr][Oo][Ff][Ii][Ll][Ee][Ss]?%s*(.*)$")
    if rest and BLib.Profiles then
        BLib.Profiles.Slash(rest)
        return
    end
    -- /blib taint [on|off]: which of Blizzard's globals an addon has written (BLib_Taint.lua, loaded after this file).
    local taintArg = (input or ""):match("^%s*[Tt][Aa][Ii][Nn][Tt]%s*(.*)$")
    if taintArg and BLib.Taint then
        BLib.Taint.Slash(taintArg)
        return
    end

    local cmd, arg = (input or ""):lower():match("^(%S*)%s*(%S*)%s*$")

    if cmd == "tab" then
        if arg == "off" then
            if BLibDB then BLibDB.outputTab = false end
            print("|cffffd100BLib|r addon output goes back to the default chat frame.")
            return
        end

        if BLibDB then BLibDB.outputTab = true end

        local frame, created, err = BLib.CreateOutputTab()
        if not frame then
            print("|cffffd100BLib|r could not make the tab: " .. tostring(err))
            return
        end

        BLib.Print("BLib", created
            and ("made the |cffffffff" .. BLib.OUTPUT_TAB .. "|r tab. Addon output lands here from now on.")
            or ("the |cffffffff" .. BLib.OUTPUT_TAB .. "|r tab already exists; output lands here."))
        return
    end

    -- Looked up when typed rather than at load, so this file needs nothing
    -- from BLib_Comm.lua, which loads after it.
    -- /blib move [addon]: the edit mode for every addon's frames (BLib_Layout.lua, loaded after this file).
    if cmd == "move" and BLib.Layout then
        BLib.Layout:Toggle(arg ~= "" and arg or nil)
        return
    end

    if cmd == "comm" and arg == "test" and BLib.Comm and BLib.Comm.RunProbe then
        BLib.Comm:RunProbe()
        return
    end

    local getMeta = (C_AddOns and C_AddOns.GetAddOnMetadata) or GetAddOnMetadata
    print("|cffffd100BLib|r v" .. tostring(getMeta and getMeta("BLib", "Version") or "?"))
    print("  |cffffffff/blib move|r  edit mode: move every addon's frames at once (also |cffffffff/move|r)")
    print("  |cffffffff/blib profile|r  save, load and share every addon's settings (copy a layout to another character)")
    print("  |cffffffff/blib taint|r  which of Blizzard's globals an addon has written (|cffffffff/blib taint on|r, then /reload)")
    print("  |cffffffff/blib tab|r  a chat tab carrying only addon output, for clean copy-paste")
    print("  |cffffffff/blib tab off|r  send it back to the default chat frame")
    print("  |cffffffff/blib comm test|r  whisper yourself addon messages and time the echo")
end

-- ============================================================
-- THE TAB FOLLOWS THE PLAYER, NOT THE CHARACTER
--
-- BLibDB is account-wide, so `/blib tab` opts IN for every character. The chat
-- window it refers to is stored by Blizzard in the per-character chat layout,
-- so a NEW character inherits the preference and none of the window.
--
-- OutputFrame then falls back to DEFAULT_CHAT_FRAME without complaint, and
-- addon output lands in the main window shuffled in with General -- which is
-- exactly what the tab exists to prevent, and it looks like the addon is
-- shouting into a public channel. (It is not: AddMessage only ever draws
-- locally. But being told "your addon posted in General" is reason enough.)
--
-- So: where the player has ALREADY opted in, make the window on a character
-- that lacks it. That is honouring the choice they made, not making one for
-- them -- the preference is still theirs to set and `/blib tab off` still
-- turns it off. A character where they never opted in is untouched.
-- ============================================================

local restore = CreateFrame("Frame")
restore:RegisterEvent("PLAYER_LOGIN")
restore:SetScript("OnEvent", function()
    if not (BLibDB and BLibDB.outputTab == true) then return end

    -- Deferred: the chat layout is restored around login, and asking for the
    -- window list too early finds a half-built one.
    local function Restore()
        if FindWindow(BLib.OUTPUT_TAB) then return end

        local frame, created = BLib.CreateOutputTab()
        if frame and created then
            BLib.Print("BLib", "remade the |cffffffff" .. BLib.OUTPUT_TAB
                .. "|r tab for this character. |cff888888The setting is"
                .. " account-wide; the window is not.|r")
        end
    end

    if C_Timer and C_Timer.After then C_Timer.After(2, Restore) else Restore() end
end)
