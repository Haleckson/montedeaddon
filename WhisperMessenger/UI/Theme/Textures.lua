local addonName,ns=...
if type(ns)~="table"then
ns={}
end

local Textures={
class_icon_prefix="Interface\\ICONS\\ClassIcon_",
faction_alliance="Interface\\ICONS\\PVPCurrency-Honor-Alliance",
faction_horde="Interface\\ICONS\\PVPCurrency-Honor-Horde",
bnet_icon="Interface\\FriendsFrame\\UI-Toast-ChatInviteIcon",

pin_icon="Interface\\AddOns\\WhisperMessenger\\Media\\pin.png",
unpin_icon="Interface\\AddOns\\WhisperMessenger\\Media\\unpin.png",
pinned_marker="Interface\\AddOns\\WhisperMessenger\\Media\\pinned.png",
trash_icon="Interface\\AddOns\\WhisperMessenger\\Media\\remove.png",

title_close_icon="Interface\\AddOns\\WhisperMessenger\\Media\\close.png",
title_settings_icon="Interface\\AddOns\\WhisperMessenger\\Media\\settings.png",
title_back_icon="Interface\\AddOns\\WhisperMessenger\\Media\\back.png",
title_new_whisper_icon="Interface\\AddOns\\WhisperMessenger\\Media\\new_whisper.png",
title_whats_new_icon="Interface\\AddOns\\WhisperMessenger\\Media\\whats_new.png",
title_mark_read_icon="Interface\\AddOns\\WhisperMessenger\\Media\\mark_read.png",
quick_reply_icon="Interface\\AddOns\\WhisperMessenger\\Media\\quick_reply.png",
muted_icon="Interface\\AddOns\\WhisperMessenger\\Media\\muted.png",
}




local KNOWN_CLASS_TAGS={
WARRIOR=true,
PALADIN=true,
HUNTER=true,
ROGUE=true,
PRIEST=true,
DEATHKNIGHT=true,
SHAMAN=true,
MAGE=true,
WARLOCK=true,
MONK=true,
DRUID=true,
DEMONHUNTER=true,
EVOKER=true,
}


local function ClassIcon(classTag)
if not classTag or not KNOWN_CLASS_TAGS[classTag]then
return nil
end
return Textures.class_icon_prefix..classTag
end


local function FactionIcon(factionName)
if factionName=="Alliance"then
return Textures.faction_alliance
elseif factionName=="Horde"then
return Textures.faction_horde
end
return nil
end



local CHANNEL_ICONS={




PARTY="Interface\\ICONS\\Achievement_BG_winAB_5Cap",
INSTANCE_CHAT="Interface\\ICONS\\Achievement_Arena_2v2_7",
RAID="Interface\\ICONS\\Ability_Hunter_HunterVsWild",
GUILD="Interface\\ICONS\\Achievement_PVP_G_09",
OFFICER="Interface\\ICONS\\Achievement_PVP_O_06",
BN_CONVERSATION="Interface\\ICONS\\Achievement_FeatsOfStrength_Gladiator_09",
COMMUNITY="Interface\\ICONS\\Achievement_Reputation_ArgentChampion",
CHANNEL="Interface\\ICONS\\Achievement_Profession_Fishing_OldManBarlowned",
}

local function ChannelIcon(channel)
return CHANNEL_ICONS[channel]
end

local ThemeTextures={
TEXTURES=Textures,
ClassIcon=ClassIcon,
FactionIcon=FactionIcon,
ChannelIcon=ChannelIcon,
}

ns.ThemeTextures=ThemeTextures
return ThemeTextures
