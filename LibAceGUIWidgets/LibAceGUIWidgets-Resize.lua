-- LibAceGUIWidgets — Resize framework satellite.
--
-- `lib:MakeResizable` / `lib:GetResizeHandle` / `lib:ApplyResizeBounds` and the ResizeHandle methods.
-- Moved here from `LibAceGUIWidgets-1.0.lua` on 2026-09-17, unchanged; the git history of the
-- framework itself is in the core file up to that commit.
--
-- WHY IT IS A SATELLITE AT ALL. This repo's `CLAUDE.md` prescribes one file per component. The
-- framework went into the core file on 2026-08-21 for one reason only: the test harness loads a
-- library from a hand-kept file list (`Tests/wowapi/env/libs.lua`), so a satellite it did not list
-- was invisible to every spec -- the library would load without `MakeResizable` and every ClearFrame
-- constructor would raise. Harness contract 2 (2026-09-08) made a new TOC file VISIBLE (verify-libs
-- names it) but still not loaded, and harness inbox thread 0045274d65c3 added the manifest line on
-- 2026-09-17 (`2aac908`). That is what unblocked this move.
--
-- LOAD ORDER, read from the loader rather than assumed. Both the TOC and the harness manifest list
-- this file immediately AFTER `LibAceGUIWidgets-1.0.lua`, and within one `libs.load` the files load
-- in the listed order. So:
--   * this file may use anything the core defines at file scope -- `lib:ScaledSize` and
--     `lib:OnScaleChanged` are both called below, and both exist by the time this runs;
--   * the core must NOT call into this file at ITS file scope, and does not. `ClearFrame` and
--     `GroupFrame` reach `lib:MakeResizable` and `lib.ResizeOnSizeChanged` from their CONSTRUCTORS,
--     which run when a consumer builds a widget, long after both files have loaded.
--
-- `lib.ResizeOnSizeChanged` is the one seam this split needed. It was a file-local
-- (`Resize_Frame_OnSizeChanged`) that the core's ClearFrame and GroupFrame constructors re-hook after
-- `AceGUI:RegisterAsContainer` replaces their OnSizeChanged script -- see the comment at those call
-- sites. A local cannot cross a file boundary, so it is published on the library table instead.

local lib = LibStub and LibStub("LibAceGUIWidgets-1.0", true)
if not lib then return end

local RESIZE_GRIP_SIZE = 25   -- ClearFrame's strip width; AceGUI's Frame uses the same 25
local RESIZE_GRIP_TEX  = 14   -- the diagonal-lines texture inset into the SE corner

-- Which sizer strips exist, and the FramePoint each hands to StartSizing. Keyed by the token a
-- caller writes in `grips`.
local RESIZE_GRIPS = { SE = "BOTTOMRIGHT", S = "BOTTOM", E = "RIGHT" }

-- Accept either a raw frame or an AceGUI widget, and REFUSE anything that is neither. The
-- `x.frame or x` idiom used in the core file is fine for a setter that no-ops, but this one attaches
-- scripts and child frames, so handing it a plain table has to fail rather than half-build.
local function resizeTargetOf(x)
	if type(x) ~= "table" then return nil end
	if x.SetResizable then return x end
	local f = x.frame
	if type(f) == "table" and f.SetResizable then return f end
	return nil
end

-- Modern SetResizeBounds carries both bounds; the Classic-era spelling needs two calls, and
-- SetMaxResize is only touched when a maximum was actually asked for (setting one to 0 is not the
-- same as leaving it unset).
--
-- All four are SCALE-1.0 values and are multiplied (MINOR 29), like ApplyMinResize in the core file.
-- The handle keeps the unscaled numbers (`handle.minW` ...) and re-applies through here on a change.
function lib:ApplyResizeBounds(frameOrWidget, minW, minH, maxW, maxH)
	local raw = resizeTargetOf(frameOrWidget) or (frameOrWidget and frameOrWidget.frame) or frameOrWidget
	if type(raw) ~= "table" then return end
	minW, minH = self:ScaledSize(minW or 0), self:ScaledSize(minH or 0)
	if maxW then maxW = self:ScaledSize(maxW) end
	if maxH then maxH = self:ScaledSize(maxH) end
	if raw.SetResizeBounds then
		raw:SetResizeBounds(minW, minH, maxW, maxH)
	else
		if raw.SetMinResize then raw:SetMinResize(minW, minH) end
		if maxW and maxH and raw.SetMaxResize then raw:SetMaxResize(maxW, maxH) end
	end
end

local ResizeHandle = {}
ResizeHandle.__index = ResizeHandle

