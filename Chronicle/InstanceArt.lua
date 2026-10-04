local addonName, C = ...

-- Crops of the loading-screen artwork shipped with the Forever client.
-- Future instances without client artwork deliberately have no entry.
local slugs = {
    ["Ragefire Chasm"] = "ragefire-chasm", ["Flammenschlund"] = "ragefire-chasm",
    ["The Hall of Thanes"] = "the-hall-of-thanes", ["Hall of Thanes"] = "the-hall-of-thanes", ["Halle der Thanen"] = "the-hall-of-thanes",
    ["Ruins of Lordaeron"] = "ruins-of-lordaeron", ["Ruinen von Lordaeron"] = "ruins-of-lordaeron",
    ["Deadmines"] = "deadmines", ["The Deadmines"] = "deadmines", ["Todesminen"] = "deadmines",
    ["Wailing Caverns"] = "wailing-caverns", ["Höhlen des Wehklagens"] = "wailing-caverns",
    ["Shadowfang Keep"] = "shadowfang-keep", ["Burg Schattenfang"] = "shadowfang-keep",
    ["Blackfathom Deeps"] = "blackfathom-deeps", ["Tiefschwarze Grotte"] = "blackfathom-deeps",
    ["Stormwind Stockade"] = "stormwind-stockade", ["Verlies"] = "stormwind-stockade",
    ["Razorfen Kraul"] = "razorfen-kraul", ["Kral der Klingenhauer"] = "razorfen-kraul",
    ["Gnomeregan"] = "gnomeregan",
    ["Excavation Site: Wetlands"] = "excavation-site-wetlands",
    ["City of Dalaran"] = "city-of-dalaran", ["Stadt Dalaran"] = "city-of-dalaran",
    ["Scarlet Monastery"] = "scarlet-monastery", ["Scharlachrotes Kloster"] = "scarlet-monastery",
    ["Razorfen Downs"] = "razorfen-downs", ["Hügel der Klingenhauer"] = "razorfen-downs",
    ["Uldaman"] = "uldaman", ["Maraudon"] = "maraudon", ["Zul'Farrak"] = "zul-farrak",
    ["Sunken Temple"] = "sunken-temple", ["Versunkener Tempel"] = "sunken-temple",
    ["Tempel von Atal'Hakkar"] = "sunken-temple",
    ["Blackrock Depths"] = "blackrock-depths", ["Schwarzfelstiefen"] = "blackrock-depths",
    ["Blackrock Spire"] = "blackrock-spire", ["Schwarzfelsspitze"] = "blackrock-spire",
    ["Dire Maul"] = "dire-maul", ["Düsterbruch"] = "dire-maul",
    ["Stratholme"] = "stratholme", ["Scholomance"] = "scholomance",
    ["Half-Pint Tavern"] = "half-pint-tavern", ["Manor Mistmantle"] = "manor-mistmantle",
    ["Onyxia's Lair"] = "onyxia-s-lair", ["Onyxias Hort"] = "onyxia-s-lair",
    ["Ruins of Ahn'Qiraj"] = "ruins-of-ahn-qiraj", ["Ruinen von Ahn'Qiraj"] = "ruins-of-ahn-qiraj",
    ["Zul'Gurub"] = "zul-gurub",
    ["Ahn'Qiraj Temple"] = "ahn-qiraj-temple", ["Tempel von Ahn'Qiraj"] = "ahn-qiraj-temple",
    ["Blackwing Lair"] = "blackwing-lair", ["Pechschwingenhort"] = "blackwing-lair",
    ["Molten Core"] = "molten-core", ["Geschmolzener Kern"] = "molten-core",
    ["Naxxramas"] = "naxxramas",
    ["Alterac Valley"] = "alterac-valley", ["Alteractal"] = "alterac-valley",
    ["Arathi Basin"] = "arathi-basin", ["Arathibecken"] = "arathi-basin",
    ["Battle for Gilneas"] = "battle-for-gilneas", ["Schlacht um Gilneas"] = "battle-for-gilneas",
    ["Darkspear Islands"] = "darkspear-islands", ["Warsong Gulch"] = "warsong-gulch",
    ["Kriegshymnenschlucht"] = "warsong-gulch",
}

function C:GetPackagedInstanceArt(name)
    local normalized = self:NormalizeInstanceName(name)
    local slug = slugs[normalized]
    return slug and ("Interface\\AddOns\\Chronicle\\InstanceArt\\" .. slug) or nil
end

-- A single masked texture avoids the visible seams produced by adjacent slices.
function C:SetSoftInstanceArt(anchor, path, width, options)
    if not path then
        anchor:Hide()
        return
    end
    options = options or {}
    if not anchor.softArtMask and anchor:GetParent().CreateMaskTexture and anchor.AddMaskTexture then
        local mask = anchor:GetParent():CreateMaskTexture()
        mask:SetTexture("Interface\\AddOns\\Chronicle\\HeaderLeftFade")
        mask:SetAllPoints(anchor)
        anchor:AddMaskTexture(mask)
        anchor.softArtMask = mask
    end
    anchor:SetTexture(path)
    anchor:SetTexCoord(options.left or 0, options.right or 1,
        options.top or 0, options.bottom or 1)
    anchor:SetAlpha(options.alpha or 1)
    anchor:Show()
end
