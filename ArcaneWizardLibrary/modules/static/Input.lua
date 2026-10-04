local _, LIB = ...

local InputData = LIB.ControlData.input
local InputTextures = InputData.textures
local ClearButtonData = InputData.clearButton
local ClearButtonTextures = ClearButtonData.textures

---@class ArcaneWizardLibraryInputConfig
---@field parent Frame Parent frame for the input field.
---@field width number Input width in pixels.
---@field text string Initial input text.
---@field placeholder string Text displayed while the unfocused input is empty.
---@field maxLetters? number Maximum number of characters. Nil or zero allows the game default.
---@field onTextChanged? fun(text: string, userInput: boolean, input: ArcaneWizardLibraryInput) Called after the text changes.
---@field onEnterPressed? fun(text: string, input: ArcaneWizardLibraryInput) Called before Enter clears focus.

---@class ArcaneWizardLibraryInput: EditBox
---@field Left Texture
---@field Center Texture
---@field Right Texture
---@field Placeholder FontString
---@field ClearButton Button
---@field placeholderText string
---@field hasFocus boolean
---@field isClearButtonChange boolean
---@field onTextChanged? fun(text: string, userInput: boolean, input: ArcaneWizardLibraryInput)
---@field onEnterPressed? fun(text: string, input: ArcaneWizardLibraryInput)

ArcaneWizardLibrary_InputMixin = {}

-----------------------
--- Local Functions ---
-----------------------

local function CreateTexture(parent, texturePath)
	local texture = parent:CreateTexture(nil, "BACKGROUND")
	texture:SetTexture(texturePath)
	texture:SetTexelSnappingBias(0)
	texture:SetSnapToPixelGrid(false)

	return texture
end

local function CreateBackground(input)
	local left = CreateTexture(input, InputTextures.normal)
	left:SetPoint("TOPLEFT")
	left:SetPoint("BOTTOMLEFT")
	left:SetWidth(InputData.capWidth)
	left:SetTexCoord(0, 0.25, 0, 1)

	local center = CreateTexture(input, InputTextures.normal)
	center:SetPoint("TOPLEFT", left, "TOPRIGHT")
	center:SetPoint("BOTTOMRIGHT", input, "BOTTOMRIGHT", -InputData.capWidth, 0)
	center:SetTexCoord(0.25, 0.75, 0, 1)

	local right = CreateTexture(input, InputTextures.normal)
	right:SetPoint("TOPRIGHT")
	right:SetPoint("BOTTOMRIGHT")
	right:SetWidth(InputData.capWidth)
	right:SetTexCoord(0.75, 1, 0, 1)

	input.Left = left
	input.Center = center
	input.Right = right
end

local function GetVisualState(input)
	if not input:IsEnabled() then
		return "disabled"
	elseif input.hasFocus then
		return "focused"
	elseif input.isHighlighted then
		return "highlight"
	end

	return "normal"
end

local function UpdateClearButtonVisual(button)
	local state = "normal"
	if button.isPushed then
		state = "pushed"
	elseif button.isHighlighted then
		state = "highlight"
	end

	button.Icon:SetTexture(ClearButtonTextures[state])
end

local function CreateClearButton(input)
	local button = CreateFrame("Button", nil, input)
	button:SetSize(ClearButtonData.size, ClearButtonData.size)
	button:SetPoint("RIGHT", -ClearButtonData.rightInset, 0)
	button:SetFrameLevel(input:GetFrameLevel() + 1)
	button:RegisterForClicks("LeftButtonUp")

	local icon = button:CreateTexture(nil, "ARTWORK")
	icon:SetAllPoints()
	icon:SetTexelSnappingBias(0)
	icon:SetSnapToPixelGrid(false)
	button.Icon = icon

	button:SetScript("OnEnter", function(self)
		self.isHighlighted = true
		UpdateClearButtonVisual(self)
	end)
	button:SetScript("OnLeave", function(self)
		self.isHighlighted = false
		self.isPushed = false
		UpdateClearButtonVisual(self)
	end)
	button:SetScript("OnMouseDown", function(self, mouseButton)
		if mouseButton == "LeftButton" then
			self.isPushed = true
			UpdateClearButtonVisual(self)
		end
	end)
	button:SetScript("OnMouseUp", function(self, mouseButton)
		if mouseButton == "LeftButton" then
			self.isPushed = false
			UpdateClearButtonVisual(self)
		end
	end)
	button:SetScript("OnClick", function()
		input.isClearButtonChange = true
		input:SetText("")
		input.isClearButtonChange = false
		input:SetFocus()
	end)

	UpdateClearButtonVisual(button)
	button:Hide()
	input.ClearButton = button
end

-------------------
--- Input Mixin ---
-------------------

function ArcaneWizardLibrary_InputMixin:UpdatePlaceholder()
	self.Placeholder:SetShown(not self.hasFocus and self:GetText() == "" and self.placeholderText ~= "")
end

function ArcaneWizardLibrary_InputMixin:UpdateClearButton()
	local isShown = self:IsEnabled() and self:GetText() ~= ""

	if not isShown then
		self.ClearButton.isHighlighted = false
		self.ClearButton.isPushed = false
		UpdateClearButtonVisual(self.ClearButton)
	end

	self.ClearButton:SetShown(isShown)
end

function ArcaneWizardLibrary_InputMixin:UpdateVisualState()
	local state = GetVisualState(self)
	local texturePath = InputTextures[state]
	local textColor = InputData.textColors[state]

	self.Left:SetTexture(texturePath)
	self.Center:SetTexture(texturePath)
	self.Right:SetTexture(texturePath)
	self:SetTextColor(unpack(textColor))
	self:UpdatePlaceholder()
	self:UpdateClearButton()
