--[[

@author Kurki
@copyright ©2026 Profession Master. All Rights Reserved.

--]]

-- create service
local PlayerService = _G.professionMaster:CreateService("player");

--- Initialize service.
function PlayerService:Initialize()
    -- get realm name and name caches
    self.realmName = string.gsub(GetRealmName(), "%s+", "");
    self.nameCache = {};
    self.longNameCache = {};

    -- visibility cache (rebuilt whenever guildmates or character sets change)
    self.visiblePlayerCache = {};
    self.visibilityVersion = 1;

    -- get player name and faction, then the realm-faction node
    self:ReadCurrentPlayer();
    self:BindNode();

    -- WoW Forever loads the addons on a fresh login before it knows the
    -- character (name "Unknown"): name and faction are read again at login
    -- and at the first entering world, before anything is stored or sent
    -- under the placeholder (on the other clients both reads are the same)
    self:HandleEvent("PLAYER_LOGIN", function()
        self:RereadCurrentPlayer();
    end);
    self:HandleEvent("PLAYER_ENTERING_WORLD", function()
        if (not self.currentReread) then
            self.currentReread = true;
            self:RereadCurrentPlayer();
            self:DropPlaceholderCharacters();
        end
    end);

    -- store current guild name
    self.guildName = IsInGuild() and (GetGuildInfo("player")) or nil;

    -- initialize guildmates (in-memory only, rebuilt each session)
    self.guildmates = {};
    self.guildmatesLoaded = false;

    -- debounced guild roster refresh (first call is immediate)
    self:HandleEvent("GUILD_ROSTER_UPDATE", function()
        if (not self.guildmatesLoaded) then
            self.guildmatesLoaded = true;
            self:RefreshGuildmates();
            return;
        end
        if (self.guildRefreshPending) then
            self.guildRefreshPending:Cancel();
        end
        self.guildRefreshPending = C_Timer.NewTimer(0.3, function()
            self.guildRefreshPending = nil;
            self:RefreshGuildmates();
        end);
    end);

    -- request guild roster update in case GUILD_ROSTER_UPDATE already fired before we registered
    if (IsInGuild()) then
        C_GuildInfo.GuildRoster();
    else
        -- characters without a guild never get a roster refresh, run the
        -- stale guild cleanup after login instead
        C_Timer.After(5, function()
            self:GetService("purge"):CheckStaleGuildCleanup();
        end);
    end
end

--- Read name and faction of the current character. The name comes from
--- GetUnitName, which carries the surname on WoW Forever (UnitName returns it
--- separately there); the client calls a character it does not know yet
--- "Unknown" (UNKNOWNOBJECT).
function PlayerService:ReadCurrentPlayer()
    -- a missing name becomes the placeholder, never a nil key
    local name = GetUnitName("player");
    if (not name or name == "") then
        name = UNKNOWNOBJECT;
    end
    self.currentShort = name;
    self.current = self:GetLongName(name);

    -- store current player faction (H = Horde, A = Alliance)
    local factionGroup = UnitFactionGroup("player");
    self.faction = (factionGroup == "Horde") and "H" or "A";
end

--- Bind the PM_Data node of realm and faction (created on first use, one per
--- server and faction, used everywhere).
-- @return true when the node changed.
function PlayerService:BindNode()
    local realmFactionKey = self.realmName .. "-" .. self.faction;
    if (realmFactionKey == self.realmFactionKey) then
        return false;
    end

    -- remember a node created by this session: it is dropped again when the
    -- faction read at login moves the session to another node
    self.realmFactionKey = realmFactionKey;
    if (not PM_Data[realmFactionKey]) then
        PM_Data[realmFactionKey] = {};
        self.createdNodeKey = realmFactionKey;
    end
    self.node = PM_Data[realmFactionKey];
    if (not self.node.guildmates) then self.node.guildmates = {}; end
    if (not self.node.own) then self.node.own = {}; end
    if (not self.node.ownLevels) then self.node.ownLevels = {}; end
    if (not self.node.syncTimes) then self.node.syncTimes = {}; end
    if (not self.node.characterSets) then self.node.characterSets = {}; end
    if (not self.node.cooldowns) then self.node.cooldowns = {}; end
    if (not self.node.guilds) then self.node.guilds = {}; end
    if (not self.node.skillTimes) then self.node.skillTimes = {}; end
    if (not self.node.dataResets) then self.node.dataResets = {}; end
    if (not self.node.sentDataResets) then self.node.sentDataResets = {}; end
    if (not self.node.reagentPrices) then self.node.reagentPrices = {}; end
    if (not self.node.scannedPrices) then self.node.scannedPrices = {}; end
    if (not self.node.guildFavorites) then self.node.guildFavorites = {}; end
    if (not self.node.ownFavorites) then self.node.ownFavorites = {}; end
    if (not self.node.databaseFavorites) then self.node.databaseFavorites = {}; end

    -- generate storage id for this server/faction node
    if (not self.node.storageId) then
        self.node.storageId = self.addon:GenerateString(12);
    end
    return true;
