--[[

@author Kurki
@copyright (c)2026 Profession Master. All Rights Reserved.

--]]

-- Gathering nodes that also exist as a weaker variant with a word around the
-- base name. WoW Forever has them in the starting zones, seen in the beta with
-- a deDE client (game object ids): "Verwelkte Friedensblume" 656160,
-- "Verkümmertes Silberblatt" 656161, "Mageres Kupfervorkommen" 562111. The
-- names in the other languages are unknown and the added word differs per node, so
-- a tooltip counts as a variant when its first line contains the name of the
-- base node and a later line names the profession.
-- Format: [herb or ore itemId of the base node] = true
-- Only nodes without a differently skilled relative belong here: "Rich Thorium
-- Vein" contains "Thorium Vein" but needs another skill.
local gatheringNodeVariants = {
    [2447] = true, -- Peacebloom
    [765] = true, -- Silverleaf
    [2770] = true, -- Copper Vein
};

_G.professionMaster:CreateModel("gathering-node-variants", gatheringNodeVariants);
