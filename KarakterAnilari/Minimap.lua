-- Karakter Anıları / Character Memoir - Minimap butonu
-- Sol tık: anı defteri, sağ tık: kitap, sürükle: minimap kenarında taşı.

local ADDON, ns = ...
local L = ns.L

local ICON = "Interface\\Icons\\INV_Misc_Book_09"
local DEFAULT_ANGLE = 200 -- derece, minimap'in sol-altı

local button

local function Settings()
    ns.settings = ns.settings or {}
    return ns.settings
end

local function UpdatePosition()
    local angle = math.rad(Settings().minimapAngle or DEFAULT_ANGLE)
    local radius = (Minimap:GetWidth() / 2) + 10
    button:ClearAllPoints()
    button:SetPoint("CENTER", Minimap, "CENTER", math.cos(angle) * radius, math.sin(angle) * radius)
end

local function OnDragUpdate()
    local mx, my = Minimap:GetCenter()
    local px, py = GetCursorPosition()
    local scale = Minimap:GetEffectiveScale()
    px, py = px / scale, py / scale
    Settings().minimapAngle = math.deg(math.atan2(py - my, px - mx)) % 360
    UpdatePosition()
end

local function ShowTooltip(self)
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    -- Tooltip oyunun fontunu kullanır; ş/ğ orada görünmediği için güvenli hale getiriyoruz
    GameTooltip:AddLine(ns.GameFontSafe(L.MM_TITLE), 1, 0.82, 0)
    if ns.db then
        GameTooltip:AddLine(ns.GameFontSafe(string.format("%d %s", #ns.db.events,
            L.UI_STATS:match("|r%s+(%S+)") or "")), 1, 1, 1)
    end
    GameTooltip:AddLine(" ")
    GameTooltip:AddLine(ns.GameFontSafe(L.MM_LEFT), 0.8, 0.8, 0.8)
    GameTooltip:AddLine(ns.GameFontSafe(L.MM_RIGHT), 0.8, 0.8, 0.8)
    GameTooltip:AddLine(ns.GameFontSafe(L.MM_DRAG), 0.8, 0.8, 0.8)
    GameTooltip:Show()
end

local function CreateButton()
    if button or not Minimap then return end

    button = CreateFrame("Button", "KarakterAnilariMinimapButton", Minimap)
    button:SetSize(31, 31)
    button:SetFrameStrata("MEDIUM")
    button:SetFrameLevel(8)
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    button:RegisterForDrag("LeftButton")
    button:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

    local overlay = button:CreateTexture(nil, "OVERLAY")
    overlay:SetSize(53, 53)
    overlay:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    overlay:SetPoint("TOPLEFT")

    local background = button:CreateTexture(nil, "BACKGROUND")
    background:SetSize(20, 20)
    background:SetTexture("Interface\\Minimap\\UI-Minimap-Background")
    background:SetPoint("TOPLEFT", 7, -5)

    local icon = button:CreateTexture(nil, "ARTWORK")
    icon:SetSize(17, 17)
    icon:SetTexture(ICON)
    icon:SetPoint("TOPLEFT", 7, -6)
    icon:SetTexCoord(0.05, 0.95, 0.05, 0.95)

    button:SetScript("OnClick", function(_, mouse)
        if mouse == "RightButton" then ns.ToggleBook() else ns.ToggleUI() end
    end)
    button:SetScript("OnDragStart", function(self)
        self:SetScript("OnUpdate", OnDragUpdate)
        GameTooltip:Hide()
    end)
    button:SetScript("OnDragStop", function(self)
        self:SetScript("OnUpdate", nil)
    end)
    button:SetScript("OnEnter", ShowTooltip)
    button:SetScript("OnLeave", function() GameTooltip:Hide() end)

    UpdatePosition()
    button:SetShown(not Settings().minimapHidden)
end

-- Komut: /anilar minimap -> göster/gizle. Yeni durumu döndürür (true = görünür).
function ns.ToggleMinimapButton()
    if not button then CreateButton() end
    local s = Settings()
    s.minimapHidden = not s.minimapHidden
    if button then button:SetShown(not s.minimapHidden) end
    return not s.minimapHidden
end

-- Ayarlar yüklendikten sonra butonu oluştur
local loader = CreateFrame("Frame")
loader:RegisterEvent("PLAYER_LOGIN")
loader:SetScript("OnEvent", function()
    pcall(CreateButton)
end)