-- A consumer callback that raises must not leave the frame latched to the mouse, so every one goes
-- through pcall and the error is handed to the client's own handler rather than swallowed.
function ResizeHandle:_fire(callback)
	if type(callback) ~= "function" or self._firing then return end
	local f = self.frame
	self._firing = true
	local ok, err = pcall(callback, f, f:GetWidth() or 0, f:GetHeight() or 0, self)
	self._firing = false
	if not ok then
		local handler = geterrorhandler and geterrorhandler()
		if handler then handler(err) end
	end
end

-- Fire onResize if the size actually moved since the last flush. Returns whether it did.
function ResizeHandle:_flush()
	local f = self.frame
	local w, h = f:GetWidth() or 0, f:GetHeight() or 0
	if w == self._lastW and h == self._lastH then return false end
	self._lastW, self._lastH = w, h
	self:_fire(self.onResize)
	return true
end

function ResizeHandle:IsResizing() return self._resizing == true end

-- The bounds are kept UNSCALED on the handle and scaled on the way to the frame, so a scale change
-- re-applies the same numbers and gets a different floor.
function ResizeHandle:SetBounds(minW, minH, maxW, maxH)
	self.minW, self.minH, self.maxW, self.maxH = minW, minH, maxW, maxH
	lib:ApplyResizeBounds(self.frame, minW, minH, maxW, maxH)
	return self
end

-- On a scale change: re-apply the bounds at the new scale, and raise the window to the new floor
-- if it now sits under it. The client's bounds only constrain a DRAG; they never grow a frame, and
-- a window narrower than its own minimum is exactly the state PersistWindow's floor exists to
-- prevent. Nothing shrinks on a scale-down: the user sized the window and it stays sized.
local function Resize_OnScaleChanged(_, _, handle)
	handle:SetBounds(handle.minW, handle.minH, handle.maxW, handle.maxH)
	local f = handle.frame
	local minW, minH = lib:ScaledSize(handle.minW or 0), lib:ScaledSize(handle.minH or 0)
	if (f:GetWidth()  or 0) < minW then f:SetWidth(minW)  end
	if (f:GetHeight() or 0) < minH then f:SetHeight(minH) end
end

function ResizeHandle:SetStatusTable(status, restore)
	self.status = status
	if status and restore ~= false then self:ApplyStatus() end
	return self
end

-- Restore size (and position, if both coordinates were saved) from the status table. The
-- TOP/BOTTOM + LEFT/LEFT anchor pair is AceGUI's, kept so a table written by a ClearFrame and a
-- table written here are interchangeable.
function ResizeHandle:ApplyStatus()
	local s, f = self.status, self.frame
	if type(s) ~= "table" then return self end
	if tonumber(s.width) then f:SetWidth(tonumber(s.width)) end
	if tonumber(s.height) then f:SetHeight(tonumber(s.height)) end
	if tonumber(s.left) and tonumber(s.top) then
		f:ClearAllPoints()
		f:SetPoint("TOP", UIParent, "BOTTOM", 0, tonumber(s.top))
		f:SetPoint("LEFT", UIParent, "LEFT", tonumber(s.left), 0)
	end
	self._lastW, self._lastH = f:GetWidth() or 0, f:GetHeight() or 0
	return self
end

-- GetLeft/GetTop answer nil for a frame with no resolved rect, so neither is written blindly -- a
-- nil there would wipe a good saved position.
function ResizeHandle:SaveStatus()
	local s, f = self.status, self.frame
	if type(s) ~= "table" then return self end
	s.width, s.height = f:GetWidth(), f:GetHeight()
	local left, top = f:GetLeft(), f:GetTop()
	if left then s.left = left end
	if top then s.top = top end
	return self
end

-- Turn the grips off without discarding the handle (a window that is only resizable while unlocked).
function ResizeHandle:SetEnabled(enabled)
	enabled = enabled ~= false
	self.enabled = enabled
	for name in pairs(RESIZE_GRIPS) do
		local grip = self.grips[name]
		if grip then
			if enabled and self._wanted[name] then grip:Show() else grip:Hide() end
		end
	end
	if not enabled then self:_stop() end
	return self
end

function ResizeHandle:_start(point)
	local f = self.frame
	if not self.enabled or self._resizing then return end
	if f.IsResizable and not f:IsResizable() then return end
	f:StartSizing(point)
	self._resizing, self._point = true, point
	self._lastW, self._lastH = f:GetWidth() or 0, f:GetHeight() or 0
	self.driver:Show()
	local AceGUI = LibStub and LibStub("AceGUI-3.0", true)
	if AceGUI and AceGUI.ClearFocus then AceGUI:ClearFocus() end
	self:_fire(self.onResizeStart)
