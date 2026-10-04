local _, L = ...;

local format, math, pi, halfpi = format, math, math.pi, math.pi / 2
local COLOUR_RED = "ffff0000"
local COLOUR_GREEN = "ff00ff00"
local COLOUR_YELLOW = "ffffff00"
local COLOUR_BLUE = "ff5041fa"
local gold_markup = CreateAtlasMarkup("nameplates-icon-elite-gold", 16, 16)
local silver_markup = CreateAtlasMarkup("nameplates-icon-elite-silver", 16, 16)
local skull_markup = CreateAtlasMarkup("DungeonSkull", 16, 16)
local classification = {[1]=gold_markup .. " ELITE",
                        [2]=silver_markup .. " Rare ELITE",
                        [4]="Rare"}
local reaction = {[-1]=COLOUR_RED, [0]=COLOUR_YELLOW, [1]=COLOUR_GREEN}

local UnitscanDataMainUI = _G["UnitscanDataMainUI"]
local MainFrameUI = CreateFrame("Frame", nil, UnitscanDataMainUI, BackdropTemplateMixin and "BackdropTemplate")
local ModelUI = CreateFrame("PlayerModel", nil, MainFrameUI)

function loadAllModel()
    local grid = getActiveGrid();
    for k, v in pairs(grid) do
        if v["active"] then
            ModelUI:SetCreature(v.id);
        end
    end
    ModelUI:SetCreature(0);
end

function update3DView(checkboxId)
    local checkbox = getActiveGrid()[checkboxId]
    if checkbox == nil then
        return
    end

    local unit = BESTIARY[checkbox.id]

    if unit == nil then
        return
    end

    ModelUI:SetCreature(checkbox.id)

    local levelColor = COLOUR_YELLOW
    if UnitLevel("player") > unit.maxLvl + 3 then
        levelColor = COLOUR_GREEN
    elseif UnitLevel("player") < unit.minLvl - 3 then
        levelColor = COLOUR_RED
    end
    local text = {}
    text[1] = "Reaction: |c" .. reaction[unit.react[2]] .. "H|r - |c" .. reaction[unit.react[1]] .. "A|r"
    text[2] = "Level range: |c" .. levelColor .. "[" .. unit.minLvl .. "-" .. unit.maxLvl .. "]|r"
    if UnitLevel("player") < unit.maxLvl + 5 then
        text[2] = text[2] .. skull_markup
    end
    text[3] = "Type: " .. (classification[checkbox.cls] or "Unknown")
    text[4] = checkbox.text
    text[5] = ""
    if unit.mana == nil then
        text[6] = "|c" .. COLOUR_BLUE .. "Mana: --|r"
    else
        text[6] = "|c" .. COLOUR_BLUE .. "Mana: " .. unit.mana .. "|r"
    end
    if unit.hp == nil then
        text[7] = "|c" .. COLOUR_GREEN .. "HP: ??|r"
    else
        text[7] = "|c" .. COLOUR_GREEN .. "HP: " .. unit.hp .. "|r"
    end
    text[8] = UNIT_TYPE[unit.typeId]

    for i = 1, 8 do
        if text[i] == nil or text[i] == "" then
            MainFrameUI["Label" .. i]:Hide()
        else
            MainFrameUI["Label" .. i]:SetText(text[i])
            MainFrameUI["Label" .. i]:Show()
        end
    end
end

for index=1,75 do
    local MyCheckButton = _G["MyCheckButton" .. index]
    MyCheckButton:HookScript("OnEnter", function()
        if MyCheckButton:IsShown() then
            MainFrameUI:Show()
            update3DView(index)
        end
    end)
end

UnitscanDataMainUI:HookScript("OnHide", function() MainFrameUI:Hide() end)

