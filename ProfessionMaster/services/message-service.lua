--[[

@author Kurki
@copyright ©2026 Profession Master. All Rights Reserved.

--]]

-- create service
local MessageService = _G.professionMaster:CreateService("message");

--- Initialize service.
function MessageService:Initialize()
    -- handle addon messages ("Pm" instead of the old "PmV" scheme saves one byte per message)
    self.messageVersion = 6;
    self.messagePrefix = "Pm" .. self.messageVersion;
    self.splitPatternCache = {};
    C_ChatInfo.RegisterAddonMessagePrefix(self.messagePrefix);

    -- messages handed to ChatThrottleLib per priority before waiting for its send
    -- callback; a small window keeps the bulk of a push in the own queue, where
    -- whispers to players who log off can still be purged
    self.MaxInFlight = 3;

    -- players the server reported as not playing (full name -> GetTime() of the
    -- error); the guild roster only learns of a logout with its next update, so
    -- whispers to them are held back until then (or for this many seconds)
    self.offlinePlayers = {};
    self.OfflineMemory = 600;
    self.playerNotFoundPattern = self:BuildSystemMessagePattern(_G.ERR_CHAT_PLAYER_NOT_FOUND_S) or "'(.+)'";
    self.friendOfflinePattern = self:BuildSystemMessagePattern(_G.ERR_FRIEND_OFFLINE_S);

    -- addon whisper targets (full name -> GetTime() of the last hand-off to
    -- ChatThrottleLib); "No player named" errors within this grace are the echo
    -- of own addon whispers and get hidden from the chat frames
    self.recentWhisperTargets = {};
    self.WhisperErrorGrace = 30;

    -- senders of addon messages this session (full name -> GetTime() of their
    -- last message): the players known to run the addon, used to elect the one
    -- !who responder and as proof of being online while the roster still shows
    -- them offline
    self.addonPlayers = {};
    self.OnlineProof = 60;

    -- wire compression via the native client api (present on all current classic
    -- clients); compressed messages carry this marker before the escaped stream
    self.CompressedMarker = "!";
    self.CompressMinSize = 64;
    self.canCompress = (C_EncodingUtil and C_EncodingUtil.CompressString and C_EncodingUtil.DecompressString
        and Enum.CompressionMethod and Enum.CompressionLevel) and true or false;

    -- escape maps for the compressed stream (addon messages must not contain zero bytes)
    self.EscapeMap = { ["\0"] = "\1\2", ["\1"] = "\1\3" };
    self.UnescapeMap = { ["\2"] = "\0", ["\3"] = "\1" };

    -- per-priority send queues: BULK carries sync data pushes, NORMAL everything
    -- else; ChatThrottleLib shares the wire budget of both with all other addons
    self.sendQueues = {};
    for _, priority in ipairs({ "NORMAL", "BULK" }) do
        local sendQueue = { queue = {}, head = 1, tail = 0, inFlight = 0, pumping = false };

        -- one shared send callback per priority (avoids one closure per message);
        -- the library hands back the queued item and whether the client sent it
        sendQueue.onSent = function(item, didSend, sendResult)
            sendQueue.inFlight = sendQueue.inFlight - 1;
            if (didSend == false) then
                self:LogSendFailure(item, sendResult);
            end
            self:Pump(priority);
        end;
        self.sendQueues[priority] = sendQueue;
    end

    -- refused sends (channel and result code) and received messages already
    -- logged this session: the log shows the first of each, not every message
    self.loggedSendFailures = {};
    self.loggedFirstMessages = {};

    self.addon:Log("MessageService", "Initialize", "Prefix %s, wire compression %s", self.messagePrefix, self.canCompress and "enabled" or "unavailable");

    -- register event
    self:HandleEvent("CHAT_MSG_ADDON", function(prefix, message, channel, sender)
        self:HandleMessage(prefix, message, sender, channel);
    end);

    -- detect offline players from system error messages and purge queued whispers
    self:HandleEvent("CHAT_MSG_SYSTEM", function(errorMessage)
        self:HandleSystemMessage(errorMessage);
    end);

    -- hide the residual "No player named" errors of own addon whispers: messages
    -- already handed to ChatThrottleLib when the target logs out cannot be purged
    -- anymore and the server answers each of them with this error
    self.addon.compat.ChatFrame_AddMessageEventFilter("CHAT_MSG_SYSTEM", function(_, _, systemMessage)
        return self:FilterSystemMessage(systemMessage);
    end);
end

