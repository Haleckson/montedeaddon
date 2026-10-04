local ldbi = LibStub("LibDBIcon-1.0")

local function OnLogin()
    local playerName = UnitName("player")
    local playerRealm = GetRealmName()

    if playerName == "Testchimp" and playerRealm == "Nek'Rosh" then
        print("Loaded")
    end
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_LOGIN")
frame:SetScript("OnEvent", OnLogin)
