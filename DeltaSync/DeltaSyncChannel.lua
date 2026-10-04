-- DeltaSyncChannel.lua
-- Optional channel transport module for DeltaSync-1.0.
--
-- Adds CHANNEL distribution support via SendChatMessage + CHAT_MSG_CHANNEL,
-- working around WoW Classic's silent drop of CHAT_MSG_ADDON for custom channel
-- numbers.  Load this file (after DeltaSync.lua) only when your addon uses
-- distribution = "CHANNEL".  Addons that only use GUILD/PARTY/RAID/WHISPER
-- should not load this file at all.
--
-- Usage in your TOC:
--   Libs\DeltaSync\DeltaSync.lua
--   Libs\DeltaSync\DeltaSyncChannel.lua   ← only if you need CHANNEL dist
--
-- Usage in DeltaSync:Initialize():
--   channelModule = {
--       enabled      = true,
--       serializer   = function(payload) -> string | nil,
--       deserializer = function(message, sender) -> payload | nil,
--   }

local MAJOR = "DeltaSync-1.0"
local lib = LibStub and LibStub(MAJOR, true)
if not lib then
    error("DeltaSyncChannel.lua: DeltaSync-1.0 is not loaded. Ensure DeltaSync.lua appears before DeltaSyncChannel.lua in your TOC.")
end

-- ============================================================================
-- lib:InitChannelModule()
-- ============================================================================
-- Registers the CHAT_MSG_CHANNEL receive frame for every prefix whose
-- channelConfig.distribution == "CHANNEL".
-- Called automatically by DeltaSync:Initialize() when channelModule.enabled = true.

