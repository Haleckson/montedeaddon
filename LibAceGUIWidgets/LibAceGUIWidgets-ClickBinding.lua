-- LibAceGUIWidgets — ClickBinding widget (MINOR 38, TOGProfessionMaster inbox e0f3923e).
-- An AceGUI-3.0 widget type, "LAGW-ClickBinding": the player sets a MODIFIER + MOUSE BUTTON combination
-- ("Alt + Left Click") by performing it. Asked for because ItemDB's Alt+click on items collides with
-- Gargul's, and the operator decided the default stays Alt + Left Click and the player may change it.
-- AceGUI's own "Keybinding" cannot record this: a Left or Right click there only starts or cancels the
-- capture and is never recorded (Ace3/AceGUI-3.0/widgets/AceGUIWidget-Keybinding.lua:28-48, :89-91).
--
--   local AceGUI = LibStub("AceGUI-3.0")
--   local cb = AceGUI:Create("LAGW-ClickBinding")
--   cb:SetLabel("Open 'Where to get it'")
--   cb:SetDefault("ALT-LeftButton")                   -- adds a small Default reset button
--   cb:SetValue(db.whereClick)                         -- silent
--   cb:SetCallback("OnValueChanged", function(widget, event, binding) db.whereClick = binding end)
--
-- THE STORED STRING is canonical so equal combos compare equal as strings: the held modifiers as a
-- prefix, always in the order ALT-, CTRL-, SHIFT-, then the button name exactly as OnClick delivers it
-- (LeftButton, RightButton, MiddleButton, Button4, Button5). "ALT-LeftButton", "CTRL-SHIFT-RightButton".
-- ItemDB already stores this form, so the format is frozen.
--
-- CAPTURE: click the button to arm it; it reads "Hold Alt, Ctrl or Shift and click here". The next click
-- ON THE BUTTON records the modifiers held at that moment plus the button. A click with NO modifier is
-- refused, for every button, with a short message, and the widget stays armed: a bare Left or Right would
-- fire on every ordinary click, and a bare Middle / Button4 / Button5 is refused as well so the rule is one
-- sentence and matches ItemDB's own refusal. Escape (out of combat) or the Cancel button disarms without
-- changing the value.
--
-- ESCAPE AND COMBAT, as ShowDialog does it: a frame that takes the keyboard must pass every other key on
-- with SetPropagateKeyboardInput, which insecure code may not call in combat (HasRestrictions,
-- SimpleFrameAPIDocumentation.lua:1233). So the keyboard is taken only when armed OUT of combat; armed in
-- combat, the Cancel button is the way out.
--
-- API, AceGUI-shaped: SetValue(binding|nil) (silent, normalised; an unreadable string counts as unbound),
-- GetValue(), SetLabel(text), SetDisabled(bool), SetDefault(binding|nil). OnValueChanged(binding) fires on
-- every change the PLAYER makes, a Default reset included, and only when the value actually changed.
-- Released disarmed, with no value, label or default.
--
-- Library functions, frame-free:
--   W:ParseClickBinding(binding)   -> alt, ctrl, shift, button   (nil for an unreadable string)
--   W:ClickBinding(alt, ctrl, shift, button) -> the canonical string (nil without a known button)
--   W:ClickBindingText(binding)    -> "Alt + Left Click"; NOT_BOUND for nil
--   W:IsClickBinding(binding, button) -> does the click happening NOW match? The held modifiers must match
--                                    EXACTLY, so Alt+Left does not fire on Alt+Ctrl+Left; button nil matches
--                                    on the modifiers alone.
-- Feature-detect with `if W.IsClickBinding then` or `AceGUI:GetWidgetVersion("LAGW-ClickBinding")`.

-- luacheck: read globals LibStub CreateFrame UIParent InCombatLockdown
-- luacheck: read globals IsAltKeyDown IsControlKeyDown IsShiftKeyDown
-- luacheck: ignore 212

local lib = LibStub and LibStub("LibAceGUIWidgets-1.0", true)
if not lib then return end

-- ---------------------------------------------------------------------------
-- The binding string
-- ---------------------------------------------------------------------------
local BUTTONS = { LeftButton = true, RightButton = true, MiddleButton = true, Button4 = true, Button5 = true }

-- Display words. The modifier names are the client's own localised key names where it has them.
local BUTTON_TEXT = {
	LeftButton = "Left Click", RightButton = "Right Click", MiddleButton = "Middle Click",
	Button4 = "Button 4 Click", Button5 = "Button 5 Click",
}

local function g(name, fallback)
	local v = rawget(_G, name)
	return type(v) == "string" and v ~= "" and v or fallback
end