--- Drain one priority queue into ChatThrottleLib (runs inside the pcall of Pump).
-- @param self The message service.
-- @param priority The priority queue to pump ("NORMAL" or "BULK").
-- @param sendQueue The queue state of that priority.
local function PumpQueue(self, priority, sendQueue)
    -- hand messages to the library until the window is full; the shared send
    -- callback (onSent) re-enters Pump and pulls the next message from the queue
    while (sendQueue.inFlight < self.MaxInFlight and sendQueue.head <= sendQueue.tail) do
        local item = sendQueue.queue[sendQueue.head];
        sendQueue.queue[sendQueue.head] = nil;
        sendQueue.head = sendQueue.head + 1;

        -- skip purged entries and whispers to players who went offline since enqueueing
        local skip = (not item) or (item.channel == "WHISPER" and item.target and not self:IsPlayerOnline(item.target));
        if (not skip) then
            -- whispers go to the name the server knows (without realm on WoW
            -- Forever); the queue keeps the full name for the offline tracking
            local target = item.target;
            if (item.channel == "WHISPER") then
                target = self:GetService("player"):GetWhisperTarget(target);
            end

            -- pcall with inFlight rollback: a send error must never leave the
            -- window counter raised, or the queue would fill up and stall forever
            sendQueue.inFlight = sendQueue.inFlight + 1;
            local success, sendError = pcall(ChatThrottleLib.SendAddonMessage, ChatThrottleLib, priority, self.messagePrefix, item.messageString, item.channel, target, nil, sendQueue.onSent, item);
            if (not success) then
                sendQueue.inFlight = sendQueue.inFlight - 1;
                self.addon:Log("MessageService", "Pump", "Send error: %s", tostring(sendError));
            elseif (item.channel == "WHISPER" and item.target) then
                -- remember the hand-off: a "No player named" error within the grace
                -- is the echo of this whisper and gets hidden from the chat
                self.recentWhisperTargets[item.target] = GetTime();
            end
        end
    end

    -- reset indices when fully drained (slots are already nil)
    if (sendQueue.head > sendQueue.tail) then
        sendQueue.head = 1;
        sendQueue.tail = 0;
    end
end

--- Hand queued messages of one priority over to ChatThrottleLib.
--- Only a small window is in flight at a time; the library paces all traffic
--- together with every other addon on the shared wire budget and calls back
--- after each submission, which pulls the next message from the queue.
-- @param priority The priority queue to pump ("NORMAL" or "BULK").
function MessageService:Pump(priority)
    local sendQueue = self.sendQueues[priority];

    -- guard against re-entrance from synchronous send callbacks
    if (sendQueue.pumping) then
        return;
    end

    -- pcall so an error can never leave the queue wedged behind the pumping flag
    sendQueue.pumping = true;
    local success, errorMessage = pcall(PumpQueue, self, priority, sendQueue);
    sendQueue.pumping = false;
    if (not success) then
        self.addon:Log("MessageService", "Pump", "Error while sending: %s", tostring(errorMessage));
    end
end

--- Log a message the client refused to send, once per channel and result per
--- session (the result code names the reason: not in a guild, target offline,
--- invalid target and so on); a refused message is gone.
-- @param item The queued item (channel, target).
-- @param sendResult Result code of the send (Enum.SendAddonMessageResult).
function MessageService:LogSendFailure(item, sendResult)
    local channel = item and item.channel;
    local failureKey = tostring(channel) .. ":" .. tostring(sendResult);
    if (self.loggedSendFailures[failureKey]) then
        return;
    end
    self.loggedSendFailures[failureKey] = true;

    -- name of the result code where the client knows the enumeration
    local resultName = tostring(sendResult);
    for name, value in pairs(Enum and Enum.SendAddonMessageResult or {}) do
        if (value == sendResult) then
            resultName = name;
            break;
        end
    end
    self.addon:Log("MessageService", "LogSendFailure", "Client refused a %s message to %s: %s", tostring(channel), tostring(item and item.target), resultName);
end