function lib:InitChannelModule()
    local cm = self.channelModule
    if not cm or not cm.enabled then return end

    -- Build prefix -> { chType, channel } lookup for CHANNEL-configured prefixes.
    --
    -- A CHANNEL-distributed prefix MUST name its channel. The match below used
    -- to read `not info.channel or <name matches>`, so a prefix whose `channel`
    -- was simply omitted did not listen to nothing -- it listened to EVERY
    -- channel the player was in: General, Trade, LookingForGroup, anyone's
    -- custom channel. Any player could then put `<prefix><payload>` into a
    -- public message and drive an OnComm_* handler on every listening client
    -- at once -- one-to-many, where a whisper is one-to-one (AUDIT finding 14).
    -- And the wide-open reading was what you got by FORGETTING a field, which
    -- is the direction a mistake actually goes. So: a missing name is a
    -- misconfiguration, refused and said aloud; a genuine listen-everywhere
    -- must be spelled `channel = "*"` so it is a decision somebody made.
    local channelPrefixes = {}
    for chType, chConfig in pairs(self.channelConfig) do
        if chConfig.distribution == "CHANNEL" and self.prefixes[chType] then
            if type(chConfig.channel) ~= "string" or chConfig.channel == "" then
                local msg = string.format(
                    "channel %s is distribution=CHANNEL but names no channel -- NOT registered. " ..
                    "Set channels.%s.channel to the channel name (or to \"*\" to deliberately " ..
                    "listen on every channel).", chType, chType)
                self:Debug("INIT", "ChannelModule: " .. msg)
                print("|cffff8800[DeltaSync]|r " .. msg)
            else
                channelPrefixes[self.prefixes[chType]] = { chType = chType, channel = chConfig.channel }
            end
        end
    end

    if not next(channelPrefixes) then
        self:Debug("INIT", "ChannelModule: no CHANNEL-distribution prefixes configured, skipping CHAT_MSG_CHANNEL handler")
        return
    end

    -- Does an inbound message's channel satisfy a prefix's configured channel?
    local function ChannelMatches(info, channelName)
        if info.channel == "*" then return true end
        return channelName ~= nil and channelName:lower() == info.channel:lower()
    end

    local frame = CreateFrame("Frame")
    frame:RegisterEvent("CHAT_MSG_CHANNEL")
    frame:SetScript("OnEvent", function(_, event, message, sender, language, channelString, target, flags, unknown, channelNumber, channelName)
        local ok, err = pcall(function()
        -- Early-out for channels we don't care about (avoids logging noise from
        -- Grouper, GuildMerge, etc.).
        local relevantChannel = false
        for _, info in pairs(channelPrefixes) do
            if ChannelMatches(info, channelName) then
                relevantChannel = true
                break
            end
        end
        if not relevantChannel then return end

        self:Debug("COMMS", "RECEIVE",
            ">>> [ChannelModule.OnEvent] chan='%s' chanStr='%s' sender='%s' msg='%.30s'",
            tostring(channelName), tostring(channelString), tostring(sender),
            tostring(message))

        -- Self-filter: WoW delivers CHAT_MSG_CHANNEL for our own sent messages too.
        -- Use pre-computed names from Initialize() — avoids nil-concat crash if
        -- UnitName("player") returns nil inside a SetScript event handler.
        -- Normalize sender (removes spaces from realm, e.g. "Foo-Old Blanchy" → "Foo-OldBlanchy")
        -- so the comparison is consistent regardless of how WoW reports the name.
        sender = self:_InboundSender(sender)
        if sender == self.playerName or sender == self.playerFullName then
            self:Debug("COMMS", "RECEIVE", "... [ChannelModule] self-filtered sender=%s", tostring(sender))
            return
        end

        -- Strip leading control chars WoW may prepend.
        -- Use %z for null byte — literal \0 inside [...] terminates the Lua 5.1
        -- pattern string at the C level, causing "malformed pattern (missing ']')".
        local cleanMsg = message:gsub("^[\127\t\n\r%z]+", "")

        for prefix, info in pairs(channelPrefixes) do
            local channelMatch = ChannelMatches(info, channelName)
            self:Debug("COMMS", "RECEIVE",
                "... [ChannelModule] prefix='%s' info.channel='%s' channelName='%s' channelMatch=%s prefixMatch=%s",
                prefix, tostring(info.channel), tostring(channelName), tostring(channelMatch),
                tostring(cleanMsg:sub(1, #prefix) == prefix))
            if channelMatch and cleanMsg:sub(1, #prefix) == prefix then
                local msgBody     = cleanMsg:sub(#prefix + 1)
                local handlerName = "OnComm_" .. info.chType
                self:Debug("COMMS", "RECEIVE",
                    ">>> [ChannelModule] MATCH prefix=%s chan=%s sender=%s bytes=%d",
                    prefix, tostring(channelName), tostring(sender), #msgBody)
                if self[handlerName] then
                    self[handlerName](self, prefix, msgBody, "CHANNEL", sender)
                end
                break
            end
        end
        end) -- pcall
        if not ok then
            -- Surface any previously-silent Lua errors in the debug log and chat.
            local errMsg = tostring(err)
            self:Debug("COMMS", "RECEIVE", "!!! [ChannelModule] OnEvent ERROR: %s", errMsg)
            if DEFAULT_CHAT_FRAME then
                DEFAULT_CHAT_FRAME:AddMessage("|cffff0000[DeltaSync] ChannelModule OnEvent error: " .. errMsg .. "|r")
            end
        end
    end)

    cm.frame = frame

    local count = 0
    for _ in pairs(channelPrefixes) do count = count + 1 end
    self:Debug("INIT", "ChannelModule: CHAT_MSG_CHANNEL handler registered (%d prefix(es))", count)
end

-- ============================================================================
-- lib:SendViaChannel()
-- ============================================================================
-- Low-level send for the CHANNEL transport.
-- Prepends prefix to body and sends via SendChatMessage.
-- Called automatically by DeltaSync:SendMessage() when distribution == "CHANNEL".
--
-- @param prefix  raw prefix string (8 chars, generated by DeltaSync)
-- @param body    already-encoded body string (must fit in 255 - #prefix bytes)
-- @param target  channel name string (e.g. "PersonalShopper")
-- @return true on success, false if channel not found

function lib:SendViaChannel(prefix, body, target)
    local channelNum = GetChannelName(target)
    self:Debug("COMMS", "SEND",
        "[ChannelModule] prefix='%s' target='%s' num=%s bytes=%d",
        prefix, tostring(target), tostring(channelNum), #body)
    if not channelNum or channelNum == 0 then
        self:Debug("COMMS", "SEND", "[ChannelModule] FAIL: channel '%s' not found", tostring(target))
        return false
    end
    local rawMsg = prefix .. body
    if #rawMsg > 255 then
        self:Debug("COMMS", "SEND",
            "[ChannelModule] WARN: message %d bytes > 255 cap, may be truncated", #rawMsg)
    end
    local ok, err = pcall(SendChatMessage, rawMsg, "CHANNEL", nil, tostring(channelNum))
    if not ok then
        self:Debug("COMMS", "SEND",
            "[ChannelModule] SendChatMessage blocked (protected context): %s", tostring(err))
        return false
    end
    self:Debug("COMMS", "SEND", "[ChannelModule] OK: %d bytes sent to channel %d", #rawMsg, channelNum)
    return true
end
