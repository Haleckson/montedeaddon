local _, GQ = ...

GQ.Equip = GQ.Equip or {}

-- How many levels above entry.maxLevel an item may still appear if it ranks in the top 3.
GQ.Equip.LEVEL_GRACE = 5

-- English client weapon subclass -> character skill line (Classic / TBC).
local WEAPON_SUBCLASS_SKILLS = {
    ["One-Handed Axes"] = "One-Handed Axes",
    ["Two-Handed Axes"] = "Two-Handed Axes",
    ["Bows"] = "Bows",
    ["Crossbows"] = "Crossbows",
    ["Daggers"] = "Daggers",
    ["Guns"] = "Guns",
    ["One-Handed Maces"] = "One-Handed Maces",
    ["Two-Handed Maces"] = "Two-Handed Maces",
    ["Polearms"] = "Polearms",
    ["One-Handed Swords"] = "One-Handed Swords",
    ["Two-Handed Swords"] = "Two-Handed Swords",
    ["Staves"] = "Staves",
    ["Fist Weapons"] = "Fist Weapons",
    ["Wands"] = "Wands",
}

function GQ.Equip:PlayerHasSkill(skillName)
    if not skillName or not GetNumSkillLines then
        return true
    end

    for i = 1, GetNumSkillLines() do
        local name, _, _, rank = GetSkillLineInfo(i)
        if name == skillName and rank and rank > 0 then
            return true
        end
    end

    return false
end

function GQ.Equip:PlayerHasWeaponSkill(itemId)
    self:PrimeItem(itemId)
    local _, _, _, _, _, class, subclass = GetItemInfo(itemId)
    if class ~= "Weapon" or not subclass then
        return true
    end

    local skillName = WEAPON_SUBCLASS_SKILLS[subclass]
    if not skillName then
        return true
    end

    return self:PlayerHasSkill(skillName)
end

function GQ.Equip:RequestItemInfo(itemId, force)
    if not force or not itemId then
        return
    end

    local numericId = tonumber(itemId)
    if not numericId then
        return
    end

    if C_Item and C_Item.RequestLoadItemDataByID then
        C_Item.RequestLoadItemDataByID(numericId)
    end
    if type(GetItemInfo) == "function" then
        GetItemInfo(numericId)
    elseif C_Item and C_Item.GetItemInfo then
        C_Item.GetItemInfo(numericId)
    end
end

function GQ.Equip:PrimeItem(itemId)
    if self._suppressItemPrime then
        return
    end
    self:RequestItemInfo(itemId)
end

function GQ.Equip:IsItemDataCached(itemId)
    if not itemId then
        return false
    end

    local numericId = tonumber(itemId)
    if numericId and C_Item and C_Item.IsItemDataCachedByID then
        return C_Item.IsItemDataCachedByID(numericId) == true
    end

    if not GetItemInfo then
        return false
    end

    local name, _, quality = GetItemInfo(itemId)
    -- Uncached Forever items often return a name with quality 0 (unidentified white).
    return name ~= nil and name ~= "" and type(quality) == "number" and quality > 0
end

function GQ.Equip:GetKnownItemQuality(itemId)
    if not itemId then
        return nil
    end

    local numericId = tonumber(itemId)
    if numericId and C_Item and C_Item.GetItemQualityByID then
        local quality = C_Item.GetItemQualityByID(numericId)
        if type(quality) == "number" and quality > 0 then
            return quality
        end
    end

    if GetItemInfo then
        local name, _, quality = GetItemInfo(itemId)
        if name and name ~= "" and type(quality) == "number" and quality > 0 then
            return quality
        end
    end

    return nil
end

