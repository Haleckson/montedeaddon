--[[

@author Kurki
@copyright ©2026 Profession Master. All Rights Reserved.

--]]

-- create service
local StartupService = _G.professionMaster:CreateService("startup");

--- Initialize service.
function StartupService:Initialize()
    -- checks of the guild hello while the client does not report the guild yet
    self.HelloGuildChecks = 12;
    self.HelloGuildCheckDelay = 5;

    -- detect fresh login vs reload
    self:HandleEvent("PLAYER_ENTERING_WORLD", function(isInitialLogin, isReloadingUi)
        self.isInitialLogin = isInitialLogin;
    end);

    -- register login event
    self:HandleEvent("PLAYER_LOGIN", function()
        self:OnPlayerLogin();
    end);

    -- integrate the TradeBoard addon (optional dependency): its requests/offers views
    -- are embedded into the professions view and its standalone UI is suppressed
    self:IntegrateTradeBoard();
end

--- Register this addon as host of the TradeBoard addon. The skill provider gives
--- the trade board access to the skill database for subject resolution and the
--- profession/category filters.
function StartupService:IntegrateTradeBoard()
    if (not _G.tradeBoard or not _G.tradeBoard.Integrate or not self.addon:IsTradeBoardCompatible()) then
        self.addon:Log("StartupService", "IntegrateTradeBoard", "TradeBoard not available or incompatible, trade tabs disabled");
        return;
    end

    local service = self;
    _G.tradeBoard:Integrate({
        GetSkillIdByItemId = function(_, itemId)
            return service:GetService("skills"):GetSkillIdByItemId(itemId);
        end,
        GetSkillById = function(_, skillId)
            return service:GetService("skills"):GetSkillById(skillId);
        end,
        GetSkillIdByName = function(_, name)
            return service:GetService("skills"):GetSkillIdByName(name);
        end,
        MatchesCategory = function(_, skillData, professionId, categoryId)
            return service:GetService("category"):MatchesCategory(skillData, professionId, categoryId, nil);
        end,
        BuildCategoryItems = function(_, visibleSkills)
            return service:GetService("category"):BuildCategoryItems(visibleSkills);
        end,
        GetProfessionOwnership = function(_, professionId)
            -- who of the own characters knows the profession and the dot color of it
            local ownProfessionsService = service:GetService("own-professions");
            local kind = ownProfessionsService:GetProfessionOwnership(professionId);
            return kind, ownProfessionsService:GetOwnershipColor(kind);
        end,
        HasAuctionPrices = function()
            -- prices of the own auction house scan (none while a price addon is installed)
            return service:GetService("auction-scan"):HasPrices();
        end,
        GetAuctionPrice = function(_, itemId)
            return service:GetService("auction-scan"):GetPrice(itemId);
        end,
        OpenTradeBoard = function()
            -- show the professions view and jump to the first trade tab if no
            -- trade tab is active (used by the /tb slash command)
            local professionsView = service.addon.professionsView;
            if (not professionsView or service.addon.inCombat) then
                return;
            end
            professionsView:Show();
            if (professionsView.activeTab ~= "requests" and professionsView.activeTab ~= "offers") then
                professionsView:SelectTab("requests");
                professionsView:RefreshActiveTab();
            end
        end,
    });
    self.addon:Log("StartupService", "IntegrateTradeBoard", "TradeBoard integrated with skill provider");
end

