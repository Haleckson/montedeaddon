--[[

@author Kurki
@copyright ©2026 Profession Master. All Rights Reserved.

--]]

-- create service
local ChatService = _G.professionMaster:CreateService("chat");

-- Prevent double !who handling of the same chat line
ChatService.lastHandledMessage = nil;

--- Initialize service.
function ChatService:Initialize()
    -- !who limits: seconds between answered commands of one requester, skills
    -- named per answer, online crafters that answer for themselves and the
    -- bytes of one answer line (leaves room for the locale suffix and prefix)
    self.WhoRequesterCooldown = 3;
    self.WhoMaxSkills = 4;
    self.WhoMaxCrafterAnswers = 3;
    self.WhoMaxBytes = 190;
    self.whoRequesters = {};

    -- check chat
    self.addon.compat.ChatFrame_AddMessageEventFilter("CHAT_MSG_CHANNEL", function(...) return self:CheckChat(...) end);
    self.addon.compat.ChatFrame_AddMessageEventFilter("CHAT_MSG_YELL", function(...) return self:CheckChat(...) end);
    self.addon.compat.ChatFrame_AddMessageEventFilter("CHAT_MSG_GUILD", function(...) return self:CheckChat(...) end);
    self.addon.compat.ChatFrame_AddMessageEventFilter("CHAT_MSG_OFFICER", function(...) return self:CheckChat(...) end);
    self.addon.compat.ChatFrame_AddMessageEventFilter("CHAT_MSG_PARTY", function(...) return self:CheckChat(...) end);
    self.addon.compat.ChatFrame_AddMessageEventFilter("CHAT_MSG_PARTY_LEADER", function(...) return self:CheckChat(...) end);
    self.addon.compat.ChatFrame_AddMessageEventFilter("CHAT_MSG_RAID", function(...) return self:CheckChat(...) end);
    self.addon.compat.ChatFrame_AddMessageEventFilter("CHAT_MSG_RAID_LEADER", function(...) return self:CheckChat(...) end);
    self.addon.compat.ChatFrame_AddMessageEventFilter("CHAT_MSG_SAY", function(...) return self:CheckChat(...) end);
    self.addon.compat.ChatFrame_AddMessageEventFilter("CHAT_MSG_WHISPER", function(...) return self:CheckChat(...) end);
    self.addon.compat.ChatFrame_AddMessageEventFilter("CHAT_MSG_WHISPER_INFORM", function(...) return self:CheckChat(...) end);
    self.addon.compat.ChatFrame_AddMessageEventFilter("CHAT_MSG_BN_WHISPER", function(...) return self:CheckChat(...) end);
    self.addon.compat.ChatFrame_AddMessageEventFilter("CHAT_MSG_BN_WHISPER_INFORM", function(...) return self:CheckChat(...) end);
    self.addon.compat.ChatFrame_AddMessageEventFilter("CHAT_MSG_INSTANCE_CHAT", function(...) return self:CheckChat(...) end);
    self.addon.compat.ChatFrame_AddMessageEventFilter("CHAT_MSG_INSTANCE_CHAT_LEADER", function(...) return self:CheckChat(...) end);
    
    -- hook hyperlink tooltips on all chat frames
    for i = 1, self.addon.compat.NUM_CHAT_WINDOWS do
        local chatFrame = _G["ChatFrame" .. i];
        if (chatFrame) then
            chatFrame:HookScript("OnHyperlinkEnter", function(_, link)
                local skillId = tonumber(link:match("^enchant:(%d+)"));
                if (not skillId) then return; end
                local skillData = self:GetService("skills"):GetSkillById(skillId);
                if (skillData) then
                    local professionQueryService = self:GetService("profession-query");
                    local players = professionQueryService:GetSkillPlayers(skillData.professionId, skillId);
                    GameTooltip:SetOwner(UIParent, "ANCHOR_CURSOR");
                    self:GetService("tooltip"):ShowTooltip(GameTooltip, skillData.professionId, skillId, skillData, players);
                end
            end);
            chatFrame:HookScript("OnHyperlinkLeave", function()
                GameTooltip:Hide();
            end);
        end
    end

    self.addon:Log("ChatService", "Initialize", "Chat filters and hyperlink hooks registered");
