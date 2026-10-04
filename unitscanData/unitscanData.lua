local _, L = ...;

SLASH_UNITSCANDATA1 = "/hcscan";

function SlashCmdList.UNITSCANDATA(msg)
    if msg == "version" then
        return UNIT_SCAN_DATA["unitscanData_VERSION"]
    end
    local activeGrid = getActiveGrid()
    autoscan_verifyConsistency(activeGrid)
    local r = drawGrid(activeGrid)
    enableToggles(r)
    UnitscanDataMainUI:Show()
end

local startHide = true;

local InfoFrameUI = CreateFrame("Frame", "unitscanDataInfoFrameUI", UIParent);
InfoFrameUI:SetClampedToScreen(true);
InfoFrameUI:SetFrameStrata("DIALOG");
InfoFrameUI:SetSize(236, 320);
InfoFrameUI:SetPoint("CENTER", UIParent, "CENTER");
InfoFrameUI:Hide();
InfoFrameUI.Label = InfoFrameUI:CreateFontString("Label", nil, "GameFontNormal");
InfoFrameUI.Label:SetJustifyH("LEFT");
InfoFrameUI.Label:SetPoint("TOP", InfoFrameUI, "TOP", 0, -9);
InfoFrameUI.Label:SetText(L["unitscanData - INFO"]);
InfoFrameUI:SetFrameStrata("MEDIUM");
local InfoMessageFrame = CreateFrame("MessageFrame", "unitscanDataInfoMessageFrame", InfoFrameUI)
InfoMessageFrame:SetSize(220, 300)
InfoMessageFrame:SetPoint("BOTTOM", InfoFrameUI, "BOTTOM", 4, 12);
InfoMessageFrame:SetJustifyH("LEFT")
InfoMessageFrame:SetJustifyV("MIDDLE")
InfoMessageFrame:SetFontObject("GameFontNormal")
InfoMessageFrame:SetFading(false)
InfoMessageFrame:Show()
InfoMessageFrame:AddMessage(getInfoText())
local ExitButton = CreateFrame("Button", "unitscanDataInfoFrameUIClose", InfoFrameUI, "UIPanelCloseButton")
ExitButton:SetPoint("TOPRIGHT", 1, 1)

local UnitscanDataMainUI = CreateFrame("Frame", "UnitscanDataMainUI", UIParent);
UnitscanDataMainUI:SetClampedToScreen(true);
UnitscanDataMainUI:SetFrameStrata("LOW");
UnitscanDataMainUI:SetSize(750, 660);
UnitscanDataMainUI:SetPoint("CENTER", UIParent, "CENTER", 20, 10);
UnitscanDataMainUI:Show();
if startHide then UnitscanDataMainUI:Hide() end
UnitscanDataMainUI:SetMovable(true);
UnitscanDataMainUI:EnableMouse(true);
UnitscanDataMainUI:RegisterForDrag("LeftButton");
UnitscanDataMainUI:SetScript("OnDragStart", UnitscanDataMainUI.StartMoving);
UnitscanDataMainUI:SetScript("OnDragStop", UnitscanDataMainUI.StopMovingOrSizing);

local backgroundMainUI = UnitscanDataMainUI:CreateTexture(nil, "BACKGROUND");
backgroundMainUI:SetAllPoints(UnitscanDataMainUI);
backgroundMainUI:SetColorTexture(0.1, 0.1, 0.1, 0.8);

UnitscanDataMainUI.Label = UnitscanDataMainUI:CreateFontString("Label", nil, "GameFontNormalLargeOutline");
UnitscanDataMainUI.Label:SetJustifyH("LEFT");
UnitscanDataMainUI.Label:SetPoint("TOP", UnitscanDataMainUI, "TOP", 0, -9);
UnitscanDataMainUI.Label:SetText(L["UnitScan Hardcore Settings"]);

