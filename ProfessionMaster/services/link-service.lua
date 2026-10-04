--[[

@author Kurki
@copyright ©2026 Profession Master. All Rights Reserved.

--]]

-- create service: links this account with other accounts on the same realm and
-- faction (own characters on a second account, friends outside the guild).
-- Trust is mutual: both sides enter one character of the other account, the
-- handshake runs over whispers, presence comes from a hidden chat channel and
-- the Battle.net friend list, the data itself flows through the normal sync
local LinkService = _G.professionMaster:CreateService("link");

--- Initialize service.
function LinkService:Initialize()
    -- hidden chat channel: presence beacon of linked characters, removed from
    -- all chat frames right after joining (see EnsureChannel)
    self.ChannelName = "PmLink";
    self.ChannelJoinDelay = 8;
    self.ChannelRetryDelay = 30;

    -- throttles: link requests per character, sync rounds per linked account,
    -- accept window for a link accept that answers an own request
    self.RequestThrottle = 60;
    self.SyncThrottle = 300;
    self.RequestWindow = 120;

    -- chunk limits (raw payload below the 255 byte addon message limit)
    self.AcceptChunkSize = 8;
    self.GuildChunkPayload = 200;

    -- session state: presence per character, one session per linked account,
    -- request throttles and open requests awaiting an accept
    self.onlineCharacters = {};
    self.sessions = {};
    self.requestTimes = {};
    self.pendingRequests = {};
    self.channelId = 0;
    self.changeListeners = {};
    self.ignoredSenders = {};
    self:BindNode();

    -- join and leave events of the hidden channel keep the presence current
    self:HandleEvent("CHAT_MSG_CHANNEL_JOIN", function(_, playerName, _, channelName, _, _, _, _, channelBaseName)
        if (self:IsOwnChannel(channelName, channelBaseName)) then
            self:NotePresence(playerName);
        end
    end);
    self:HandleEvent("CHAT_MSG_CHANNEL_LEAVE", function(_, playerName, _, channelName, _, _, _, _, channelBaseName)
        if (self:IsOwnChannel(channelName, channelBaseName)) then
            self:NoteAbsence(playerName);
        end
    end);

    -- hide the join and leave notices of the hidden channel from the chat frames
    self.addon.compat.ChatFrame_AddMessageEventFilter("CHAT_MSG_CHANNEL_NOTICE", function(_, _, ...)
        local channelName = select(4, ...);
        local channelBaseName = select(9, ...);
        return self:IsOwnChannel(channelName, channelBaseName);
    end);

    -- battle.net friends: a linked character that comes online on this realm
    -- is found there without the channel (debounced, the events fire in bursts)
    local function scheduleScan()
        if (self.friendScanPending) then
            self.friendScanPending:Cancel();
        end
        self.friendScanPending = C_Timer.NewTimer(5, function()
            self.friendScanPending = nil;
            self:ScanBattleNetFriends();
        end);
    end
    self:HandleEvent("BN_FRIEND_INFO_CHANGED", scheduleScan);
    self:HandleEvent("BN_FRIEND_ACCOUNT_ONLINE", scheduleScan);
    self:HandleEvent("BN_FRIEND_ACCOUNT_OFFLINE", scheduleScan);
end

--- Run the login actions: join the hidden channel and scan the friend list.
function LinkService:OnLogin()
    if (not self:HasTrust()) then
        return;
    end
    C_Timer.After(self.ChannelJoinDelay, function()
        self:EnsureChannel();
    end);
    C_Timer.After(5, function()
        self:ScanBattleNetFriends();
    end);
end

--- Check whether any trusted character or linked account exists.
function LinkService:HasTrust()
    return next(self.node.trustedCharacters) ~= nil or next(self.node.linkedAccounts) ~= nil;
end