end

function ResizeHandle:_stop()
	if not self._resizing then return end
	self._resizing, self._point = false, nil
	self.frame:StopMovingOrSizing()
	self:_flush()
	self:SaveStatus()
	self.driver:Hide()
	self:_fire(self.onResizeStop)
end

-- Drop the grips and the driver. The handle stays attached to the frame so a later MakeResizable
-- rebuilds rather than stacking a second set.
function ResizeHandle:Destroy()
	self:_stop()
	for name, grip in pairs(self.grips) do
		grip:Hide()
		grip:SetScript("OnMouseDown", nil)
		grip:SetScript("OnMouseUp", nil)
		self.grips[name] = nil
	end
	self._wanted, self._gripSpec = {}, nil
	self.driver:Hide()
	self.driver:SetScript("OnUpdate", nil)
	self.onResize, self.onResizeStart, self.onResizeStop = nil, nil, nil
	lib:OnScaleChanged(self, nil)   -- a destroyed handle must not keep re-applying bounds on a scale change
	return self
end

local function Resize_Driver_OnUpdate(driver)
	local handle = driver._resizeHandle
	if not handle then return end
	handle:_flush()
	-- A programmatic resize wakes the driver for exactly one tick; a drag keeps it awake.
	if not handle._resizing then driver:Hide() end
end

-- A resize the framework did not start (the consumer calling SetWidth, a parent re-laying out)
-- still owes onResize. Waking the driver rather than firing here is what keeps the "at most once
-- per draw" promise when SetWidth and SetHeight arrive as two separate changes.
--
-- PUBLISHED ON `lib` rather than kept local, because the core file's ClearFrame and GroupFrame
-- constructors re-hook it after `AceGUI:RegisterAsContainer` replaces their OnSizeChanged script.
-- It is not consumer API: `MakeResizable` installs it for you.
local function Resize_Frame_OnSizeChanged(frame)
	local handle = frame._resizeHandle
	if handle and not handle._firing then handle.driver:Show() end
end
lib.ResizeOnSizeChanged = Resize_Frame_OnSizeChanged

-- Releasing the mouse outside the grip does not always give it its OnMouseUp back, and a hidden
-- window that is still latched keeps resizing itself the next time the cursor moves.
local function Resize_Frame_OnHide(frame)
	local handle = frame._resizeHandle
	if handle then handle:_stop() end
end

local function Resize_Grip_OnMouseDown(grip)
	local handle = grip._resizeHandle
	if handle then handle:_start(grip._resizePoint) end
end

local function Resize_Grip_OnMouseUp(grip)
	local handle = grip._resizeHandle
	if handle then handle:_stop() end
end

-- Geometry copied from ClearFrame verbatim rather than re-derived: the SE corner is a `size` square,
-- S is a full-width strip stopping `size` short of it, E is a full-height strip stopping `size` above
-- it. Grips are left at their default frame level (parent + 1), which is what ClearFrame's
-- `liftAboveSizers(+5)` for its bottom-row controls is written against.
local function buildResizeGrip(handle, name, size, showGrip)
	local frame = handle.frame
	local grip = CreateFrame("Frame", nil, frame)
	grip:EnableMouse(true)
	if name == "SE" then
		grip:SetPoint("BOTTOMRIGHT")
		grip:SetWidth(size)
		grip:SetHeight(size)
		if showGrip then
			local tex = grip:CreateTexture(nil, "BACKGROUND")
			tex:SetWidth(RESIZE_GRIP_TEX)
			tex:SetHeight(RESIZE_GRIP_TEX)
			tex:SetPoint("BOTTOMRIGHT", -8, 8)
			tex:SetTexture("Interface\\Tooltips\\UI-Tooltip-Border")
			local x = 0.1 * RESIZE_GRIP_TEX / 17
			tex:SetTexCoord(0.05 - x, 0.5, 0.05, 0.5 + x, 0.05, 0.5 - x, 0.5 + x, 0.5)
			grip.texture = tex
		end
	elseif name == "S" then
		grip:SetPoint("BOTTOMRIGHT", -size, 0)
		grip:SetPoint("BOTTOMLEFT", 0, 0)
		grip:SetHeight(size)
	else -- "E"
		grip:SetPoint("BOTTOMRIGHT", 0, size)
		grip:SetPoint("TOPRIGHT")
		grip:SetWidth(size)
	end
	grip._resizeHandle = handle
	grip._resizePoint  = RESIZE_GRIPS[name]
	grip:SetScript("OnMouseDown", Resize_Grip_OnMouseDown)
	grip:SetScript("OnMouseUp", Resize_Grip_OnMouseUp)
	return grip
