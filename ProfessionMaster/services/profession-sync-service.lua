--[[

@author Kurki
@copyright ©2026 Profession Master. All Rights Reserved.

--]]

-- create service
local ProfessionSyncService = _G.professionMaster:CreateService("profession-sync");

-- re-broadcast window for sent data reset tombstones (30 days)
local DATA_RESET_REBROADCAST_SECONDS = 30 * 24 * 60 * 60;

-- push pacing: players serialized per tick and tick interval (see SendPlayerDataAsync)
local PUSH_PLAYERS_PER_TICK = 3;
local PUSH_TICK_INTERVAL = 0.1;

--- Initialize service.
function ProfessionSyncService:Initialize()
    -- skill count per character whose owner was asked for their complete data
    -- in this session; the same count would answer the same twice
    self.fullRequestedCounts = {};

    -- listen for nearby crafting to discover guild member professions
    self:HandleEvent("CHAT_MSG_TRADESKILLS", function(message, sender)
        self:HandleTradeSkillMessage(message, sender);
    end);
end

--- Count entries in a hash table (non-array table).
function ProfessionSyncService:CountTableEntries(tbl)
    local count = 0;
    for _ in pairs(tbl) do
        count = count + 1;
    end
    return count;
end

--- Queue MyCharacters messages with chunking to respect the 255-byte addon message limit.
-- @param messageQueue Table to append messages to.
-- @param characterSet Array of character names to send.
function ProfessionSyncService:QueueMyCharactersMessages(messageQueue, characterSet)
    local MyCharactersMessage = self:GetModel("my-characters-message");

    -- prefix "MC:" = 3 bytes, max payload = 252 bytes
    local maxPayload = 252;
    local chunk = {};
    local chunkLength = 0;

    for _, name in ipairs(characterSet) do
        -- calculate size with comma separator (first entry has no comma)
        local entryLength = #name + (#chunk > 0 and 1 or 0);

        -- start a new chunk if this entry would exceed the limit
        if (chunkLength + entryLength > maxPayload and #chunk > 0) then
            table.insert(messageQueue, MyCharactersMessage:Create(chunk));
            chunk = {};
            chunkLength = 0;
            entryLength = #name;
        end

        table.insert(chunk, name);
        chunkLength = chunkLength + entryLength;
    end

    -- send remaining chunk
    if (#chunk > 0) then
        table.insert(messageQueue, MyCharactersMessage:Create(chunk));
    end
end

--- Check incoming message and route to appropriate handler.
function ProfessionSyncService:CheckMessage(prefix, sender, message)
    -- check if is hello message
    local HelloMessage = self:GetModel("hello-message");
    if (prefix == HelloMessage.prefix) then
        self:HandleHelloMessage(sender, message);
        return;
    end

    -- check if is request profession message
    local RequestProfessionsMessage = self:GetModel("request-professions-message");
    if (prefix == RequestProfessionsMessage.prefix) then
        self:HandleRequestProfessionsMessage(sender, message);
        return;
    end

    -- check if is my characters message
    local MyCharactersMessage = self:GetModel("my-characters-message");
    if (prefix == MyCharactersMessage.prefix) then
        self:HandleMyCharactersMessage(sender, message);
        return;
    end

    -- check if is player profession message
    local PlayerProfessionsMessage = self:GetModel("player-professions-message");
    if (prefix == PlayerProfessionsMessage.prefix) then
        self:HandlePlayerProfessionsMessage(sender, message);
        return;
    end

    -- check if is player specializations message
    local PlayerSpecializationsMessage = self:GetModel("player-specializations-message");
    if (prefix == PlayerSpecializationsMessage.prefix) then
        self:HandlePlayerSpecializationsMessage(sender, message);
        return;
    end

    -- check if is player cooldowns message
    local PlayerCooldownsMessage = self:GetModel("player-cooldowns-message");
    if (prefix == PlayerCooldownsMessage.prefix) then
        self:HandlePlayerCooldownsMessage(sender, message);
        return;
    end

    -- check if is digest offer message
    local DigestOfferMessage = self:GetModel("digest-offer-message");
    if (prefix == DigestOfferMessage.prefix) then
        self:HandleDigestOfferMessage(sender, message);
        return;
    end

    -- check if is data request message
    local DataRequestMessage = self:GetModel("data-request-message");
    if (prefix == DataRequestMessage.prefix) then
        self:HandleDataRequestMessage(sender, message);
        return;
    end

    -- check if is end-of-sequence marker
    local EndOfSequenceMessage = self:GetModel("end-of-sequence-message");
    if (prefix == EndOfSequenceMessage.prefix) then
        self:HandleEndOfSequenceMessage(sender, message);
        return;
    end

    -- check if is player meta message
    local PlayerMetaMessage = self:GetModel("player-meta-message");
    if (prefix == PlayerMetaMessage.prefix) then
        self:HandlePlayerMetaMessage(sender, message);
        return;
    end

    -- check if is player data reset message
    local PlayerDataResetMessage = self:GetModel("player-data-reset-message");
    if (prefix == PlayerDataResetMessage.prefix) then
        self:HandlePlayerDataResetMessage(sender, message);
        return;
    end
end

--- Handle Hello message from a guild member.
function ProfessionSyncService:HandleHelloMessage(sender, message)
    local HelloMessage = self:GetModel("hello-message");
    local storeService = self:GetService("profession-store");

    -- parse hello message
    local helloMessage = HelloMessage:Parse(message);

    -- compare fingerprints (a match allows the meta-only response below)
    local fingerprintMatch = (helloMessage.fingerprint ~= "" and helloMessage.fingerprint == storeService.dataFingerprint);

    -- deduplicate: skip if already responding to this storageId
    if (not self.pendingHelloRequests) then
        self.pendingHelloRequests = {};
    end
    if (self.pendingHelloRequests[helloMessage.storageId]) then
        return;
    end

    -- mark as pending and schedule response with random delay (spread network load)
    local delay = 2 + math.random() * 6;
    self.pendingHelloRequests[helloMessage.storageId] = true;
    C_Timer.After(delay, function()
        -- if fingerprints match, only exchange meta (no digest comparison needed)
        if (fingerprintMatch) then
            local messageQueue = {};
            self:QueueOwnMetaMessages(messageQueue);
            if (#messageQueue > 0) then
                local messageService = self:GetService("message");
                for _, msg in ipairs(messageQueue) do
                    messageService:SendToPlayer(sender, msg, "BULK");
                end
            end
        else
            -- send full digest offer (skill counts + meta)
            self:SendDigestOffer(sender);
        end

        -- keep blocked for 5 minutes to prevent duplicate responses when same installation logs alts
        C_Timer.After(300, function()
            self.pendingHelloRequests[helloMessage.storageId] = nil;
        end);
    end);
end

--- Handle RequestProfessions message.
function ProfessionSyncService:HandleRequestProfessionsMessage(sender, message)
    local RequestProfessionsMessage = self:GetModel("request-professions-message");
    local rpMessage = RequestProfessionsMessage:Parse(message);

    -- track first responder after our hello (they get relay duty)
    local shouldRelay = rpMessage.relay;
    if (rpMessage.sendBack and not self.helloRelayAssigned) then
        self.helloRelayAssigned = true;
        shouldRelay = true;
        self.addon:Log("ProfessionSyncService", "HandleRequestProfessionsMessage", "Assigned relay duty to %s", sender);
    end

    -- forward to own-professions service
    self:GetService("own-professions"):SendOwnProfessionsToPlayer(sender, rpMessage.storageId, rpMessage.lastSyncDate, rpMessage.sendBack, shouldRelay);
end

--- Handle MyCharacters message.
function ProfessionSyncService:HandleMyCharactersMessage(sender, message)
    local MyCharactersMessage = self:GetModel("my-characters-message");
    local mcMessage = MyCharactersMessage:Parse(message);

    self:GetService("profession-store"):StoreCharacterSet(mcMessage.characterNames);
end

--- Handle PlayerProfessions message.
function ProfessionSyncService:HandlePlayerProfessionsMessage(sender, message)
    local PlayerProfessionsMessage = self:GetModel("player-professions-message");
    local ppMessage = PlayerProfessionsMessage:Parse(message);

    -- ignore skill data about own characters (local scan is authoritative)
    local playerService = self:GetService("player");
    local storeName = playerService:GetLongName(ppMessage.playerName);
    if (playerService:IsOwnCharacter(storeName)) then
        return;
    end

    -- while a reset tombstone is active, only accept data sent by the owner
    if (playerService:IsSameCharacterOwner(sender, storeName)) then
        -- owner sent fresh data, clear the tombstone for this profession (and any full tombstone)
        playerService:ClearDataResets(storeName, ppMessage.professionId);
    elseif (playerService:IsDataResetActive(storeName, ppMessage.professionId)) then
        -- third party trying to re-add data for a dropped/purged profession: ignore
        return;
    end

    -- store player skills (the store service logs one summary per sync burst)
    self:GetService("profession-store"):StorePlayerSkills(ppMessage.playerName, ppMessage.professionId, ppMessage.skills);

    -- add sync time
    self:GetService("player").node.syncTimes[ppMessage.storageId] = time();
end

--- Handle PlayerSpecializations message.
function ProfessionSyncService:HandlePlayerSpecializationsMessage(sender, message)
    local PlayerSpecializationsMessage = self:GetModel("player-specializations-message");
    local psMessage = PlayerSpecializationsMessage:Parse(message);

    -- ignore specializations of own characters (detected locally)
    local playerService = self:GetService("player");
    local fullName = playerService:GetLongName(psMessage.playerName);
    if (playerService:IsOwnCharacter(fullName)) then
        return;
    end

    -- store specializations
    PM_Specializations[fullName] = psMessage.specializations;
end

--- Handle PlayerCooldowns message.
function ProfessionSyncService:HandlePlayerCooldownsMessage(sender, message)
    local PlayerCooldownsMessage = self:GetModel("player-cooldowns-message");
    local pcMessage = PlayerCooldownsMessage:Parse(message);

    -- ignore cooldowns of own characters (scanned locally)
    local playerService = self:GetService("player");
    if (playerService:IsOwnCharacter(pcMessage.playerName)) then
        return;
    end

    -- store cooldowns
    self:GetService("cooldown"):StorePlayerCooldowns(pcMessage.playerName, pcMessage.cooldowns);
end

--- Handle DigestOffer message (accumulate chunks).
function ProfessionSyncService:HandleDigestOfferMessage(sender, message)
    local DigestOfferMessage = self:GetModel("digest-offer-message");
    local doMessage = DigestOfferMessage:Parse(message);

    -- accumulate digest entries from sender (may arrive in multiple chunks)
    if (not self.pendingDigests) then
        self.pendingDigests = {};
    end
    if (not self.pendingDigests[sender]) then
        self.pendingDigests[sender] = { storageId = doMessage.storageId, entries = {} };
    end

    -- merge entries into pending digest
    for storeName, count in pairs(doMessage.entries) do
        self.pendingDigests[sender].entries[storeName] = count;
    end

    -- fallback timer in case end-of-sequence marker is lost (30s timeout)
    if (self.pendingDigests[sender].timer) then
        self.pendingDigests[sender].timer:Cancel();
    end
    self.pendingDigests[sender].timer = C_Timer.NewTimer(30, function()
        local digest = self.pendingDigests[sender];
        if (not digest) then return; end
        self.pendingDigests[sender] = nil;
        self.addon:Log("ProfessionSyncService", "HandleDigestOfferMessage", "DigestOffer fallback timer fired for %s", sender);
        self:HandleDigestOffer(sender, digest.storageId, digest.entries);
    end);
end

--- Handle DataRequest message (accumulate chunks).
function ProfessionSyncService:HandleDataRequestMessage(sender, message)
    local DataRequestMessage = self:GetModel("data-request-message");
    local drMessage = DataRequestMessage:Parse(message);

    -- accumulate requested players (may arrive in multiple chunks)
    if (not self.pendingDataRequests) then
        self.pendingDataRequests = {};
    end
    if (not self.pendingDataRequests[sender]) then
        self.pendingDataRequests[sender] = {};
    end

    -- merge player entries (storeName → sinceTimestamp)
    for storeName, since in pairs(drMessage.players) do
        self.pendingDataRequests[sender][storeName] = since;
    end

    -- fallback timer in case end-of-sequence marker is lost (30s timeout)
    if (self.pendingDataRequestTimers and self.pendingDataRequestTimers[sender]) then
        self.pendingDataRequestTimers[sender]:Cancel();
    end
    if (not self.pendingDataRequestTimers) then
        self.pendingDataRequestTimers = {};
    end
    self.pendingDataRequestTimers[sender] = C_Timer.NewTimer(30, function()
        local requestedPlayers = self.pendingDataRequests[sender];
        self.pendingDataRequests[sender] = nil;
        self.pendingDataRequestTimers[sender] = nil;
        if (requestedPlayers and next(requestedPlayers)) then
            self.addon:Log("ProfessionSyncService", "HandleDataRequestMessage", "DataRequest fallback timer fired for %s (%d players)", sender, self:CountTableEntries(requestedPlayers));
            self:SendRequestedPlayerData(sender, requestedPlayers);
        end
    end);
end

--- Handle EndOfSequence message (triggers immediate processing of accumulated data).
function ProfessionSyncService:HandleEndOfSequenceMessage(sender, message)
    local EndOfSequenceMessage = self:GetModel("end-of-sequence-message");
    local endMessage = EndOfSequenceMessage:Parse(message);

    -- handle digest offer end marker
    if (endMessage.sequenceType == "DO") then
        if (self.pendingDigests and self.pendingDigests[sender]) then
            -- cancel fallback timer
            if (self.pendingDigests[sender].timer) then
                self.pendingDigests[sender].timer:Cancel();
            end

            -- process immediately
            local digest = self.pendingDigests[sender];
            self.pendingDigests[sender] = nil;
            self:HandleDigestOffer(sender, digest.storageId, digest.entries);
        end

    -- handle data request end marker
    elseif (endMessage.sequenceType == "DR") then
        if (self.pendingDataRequests and self.pendingDataRequests[sender]) then
            -- cancel fallback timer
            if (self.pendingDataRequestTimers and self.pendingDataRequestTimers[sender]) then
                self.pendingDataRequestTimers[sender]:Cancel();
                self.pendingDataRequestTimers[sender] = nil;
            end

            -- process immediately
            local requestedPlayers = self.pendingDataRequests[sender];
            self.pendingDataRequests[sender] = nil;
            if (next(requestedPlayers)) then
                self:SendRequestedPlayerData(sender, requestedPlayers);
            end
        end
    end

    -- player professions end markers need no handling, data is already stored per chunk
end

--- Handle PlayerMeta message.
function ProfessionSyncService:HandlePlayerMetaMessage(sender, message)
    local PlayerMetaMessage = self:GetModel("player-meta-message");
    local pmMessage = PlayerMetaMessage:Parse(message);
    local playerService = self:GetService("player");
    local fullName = playerService:GetLongName(pmMessage.storeName);

    -- ignore meta of own characters (detected locally)
    if (playerService:IsOwnCharacter(fullName)) then
        return;
    end

    -- while any reset tombstone is active, only accept meta sent by the owner
    if (not playerService:IsSameCharacterOwner(sender, fullName) and playerService:IsAnyDataResetActive(fullName)) then
        return;
    end

    -- store specializations
    if (next(pmMessage.specializations)) then
        PM_Specializations[fullName] = pmMessage.specializations;
    end

    -- store cooldowns
    if (next(pmMessage.cooldowns)) then
        self:GetService("cooldown"):StorePlayerCooldowns(pmMessage.storeName, pmMessage.cooldowns);
    end
end

--- Handle PlayerDataReset message (tombstone for purged characters or dropped professions).
function ProfessionSyncService:HandlePlayerDataResetMessage(sender, message)
    local PlayerDataResetMessage = self:GetModel("player-data-reset-message");
    local resetMessage = PlayerDataResetMessage:Parse(message);
    local playerService = self:GetService("player");
    local storeName = playerService:GetLongName(resetMessage.storeName);
    if (not storeName or resetMessage.timestamp == 0) then
        return;
    end

    -- never reset own characters (local scan is authoritative)
    if (playerService:IsOwnCharacter(storeName)) then
        return;
    end

    -- only the owner may reset data of their own characters
    if (not playerService:IsSameCharacterOwner(sender, storeName)) then
        return;
    end

    -- get (and migrate) the tombstone entry for this character
    if (not playerService.node.dataResets) then
        playerService.node.dataResets = {};
    end
    local resetEntry = playerService:GetDataResets(storeName);
    if (not resetEntry) then
        resetEntry = {};
        playerService.node.dataResets[storeName] = resetEntry;
    end

    -- delete stored data (single profession or all data of the character)
    -- re-broadcasts arrive with the original timestamp, so ignore duplicate or older tombstones
    local guildmates = playerService.node.guildmates;
    if (resetMessage.professionId > 0) then
        -- scoped tombstone: only reset the one dropped profession
        local existing = resetEntry.professions and resetEntry.professions[resetMessage.professionId];
        if (existing and existing >= resetMessage.timestamp) then
            return;
        end
        if (guildmates[storeName]) then
            guildmates[storeName][resetMessage.professionId] = nil;
        end
        if (playerService.node.skillTimes[storeName]) then
            playerService.node.skillTimes[storeName][resetMessage.professionId] = nil;
        end

        -- remember scoped tombstone to block stale data from third parties until the owner sends again
        if (not resetEntry.professions) then
            resetEntry.professions = {};
        end
        resetEntry.professions[resetMessage.professionId] = resetMessage.timestamp;
    else
        -- full reset: wipe everything and supersede any scoped tombstones
        if (resetEntry.all and resetEntry.all >= resetMessage.timestamp) then
            return;
        end
        guildmates[storeName] = nil;
        playerService.node.skillTimes[storeName] = nil;
        playerService.node.cooldowns[storeName] = nil;
        playerService.node.syncTimes[storeName] = nil;
        PM_Specializations[storeName] = nil;

        -- remember full tombstone to block stale data from third parties until the owner sends again
        resetEntry.all = resetMessage.timestamp;
        resetEntry.professions = nil;
    end

    -- rebuild reverse index and fingerprint deferred (resets can arrive in bursts at login)
    self:GetService("profession-query"):ScheduleRebuild();
    self:GetService("profession-store"):ScheduleRefresh();

    self.addon:Log("ProfessionSyncService", "HandlePlayerDataResetMessage", "Applied data reset for %s (professionId=%s) from %s", storeName, tostring(resetMessage.professionId), sender);
end

--- Queue own sent data reset tombstones for re-broadcast (prunes expired entries).
-- @param messageQueue Table to append messages to.
function ProfessionSyncService:QueueSentDataResets(messageQueue)
    local playerService = self:GetService("player");
    local sentResets = playerService.node.sentDataResets;
    if (not sentResets or #sentResets == 0) then
        return;
    end

    local PlayerDataResetMessage = self:GetModel("player-data-reset-message");
    local now = time();

    -- iterate backwards to allow pruning expired entries
    for i = #sentResets, 1, -1 do
        local entry = sentResets[i];
        if (now - entry.time > DATA_RESET_REBROADCAST_SECONDS) then
            table.remove(sentResets, i);
        else
            table.insert(messageQueue, PlayerDataResetMessage:Create(entry.name, entry.time, entry.professionId));
        end
    end
end

--- Say hello to guild.
function ProfessionSyncService:SayHelloToGuild()
    -- reset relay assignment for this hello round
    self.helloRelayAssigned = false;

    -- reset recently requested cache (new sync round)
    self.recentlyRequested = {};

    -- force immediate fingerprint recalculation (debounced update may not have fired yet)
    self:GetService("profession-store"):UpdateFingerprint();

    -- send hello message to guild with current data fingerprint; the online
    -- characters of linked accounts get the same hello as a whisper and
    -- answer with their digest like a guild member
    local playerService = self:GetService("player");
    local storeService = self:GetService("profession-store");
    local messageService = self:GetService("message");
    messageService:Broadcast(self:GetModel("hello-message"):Create(playerService.node.storageId, storeService.dataFingerprint));

    -- re-broadcast active data reset tombstones (reaches players that missed the original reset);
    -- BULK like all data messages, so they can never overtake older queued skill data
    local resetQueue = {};
    self:QueueSentDataResets(resetQueue);
    for _, resetMessage in ipairs(resetQueue) do
        messageService:Broadcast(resetMessage, "BULK");
    end
end

--- Say hello to one player (a linked character): opens the digest exchange
--- with that account exactly like a guild hello does.
-- @param playerName Full name of the player.
function ProfessionSyncService:SayHelloToPlayer(playerName)
    self.recentlyRequested = {};
    self:GetService("profession-store"):UpdateFingerprint();

    local playerService = self:GetService("player");
    local storeService = self:GetService("profession-store");
    local messageService = self:GetService("message");
    messageService:SendToPlayer(playerName, self:GetModel("hello-message"):Create(playerService.node.storageId, storeService.dataFingerprint));

    -- active tombstones travel with the hello, the partner may have missed them
    local resetQueue = {};
    self:QueueSentDataResets(resetQueue);
    for _, resetMessage in ipairs(resetQueue) do
        messageService:SendToPlayer(playerName, resetMessage, "BULK");
    end
    self.addon:Log("ProfessionSyncService", "SayHelloToPlayer", "Sent hello to linked character %s", playerName);
end

--- Send a digest offer to a player (per-player skill counts).
-- @param playerName Name of the player to send digest to.
function ProfessionSyncService:SendDigestOffer(playerName)
    local playerService = self:GetService("player");
    local guildmates = playerService.node.guildmates;
    local DigestOfferMessage = self:GetModel("digest-offer-message");
    local messageService = self:GetService("message");

    -- build per-player skill counts
    local entries = {};
    local entryCount = 0;
    local messageQueue = {};

    for storeName, professions in pairs(guildmates) do
        -- count total skills for this player
        local count = 0;
        for _, skillIds in pairs(professions) do
            count = count + #skillIds;
        end

        entries[storeName] = count;
        entryCount = entryCount + 1;

        -- chunk at 6 entries per message (storeName.count with full realm names + storageId must fit 255 bytes)
        if (entryCount == 6) then
            table.insert(messageQueue, DigestOfferMessage:Create(playerService.node.storageId, entries));
            entries = {};
            entryCount = 0;
        end
    end

    -- send remaining entries (or empty digest if no guildmates known — triggers sync on receiver)
    if (entryCount > 0 or #messageQueue == 0) then
        table.insert(messageQueue, DigestOfferMessage:Create(playerService.node.storageId, entries));
    end

    -- include own meta (cooldowns/specs/characters — ensures meta is exchanged even when skills match)
    self:QueueOwnMetaMessages(messageQueue);

    -- include own data reset tombstones (receiver may have missed the original reset)
    self:QueueSentDataResets(messageQueue);

    -- append end-of-sequence marker
    local EndOfSequenceMessage = self:GetModel("end-of-sequence-message");
    table.insert(messageQueue, EndOfSequenceMessage:Create("DO"));

    -- send all messages via queue (message-service handles cooperative throttling)
    for _, msg in ipairs(messageQueue) do
        messageService:SendToPlayer(playerName, msg, "BULK");
    end
end

--- Handle a received digest offer: compare with own data and sync differences.
-- @param senderName Name of the player who sent the digest.
-- @param senderStorageId Storage ID of the sender.
-- @param digest Table of { storeName = skillCount } from the sender.
function ProfessionSyncService:HandleDigestOffer(senderName, senderStorageId, digest)
    local playerService = self:GetService("player");
    local guildmates = playerService.node.guildmates;
    local messageService = self:GetService("message");

    -- track recently requested players to avoid duplicate requests from multiple digest responders
    if (not self.recentlyRequested) then
        self.recentlyRequested = {};
    end

    -- compare sender's digest with own data
    local playersToRequest = {};
    local playersToRequestCount = 0;
    local playersToPush = {};

    -- check all players in sender's digest
    for storeName, senderCount in pairs(digest) do
        local myCount = 0;
        if (guildmates[storeName]) then
            for _, skillIds in pairs(guildmates[storeName]) do
                myCount = myCount + #skillIds;
            end
        end

        -- the owner scans their characters locally, so their copy is the truth;
        -- everybody else only knows the skills that reached them
        local isOwnCharacter = playerService:IsOwnCharacter(storeName);
        local senderIsOwner = playerService:IsSameCharacterOwner(senderName, storeName);

        -- while a tombstone is active, data of that character is only taken from its owner
        local resetBlocked = playerService:IsAnyDataResetActive(storeName) and not senderIsOwner;

        if (isOwnCharacter) then
            -- own character: every difference means the other side does not have
            -- my scan, a higher count there included (skills of mine they still
            -- keep from older versions). Sending only when I hold more left the
            -- recipes learned since then unsent forever
            if (senderCount ~= myCount) then
                table.insert(playersToPush, storeName);
                if (senderCount > myCount) then
                    self.addon:Log("ProfessionSyncService", "HandleDigestOffer", "Sending own skills of %s to %s: they hold %d, I have %d", storeName, senderName, senderCount, myCount);
                end
            end
        elseif (senderIsOwner) then
            -- the sender owns the character: every difference is asked back in
            -- full. A delta cannot tell a recipe learned since my last receipt
            -- from one I already have, and the answer covers a single player.
            -- As long as their count stays the same their answer does too, so
            -- it is asked once per session and again after they learned more
            if (senderCount ~= myCount and not resetBlocked and self.fullRequestedCounts[storeName] ~= senderCount) then
                playersToRequest[storeName] = 0;
                playersToRequestCount = playersToRequestCount + 1;
                self.recentlyRequested[storeName] = true;
                self.fullRequestedCounts[storeName] = senderCount;
                self.addon:Log("ProfessionSyncService", "HandleDigestOffer", "Asking %s for all skills of %s: they hold %d, I have %d", senderName, storeName, senderCount, myCount);
            end

        -- sender has more data → request it (skip if already requested from another player recently)
        elseif (senderCount > myCount and not resetBlocked and not self.recentlyRequested[storeName]) then
            -- include my last sync time for this player so sender can send only new skills (delta)
            local mySyncTime = playerService.node.syncTimes[playerService:GetLongName(storeName)] or 0;
            playersToRequest[storeName] = mySyncTime;
            playersToRequestCount = playersToRequestCount + 1;
            self.recentlyRequested[storeName] = true;

        -- I have more data → push it to sender
        elseif (myCount > senderCount) then
            table.insert(playersToPush, storeName);
        end
    end

    -- check players I have that sender doesn't; their own characters stay out,
    -- data about themselves is dropped on arrival anyway
    for storeName, _ in pairs(guildmates) do
        if (not digest[storeName] and not playerService:IsSameCharacterOwner(senderName, storeName)) then
            table.insert(playersToPush, storeName);
        end
    end

    -- log comparison result, but only when there is something to exchange
    if (playersToRequestCount > 0 or #playersToPush > 0) then
        self.addon:Log("ProfessionSyncService", "HandleDigestOffer", "Digest from %s: %d to request, %d to push", senderName, playersToRequestCount, #playersToPush);
    end

    -- build message queue for push + request
    local messageQueue = {};

    -- queue data request for players sender has more of (chunked to fit 255 byte limit)
    if (playersToRequestCount > 0) then
        local DataRequestMessage = self:GetModel("data-request-message");
        local chunk = {};
        local chunkCount = 0;
        for storeName, since in pairs(playersToRequest) do
            chunk[storeName] = since;
            chunkCount = chunkCount + 1;

            -- chunk at 5 entries per message (name.timestamp pairs are longer than plain names)
            if (chunkCount == 5) then
                table.insert(messageQueue, DataRequestMessage:Create(chunk));
                chunk = {};
                chunkCount = 0;
            end
        end

        -- send remaining
        if (chunkCount > 0) then
            table.insert(messageQueue, DataRequestMessage:Create(chunk));
        end

        -- mark end of data request sequence
        local EndOfSequenceMessage = self:GetModel("end-of-sequence-message");
        table.insert(messageQueue, EndOfSequenceMessage:Create("DR"));
    end

    -- send data requests right away (small), then push data spread over time
    for _, msg in ipairs(messageQueue) do
        messageService:SendToPlayer(senderName, msg);
    end
    self:SendPlayerDataAsync(senderName, playersToPush, senderStorageId);
end

--- Send requested player data to a requesting player.
-- @param playerName Name of the requesting player.
-- @param requestedPlayers Table of { storeName = sinceTimestamp } pairs.
function ProfessionSyncService:SendRequestedPlayerData(playerName, requestedPlayers)
    self.addon:Log("ProfessionSyncService", "SendRequestedPlayerData", "Sending data for %d players to %s", self:CountTableEntries(requestedPlayers), playerName);
    self:SendPlayerDataAsync(playerName, requestedPlayers, nil);
end

--- Send player data to a target spread over time.
--- Serializing hundreds of skill messages in one execution trips the client
--- watchdog during login sync, so the queue is built in small slices per tick;
--- the message service still handles wire throttling. Own meta and the
--- end-of-sequence marker follow after the last slice.
-- @param targetName Name of the receiving player.
-- @param players Table of { storeName = sinceTimestamp } or array of store names.
-- @param senderStorageId Storage id of the sync partner (updates sync time when done) or nil.
function ProfessionSyncService:SendPlayerDataAsync(targetName, players, senderStorageId)
    local messageService = self:GetService("message");
    local playerService = self:GetService("player");

    -- normalize input to a work list of { name, since } entries
    local work = {};
    if (players[1] ~= nil) then
        for _, storeName in ipairs(players) do
            work[#work + 1] = { name = storeName, since = 0 };
        end
    else
        for storeName, since in pairs(players) do
            work[#work + 1] = { name = storeName, since = since };
        end
    end

    -- replace a still running push to the same target (new request supersedes it)
    if (not self.pendingPushes) then
        self.pendingPushes = {};
    end
    if (self.pendingPushes[targetName]) then
        self.pendingPushes[targetName]:Cancel();
        self.pendingPushes[targetName] = nil;
        self.addon:Log("ProfessionSyncService", "SendPlayerDataAsync", "Replaced running push to %s", targetName);
    end

    -- serialize a small slice of players per call, finish with meta + end marker
    local position = 1;
    local function sendSlice()
        -- stop the push once the target went offline (every further slice would
        -- only raise "No player named" errors until the roster catches up)
        if (not messageService:IsPlayerOnline(targetName)) then
            if (self.pendingPushes[targetName]) then
                self.pendingPushes[targetName]:Cancel();
                self.pendingPushes[targetName] = nil;
            end
            self.addon:Log("ProfessionSyncService", "SendPlayerDataAsync", "Target %s went offline, push aborted at %d/%d", targetName, position - 1, #work);

            -- mark the work list as done so no ticker is started after the first slice
            position = #work + 1;
            return;
        end

        local sliceEnd = math.min(position + PUSH_PLAYERS_PER_TICK - 1, #work);
        while (position <= sliceEnd) do
            local entry = work[position];
            position = position + 1;

            local messageQueue = {};
            self:QueuePlayerData(messageQueue, { [entry.name] = entry.since });
            for _, msg in ipairs(messageQueue) do
                messageService:SendToPlayer(targetName, msg, "BULK");
            end
        end

        -- check if all players are pushed
        if (position > #work) then
            -- stop ticker
            if (self.pendingPushes[targetName]) then
                self.pendingPushes[targetName]:Cancel();
                self.pendingPushes[targetName] = nil;
            end

            -- always push own meta (cooldowns + specializations change independently of skills)
            local messageQueue = {};
            self:QueueOwnMetaMessages(messageQueue);

            -- append end-of-sequence marker
            local EndOfSequenceMessage = self:GetModel("end-of-sequence-message");
            table.insert(messageQueue, EndOfSequenceMessage:Create("PP"));
            for _, msg in ipairs(messageQueue) do
                messageService:SendToPlayer(targetName, msg, "BULK");
            end

            -- update sync time for sync partner
            if (senderStorageId) then
                playerService.node.syncTimes[senderStorageId] = time();
            end
        end
    end

    self.addon:Log("ProfessionSyncService", "SendPlayerDataAsync", "Pushing data of %d players to %s", #work, targetName);

    -- first slice runs immediately (small pushes finish without waiting for a tick)
    sendSlice();
    if (position <= #work) then
        self.pendingPushes[targetName] = C_Timer.NewTicker(PUSH_TICK_INTERVAL, sendSlice);
    end
end

--- Queue skill data and meta for a list of players into a message queue.
-- @param messageQueue Table to append messages to.
-- @param requestedPlayers Table of { storeName = sinceTimestamp } or array of store names (legacy).
function ProfessionSyncService:QueuePlayerData(messageQueue, requestedPlayers)
    local playerService = self:GetService("player");
    local guildmates = playerService.node.guildmates;
    local skillTimes = playerService.node.skillTimes;
    local PlayerProfessionsMessage = self:GetModel("player-professions-message");
    local PlayerMetaMessage = self:GetModel("player-meta-message");

    -- normalize input: if array (legacy push usage), convert to table with sinceTimestamp=0
    local players = requestedPlayers;
    if (requestedPlayers[1] ~= nil or not next(requestedPlayers)) then
        players = {};
        for _, storeName in ipairs(requestedPlayers) do
            players[storeName] = 0;
        end
    end

    for storeName, sinceTimestamp in pairs(players) do
        local professions = guildmates[storeName];
        if (professions) then
            local fullName = playerService:GetLongName(storeName);
            local playerSkillTimes = skillTimes[storeName];

            -- own characters always answer completely: the local scan is the
            -- truth, and the timestamps of two computers cannot be compared, so
            -- a delta could hold back exactly the recipes the other side lacks
            if (playerService:IsOwnCharacter(storeName)) then
                sinceTimestamp = 0;
            end

            -- queue skill messages per profession
            for professionId, skillIds in pairs(professions) do
                -- delta mode: skip professions unchanged since the requester's
                -- last sync. One timestamp per profession; tonumber also
                -- shields against unmigrated per-skill tables
                local lastAdded = tonumber(playerSkillTimes and playerSkillTimes[professionId]) or 0;
                if (sinceTimestamp == 0 or lastAdded > sinceTimestamp) then
                    local messageSkills = {};
                    for _, skillId in ipairs(skillIds) do
                        table.insert(messageSkills, { skillId = skillId });

                        -- chunk at 28 skills per message (6-digit IDs + max-length player names fit 255 bytes)
                        if (#messageSkills == 28) then
                            table.insert(messageQueue, PlayerProfessionsMessage:Create(professionId, playerService.node.storageId, fullName, messageSkills));
                            messageSkills = {};
                        end
                    end

                    -- queue remaining skills
                    if (#messageSkills > 0) then
                        table.insert(messageQueue, PlayerProfessionsMessage:Create(professionId, playerService.node.storageId, fullName, messageSkills));
                    end
                end
            end

            -- queue meta message (skip own characters — handled by QueueOwnMetaMessages)
            if (not playerService.node.own[storeName]) then
                local specializations = PM_Specializations[fullName] or {};
                local cooldowns = (playerService.node.cooldowns and playerService.node.cooldowns[fullName]) or {};
                if (next(specializations) or next(cooldowns)) then
                    table.insert(messageQueue, PlayerMetaMessage:Create(storeName, specializations, cooldowns));
                end

                -- queue character set with chunking (avoids 255-byte overflow)
                local characterSet = playerService:FindCharacterSet(storeName) or {};
                if (#characterSet > 0) then
                    self:QueueMyCharactersMessages(messageQueue, characterSet);
                end
            end
        end
    end
end

--- Queue own characters' meta messages (cooldowns + specializations) into a message queue.
-- @param messageQueue Table to append messages to.
function ProfessionSyncService:QueueOwnMetaMessages(messageQueue)
    local playerService = self:GetService("player");
    local PlayerMetaMessage = self:GetModel("player-meta-message");

    -- iterate own characters
    for characterName, _ in pairs(playerService.node.own) do
        -- gather meta data
        local fullName = playerService:GetLongName(characterName);
        local specializations = PM_Specializations[fullName] or {};
        local cooldowns = (playerService.node.cooldowns and playerService.node.cooldowns[fullName]) or {};

        -- queue specs + cooldowns if any exist
        if (next(specializations) or next(cooldowns)) then
            table.insert(messageQueue, PlayerMetaMessage:Create(characterName, specializations, cooldowns));
        end

        -- queue character set with chunking (avoids 255-byte overflow)
        local characterSet = playerService:FindCharacterSet(characterName) or {};
        if (#characterSet > 0) then
            self:QueueMyCharactersMessages(messageQueue, characterSet);
        end
    end
end

--- Request professions from another player.
function ProfessionSyncService:RequestProfessionsFromPlayer(playerName, playerStorageId, sendBack, relay)
    -- get last sync
    local lastSyncDate = self:GetLastSyncDate(playerStorageId);

    -- send request professions message to player
    self:GetService("message"):SendToPlayer(playerName, self:GetModel("request-professions-message"):Create(self:GetService("player").node.storageId, lastSyncDate, sendBack, relay));
end

--- Get last sync date of storage.
-- @param storageId Storage id of player to get last sync date for.
-- @return Date of last sync or 0 if not synced yet.
function ProfessionSyncService:GetLastSyncDate(storageId)
    local playerService = self:GetService("player");
    local syncTime = playerService.node.syncTimes[storageId];
    if (not syncTime) then
        return 0;
    end
    return syncTime;
end

--- Handle a CHAT_MSG_TRADESKILLS message to discover guild member skills.
function ProfessionSyncService:HandleTradeSkillMessage(message, sender)
    -- extract item link from the message
    -- the color is a hex code on the classic clients and a quality name
    -- (|cnIQ3:) on the modern client
    local itemLink = message:match("(|c[%w:]+|Hitem:[^|]+|h%[.-%]|h|r)");
    if (not itemLink) then return; end

    -- resolve sender name with realm
    local playerService = self:GetService("player");
    local playerName = playerService:GetLongName(sender);
    if (not playerName) then return; end

    -- skip own characters and players on the ignore list
    if (playerService:IsCurrentPlayer(playerName) or playerService:IsIgnored(playerName)) then return; end

    -- check if sender is a guild member
    if (not playerService:IsGuildmate(playerName)) then return; end

    -- find the skill by item link
    local queryService = self:GetService("profession-query");
    local skillId, skillData, professionId = queryService:FindSkillByItemLink(itemLink);
    if (not skillId or not professionId) then return; end

    -- check if player already known for this skill
    local storeName = playerService:GetLongName(playerName);
    local players = queryService:GetSkillPlayers(professionId, skillId);
    for _, existingPlayer in ipairs(players) do
        if (existingPlayer == storeName) then
            return;
        end
    end

    -- add player to the skill
    self:GetService("profession-store"):StorePlayerSkills(playerName, professionId, {{ skillId = skillId, itemId = skillData.itemId }});

    -- invalidate player professions cache in tooltip service
    local tooltipService = self:GetService("tooltip");
    tooltipService.playerProfessionsCache = nil;
end
