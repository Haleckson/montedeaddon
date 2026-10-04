local _, ns = ...

-- Ways in: key bindings (Bindings.xml), a minimap button and the Addon
-- Compartment (the addons button by the minimap).

local Launcher = {}
ns.Launcher = Launcher

local Theme = ns.Theme

-- Key bindings (Options > Keybindings > AddOns > Lorever).
BINDING_HEADER_LOREVER = "Lorever"
BINDING_NAME_LOREVER_TOGGLE = "Open or close the book of lore"
BINDING_NAME_LOREVER_NARRATE = "Narrator: play or pause"
BINDING_NAME_LOREVER_NARRATE_HERE = "Narrator: read the land you stand in"

-- The language is known only once the saved settings are read.
ns.Listen("FL_DB_READY", function()
	BINDING_NAME_LOREVER_TOGGLE = ns.T("Open or close the book of lore")
	BINDING_NAME_LOREVER_NARRATE = ns.T("Narrator: play or pause")
	BINDING_NAME_LOREVER_NARRATE_HERE = ns.T("Narrator: read the land you stand in")
end)

function Lorever_Toggle()
	if ns.QuestLogTab.IsOpen() then
		ns.QuestLogTab.Close()
	elseif ns.Window.IsShown() then
		ns.Window.Hide()
	else
		ns.QuestLogTab.Open()
	end
end

function Lorever_NarrateToggle()
	if not ns.Voice.Toggle() then
		if not ns.Voice.PlayHere() then ns.Print(ns.T("Nothing to read here yet.")) end
	end
end

function Lorever_NarrateHere()
	if not ns.Voice.PlayHere() then ns.Print(ns.T("No lore of this place has yet been written.")) end
end

local function tooltip(owner)
	GameTooltip:SetOwner(owner, "ANCHOR_LEFT")
	GameTooltip:AddLine("Lorever", unpack(Theme.TURQUOISE))
	local P = ns.Progress
	GameTooltip:AddLine(string.format(ns.T("Lore level %d  \194\183  Literature level %d"), P.Level("lore"), P.Level("books")), 1, 1, 1)
	GameTooltip:AddLine(ns.T("Click: open the book of lore"), 0.8, 0.8, 0.8)
	GameTooltip:AddLine(ns.T("Right-click: narrator, play or pause"), 0.8, 0.8, 0.8)
	GameTooltip:AddLine(ns.T("Drag: move this button"), 0.8, 0.8, 0.8)
	GameTooltip:Show()
end

-- Addon Compartment (the TOC names these functions).
function Lorever_OnAddonCompartmentClick(_, button)
	if button == "RightButton" then Lorever_NarrateToggle() else Lorever_Toggle() end
end
function Lorever_OnAddonCompartmentEnter(_, owner) tooltip(owner) end
function Lorever_OnAddonCompartmentLeave() GameTooltip:Hide() end

-- Minimap button -----------------------------------------------------------------------

local button

local function place()
	local angle = math.rad(ns.db.minimapAngle or 200)
	local radius = (Minimap:GetWidth() / 2) + 6
	button:ClearAllPoints()
	button:SetPoint("CENTER", Minimap, "CENTER", math.cos(angle) * radius, math.sin(angle) * radius)
end

local function create()
	button = CreateFrame("Button", "LoreverMinimapButton", Minimap)
	button:SetSize(31, 31)
	button:SetFrameStrata("MEDIUM")
	button:SetFrameLevel(8)
	button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	button:RegisterForDrag("LeftButton")
	local icon = button:CreateTexture(nil, "BACKGROUND")
	icon:SetSize(20, 20)
	icon:SetPoint("CENTER", 0, 1)
	icon:SetTexture(Theme.ICON)
	local border = button:CreateTexture(nil, "OVERLAY")
	border:SetSize(53, 53)
	border:SetPoint("TOPLEFT")
	border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
	button:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
	button:SetScript("OnClick", function(_, b)
		if b == "RightButton" then Lorever_NarrateToggle() else Lorever_Toggle() end
	end)
	button:SetScript("OnEnter", tooltip)
	button:SetScript("OnLeave", GameTooltip_Hide)
	button:SetScript("OnDragStart", function(self)
		-- R3: runs every frame only while the player drags the button, then stops.
		self:SetScript("OnUpdate", function()
			local mx, my = Minimap:GetCenter()
			local scale = Minimap:GetEffectiveScale()
			local cx, cy = GetCursorPosition()
			ns.db.minimapAngle = math.deg(math.atan2(cy / scale - my, cx / scale - mx))
			place()
		end)
	end)
	button:SetScript("OnDragStop", function(self) self:SetScript("OnUpdate", nil) end)
	Launcher.button = button
end

function Launcher.Update()
	if not button then return end
	if ns.db.settings.minimapButton then
		place()
		button:Show()
	else
		button:Hide()
	end
end

ns.Listen("FL_LOGIN", function()
	if not Minimap then return end
	create()
	Launcher.Update()
end)
ns.Listen("FL_SETTINGS_CHANGED", function(_, key) if key == "minimapButton" then Launcher.Update() end end)