--- Bind the persisted per realm and faction node of the player service:
--- characters the player trusts and the accounts confirmed through a
--- handshake. Called again when the player service moves to another node.
function LinkService:BindNode()
    self.node = self:GetService("player").node;
    if (not self.node.trustedCharacters) then self.node.trustedCharacters = {}; end
    if (not self.node.linkedAccounts) then self.node.linkedAccounts = {}; end
    self:RebuildIndexes();
end

--- Rebuild the lowercase lookups of trusted names, linked account characters
--- and members of guilds received from linked accounts. Everything that
--- changes the trust list, the linked accounts or their guilds calls this.
function LinkService:RebuildIndexes()
    local playerService = self:GetService("player");
    self.trustedIndex = {};
    self.linkedCharacterIndex = {};
    self.linkedMemberIndex = {};

    for name, _ in pairs(self.node.trustedCharacters) do
        self.trustedIndex[string.lower(playerService:GetLongName(name))] = name;
    end
    for storageId, account in pairs(self.node.linkedAccounts) do
        for _, characterName in ipairs(account.characters or {}) do
            self.linkedCharacterIndex[string.lower(playerService:GetLongName(characterName))] = storageId;
        end
    end
    for _, guildEntry in pairs(self.node.guilds) do
        if (guildEntry.linkedAccounts and next(guildEntry.linkedAccounts) and guildEntry.members) then
            for memberName, _ in pairs(guildEntry.members) do
                self.linkedMemberIndex[string.lower(playerService:GetLongName(memberName))] = true;
            end
        end
    end

    -- the visibility of players depends on these lookups
    playerService:InvalidateVisiblePlayerCache();
end

--- Check whether a character name is on the trust list.
function LinkService:IsTrustedName(name)
    return self.trustedIndex[string.lower(self:GetService("player"):GetLongName(name))] ~= nil;
end

--- Check whether a character belongs to a linked account.
-- @return The storage id of the linked account or nil.
function LinkService:GetLinkedAccountByCharacter(name)
    return self.linkedCharacterIndex[string.lower(self:GetService("player"):GetLongName(name))];
end

--- Check whether a player is known through a link: a character of a linked
--- account or a member of a guild received from one.
function LinkService:IsLinkedPlayer(name)
    local key = string.lower(self:GetService("player"):GetLongName(name));
    return self.linkedCharacterIndex[key] ~= nil or self.linkedMemberIndex[key] == true;
end

--- Check whether a linked character is online right now (presence signal
--- seen and no whisper error since).
function LinkService:IsCharacterOnline(fullName)
    if (not self.onlineCharacters[fullName]) then
        return false;
    end
    return self:GetService("message"):IsPlayerOnline(fullName);
end

--- Get the online characters of all linked accounts (whisper targets for
--- broadcasts that would otherwise only reach the guild).
function LinkService:GetOnlinePartnerCharacters()
    local characters = {};
    for _, session in pairs(self.sessions) do
        if (session.character and self:IsCharacterOnline(session.character)) then
            table.insert(characters, session.character);
        end
    end
    return characters;
end

--- Check whether a link session with this character is active.
function LinkService:HasSessionWith(fullName)
    for _, session in pairs(self.sessions) do
        if (session.character == fullName) then
            return true;
        end
    end
    return false;
end

--- Note a presence signal of a character (channel join, channel hello,
--- battle.net friend list) and open the link when the character is trusted.
function LinkService:NotePresence(name)
    local playerService = self:GetService("player");
    local fullName = playerService:GetLongName(name);
    if (not fullName or playerService:IsCurrentPlayer(fullName)) then
        return;
    end
    self:MarkOnline(fullName);

    -- trusted by name or a known character of a linked account: open the link
    -- unless a session with exactly this character is running already
    local trusted = self:IsTrustedName(fullName) or self:GetLinkedAccountByCharacter(fullName) ~= nil;
    if (trusted and not self:HasSessionWith(fullName)) then
        self:RequestLink(fullName);
    end
end

