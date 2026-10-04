local _, LIB = ...

local ControlData = LIB.ControlData
local SelectionData = ControlData.selection
local DropdownData = ControlData.dropdown
local DropdownTextures = DropdownData.textures

---@class ArcaneWizardLibraryDropdownOption
---@field label? string Displayed option or group label.
---@field value? string|number|boolean Selectable option value.
---@field icon? string|number Optional texture path or file ID.
---@field atlas? string Optional texture atlas name.
---@field textColor? number[] Optional RGB or RGBA label color.
---@field children? ArcaneWizardLibraryDropdownOption[] Nested options.
---@field divider? boolean Whether the entry is a divider.
---@field disabled? boolean Whether the entry is disabled.

---@class ArcaneWizardLibraryDropdownConfig
---@field parent Frame Parent frame for the dropdown.
---@field width number Dropdown width in pixels.
---@field options ArcaneWizardLibraryDropdownOption[]|fun(): ArcaneWizardLibraryDropdownOption[] Static options or a dynamic options provider.
---@field selectedValue? string|number|boolean Initially selected option value.
---@field onValueChanged? fun(value: string|number|boolean, option: ArcaneWizardLibraryDropdownOption, dropdown: ArcaneWizardLibraryDropdown) Called after a user changes the selection.

---@class ArcaneWizardLibraryDropdown: Button
---@field value? string|number|boolean Currently selected value.
---@field optionsSource ArcaneWizardLibraryDropdownOption[]|fun(): ArcaneWizardLibraryDropdownOption[] Static options or a dynamic options provider.
---@field onValueChanged? fun(value: string|number|boolean, option: ArcaneWizardLibraryDropdownOption, dropdown: ArcaneWizardLibraryDropdown)
---@field defaultText string Text displayed without a selection.
---@field emptyText string Text displayed when the menu has no entries.

ArcaneWizardLibrary_DropdownMixin = {}

-----------------------
--- Local Functions ---
-----------------------

local function IsDropdownValue(value)
	local valueType = type(value)
	return valueType == "string" or valueType == "number" or valueType == "boolean"
end

