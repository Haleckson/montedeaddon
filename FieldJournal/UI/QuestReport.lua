local _, FieldJournal = ...

FieldJournal.UI = FieldJournal.UI or {}
local Report = {}
FieldJournal.UI.QuestReport = Report

local REPORT_URL = "https://www.curseforge.com/wow/addons/forever-field-journal/comments"

local frame = CreateFrame("Frame", "FieldJournalQuestReportFrame", UIParent, "BackdropTemplate")
frame:SetSize(540, 230)
frame:SetPoint("CENTER")
frame:SetFrameStrata("DIALOG")
frame:SetClampedToScreen(true)
frame:EnableMouse(true)
frame:SetMovable(true)
frame:RegisterForDrag("LeftButton")
frame:SetScript("OnDragStart", frame.StartMoving)
frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
frame:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    edgeSize = 32,
    insets = { left = 11, right = 12, top = 12, bottom = 11 },
})
frame:Hide()

local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
title:SetPoint("TOP", 0, -22)
title:SetText("Report a missing Field Journal quest")

local instruction = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
instruction:SetPoint("TOPLEFT", 27, -57)
instruction:SetPoint("TOPRIGHT", -27, -57)
instruction:SetJustifyH("LEFT")
instruction:SetText("Copy the link below (Ctrl+C) into your browser. Then copy the quest details into a comment:")

local function MakeCopyBox(y)
    local box = CreateFrame("EditBox", nil, frame, "InputBoxTemplate")
    box:SetSize(472, 28)
    box:SetPoint("TOP", frame, "TOP", 0, y)
    box:SetAutoFocus(false)
    box:SetScript("OnEditFocusGained", function(self) self:HighlightText() end)
    box:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    box:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
    return box
end

local urlBox = MakeCopyBox(-109)
urlBox:SetText(REPORT_URL)
local detailsBox = MakeCopyBox(-153)

local close = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
close:SetSize(110, 24)
close:SetPoint("BOTTOM", 0, 24)
close:SetText("Done")
close:SetScript("OnClick", function() frame:Hide() end)

if UISpecialFrames then
    table.insert(UISpecialFrames, "FieldJournalQuestReportFrame")
end

function Report:ShowReport(quest)
    local details = string.format("Missing journal quest: %s | Quest ID: %d | Zone: %s",
        tostring(quest.title or "Unknown"), quest.id, tostring(quest.zone or "Unknown"))
    if quest.subregion and quest.subregion ~= "" then
        details = details .. " | Area: " .. quest.subregion
    end
    if quest.npcName and quest.npcName ~= "" then
        details = details .. " | Quest giver: " .. quest.npcName
    end
    detailsBox:SetText(details)
    frame:Show()
    urlBox:SetFocus()
    urlBox:HighlightText()
end

StaticPopupDialogs["FIELDJOURNAL_MISSING_QUEST"] = {
    text = "Forever Field Journal: You've discovered a quest without a written journal entry: %s. Would you like to report it on the addon page?",
    button1 = "Yes, show report link",
    button2 = "No thanks",
    OnAccept = function(_, quest)
        if quest then Report:ShowReport(quest) end
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

function Report:ShowUnknownQuest(questID, record)
    if not questID or not StaticPopup_Show then return end
    local quest = {
        id = questID,
        title = record and record.title or ("Quest " .. tostring(questID)),
        zone = record and record.zone or "Unknown",
        subregion = record and record.subregion,
        npcName = record and record.npcName,
    }
    StaticPopup_Show("FIELDJOURNAL_MISSING_QUEST",
        quest.title .. " (ID " .. tostring(questID) .. ")", nil, quest)
end
