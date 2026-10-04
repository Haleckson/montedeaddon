local _, ns = ...

-- The Lore tracker: a short list on the right of the screen, like the quest
-- tracker, of the figures and writings the reader is looking for.
-- It sits right under Questie's tracker when Questie is there, else under the
-- game's objective tracker. It never touches Questie's own frames.
--
--   left click   open the page
--   right click  point the arrow at it
--   shift click  stop tracking it

local Tracker = {}
ns.Tracker = Tracker

local Theme, Track = ns.Theme, ns.Track
local C = Theme.Color
local ROWS, ROW_H, WIDTH = 8, 16, 230
local BOOK_ICON = "Interface\\Icons\\INV_Misc_Book_11"

local frame, header, rows

local function distanceText(d)
	if not d then return nil end
	if d < 1000 then return string.format(ns.T("%d yd"), math.floor(d / 5 + 0.5) * 5) end
	return string.format(ns.T("%.1f k yd"), d / 1000)
end

local function createRow(i)
	local row = CreateFrame("Button", nil, frame)
	row:SetSize(WIDTH, ROW_H)
	row:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -2 - (i - 1) * ROW_H)
	row:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	row.icon = row:CreateTexture(nil, "ARTWORK")
	row.icon:SetSize(12, 12)
	row.icon:SetPoint("LEFT", 2, 0)
	row.label = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	row.label:SetPoint("LEFT", row.icon, "RIGHT", 4, 0)
	row.label:SetPoint("RIGHT", -60, 0)
	row.label:SetJustifyH("LEFT")
	row.right = row:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
	row.right:SetPoint("RIGHT", -2, 0)
	row.right:SetJustifyH("RIGHT")
	row:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
	row:SetScript("OnClick", function(self, button)
		local entry = self.item and self.item.entry
		if not entry then return end
		if IsShiftKeyDown and IsShiftKeyDown() then
			if Track.IsTracked(entry.id) then Track.Toggle(entry.id) end
		elseif button == "RightButton" then
			Track.SetWaypoint(entry)
		else
			ns.QuestLogTab.Open(entry.id)
		end
	end)
	row:SetScript("OnEnter", function(self)
		local entry = self.item and self.item.entry
		if not entry then return end
		GameTooltip:SetOwner(self, "ANCHOR_LEFT")
		GameTooltip:AddLine(entry.title, 1, 1, 1)
		if entry.kind == "book" then
			GameTooltip:AddLine(entry.found or "", 1, 0.82, 0, true)
		else
			GameTooltip:AddLine(Theme.Plain(ns.Lore.Hint(entry)), 1, 0.82, 0, true)
		end
		GameTooltip:AddLine(ns.T("Click: read  \194\183  Right-click: waypoint") .. (Track.IsTracked(entry.id) and "  \194\183  " .. ns.T("Shift-click: stop tracking") or ""), unpack(Theme.TURQUOISE))
		GameTooltip:Show()
	end)
	row:SetScript("OnLeave", GameTooltip_Hide)
	return row
end

local hooked

-- Under Questie's tracker, else under the game's, else below the minimap.
local function anchor()
	frame:ClearAllPoints()
	local questie = _G.Questie_BaseFrame
	-- Questie may build its tracker after us: follow it once it exists.
	if questie and not hooked and questie.HookScript then
		hooked = true
		questie:HookScript("OnSizeChanged", function() Tracker.Update() end)
		questie:HookScript("OnShow", function() Tracker.Update() end)
		questie:HookScript("OnHide", function() Tracker.Update() end)
	end
	if questie and questie.IsShown and questie:IsShown() then
		frame:SetPoint("TOPLEFT", questie, "BOTTOMLEFT", 4, -6)
		return
	end
	local blizzard = _G.ObjectiveTrackerFrame
	if blizzard and blizzard.IsShown and blizzard:IsShown() then
		frame:SetPoint("TOPLEFT", blizzard, "BOTTOMLEFT", 4, -6)
		return
	end
	frame:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", -80, -260)
end

function Tracker.Update()
	if not frame then return end
	local s = ns.db.settings
	local list = s.tracker and Track.List() or {}
	if #list == 0 then
		frame:Hide()
		return
	end
	anchor()
	local tracked = 0
	for _, item in ipairs(list) do if not item.auto then tracked = tracked + 1 end end
	header.text:SetText(C(Theme.TURQUOISE_HEX, ns.T("Lore")) .. "  " .. C("ffaaaaaa", tostring(#list)))
	frame.collapsed = frame.collapsed or false
	for i = 1, ROWS do
		local row = rows[i]
		local item = list[i]
		if item and not frame.collapsed then
			row.item = item
			local entry = item.entry
			if entry.kind == "book" then
				row.icon:SetTexture(BOOK_ICON)
				row.icon:SetVertexColor(1, 1, 1)
			else
				Theme.Marker(row.icon)
			end
			local label = entry.title
			if item.auto then label = C("ffbbbbbb", label) end
			if Track.waypoint == entry.id then label = "|TInterface\\Minimap\\Minimap-Waypoint-MapPin-Tracked:12:12:0:0|t " .. label end
			row.label:SetText(label)
			row.right:SetText(distanceText(item.distance) or (item.spot and "" or C("ff888888", ns.T("far"))))
			row:Show()
		else
			row.item = nil
			row:Hide()
		end
	end
	local shown = frame.collapsed and 0 or math.min(#list, ROWS)
	frame:SetHeight(20 + shown * ROW_H)
	frame:Show()
end

local function create()
	frame = CreateFrame("Frame", "LoreverTrackerFrame", UIParent)
	frame:SetSize(WIDTH, 20)
	frame:SetFrameStrata("LOW")
	header = CreateFrame("Button", nil, frame)
	header:SetSize(WIDTH, 18)
	header:SetPoint("TOPLEFT")
	header.text = header:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	header.text:SetPoint("LEFT", 2, 0)
	header:SetScript("OnClick", function()
		frame.collapsed = not frame.collapsed
		Tracker.Update()
	end)
	header:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_LEFT")
		GameTooltip:AddLine(ns.T("Lore to find"), 1, 1, 1)
		GameTooltip:AddLine(ns.T("Track pages from the book of lore: each one has a Track button."), 1, 0.82, 0, true)
		GameTooltip:AddLine(ns.T("Click to fold or unfold."), unpack(Theme.TURQUOISE))
		GameTooltip:Show()
	end)
	header:SetScript("OnLeave", GameTooltip_Hide)
	rows = {}
	for i = 1, ROWS do rows[i] = createRow(i) end
	-- Distances change as the reader walks.
	local elapsed = 0
	frame:SetScript("OnUpdate", function(_, dt)
		elapsed = elapsed + dt
		if elapsed >= 1 then
			elapsed = 0
			Tracker.Update()
		end
	end)
	Tracker.frame = frame
end

ns.Listen("FL_LOGIN", function()
	create()
	-- Questie builds its tracker after login; place ours again once it is ready.
	local API = _G.Questie and _G.Questie.API
	if API and API.RegisterOnReady then pcall(API.RegisterOnReady, function() C_Timer.After(1, Tracker.Update) end) end
	Tracker.Update()
end)
ns.Listen("FL_TRACK_CHANGED", function() Tracker.Update() end)
ns.Listen("FL_ZONE", function() Tracker.Update() end)
ns.Listen("FL_SETTINGS_CHANGED", function() Tracker.Update() end)
