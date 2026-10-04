UNIT_SCAN_DATA = {}

UNIT_SCAN_DATA["unitscanData_DB_VERSION"] = "1.9"
UNIT_SCAN_DATA["unitscanData_VERSION"] = "1.2.0"
UNIT_SCAN_DATA["unitscan_SUGGESTED_VERSION"] = "v1.1.3 for 1.14.3"

UNIT_SCAN_DATA["unitscanData_AUTHOR"] = "Sliccer"
UNIT_SCAN_DATA["unitscanData_AUTHOR_MAIL"] = "Sliccer"
UNIT_SCAN_DATA["unitscan_AUTHOR"] = "Sliccer"

UNIT_SCAN_DATA["LAST_REGION"] = nil

function loadDefaultData()
	_G["CHECKBOX_GRID_STATE"] = {};
	_G["unitscanData_DB_VERSION"] = UNIT_SCAN_DATA["unitscanData_DB_VERSION"]
	for zoneId, zoneTable in pairs(OUTPUT_TABLE) do
	    _G["CHECKBOX_GRID_STATE"][zoneId] = {}
        for index, checkboxContent in pairs(zoneTable) do
            _G["CHECKBOX_GRID_STATE"][zoneId][index] = {}
             for key, value in pairs(checkboxContent) do
                _G["CHECKBOX_GRID_STATE"][zoneId][index][key] = value
            end
        end
    end

    local macroInfo = GetMacroInfo("unitscanHC");
    if macroInfo == nil then
        local newMacro = CreateMacro("unitscanHC", "SPELL_NATURE_SLEEP", "/hcscan", nil);
    end
	
	local macroInfoData = GetMacroInfo("unitscanData")
	if macroInfoData ~= nil then
		DeleteMacro("unitscanData")
	end
end

function loadhordedefault()
	_G["CHECKBOX_GRID_STATE"] = {};
	_G["unitscanData_DB_VERSION"] = UNIT_SCAN_DATA["unitscanData_DB_VERSION"]
	for zoneId, zoneTable in pairs(HORDE_TABLE) do
	    _G["CHECKBOX_GRID_STATE"][zoneId] = {}
        for index, checkboxContent in pairs(zoneTable) do
            _G["CHECKBOX_GRID_STATE"][zoneId][index] = {}
             for key, value in pairs(checkboxContent) do
                _G["CHECKBOX_GRID_STATE"][zoneId][index][key] = value
            end
        end
    end

    local macroInfo = GetMacroInfo("unitscanHC");
    if macroInfo == nil then
        local newMacro = CreateMacro("unitscanHC", "SPELL_NATURE_SLEEP", "/hcscan", nil);
    end
	
	local macroInfoData = GetMacroInfo("unitscanData")
	if macroInfoData ~= nil then
		DeleteMacro("unitscanData")
	end
end