end

--- Read the current character again and take it over when it differs from
--- the one read before, moving to the node of its faction when that differs
--- too. Nothing changes when both reads agree.
function PlayerService:RereadCurrentPlayer()
    local previousName = self.current;
    local previousNodeKey = self.realmFactionKey;
    local previousNodeCreated = (self.createdNodeKey == previousNodeKey);
    self:ReadCurrentPlayer();

    -- the node of the wrong faction only existed for this session
    local nodeChanged = self:BindNode();
    if (nodeChanged) then
        if (previousNodeCreated) then
            PM_Data[previousNodeKey] = nil;
        end
        self:GetService("link"):BindNode();
    end
    if (nodeChanged or self.current ~= previousName) then
        self:InvalidateVisiblePlayerCache();
        self.addon:Log("PlayerService", "RereadCurrentPlayer", "Character was %s on %s, now %s on %s", previousName, previousNodeKey, self.current, self.realmFactionKey);
    end
end

--- Drop the own data earlier sessions stored under the placeholder name:
--- before the character was read again at login, a fresh WoW Forever login
--- stored and sent its professions as "Unknown-Realm". The data reset makes
--- guildmates drop that character too.
function PlayerService:DropPlaceholderCharacters()
    -- only where character names carry a surname (WoW Forever): a name without
    -- one is never a real character there, elsewhere it could be one
    if (not string.find(self.currentShort, " ", 1, true)) then
        return;
    end

    -- the placeholder, with or without realm
    local function isPlaceholder(name)
        local shortName = self:GetShortName(name);
        return shortName == UNKNOWNOBJECT or shortName == UNKNOWN;
    end

    -- guild memberships a roster update before login stored under it
    for _, guildEntry in pairs(self.node.guilds) do
        for memberName, _ in pairs(guildEntry.ownMembers or {}) do
            if (isPlaceholder(memberName)) then
                guildEntry.ownMembers[memberName] = nil;
            end
        end
    end

    -- own characters stored under it
    local placeholders = {};
    for ownName, _ in pairs(self.node.own) do
        if (isPlaceholder(ownName)) then
            table.insert(placeholders, ownName);
        end
    end
    if (#placeholders == 0) then
        return;
    end

    -- purge like a player purge, plus the levels the silent purge keeps
    local purgeService = self:GetService("purge");
    purgeService:PurgeCharactersSilent(placeholders);
    for _, storeName in ipairs(placeholders) do
        self.node.ownLevels[storeName] = nil;
        purgeService:BroadcastDataReset(storeName, 0);
        self.addon:Log("PlayerService", "DropPlaceholderCharacters", "Dropped own data stored as %s", storeName);
    end
    self:GetService("profession-query"):ScheduleRebuild();
end

--- Get the name of the own guild, read again while unknown: the client
--- reports it some time after login.
-- @return Guild name or nil.
function PlayerService:GetGuildName()
    if (not self.guildName and IsInGuild()) then
        self.guildName = GetGuildInfo("player");
    end
    return self.guildName;
end

--- Parse a player name into short name (cached).
function PlayerService:ParsePlayerName(name)
    local cached = self.nameCache[name];
    if (cached) then
        return cached;
    end

    -- always extract just the character name (before dash)
    local dashPos = string.find(name, "-", 1, true);
    local result;
    if (dashPos) then
        result = { short = string.sub(name, 1, dashPos - 1) };
    else
        result = { short = name };
    end

    self.nameCache[name] = result;
    return result;
end

--- Refresh guildmates.
function PlayerService:RefreshGuildmates()
    -- update guild name (may not be available at first Initialize call)
    self:GetGuildName();

    -- rebuild guildmates from current guild roster (the refresh time lets the
    -- message service tell a fresh online state from a stale one after a logout)
    local previousRoster = self.guildmates;
    local previousRosterCount = self.guildmateCount or 0;
    self.guildmates = {};
    self.guildmatesRefreshedAt = GetTime();

    -- iterate all members (track membership changes; online flips don't affect visibility)
    local rosterCount = 0;
    local membersChanged = false;
    for guildIndex = 1, GetNumGuildMembers() do
        -- get player info
        local rosterName, _, _, _, _, _, _, _, online = GetGuildRosterInfo(guildIndex);

        -- check player name (keyed with realm like every other name, whatever
        -- form the client hands out)
        if (rosterName) then
            local playerName = self:GetLongName(rosterName);
            if (not self.rosterFormatLogged) then
                self.rosterFormatLogged = true;
                self.addon:Log("PlayerService", "RefreshGuildmates", "Guild %s: %d members, first as %s", tostring(self.guildName), GetNumGuildMembers(), rosterName);
            end
            self.guildmates[playerName] = { online = online };
            rosterCount = rosterCount + 1;
            if (not previousRoster[playerName]) then
                membersChanged = true;
            end
        end
    end
    self.guildmateCount = rosterCount;

    -- drop visibility results only when the membership actually changed
    if (membersChanged or rosterCount ~= previousRosterCount) then
        self:InvalidateVisiblePlayerCache();
    end

    -- persist guild members into node.guilds
    if (self.guildName and next(self.guildmates)) then
        local guildEntry = self.node.guilds[self.guildName];
        if (not guildEntry) then
            guildEntry = {};
            self.node.guilds[self.guildName] = guildEntry;
        end

        -- track which own characters are members of this guild (drives the
        -- stale guild cleanup: guilds without a recently seen own member are
        -- purged after the retention period)
        if (not guildEntry.ownMembers) then
            guildEntry.ownMembers = {};
        end
        guildEntry.ownMembers[self.current] = time();

        -- capture previous member list before overwriting (needed for leave detection)
        local previousMembers = guildEntry.members or {};

        -- overwrite with current roster
        guildEntry.members = {};
        for playerName, _ in pairs(self.guildmates) do
            guildEntry.members[playerName] = true;
        end

        -- collect players who were previously in this guild but are no longer
        local playersToPurge = {};
        for previousMember, _ in pairs(previousMembers) do
            -- check if player left the guild (members stored by older versions
            -- may lack the realm)
            local storeName = self:GetLongName(previousMember);
            if (not self.guildmates[storeName]) then
                -- skip own characters and players a linked account vouches for
                if (not self.node.own[storeName] and not self:GetService("link"):IsLinkedPlayer(storeName)) then
                    -- check if any alt in the same character set is still in guild
                    local altInGuild = false;
                    local characterSet = self:FindCharacterSet(storeName);
                    if (characterSet) then
                        for _, altName in ipairs(characterSet) do
                            local altFullName = self:GetLongName(altName);
                            if (self.guildmates[altFullName]) then
                                altInGuild = true;
                                break;
                            end
                        end
                    end

                    -- purge if no connection to guild remains
                    if (not altInGuild) then
                        self.addon:Log("PlayerService", "RefreshGuildmates", "Purging %s (left guild %s)", previousMember, self.guildName);
                        table.insert(playersToPurge, previousMember);
                    end
                end
            end
        end

        -- purge in one batch and rebuild the skill index in the background
        if (#playersToPurge > 0) then
            self:GetService("purge"):PurgeCharactersSilent(playersToPurge);
            self:GetService("profession-query"):ScheduleRebuild();
        end
    end

    -- once per session: drop guilds no own character is in any more
    self:GetService("purge"):CheckStaleGuildCleanup();
end

--- Get guildmate entry by name.
-- @param name Player name.
-- @return Guildmate table or nil.
function PlayerService:GetGuildmate(name)
    return self.guildmates[name];
end

--- Check if player is a guildmate.
-- @param name Player name.
-- @return boolean
function PlayerService:IsGuildmate(name)
    return self.guildmates[name] ~= nil;
end

--- Get player short name.
function PlayerService:GetShortName(name)
    return self:ParsePlayerName(name).short;
end

--- Get player name with realm only if different from own realm.
--- Same realm → "Name", other realm → "Name-OtherRealm".
function PlayerService:GetRealmShortName(name)
    -- handle nil
    if (not name) then return nil; end

    -- check if realm is included
    local dashPos = string.find(name, "-", 1, true);
    if (not dashPos) then
        return name;
    end

    -- compare realm to own realm
    local realm = string.sub(name, dashPos + 1);
    if (realm == self.realmName) then
        return string.sub(name, 1, dashPos - 1);
    end

    return name;
end

--- Check name and add realm if not set.
function PlayerService:GetLongName(name)
    -- check if name is null
    if (name == nil) then
        return nil;
    end

    -- use cached result (called for every player of every skill while building lists)
    local cached = self.longNameCache[name];
    if (cached) then
        return cached;
    end

    -- check if realm already included
    local longName = name;
    if (string.find(name, "-", 1, true) == nil) then
        longName = name .. "-" .. self.realmName;
    end

    self.longNameCache[name] = longName;
    return longName;
end

--- Check if given player is current player.
function PlayerService:IsCurrentPlayer(name)
    return self.current == self:GetLongName(name);
end

--- Name to whisper a player by. WoW Forever names ("First Surname") carry no
--- realm: chat and addon senders come without one, and the server refuses a
--- whisper to "First Surname-Realm" as "not online". Where the own name has a
--- surname, the own realm the addon adds to every name comes off again; a
--- classic character name never holds a space, so the name stays as it is.
-- @param name Full player name (Name-Realm).
-- @return Name to whisper.
function PlayerService:GetWhisperTarget(name)
    if (not name or not self.currentShort or not string.find(self.currentShort, " ", 1, true)) then
        return name;
    end
    return self:GetRealmShortName(name);
end

--- Check whether a (possibly realm-qualified) name is on the player's ignore
--- list. The list may hold the name with or without realm, so both forms are
--- tried; without the friend list api nobody counts as ignored.
function PlayerService:IsIgnored(name)
    if (not name or not C_FriendList or not C_FriendList.IsIgnored) then
        return false;
    end
    if (C_FriendList.IsIgnored(name)) then
        return true;
    end
    local shortName = self:GetShortName(name);
    return shortName ~= name and C_FriendList.IsIgnored(shortName) or false;
end

--- Format palyer names.
function PlayerService:CombinePlayerNames(playerNames, maxAmount, professionId, skillId, useRealmShortName)
    -- prepare values
    local localeService = self:GetService("locale");
    local containsCurrentPlayer = false;
    local ownPlayerNames = {};
    local onlinePlayers = {};
    local offlinePlayers = {};
    local onlineSpecialists = {};
    local offlineSpecialists = {};

    -- full character names of online players, keyed by display name (for whispering)
    local onlineWhisperNames = {};

    -- determine which specialization spell IDs match this skill
    local matchingSpecSpellIds = nil;
    if (professionId and skillId) then
        local specializationSpells = self:GetModel("specialization-spells");
        local specs = specializationSpells and specializationSpells[professionId];
        if (specs) then
            local skillData = self:GetService("skills"):GetSkillById(skillId);
            if (skillData) then
                local itemClassId = skillData.classId;
                local itemSubclassId = skillData.subclassId;
                matchingSpecSpellIds = {};
                for _, spec in ipairs(specs) do
                    if (spec.matchClassId) then
                        if (itemClassId == spec.matchClassId) then
                            if (spec.matchSubclassIds) then
                                for _, subId in ipairs(spec.matchSubclassIds) do
                                    if (itemSubclassId == subId) then
                                        table.insert(matchingSpecSpellIds, spec.spellId);
                                        break;
                                    end
                                end
                            else
                                table.insert(matchingSpecSpellIds, spec.spellId);
                            end
                        end
                    end
                end
                if (#matchingSpecSpellIds == 0) then
                    matchingSpecSpellIds = nil;
                end
            end
        end
    end

    -- iterate all player names
    for _, playerName in ipairs(playerNames) do
        -- resolve stored short name to full name for lookups
        local fullName = self:GetLongName(playerName);

        -- get display player name
        local shortPlayerName = useRealmShortName and self:GetRealmShortName(fullName) or self:GetShortName(fullName);

        -- check if is current player
        if (self:IsCurrentPlayer(playerName)) then
            -- set is current player
            containsCurrentPlayer = true;

            -- reset other player names, not required
            ownPlayerNames = {};
        -- check if is own player (direct or via character set)
        elseif (self:IsOwnPlayer(playerName)) then
            -- add to own players if current player is not added
            if (not containsCurrentPlayer) then
                table.insert(ownPlayerNames, shortPlayerName);
            end
        else
            -- check if player has matching specialization for this skill
            local isSpecialist = false;
            if (matchingSpecSpellIds and PM_Specializations[fullName]) then
                local playerSpecSpellId = PM_Specializations[fullName][professionId];
                if (playerSpecSpellId) then
                    for _, matchSpellId in ipairs(matchingSpecSpellIds) do
                        if (playerSpecSpellId == matchSpellId) then
                            isSpecialist = true;
                            break;
                        end
                    end
                end
            end

            -- check if is online
            local guildPlayer = self:GetRosterEntry(fullName);
            if (guildPlayer and guildPlayer.online) then
                -- set online player
                if (isSpecialist) then
                    onlineSpecialists[shortPlayerName] = {};
                else
                    onlinePlayers[shortPlayerName] = {};
                end
                onlineWhisperNames[shortPlayerName] = fullName;
            else
                -- find character set
                local addToOffline = true;
                local characterSet = self:FindCharacterSet(playerName);
                if (characterSet) then
                    -- check if twink online
                    local twinkNamesOnline = {};
                    for _, twinkName in ipairs(characterSet) do
                        local twinkFullName = self:GetLongName(twinkName);
                        local twinkGuildPlayer = self:GetRosterEntry(twinkFullName);
                        if (twinkGuildPlayer and twinkGuildPlayer.online) then
                            table.insert(twinkNamesOnline, twinkFullName);
                        end
                    end

                    -- check if twinks online
                    if (#twinkNamesOnline > 0) then
                        -- do not add to offline
                        addToOffline = false;

                        -- check if at least one twinks has profession
                        local twinksHaveProfession = false;
                        for _, iterName in ipairs(playerNames) do
                            local iterFullName = self:GetLongName(iterName);
                            for _, twinkNameOnline in pairs(twinkNamesOnline) do
                                if (iterFullName == twinkNameOnline) then
                                    twinksHaveProfession = true;
                                    break;
                                end
                            end
                            if (twinksHaveProfession) then
                                break;
                            end
                        end

                        -- check if must be added as a twink
                        if (not twinksHaveProfession) then
                            for _, twinkNameOnline in pairs(twinkNamesOnline) do
                                -- add short online twink name to online players if not already added
                                local shortTwinkNameOnline = useRealmShortName and self:GetRealmShortName(twinkNameOnline) or self:GetShortName(twinkNameOnline);
                                onlineWhisperNames[shortTwinkNameOnline] = twinkNameOnline;
                                if (isSpecialist) then
                                    if (not onlineSpecialists[shortTwinkNameOnline]) then
                                        onlineSpecialists[shortTwinkNameOnline] = {};
                                    end
                                    if (self:GetRosterEntry(fullName)) then
                                        table.insert(onlineSpecialists[shortTwinkNameOnline], shortPlayerName);
                                    else
                                        table.insert(onlineSpecialists[shortTwinkNameOnline], "alt");
                                    end
                                else
                                    if (not onlinePlayers[shortTwinkNameOnline]) then
                                        onlinePlayers[shortTwinkNameOnline] = {};
                                    end
                                    if (self:GetRosterEntry(fullName)) then
                                        table.insert(onlinePlayers[shortTwinkNameOnline], shortPlayerName);
                                    else
                                        table.insert(onlinePlayers[shortTwinkNameOnline], "alt");
                                    end
                                end
                            end
                        end
                    end
                end

                -- check if is offline
                if (addToOffline) then
                    if (self:GetRosterEntry(fullName)) then
                        -- add to offline players
                        if (isSpecialist) then
                            if (not offlineSpecialists[shortPlayerName]) then
                                offlineSpecialists[shortPlayerName] = {};
                            end
                        else
                            if (not offlinePlayers[shortPlayerName]) then
                                offlinePlayers[shortPlayerName] = {};
                            end
                        end
                    elseif (characterSet) then
                        local guildTwinkName = nil;
                        local characterSetExists = false;
                        for _, twinkName in ipairs(characterSet) do
                            local twinkFullName = self:GetLongName(twinkName);
                            local shortTwinkName = useRealmShortName and self:GetRealmShortName(twinkFullName) or self:GetShortName(twinkFullName);
                            if (isSpecialist) then
                                if (offlineSpecialists[shortTwinkName]) then
                                    characterSetExists = true;
                                    break;
                                end
                            else
                                if (offlinePlayers[shortTwinkName]) then
                                    characterSetExists = true;
                                    break;
                                end
                            end
                            
                            -- get guild twink name
                            if (self:GetRosterEntry(twinkFullName) and not guildTwinkName) then  
                                guildTwinkName = shortTwinkName;
                            end
                        end

                        -- check if guild twink name found and not added already
                        if (not characterSetExists and guildTwinkName) then
                            if (isSpecialist) then
                                if (not offlineSpecialists[guildTwinkName]) then
                                    offlineSpecialists[guildTwinkName] = {};
                                end
                                table.insert(offlineSpecialists[guildTwinkName], "alt");
                            else
                                if (not offlinePlayers[guildTwinkName]) then
                                    offlinePlayers[guildTwinkName] = {};
                                end
                                table.insert(offlinePlayers[guildTwinkName], "alt");
                            end
                        end
                    end
                end
            end
        end
    end

    -- prepare result; whisperTargets holds the full character name per result
    -- index for online entries (offline entries and "You" stay nil)
    local result = {};
    local whisperTargets = {};

    -- add yourself
    if (containsCurrentPlayer) then
        table.insert(result, "|cff00ee00" .. localeService:Get("You"));
    elseif (#ownPlayerNames > 0) then
        table.sort(ownPlayerNames, function(a, b)
            return a < b;
        end);
        table.insert(result, "|cff00ee00" .. localeService:Get("You") .. " (" .. table.concat(ownPlayerNames, ", ") .. ")");
    end

    -- add online specialists (light blue)
    table.sort(onlineSpecialists, function(a, b)
        return a < b;
    end);
    for onlineSpecialistName, onlineSpecialistTwinks in pairs(onlineSpecialists) do
        if (maxAmount and #result >= maxAmount) then
            table.insert(result, "...");
            break;
        end
        if (#onlineSpecialistTwinks == 1) then
            table.insert(result, "|cff71d5ff" .. onlineSpecialistName .. " (" .. onlineSpecialistTwinks[1] .. ")");
        elseif (#onlineSpecialistTwinks > 1) then
            table.insert(result, "|cff71d5ff" .. onlineSpecialistName .. " (" .. #onlineSpecialistTwinks .. " alts)");
        else
            table.insert(result, "|cff71d5ff" .. onlineSpecialistName);
        end
        whisperTargets[#result] = onlineWhisperNames[onlineSpecialistName];
    end

    -- add online players
    table.sort(onlinePlayers, function(a, b)
        return a < b;
    end);
    for onlinePlayerName, onlinePlayerTwinks in pairs(onlinePlayers) do
        if (maxAmount and #result >= maxAmount) then
            table.insert(result, "...");
            break;
        end
        if (#onlinePlayerTwinks == 1) then
            table.insert(result, "|cffffffff" .. onlinePlayerName .. " (" .. onlinePlayerTwinks[1] .. ")");
        elseif (#onlinePlayerTwinks > 1) then
            table.insert(result, "|cffffffff" .. onlinePlayerName .. " (" .. #onlinePlayerTwinks .. " alts)");
        else
            table.insert(result, "|cffffffff" .. onlinePlayerName);
        end
        whisperTargets[#result] = onlineWhisperNames[onlinePlayerName];
    end

    -- check maximum amount
    if (not maxAmount or #result < maxAmount) then
        -- add offline specialists (faded light blue)
        for offlineSpecialistName, offlineSpecialistTwinks in pairs(offlineSpecialists) do
            if (maxAmount and #result >= maxAmount) then
                table.insert(result, "...");
                break;
            end
            if (#offlineSpecialistTwinks == 1) then
                table.insert(result, "|cff448099" .. offlineSpecialistName .. " (" .. offlineSpecialistTwinks[1] .. ")");
            elseif (#offlineSpecialistTwinks > 1) then
                table.insert(result, "|cff448099" .. offlineSpecialistName .. " (" .. #offlineSpecialistTwinks .. " alts)");
            else
                table.insert(result, "|cff448099" .. offlineSpecialistName);
            end
        end
    end

    -- check maximum amount
    if (not maxAmount or #result < maxAmount) then
        -- add offline players
        for offlinePlayerName, offlinePlayerTwinks in pairs(offlinePlayers) do
            if (maxAmount and #result >= maxAmount) then
                table.insert(result, "...");
                break;
            end
            if (#offlinePlayerTwinks == 1) then
                table.insert(result, "|cff999999" .. offlinePlayerName .. " (" .. offlinePlayerTwinks[1] .. ")");
            elseif (#offlinePlayerTwinks > 1) then
                table.insert(result, "|cff999999" .. offlinePlayerName .. " (" .. #offlinePlayerTwinks .. " alts)");
            else
                table.insert(result, "|cff999999" .. offlinePlayerName);
            end
        end
    end

    -- players combined
    return result, whisperTargets;
end

--- Check if a player would be shown in player name lists.
--- Mirrors the visibility rules of CombinePlayerNames: the current player, own
--- characters, live guildmates and alts of live guildmates are visible. While
--- the guild roster is not loaded yet, all players are treated as visible.
-- @param playerName Player name.
-- @return boolean
function PlayerService:IsVisiblePlayer(playerName)
    -- treat all players as visible until the guild roster is known
    if (not self.guildmatesLoaded) then
        return true;
    end

    -- use cached result (called for every player of every skill while building lists)
    local cached = self.visiblePlayerCache[playerName];
    if (cached ~= nil) then
        return cached;
    end

    local visible = self:ResolveVisiblePlayer(playerName);
    self.visiblePlayerCache[playerName] = visible;
    return visible;
end

--- Resolve the visibility of a player without using the cache.
-- @param playerName Player name.
-- @return boolean
function PlayerService:ResolveVisiblePlayer(playerName)
    -- check current and own characters
    if (self:IsCurrentPlayer(playerName) or self:IsOwnPlayer(playerName)) then
        return true;
    end

    -- check live guild roster and the players known through linked accounts
    if (self:GetRosterEntry(self:GetLongName(playerName))) then
        return true;
    end

    -- check if any alt in the character set is a live guildmate or linked player
    local characterSet = self:FindCharacterSet(playerName);
    if (characterSet) then
        for _, twinkName in ipairs(characterSet) do
            if (self:GetRosterEntry(self:GetLongName(twinkName))) then
                return true;
            end
        end
    end
    return false;
end

--- Get the roster entry of a player: the live guild roster first, then the
--- players known through linked accounts (their characters and the members
--- of the guilds they shared; online when a presence signal was seen).
-- @param fullName Full name of the player (Name-Realm).
-- @return { online = boolean } or nil when the player is unknown.
function PlayerService:GetRosterEntry(fullName)
    local guildPlayer = self.guildmates[fullName];
    if (guildPlayer) then
        return guildPlayer;
    end
    local linkService = self:GetService("link");
    if (linkService:IsLinkedPlayer(fullName)) then
        return { online = linkService:IsCharacterOnline(fullName), linked = true };
    end
    return nil;
end

--- Check if at least one player in the given list is visible.
-- @param playerNames List of player names.
-- @return boolean
function PlayerService:HasVisiblePlayers(playerNames)
    for _, playerName in ipairs(playerNames) do
        if (self:IsVisiblePlayer(playerName)) then
            return true;
        end
    end
    return false;
end

--- Check if a player belongs to the current account (own character or linked via character set).
function PlayerService:IsOwnPlayer(playerName)
    -- direct match in own characters
    if (self.node.own[playerName]) then
        return true;
    end

    -- check via character set (linked alt)
    local characterSet = self:FindCharacterSet(playerName);
    if (characterSet) then
        for _, characterName in ipairs(characterSet) do
            if (self:IsCurrentPlayer(characterName) or self.node.own[characterName]) then
                return true;
            end
        end
    end

    return false;
end

--- Check if a player belongs to the current account (current player, own character or linked alt).
function PlayerService:IsOwnCharacter(name)
    local fullName = self:GetLongName(name);
    if (not fullName) then
        return false;
    end
    return self:IsCurrentPlayer(fullName) or self:IsOwnPlayer(fullName);
end

--- Check if two player names belong to the same owner (same character or same character set).
-- @param ownerName Name of the player claiming ownership (e.g. message sender).
-- @param characterName Name of the character to check.
function PlayerService:IsSameCharacterOwner(ownerName, characterName)
    local ownerFullName = self:GetLongName(ownerName);
    local characterFullName = self:GetLongName(characterName);
    if (not ownerFullName or not characterFullName) then
        return false;
    end
    if (ownerFullName == characterFullName) then
        return true;
    end

    -- check if owner is a linked alt of the character
    local characterSet = self:FindCharacterSet(characterFullName);
    if (characterSet) then
        for _, setCharacterName in ipairs(characterSet) do
            if (self:GetLongName(setCharacterName) == ownerFullName) then
                return true;
            end
        end
    end
    return false;
end

--- Get the data reset tombstone entry for a character, migrating the legacy scalar format.
-- Legacy format stored a single timestamp per character (whole-character reset). The new
-- format is a table { all = <timestamp>, professions = { [professionId] = <timestamp> } } so
-- scoped (per-profession) drops can be tracked independently of full-character purges.
-- @param storeName Full name of the character.
-- @return The (possibly migrated) tombstone table, or nil if none exists.
function PlayerService:GetDataResets(storeName)
    if (not self.node.dataResets) then
        self.node.dataResets = {};
    end
    local entry = self.node.dataResets[storeName];

    -- migrate legacy scalar timestamp (whole-character reset) to structured format
    if (type(entry) == "number") then
        entry = { all = entry };
        self.node.dataResets[storeName] = entry;
    end
    return entry;
end

--- Check if a reset tombstone currently blocks data for a specific profession.
-- @param storeName Full name of the character.
-- @param professionId Profession id to check (0 or nil checks only the full-character tombstone).
-- @return true if a full-character or matching per-profession tombstone is active.
function PlayerService:IsDataResetActive(storeName, professionId)
    local entry = self:GetDataResets(storeName);
    if (not entry) then
        return false;
    end
    if (entry.all) then
        return true;
    end
    if (professionId and professionId > 0 and entry.professions and entry.professions[professionId]) then
        return true;
    end
    return false;
end

--- Check if any reset tombstone (full-character or any profession) is active for a character.
-- @param storeName Full name of the character.
function PlayerService:IsAnyDataResetActive(storeName)
    local entry = self:GetDataResets(storeName);
    if (not entry) then
        return false;
    end
    if (entry.all) then
        return true;
    end
    if (entry.professions and next(entry.professions)) then
        return true;
    end
    return false;
end

--- Clear reset tombstones after the owner sent fresh data (owner is authoritative again).
-- The full-character tombstone is always dropped; a scoped tombstone is only dropped for the
-- profession the owner actually refreshed, so other dropped professions stay blocked.
-- @param storeName Full name of the character.
-- @param professionId Profession id the owner just sent (0 or nil clears only the full tombstone).
function PlayerService:ClearDataResets(storeName, professionId)
    local entry = self.node.dataResets and self.node.dataResets[storeName];
    if (not entry) then
        return;
    end

    -- legacy scalar tombstone: a fresh owner send clears it entirely
    if (type(entry) == "number") then
        self.node.dataResets[storeName] = nil;
        return;
    end

    -- owner is alive and authoritative: drop the full-character tombstone
    entry.all = nil;

    -- drop the scoped tombstone only for the profession the owner refreshed
    if (professionId and professionId > 0 and entry.professions) then
        entry.professions[professionId] = nil;
    end

    -- remove the entry entirely once no tombstone remains
    if (not entry.all and (not entry.professions or not next(entry.professions))) then
        self.node.dataResets[storeName] = nil;
    end
end

--- Drop the cached player visibility results.
--- Must be called whenever guildmates, own characters or character sets change.
function PlayerService:InvalidateVisiblePlayerCache()
    self.visiblePlayerCache = {};
    self.visibilityVersion = (self.visibilityVersion or 0) + 1;
end

--- Drop the character set lookup index (and everything derived from it).
function PlayerService:InvalidateCharacterSetIndex()
    self.characterSetIndex = nil;
    self:InvalidateVisiblePlayerCache();
end

--- Build character set lookup index for O(1) access.
function PlayerService:RebuildCharacterSetIndex()
    self.characterSetIndex = {};
    for _, characterSet in ipairs(self.node.characterSets) do
        for _, existingCharacterName in ipairs(characterSet) do
            self.characterSetIndex[existingCharacterName] = characterSet;
        end
    end
end

--- Find character set by character name (stored as full "Name-Realm" names).
-- @param characterName Full name or store name of the character.
-- @return The character set table, or nil.
function PlayerService:FindCharacterSet(characterName)
    -- ensure full name for comparison
    local fullName = self:GetLongName(characterName);

    -- rebuild index on first use or after invalidation
    if (not self.characterSetIndex) then
        self:RebuildCharacterSetIndex();
    end

    return self.characterSetIndex[fullName];
end