end

--- Write message.
function ChatService:Write(locale, ...)
    self:WriteBare(self:GetService("locale"):Get(locale, ...));
end

--- Write bare message.
function ChatService:WriteBare(message)
    DEFAULT_CHAT_FRAME:AddMessage("|cffDA8CFF[PM]|cffffffff " .. message);
end

--- Parse !who argument to extract a skill id and/or item id.
-- Supports: item links, enchant/spell links, or plain numeric ids.
-- @return skillId, itemId (either or both may be nil)
function ChatService:ParseWhoArgument(argument)
    -- try to match an item link: |Hitem:12345:...|h[...]|h
    local itemId = tonumber(argument:match("|Hitem:(%d+)"));
    if (itemId) then
        -- resolve item id to skill id
        local skillId = self:GetService("skills"):GetSkillIdByItemId(itemId);
        return skillId, itemId;
    end

    -- try to match an enchant link: |Henchant:12345|h[...]|h
    local enchantId = tonumber(argument:match("|Henchant:(%d+)"));
    if (enchantId) then
        -- enchant id is the skill id
        local skillData = self:GetService("skills"):GetSkillById(enchantId);
        local resolvedItemId = skillData and skillData.itemId or nil;
        return enchantId, resolvedItemId;
    end

    -- try to match a spell link: |Hspell:12345|h[...]|h
    local spellId = tonumber(argument:match("|Hspell:(%d+)"));
    if (spellId) then
        local skillData = self:GetService("skills"):GetSkillById(spellId);
        local resolvedItemId = skillData and skillData.itemId or nil;
        return spellId, resolvedItemId;
    end

    -- try to match a PM link: [PM: name : 12345]
    local pmSkillId = tonumber(argument:match("%[PM:.*:%s*(%d+)%s*%]"));
    if (pmSkillId) then
        local skillData = self:GetService("skills"):GetSkillById(pmSkillId);
        local resolvedItemId = skillData and skillData.itemId or nil;
        return pmSkillId, resolvedItemId;
    end

    -- try plain numeric id
    local numericId = tonumber(argument:match("^%s*(%d+)%s*$"));
    if (numericId) then
        -- first check if it's a known skill id
        local skillData = self:GetService("skills"):GetSkillById(numericId);
        if (skillData) then
            return numericId, skillData.itemId;
        end

        -- otherwise check if it's an item id
        local skillId = self:GetService("skills"):GetSkillIdByItemId(numericId);
        if (skillId) then
            return skillId, numericId;
        end
    end

    return nil, nil;
end