local customTexture = UnitscanDataMainUI:CreateTexture("CustomTexture", "ARTWORK");
customTexture:SetTexture("Interface\\AddOns\\unitscan\\unitscanhardcore");
customTexture:SetSize(32, 32);
customTexture:SetPoint("RIGHT", UnitscanDataMainUI.Label, "LEFT", -10, 0);

local bottomRightText = UnitscanDataMainUI:CreateFontString("BottomRightText", nil, "GameFontNormalOutline");
bottomRightText:SetJustifyH("RIGHT");
bottomRightText:SetPoint("BOTTOMRIGHT", UnitscanDataMainUI, "BOTTOMRIGHT", -10, 50);
bottomRightText:SetText("|cFFFF0000UnitScan Hardcore|r\nby |cff8788eeSlicc|r  EU-Stitches\n|cff3fc7ebMerlinx|r  EU-Soulseeker\nHold CTRL to move Alert");

local bottomRightText = UnitscanDataMainUI:CreateFontString("BottomRightText", nil, "GameFontNormalOutline");
bottomRightText:SetJustifyH("RIGHT");
bottomRightText:SetPoint("BOTTOMRIGHT", UnitscanDataMainUI, "BOTTOMRIGHT", -10, 110);
bottomRightText:SetText("|cFFFF0000HC:|r |cFF00FF001.15.9|r\n|cFFB8860B|cFFFFFF00Forever:|r |cFF00FF001.60.1|r\n|cFF0B7A3FTBC|r: |cFF00FF002.5.6|r");

local unitscanDataInfoButton = CreateFrame("Button", "unitscanDataInfoButton", UnitscanDataMainUI, "GameMenuButtonTemplate");
unitscanDataInfoButton:SetText("?");
unitscanDataInfoButton:SetSize(20, 20);
unitscanDataInfoButton:SetPoint("TOPRIGHT", UnitscanDataMainUI, "TOPRIGHT", -26, -5);

unitscanDataInfoButton:SetAlpha(0);

local ExitButtonMainUI = CreateFrame("Button", "UnitscanDataMainUIClose", UnitscanDataMainUI, "UIPanelCloseButton");
ExitButtonMainUI:SetPoint("TOPRIGHT", 1, 1);

local GridTitleContainer = CreateFrame("Frame", "TestAddonGridTitleContainer", UnitscanDataMainUI)
GridTitleContainer:SetPoint("TOP", UnitscanDataMainUI, "TOP", 0, -28);
GridTitleContainer.Label = GridTitleContainer:CreateFontString("Label", nil, "ErrorFont")
GridTitleContainer.Label:SetJustifyH("RIGHT")
GridTitleContainer.Label:SetPoint("LEFT", GridTitleContainer, "LEFT", 0, 0)

local TestAddonToggle1Button = CreateFrame("Button", "TestAddonToggle1Button", UnitscanDataMainUI);
TestAddonToggle1Button:SetSize(80, 32);
TestAddonToggle1Button:SetPoint("BOTTOMRIGHT", UnitscanDataMainUI, "BOTTOMRIGHT", -6, 8);
local texture1 = TestAddonToggle1Button:CreateTexture(nil, "BACKGROUND");
texture1:SetAllPoints(TestAddonToggle1Button);
texture1:SetColorTexture(0, 0, 0, 0.9);
TestAddonToggle1Button:SetScript("OnClick", function(self, arg1)
    toggleAllByClassification(1);
    local activeGrid = getActiveGrid();
    drawGrid(activeGrid);
    unitscan_updateAllFromGrid(activeGrid);
end);

local text1 = TestAddonToggle1Button:CreateFontString(nil, "OVERLAY", "GameFontNormalOutline");
text1:SetPoint("CENTER", TestAddonToggle1Button, "CENTER", 0, 0);
text1:SetText(L["Elite"]);