--- Create the minimap button: left-click toggles the professions window
--- (shift: settings), right-click the missing reagents (shift: cooldowns);
--- ctrl+right-click hides the button (handled by the ui service).
function StartupService:CreateMinimapIcon()
    local addon = self.addon;
    local service = self;
    self:GetService("ui"):CreateMinimapIcon({
        icon = "Interface\\Icons\\Inv_misc_book_05",
        onClick = function(button)
            if (button == "LeftButton") then
                if (IsShiftKeyDown()) then
                    addon.settingsView:Open();
                elseif (not addon.inCombat) then
                    addon:ToggleMainView();
                end
            elseif (button == "RightButton") then
                if (IsShiftKeyDown()) then
                    service:GetService("cooldown"):ToggleCooldownView();
                else
                    service:GetService("inventory"):ToggleMissingReagents();
                end
            end
        end,
        onTooltip = function(tooltip)
            local localeService = service:GetService("locale");
            tooltip:SetText(localeService:Get("MinimapButtonTitle"));
            tooltip:AddLine(" ");
            tooltip:AddLine(localeService:Get("MinimapButtonLeftClick"));
            tooltip:AddLine(localeService:Get("MinimapButtonShiftLeftClick"));
            tooltip:AddLine(localeService:Get("MinimapButtonRightClick"));
            tooltip:AddLine(localeService:Get("MinimapButtonShiftRightClick"));
        end,
        onHidden = function()
            -- sync the settings checkbox in case the panel is open
            if (PmSettingsShowMinimapButton) then
                PmSettingsShowMinimapButton:SetChecked(false);
            end
        end,
    });
end

--- Handle player login.
function StartupService:OnPlayerLogin()
    -- create the main windows: professions overview and database view
    self.addon.professionsView = self.addon:NewView("professions");
    self.addon.databaseView = self.addon:NewView("database");

    -- migrate data
    self:Migrate();

    -- create minimap icon
    self:CreateMinimapIcon();

    -- initialize settings panel
    self.addon.settingsView = self.addon:NewView("settings");
    self.addon.settingsView:Initialize();

    -- watch tooltip
    self:GetService("tooltip"):WatchTooltip();

    -- startup
    self:GetService("timer"):Wait("PlayerLogin", 3, function()
        -- run startup actions (only on fresh login, not reload)
        if (self.isInitialLogin) then
            -- broadcast version
            self:GetService("message"):SendToGuild(self:GetModel("version-broadcast-message"):Create());

            -- check welcome
            self:GetService("own-professions"):CheckWelcome();

            -- detect own specializations (TBC+)
            self:GetService("own-professions"):DetectSpecializations();

            -- say hello to guild (throttled to once per 2 hours per guild)
            self:CheckHelloToGuild();
        end

        -- find the characters of linked accounts (hidden channel, friend list);
        -- also after a reload, the session presence is gone then
        self:GetService("link"):OnLogin();
        if (self.isInitialLogin) then
            -- notify ready cooldowns after delay (allows sync data to arrive)
            C_Timer.After(12, function()
                self:GetService("cooldown"):NotifyReadyCooldowns();
            end);
        end

        -- strip first aid skills older versions stored under other professions
        -- (own and guildmate data, resets go out for affected own professions)
        self:GetService("own-professions"):RepairFirstAidSkills();

        -- scan professions from the skill lines (also on reload): stores the
        -- profession levels the views depend on and detects gathering skills
        self:GetService("own-professions"):ScanGatheringProfessions();

        -- show cooldown view if there are watched cooldowns and not explicitly hidden
        C_Timer.After(5, function()
            self:GetService("cooldown"):CheckWatchedCooldowns();
        end);

        -- check missing reagents
        self:GetService("inventory"):CheckMissingReagents();

        -- show the leveling to do list again that was open at the last logout
        self:GetService("leveling-planner"):RestoreTodo();

        -- auto-open the last used main window in dev mode
        if (self.addon.devMode) then
            self.addon:GetMainView():Show();
        end
    end);
end

--- Check if Hello should be sent to guild (throttled to once per 2 hours).
-- @param attempt Number of the check while the guild is not known yet.
function StartupService:CheckHelloToGuild(attempt)
    local playerService = self:GetService("player");
    local guildName = playerService:GetGuildName();

    -- skip if not in a guild
    if (not IsInGuild()) then
        return;
    end

    -- the client reports the guild some time after login: ask for the roster
    -- and check again instead of skipping the hello for the whole session
    if (not guildName) then
        attempt = (attempt or 0) + 1;
        if (attempt > self.HelloGuildChecks) then
            self.addon:Log("StartupService", "CheckHelloToGuild", "Guild still unknown after %d checks, no hello this session", self.HelloGuildChecks);
            return;
        end
        C_GuildInfo.GuildRoster();
        C_Timer.After(self.HelloGuildCheckDelay, function()
            self:CheckHelloToGuild(attempt);
        end);
        return;
    end

    -- check throttle
    local guildEntry = playerService.node.guilds[guildName];
    local lastHelloTime = guildEntry and guildEntry.lastHelloTime or 0;
    if (time() - lastHelloTime <= 300) then
        return;
    end

    -- send hello
    if (not guildEntry) then
        guildEntry = {};
        playerService.node.guilds[guildName] = guildEntry;
    end
    guildEntry.lastHelloTime = time();
    self:GetService("profession-sync"):SayHelloToGuild();
    self.addon:Log("StartupService", "CheckHelloToGuild", "Sent Hello to guild %s (last was %ds ago)", guildName, time() - lastHelloTime);