--- Remember a character as online.
function LinkService:MarkOnline(fullName)
    local wasOnline = self.onlineCharacters[fullName] ~= nil;
    self.onlineCharacters[fullName] = GetTime();
    self:GetService("message").offlinePlayers[fullName] = nil;
    if (not wasOnline and self:IsLinkedPlayer(fullName)) then
        self:NotifyChanged();
    end
end

--- Note that a character left the hidden channel (logout).
function LinkService:NoteAbsence(name)
    local fullName = self:GetService("player"):GetLongName(name);
    if (not fullName or not self.onlineCharacters[fullName]) then
        return;
    end
    self.onlineCharacters[fullName] = nil;
    self.pendingRequests[fullName] = nil;

    -- queued whispers to the character are dropped, the session waits for
    -- the next character of that account
    self:GetService("message"):MarkPlayerOffline(fullName);
    for storageId, session in pairs(self.sessions) do
        if (session.character == fullName) then
            session.character = nil;
            self.addon:Log("LinkService", "NoteAbsence", "Linked character %s went offline (account %s)", fullName, storageId);
        end
    end
    self:NotifyChanged();
end

--- Whisper a link request to a trusted character.
function LinkService:RequestLink(fullName)
    local playerService = self:GetService("player");
    if (playerService:IsOwnCharacter(fullName)) then
        return;
    end

    -- one request per character and minute is enough, both sides request
    local lastRequest = self.requestTimes[fullName] or 0;
    if (GetTime() - lastRequest < self.RequestThrottle) then
        return;
    end
    self.requestTimes[fullName] = GetTime();
    self.pendingRequests[fullName] = GetTime();

    local LinkRequestMessage = self:GetModel("link-request-message");
    self:GetService("message"):SendToPlayer(fullName, LinkRequestMessage:Create(self.node.storageId));
    self.addon:Log("LinkService", "RequestLink", "Link request sent to %s", fullName);
end

--- Route incoming link messages.
-- @param prefix Message prefix.
-- @param sender Sender name.
-- @param message Message content.
-- @param channel Distribution the message arrived on ("CHANNEL", "WHISPER", ...).
-- @return true when the message was a link message.
function LinkService:CheckMessage(prefix, sender, message, channel)
    -- presence beacon of the hidden channel
    local LinkHelloMessage = self:GetModel("link-hello-message");
    if (prefix == LinkHelloMessage.prefix) then
        if (channel == "CHANNEL") then
            self:NotePresence(sender);
        end
        return true;
    end

    -- handshake and roster messages only count as whispers
    local LinkRequestMessage = self:GetModel("link-request-message");
    if (prefix == LinkRequestMessage.prefix) then
        if (channel == "WHISPER") then
            self:HandleLinkRequest(sender, LinkRequestMessage:Parse(message));
        end
        return true;
    end
    local LinkAcceptMessage = self:GetModel("link-accept-message");
    if (prefix == LinkAcceptMessage.prefix) then
        if (channel == "WHISPER") then
            self:HandleLinkAccept(sender, LinkAcceptMessage:Parse(message));
        end
        return true;
    end
    local LinkGuildMessage = self:GetModel("link-guild-message");
    if (prefix == LinkGuildMessage.prefix) then
        if (channel == "WHISPER") then
            self:HandleLinkGuild(sender, LinkGuildMessage:Parse(message));
        end
        return true;
    end
    return false;
end

--- Handle a link request: answer with the own character list when the sender
--- is trusted, ignore it otherwise (the other side sees "waiting").
function LinkService:HandleLinkRequest(sender, message)
    local playerService = self:GetService("player");
    local senderName = playerService:GetLongName(sender);
    local storageId = message.storageId;
    if (storageId == "" or storageId == self.node.storageId) then
        return;
    end

    -- trusted by name, or the account is linked already (a new alt of it)
    if (not self:IsTrustedName(senderName) and not self.node.linkedAccounts[storageId]) then
        if (not self.ignoredSenders[senderName]) then
            self.ignoredSenders[senderName] = true;
            self.addon:Log("LinkService", "HandleLinkRequest", "Ignored link request from %s (not trusted)", senderName);
        end
        return;
    end

    local session = self:EstablishLink(storageId, senderName);
    self:SendLinkAccept(senderName, session);