end

--- Sets the text displayed while the unfocused input is empty.
---
--- @param text string The placeholder text; an empty string hides it.
function ArcaneWizardLibrary_InputMixin:SetPlaceholder(text)
	assert(type(text) == "string", LIB.CommonData.debugPrefix .. "Input SetPlaceholder text must be a string.")

	self.placeholderText = text
	self.Placeholder:SetText(text)
	self:UpdatePlaceholder()
end

--- Returns the configured placeholder text.
---
--- @return string text The placeholder text.
function ArcaneWizardLibrary_InputMixin:GetPlaceholder()
	return self.placeholderText
end

function ArcaneWizardLibrary_InputMixin:OnLoad()
	self.placeholderText = ""
	self.hasFocus = false
	self.isClearButtonChange = false
	self:SetHeight(InputData.height)
	self:SetAutoFocus(false)
	self:SetFontObject(GameFontHighlight)
	self:SetJustifyH("LEFT")
	self:SetTextInsets(InputData.textLeftInset, InputData.textRightInset, 0, 0)

	CreateBackground(self)

	local placeholder = self:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	placeholder:SetPoint("LEFT", InputData.textLeftInset, 0)
	placeholder:SetPoint("RIGHT", -InputData.textRightInset, 0)
	placeholder:SetJustifyH("LEFT")
	placeholder:SetWordWrap(false)
	placeholder:SetTextColor(unpack(InputData.textColors.placeholder))
	self.Placeholder = placeholder
	CreateClearButton(self)

	self:UpdateVisualState()
end

function ArcaneWizardLibrary_InputMixin:OnSizeChanged()
	local width = self:GetWidth()
	local height = self:GetHeight()

	if width and width < InputData.minimumWidth then
		self:SetWidth(InputData.minimumWidth)
	end

	if height and height ~= InputData.height then
		self:SetHeight(InputData.height)
	end
end

function ArcaneWizardLibrary_InputMixin:OnEnter()
	self.isHighlighted = true
	self:UpdateVisualState()
end

function ArcaneWizardLibrary_InputMixin:OnLeave()
	self.isHighlighted = false
	self:UpdateVisualState()
end

function ArcaneWizardLibrary_InputMixin:OnEditFocusGained()
	self.hasFocus = true
	self:UpdateVisualState()
end

function ArcaneWizardLibrary_InputMixin:OnEditFocusLost()
	self.hasFocus = false
	self:UpdateVisualState()
end

function ArcaneWizardLibrary_InputMixin:OnTextChanged(userInput)
	local isUserInput = not not (userInput or self.isClearButtonChange)
	self.isClearButtonChange = false
	self:UpdatePlaceholder()
	self:UpdateClearButton()

	if self.onTextChanged then
		self.onTextChanged(self:GetText(), isUserInput, self)
	end
end

function ArcaneWizardLibrary_InputMixin:OnEnterPressed()
	if self.onEnterPressed then
		self.onEnterPressed(self:GetText(), self)
	end

	self:ClearFocus()
end

function ArcaneWizardLibrary_InputMixin:OnEscapePressed()
	self:ClearFocus()
end

function ArcaneWizardLibrary_InputMixin:OnEnable()
	self:UpdateVisualState()
end

function ArcaneWizardLibrary_InputMixin:OnDisable()
	self.isHighlighted = false
	self.hasFocus = false
	self:ClearFocus()
	self:UpdateVisualState()
end

------------------------
--- Public Functions ---
------------------------

--- Creates a consistently styled single-line input field.
---
--- @param config ArcaneWizardLibraryInputConfig Input configuration.
---
--- @return ArcaneWizardLibraryInput input The created input field.
function ArcaneWizardLibrary.Controls:CreateInput(config)
	assert(type(config) == "table", LIB.CommonData.debugPrefix .. "CreateInput config must be a table.")
	assert(config.parent ~= nil, LIB.CommonData.debugPrefix .. "CreateInput parent is required.")
	assert(type(config.width) == "number" and config.width >= InputData.minimumWidth, LIB.CommonData.debugPrefix .. "CreateInput width must be at least " .. InputData.minimumWidth .. ".")
	assert(type(config.text) == "string", LIB.CommonData.debugPrefix .. "CreateInput text must be a string.")
	assert(type(config.placeholder) == "string", LIB.CommonData.debugPrefix .. "CreateInput placeholder must be a string.")
	assert(config.maxLetters == nil or type(config.maxLetters) == "number" and config.maxLetters >= 0 and config.maxLetters == math.floor(config.maxLetters), LIB.CommonData.debugPrefix .. "CreateInput maxLetters must be a non-negative integer or nil.")
	assert(config.onTextChanged == nil or type(config.onTextChanged) == "function", LIB.CommonData.debugPrefix .. "CreateInput onTextChanged must be a function or nil.")
	assert(config.onEnterPressed == nil or type(config.onEnterPressed) == "function", LIB.CommonData.debugPrefix .. "CreateInput onEnterPressed must be a function or nil.")

	local input = CreateFrame("EditBox", nil, config.parent, "ArcaneWizardLibrary_InputTemplate")
	input:SetWidth(config.width)
	input:SetPlaceholder(config.placeholder)
	if config.maxLetters then
		input:SetMaxLetters(config.maxLetters)
	end
	input:SetText(config.text)
	input.onTextChanged = config.onTextChanged
	input.onEnterPressed = config.onEnterPressed

	return input
end