end

-- Migrate data.
function StartupService:Migrate()
    -- get store version
    local storeVersion = PM_Settings.storeVersion;

    -- migrate to store version 9: guildmates from profession-centric to player-centric
    if (not storeVersion or storeVersion < 9) then
        self.addon:Log("StartupService", "Migrate", "Migrating to store version 9");
        self:MigrateToDataNode();
    end

    -- migrate to store version 10: cooldowns/syncTimes/characterSets from short names to full names
    if (not storeVersion or storeVersion < 11) then
        self.addon:Log("StartupService", "Migrate", "Migrating to store version 11");
        self:MigrateCooldownsToFullNames();
    end

    -- migrate to store version 12: guildmates/own keys from short names to full names
    if (not storeVersion or storeVersion < 13) then
        self.addon:Log("StartupService", "Migrate", "Migrating to store version 13");
        self:MigrateDataKeysToFullNames();
    end

    -- migrate to store version 14: skillTimes from one timestamp per skill to
    -- one per player and profession
    if (not storeVersion or storeVersion < 14) then
        self.addon:Log("StartupService", "Migrate", "Migrating to store version 14");
        self:MigrateSkillTimesToProfessionTimes();
    end

    -- set store version
    PM_Settings.storeVersion = 14;
end

--- Collapse per-skill timestamps to one timestamp per player and profession.
--- The sync delta only needs to know when a profession last changed; the old
--- per-skill tables were by far the biggest part of the saved variables.
function StartupService:MigrateSkillTimesToProfessionTimes()
    for _, node in pairs(PM_Data) do
        if (type(node) == "table" and type(node.skillTimes) == "table") then
            for _, professionTimes in pairs(node.skillTimes) do
                if (type(professionTimes) == "table") then
                    for professionId, skillTimes in pairs(professionTimes) do
                        if (type(skillTimes) == "table") then
                            -- keep the newest timestamp of the profession
                            local lastAdded = 0;
                            for _, addedAt in pairs(skillTimes) do
                                if (type(addedAt) == "number" and addedAt > lastAdded) then
                                    lastAdded = addedAt;
                                end
                            end
                            professionTimes[professionId] = (lastAdded > 0) and lastAdded or nil;
                        end
                    end
                end
            end
        end
    end
end

