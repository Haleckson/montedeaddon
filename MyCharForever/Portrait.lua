local addonName, MCF = ...
-- Character portrait for the website. The game cannot hand out its 3D portrait as an image file, so the addon shows
-- the head of the character alone in the middle of the screen and takes a screenshot of it. The screenshot is logged
-- like every other one (reason "PORTRAIT") together with the crop that frames the picture (screenshots[].portrait:
-- zoom, x, y); the website cuts the round portrait out of it by itself. The newest PORTRAIT screenshot counts.

local function de() return MCF:GetLanguage() == "deDE" end
local function L(german, english) return de() and german or english end

local FRAME_SIZE = 256   -- edge of the picture frame in UI units, shown exactly in the middle of the screen
local CROP_SHARE = 0.92  -- the website crops slightly inside the frame so that no frame edge reaches the round portrait
local SETTLE = 1.4       -- seconds the model gets to load and turn to the camera before the screenshot is requested
local BACKGROUND = {0.11, 0.10, 0.15, 1}

local info, cap, preview, status
local mode3d = true
local busy = false

-- One head picture: 3D model of the player (head close-up) or, as a fallback, the game's 2D portrait texture.
local function MakeView(parent, size)
    local v = CreateFrame("Frame", nil, parent)
    v:SetSize(size, size)
    v.bg = v:CreateTexture(nil, "BACKGROUND")
    v.bg:SetAllPoints()
    v.bg:SetColorTexture(unpack(BACKGROUND))
    local okModel, model = pcall(CreateFrame, "PlayerModel", nil, v)
    if okModel and model then
        v.model = model
        model:SetAllPoints()
        -- The head close-up only works once the model has loaded.
        model:SetScript("OnModelLoaded", function(self)
            pcall(function() if self.SetPortraitZoom then self:SetPortraitZoom(1) end end)
        end)
    end
    v.tex = v:CreateTexture(nil, "ARTWORK")
    v.tex:SetAllPoints()
    v.tex:Hide()
    return v
end

local function Refresh(v)
    if not v then return end
    local use3d = mode3d and v.model ~= nil
    if v.model then v.model:SetShown(use3d) end
    v.tex:SetShown(not use3d)
    if use3d then
        pcall(function()
            v.model:SetUnit("player")
            if v.model.SetPortraitZoom then v.model:SetPortraitZoom(1) end
            if v.model.SetRotation then v.model:SetRotation(0) end
        end)
    else
        pcall(SetPortraitTexture, v.tex, "player")
    end
end

local function SetStatus(text)
    if status then status:SetText(text or "") end
end

local function EndCapture(entry)
    if cap then cap:Hide() end
    busy = false
    if info then info:Show() end
    if entry then
        SetStatus(L("Porträt gespeichert. Es erscheint im Chronik-Viewer, sobald du dort den Screenshot-Ordner verbindest.",
            "Portrait saved. It appears in the chronicle viewer once you connect the screenshot folder there."))
    else
        SetStatus(L("Das Porträt konnte nicht aufgenommen werden.", "The portrait could not be taken."))
    end
end

local function StartCapture()
    if busy then return end
    if not (MyCharForeverDB and MCF.TakePortraitScreenshot) then return end
    busy = true
    SetStatus("")
    info:Hide()
    if not cap then
        cap = CreateFrame("Frame", "MyCharForeverPortraitCapture", UIParent)
        cap:SetFrameStrata("TOOLTIP")
        cap:SetSize(FRAME_SIZE, FRAME_SIZE)
        cap:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
        cap.view = MakeView(cap, FRAME_SIZE)
        cap.view:SetAllPoints()
    end
    cap:Show()
    Refresh(cap.view)
    C_Timer.After(0.4, function() if cap:IsShown() then Refresh(cap.view) end end)
    C_Timer.After(SETTLE, function()
        if not cap:IsShown() then busy = false; return end
        local height = UIParent:GetHeight() or 768
        local crop = {
            zoom = math.floor(height / (FRAME_SIZE * CROP_SHARE) * 1000 + 0.5) / 1000,
            x = 50, y = 50,
            mode = (mode3d and cap.view.model) and "3d" or "2d",
        }
        MCF:TakePortraitScreenshot(crop, EndCapture)
    end)
end