--- Resolve the !who argument to the skills it names.
--- A link or id names exactly one skill, free text is searched in the skill
--- names and may name several (only skills somebody in the guild can craft).
--- Recipes that only work on the equipment of the crafter (ring enchants,
--- tinkers, embroideries, sockets) are no answer and reported separately.
-- @param argument Text after !who.
-- @return matches list of { skillId, professionId, skillData }, isTextSearch,
--- isSelfOnly (nothing left but recipes only the crafter can use)
function ChatService:ResolveWhoSkills(argument)
    local queryService = self:GetService("profession-query");

    -- links and ids
    local targetSkillId, targetItemId = self:ParseWhoArgument(argument);
    if (targetSkillId or targetItemId) then
        local skillId, skillData, professionId = queryService:FindSkillByIdOrItemId(targetSkillId, targetItemId);
        if (skillData) then
            -- a recipe only the crafter can use is no answer for the requester
            if (self:GetService("skills"):IsSelfOnlySkill(skillId)) then
                return {}, false, true;
            end
            return { { skillId = skillId, professionId = professionId, skillData = skillData } }, false, false;
        end
        return {}, false, false;
    end

    -- a link the addon does not know is not searched as text
    if (string.find(argument, "|H", 1, true)) then
        return {}, false, false;
    end

    -- free text
    local matches, selfOnlyCount = queryService:FindSkillsByText(argument);
    return matches, true, (#matches == 0 and selfOnlyCount > 0);
end

--- Check whether this character is the one guild member that answers a !who
--- for the others: the online guild member with the addon whose name sorts
--- first. Every member computes the same result from the roster, so exactly
--- one answers; addon users are the senders of addon messages this session.
function ChatService:IsWhoResponder()
    local playerService = self:GetService("player");
    local messageService = self:GetService("message");
    local responder = playerService.current;
    for name, guildmate in pairs(playerService.guildmates) do
        local fullName = playerService:GetLongName(name);
        if (guildmate.online and fullName < responder and messageService:HasAddon(fullName) and messageService:IsPlayerOnline(fullName)) then
            responder = fullName;
        end
    end
    return responder == playerService.current;
end

--- Check whether this character answers "I can craft" for a skill: only the
--- first few online crafters do, sorted by name, so a common recipe does not
--- trigger a whisper from every crafter in the guild.
-- @param crafters Crafters of the skill (see ProfessionQueryService:GetSkillCrafters).
function ChatService:IsAnsweringCrafter(crafters)
    local currentPlayer = self:GetService("player").current;
    local position = 0;
    for _, fullName in ipairs(crafters.online) do
        if (fullName < currentPlayer) then
            position = position + 1;
        end
    end
    return position < self.WhoMaxCrafterAnswers;
end

--- Join items into one whisper line that stays within the chat limit.
--- Items that no longer fit are summed up as "+N".
function ChatService:JoinForWhisper(prefix, items, separator)
    local text = prefix;
    local added = 0;
    for _, item in ipairs(items) do
        local candidate = text .. (added > 0 and separator or "") .. item;

        -- keep room for the "+N" suffix
        if (added > 0 and string.len(candidate) > self.WhoMaxBytes - 6) then
            return text .. " +" .. (#items - added);
        end
        text = candidate;
        added = added + 1;
    end
    return text;
end

--- Handle !who command.
--- Crafters answer for themselves, the other guild crafters (online or not)
--- are named once by the elected responder, a whisper is always answered by
--- the whispered character.
-- @param player The player who sent the command.
-- @param argument Optional argument after !who (link, id or text).
-- @param isWhisper Whether the command was sent via whisper.
-- @param reply Function that whispers a text back to the requester.
function ChatService:HandleWhoCommand(player, argument, isWhisper, reply)
    local playerService = self:GetService("player");

    -- do not respond to own messages
    if (playerService:GetLongName(player) == playerService.current) then
        return;
    end

    -- nothing asked
    if (not argument or argument == "") then
        return;
    end

    -- one answer per requester every few seconds, repeated chat lines must not turn into whisper spam
    local now = GetTime();
    local lastRequest = self.whoRequesters[player];
    if (lastRequest and now - lastRequest < self.WhoRequesterCooldown) then
        return;
    end
    self.whoRequesters[player] = now;

    -- resolve the skills and their crafters
    local skills, isTextSearch, isSelfOnly = self:ResolveWhoSkills(argument);
    local queryService = self:GetService("profession-query");
    local ownSkillNames = {};
    local answersAsCrafter = false;
    local otherEntries = {};
    for index, match in ipairs(skills) do
        if (index > self.WhoMaxSkills) then
            break;
        end
        local crafters = queryService:GetSkillCrafters(match.professionId, match.skillId);
        if (crafters.own) then
            table.insert(ownSkillNames, match.skillData.name);
            if (self:IsAnsweringCrafter(crafters)) then
                answersAsCrafter = true;
            end
        end
        if (#crafters.players > 0) then
            local names = {};
            for _, fullName in ipairs(crafters.players) do
                table.insert(names, playerService:GetRealmShortName(fullName));
            end
            table.insert(otherEntries, { skillName = match.skillData.name, names = names });
        end
    end
    self.addon:Log("ChatService", "HandleWhoCommand", "!who from %s: %d skills, own %d, others %d, self only %s, whisper %s", tostring(player), #skills, #ownSkillNames, #otherEntries, tostring(isSelfOnly), tostring(isWhisper));

    -- crafters answer for themselves (a whisper is always answered)
    local localeService = self:GetService("locale");
    if (#ownSkillNames > 0 and (isWhisper or answersAsCrafter)) then
        if (isTextSearch) then
            reply(self:JoinForWhisper(localeService:Get("WhoCraftListResponse") .. " ", ownSkillNames, ", "));
        else
            reply(localeService:Get("WhoCraftResponse"));
        end
    end

    -- the other crafters are named once, by the elected responder
    if (not isWhisper and not self:IsWhoResponder()) then
        return;
    end
    if (#otherEntries > 0) then
        if (isTextSearch) then
            local entries = {};
            for _, entry in ipairs(otherEntries) do
                table.insert(entries, self:JoinForWhisper(entry.skillName .. ": ", entry.names, ", "));
            end
            reply(self:JoinForWhisper("", entries, "; "));
        else
            reply(self:JoinForWhisper("", otherEntries[1].names, ", ") .. " " .. localeService:Get("WhoOtherCanCraftResponse"));
        end
    elseif (isSelfOnly) then
        reply(localeService:Get("WhoSelfOnlyResponse"));
    elseif (#ownSkillNames == 0) then
        reply(localeService:Get("WhoCannotCraftResponse"));
    end
end

--- Check chat.
function ChatService:CheckChat(_, event, message, player, l, cs, t, flag, channelId, ...)
    -- check flag, event and channel
    if flag == "GM" or flag == "DEV" or (event == "CHAT_MSG_CHANNEL" and type(channelId) == "number" and channelId > 0) then
        return;
    end

    -- check if is whisper
    local isWhisper = (event == "CHAT_MSG_WHISPER" or event == "CHAT_MSG_BN_WHISPER");

    -- check for !who command (only in guild, party and raid)
    if (PM_Settings.respondToWho and message and (event == "CHAT_MSG_GUILD" 
        or event == "CHAT_MSG_PARTY" or event == "CHAT_MSG_PARTY_LEADER"
        or event == "CHAT_MSG_RAID" or event == "CHAT_MSG_RAID_LEADER"
        or isWhisper)) then
        -- match "!who" alone or followed by an argument (link, id or text), not "!whoever"
        local whoMatch = message:match("^![Ww][Hh][Oo]%s+(.*)$") or (message:match("^![Ww][Hh][Oo]%s*$") and "");
        if (whoMatch and not self:GetService("player"):IsIgnored(player)) then
            -- handle each chat line only once: filters run once per chat frame/tab,
            -- so key on the line id (arg11) with player+message as fallback
            local lineId = select(4, ...);
            local messageKey = tostring(lineId or 0) .. "|" .. tostring(player or "") .. "|" .. message;
            if (self.lastHandledMessage ~= messageKey) then
                self.lastHandledMessage = messageKey;

                -- battle.net whispers are answered over the sender id (arg13), everything else by name
                local bnSenderId = (event == "CHAT_MSG_BN_WHISPER") and select(6, ...) or nil;
                local reply = function(text)
                    if (bnSenderId) then
                        self.addon.compat.BNSendWhisper(bnSenderId, "[PM] " .. text);
                    else
                        ChatThrottleLib:SendChatMessage("NORMAL", "PM", "[PM] " .. text, "WHISPER", nil, player);
                    end
                end
                self:HandleWhoCommand(player, whoMatch, isWhisper, reply);
            end
        end
    end

    -- prepare values
    local newMessage = "";
    local currentMessage = message;
    local messageRead = false;

    -- read message
    repeat
        -- read skill name and id
        local startPos, endPos, skillName, skillId = currentMessage:find("%[PM: (.*) : (.*)%]");

        -- check if skill found
        if(skillName and skillId) then
            -- build new message
            newMessage = newMessage .. currentMessage:sub(1, startPos - 1);
            newMessage = newMessage .. "|cffffd000|Henchant:" .. skillId .. "|h[" .. skillName .. "]|h|r"

            -- redefine current message
            currentMessage = currentMessage:sub(endPos + 1);
        else
            -- skill not found, message read
            messageRead = true;
        end
    until(messageRead)

    -- check new message
    if (newMessage ~= "") then
        -- add remaining message
        newMessage = newMessage .. currentMessage;

        -- return new message
        return false, newMessage, player, l, cs, t, flag, channelId, ...; 
    end
end

