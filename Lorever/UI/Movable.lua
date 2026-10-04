local _, ns = ...

-- Frames of ours that the reader may move: Shift-drag, and the place is kept
-- (LoreverDB.positions[key] = { x, y, corner }: the frame's centre, measured
-- from the parent's corner nearest to it). The nearest corner keeps a button
-- beside the things around it when the parent changes size, as the world map
-- does between full screen and windowed. Old places without a corner count
-- from the bottom left.
-- /lorever resetpos puts every one back. Only our own frames are moved; the
-- game's frames they sit beside are never touched (COMPLIANCE.md, R3).

local Movable = {}
ns.Movable = Movable

local frames = {} -- [key] = { frame = , parent = , default = function(frame) }
local moving = {} -- [frame] = true while the reader drags it

local function positions()
	ns.db.positions = ns.db.positions or {}
	return ns.db.positions
end

function Movable.Place(key)
	local m = frames[key]
	if not m then return end
	local pos = ns.db and positions()[key]
	m.frame:ClearAllPoints()
	if pos then
		m.frame:SetPoint("CENTER", m.parent, pos[3] or "BOTTOMLEFT", pos[1], pos[2])
	else
		m.default(m.frame)
	end
end

-- The frame's centre, measured from its parent's nearest corner.
local function offset(frame, parent)
	local x, y = frame:GetCenter()
	local left, bottom = parent:GetLeft(), parent:GetBottom()
	local right, top = parent:GetRight(), parent:GetTop()
	if not (x and y and left and bottom) then return nil end
	local fs, ps = frame:GetEffectiveScale() or 1, parent:GetEffectiveScale() or 1
	if type(fs) ~= "number" or type(ps) ~= "number" or ps == 0 then fs, ps = 1, 1 end
	x, y = x * fs, y * fs
	left, bottom = left * ps, bottom * ps
	right, top = (right or left) * ps, (top or bottom) * ps
	local fromRight, fromTop = x - right, y - top
	local useRight = right and math.abs(fromRight) < math.abs(x - left)
	local useTop = top and math.abs(fromTop) < math.abs(y - bottom)
	local corner = (useTop and "TOP" or "BOTTOM") .. (useRight and "RIGHT" or "LEFT")
	return (useRight and fromRight or x - left) / fs, (useTop and fromTop or y - bottom) / fs, corner
end

-- Makes `frame` movable with Shift-drag. `default(frame)` sets its usual place.
function Movable.Add(key, frame, parent, default)
	frames[key] = { frame = frame, parent = parent or UIParent, default = default }
	frame:SetMovable(true)
	frame:SetClampedToScreen(true)
	frame:RegisterForDrag("LeftButton")
	frame:SetScript("OnDragStart", function(self)
		if IsShiftKeyDown and IsShiftKeyDown() then
			moving[self] = true
			self:StartMoving()
		end
	end)
	frame:SetScript("OnDragStop", function(self)
		if not moving[self] then return end
		moving[self] = nil
		self:StopMovingOrSizing()
		local x, y, corner = offset(self, frames[key].parent)
		if x then positions()[key] = { x, y, corner } end
		Movable.Place(key)
	end)
	Movable.Place(key)
end

function Movable.IsMoving(frame) return moving[frame] == true end

function Movable.ResetAll()
	ns.db.positions = {}
	for key in pairs(frames) do Movable.Place(key) end
end

function Movable.Tip()
	return ns.T("Shift-drag: move this button")
end
