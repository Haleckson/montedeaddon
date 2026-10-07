--[[
  Forever Companion - Discovery/VendorDiscovery.lua
  Records merchants with their inventory, and every recipe they sell as its
  own recipe discovery (linked to the vendor as parent).

  Item names can be uncached when the merchant window opens, so the scan runs
  shortly after MERCHANT_SHOW and once more if names were still missing.
]]

local _, FC = ...

local Engine = FC.DiscoveryEngine
local Compat = FC.Compat
local U = FC.Utils
local Categories = FC.Categories

local Vendor = {}

-- "Requires %s (%d)" -> "^Requires (.+) %((%d+)%)$"
local function buildSkillPattern()
    local template = _G.ITEM_MIN_SKILL
    if type(template) ~= "string" then return nil end
    local pattern = template:gsub("([%(%)%.%[%]%*%+%-%?%^%$])", "%%%1")
    pattern = pattern:gsub("%%s", "(.+)"):gsub("%%d", "(%%d+)")
    return "^" .. pattern .. "$"
end

function Vendor:RecipeRequirement(itemID)
    self.skillPattern = self.skillPattern or buildSkillPattern()
    if not self.skillPattern then return nil end
    for _, line in ipairs(Compat.GetItemTooltipLines(itemID)) do
        local profName, level = line:match(self.skillPattern)
        if profName then
            return Categories:ProfessionFromText(profName), tonumber(level)
        end
    end
    return nil
end

function Vendor:Scan(attempt)
    local info = Compat.GetMerchantUnitInfo()
    if not info or not info.npcID or not info.name then return end
    Engine:MarkService(info.npcID)
    local items, total = Compat.GetMerchantItems()
    if total == 0 then return end

    local inventory, recipes, missingNames = {}, {}, false
    for _, item in ipairs(items) do
        local isRecipe = item.classID == Compat.ITEM_CLASS_RECIPE
        if not item.name then missingNames = true end
        if #inventory < FC.C.LIMITS.INVENTORY then
            local details = Compat.GetItemInfo(item.itemID)
            inventory[#inventory + 1] = {
                i = item.itemID,
                n = item.name,
                l = item.numAvailable >= 0 and item.numAvailable or nil,
                rc = isRecipe or nil,
                q = details and details.quality or nil,
            }
        end
        if isRecipe then recipes[#recipes + 1] = item end
    end

    if missingNames and (attempt or 1) < 2 then
        U.After(1.5, function() Vendor:Scan(2) end)
        return
    end

    local subtitle
    local lines = Compat.GetUnitTooltipLines("npc")
    if lines[2] and not lines[2]:find("^" .. (LEVEL or "Level")) then subtitle = lines[2] end

    local fields = Engine:LocationFields()
    fields.t = "vendor"
    fields.n = info.name
    fields.npc = info.npcID
    local summary = FC.Config:Get("discovery.autoText") and FC.AutoText:VendorSummary(inventory) or nil
    if subtitle and summary then
        fields.d = subtitle .. ". " .. summary
    else
        fields.d = subtitle or summary
    end
    fields.inv = inventory
    fields.ic = Categories:Get("vendor").icon
    local vendorRec, isNew = Engine:Record(fields, { force = attempt == 2 })
    if vendorRec and not isNew and FC.Store:IsMine(vendorRec) then
        -- only a changed stock creates a new revision (and a new sync message)
        local before = FC.Serializer:Serialize(vendorRec.inv or {})
        local _, cleaned = FC.Store:Validate({ id = "x", t = "vendor", n = "x", a = "x", c = 1, u = 1, r = 1, inv = inventory })
        if before ~= FC.Serializer:Serialize(cleaned and cleaned.inv or {}) then
            FC.Store:Update(vendorRec.id, { inv = inventory, d = fields.d or false }, "auto")
        end
    end

    if not FC.Config:Get("discovery.recipes") then return end
    for _, item in ipairs(recipes) do
        local profession, skill = self:RecipeRequirement(item.itemID)
        local recipeFields = {
            t = "recipe",
            n = item.name,
            it = item.itemID,
            pr = profession or Categories:ProfessionFromSubclass(item.subClassID),
            sk = skill,
            src = info.name,
            pa = "vendor:" .. info.npcID,
            m = fields.m, x = fields.x, y = fields.y, z = fields.z, sz = fields.sz,
            ic = item.icon,
        }
        if item.name then Engine:Record(recipeFields) end
    end
end

Engine:RegisterDetector("vendors", {
    setting = "discovery.vendors",
    events = {
        MERCHANT_SHOW = function()
            U.After(0.3, function() Vendor:Scan(1) end)
        end,
    },
})

FC.VendorDiscovery = Vendor