end

-- Returns the handle, or nil if the target is not a frame (and an AceGUI widget's `.frame` counts).
function lib:MakeResizable(frameOrWidget, opts)
	opts = opts or {}
	local frame = resizeTargetOf(frameOrWidget)
	if not frame then return nil end

	local handle = frame._resizeHandle
	if not handle then
		handle = setmetatable({ frame = frame, grips = {}, _wanted = {}, enabled = true }, ResizeHandle)
		frame._resizeHandle = handle

		-- The throttle. A 1x1 mouse-less child, shown only while there is a pending size change:
		-- a hidden frame gets no OnUpdate, so an idle window costs nothing.
		local driver = CreateFrame("Frame", nil, frame)
		driver:SetWidth(1)
		driver:SetHeight(1)
		driver:SetPoint("TOPLEFT")
		driver:Hide()
		driver._resizeHandle = handle
		handle.driver = driver
		driver:SetScript("OnUpdate", Resize_Driver_OnUpdate)

		-- HookScript, not SetScript: the frame is the consumer's and may already have handlers.
		if frame.HookScript then
			frame:HookScript("OnSizeChanged", Resize_Frame_OnSizeChanged)
			frame:HookScript("OnHide", Resize_Frame_OnHide)
		end
		-- The handle is held by the frame, so this weak-keyed registration lives as long as it does.
		self:OnScaleChanged(handle, Resize_OnScaleChanged)
	else
		handle.driver:SetScript("OnUpdate", Resize_Driver_OnUpdate)   -- undo a previous Destroy
		self:OnScaleChanged(handle, Resize_OnScaleChanged)
	end

	-- A re-call MERGES (MINOR 30): an option the call omits keeps its current value, and `false`
	-- clears a callback. Before, every key was assigned straight from `opts`, so the obvious way to
	-- add a live callback to a window that already had a handle -- `MakeResizable(clearFrame,
	-- { onResize = fn })` -- nil-ed ClearFrame's onResizeStop (the window silently stopped saving its
	-- size) and reset its 400x200 minimum to 0. Dibs' DIBSREQ-LAGW-003. On a new handle every field
	-- starts nil, so a first call behaves exactly as it always did.
	for _, key in ipairs({ "onResize", "onResizeStart", "onResizeStop" }) do
		if opts[key] ~= nil then handle[key] = opts[key] or nil end
	end

	frame:SetResizable(true)
	local function keep(key) if opts[key] == nil then return handle[key] end return opts[key] or nil end
	handle:SetBounds(keep("minW"), keep("minH"), keep("maxW"), keep("maxH"))

	-- `grips` is a SET, not one corner: "SE", "S", "E" or any combination ("SE S E", "SE,S").
	-- Anything unrecognised simply builds nothing, so `grips = false` is a legal way to ask for
	-- bounds and callbacks with no drag handles at all. Omitted, it keeps the set a previous call
	-- asked for; Destroy forgets that set, so a call after it gets the default three again.
	local spec = opts.grips
	if spec == nil then spec = handle._gripSpec end
	if spec == nil then spec = "SE S E" end
	handle._gripSpec = spec
	local wanted = {}
	for token in tostring(spec):upper():gmatch("%a+") do
		if RESIZE_GRIPS[token] then wanted[token] = true end
	end
	handle._wanted = wanted

	local size = tonumber(opts.gripSize) or RESIZE_GRIP_SIZE
	for name in pairs(RESIZE_GRIPS) do
		local grip = handle.grips[name]
		if wanted[name] then
			if not grip then
				grip = buildResizeGrip(handle, name, size, opts.showGrip ~= false)
				handle.grips[name] = grip
			end
			if handle.enabled then grip:Show() end
		elseif grip then
			grip:Hide()
		end
	end

	if opts.status ~= nil then handle:SetStatusTable(opts.status, opts.restore) end
	handle._lastW, handle._lastH = frame:GetWidth() or 0, frame:GetHeight() or 0
	return handle
end

-- The handle previously attached by MakeResizable, or nil. Lets a consumer re-point callbacks or
-- read `IsResizing()` without holding the return value from construction.
function lib:GetResizeHandle(frameOrWidget)
	local frame = resizeTargetOf(frameOrWidget)
	return frame and frame._resizeHandle or nil
end