local TestAddonToggle2Button = CreateFrame("Button", "TestAddonToggle2Button", UnitscanDataMainUI);
TestAddonToggle2Button:SetSize(80, 32);
TestAddonToggle2Button:SetPoint("RIGHT", TestAddonToggle1Button, "LEFT", -6, 0);
local texture2 = TestAddonToggle2Button:CreateTexture(nil, "BACKGROUND");
texture2:SetAllPoints(TestAddonToggle2Button);
texture2:SetColorTexture(0, 0, 0, 0.9);
TestAddonToggle2Button:SetScript("OnClick", function(self, arg1)
    toggleAllByClassification(2);
    local activeGrid = getActiveGrid();
    drawGrid(activeGrid);
    unitscan_updateAllFromGrid(activeGrid);
end);

local text2 = TestAddonToggle2Button:CreateFontString(nil, "OVERLAY", "GameFontNormalOutline");
text2:SetPoint("CENTER", TestAddonToggle2Button, "CENTER", 0, 0);
text2:SetText(L["Rare Elite"]);

local TestAddonToggle4Button = CreateFrame("Button", "TestAddonToggle4Button", UnitscanDataMainUI);
TestAddonToggle4Button:SetSize(80, 32);
TestAddonToggle4Button:SetPoint("RIGHT", TestAddonToggle2Button, "LEFT", -6, 0);
local texture4 = TestAddonToggle4Button:CreateTexture(nil, "BACKGROUND");
texture4:SetAllPoints(TestAddonToggle4Button);
texture4:SetColorTexture(0, 0, 0, 0.9);
TestAddonToggle4Button:SetScript("OnClick", function(self, arg1)
    toggleAllByClassification(4);
    local activeGrid = getActiveGrid();
    drawGrid(activeGrid);
    unitscan_updateAllFromGrid(activeGrid);
end);

local text4 = TestAddonToggle4Button:CreateFontString(nil, "OVERLAY", "GameFontNormalOutline");
text4:SetPoint("CENTER", TestAddonToggle4Button, "CENTER", 0, 0);
text4:SetText(L["Rare"]);

local TestAddonToDefaultButton = CreateFrame("Button", "TestAddonToDefaultButton", UnitscanDataMainUI);
TestAddonToDefaultButton:SetSize(80, 32);
TestAddonToDefaultButton:SetPoint("RIGHT", TestAddonToggle4Button, "LEFT", -6, 0);
local textureDefault = TestAddonToDefaultButton:CreateTexture(nil, "BACKGROUND");
textureDefault:SetAllPoints(TestAddonToDefaultButton);
textureDefault:SetColorTexture(0, 0, 0, 0.9);
TestAddonToDefaultButton:SetScript("OnClick", function(self, arg1)
    toggleToDefault();
    local activeGrid = getActiveGrid();
    drawGrid(activeGrid);
    unitscan_updateAllFromGrid(activeGrid);
end);

local textDefault = TestAddonToDefaultButton:CreateFontString(nil, "OVERLAY", "GameFontNormalOutline");
textDefault:SetPoint("CENTER", TestAddonToDefaultButton, "CENTER", 0, 0);
textDefault:SetText(L["Default\n Settings"]);

local TestAddonToggle5Button = CreateFrame("Button", "TestAddonToggle5Button", UnitscanDataMainUI);
TestAddonToggle5Button:SetSize(80, 32);
TestAddonToggle5Button:SetPoint("RIGHT", TestAddonToDefaultButton, "LEFT", -6, 0);
local texture5 = TestAddonToggle5Button:CreateTexture(nil, "BACKGROUND");
texture5:SetAllPoints(TestAddonToggle5Button);
texture5:SetColorTexture(0, 0, 0, 0.9);
TestAddonToggle5Button:SetScript("OnClick", function(self, arg1)
    toggleAllByClassification(5);
    local activeGrid = getActiveGrid();
    drawGrid(activeGrid);
    unitscan_updateAllFromGrid(activeGrid);
end);

local text5 = TestAddonToggle5Button:CreateFontString(nil, "OVERLAY", "GameFontNormalOutline");
text5:SetPoint("CENTER", TestAddonToggle5Button, "CENTER", 0, 0);
text5:SetText(L["Alliance\n PvP NPCS"]);

