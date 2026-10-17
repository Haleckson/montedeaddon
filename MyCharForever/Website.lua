local addonName, MCF = ...
-- The project website: the one place for its address and for the window that shows it.
-- WoW addons cannot open a browser, so the window offers the address in a selected text field (Ctrl+C copies it).
-- Used by the welcome window, the main window button, the screenshots info text and /mcf website.

MCF.Website = {
  host = "www.mycharforever.com",
  width = 460,
  height = 230,
}
local W = MCF.Website

local function de() return MCF:GetLanguage() == "deDE" end

function MCF:GetWebsiteText()
  if de() then
    return "Auf der Website wird deine Chronik zum Fotobuch: Screenshots mit Level und Ort, Tagebuch, Gold-Diagramme, Dungeons und mehr, "
      .. "schöner dargestellt als im Spiel. Du wählst dort deinen WoW-Ordner; die Seite läuft nur in deinem Browser, nichts wird hochgeladen. "
      .. "Dort kannst du auch die neueste Addon-Version herunterladen."
  end
  return "On the website your chronicle becomes a photo book: screenshots with level and place, journal, gold charts, dungeons and more, "
    .. "shown more nicely than in the game. You pick your WoW folder there; the page runs only in your browser and nothing is uploaded. "
    .. "You can also download the latest addon version there."
end

local window, text, edit
local function build()
  if window then return end
  window = MCF.Kit.Window("MyCharForeverWebsiteFrame", {w = W.width, h = W.height, level = 880})
  text = window.content:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
  text:SetPoint("TOPLEFT", 4, -4); text:SetWidth(W.width - 56); text:SetJustifyH("LEFT"); text:SetJustifyV("TOP")
  edit = CreateFrame("EditBox", nil, window.content, "InputBoxTemplate")
  edit:SetSize(W.width - 70, 24); edit:SetPoint("BOTTOMLEFT", 8, 12); edit:SetAutoFocus(false)
  edit:SetScript("OnEscapePressed", function(self) self:ClearFocus(); window:Hide() end)
  -- the address stays as it is: typing or pasting in this field changes nothing
  edit:SetScript("OnTextChanged", function(self, user) if user then self:SetText(W.host); self:HighlightText() end end)
  edit:SetScript("OnEditFocusGained", function(self) self:HighlightText() end)
end

function MCF:ShowWebsite()
  build()
  window.title:SetText(de() and "MyCharForever im Browser" or "MyCharForever in your browser")
  text:SetText(self:GetWebsiteText())
  edit:SetText(W.host); edit:SetCursorPosition(0)
  window:Show(); window:Raise()
  edit:SetFocus(); edit:HighlightText()
end

MCF:AddCommand{group="main", usage="/mcf website", key="website",
  de="Adresse der Website anzeigen (Fotobuch, Download)", en="Show the website address (photo book, download)",
  run=function() MCF:ShowWebsite() end}