--- Migrate old separate SavedVariables into the unified PM_Data structure.
function StartupService:MigrateToDataNode()
    -- determine current realm and faction
    local realmName = string.gsub(GetRealmName(), "%s+", "");
    local factionGroup = UnitFactionGroup("player");
    local faction = (factionGroup == "Horde") and "H" or "A";
    local realmFactionKey = realmName .. "-" .. faction;

    -- helper: convert full "Name-Realm" to short store name
    local function toStoreName(fullName)
        if (not fullName) then return nil; end
        local dashPos = string.find(fullName, "-", 1, true);
        if (not dashPos) then return fullName; end
        local realm = string.sub(fullName, dashPos + 1);
        if (realm == realmName) then
            return string.sub(fullName, 1, dashPos - 1);
        end
        return fullName;
    end

    -- helper: get the correct node for a player based on PM_PlayerFactions
    local function getNodeForPlayer(fullName)
        local playerFaction = PM_PlayerFactions and PM_PlayerFactions[fullName];
        local targetKey;
        if (playerFaction) then
            local dashPos = string.find(fullName, "-", 1, true);
            local playerRealm = dashPos and string.sub(fullName, dashPos + 1) or realmName;
            targetKey = playerRealm .. "-" .. playerFaction;
        else
            targetKey = realmFactionKey;
        end
        if (not PM_Data[targetKey]) then
            PM_Data[targetKey] = {};
        end
        local targetNode = PM_Data[targetKey];
        if (not targetNode.guildmates) then targetNode.guildmates = {}; end
        if (not targetNode.own) then targetNode.own = {}; end
        if (not targetNode.syncTimes) then targetNode.syncTimes = {}; end
        if (not targetNode.characterSets) then targetNode.characterSets = {}; end
        return targetNode;
    end

    -- ensure current node exists
    if (not PM_Data[realmFactionKey]) then
        PM_Data[realmFactionKey] = {};
    end
    local node = PM_Data[realmFactionKey];
    if (not node.guildmates) then node.guildmates = {}; end
    if (not node.own) then node.own = {}; end
    if (not node.syncTimes) then node.syncTimes = {}; end
    if (not node.characterSets) then node.characterSets = {}; end

    -- migrate PM_Professions → guildmates (player-centric, faction-aware)
    if (PM_Professions and next(PM_Professions)) then
        for professionId, profession in pairs(PM_Professions) do
            if (type(professionId) ~= "number") then break; end
            for skillId, skillEntry in pairs(profession) do
                if (skillEntry.players and #skillEntry.players > 0) then
                    for _, playerName in ipairs(skillEntry.players) do
                        local targetNode = getNodeForPlayer(playerName);
                        local shortName = toStoreName(playerName);
                        if (not targetNode.guildmates[shortName]) then
                            targetNode.guildmates[shortName] = {};
                        end
                        if (not targetNode.guildmates[shortName][professionId]) then
                            targetNode.guildmates[shortName][professionId] = {};
                        end
                        table.insert(targetNode.guildmates[shortName][professionId], skillId);
                    end
                end
            end
        end
    end

    -- migrate intermediate v8 format (profession-centric in node.guildmates) to player-centric
    local firstKey = next(node.guildmates);
    if (firstKey and type(firstKey) == "number") then
        local oldGuildmates = node.guildmates;
        node.guildmates = {};
        for professionId, skills in pairs(oldGuildmates) do
            if (type(professionId) == "number") then
                for skillId, players in pairs(skills) do
                    for _, playerName in ipairs(players) do
                        if (not node.guildmates[playerName]) then
                            node.guildmates[playerName] = {};
                        end
                        if (not node.guildmates[playerName][professionId]) then
                            node.guildmates[playerName][professionId] = {};
                        end
                        table.insert(node.guildmates[playerName][professionId], skillId);
                    end
                end
            end
        end
    end

    -- migrate PM_OwnProfessions → own (faction-aware)
    if (PM_OwnProfessions and next(PM_OwnProfessions)) then
        for playerName, professions in pairs(PM_OwnProfessions) do
            local targetNode = getNodeForPlayer(playerName);
            local shortName = toStoreName(playerName);
            targetNode.own[shortName] = professions;
        end
    end

    -- migrate PM_SyncTimes → current node syncTimes
    if (PM_SyncTimes and next(PM_SyncTimes)) then
        for storageId, timestamp in pairs(PM_SyncTimes) do
            node.syncTimes[storageId] = timestamp;
        end
    end

    -- migrate PM_CharacterSets → characterSets (faction-aware using first member)
    if (PM_CharacterSets and next(PM_CharacterSets)) then
        for _, characterSet in ipairs(PM_CharacterSets) do
            local shortSet = {};
            local targetNode = node;
            if (#characterSet > 0) then
                targetNode = getNodeForPlayer(characterSet[1]);
            end
            for _, characterName in ipairs(characterSet) do
                table.insert(shortSet, toStoreName(characterName));
            end
            table.insert(targetNode.characterSets, shortSet);
        end
    end

    -- clear old variables
    PM_Professions = nil;
    PM_OwnProfessions = nil;
    PM_SyncTimes = nil;
    PM_CharacterSets = nil;
    PM_PlayerFactions = nil;
end

--- Migrate cooldowns keys from short names to full "Name-Realm" format.
function StartupService:MigrateCooldownsToFullNames()
    -- build lookup of short name → full name from PM_Specializations (always has full "Name-Realm" keys)
    local knownFullNames = {};
    if (PM_Specializations) then
        for fullName, _ in pairs(PM_Specializations) do
            local dashPos = string.find(fullName, "-", 1, true);
            if (dashPos) then
                local shortName = string.sub(fullName, 1, dashPos - 1);
                knownFullNames[shortName] = fullName;
            end
        end
    end

    -- iterate all data nodes
    for nodeKey, node in pairs(PM_Data) do
        -- extract realm from node key (format: "RealmName-Faction", e.g. "PyrewoodVillage-A")
        local nodeRealm = string.sub(nodeKey, 1, -3);

        -- add guildmate keys that contain a dash (players from other realms in the cluster)
        if (node.guildmates) then
            for storeName, _ in pairs(node.guildmates) do
                local dashPos = string.find(storeName, "-", 1, true);
                if (dashPos) then
                    local shortName = string.sub(storeName, 1, dashPos - 1);
                    knownFullNames[shortName] = storeName;
                end
            end
        end

        -- add own character names (short names on same realm)
        if (node.own) then
            for storeName, _ in pairs(node.own) do
                if (not string.find(storeName, "-", 1, true) and not knownFullNames[storeName]) then
                    knownFullNames[storeName] = storeName .. "-" .. nodeRealm;
                end
            end
        end

        -- add character set names (short names on same realm)
        if (node.characterSets) then
            for _, characterSet in ipairs(node.characterSets) do
                for _, characterName in ipairs(characterSet) do
                    if (not string.find(characterName, "-", 1, true) and not knownFullNames[characterName]) then
                        knownFullNames[characterName] = characterName .. "-" .. nodeRealm;
                    end
                end
            end
        end

        -- migrate cooldowns keys
        if (node.cooldowns) then
            -- collect keys that need renaming (no dash = short name)
            local toRename = {};
            for playerName, cooldownData in pairs(node.cooldowns) do
                if (not string.find(playerName, "-", 1, true)) then
                    -- resolve full name from known sources, fall back to node realm
                    local fullName = knownFullNames[playerName] or (playerName .. "-" .. nodeRealm);
                    toRename[playerName] = { fullName = fullName, data = cooldownData };
                end
            end

            -- apply renames
            for shortName, entry in pairs(toRename) do
                -- merge into existing full-name entry if present
                if (node.cooldowns[entry.fullName]) then
                    for spellId, expires in pairs(entry.data) do
                        node.cooldowns[entry.fullName][spellId] = expires;
                    end
                else
                    node.cooldowns[entry.fullName] = entry.data;
                end
                node.cooldowns[shortName] = nil;
            end
        end

        -- migrate syncTimes player-name keys (use knownFullNames to identify player names vs storageIds)
        if (node.syncTimes) then
            -- collect keys that need renaming
            local toRename = {};
            for key, timestamp in pairs(node.syncTimes) do
                -- rename if no dash and key is a known player name (not a storageId)
                if (not string.find(key, "-", 1, true) and knownFullNames[key]) then
                    toRename[key] = { fullName = knownFullNames[key], timestamp = timestamp };
                end
            end

            -- apply renames
            for shortName, entry in pairs(toRename) do
                -- keep the newer timestamp if full-name entry already exists
                local existing = node.syncTimes[entry.fullName];
                if (not existing or entry.timestamp > existing) then
                    node.syncTimes[entry.fullName] = entry.timestamp;
                end
                node.syncTimes[shortName] = nil;
            end
        end

        -- migrate characterSets entries to full names
        if (node.characterSets) then
            for _, characterSet in ipairs(node.characterSets) do
                for i, characterName in ipairs(characterSet) do
                    if (not string.find(characterName, "-", 1, true)) then
                        characterSet[i] = knownFullNames[characterName] or (characterName .. "-" .. nodeRealm);
                    end
                end
            end
        end
    end

    -- migrate watchedCooldowns player names
    if (PM_Settings and PM_Settings.watchedCooldowns) then
        local realmName = string.gsub(GetRealmName(), "%s+", "");
        for _, entry in ipairs(PM_Settings.watchedCooldowns) do
            if (entry.playerName and not string.find(entry.playerName, "-", 1, true)) then
                -- resolve from known sources, fall back to current realm
                entry.playerName = knownFullNames[entry.playerName] or (entry.playerName .. "-" .. realmName);
            end
        end
    end
end

--- Migrate guildmates and own keys from short names to full "Name-Realm" format.
function StartupService:MigrateDataKeysToFullNames()
    -- build lookup of short name → full name from PM_Specializations (always has full "Name-Realm" keys)
    local knownFullNames = {};
    if (PM_Specializations) then
        for fullName, _ in pairs(PM_Specializations) do
            local dashPos = string.find(fullName, "-", 1, true);
            if (dashPos) then
                local shortName = string.sub(fullName, 1, dashPos - 1);
                knownFullNames[shortName] = fullName;
            end
        end
    end

    -- iterate all data nodes
    for nodeKey, node in pairs(PM_Data) do
        -- extract realm from node key (format: "RealmName-Faction", e.g. "PyrewoodVillage-A")
        local nodeRealm = string.sub(nodeKey, 1, -3);

        -- add known full names from character sets (already migrated to full names)
        if (node.characterSets) then
            for _, characterSet in ipairs(node.characterSets) do
                for _, characterName in ipairs(characterSet) do
                    local dashPos = string.find(characterName, "-", 1, true);
                    if (dashPos) then
                        local shortName = string.sub(characterName, 1, dashPos - 1);
                        knownFullNames[shortName] = characterName;
                    end
                end
            end
        end

        -- add known full names from guildmates keys that already have a dash
        if (node.guildmates) then
            for storeName, _ in pairs(node.guildmates) do
                local dashPos = string.find(storeName, "-", 1, true);
                if (dashPos) then
                    local shortName = string.sub(storeName, 1, dashPos - 1);
                    knownFullNames[shortName] = storeName;
                end
            end
        end

        -- add known full names from own keys that already have a dash
        if (node.own) then
            for storeName, _ in pairs(node.own) do
                local dashPos = string.find(storeName, "-", 1, true);
                if (dashPos) then
                    local shortName = string.sub(storeName, 1, dashPos - 1);
                    knownFullNames[shortName] = storeName;
                end
            end
        end

        -- migrate guildmates keys
        if (node.guildmates) then
            -- collect keys that need renaming (no dash = short name)
            local toRename = {};
            for storeName, data in pairs(node.guildmates) do
                if (not string.find(storeName, "-", 1, true)) then
                    local fullName = knownFullNames[storeName] or (storeName .. "-" .. nodeRealm);
                    toRename[storeName] = { fullName = fullName, data = data };
                end
            end

            -- apply renames
            for shortName, entry in pairs(toRename) do
                -- merge into existing full-name entry if present
                if (node.guildmates[entry.fullName]) then
                    for professionId, skills in pairs(entry.data) do
                        node.guildmates[entry.fullName][professionId] = skills;
                    end
                else
                    node.guildmates[entry.fullName] = entry.data;
                end
                node.guildmates[shortName] = nil;
            end
        end

        -- migrate own keys
        if (node.own) then
            -- collect keys that need renaming (no dash = short name)
            local toRename = {};
            for storeName, data in pairs(node.own) do
                if (not string.find(storeName, "-", 1, true)) then
                    local fullName = knownFullNames[storeName] or (storeName .. "-" .. nodeRealm);
                    toRename[storeName] = { fullName = fullName, data = data };
                end
            end

            -- apply renames
            for shortName, entry in pairs(toRename) do
                -- merge into existing full-name entry if present
                if (node.own[entry.fullName]) then
                    for professionId, skills in pairs(entry.data) do
                        node.own[entry.fullName][professionId] = skills;
                    end
                else
                    node.own[entry.fullName] = entry.data;
                end
                node.own[shortName] = nil;
            end
        end
    end
end
