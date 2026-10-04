local NewFrameUI = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")

NewFrameUI:SetPoint("TOPRIGHT", UnitscanDataMainUI, "TOPLEFT", 0, 0)

NewFrameUI:SetSize(300, 660)

NewFrameUI:SetBackdrop({
    bgFile = "Interface\\Addons\\unitscanData\\assets\\WhiteLine",
    edgeFile = "Interface\\Addons\\unitscanData\\assets\\border",
    edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 },
})

NewFrameUI:SetBackdropColor(0.1, 0.1, 0.1, 0.8)
NewFrameUI:SetMovable(true)
NewFrameUI:Hide()

local ScrollFrame = CreateFrame("ScrollFrame", nil, NewFrameUI, "UIPanelScrollFrameTemplate")
ScrollFrame:SetSize(280, 590)
ScrollFrame:SetPoint("TOPLEFT", NewFrameUI, "TOPLEFT", -10, -10)
ScrollFrame:SetClipsChildren(true) -- fix missalignment on wow forever

local ScrollChild = CreateFrame("Frame", nil, ScrollFrame)
ScrollChild:SetSize(280, 630)
ScrollFrame:SetScrollChild(ScrollChild)

local newsEntries = {}

local function AddNewsEntry(headline, realm, date, text)
    local entry = CreateFrame("Frame", nil, ScrollChild)
    entry:SetSize(260, 100)
    entry:SetPoint("TOP", ScrollChild, "TOP", 0, -#newsEntries * 120)

    local headlineText = entry:CreateFontString(nil, "ARTWORK", "GameFontNormalLargeOutline")
    headlineText:SetPoint("TOPLEFT", entry, "TOPLEFT", 10, 0)
    headlineText:SetText(headline)

    local realmDateText = entry:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    realmDateText:SetPoint("TOPLEFT", headlineText, "BOTTOMLEFT", 0, -5)

    local playerRealm = GetRealmName()

    local strippedRealm = realm:match("^(.-)-[EUUS]+$") or realm

    if strippedRealm == playerRealm then
        realmDateText:SetText("|cff00ff00" .. realm .. "|r | " .. "|cffFFFFFF" .. date .. "|r")
    else
        -- 38F
        if realm == "General News" then
            realmDateText:SetText("|cffff0000" .. realm .. "|r | " .. "|cffFFFFFF" .. date .. "|r")
        else
            realmDateText:SetText(realm .. " | " .. "|cffFFFFFF" .. date .. "|r")
        end
    end

    -- T2
    local newsText = entry:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    newsText:SetPoint("TOPLEFT", realmDateText, "BOTTOMLEFT", 0, -5)
    newsText:SetWidth(260)
    newsText:SetJustifyH("LEFT")
    newsText:SetText(text)
    newsText:SetWordWrap(true)

    -- E1
    table.insert(newsEntries, entry)

    -- E2
    ScrollChild:SetHeight(#newsEntries * 120)
end

AddNewsEntry("Classic Forever", "General News", "September 16, 2026", "PSA: UnitScan Hardcore will be maintained & available in WoW Classic Forever. Thanks for all the feedback and reported bugs so far, see you in Forever!")
AddNewsEntry("Orgrimmar Griefer", "Soulseeker-EU", "August 20, 2026", "Multiple Deaths due to griefing in Orgrimmar, Thralls room, have been reported on Soulseeker, if you are playing a low level character be vigilant.")
AddNewsEntry("Server Instability", "Doomhowl-US", "August 7, 2026", "Doomhowl is experiencing repeated server instability and disconnects across multiple days. Many deaths have been reported, it is currently not recommended to play.")
AddNewsEntry("Griefer Warning", "Soulseeker-EU", "June 21, 2026", "Beware of |cFFC77BFFSchnellerf|r, Human Paladin on EU Stitches has been reported to grief in Stormwind by dragging Elite Onyxia Guards to the Trade District and AH.")
AddNewsEntry("Midnight Release", "General News", "March 3, 2026", "The Midnight Expansion has been released on retail. Server instability and other issus are anticipated to affect gameplay. Caution when playing is highly advised.")
AddNewsEntry("TBC Release", "General News", "February 5, 2026", "The Burning Crusade is about to be released. Server instability and other issus are anticipated to affect gameplay. Caution when playing is highly advised.")
AddNewsEntry("TBC Prepatch", "General News", "January 15, 2026", "The Prepatch for TBC went live and server instability aswell as TBC spill-over on Hardcore servers are expected, be mindful when playing during this time.")
AddNewsEntry("Characters Restored", "Doomhowl-US", "January 6, 2026", "Blizzard has restored Hardcore characters lost during a recent DDoS attack on Doomhowl-US, characters on Defias Pillager were also restored.")
AddNewsEntry("Server Instability", "Doomhowl-US", "January 4, 2026", "Doomhowl is experiencing instability and disconnects due to an apparent DDoS Attack. A large number of Players have died recently, caution is advised when playing.")
AddNewsEntry("Beware of Ayse", "Soulseeker-EU", "January 3, 2026", "Player |cFFC77BFFAyse|r, a confirmed Griefer, has been spotted trying to kill low level players in Duskwood & Westfall. Be aware when encountering this Player.")
AddNewsEntry("Twitch Event", "Soulseeker-EU", "December 27, 2025", "The Germans are currently laying siege to Soulseeker, as part of their Twitch-Event. As a result, the Server could be unstable, caution is advised.")
AddNewsEntry("Naxxramas - Scourge Invasions", "General News", "October 2, 2025", "Scourge Invasions are now active in Anniversary Hardcore Servers. Major cities may come under attack, posing a serious threat to low-level characters and bank alts.")
AddNewsEntry("Booty Bay Guard Aggro", "Doomhowl-US", "August 25, 2025", "Players are redirecting Booty Bay guard aggro onto others by engaging them and then requesting buffs from unsuspecting players to get them killed.")
AddNewsEntry("Race for World First in Progress", "General News", "August 13, 2025", "The Race for World First is underway on retail servers. Performance issues may occur, so caution is advised when playing on Hardcore Servers.")
AddNewsEntry("Confirmed DDoS Attack", "Soulseeker-EU", "July 29, 2025", "Blizzard has confirmed an ongoing DDoS attack causing severe server instability on Soulseeker-EU. Many deaths have been reported; be very cautious.")
AddNewsEntry("Mind Control PvP Grief", "Soulseeker-EU", "July 13, 2025", "Players are abusing NPC mind control during the AQ War Effort event in Silithus to kill others. Stay alert in the area when engaging enemies with MC.")
AddNewsEntry("ZG Release & Instability", "General News", "May 2, 2025", "Zul'Gurub has been released. Server instability and possible DDoS activity are currently affecting gameplay - many Deaths have been reported so far.")
AddNewsEntry("Server instability & DC's ", "General News", "March 17, 2025", "All Servers are experiencing instability and disconnects due to DDoS Attacks. A large number of Players have died recently, caution is advised when playing right now.")
AddNewsEntry("RFC Grief Runs", "Doomhowl-US", "January 11, 2025", "|cFFC77BFFLongsleeve|r is inviting players for RFC runs and intentionally wiping groups by pulling adds from the lava bridge area. Be cautious when joining groups.")
AddNewsEntry("Goblin Mortar Griefing Alert", "Soulseeker-EU", "January 6, 2025", "|cFFC77BFFBreevobrath|r and |cFFC77BFFBugli|r are using the Goblin Mortar to kill Bank alts. Party is required to be killed; avoid accepting group invites from strangers on low level characters/bank alts.")
AddNewsEntry("Character Profiles & Tracking", "General News", "December 10, 2024", "Unitscan Hardcore now tracks PvP NPC's by default for your respective Faction and saves settings per character, enabling faction- and level-based configurations.")
AddNewsEntry("Upcoming Fresh Realms", "General News", "November 14, 2024", "A Fresh Era and Hardcore realm are set to launch on November 21st. All HC players should prepare for possible server outages and lag during peak times.")
AddNewsEntry("Auction House Attack Warning", "Defias Pillager-US", "November 7, 2024", "|cFFC77BFFSeymoor|r is dragging Onyxia Elite Guards and the Sewer Beast to the SW Auction House, targeting low-level players with lethal cleave attacks.")
AddNewsEntry("Malicious Summons Alert", "Defias Pillager-US", "November 5, 2024", "Be cautious of |cFFC77BFFThirdsisters|r and |cFFC77BFFDavidgogomo|r advertising harmful summons intended to drop players into the lava in Ironforge.")
AddNewsEntry("Strat Pet Debuff Grief", "Defias Pillager-US", "November 1, 2024", "Beware of |cFFC77BFFAjleg|r on DP US, abusing Debuffs from Strat to summon hostile Units. Tracking Wrath & Spiteful Phantom across all Zones now.")
AddNewsEntry("Beware of Xkinger", "Stitches-EU", "October 20, 2024", "Tracking for |cFFC77BFFXkinger|r, a known Griefer on EU Stitches has been enabled in all Zones for Alliance Players, in addition to tracking all Units he is using for griefing.")
AddNewsEntry("STV Ogre Griefing", "General News", "October 13, 2024", "Beware of Griefers dragging Warmonger Ogres from STV to Elwynn, Duskwood, Redridge & Westfall. Tracking for the above units in lower level zones has been enabled by default.")

UnitscanDataMainUI:HookScript("OnHide", function() NewFrameUI:Hide() end)
UnitscanDataMainUI:HookScript("OnShow", function() NewFrameUI:Show() end)

local DeactivateNews = CreateFrame("CheckButton", "DeactivateNews", NewFrameUI, "UICheckButtonTemplate")
DeactivateNews:SetPoint("BOTTOM", NewFrameUI, "BOTTOM", -120, 10)

DeactivateNews.text = DeactivateNews:CreateFontString(nil, "OVERLAY", "GameFontNormal")
DeactivateNews.text:SetPoint("LEFT", DeactivateNews, "RIGHT", 4, 0)
DeactivateNews.text:SetText("News only show on login in\nsafe areas and for unread entries.\nCheck the box to disable.")

local function UpdateDeactivateNewsCheckbox()
    DeactivateNews:SetChecked(not newsEnabled)
end

NewFrameUI:HookScript("OnShow", UpdateDeactivateNewsCheckbox)
UpdateDeactivateNewsCheckbox()

DeactivateNews:SetScript("OnClick", function(self)
    newsEnabled = not self:GetChecked()

    if newsEnabled then
        print("|cff00ff00UnitScan Hardcore News on login enabled|r")
    else
        print("|cffff0000UnitScan Hardcore News on login disabled.|r")
    end

    ShowNewsIfNecessary()
end)