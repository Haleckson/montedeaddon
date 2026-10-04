local _, LIB = ...

local ControlData = LIB.ControlData
local ButtonData = ControlData.button
local SelectionData = ControlData.selection

---@alias ArcaneWizardLibraryButtonStyle "classic"|"red"

---@class ArcaneWizardLibraryButtonConfig
---@field parent Frame Parent frame for the button.
---@field width number Button width in pixels.
---@field label string Displayed button label.
---@field onClick? fun(button: ArcaneWizardLibraryActionButton, mouseButton: string, down: boolean) Called when the button is clicked.
---@field buttonStyle? ArcaneWizardLibraryButtonStyle Visual style. Defaults to classic.

---@class ArcaneWizardLibraryCheckboxConfig
---@field parent Frame Parent frame for the checkbox.
---@field width number Checkbox width in pixels.
---@field label string Displayed checkbox label.
---@field checked boolean Initial checked state.
---@field onValueChanged? fun(checked: boolean, checkbox: ArcaneWizardLibrarySelectionControl) Called after a user changes the value.

---@class ArcaneWizardLibraryOptionGroupConfig
---@field parent Frame Parent frame for the option group.
---@field width number Width of every option in pixels.
---@field options ArcaneWizardLibraryOptionConfig[] Options in display order.
---@field selectedValue string|number|boolean Initially selected option value.
---@field onValueChanged? fun(value: string|number|boolean, option: ArcaneWizardLibrarySelectionControl, group: ArcaneWizardLibraryOptionGroup) Called after a user changes the value.

---@class ArcaneWizardLibraryActionButton: Button
---@field Left Texture
---@field Center Texture
---@field Right Texture
---@field buttonStyle ArcaneWizardLibraryButtonStyle
---@field buttonStates table

---@class ArcaneWizardLibrarySelectionControl: CheckButton
---@field Text FontString Control label.
---@field controlStyle "checkbox"|"option" Visual control style.

---@class ArcaneWizardLibraryOptionConfig
---@field label string Displayed option label.
---@field value string|number|boolean Value represented by the option.

---@class ArcaneWizardLibraryOptionGroup: Frame
---@field buttons ArcaneWizardLibrarySelectionControl[] Option buttons in display order.
---@field buttonsByValue table<string|number|boolean, ArcaneWizardLibrarySelectionControl> Option buttons indexed by value.
---@field value string|number|boolean Currently selected value.
---@field enabled boolean Whether the option group is enabled.

ArcaneWizardLibrary_ActionButtonMixin = {}
ArcaneWizardLibrary_SelectionControlMixin = {}

-----------------------
--- Local Functions ---
-----------------------

local function ConfigureTexture(control, setterName, getterName, texturePath, blendMode)
	control[setterName](control, texturePath)

	local texture = control[getterName](control)
	texture:ClearAllPoints()
	texture:SetSize(SelectionData.iconSize, SelectionData.iconSize)
	texture:SetPoint("LEFT")
	texture:SetTexelSnappingBias(0)
	texture:SetSnapToPixelGrid(false)

	if blendMode then
		texture:SetBlendMode(blendMode)
	end
end

local function ConfigureTextures(control, controlStyle)
	local textures = SelectionData.textures[controlStyle]
	ConfigureTexture(control, "SetNormalTexture", "GetNormalTexture", textures.normal)
	ConfigureTexture(control, "SetPushedTexture", "GetPushedTexture", textures.pushed)
	ConfigureTexture(control, "SetDisabledTexture", "GetDisabledTexture", textures.disabled)
	ConfigureTexture(control, "SetHighlightTexture", "GetHighlightTexture", textures.highlight, "ADD")
	ConfigureTexture(control, "SetCheckedTexture", "GetCheckedTexture", textures.checked)
	ConfigureTexture(control, "SetDisabledCheckedTexture", "GetDisabledCheckedTexture", textures.disabledChecked)
end