--- Enqueue a message for cooperative throttled delivery.
-- @param messageString The serialized message string.
-- @param channel The channel ("GUILD", "WHISPER", "RAID", "PARTY", "CHANNEL").
-- @param target The target player (for WHISPER), the channel number (for CHANNEL) or nil.
-- @param priority ChatThrottleLib priority ("NORMAL" or "BULK"), defaults to "NORMAL".
function MessageService:Enqueue(messageString, channel, target, priority)
    -- unknown or missing priorities ride the NORMAL queue
    if (not self.sendQueues[priority]) then
        priority = "NORMAL";
    end

    -- drop above WoW's 255-byte addon message limit: a cut payload is garbage on
    -- the receiver anyway and ChatThrottleLib refuses longer payloads with an error
    if (#messageString > 255) then
        self.addon:Log("MessageService", "Enqueue", "WARNING: message exceeds 255 bytes (%d bytes), dropped: %s", #messageString, string.sub(messageString, 1, 60));
        return;
    end

    -- add to queue and hand over to ChatThrottleLib
    local sendQueue = self.sendQueues[priority];
    sendQueue.tail = sendQueue.tail + 1;
    sendQueue.queue[sendQueue.tail] = {
        messageString = messageString,
        channel = channel,
        target = target
    };
    self:Pump(priority);
end

--- Build the wire form of a message (compressed when supported and smaller).
-- @param message Message model to serialize.
-- @return The wire string to enqueue.
function MessageService:BuildWireString(message)
    local messageString = message.prefix .. ":" .. message:ToString();

    -- plain form when the client cannot compress or the message is too small to win
    if (not self.canCompress or #messageString < self.CompressMinSize) then
        return messageString;
    end

    -- deflate, then escape zero bytes
    local compressed = C_EncodingUtil.CompressString(messageString, Enum.CompressionMethod.Deflate, Enum.CompressionLevel.OptimizeForSize);
    if (not compressed) then
        return messageString;
    end
    local escaped = string.gsub(compressed, "[%z\1]", self.EscapeMap);

    -- keep whichever form is smaller (short messages rarely win by deflate)
    local wireString = self.CompressedMarker .. escaped;
    if (#wireString < #messageString) then
        return wireString;
    end
    return messageString;
end

--- Unwrap a received wire string (inflate when the compressed marker is present).
-- @param wireString The received message string.
-- @return The plain message string, or nil if it cannot be decoded.
function MessageService:UnwrapWireString(wireString)
    -- plain messages pass through
    if (string.sub(wireString, 1, 1) ~= self.CompressedMarker) then
        return wireString;
    end

    -- clients without the native api cannot read compressed messages
    if (not self.canCompress) then
        if (not self.decompressUnavailableLogged) then
            self.decompressUnavailableLogged = true;
            self.addon:Log("MessageService", "UnwrapWireString", "WARNING: received compressed message but client cannot decompress");
        end
        return nil;
    end

    -- unescape and inflate (pcall guards against corrupted streams)
    local compressed = string.gsub(string.sub(wireString, 2), "\1([\2\3])", self.UnescapeMap);
    local success, messageString = pcall(C_EncodingUtil.DecompressString, compressed, Enum.CompressionMethod.Deflate);
    if (not success or not messageString) then
        self.addon:Log("MessageService", "UnwrapWireString", "WARNING: dropped undecodable compressed message (%d bytes)", #wireString);
        return nil;
    end
    return messageString;
end

--- Handle message.
-- @param prefix Addon message prefix.
-- @param message Wire string.
-- @param sender Sender name.
-- @param channel Distribution the message arrived on ("GUILD", "WHISPER", "CHANNEL", ...).
function MessageService:HandleMessage(prefix, message, sender, channel)
    -- check if is addon prefix
    if (prefix ~= self.messagePrefix) then
        return;
    end

    -- the first own echo and the first message of another player per session
    -- show that messages arrive and how the client writes sender names
    local playerService = self:GetService("player");
    local isOwnMessage = playerService:IsCurrentPlayer(sender);
    local messageKind = isOwnMessage and "own" or "other";
    if (not self.loggedFirstMessages[messageKind]) then
        self.loggedFirstMessages[messageKind] = true;
        self.addon:Log("MessageService", "HandleMessage", "First %s message this session: %s via %s", messageKind, tostring(sender), tostring(channel));
    end

    -- check if own player or a player on the ignore list
    if (isOwnMessage or playerService:IsIgnored(sender)) then
         return;
    end

    -- a message from the player proves they are back online and run the addon
    local senderFullName = playerService:GetLongName(sender);
    self.offlinePlayers[senderFullName] = nil;
    self.addonPlayers[senderFullName] = GetTime();

    -- unwrap compressed messages
    message = self:UnwrapWireString(message);
    if (not message) then
        return;
    end

    -- get prefix and content (guard against malformed messages without colon)
    local colonPos = string.find(message, ":");
    if (not colonPos) then
        return;
    end
    local messagePrefix = string.sub(message, 1, colonPos - 1);
    local messageContent = string.sub(message, colonPos + 1);

    -- link messages (handshake with linked accounts, presence beacon) first,
    -- they never reach the profession sync
    local linkSuccess, linkError = pcall(function()
        return self:GetService("link"):CheckMessage(messagePrefix, sender, messageContent, channel);
    end);
    if (not linkSuccess) then
        self.addon:Log("MessageService", "HandleMessage", "Error processing link message from %s: %s", sender, tostring(linkError));
        return;
    elseif (linkError) then
        return;
    end

    -- check message (pcall to prevent corrupted messages from crashing the addon)
    local success, errorMessage = pcall(function()
        self:GetService("profession-sync"):CheckMessage(messagePrefix, sender, messageContent);
    end);
    if (not success) then
        self.addon:Log("MessageService", "HandleMessage", "Error processing message from %s: %s", sender, tostring(errorMessage));
    end

    -- check version message
    local versionSuccess, versionError = pcall(function()
        self:GetService("version"):CheckMessage(messagePrefix, sender, messageContent);
    end);
    if (not versionSuccess) then
        self.addon:Log("MessageService", "HandleMessage", "Error processing version message from %s: %s", sender, tostring(versionError));
    end
end

--- Split string.
function MessageService:SplitString(value, separator)
    -- get or build cached pattern
    local pattern = self.splitPatternCache[separator];
    if (not pattern) then
        pattern = "([^" .. separator .. "]+)";
        self.splitPatternCache[separator] = pattern;
    end

    -- split value by pattern
    local result = {};
    local n = 0;
    for part in string.gmatch(value, pattern) do
        n = n + 1;
        result[n] = part;
    end
    return result;
end

--- Trim string.
function MessageService:TrimString(value)
    local match = string.match;
    return match(value, "^()%s*$") and "" or match(value, "^%s*(.*%S)");
end

--- Send message to guild.
-- @param message Message to send.
-- @param priority Optional ChatThrottleLib priority, defaults to "NORMAL".
function MessageService:SendToGuild(message, priority)
    -- check if player is in guild
    if (not IsInGuild()) then
        return;
    end

    -- build message string and enqueue
    local messageString = self:BuildWireString(message);
    self:Enqueue(messageString, "GUILD", nil, priority);
end

--- Send message to player.
-- @param player Name of player to send message to.
-- @param message Message to send.
-- @param priority Optional ChatThrottleLib priority, defaults to "NORMAL".
function MessageService:SendToPlayer(player, message, priority)
    -- skip if player is known to be offline
    if (not self:IsPlayerOnline(player)) then
        return;
    end

    -- build message string and enqueue
    local messageString = self:BuildWireString(message);
    self:Enqueue(messageString, "WHISPER", player, priority);
end

--- Send message to a chat channel (the hidden link channel).
-- @param channelId Number of the joined channel.
-- @param message Message to send.
-- @param priority Optional ChatThrottleLib priority, defaults to "NORMAL".
function MessageService:SendToChannel(channelId, message, priority)
    if (not channelId or channelId == 0) then
        return;
    end
    local messageString = self:BuildWireString(message);
    self:Enqueue(messageString, "CHANNEL", channelId, priority);
end

--- Send message to the guild and to the online characters of linked accounts
--- that are not guild members themselves (they would get it twice otherwise).
-- @param message Message to send.
-- @param priority Optional ChatThrottleLib priority, defaults to "NORMAL".
function MessageService:Broadcast(message, priority)
    self:SendToGuild(message, priority);
    local playerService = self:GetService("player");
    for _, partnerName in ipairs(self:GetService("link"):GetOnlinePartnerCharacters()) do
        if (not playerService.guildmates[partnerName]) then
            self:SendToPlayer(partnerName, message, priority);
        end
    end
end

--- Build the Lua pattern of a system message from its global string, so the
--- player name is found in every locale.
-- @param template The global string with one %s placeholder (e.g. ERR_CHAT_PLAYER_NOT_FOUND_S).
-- @return The anchored pattern with one capture for the player name, or nil when the global string is missing or unusual.
function MessageService:BuildSystemMessagePattern(template)
    if (type(template) ~= "string" or not string.find(template, "%s", 1, true)) then
        return nil;
    end

    -- escape pattern magic characters, then turn the name placeholder into a capture
    local pattern = string.gsub(template, "[%^%$%(%)%%%.%[%]%*%+%-%?]", "%%%0");
    pattern = string.gsub(pattern, "%%%%s", "(.+)", 1);
    return "^" .. pattern .. "$";
end

--- Handle system messages to detect offline player errors.
-- @param errorMessage The system message string.
function MessageService:HandleSystemMessage(errorMessage)
    -- "No player named 'X' is currently playing" (a whisper failed) and
    -- "X has gone offline." (logout broadcast, arrives before the roster
    -- update and before the first error) both mark the player offline
    local offlineName = string.match(errorMessage, self.playerNotFoundPattern);
    local fromWhisperError = offlineName ~= nil;
    if (not offlineName and self.friendOfflinePattern) then
        offlineName = string.match(errorMessage, self.friendOfflinePattern);
    end
    if (not offlineName) then
        return;
    end

    -- resolve to full name (with realm)
    local fullName = self:GetService("player"):GetLongName(offlineName);
    self:MarkPlayerOffline(fullName, fromWhisperError);
end

--- Remember a player as offline and purge the queued whispers to them.
--- The guild roster only learns of a logout with its next update, until then
--- every further whisper would raise the "No player named" error again.
-- @param fullName Full name of the player (Name-Realm).
-- @param fromWhisperError True when a whisper error reported the logout (logged once).
function MessageService:MarkPlayerOffline(fullName, fromWhisperError)
    local alreadyOffline = self.offlinePlayers[fullName] ~= nil;
    self.offlinePlayers[fullName] = GetTime();

    -- purge all queued whispers to this player (in-flight ones are already at the lib)
    local purgedCount = 0;
    for _, sendQueue in pairs(self.sendQueues) do
        for index = sendQueue.head, sendQueue.tail do
            local item = sendQueue.queue[index];
            if (item and item.channel == "WHISPER" and item.target == fullName) then
                sendQueue.queue[index] = nil;
                purgedCount = purgedCount + 1;
            end
        end
    end

    -- log the first whisper error and every purge, not each repeated error and
    -- not the plain logout broadcast of uninvolved players
    if (purgedCount > 0 or (fromWhisperError and not alreadyOffline)) then
        self.addon:Log("MessageService", "MarkPlayerOffline", "Player %s offline, purged %d queued messages", fullName, purgedCount);
    end
end

--- Decide whether a system message is the whisper error of own addon traffic.
--- Messages already handed to ChatThrottleLib when the target logs out cannot
--- be purged anymore; their errors are hidden from the chat frames. Errors of
--- manual whispers stay visible (their target was never handed off by PM).
-- @param systemMessage The system message string.
-- @return true when the message should be hidden from the chat frame.
function MessageService:FilterSystemMessage(systemMessage)
    -- only the "No player named 'X' is currently playing" error is ever hidden
    local offlineName = string.match(systemMessage, self.playerNotFoundPattern);
    if (not offlineName) then
        return false;
    end

    -- hide only when the addon whispered this player shortly before
    local fullName = self:GetService("player"):GetLongName(offlineName);
    local sentAt = self.recentWhisperTargets[fullName];
    if (sentAt and GetTime() - sentAt < self.WhisperErrorGrace) then
        return true;
    end
    return false;
end

--- Check if a player sent an addon message this session, so they run the addon.
-- @param playerName Full name of the player to check (Name-Realm).
function MessageService:HasAddon(playerName)
    return self.addonPlayers[playerName] ~= nil;
end

--- Check if a player is online (based on guild roster and detected offline errors).
-- @param playerName Full name of the player to check (Name-Realm).
-- @return true if the player is online or status is unknown, false if confirmed offline.
function MessageService:IsPlayerOnline(playerName)
    local playerService = self:GetService("player");
    local guildPlayer = playerService.guildmates[playerName];

    -- a message just received proves the player is online: the roster keeps its
    -- online flag until the next update and reported guild members who had just
    -- logged in as offline, which dropped the answer to their sync hello
    local lastMessageAt = self.addonPlayers[playerName];
    local offlineSince = self.offlinePlayers[playerName];
    if (lastMessageAt and (GetTime() - lastMessageAt) < self.OnlineProof
        and ((not offlineSince) or offlineSince < lastMessageAt)) then
        return true;
    end

    -- check guild roster for online status
    if (guildPlayer and not guildPlayer.online) then
        return false;
    end

    -- players the server reported offline stay blocked until a roster update
    -- after the error lists them online again (relog) or the memory expires
    local offlineSince = self.offlinePlayers[playerName];
    if (offlineSince) then
        local rosterRefreshedAt = playerService.guildmatesRefreshedAt or 0;
        local relogged = guildPlayer and guildPlayer.online and rosterRefreshedAt > offlineSince;
        if (not relogged and GetTime() - offlineSince < self.OfflineMemory) then
            return false;
        end
        self.offlinePlayers[playerName] = nil;
    end

    -- unknown players or online players pass through
    return true;
end
