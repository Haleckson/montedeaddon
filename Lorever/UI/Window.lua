local _, ns = ...

-- Standalone lore window (/lorever). Also the fallback when the quest log
-- tab cannot be added.

local W = {}
ns.Window = W

local frame, panel

-- Where the reader left the window, or beside the middle of the screen.
function W.Place()
	if not frame then return end
	frame:ClearAllPoints()
	local pos = ns.db.windowPos
	if pos then
		frame:SetPoint("CENTER", UIParent, "BOTTOMLEFT", pos[1], pos[2])
	else
		frame:SetPoint("CENTER", 220, 0)
	end
end

function W.ResetPosition()
	ns.db.windowPos = nil
	W.Place()
end

local function build()
	frame = CreateFrame("Frame", "LoreverFrame", UIParent, "ButtonFrameTemplate")
	frame:SetSize(430, 640)
	W.Place()
	-- Drag the top of the window (or any empty part) to move it. The place is
	-- kept: the window opens again where the reader left it.
	frame:SetMovable(true)
	frame:EnableMouse(true)
	frame:RegisterForDrag("LeftButton")
	frame:SetScript("OnDragStart", frame.StartMoving)
	frame:SetScript("OnDragStop", function(self)
		self:StopMovingOrSizing()
		local x, y = self:GetCenter()
		if x and y then ns.db.windowPos = { x, y } end
		W.Place()
	end)
	frame:SetClampedToScreen(true)
	frame:SetFrameStrata("HIGH")
	if ButtonFrameTemplate_HidePortrait then ButtonFrameTemplate_HidePortrait(frame) end
	if frame.SetTitle then
		frame:SetTitle("Lorever")
	elseif frame.TitleText then
		frame.TitleText:SetText("Lorever")
	end
	-- Not added to Blizzard's UISpecialFrames (Esc to close): the add-on writes
	-- nothing into Blizzard's tables (COMPLIANCE.md, R3). The X button, the key
	-- binding and the minimap button close it.
	local host = CreateFrame("Frame", nil, frame)
	host:SetPoint("TOPLEFT", 8, -28)
	host:SetPoint("BOTTOMRIGHT", -8, 8)
	panel = ns.Panel.Create(host)
	frame:Hide()
end

function W.Toggle()
	if not frame then build() end
	frame:SetShown(not frame:IsShown())
end

function W.IsShown() return frame ~= nil and frame:IsShown() end
function W.Hide() if frame then frame:Hide() end end

function W.Show(entryID)
	if not frame then build() end
	frame:Show()
	if entryID then panel:Open(entryID) else panel:Refresh() end
end