end

--- Handle a link accept: store the characters of the linked account, answer
--- with the own list once and start the sync round.
function LinkService:HandleLinkAccept(sender, message)
    local playerService = self:GetService("player");
    local senderName = playerService:GetLongName(sender);
    local storageId = message.storageId;
    if (storageId == "" or storageId == self.node.storageId) then
        return;
    end

    -- accept only from trusted names, linked accounts or as the answer to an
    -- own request sent within the request window
    local requestedAt = self.pendingRequests[senderName];
    local answersOwnRequest = requestedAt and (GetTime() - requestedAt < self.RequestWindow);
    if (not self:IsTrustedName(senderName) and not self.node.linkedAccounts[storageId] and not answersOwnRequest) then
        return;
    end

    local session = self:EstablishLink(storageId, senderName);
    local account = self.node.linkedAccounts[storageId];

    -- the first chunk replaces the character list, later chunks extend it
    if (message.first) then
        account.characters = {};
    end
    local known = {};
    for _, characterName in ipairs(account.characters) do
        known[characterName] = true;
    end
    for _, characterName in ipairs(message.characterNames) do
        local fullName = playerService:GetLongName(characterName);
        if (fullName and not known[fullName]) then
            known[fullName] = true;
            table.insert(account.characters, fullName);
        end
    end

    -- remember the account behind the trusted entries of these characters
    for trustedName, entry in pairs(self.node.trustedCharacters) do
        if (known[playerService:GetLongName(trustedName)]) then
            entry.storageId = storageId;
        end
    end
    self:RebuildIndexes();

    -- answer once per session, then both sides know each other's characters
    if (not session.acceptSent) then
        self:SendLinkAccept(senderName, session);
    end

    -- start the sync round after the last accept chunk arrived
    if (session.syncTimer) then
        session.syncTimer:Cancel();
    end
    session.syncTimer = C_Timer.NewTimer(2, function()
        session.syncTimer = nil;
        self:StartLinkSync(storageId);
    end);
    self:NotifyChanged();
end

--- Create or refresh the link with an account and remember which of its
--- characters is talking to us right now.
-- @return The session of the linked account.
function LinkService:EstablishLink(storageId, characterName)
    local account = self.node.linkedAccounts[storageId];
    if (not account) then
        account = { characters = {}, guilds = {}, linkedAt = time() };
        self.node.linkedAccounts[storageId] = account;
        self:GetService("chat"):Write("LinkedAccountConfirmed", self:GetService("player"):GetShortName(characterName));
        self.addon:Log("LinkService", "EstablishLink", "Linked account %s confirmed via %s", storageId, characterName);
    end

    -- a character we hear from belongs to that account for sure
    local listed = false;
    for _, existing in ipairs(account.characters) do
        if (existing == characterName) then
            listed = true;
            break;
        end
    end
    if (not listed) then
        table.insert(account.characters, characterName);
        self:RebuildIndexes();
    end

    local session = self.sessions[storageId];
    if (not session) then
        session = {};
        self.sessions[storageId] = session;
    end
    if (session.character ~= characterName) then
        session.character = characterName;
        session.acceptSent = false;
    end
    self.pendingRequests[characterName] = nil;
    self:MarkOnline(characterName);
    self:NotifyChanged();
    return session;
end

