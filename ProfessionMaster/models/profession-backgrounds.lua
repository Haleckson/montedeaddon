--[[

@author Kurki
@copyright ©2026 Profession Master. All Rights Reserved.

--]]

-- create model: the parchment background of the forever style per profession
-- (skill line id -> file name under textures\forever\backgrounds); professions
-- without own art and the "all professions" views use the generic parchment
local ProfessionBackgrounds = _G.professionMaster:CreateModel("profession-backgrounds", {
    [164] = "blacksmithing",
    [165] = "leatherworking",
    [171] = "alchemy",
    [182] = "herbalism",
    [185] = "cooking",
    [186] = "mining",
    [197] = "tailoring",
    [202] = "engineering",
    [333] = "enchanting",
    [356] = "fishing",
    [393] = "skinning",
    [755] = "jewelcrafting",
    [773] = "inscription",
});

--- Get the background file name of a profession.
-- @param professionId Skill line id (0 or nil for all professions).
-- @return File name without path and extension.
function ProfessionBackgrounds:GetName(professionId)
    return professionId and self[professionId] or "generic";
end