local function BuildWindow()
    info = CreateFrame("Frame", "MyCharForeverPortraitFrame", UIParent, "BasicFrameTemplateWithInset")
    info:SetSize(470, 560)
    info:SetPoint("CENTER")
    info:SetFrameStrata("DIALOG")
    info:SetMovable(true); info:EnableMouse(true)
    info:RegisterForDrag("LeftButton")
    info:SetScript("OnDragStart", info.StartMoving)
    info:SetScript("OnDragStop", info.StopMovingOrSizing)
    if MCF.MakeOpaque then MCF.MakeOpaque(info, 24) end
    info.TitleText:SetText("MyCharForever")

    info.head = info:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    info.head:SetPoint("TOPLEFT", 18, -34)

    info.text = info:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    info.text:SetPoint("TOPLEFT", 18, -62)
    info.text:SetPoint("TOPRIGHT", -18, -62)
    info.text:SetJustifyH("LEFT")
    info.text:SetSpacing(3)

    preview = MakeView(info, 128)
    preview:SetPoint("TOPLEFT", info.text, "BOTTOMLEFT", 6, -20)
    local frameBorder = info:CreateTexture(nil, "BACKGROUND")
    frameBorder:SetPoint("TOPLEFT", preview, "TOPLEFT", -3, 3)
    frameBorder:SetPoint("BOTTOMRIGHT", preview, "BOTTOMRIGHT", 3, -3)
    frameBorder:SetColorTexture(0.85, 0.65, 0.13, 1)

    info.hint = info:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    info.hint:SetPoint("LEFT", preview, "RIGHT", 18, 40)
    info.hint:SetPoint("RIGHT", info, "RIGHT", -18, 0)
    info.hint:SetJustifyH("LEFT")
    info.hint:SetSpacing(2)

    info.take = CreateFrame("Button", nil, info, "UIPanelButtonTemplate")
    info.take:SetSize(150, 26)
    info.take:SetPoint("LEFT", preview, "RIGHT", 18, 6)
    info.take:SetScript("OnClick", StartCapture)

    info.switch = CreateFrame("Button", nil, info, "UIPanelButtonTemplate")
    info.switch:SetSize(150, 24)
    info.switch:SetPoint("TOPLEFT", info.take, "BOTTOMLEFT", 0, -6)
    info.switch:SetScript("OnClick", function()
        mode3d = not mode3d
        Refresh(preview)
        info:UpdateTexts()
    end)

    status = info:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    status:SetPoint("TOPLEFT", preview, "BOTTOMLEFT", -6, -16)
    status:SetWidth(430)
    status:SetJustifyH("LEFT")
    status:SetSpacing(2)

    function info:UpdateTexts()
        self.head:SetText(L("Porträt für deine Chronik", "Portrait for your chronicle"))
        self.text:SetText(L(
            "Auf der Webseite bekommt dein Charakter ein rundes Porträt. Das Spiel kann sein Porträt nicht als Bilddatei weitergeben, deshalb macht das Addon dafür einen Screenshot:\n\n1. Rüste an, was auf dem Bild zu sehen sein soll (Helm, Schulterstücke).\n2. Klicke auf „Aufnehmen“. Das Fenster verschwindet und dein Kopf erscheint kurz in der Bildschirmmitte.\n3. Bewege dich bitte nicht. Nach etwa einer Sekunde wird der Screenshot gemacht, danach ist alles wieder da.\n\nDie Webseite zeigt das Porträt, sobald du dort den Screenshot-Ordner verbindest.",
            "On the website your character gets a round portrait. The game cannot hand out its portrait as an image file, so the addon takes a screenshot for it:\n\n1. Equip what the picture should show (helmet, shoulders).\n2. Click \"Take portrait\". The window disappears and your head shows in the middle of the screen for a moment.\n3. Please do not move. After about a second the screenshot is taken and everything comes back.\n\nThe website shows the portrait as soon as you connect the screenshot folder there."))
        self.hint:SetText(mode3d and L("Vorschau: 3D-Kopf", "Preview: 3D head") or L("Vorschau: 2D-Porträt", "Preview: 2D portrait"))
        self.take:SetText(L("Aufnehmen", "Take portrait"))
        self.switch:SetText(mode3d and L("2D-Porträt nehmen", "Use 2D portrait") or L("3D-Kopf nehmen", "Use 3D head"))
    end
end

function MCF:ShowPortraitWindow()
    if not info then BuildWindow() end
    info:UpdateTexts()
    SetStatus("")
    info:Show()
    Refresh(preview)
    C_Timer.After(0.3, function() if info:IsShown() then Refresh(preview) end end)
end

MCF:AddCommand{group = "main", usage = "/mcf portrait", key = "portrait",
    de = "Porträt für die Webseite aufnehmen (Kopf in der Bildschirmmitte, automatischer Screenshot)",
    en = "Take the portrait for the website (head in the middle of the screen, automatic screenshot)",
    run = function() MCF:ShowPortraitWindow() end}
