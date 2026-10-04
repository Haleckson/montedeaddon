local _, LIB = ...

------------------------
--- Public Functions ---
------------------------

--- Deep-copies an acyclic table; metatables are not preserved.
---
--- @param source table The table to copy.
---
--- @return table copy The copied table.
function ArcaneWizardLibrary.Utils:CopyTable(source)
	local target = {}

	for key, value in pairs(source) do
		if type(value) == "table" then
			target[key] = self:CopyTable(value)
		else
			target[key] = value
		end
	end

	return target
end

--- Returns the character and realm name of the current player as separate values.
---
--- @return string|nil characterName The character name, or nil if unavailable.
--- @return string|nil realmName The realm name, or nil if unavailable.
function ArcaneWizardLibrary.Utils:GetCharacterAndRealm()
	local characterName = UnitName("player")
	local realmName = GetRealmName()

	return characterName, realmName
end

--- Returns the legacy name-based character-realm key.
---
--- @return string|nil characterRealmKey "CharacterName#RealmName", or nil if either name is unavailable.
function ArcaneWizardLibrary.Utils:GetCharacterRealmKey()
	local characterName, realmName = self:GetCharacterAndRealm()
	if not characterName or characterName == "" or not realmName or realmName == "" then
		return nil
	end

	return characterName .. "#" .. realmName
end

--- Returns the current player's complete GUID.
---
--- @return string|nil characterGUID The GUID, or nil if unavailable.
function ArcaneWizardLibrary.Utils:GetCharacterGUID()
	local guid = UnitGUID("player")
	if not guid or guid == "" then
		return nil
	end

	return guid
end

--- Recursively fills missing values without replacing existing values.
---
--- @param target table The table to update in place.
--- @param source table The values to copy from.
function ArcaneWizardLibrary.Utils:MergeMissingTableEntries(target, source)
	for key, value in pairs(source) do
		if target[key] == nil then
			target[key] = type(value) == "table" and self:CopyTable(value) or value
		elseif type(target[key]) == "table" and type(value) == "table" then
			self:MergeMissingTableEntries(target[key], value)
		end
	end
end