function GQ.Equip:GetItemIconTexture(itemId)
    if not itemId then
        return nil
    end

    if C_Item and C_Item.GetItemIconByID then
        local icon = C_Item.GetItemIconByID(itemId)
        if icon then
            return icon
        end
    end
    if type(GetItemIcon) == "function" then
        local icon = GetItemIcon(itemId)
        if icon then
            return icon
        end
    end
    if type(GetItemInfoInstant) == "function" then
        local icon = select(5, GetItemInfoInstant(itemId))
        if icon then
            return icon
        end
    end
    if GetItemInfo then
        return select(10, GetItemInfo(itemId))
    end
    return nil
end

function GQ.Equip:IsItemInfoLoaded(itemId)
    if not itemId then
        return false
    end
    self:PrimeItem(itemId)
    return self:IsItemDataCached(itemId)
end

function GQ.Equip:GetItemBindType(itemId)
    if not itemId or not self:IsItemInfoLoaded(itemId) then
        return nil
    end

    local bindType
    if type(GetItemInfo) == "function" then
        bindType = select(14, GetItemInfo(itemId))
    end
    if bindType == nil and C_Item and C_Item.GetItemInfo then
        bindType = select(14, C_Item.GetItemInfo(itemId))
    end

    return bindType
end

function GQ.Equip:IsBindOnEquip(itemId)
    local bindType = self:GetItemBindType(itemId)
    if bindType == nil then
        return nil
    end

    local bindOnEquip = (Enum and Enum.ItemBind and Enum.ItemBind.OnEquip) or 2
    return bindType == bindOnEquip
end

function GQ.Equip:IsBindOnPickup(itemId)
    local bindType = self:GetItemBindType(itemId)
    if bindType == nil then
        return nil
    end

    local bindOnPickup = (Enum and Enum.ItemBind and Enum.ItemBind.OnAcquire) or 1
    return bindType == bindOnPickup
end

function GQ.Equip:GetRequiredLevel(itemId)
    if not itemId then
        return 9999
    end
    self:PrimeItem(itemId)
    if not self:IsItemInfoLoaded(itemId) then
        return nil
    end
    local _, _, _, _, reqLevel = GetItemInfo(itemId)
    return reqLevel or 0
end

-- Uses GetEffectiveLevel, so a simulator level of 8 can show a Requires Level 8 item.
-- Unknown (tooltip not cached yet) is allowed; query cache is invalidated when it loads.
function GQ.Equip:MeetsRequiredLevel(itemId, playerLevel)
    if not itemId then
        return false
    end
    playerLevel = playerLevel or GQ:GetEffectiveLevel()
    local reqLevel = self:GetRequiredLevel(itemId)
    if reqLevel == nil then
        if not self._suppressItemPrime and GQ.Data and GQ.Data.NotePendingRequiredLevel then
            GQ.Data:NotePendingRequiredLevel(itemId)
        end
        return true
    end
    return reqLevel <= playerLevel
end

function GQ.Equip:GetEquipSlot(itemId)
    if not itemId then
        return nil
    end
    self:PrimeItem(itemId)
    local _, _, _, _, _, _, _, _, equipSlot = GetItemInfo(itemId)
    return equipSlot
end

function GQ.Equip:IsTwoHandWeapon(itemId)
    return self:GetEquipSlot(itemId) == "INVTYPE_2HWEAPON"
end

local RECOMMENDATION_SLOTS = {
    MainHand = true,
    SecondaryHand = true,
    Ranged = true,
}

-- Best armor tier per class by level (Classic / TBC).
local CLASS_ARMOR_TIER = {
    WARRIOR = { unlockPlate = 40, bestBelow = "Mail" },
    PALADIN = { unlockPlate = 40, bestBelow = "Mail" },
    HUNTER = { unlockMail = 40, bestBelow = "Leather" },
    SHAMAN = { unlockMail = 40, bestBelow = "Leather" },
    DRUID = { bestBelow = "Leather" },
    ROGUE = { bestBelow = "Leather" },
    PRIEST = { bestBelow = "Cloth" },
    MAGE = { bestBelow = "Cloth" },
    WARLOCK = { bestBelow = "Cloth" },
}