MainFrameUI:SetPoint("TOPLEFT", UnitscanDataMainUI, "TOPRIGHT", 0, 0)
MainFrameUI:SetSize(312, 396)
MainFrameUI:SetBackdrop({
    bgFile = "Interface\\Addons\\unitscanData\\assets\\WhiteLine",
    edgeFile = "Interface\\Addons\\unitscanData\\assets\\border",
	edgeSize = 16,
	insets = { left = 4, right = 4, top = 4, bottom = 4 },
})
MainFrameUI:SetBackdropColor(0.1, 0.1, 0.1, 0.8)
MainFrameUI:SetMovable(false)
MainFrameUI:Hide()
for i=1, 4 do
    MainFrameUI["Label" .. i] = MainFrameUI:CreateFontString("Label", nil, "GameFontNormal")
    MainFrameUI["Label" .. i]:SetJustifyH("RIGHT")
    MainFrameUI["Label" .. i]:SetPoint("BOTTOMRIGHT", MainFrameUI, "BOTTOMRIGHT", -8, 6 + 16 * (i - 1))
    MainFrameUI["Label" .. i+4] = MainFrameUI:CreateFontString("Label", nil, "GameFontNormal")
    MainFrameUI["Label" .. i+4]:SetJustifyH("RIGHT")
    MainFrameUI["Label" .. i+4]:SetPoint("BOTTOMLEFT", MainFrameUI, "BOTTOMLEFT", 8, 6 + 16 * (i - 1))
end

ModelUI:RefreshUnit()
ModelUI:SetPoint("TOP", MainFrameUI, "TOP", 0, -5)
ModelUI:SetSize(300, 300)
ModelUI:SetMovable(false)
ModelUI:EnableMouse(true)
ModelUI:EnableMouseWheel(true)

local function onDragUpdate(self, elapsed)
    local x, y = GetCursorPosition()
    local px, py, pz = self:GetPosition()
    if IsAltKeyDown() then
        local mx = format("%.2f", (px + (y - self.y) / 64))
        if format("%.2f", px) ~= mx then
            self:SetPosition(mx, py, pz)
        end
    else
        local my = format("%.2f", (py + (x - self.x) / 64))
        local mz = format("%.2f", (pz + (y - self.y) / 64))
        if format("%.2f", py) ~= my or format("%.2f", pz) ~= mz then
            self:SetPosition(px, my, mz)
        end
    end
    self.x, self.y = x, y
end

local function onRotateHUpdate(self, elapsed)
    local x, y = GetCursorPosition()
    local rotation = format("%.0f", math.abs(math.deg(((x - self.x) / 84 + self:GetFacing())) % 360))
    if rotation ~= format("%.0f", math.abs(math.deg(self:GetFacing()) % 360)) then
        self:SetRotation(math.rad(rotation))
    end
    self.x, self.y = x, y
end

local function OnMouseDown(self, button)
    if button == "LeftButton" then
        self.x, self.y = GetCursorPosition()
        self:SetScript("OnUpdate", onDragUpdate)
    elseif button == "RightButton" then
        self.x, self.x = GetCursorPosition()
        self:SetScript("OnUpdate", onRotateHUpdate)
    end
end

local function OnMouseUp(self, button)
    if button == "LeftButton" then
        self:SetScript("OnUpdate", nil)
    elseif button == "RightButton" then
        self:SetScript("OnUpdate", nil)
    elseif button == "MiddleButton" then
        self:SetScript("OnUpdate", nil)
    end
end


ModelUI:SetScript("OnMouseDown", OnMouseDown)
ModelUI:SetScript("OnMouseUp", OnMouseUp)


ModelUI:RegisterEvent("ZONE_CHANGED_NEW_AREA");
local function onAddonModel3DEvent(self, event, arg1, ...)
    if event == "ZONE_CHANGED" or event == "ZONE_CHANGED_INDOORS" or event == "ZONE_CHANGED_NEW_AREA" then
        loadAllModel();
 	end
end
ModelUI:SetScript("OnEvent", onAddonModel3DEvent);