local _, ns = ...

-- Two quick ways to a figure's page (spec: specs/2026-10-02-botao-do-alvo.md):
--
--   1. a small book button by the target frame, shown while the target is a
--      figure with a page; Shift-drag moves it (for other unit frames);
--   2. a right-click on a friendly figure that opens no window of its own
--      (no quest, shop or talk) opens its page.
--
-- Only frames of our own and hooks (COMPLIANCE.md, R3): nothing is written into
-- Blizzard's target frame, and nothing is done for the player. The page opens
-- only on the player's own click.

local FB = {}
ns.FigureButton = FB

local Theme, Lore, U = ns.Theme, ns.Lore, ns.U

-- The page of an NPC: the first figure that carries its id.
function FB.FigureOf(npcID)
	if not npcID then return nil end
	return Lore.FiguresForNpc(npcID)[1]
end

-- Opens the page of a figure, in the window that the reader can move.
function FB.Open(npcID)
	local figure = FB.FigureOf(npcID)
	if not figure then return false end
	ns.Triggers.Meet(npcID) -- the reader faced this figure: the page is discovered
	ns.Window.Show(figure.id)
	return true
end

-- The button by the target frame -----------------------------------------------------------

local button
local shown -- the npc id the button stands for
local dragging = false

local function place()
	button:ClearAllPoints()
	local pos = ns.db.targetButtonPos
	if pos then
		button:SetPoint("CENTER", UIParent, "BOTTOMLEFT", pos[1], pos[2])
	elseif TargetFrame then
		button:SetPoint("LEFT", TargetFrame, "RIGHT", -18, 22)
	else
		button:SetPoint("CENTER", UIParent, "CENTER", 0, -120)
	end
end

local function tooltip(self)
	local figure = FB.FigureOf(shown)
	GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
	GameTooltip:AddLine("Lorever", unpack(Theme.TURQUOISE))
	if figure then GameTooltip:AddLine(figure.title, 1, 1, 1) end
	GameTooltip:AddLine(ns.T("Click: open the lore page"), 0.8, 0.8, 0.8)
	GameTooltip:AddLine(ns.T("Shift-drag: move this button"), 0.8, 0.8, 0.8)
	GameTooltip:Show()
end

local function create()
	button = CreateFrame("Button", "LoreverTargetButton", UIParent)
	button:SetSize(28, 28)
	button:SetFrameStrata("MEDIUM")
	button:SetFrameLevel(20)
	button:SetClampedToScreen(true)
	button:SetMovable(true)
	button:RegisterForClicks("LeftButtonUp")
	button:RegisterForDrag("LeftButton")
	local icon = button:CreateTexture(nil, "BACKGROUND")
	icon:SetSize(18, 18)
	icon:SetPoint("CENTER", 0, 1)
	icon:SetTexture(Theme.ICON)
	local border = button:CreateTexture(nil, "OVERLAY")
	border:SetSize(48, 48)
	border:SetPoint("TOPLEFT")
	border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
	button:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
	button:SetScript("OnClick", function() FB.Open(shown) end)
	button:SetScript("OnEnter", tooltip)
	button:SetScript("OnLeave", GameTooltip_Hide)
	button:SetScript("OnDragStart", function(self)
		if IsShiftKeyDown and IsShiftKeyDown() then
			dragging = true
			self:StartMoving()
		end
	end)
	button:SetScript("OnDragStop", function(self)
		if not dragging then return end
		dragging = false
		self:StopMovingOrSizing()
		local x, y = self:GetCenter()
		if x and y then ns.db.targetButtonPos = { x, y } end
		place()
	end)
	button:Hide()
	FB.button = button
end

function FB.Update()
	local npcID = ns.db.settings.targetButton and U.UnitNpcID("target") or nil
	shown = FB.FigureOf(npcID) and npcID or nil
	if not shown then
		if button then button:Hide() end
		return
	end
	if not button then create() end
	place()
	button:Show()
end

-- /lorever button: the button goes back beside the target frame.
function FB.ResetPosition()
	ns.db.targetButtonPos = nil
	if button then place() end
end

ns.On("PLAYER_TARGET_CHANGED", FB.Update)
ns.Listen("FL_LOGIN", FB.Update)
ns.Listen("FL_SETTINGS_CHANGED", function(_, key) if key == "targetButton" then FB.Update() end end)

-- Right-click on a figure in the world ------------------------------------------------------
--
-- The game tells an add-on nothing about a click on the world, so the world
-- frame's own mouse scripts are hooked (read only). A right press and release
-- on the same spot is a click; a press that moves is the camera turning.

FB.CLICK_TIME = 0.4   -- seconds between press and release
FB.CLICK_MOVE = 6     -- pixels the cursor may move
FB.WAIT = 0.35        -- seconds to see whether the figure opens a window of its own

local press -- { npc, x, y, at }
local windowAt = -100 -- when a quest, shop or talk window last opened

local function down(_, mouseButton)
	press = nil
	if mouseButton ~= "RightButton" or not ns.db or not ns.db.settings.rightClickLore then return end
	local npcID = U.UnitNpcID("mouseover")
	if not FB.FigureOf(npcID) then return end
	if UnitCanAttack and UnitCanAttack("player", "mouseover") then return end -- a right-click there is an attack
	local x, y = GetCursorPosition()
	press = { npc = npcID, x = x, y = y, at = GetTime() }
end

local function up(_, mouseButton)
	local p = press
	press = nil
	if not p or mouseButton ~= "RightButton" then return end
	local x, y = GetCursorPosition()
	if GetTime() - p.at > FB.CLICK_TIME or math.abs(x - p.x) > FB.CLICK_MOVE or math.abs(y - p.y) > FB.CLICK_MOVE then return end
	if U.InCombat() then return end
	local clickedAt = GetTime()
	C_Timer.After(FB.WAIT, function()
		-- The figure opened a quest, a shop or a talk: that window comes first.
		if windowAt >= clickedAt - 0.05 or U.InCombat() then return end
		if not ns.db.settings.rightClickLore then return end
		FB.Open(p.npc)
	end)
end
FB.OnWorldMouseDown, FB.OnWorldMouseUp = down, up

for _, event in ipairs({
	"GOSSIP_SHOW", "QUEST_GREETING", "QUEST_DETAIL", "QUEST_PROGRESS", "QUEST_COMPLETE",
	"MERCHANT_SHOW", "TRAINER_SHOW", "TAXIMAP_OPENED", "BANKFRAME_OPENED",
	"PLAYER_INTERACTION_MANAGER_FRAME_SHOW",
}) do
	ns.On(event, function() windowAt = GetTime() end)
end

ns.Listen("FL_LOGIN", function()
	if not WorldFrame or not WorldFrame.HookScript then return end
	WorldFrame:HookScript("OnMouseDown", down)
	WorldFrame:HookScript("OnMouseUp", up)
end)