local function AssertSelectionControlConfig(config, methodName)
	assert(type(config) == "table", LIB.CommonData.debugPrefix .. methodName .. " config must be a table.")
	assert(config.parent ~= nil, LIB.CommonData.debugPrefix .. methodName .. " parent is required.")
	assert(type(config.width) == "number" and config.width >= SelectionData.minimumWidth, LIB.CommonData.debugPrefix .. methodName .. " width must be at least " .. SelectionData.minimumWidth .. ".")
	assert(type(config.label) == "string" and config.label ~= "", LIB.CommonData.debugPrefix .. methodName .. " label must be a non-empty string.")
	assert(config.onValueChanged == nil or type(config.onValueChanged) == "function", LIB.CommonData.debugPrefix .. methodName .. " onValueChanged must be a function or nil.")
end

local function ValidateOptions(options, selectedValue)
	assert(type(options) == "table" and #options > 0, LIB.CommonData.debugPrefix .. "CreateOptionGroup options must be a non-empty table.")

	local values = {}
	local selectedValueExists = false

	for index, option in ipairs(options) do
		assert(type(option) == "table", LIB.CommonData.debugPrefix .. "CreateOptionGroup option " .. index .. " must be a table.")
		assert(type(option.label) == "string" and option.label ~= "", LIB.CommonData.debugPrefix .. "CreateOptionGroup option " .. index .. " label must be a non-empty string.")

		local valueType = type(option.value)
		assert(valueType == "string" or valueType == "number" or valueType == "boolean", LIB.CommonData.debugPrefix .. "CreateOptionGroup option " .. index .. " value must be a string, number, or boolean.")
		assert(not values[option.value], LIB.CommonData.debugPrefix .. "CreateOptionGroup option values must be unique.")

		values[option.value] = true

		if option.value == selectedValue then
			selectedValueExists = true
		end
	end

	assert(selectedValueExists, LIB.CommonData.debugPrefix .. "CreateOptionGroup selectedValue must match an option value.")
end

local function GetButtonState(button)
	local states = button.buttonStates
	if not button:IsEnabled() then
		return states.disabled
	elseif button.isPushed then
		return states.pushed
	elseif button.isHighlighted then
		return states.highlight
	end

	return states.normal
end

local function ConfigureButtonStyle(button, buttonStyle)
	button.buttonStyle = buttonStyle
	button.buttonStates = ButtonData.styles[buttonStyle]
end

local function UpdateButtonAfterClick(button)
	button.isPushed = false
	button.isHighlighted = true
	button:UpdateVisualState()
end

--------------------
--- Button Mixin ---
--------------------

function ArcaneWizardLibrary_ActionButtonMixin:UpdateVisualState()
	local state = GetButtonState(self)
	self.Left:SetTexture(state.texture)
	self.Center:SetTexture(state.texture)
	self.Right:SetTexture(state.texture)

	local text = self:GetFontString()
	text:SetTextColor(unpack(state.text))
end

function ArcaneWizardLibrary_ActionButtonMixin:OnLoad()
	ConfigureButtonStyle(self, ButtonData.defaultStyle)
	self:SetHeight(ButtonData.height)
	self:SetPushedTextOffset(0, -1)
	self:RegisterForClicks("LeftButtonUp")
	self:HookScript("OnClick", UpdateButtonAfterClick)
	self:UpdateVisualState()
end

function ArcaneWizardLibrary_ActionButtonMixin:OnSizeChanged()
	local width = self:GetWidth()
	local height = self:GetHeight()

	if width and width < ButtonData.minimumWidth then
		self:SetWidth(ButtonData.minimumWidth)
	end

	if height and height ~= ButtonData.height then
		self:SetHeight(ButtonData.height)
	end
end

function ArcaneWizardLibrary_ActionButtonMixin:OnEnter()
	self.isHighlighted = true
	self:UpdateVisualState()
end

function ArcaneWizardLibrary_ActionButtonMixin:OnLeave()
	self.isHighlighted = false
	self.isPushed = false
	self:UpdateVisualState()
end

function ArcaneWizardLibrary_ActionButtonMixin:OnMouseDown(button)
	if button == "LeftButton" and self:IsEnabled() then
		self.isPushed = true
		self:UpdateVisualState()
	end
end

function ArcaneWizardLibrary_ActionButtonMixin:OnMouseUp(button)
	if button == "LeftButton" then
		self.isPushed = false
		self.isHighlighted = self:IsMouseOver()
		self:UpdateVisualState()
	end
end

function ArcaneWizardLibrary_ActionButtonMixin:OnEnable()
	self:UpdateVisualState()
end

function ArcaneWizardLibrary_ActionButtonMixin:OnDisable()
	self.isPushed = false
	self:UpdateVisualState()
end

---------------------
--- Control Mixin ---
---------------------

function ArcaneWizardLibrary_SelectionControlMixin:UpdateTextColor()
	local text = self:GetFontString()
	if not text then
		return
	end

	local textColor
	if not self:IsEnabled() then
		textColor = SelectionData.textColors.disabled
	elseif self.isHighlighted then
		textColor = SelectionData.textColors.highlight
	else
		textColor = SelectionData.textColors.normal
	end

	text:SetTextColor(unpack(textColor))
end

function ArcaneWizardLibrary_SelectionControlMixin:OnLoad(controlStyle)
	self.controlStyle = controlStyle
	self:SetHeight(SelectionData.height)
	self:RegisterForClicks("LeftButtonUp")

	local text = self:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	text:SetPoint("LEFT", SelectionData.textOffset, 0)
	text:SetPoint("RIGHT")
	text:SetJustifyH("LEFT")
	self.Text = text
	self:SetFontString(text)

	ConfigureTextures(self, controlStyle)
	self:UpdateTextColor()
end

function ArcaneWizardLibrary_SelectionControlMixin:OnSizeChanged()
	local width = self:GetWidth()
	local height = self:GetHeight()

	if width and width < SelectionData.minimumWidth then
		self:SetWidth(SelectionData.minimumWidth)
	end

	if height and height ~= SelectionData.height then
		self:SetHeight(SelectionData.height)
	end
end

function ArcaneWizardLibrary_SelectionControlMixin:OnEnter()
	self.isHighlighted = true
	self:UpdateTextColor()
end

function ArcaneWizardLibrary_SelectionControlMixin:OnLeave()
	self.isHighlighted = false
	self:UpdateTextColor()
end

function ArcaneWizardLibrary_SelectionControlMixin:OnEnable()
	self:UpdateTextColor()
end

function ArcaneWizardLibrary_SelectionControlMixin:OnDisable()
	self.isHighlighted = false
	self:UpdateTextColor()
end

------------------------
--- Public Functions ---
------------------------

--- Creates a consistently styled action button.
---
--- @param config ArcaneWizardLibraryButtonConfig Button configuration.
---
--- @return ArcaneWizardLibraryActionButton button The created button.
function ArcaneWizardLibrary.Controls:CreateButton(config)
	assert(type(config) == "table", LIB.CommonData.debugPrefix .. "CreateButton config must be a table.")

	local buttonStyle = config.buttonStyle or ButtonData.defaultStyle
	assert(config.parent ~= nil, LIB.CommonData.debugPrefix .. "CreateButton parent is required.")
	assert(type(config.width) == "number" and config.width >= ButtonData.minimumWidth, LIB.CommonData.debugPrefix .. "CreateButton width must be at least " .. ButtonData.minimumWidth .. ".")
	assert(type(config.label) == "string" and config.label ~= "", LIB.CommonData.debugPrefix .. "CreateButton label must be a non-empty string.")
	assert(config.onClick == nil or type(config.onClick) == "function", LIB.CommonData.debugPrefix .. "CreateButton onClick must be a function or nil.")
	assert(ButtonData.styles[buttonStyle] ~= nil, LIB.CommonData.debugPrefix .. "CreateButton buttonStyle is not defined.")

	local button = CreateFrame("Button", nil, config.parent, "ArcaneWizardLibrary_ActionButtonTemplate")
	button:SetWidth(config.width)
	button:SetText(config.label)
	ConfigureButtonStyle(button, buttonStyle)
	button:UpdateVisualState()

	if config.onClick then
		button:SetScript("OnClick", config.onClick)
	end

	return button
end

--- Creates a consistently styled checkbox.
---
--- @param config ArcaneWizardLibraryCheckboxConfig Checkbox configuration.
---
--- @return ArcaneWizardLibrarySelectionControl checkbox The created checkbox.
function ArcaneWizardLibrary.Controls:CreateCheckbox(config)
	AssertSelectionControlConfig(config, "CreateCheckbox")
	assert(type(config.checked) == "boolean", LIB.CommonData.debugPrefix .. "CreateCheckbox checked must be a boolean.")

	local checkbox = CreateFrame("CheckButton", nil, config.parent, "ArcaneWizardLibrary_CheckboxTemplate")
	checkbox:SetWidth(config.width)
	checkbox:SetText(config.label)
	checkbox:SetChecked(config.checked)

	if config.onValueChanged then
		checkbox:SetScript("OnClick", function(button)
			config.onValueChanged(not not button:GetChecked(), button)
		end)
	end

	return checkbox
end

--- Creates a group of mutually exclusive options.
---
--- @param config ArcaneWizardLibraryOptionGroupConfig Option group configuration.
---
--- @return ArcaneWizardLibraryOptionGroup group The created option group.
function ArcaneWizardLibrary.Controls:CreateOptionGroup(config)
	assert(type(config) == "table", LIB.CommonData.debugPrefix .. "CreateOptionGroup config must be a table.")
	assert(config.parent ~= nil, LIB.CommonData.debugPrefix .. "CreateOptionGroup parent is required.")
	assert(type(config.width) == "number" and config.width >= SelectionData.minimumWidth, LIB.CommonData.debugPrefix .. "CreateOptionGroup width must be at least " .. SelectionData.minimumWidth .. ".")
	assert(config.onValueChanged == nil or type(config.onValueChanged) == "function", LIB.CommonData.debugPrefix .. "CreateOptionGroup onValueChanged must be a function or nil.")
	ValidateOptions(config.options, config.selectedValue)

	local optionCount = #config.options
	local groupHeight = optionCount * SelectionData.height + (optionCount - 1) * SelectionData.optionSpacing
	local group = CreateFrame("Frame", nil, config.parent)
	group:SetSize(config.width, groupHeight)
	group.buttons = {}
	group.buttonsByValue = {}
	group.enabled = true

	--- Returns the selected option value.
	---
	--- @return string|number|boolean value The selected value.
	function group:GetValue()
		return self.value
	end

	--- Selects an option without invoking onValueChanged.
	---
	--- @param value string|number|boolean A value present in the option group.
	function group:SetValue(value)
		local selectedButton = self.buttonsByValue[value]
		assert(selectedButton ~= nil, LIB.CommonData.debugPrefix .. "OptionGroup SetValue value must match an option value.")

		self.value = value
		for _, button in ipairs(self.buttons) do
			button:SetChecked(button == selectedButton)
		end
	end

	--- Enables or disables every option in the group.
	---
	--- @param enabled boolean Whether the options can be selected.
	function group:SetEnabled(enabled)
		assert(type(enabled) == "boolean", LIB.CommonData.debugPrefix .. "OptionGroup SetEnabled enabled must be a boolean.")

		self.enabled = enabled
		for _, button in ipairs(self.buttons) do
			if enabled then
				button:Enable()
			else
				button:Disable()
			end
		end
	end

	for index, option in ipairs(config.options) do
		local button = CreateFrame("CheckButton", nil, group, "ArcaneWizardLibrary_OptionButtonTemplate")
		button:SetWidth(config.width)
		button:SetPoint("TOPLEFT", 0, -(index - 1) * (SelectionData.height + SelectionData.optionSpacing))
		button:SetText(option.label)
		button.value = option.value
		button:SetScript("OnClick", function(clickedButton)
			if group.value == clickedButton.value then
				clickedButton:SetChecked(true)
				return
			end

			group:SetValue(clickedButton.value)
			if config.onValueChanged then
				config.onValueChanged(clickedButton.value, clickedButton, group)
			end
		end)

		group.buttons[index] = button
		group.buttonsByValue[option.value] = button
	end

	group:SetValue(config.selectedValue)

	return group
end
