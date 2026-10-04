local USHCverify = _G["USHCverify"]

local version = select(1, GetBuildInfo())

if not USHCverify or not USHCverify.isMainLoaded then
    print("|cFFFF0000Warning: Unitscan Hardcore installation is corrupted and will not work properly! Please re-download on CurseForge: |cFFFFFF00https://www.curseforge.com/wow/addons/unitscan-hardcore|r|cFFFF0000. Do not use multiple versions of unitscan at the same time!|r")
else
    print("|cFFFF0000Unitscan Hardcore " .. version .. "|r |cFFE6E600loaded|r |cFF00FF00successfully|r. Type |cFFFFFF00\"|cFF00FF00/Hcscan|cFFFFFF00\"|c00ADD8E6 for Settings (Bank Alt Protection is enabled by default) - Move Alert Frames by Holding CTRL|r")
end