function lib:ClickBinding(alt, ctrl, shift, button)
	if not BUTTONS[button] then return nil end
	return (alt and "ALT-" or "") .. (ctrl and "CTRL-" or "") .. (shift and "SHIFT-" or "") .. button
end

-- Accepts the prefixes in ANY order and any letter case, so a hand-edited saved value still reads; the
-- button name must be exact. Returns nil for anything else, including a repeated modifier.
function lib:ParseClickBinding(binding)
	if type(binding) ~= "string" then return nil end
	local alt, ctrl, shift = false, false, false
	local rest = binding
	while true do
		local mod, tail = rest:match("^(%a+)%-(.+)$")
		if not mod then break end
		mod = mod:upper()
		if mod == "ALT" and not alt then alt = true
		elseif mod == "CTRL" and not ctrl then ctrl = true
		elseif mod == "SHIFT" and not shift then shift = true
		else return nil end
		rest = tail
	end
	if not BUTTONS[rest] then return nil end
	return alt, ctrl, shift, rest
end

local function normalise(binding)
	local alt, ctrl, shift, button = lib:ParseClickBinding(binding)
	if not button then return nil end
	return lib:ClickBinding(alt, ctrl, shift, button)
end

function lib:ClickBindingText(binding)
	local alt, ctrl, shift, button = self:ParseClickBinding(binding)
	if not button then return g("NOT_BOUND", "Not Bound") end
	local parts = {}
	if alt then parts[#parts + 1] = g("ALT_KEY_TEXT", "Alt") end
	if ctrl then parts[#parts + 1] = g("CTRL_KEY_TEXT", "Ctrl") end
	if shift then parts[#parts + 1] = g("SHIFT_KEY_TEXT", "Shift") end
	parts[#parts + 1] = BUTTON_TEXT[button]
	return table.concat(parts, " + ")
end

local function held()
	return (IsAltKeyDown and IsAltKeyDown()) and true or false,
		(IsControlKeyDown and IsControlKeyDown()) and true or false,
		(IsShiftKeyDown and IsShiftKeyDown()) and true or false
end

function lib:IsClickBinding(binding, button)
	local alt, ctrl, shift, want = self:ParseClickBinding(binding)
	if not want then return false end
	if button ~= nil and button ~= want then return false end
	local a, c, s = held()
	return a == alt and c == ctrl and s == shift
end

-- ---------------------------------------------------------------------------
-- The widget
-- ---------------------------------------------------------------------------
do
	local Type, Version = "LAGW-ClickBinding", 1   -- 1: a new type, no competing copy under this name
	local AceGUI = LibStub("AceGUI-3.0", true)
	if AceGUI and (AceGUI:GetWidgetVersion(Type) or 0) < Version then
		local WIDTH, BUTTON_H, LABEL_H, RESET_W, GAP = 200, 24, 18, 64, 4
		local PROMPT = "Hold Alt, Ctrl or Shift and click here"
		local REFUSED = "Needs Alt, Ctrl or Shift -- try again"

		local function inCombat() return (InCombatLockdown and InCombatLockdown()) and true or false end
		local S = function(px) return lib:ScaledSize(px) end

		local function showValue(self)
			self.button:SetText(lib:ClickBindingText(self.value))
		end

		-- The side button is Default while idle (only when a default is set) and Cancel while armed.
		local function layout(self)
			local side = self.reset
			local showSide = self.armed or self.default ~= nil
			side:SetShown(showSide and true or false)
			side:SetText(self.armed and g("CANCEL", "Cancel") or g("DEFAULT", "Default"))
			side:SetSize(S(RESET_W), S(BUTTON_H))
			self.button:SetHeight(S(BUTTON_H))
			self.button:ClearAllPoints()
			self.button:SetPoint("BOTTOMLEFT", self.frame, "BOTTOMLEFT", 0, 0)
			if showSide then
				self.button:SetPoint("BOTTOMRIGHT", side, "BOTTOMLEFT", -S(GAP), 0)
			else
				self.button:SetPoint("BOTTOMRIGHT", self.frame, "BOTTOMRIGHT", 0, 0)
			end
			local hasLabel = (self.label:GetText() or "") ~= ""
			self.label:SetShown(hasLabel)
			self.label:SetHeight(S(LABEL_H))
			self.alignoffset = hasLabel and S(LABEL_H + 12) or nil
			self:SetHeight(hasLabel and S(LABEL_H + BUTTON_H + 2) or S(BUTTON_H))
		end

		local function disarm(self)
			if not self.armed then return end
			self.armed = nil
			local b = self.button
			b:SetScript("OnKeyDown", nil)
			if b.EnableKeyboard and not inCombat() then b:EnableKeyboard(false) end
			if b.UnlockHighlight then b:UnlockHighlight() end
			showValue(self)
			layout(self)
		end

		-- Escape disarms and is consumed; every other key goes on to the game. Only installed out of
		-- combat, and the propagation flag is left alone if combat starts while armed.
		local function Button_OnKeyDown(b, key)
			local consume = key == "ESCAPE"
			if not inCombat() and b.SetPropagateKeyboardInput then b:SetPropagateKeyboardInput(not consume) end
			if consume then disarm(b.obj) end
		end

		local function arm(self)
			self.armed = true
			local b = self.button
			b:SetText(PROMPT)
			if b.LockHighlight then b:LockHighlight() end
			if not inCombat() then
				if b.EnableKeyboard then b:EnableKeyboard(true) end
				if b.SetPropagateKeyboardInput then b:SetPropagateKeyboardInput(true) end
				b:SetScript("OnKeyDown", Button_OnKeyDown)
			end
			layout(self)
		end

		local function setFromPlayer(self, binding)
			local changed = binding ~= self.value
			self.value = binding
			showValue(self)
			if changed then self:Fire("OnValueChanged", binding) end
		end

		local function Button_OnClick(b, mouseButton)
			local self = b.obj
			if self.disabled then return end
			if not self.armed then arm(self) return end
			local alt, ctrl, shift = held()
			local binding = lib:ClickBinding(alt, ctrl, shift, mouseButton)
			if not binding then return end                         -- a button this widget does not know
			if not (alt or ctrl or shift) then
				b:SetText(REFUSED)                                  -- stays armed
				return
			end
			disarm(self)
			setFromPlayer(self, binding)
		end

		local function Reset_OnClick(r)
			local self = r.obj
			if self.armed then disarm(self) return end
			if self.disabled or self.default == nil then return end
			setFromPlayer(self, self.default)
		end

		local methods = {
			["OnAcquire"] = function(self)
				self:SetWidth(WIDTH)
				self.armed = true; disarm(self)
				self.value, self.default = nil, nil
				self.label:SetText("")
				self:SetDisabled(false)
				showValue(self)
				layout(self)
			end,

			["OnRelease"] = function(self)
				disarm(self)
				self.value, self.default = nil, nil
				self.label:SetText("")
			end,

			["SetValue"] = function(self, binding)
				self.value = normalise(binding)
				if not self.armed then showValue(self) end
			end,

			["GetValue"] = function(self) return self.value end,

			["SetLabel"] = function(self, text)
				self.label:SetText(text or "")
				layout(self)
			end,

			["SetDefault"] = function(self, binding)
				self.default = normalise(binding)
				layout(self)
			end,

			["SetDisabled"] = function(self, disabled)
				self.disabled = disabled and true or nil
				if disabled then disarm(self) end
				self.button:SetEnabled(not disabled)
				self.reset:SetEnabled(not disabled)
				if disabled then self.label:SetTextColor(0.5, 0.5, 0.5) else self.label:SetTextColor(1, 1, 1) end
			end,
		}

		local function Constructor()
			local frame = CreateFrame("Frame", nil, UIParent)
			frame:Hide()

			local label = frame:CreateFontString(nil, "OVERLAY")
			label:SetFontObject(lib:ScaledFont("GameFontHighlight"))
			label:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
			label:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
			label:SetJustifyH("LEFT")

			local button = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
			-- Every button, so Middle / Button4 / Button5 reach OnClick as well as Left and Right.
			button:RegisterForClicks("AnyUp")
			button:SetScript("OnClick", Button_OnClick)
			button:SetScript("OnEnter", function(b) b.obj:Fire("OnEnter") end)
			button:SetScript("OnLeave", function(b) b.obj:Fire("OnLeave") end)
			-- A window closing, or a tab switching, while armed must not leave the keyboard taken.
			button:HookScript("OnHide", function(b) disarm(b.obj) end)

			local reset = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
			reset:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)
			reset:SetScript("OnClick", Reset_OnClick)

			local widget = { frame = frame, label = label, button = button, reset = reset, type = Type }
			button.obj, reset.obj = widget, widget
			for method, func in pairs(methods) do widget[method] = func end

			lib:OnScaleChanged(widget, function(_, _, w)
				w.label:SetFontObject(lib:ScaledFont("GameFontHighlight"))
				layout(w)
				local parent = w.parent
				if parent and parent.DoLayout then parent:DoLayout() end
			end)
			return AceGUI:RegisterAsWidget(widget)
		end

		AceGUI:RegisterWidgetType(Type, Constructor, Version)
	end
end