--- Whisper the own character list of this realm to a linked character.
function LinkService:SendLinkAccept(targetName, session)
    local playerService = self:GetService("player");
    local messageService = self:GetService("message");
    local LinkAcceptMessage = self:GetModel("link-accept-message");

    -- own characters of this node, the current one first
    local names = { playerService:GetRealmShortName(playerService.current) };
    for characterName, _ in pairs(self.node.own) do
        local fullName = playerService:GetLongName(characterName);
        if (fullName ~= playerService.current) then
            table.insert(names, playerService:GetRealmShortName(fullName));
        end
    end

    -- chunked, the first chunk resets the list on the receiver
    local chunk = {};
    local first = true;
    for _, name in ipairs(names) do
        table.insert(chunk, name);
        if (#chunk == self.AcceptChunkSize) then
            messageService:SendToPlayer(targetName, LinkAcceptMessage:Create(self.node.storageId, first, chunk));
            chunk = {};
            first = false;
        end
    end
    if (#chunk > 0 or first) then
        messageService:SendToPlayer(targetName, LinkAcceptMessage:Create(self.node.storageId, first, chunk));
    end
    session.acceptSent = true;
    self.addon:Log("LinkService", "SendLinkAccept", "Sent %d own characters to %s", #names, targetName);
end

--- Start a sync round with a linked account: share the guild rosters and let
--- the account with the smaller storage id open the digest exchange, so both
--- sides never push the same data at each other.
function LinkService:StartLinkSync(storageId)
    local session = self.sessions[storageId];
    if (not session or not session.character) then
        return;
    end
    if (GetTime() - (session.syncedAt or 0) < self.SyncThrottle) then
        return;
    end
    session.syncedAt = GetTime();

    self:SendGuildRosters(session.character);
    local opensExchange = self.node.storageId < storageId;
    if (opensExchange) then
        self:GetService("profession-sync"):SayHelloToPlayer(session.character);
    end
    self.addon:Log("LinkService", "StartLinkSync", "Sync round with account %s via %s (%s)", storageId, session.character, opensExchange and "hello sent" or "waiting for hello");
end

--- Whisper the member lists of all known guilds of this realm to a linked
--- character, chunked below the addon message limit.
function LinkService:SendGuildRosters(targetName)
    local playerService = self:GetService("player");
    local messageService = self:GetService("message");
    local LinkGuildMessage = self:GetModel("link-guild-message");
    local guildCount = 0;

    for guildName, guildEntry in pairs(self.node.guilds) do
        if (guildEntry.members and next(guildEntry.members)) then
            guildCount = guildCount + 1;

            -- prefix, chunk flag, guild name and separators leave this much for names
            local budget = self.GuildChunkPayload - #guildName;
            local chunk = {};
            local chunkLength = 0;
            local first = true;
            for memberName, _ in pairs(guildEntry.members) do
                local name = playerService:GetRealmShortName(playerService:GetLongName(memberName));
                if (chunkLength + #name + 1 > budget and #chunk > 0) then
                    messageService:SendToPlayer(targetName, LinkGuildMessage:Create(guildName, first, chunk), "BULK");
                    chunk = {};
                    chunkLength = 0;
                    first = false;
                end
                table.insert(chunk, name);
                chunkLength = chunkLength + #name + 1;
            end
            if (#chunk > 0) then
                messageService:SendToPlayer(targetName, LinkGuildMessage:Create(guildName, first, chunk), "BULK");
            end
        end
    end
    self.addon:Log("LinkService", "SendGuildRosters", "Sent %d guild rosters to %s", guildCount, targetName);
end

--- Handle a guild roster chunk of a linked account. Guilds the player is a
--- member of keep their own roster, other guilds take the received members
--- and become visible through the link.
function LinkService:HandleLinkGuild(sender, message)
    local playerService = self:GetService("player");
    local senderName = playerService:GetLongName(sender);
    local storageId = self:GetLinkedAccountByCharacter(senderName);
    local account = storageId and self.node.linkedAccounts[storageId];
    if (not account or message.guildName == "") then
        return;
    end

    -- mark the guild as received from this account
    local guildEntry = self.node.guilds[message.guildName];
    if (not guildEntry) then
        guildEntry = {};
        self.node.guilds[message.guildName] = guildEntry;
    end
    if (not guildEntry.linkedAccounts) then
        guildEntry.linkedAccounts = {};
    end
    guildEntry.linkedAccounts[storageId] = true;
    if (not account.guilds) then
        account.guilds = {};
    end
    account.guilds[message.guildName] = true;

    -- own guilds keep the roster of the game
    local ownGuild = (message.guildName == playerService.guildName) or (guildEntry.ownMembers and next(guildEntry.ownMembers) ~= nil);
    if (not ownGuild) then
        if (message.first or not guildEntry.members) then
            guildEntry.members = {};
        end
        for _, memberName in ipairs(message.memberNames) do
            local fullName = playerService:GetLongName(memberName);
            if (fullName) then
                guildEntry.members[fullName] = true;
            end
        end
    end

    -- rosters arrive in bursts: rebuild the lookups and refresh the views once
    if (self.rosterRebuildPending) then
        self.rosterRebuildPending:Cancel();
    end
    self.rosterRebuildPending = C_Timer.NewTimer(2, function()
        self.rosterRebuildPending = nil;
        self:RebuildIndexes();
        self:GetService("profession-store"):ScheduleRefresh();
        self:NotifyChanged();
    end);
end

--- Add a character of another account to the trust list.
-- @param name Character name as entered (with or without realm).
-- @return true when added, false with a reason ("own", "exists", "invalid") otherwise.
function LinkService:AddTrustedCharacter(name)
    local playerService = self:GetService("player");
    local trimmed = self:GetService("message"):TrimString(name or "");
    if (trimmed == "" or string.find(trimmed, "[%s,:]")) then
        return false, "invalid";
    end
    local fullName = playerService:GetLongName(trimmed);
    if (playerService:IsOwnCharacter(fullName)) then
        return false, "own";
    end
    if (self:IsTrustedName(fullName)) then
        return false, "exists";
    end

    self.node.trustedCharacters[fullName] = { addedAt = time() };
    self:RebuildIndexes();
    self.addon:Log("LinkService", "AddTrustedCharacter", "Added %s to the trust list", fullName);

    -- look for the character right away
    self:EnsureChannel();
    self:ScanBattleNetFriends();
    if (self.onlineCharacters[fullName]) then
        self:RequestLink(fullName);
    end
    self:NotifyChanged();
    return true;
end

--- Remove a character from the trust list; the linked account behind it is
--- dropped together with its data when no other trusted entry keeps it.
function LinkService:RemoveTrustedCharacter(fullName)
    local entry = self.node.trustedCharacters[fullName];
    if (not entry) then
        return;
    end
    local storageId = entry.storageId or self:GetLinkedAccountByCharacter(fullName);
    self.node.trustedCharacters[fullName] = nil;
    self.addon:Log("LinkService", "RemoveTrustedCharacter", "Removed %s from the trust list", fullName);

    -- unlink the account unless another trusted character still maps to it
    if (storageId) then
        local stillTrusted = false;
        for _, otherEntry in pairs(self.node.trustedCharacters) do
            if (otherEntry.storageId == storageId) then
                stillTrusted = true;
                break;
            end
        end
        if (not stillTrusted) then
            self:UnlinkAccount(storageId);
        end
    end
    self:RebuildIndexes();
    self:EnsureChannel();
    self:NotifyChanged();
end

--- Drop a linked account: its guilds lose the link mark (and vanish when no
--- own character is in them), players reachable only through it are purged.
function LinkService:UnlinkAccount(storageId)
    local playerService = self:GetService("player");
    local account = self.node.linkedAccounts[storageId];
    if (not account) then
        return;
    end

    for guildName, _ in pairs(account.guilds or {}) do
        local guildEntry = self.node.guilds[guildName];
        if (guildEntry and guildEntry.linkedAccounts) then
            guildEntry.linkedAccounts[storageId] = nil;
            local ownGuild = (guildName == playerService.guildName) or (guildEntry.ownMembers and next(guildEntry.ownMembers) ~= nil);
            if (not next(guildEntry.linkedAccounts) and not ownGuild) then
                self.node.guilds[guildName] = nil;
            end
        end
    end
    self.node.linkedAccounts[storageId] = nil;
    self.node.syncTimes[storageId] = nil;
    self.sessions[storageId] = nil;
    for _, entry in pairs(self.node.trustedCharacters) do
        if (entry.storageId == storageId) then
            entry.storageId = nil;
        end
    end
    self:RebuildIndexes();

    -- the account's characters and the members of its guilds are gone now
    local purgeService = self:GetService("purge");
    purgeService:PurgeUnanchoredPlayers("UnlinkAccount");
    self.addon:Log("LinkService", "UnlinkAccount", "Unlinked account %s", storageId);
end

--- Get the trust list for the settings page, sorted by name.
-- @return Array of { name, storageId, linked, onlineCharacter, lastSync, characterCount }.
function LinkService:GetTrustedEntries()
    local playerService = self:GetService("player");
    local entries = {};
    for name, entry in pairs(self.node.trustedCharacters) do
        local storageId = entry.storageId or self:GetLinkedAccountByCharacter(name);
        local account = storageId and self.node.linkedAccounts[storageId];
        local session = storageId and self.sessions[storageId];
        local onlineCharacter = nil;
        if (session and session.character and self:IsCharacterOnline(session.character)) then
            onlineCharacter = playerService:GetShortName(session.character);
        elseif (self.onlineCharacters[name] and self:IsCharacterOnline(name)) then
            onlineCharacter = playerService:GetShortName(name);
        end
        table.insert(entries, {
            name = name,
            displayName = playerService:GetRealmShortName(name),
            storageId = storageId,
            linked = account ~= nil,
            onlineCharacter = onlineCharacter,
            lastSync = storageId and self.node.syncTimes[storageId] or nil,
            characterCount = account and #account.characters or 0
        });
    end
    table.sort(entries, function(a, b)
        return a.name < b.name;
    end);
    return entries;
end

--- Register a callback for changes of the trust list, links or presence.
function LinkService:AddChangeListener(callback)
    table.insert(self.changeListeners, callback);
end

--- Notify the registered listeners (settings page).
function LinkService:NotifyChanged()
    for _, listener in ipairs(self.changeListeners) do
        pcall(listener);
    end
end

--- Check whether the hidden channel should be joined: at least one trusted
--- character or linked account exists.
function LinkService:ShouldUseChannel()
    return self:HasTrust();
end

--- Join or leave the hidden channel according to the current trust list.
function LinkService:EnsureChannel()
    if (not self:ShouldUseChannel()) then
        self:LeaveChannel();
        return;
    end
    local channelId = GetChannelName(self.ChannelName);
    if (channelId and channelId > 0) then
        self:OnChannelJoined();
        return;
    end
    JoinChannelByName(self.ChannelName);
    C_Timer.After(2, function()
        self:OnChannelJoined();
    end);
end

--- Finish a channel join: hide the channel from the chat frames and announce
--- the own presence. The join is asynchronous and can fail right after login,
--- so one retry follows when the channel is still unknown.
function LinkService:OnChannelJoined()
    local channelId = GetChannelName(self.ChannelName);
    if (not channelId or channelId == 0) then
        if (not self.channelRetryScheduled and self:ShouldUseChannel()) then
            self.channelRetryScheduled = true;
            C_Timer.After(self.ChannelRetryDelay, function()
                self.channelRetryScheduled = false;
                self:EnsureChannel();
            end);
            self.addon:Log("LinkService", "OnChannelJoined", "Channel %s not joined yet, retrying in %ds", self.ChannelName, self.ChannelRetryDelay);
        end
        return;
    end
    local firstJoin = self.channelId ~= channelId;
    self.channelId = channelId;
    self:HideChannel();
    if (firstJoin) then
        self.addon:Log("LinkService", "OnChannelJoined", "Joined hidden channel %s (%d)", self.ChannelName, channelId);
        self:SendChannelHello();
    end
end

--- Remove the hidden channel from every chat frame.
function LinkService:HideChannel()
    if (not self.addon.compat.ChatFrame_RemoveChannel) then
        return;
    end
    for index = 1, (self.addon.compat.NUM_CHAT_WINDOWS or 10) do
        local chatFrame = _G["ChatFrame" .. index];
        if (chatFrame) then
            self.addon.compat.ChatFrame_RemoveChannel(chatFrame, self.ChannelName);
        end
    end
end

--- Leave the hidden channel.
function LinkService:LeaveChannel()
    local channelId = GetChannelName(self.ChannelName);
    if (channelId and channelId > 0) then
        LeaveChannelByName(self.ChannelName);
        self.addon:Log("LinkService", "LeaveChannel", "Left hidden channel %s", self.ChannelName);
    end
    self.channelId = 0;
end

--- Check whether a channel event belongs to the hidden channel.
function LinkService:IsOwnChannel(channelName, channelBaseName)
    local ownName = string.lower(self.ChannelName);
    if (channelBaseName and string.lower(channelBaseName) == ownName) then
        return true;
    end
    if (channelName and string.lower(channelName) == ownName) then
        return true;
    end
    return channelName ~= nil and string.find(string.lower(channelName), "%. " .. ownName .. "$") ~= nil;
end

--- Send the presence beacon on the hidden channel.
function LinkService:SendChannelHello()
    if (self.channelId == 0) then
        return;
    end
    self:GetService("message"):SendToChannel(self.channelId, self:GetModel("link-hello-message"):Create());
end

--- Scan the battle.net friend list for trusted or linked characters online on
--- this realm and faction (silent presence source without the channel).
function LinkService:ScanBattleNetFriends()
    if (not self:HasTrust() or not C_BattleNet or not C_BattleNet.GetFriendNumGameAccounts or not C_BattleNet.GetFriendGameAccountInfo) then
        return;
    end
    local success, scanError = pcall(function()
        self:ScanBattleNetFriendsUnsafe();
    end);
    if (not success and not self.friendScanErrorLogged) then
        self.friendScanErrorLogged = true;
        self.addon:Log("LinkService", "ScanBattleNetFriends", "Friend list scan failed: %s", tostring(scanError));
    end
end

--- Battle.net scan without error guard (see ScanBattleNetFriends).
function LinkService:ScanBattleNetFriendsUnsafe()
    local ownFaction = UnitFactionGroup("player");
    local numFriends = (BNGetNumFriends and BNGetNumFriends()) or 0;
    for friendIndex = 1, numFriends do
        local accountCount = C_BattleNet.GetFriendNumGameAccounts(friendIndex) or 0;
        for accountIndex = 1, accountCount do
            local info = C_BattleNet.GetFriendGameAccountInfo(friendIndex, accountIndex);
            if (info and info.isOnline and info.clientProgram == BNET_CLIENT_WOW and info.characterName and info.characterName ~= ""
                and info.realmName and info.realmName ~= ""
                and (not info.wowProjectID or not WOW_PROJECT_ID or info.wowProjectID == WOW_PROJECT_ID)
                and (not info.factionName or info.factionName == "" or info.factionName == ownFaction)) then
                local fullName = info.characterName .. "-" .. string.gsub(info.realmName, "%s+", "");
                if (self:IsTrustedName(fullName) or self:GetLinkedAccountByCharacter(fullName)) then
                    self:NotePresence(fullName);
                end
            end
        end
    end
end