local ARMOR_SUBCLASS_SLOTS = {
    Head = true,
    Shoulder = true,
    Chest = true,
    Wrist = true,
    Hands = true,
    Waist = true,
    Legs = true,
    Feet = true,
}

function GQ.Equip:SlotUsesArmorSubclass(slotName)
    if not slotName or not GQ.Data then
        return false
    end
    return ARMOR_SUBCLASS_SLOTS[GQ.Data:NormalizeSlotName(slotName)] == true
end

function GQ.Equip:GetPreferredArmorSubclass(classFile, playerLevel)
    local tier = CLASS_ARMOR_TIER[classFile]
    if not tier then
        return nil
    end

    playerLevel = playerLevel or GQ:GetEffectiveLevel()
    if tier.unlockPlate and playerLevel >= tier.unlockPlate then
        return "Plate"
    end
    if tier.unlockMail and playerLevel >= tier.unlockMail then
        return "Mail"
    end

    return tier.bestBelow
end

function GQ.Equip:GetItemArmorSubclass(itemId)
    if not itemId then
        return nil
    end

    self:PrimeItem(itemId)
    local _, _, _, _, _, class, subclass = GetItemInfo(itemId)
    if class == "Armor" and subclass then
        return subclass
    end

    return nil
end

function GQ.Equip:MeetsArmorPreference(itemId, slotName, classFile, playerLevel)
    if not self:SlotUsesArmorSubclass(slotName) then
        return true
    end

    local preferred = self:GetPreferredArmorSubclass(classFile, playerLevel)
    local actual = self:GetItemArmorSubclass(itemId)
    if not preferred or not actual then
        return true
    end

    return actual == preferred
end

function GQ.Equip:CanPlayerEquip(itemId, slotName)
    if not itemId then
        return false
    end

    self:PrimeItem(itemId)

    -- Item data may not be cached yet; don't exclude curated entries until we know.
    if not self:IsItemInfoLoaded(itemId) then
        return true
    end

    if not self:MeetsRequiredLevel(itemId) then
        return false
    end

    -- Weapon slots: recommend by level + data rules; ignore equipped 1H/2H conflicts.
    if slotName and RECOMMENDATION_SLOTS[slotName] then
        return true
    end

    if not self:PlayerHasWeaponSkill(itemId) then
        return false
    end

    local link = "item:" .. itemId
    if IsEquippableItem then
        return IsEquippableItem(link) and true or false
    end

    return true
end

function GQ.Equip:CanPlayerEquipNow(itemId)
    if not itemId then
        return false
    end

    self:PrimeItem(itemId)

    if not self:MeetsRequiredLevel(itemId) then
        return false
    end

    if not self:PlayerHasWeaponSkill(itemId) then
        return false
    end

    local link = "item:" .. itemId
    if IsEquippableItem then
        return IsEquippableItem(link) and true or false
    end

    return true
end

function GQ.Equip:EntryMatchesSpec(entry)
    if not entry.specs then
        return true
    end

    local spec = GQ.GetEffectiveSpec and GQ:GetEffectiveSpec()
    if not spec then
        return true
    end

    return entry.specs[spec] == true
end

function GQ.Equip:EntryMatchesItemRules(entry)
    if not entry or not entry.itemId then
        return false
    end

    if not self:MeetsRequiredLevel(entry.itemId) then
        return false
    end

    if not self:CanPlayerEquip(entry.itemId, entry.slot) then
        return false
    end

    if not self:EntryMatchesSpec(entry) then
        return false
    end

    return true
end

function GQ.Equip:EntryWithinLevelBand(entry)
    if not entry then
        return false
    end

    local playerLevel = GQ:GetEffectiveLevel()
    if playerLevel < (entry.minLevel or 1) then
        return false
    end

    if playerLevel > (entry.maxLevel or playerLevel) + self.LEVEL_GRACE then
        return false
    end

    return true
end