local TestAddonToggle6Button = CreateFrame("Button", "TestAddonToggle6Button", UnitscanDataMainUI);
TestAddonToggle6Button:SetSize(80, 32);
TestAddonToggle6Button:SetPoint("RIGHT", TestAddonToggle5Button, "LEFT", -6, 0);
local texture6 = TestAddonToggle6Button:CreateTexture(nil, "BACKGROUND");
texture6:SetAllPoints(TestAddonToggle6Button);
texture6:SetColorTexture(0, 0, 0, 0.9);
TestAddonToggle6Button:SetScript("OnClick", function(self, arg1)
    toggleAllByClassification(6);
    local activeGrid = getActiveGrid();
    drawGrid(activeGrid);
    unitscan_updateAllFromGrid(activeGrid);
end);

local text6 = TestAddonToggle6Button:CreateFontString(nil, "OVERLAY", "GameFontNormalOutline");
text6:SetPoint("CENTER", TestAddonToggle6Button, "CENTER", 0, 0);
text6:SetText(L["Horde\n PvP NPCS"]);

local TestAddonToggle7Button = CreateFrame("Button", "TestAddonToggle7Button", UnitscanDataMainUI);
TestAddonToggle7Button:SetSize(80, 32);
TestAddonToggle7Button:SetPoint("RIGHT", TestAddonToggle6Button, "LEFT", -6, 0);
local texture7 = TestAddonToggle7Button:CreateTexture(nil, "BACKGROUND");
texture7:SetAllPoints(TestAddonToggle7Button);
texture7:SetColorTexture(0, 0, 0, 0.9);
TestAddonToggle7Button:SetScript("OnClick", function(self, arg1)
    toggleAllByClassification(7);
    local activeGrid = getActiveGrid();
    drawGrid(activeGrid);
    unitscan_updateAllFromGrid(activeGrid);
end);

local text7 = TestAddonToggle7Button:CreateFontString(nil, "OVERLAY", "GameFontNormalOutline");
text7:SetPoint("CENTER", TestAddonToggle7Button, "CENTER", 0, 0);
text7:SetText(L["Bank Alt\n Grief Alert"]);

showmobinfo = tonumber(showmobinfo) or 1

local TestAddonToggle8Button = CreateFrame("Button", "TestAddonToggle8Button", UnitscanDataMainUI);
TestAddonToggle8Button:SetSize(80, 32);
TestAddonToggle8Button:SetPoint("RIGHT", TestAddonToggle7Button, "LEFT", -6, 0);

local texture8 = TestAddonToggle8Button:CreateTexture(nil, "BACKGROUND");
texture8:SetAllPoints(TestAddonToggle8Button);

local function UpdateToggleButtonColor()
    showmobinfo = tonumber(showmobinfo) or 1
    if showmobinfo == 1 then
        texture8:SetColorTexture(0, 1, 0, 0.9);  -- g
    else
        texture8:SetColorTexture(1, 0, 0, 0.9);  -- r
    end
end

local f = CreateFrame("Frame")
f:RegisterEvent("ADDON_LOADED")
f:SetScript("OnEvent", function(self, event, arg1)
    if arg1 == "unitscanData" then  -- r2
        UpdateToggleButtonColor();
    end
end)

TestAddonToggle8Button:SetScript("OnClick", function(self, arg1)
    if tonumber(showmobinfo) == 1 then
        showmobinfo = 0;
        DEFAULT_CHAT_FRAME:AddMessage("Unitscan Hardcore Mob Info DISABLED", 1, 0, 0);  -- r
    else
        showmobinfo = 1;
        DEFAULT_CHAT_FRAME:AddMessage("Unitscan Hardcore Mob Info ENABLED", 0, 1, 0);   -- g
    end
    UpdateToggleButtonColor();
end);

local text8 = TestAddonToggle8Button:CreateFontString(nil, "OVERLAY", "GameFontNormalOutline");
text8:SetPoint("CENTER", TestAddonToggle8Button, "CENTER", 0, 0);
text8:SetText("Mob Info\nToggle");