local function ValidateDropdownOptions(options, values, path)
	assert(type(options) == "table", LIB.CommonData.debugPrefix .. path .. " must return or contain a table.")

	for index, option in ipairs(options) do
		local optionPath = path .. " option " .. index
		assert(type(option) == "table", LIB.CommonData.debugPrefix .. optionPath .. " must be a table.")

		if option.divider then
			assert(option.disabled == nil or type(option.disabled) == "boolean", LIB.CommonData.debugPrefix .. optionPath .. " disabled must be a boolean or nil.")
		else
			assert(type(option.label) == "string" and option.label ~= "", LIB.CommonData.debugPrefix .. optionPath .. " label must be a non-empty string.")
			assert(option.disabled == nil or type(option.disabled) == "boolean", LIB.CommonData.debugPrefix .. optionPath .. " disabled must be a boolean or nil.")
			assert(option.icon == nil or type(option.icon) == "string" or type(option.icon) == "number", LIB.CommonData.debugPrefix .. optionPath .. " icon must be a texture path, file ID, or nil.")
			assert(option.atlas == nil or type(option.atlas) == "string", LIB.CommonData.debugPrefix .. optionPath .. " atlas must be a string or nil.")
			assert(not (option.icon and option.atlas), LIB.CommonData.debugPrefix .. optionPath .. " cannot define both icon and atlas.")

			if option.textColor then
				assert(type(option.textColor) == "table" and #option.textColor >= 3, LIB.CommonData.debugPrefix .. optionPath .. " textColor must contain at least red, green, and blue values.")
				for colorIndex = 1, math.min(#option.textColor, 4) do
					local colorValue = option.textColor[colorIndex]
					assert(type(colorValue) == "number" and colorValue >= 0 and colorValue <= 1, LIB.CommonData.debugPrefix .. optionPath .. " textColor values must be numbers between 0 and 1.")
				end
			end

			if option.children then
				assert(option.value == nil, LIB.CommonData.debugPrefix .. optionPath .. " cannot define both value and children.")
				ValidateDropdownOptions(option.children, values, optionPath .. " children")
			else
				assert(IsDropdownValue(option.value), LIB.CommonData.debugPrefix .. optionPath .. " value must be a string, number, or boolean.")
				assert(not values[option.value], LIB.CommonData.debugPrefix .. "CreateDropdown option values must be unique.")
				values[option.value] = true
			end
		end
	end
end

local function FindDropdownOption(options, value)
	for _, option in ipairs(options) do
		if option.children then
			local childOption = FindDropdownOption(option.children, value)
			if childOption then
				return childOption
			end
		elseif not option.divider and option.value == value then
			return option
		end
	end
end

local function CreateTexture(parent, layer, texturePath)
	local texture = parent:CreateTexture(nil, layer)
	texture:SetTexture(texturePath)
	texture:SetTexelSnappingBias(0)
	texture:SetSnapToPixelGrid(false)

	return texture
end

local function CreateColorTexture(parent, layer, color)
	local texture = parent:CreateTexture(nil, layer)
	texture:SetColorTexture(unpack(color))

	return texture
end

local function SetRowTextColor(row)
	local color
	if row.option and row.option.disabled then
		color = DropdownData.menuTextColors.disabled
	elseif row.isHighlighted then
		color = DropdownData.menuTextColors.highlight
	elseif row.option and row.option.textColor then
		color = row.option.textColor
	else
		color = DropdownData.menuTextColors.normal
	end

	row.Text:SetTextColor(unpack(color))
end

local function UpdatePanelScroll(panel, offset)
	panel.scrollOffset = math.max(0, math.min(offset, panel.maximumScroll))
	panel.ScrollFrame:SetVerticalScroll(panel.scrollOffset)

	if panel.maximumScroll <= 0 then
		panel.ScrollTrack:Hide()
		panel.ScrollThumb:Hide()
		return
	end

	panel.ScrollTrack:Show()
	panel.ScrollThumb:Show()

	local viewportHeight = panel.viewportHeight
	local contentHeight = panel.contentHeight
	local thumbHeight = math.max(16, viewportHeight * viewportHeight / contentHeight)
	local travel = viewportHeight - thumbHeight
	local ratio = panel.scrollOffset / panel.maximumScroll

	panel.ScrollThumb:SetHeight(thumbHeight)
	panel.ScrollThumb:ClearAllPoints()
	panel.ScrollThumb:SetPoint("TOP", panel.ScrollTrack, "TOP", 0, -travel * ratio)
end

local function CreateMenuRow(dropdown, panel)
	local row = CreateFrame("Button", nil, panel.ScrollChild)
	row.dropdown = dropdown
	row.panel = panel
	row:RegisterForClicks("LeftButtonUp")
	row:EnableMouseWheel(true)

	row.Highlight = CreateColorTexture(row, "BACKGROUND", DropdownData.menuColors.highlight)
	row.Highlight:SetAllPoints()
	row.Highlight:Hide()

	row.Indicator = CreateTexture(row, "ARTWORK", SelectionData.textures.option.normal)
	row.Indicator:SetSize(DropdownData.menuIndicatorSize, DropdownData.menuIndicatorSize)
	row.Indicator:SetPoint("LEFT", 4, 0)

	row.Checked = CreateTexture(row, "OVERLAY", SelectionData.textures.option.checked)
	row.Checked:SetSize(DropdownData.menuIndicatorSize, DropdownData.menuIndicatorSize)
	row.Checked:SetPoint("CENTER", row.Indicator)

	row.Icon = row:CreateTexture(nil, "ARTWORK")
	row.Icon:SetSize(DropdownData.menuIconSize, DropdownData.menuIconSize)
	row.Icon:SetPoint("RIGHT", -5, 0)

	row.SubmenuArrow = CreateTexture(row, "ARTWORK", DropdownTextures.submenuArrow)
	row.SubmenuArrow:SetSize(DropdownData.menuIconSize, DropdownData.menuIconSize)
	row.SubmenuArrow:SetPoint("RIGHT", -3, 0)

	row.Divider = CreateColorTexture(row, "ARTWORK", DropdownData.menuColors.divider)
	row.Divider:SetHeight(1)
	row.Divider:SetPoint("LEFT", 6, 0)
	row.Divider:SetPoint("RIGHT", -6, 0)

	row.Text = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	row.Text:SetJustifyH("LEFT")
	row.Text:SetWordWrap(false)

	row:SetScript("OnEnter", function(self)
		if not self.option or self.option.divider or self.option.disabled then
			return
		end

		self.isHighlighted = true
		self.Highlight:Show()
		SetRowTextColor(self)
		self.dropdown:CloseMenuPanelsAfter(self.panel.depth)

		if self.option.children then
			self.dropdown:OpenSubmenu(self)
		end
	end)

	row:SetScript("OnLeave", function(self)
		self.isHighlighted = false
		self.Highlight:Hide()
		SetRowTextColor(self)
	end)

	row:SetScript("OnClick", function(self)
		if not self.option or self.option.divider or self.option.disabled then
			return
		end

		if self.option.children then
			self.dropdown:OpenSubmenu(self)
		else
			self.dropdown:SelectOption(self.option)
		end
	end)

	row:SetScript("OnMouseWheel", function(self, delta)
		UpdatePanelScroll(self.panel, self.panel.scrollOffset - delta * DropdownData.menuScrollStep)
	end)

	return row
end

local function CreateMenuPanel(dropdown, depth)
	local panel = CreateFrame("Frame", nil, UIParent)
	panel.depth = depth
	panel.rows = {}
	panel.scrollOffset = 0
	panel:SetFrameStrata("FULLSCREEN_DIALOG")
	panel:SetFrameLevel(110 + depth * 10)
	panel:SetClampedToScreen(true)
	panel:EnableMouse(true)
	panel:Hide()

	panel.Background = CreateColorTexture(panel, "BACKGROUND", DropdownData.menuColors.background)
	panel.Background:SetAllPoints()

	panel.BorderTop = CreateColorTexture(panel, "BORDER", DropdownData.menuColors.border)
	panel.BorderTop:SetHeight(1)
	panel.BorderTop:SetPoint("TOPLEFT")
	panel.BorderTop:SetPoint("TOPRIGHT")

	panel.BorderLeft = CreateColorTexture(panel, "BORDER", DropdownData.menuColors.border)
	panel.BorderLeft:SetWidth(1)
	panel.BorderLeft:SetPoint("TOPLEFT")
	panel.BorderLeft:SetPoint("BOTTOMLEFT")

	panel.BorderRight = CreateColorTexture(panel, "BORDER", DropdownData.menuColors.border)
	panel.BorderRight:SetWidth(1)
	panel.BorderRight:SetPoint("TOPRIGHT")
	panel.BorderRight:SetPoint("BOTTOMRIGHT")

	panel.BorderBottom = CreateColorTexture(panel, "BORDER", DropdownData.menuColors.border)
	panel.BorderBottom:SetHeight(1)
	panel.BorderBottom:SetPoint("BOTTOMLEFT")
	panel.BorderBottom:SetPoint("BOTTOMRIGHT")

	panel.ScrollFrame = CreateFrame("ScrollFrame", nil, panel)
	panel.ScrollFrame:SetPoint("TOPLEFT", DropdownData.menuPadding, -DropdownData.menuPadding)
	panel.ScrollFrame:SetPoint("BOTTOMRIGHT", -DropdownData.menuPadding, DropdownData.menuPadding)
	panel.ScrollFrame:EnableMouseWheel(true)

	panel.ScrollChild = CreateFrame("Frame", nil, panel.ScrollFrame)
	panel.ScrollFrame:SetScrollChild(panel.ScrollChild)

	panel.ScrollTrack = CreateColorTexture(panel, "ARTWORK", DropdownData.menuColors.scrollTrack)
	panel.ScrollTrack:SetWidth(2)
	panel.ScrollTrack:SetPoint("TOPRIGHT", -2, -DropdownData.menuPadding)
	panel.ScrollTrack:SetPoint("BOTTOMRIGHT", -2, DropdownData.menuPadding)

	panel.ScrollThumb = CreateColorTexture(panel, "OVERLAY", DropdownData.menuColors.scrollThumb)
	panel.ScrollThumb:SetWidth(2)

	panel.ScrollFrame:SetScript("OnMouseWheel", function(_, delta)
		UpdatePanelScroll(panel, panel.scrollOffset - delta * DropdownData.menuScrollStep)
	end)

	return panel
end

----------------------
--- Dropdown Mixin ---
----------------------

function ArcaneWizardLibrary_DropdownMixin:UpdateVisualState()
	local state
	if not self:IsEnabled() then
		state = "disabled"
	elseif self.isPushed then
		state = "pushed"
	elseif self.isHighlighted or self.menuOpen then
		state = "highlight"
	else
		state = "normal"
	end

	local texturePath = DropdownTextures[state]
	self.Left:SetTexture(texturePath)
	self.Center:SetTexture(texturePath)
	self.Right:SetTexture(texturePath)

	local arrowTexture = DropdownTextures.arrowNormal
	if state == "highlight" then
		arrowTexture = DropdownTextures.arrowHighlight
	elseif state == "pushed" then
		arrowTexture = DropdownTextures.arrowPushed
	elseif state == "disabled" then
		arrowTexture = DropdownTextures.arrowDisabled
	end
	self.Arrow:SetTexture(arrowTexture)

	local textColor
	if state == "disabled" then
		textColor = DropdownData.textColors.disabled
	elseif self.value ~= nil then
		textColor = DropdownData.textColors.selected
	elseif state == "pushed" then
		textColor = DropdownData.textColors.highlight
	else
		textColor = DropdownData.textColors[state] or DropdownData.textColors.normal
	end
	self.Text:SetTextColor(unpack(textColor))
end

function ArcaneWizardLibrary_DropdownMixin:UpdateDisplayedText()
	local option
	if self.value ~= nil and self.currentOptions then
		option = FindDropdownOption(self.currentOptions, self.value)
	end

	self:SetText(option and option.label or self.defaultText)
	self:UpdateVisualState()
end

function ArcaneWizardLibrary_DropdownMixin:ResolveOptions()
	local options = self.optionsSource
	if type(options) == "function" then
		options = options()
	end

	ValidateDropdownOptions(options, {}, "CreateDropdown options")
	return options
end

function ArcaneWizardLibrary_DropdownMixin:GetMenuPanel(depth)
	local panel = self.menuPanels[depth]
	if not panel then
		panel = CreateMenuPanel(self, depth)
		self.menuPanels[depth] = panel
	end

	return panel
end

function ArcaneWizardLibrary_DropdownMixin:CloseMenuPanelsAfter(depth)
	for panelDepth = depth + 1, #self.menuPanels do
		self.menuPanels[panelDepth]:Hide()
	end
end

function ArcaneWizardLibrary_DropdownMixin:BuildMenuPanel(options, depth, owner)
	local panel = self:GetMenuPanel(depth)
	local displayOptions = options
	if #displayOptions == 0 then
		displayOptions = {
			{ label = self.emptyText, disabled = true }
		}
	end

	local contentHeight = 0
	local contentWidth = math.max(self:GetWidth(), DropdownData.minimumWidth) - DropdownData.menuPadding * 2
	local maximumContentWidth = DropdownData.menuMaximumWidth - DropdownData.menuPadding * 2

	for index, option in ipairs(displayOptions) do
		local row = panel.rows[index]
		if not row then
			row = CreateMenuRow(self, panel)
			panel.rows[index] = row
		end

		local rowHeight = option.divider and DropdownData.menuDividerHeight or DropdownData.menuRowHeight
		row.option = option
		row.isHighlighted = false
		row:SetSize(contentWidth, rowHeight)
		row:ClearAllPoints()
		row:SetPoint("TOPLEFT", 0, -contentHeight)
		row.Highlight:Hide()
		row.Divider:SetShown(not not option.divider)
		row.Text:SetShown(not option.divider)
		row.Indicator:Hide()
		row.Checked:Hide()
		row.Icon:Hide()
		row.SubmenuArrow:Hide()
		row:EnableMouse(not option.divider)

		if not option.divider then
			local hasChildren = option.children ~= nil
			local hasValue = IsDropdownValue(option.value)
			local leftInset = hasValue and 23 or 8
			local rightInset = 8

			row.Text:SetText(option.label)
			row.Text:ClearAllPoints()
			row.Text:SetPoint("LEFT", leftInset, 0)

			if hasValue then
				row.Indicator:SetTexture(option.disabled and SelectionData.textures.option.disabled or SelectionData.textures.option.normal)
				row.Checked:SetTexture(option.disabled and SelectionData.textures.option.disabledChecked or SelectionData.textures.option.checked)
				row.Indicator:Show()
				row.Checked:SetShown(self.value == option.value)
			end

			if hasChildren then
				row.SubmenuArrow:Show()
				rightInset = rightInset + DropdownData.menuIconSize
			end

			if option.icon or option.atlas then
				if option.atlas then
					row.Icon:SetAtlas(option.atlas)
				else
					row.Icon:SetTexture(option.icon)
				end
				row.Icon:ClearAllPoints()
				row.Icon:SetPoint("RIGHT", hasChildren and -(DropdownData.menuIconSize + 4) or -5, 0)
				row.Icon:Show()
				rightInset = rightInset + DropdownData.menuIconSize
			end

			row.Text:SetPoint("RIGHT", -rightInset, 0)
			SetRowTextColor(row)

			local requiredWidth = leftInset + row.Text:GetUnboundedStringWidth() + rightInset
			contentWidth = math.min(math.max(contentWidth, requiredWidth), maximumContentWidth)
		end

		row:Show()
		contentHeight = contentHeight + rowHeight
	end

	for index = #displayOptions + 1, #panel.rows do
		panel.rows[index]:Hide()
	end

	for index = 1, #displayOptions do
		panel.rows[index]:SetWidth(contentWidth)
	end

	local viewportHeight = math.min(contentHeight, DropdownData.menuMaximumHeight)
	local panelWidth = contentWidth + DropdownData.menuPadding * 2
	local panelHeight = viewportHeight + DropdownData.menuPadding * 2
	panel.contentHeight = contentHeight
	panel.viewportHeight = viewportHeight
	panel.maximumScroll = math.max(0, contentHeight - viewportHeight)
	panel:SetSize(panelWidth, panelHeight)
	panel.ScrollChild:SetSize(contentWidth, math.max(contentHeight, 1))
	UpdatePanelScroll(panel, 0)

	panel:ClearAllPoints()
	if depth == 1 then
		panel:SetPoint("TOPLEFT", self, "BOTTOMLEFT", 0, -2)
	else
		panel:SetPoint("TOPLEFT", owner, "TOPRIGHT", DropdownData.menuPadding + DropdownData.submenuSpacing, 0)
	end
	panel:Show()

	return panel
end

function ArcaneWizardLibrary_DropdownMixin:OpenSubmenu(owner)
	self:CloseMenuPanelsAfter(owner.panel.depth)
	self:BuildMenuPanel(owner.option.children, owner.panel.depth + 1, owner)
end

--- Refreshes options and the menu; clears any selection absent from the options.
function ArcaneWizardLibrary_DropdownMixin:GenerateMenu()
	self.currentOptions = self:ResolveOptions()

	if self.value ~= nil and not FindDropdownOption(self.currentOptions, self.value) then
		self.value = nil
	end

	self:UpdateDisplayedText()

	if self.menuOpen then
		self:CloseMenuPanelsAfter(0)
		self:BuildMenuPanel(self.currentOptions, 1, self)
	end
end

--- Opens and refreshes the menu unless disabled or already open.
function ArcaneWizardLibrary_DropdownMixin:OpenMenu()
	if not self:IsEnabled() or self.menuOpen then
		return
	end

	self:GenerateMenu()
	self.menuOpen = true
	self.DismissFrame:Show()
	self:BuildMenuPanel(self.currentOptions, 1, self)
	self:UpdateVisualState()
end

--- Closes the dropdown menu and all nested menu panels.
function ArcaneWizardLibrary_DropdownMixin:CloseMenu()
	if not self.menuOpen then
		return
	end

	self.menuOpen = false
	self.DismissFrame:Hide()
	self:CloseMenuPanelsAfter(0)
	self:UpdateVisualState()
end

--- Opens or closes the dropdown menu according to its current state.
function ArcaneWizardLibrary_DropdownMixin:ToggleMenu()
	if self.menuOpen then
		self:CloseMenu()
	else
		self:OpenMenu()
	end
end

function ArcaneWizardLibrary_DropdownMixin:SelectOption(option)
	self.value = option.value
	self:UpdateDisplayedText()
	self:CloseMenu()

	if self.onValueChanged then
		self.onValueChanged(option.value, option, self)
	end
end

--- Returns the selected option value.
---
--- @return string|number|boolean|nil value The selected value, or nil when no option is selected.
function ArcaneWizardLibrary_DropdownMixin:GetValue()
	return self.value
end

--- Selects an option without invoking onValueChanged.
---
--- @param value string|number|boolean|nil A value present in the options, or nil to clear the selection.
function ArcaneWizardLibrary_DropdownMixin:SetValue(value)
	if value == nil then
		self.value = nil
		self:UpdateDisplayedText()
		if self.menuOpen then
			self:GenerateMenu()
		end
		return
	end

	assert(IsDropdownValue(value), LIB.CommonData.debugPrefix .. "Dropdown SetValue value must be a string, number, boolean, or nil.")
	self.currentOptions = self:ResolveOptions()
	assert(FindDropdownOption(self.currentOptions, value) ~= nil, LIB.CommonData.debugPrefix .. "Dropdown SetValue value must match an option value.")

	self.value = value
	self:UpdateDisplayedText()
	if self.menuOpen then
		self:GenerateMenu()
	end
end

--- Replaces the options source and refreshes the menu.
---
--- @param options ArcaneWizardLibraryDropdownOption[]|fun(): ArcaneWizardLibraryDropdownOption[] Options or provider.
function ArcaneWizardLibrary_DropdownMixin:SetOptions(options)
	assert(type(options) == "table" or type(options) == "function", LIB.CommonData.debugPrefix .. "Dropdown SetOptions options must be a table or function.")
	self.optionsSource = options
	self:GenerateMenu()
end

--- Sets the text displayed when no option is selected.
---
--- @param text string The non-empty selection placeholder.
function ArcaneWizardLibrary_DropdownMixin:SetDefaultText(text)
	assert(type(text) == "string" and text ~= "", LIB.CommonData.debugPrefix .. "Dropdown SetDefaultText text must be a non-empty string.")
	self.defaultText = text
	self:UpdateDisplayedText()
end

--- Sets the text displayed when the menu has no entries.
---
--- @param text string The non-empty empty-menu label.
function ArcaneWizardLibrary_DropdownMixin:SetEmptyText(text)
	assert(type(text) == "string" and text ~= "", LIB.CommonData.debugPrefix .. "Dropdown SetEmptyText text must be a non-empty string.")
	self.emptyText = text
	if self.menuOpen then
		self:GenerateMenu()
	end
end

function ArcaneWizardLibrary_DropdownMixin:OnLoad()
	self.defaultText = "Select..."
	self.emptyText = "No options"
	self.menuPanels = {}
	self.menuOpen = false
	self.optionsSource = {}
	self:RegisterForClicks("LeftButtonUp")

	self.Left = CreateTexture(self, "BACKGROUND", DropdownTextures.normal)
	self.Left:SetSize(DropdownData.capWidth, DropdownData.height)
	self.Left:SetPoint("LEFT")
	self.Left:SetTexCoord(0, 0.25, 0, 1)

	self.Center = CreateTexture(self, "BACKGROUND", DropdownTextures.normal)
	self.Center:SetPoint("TOPLEFT", self.Left, "TOPRIGHT")
	self.Center:SetPoint("BOTTOMRIGHT", -DropdownData.capWidth, 0)
	self.Center:SetTexCoord(0.25, 0.75, 0, 1)

	self.Right = CreateTexture(self, "BACKGROUND", DropdownTextures.normal)
	self.Right:SetSize(DropdownData.capWidth, DropdownData.height)
	self.Right:SetPoint("RIGHT")
	self.Right:SetTexCoord(0.75, 1, 0, 1)

	self.Arrow = CreateTexture(self, "ARTWORK", DropdownTextures.arrowNormal)
	self.Arrow:SetSize(DropdownData.arrowSize, DropdownData.arrowSize)
	self.Arrow:SetPoint("RIGHT", -3, 0)

	self.Text = self:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	self.Text:SetPoint("LEFT", DropdownData.textLeftInset, 0)
	self.Text:SetPoint("RIGHT", -DropdownData.textRightInset, 0)
	self.Text:SetJustifyH("LEFT")
	self.Text:SetWordWrap(false)
	self:SetFontString(self.Text)

	self.DismissFrame = CreateFrame("Button", nil, UIParent)
	self.DismissFrame:SetAllPoints()
	self.DismissFrame:SetFrameStrata("FULLSCREEN_DIALOG")
	self.DismissFrame:SetFrameLevel(100)
	self.DismissFrame:Hide()
	self.DismissFrame:SetScript("OnClick", function()
		self:CloseMenu()
	end)

	self:UpdateDisplayedText()
	self:UpdateVisualState()
end

function ArcaneWizardLibrary_DropdownMixin:OnSizeChanged()
	local width = self:GetWidth()
	local height = self:GetHeight()

	if width and width < DropdownData.minimumWidth then
		self:SetWidth(DropdownData.minimumWidth)
	end

	if height and height ~= DropdownData.height then
		self:SetHeight(DropdownData.height)
	end

	if self.menuOpen and self.currentOptions then
		self:CloseMenuPanelsAfter(1)
		self:BuildMenuPanel(self.currentOptions, 1, self)
	end
end

function ArcaneWizardLibrary_DropdownMixin:OnEnter()
	self.isHighlighted = true
	self:UpdateVisualState()
end

function ArcaneWizardLibrary_DropdownMixin:OnLeave()
	self.isHighlighted = false
	self.isPushed = false
	self:UpdateVisualState()
end

function ArcaneWizardLibrary_DropdownMixin:OnMouseDown(button)
	if button == "LeftButton" and self:IsEnabled() then
		self.isPushed = true
		self:UpdateVisualState()
	end
end

function ArcaneWizardLibrary_DropdownMixin:OnMouseUp(button)
	if button == "LeftButton" then
		self.isPushed = false
		self.isHighlighted = self:IsMouseOver()
		self:UpdateVisualState()
	end
end

function ArcaneWizardLibrary_DropdownMixin:OnClick()
	self:ToggleMenu()
end

function ArcaneWizardLibrary_DropdownMixin:OnEnable()
	self:UpdateVisualState()
end

function ArcaneWizardLibrary_DropdownMixin:OnDisable()
	self.isPushed = false
	self:CloseMenu()
	self:UpdateVisualState()
end

function ArcaneWizardLibrary_DropdownMixin:OnHide()
	self:CloseMenu()
end

------------------------
--- Public Functions ---
------------------------

--- Creates a consistently styled dropdown with optional icons and nested option groups.
---
--- @param config ArcaneWizardLibraryDropdownConfig Dropdown configuration.
---
--- @return ArcaneWizardLibraryDropdown dropdown The created dropdown.
function ArcaneWizardLibrary.Controls:CreateDropdown(config)
	assert(type(config) == "table", LIB.CommonData.debugPrefix .. "CreateDropdown config must be a table.")
	assert(config.parent ~= nil, LIB.CommonData.debugPrefix .. "CreateDropdown parent is required.")
	assert(type(config.width) == "number" and config.width >= DropdownData.minimumWidth, LIB.CommonData.debugPrefix .. "CreateDropdown width must be at least " .. DropdownData.minimumWidth .. ".")
	assert(type(config.options) == "table" or type(config.options) == "function", LIB.CommonData.debugPrefix .. "CreateDropdown options must be a table or function.")
	assert(config.selectedValue == nil or IsDropdownValue(config.selectedValue), LIB.CommonData.debugPrefix .. "CreateDropdown selectedValue must be a string, number, boolean, or nil.")
	assert(config.onValueChanged == nil or type(config.onValueChanged) == "function", LIB.CommonData.debugPrefix .. "CreateDropdown onValueChanged must be a function or nil.")

	local dropdown = CreateFrame("Button", nil, config.parent, "ArcaneWizardLibrary_DropdownTemplate")
	dropdown:SetWidth(config.width)
	dropdown.onValueChanged = config.onValueChanged
	dropdown:SetOptions(config.options)
	dropdown:SetValue(config.selectedValue)

	return dropdown
end