for j=0,2 do
for i=1,25 do
	local index = i + j * 25;
	local MyCheckButton = CreateFrame("CheckButton", "MyCheckButton" .. index, UnitscanDataMainUI, "ChatConfigCheckButtonTemplate");
	MyCheckButton:SetSize(26, 26);
	MyCheckButton:SetPoint("TOPLEFT", UnitscanDataMainUI, "TOPLEFT", 10 + j * 240, -36 -22 * i);
	MyCheckButton:SetScript("OnClick", 
  		function()
			local CHECKBOX_GRID_STATE = getActiveGrid();
			if CHECKBOX_GRID_STATE[index]["active"] then
                if MyCheckButton:GetChecked() ~= CHECKBOX_GRID_STATE[index]["check"] then
			        CHECKBOX_GRID_STATE[index]["check"] = not CHECKBOX_GRID_STATE[index]["check"];
                end
			    unitscan_updateSingleCheckbox(CHECKBOX_GRID_STATE[index]);
            end
  		end
	);
	_G["MyCheckButton" .. i .. 'Text']:SetFont(_G["MyCheckButton" .. i .. 'Text']:GetFont(), 11)
end
end

UnitscanDataMainUI:RegisterEvent("ADDON_LOADED");
UnitscanDataMainUI:RegisterEvent("ZONE_CHANGED_NEW_AREA");

local function onAddonEvent(self, event, arg1, ...)
	if event == "ADDON_LOADED" and arg1 == "unitscanData" then
  		if _G["unitscanData_DB_VERSION"] == nil or _G["unitscanData_DB_VERSION"] ~= UNIT_SCAN_DATA["unitscanData_DB_VERSION"] then
  			local faction, _ = UnitFactionGroup("player");
  			if faction == "Alliance" then
  				loadDefaultData();
  			elseif faction == "Horde" then
  				loadhordedefault();
  			end
		end
        bothAddonsLoaded();
 	end
    if event == "ZONE_CHANGED" or event == "ZONE_CHANGED_INDOORS" or event == "ZONE_CHANGED_NEW_AREA" then
        onZoneChangeEvent(event);
 	end
end
UnitscanDataMainUI:SetScript("OnEvent", onAddonEvent);


local addon = LibStub("AceAddon-3.0"):NewAddon("Unitscan Hardcore")

local miniButton = LibStub("LibDataBroker-1.1"):NewDataObject("Unitscan Hardcore", {
	type = "data source",
	text = "Unitscan Hardcore",
	icon = "Interface\\AddOns\\unitscan\\unitscanhardcore.tga",
	OnClick = function(self, btn)
		if not UnitscanDataMainUI:IsShown() then
			UnitscanDataMainUI:Show()
		else
			UnitscanDataMainUI:Hide()
		end
	end,

	OnTooltipShow = function(tooltip)
		tooltip:AddLine("|cFFFF0000Unitscan Hardcore|r")
		tooltip:AddLine("|cFFADD8E6Click|r |cFFFFFF00to open Main Menu for advanced|r")
		tooltip:AddLine("|cFFFFFF00Settings & recent Hardcore Notifications|r")
	end,
})

UnitscanHardcoreMinimapIcon = LibStub("LibDBIcon-1.0", true)

---@diagnostic disable-next-line: duplicate-set-field
function addon:OnInitialize()
	---@diagnostic disable-next-line: inject-field
	self.db = LibStub("AceDB-3.0"):New("UnitscanHardcoreMinimapPosDB", {
		profile = {
			minimap = {
				hide = false,
			},
		},
	})

	---@diagnostic disable-next-line: param-type-mismatch
	UnitscanHardcoreMinimapIcon:Register("Unitscan Hardcore", miniButton, self.db.profile.minimap)
end

UnitscanHardcoreMinimapIcon:Show("Unitscan Hardcore")

local USHCheck = USHCheck or {}

USHCheck.isMainLoaded = true

_G["USHCheck"] = USHCheck