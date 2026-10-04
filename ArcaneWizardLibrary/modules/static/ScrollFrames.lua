local _, LIB = ...

local ScrollFrameData = LIB.ScrollFrameData

---@class ArcaneWizardLibraryScrollFrame: Frame
---@field background Texture
---@field scrollFrame ScrollFrame
---@field content Frame
---@field scrollBar Slider
---@field scrollUpButton Button
---@field scrollDownButton Button
---@field scrollStep number
---@field requestedContentHeight number

---@class ArcaneWizardLibraryScrollFrameConfig
---@field parent Frame Parent frame for the scroll area.
---@field width number Scroll area width in pixels.
---@field height number Scroll area height in pixels.
---@field backgroundStyle "transparent"|"solid-black"|"solid-dark"|"solid-library"|"pattern" Background style defined by Arcane Wizard: Library.
---@field backgroundAlpha number Background opacity from 0 to 1.
---@field showBorder boolean Whether to create the outer border.

-----------------------
--- Local Functions ---
-----------------------

local function CreateColorTexture(owner, layer, color)
	local texture = owner:CreateTexture(nil, layer)
	texture:SetColorTexture(unpack(color))

	return texture
end

local function UpdateBackgroundTiling(frame)
	if not frame.backgroundTileSize then
		return
	end

	local insets = frame.backgroundInsets
	local horizontalInsets = insets and insets.left + insets.right or 0
	local verticalInsets = insets and insets.top + insets.bottom or 0
	frame.background:SetTexCoord(
		0,
		(frame:GetWidth() - horizontalInsets) / frame.backgroundTileSize,
		0,
		(frame:GetHeight() - verticalInsets) / frame.backgroundTileSize
	)
end

local function CreateBackground(frame, backgroundStyle, showBorder, backgroundAlpha)
	local background = frame:CreateTexture(nil, "BACKGROUND")
	local insets = showBorder and ScrollFrameData.backgroundInsets or nil

	if backgroundStyle.color then
		local color = backgroundStyle.color
		background:SetColorTexture(color.red, color.green, color.blue, 1)
	else
		background:SetTexture(backgroundStyle.path, "REPEAT", "REPEAT")
		background:SetTexelSnappingBias(0)
		background:SetSnapToPixelGrid(false)
		background:SetHorizTile(true)
		background:SetVertTile(true)
		frame.backgroundTileSize = backgroundStyle.tileSize
	end

	if insets then
		background:SetPoint("TOPLEFT", insets.left, -insets.top)
		background:SetPoint("BOTTOMRIGHT", -insets.right, insets.bottom)
	else
		background:SetAllPoints()
	end

	background:SetAlpha(backgroundStyle.alpha == nil and backgroundAlpha or backgroundStyle.alpha)
	frame.background = background
	frame.backgroundInsets = insets
	UpdateBackgroundTiling(frame)
end

local function CreateBorder(frame, showBorder)
	if not showBorder then
		return
	end

	local color = ScrollFrameData.borderColor
	local top = CreateColorTexture(frame, "BORDER", color)
	top:SetHeight(1)
	top:SetPoint("TOPLEFT")
	top:SetPoint("TOPRIGHT")

	local bottom = CreateColorTexture(frame, "BORDER", color)
	bottom:SetHeight(1)
	bottom:SetPoint("BOTTOMLEFT")
	bottom:SetPoint("BOTTOMRIGHT")

	local left = CreateColorTexture(frame, "BORDER", color)
	left:SetWidth(1)
	left:SetPoint("TOPLEFT")
	left:SetPoint("BOTTOMLEFT")

	local right = CreateColorTexture(frame, "BORDER", color)
	right:SetWidth(1)
	right:SetPoint("TOPRIGHT")
	right:SetPoint("BOTTOMRIGHT")

	frame.border = {
		top = top,
		bottom = bottom,
		left = left,
		right = right
	}
end

local function GetVisualState(region)
	if not region:IsEnabled() then
		return "disabled"
	elseif region.isPushed then
		return "pushed"
	elseif region.isHighlighted then
		return "highlight"
	end

	return "normal"
end

local function UpdateArrowButton(button)
	button.texture:SetTexture(button.textures[GetVisualState(button)])
end

local function CreateArrowButton(frame, direction)
	local data = ScrollFrameData.scrollBar
	local button = CreateFrame("Button", nil, frame)
	button:SetSize(data.buttonSize, data.buttonSize)
	button:RegisterForClicks("LeftButtonUp")
	button.textures = data.textures[direction]

	local texture = button:CreateTexture(nil, "ARTWORK")
	texture:SetAllPoints()
	texture:SetTexelSnappingBias(0)
	texture:SetSnapToPixelGrid(false)
	button.texture = texture

	button:SetScript("OnEnter", function(self)
		self.isHighlighted = true
		UpdateArrowButton(self)
	end)
	button:SetScript("OnLeave", function(self)
		self.isHighlighted = false
		self.isPushed = false
		UpdateArrowButton(self)
	end)
	button:SetScript("OnMouseDown", function(self, mouseButton)
		if mouseButton == "LeftButton" and self:IsEnabled() then
			self.isPushed = true
			UpdateArrowButton(self)
		end
	end)
	button:SetScript("OnMouseUp", function(self, mouseButton)
		if mouseButton == "LeftButton" then
			self.isPushed = false
			self.isHighlighted = self:IsMouseOver()
			UpdateArrowButton(self)
		end
	end)
	button:SetScript("OnEnable", UpdateArrowButton)
	button:SetScript("OnDisable", function(self)
		self.isPushed = false
		UpdateArrowButton(self)
	end)
	UpdateArrowButton(button)

	return button
end

local function UpdateThumbTexture(scrollBar)
	scrollBar.thumb:SetTexture(scrollBar.thumbTextures[GetVisualState(scrollBar)])
end

local function UpdateScrollButtons(frame)
	local minimum, maximum = frame.scrollBar:GetMinMaxValues()
	local value = frame.scrollBar:GetValue()
	local canScroll = maximum > minimum

	if canScroll then
		frame.scrollBar:Enable()
	else
		frame.scrollBar:Disable()
	end

	frame.scrollUpButton:SetEnabled(canScroll and value > minimum)
	frame.scrollDownButton:SetEnabled(canScroll and value < maximum)
	UpdateThumbTexture(frame.scrollBar)
end

local function UpdateScrollRange(frame, verticalRange)
	if not frame.scrollBar then
		return
	end

	local scrollBar = frame.scrollBar
	local range = math.max(0, verticalRange or frame.scrollFrame:GetVerticalScrollRange())

	if range <= ScrollFrameData.scrollBar.rangeTolerance then
		range = 0
	end

	local value = math.min(scrollBar:GetValue(), range)

	scrollBar:SetMinMaxValues(0, range)
	scrollBar:SetValue(value)
	UpdateScrollButtons(frame)
end

local function UpdateScrollBarTrack(scrollBar)
	local data = ScrollFrameData.scrollBar
	local tileSize = data.trackTileSize
	local availableThumbHeight = math.max(1, scrollBar:GetHeight() - data.thumbTrackInset * 2)
	scrollBar.track:SetTexCoord(0, 1, 0, scrollBar:GetHeight() / tileSize)
	scrollBar.thumb:SetSize(data.thumbWidth, math.min(data.thumbHeight, availableThumbHeight))
end

local function UpdateContentSize(frame)
	local scrollFrame = frame.scrollFrame
	local width = math.max(1, scrollFrame:GetWidth())
	local height = math.max(frame.requestedContentHeight, scrollFrame:GetHeight())
	frame.content:SetSize(width, height)
	UpdateScrollRange(frame, height - scrollFrame:GetHeight())
	UpdateScrollBarTrack(frame.scrollBar)
	UpdateBackgroundTiling(frame)
end

local function CreateScrollBar(frame)
	local data = ScrollFrameData.scrollBar
	local upButton = CreateArrowButton(frame, "up")
	upButton:SetPoint("TOPRIGHT", -data.rightInset, -data.topInset)
	upButton:SetScript("OnClick", function()
		frame:SetVerticalScroll(frame:GetVerticalScroll() - frame.scrollStep)
	end)

	local downButton = CreateArrowButton(frame, "down")
	downButton:SetPoint("BOTTOMRIGHT", -data.rightInset, data.bottomInset)
	downButton:SetScript("OnClick", function()
		frame:SetVerticalScroll(frame:GetVerticalScroll() + frame.scrollStep)
	end)

	local scrollBar = CreateFrame("Slider", nil, frame)
	scrollBar:SetOrientation("VERTICAL")
	scrollBar:SetWidth(data.width)
	scrollBar:SetPoint("TOP", upButton, "BOTTOM", 0, -data.buttonSpacing)
	scrollBar:SetPoint("BOTTOM", downButton, "TOP", 0, data.buttonSpacing)
	scrollBar:SetMinMaxValues(0, 0)
	scrollBar:SetValueStep(1)
	scrollBar:SetValue(0)

	local track = scrollBar:CreateTexture(nil, "BACKGROUND")
	track:SetTexture(data.textures.track, "REPEAT", "REPEAT")
	track:SetWidth(data.trackWidth)
	track:SetPoint("TOP")
	track:SetPoint("BOTTOM")
	track:SetTexelSnappingBias(0)
	track:SetSnapToPixelGrid(false)
	track:SetHorizTile(false)
	track:SetVertTile(true)

	scrollBar:SetThumbTexture(data.textures.thumb.normal)
	local thumb = scrollBar:GetThumbTexture()
	thumb:SetSize(data.thumbWidth, data.thumbHeight)
	thumb:SetTexelSnappingBias(0)
	thumb:SetSnapToPixelGrid(false)

	scrollBar.track = track
	scrollBar.thumb = thumb
	scrollBar.thumbTextures = data.textures.thumb
	scrollBar:SetScript("OnValueChanged", function(_, value)
		frame.scrollFrame:SetVerticalScroll(value)
		UpdateScrollButtons(frame)
	end)
	scrollBar:SetScript("OnEnter", function(self)
		self.isHighlighted = true
		UpdateThumbTexture(self)
	end)
	scrollBar:SetScript("OnLeave", function(self)
		self.isHighlighted = false
		self.isPushed = false
		UpdateThumbTexture(self)
	end)
	scrollBar:SetScript("OnMouseDown", function(self, mouseButton)
		if mouseButton == "LeftButton" and self:IsEnabled() then
			self.isPushed = true
			UpdateThumbTexture(self)
		end
	end)
	scrollBar:SetScript("OnMouseUp", function(self, mouseButton)
		if mouseButton == "LeftButton" then
			self.isPushed = false
			self.isHighlighted = self:IsMouseOver()
			UpdateThumbTexture(self)
		end
	end)
	scrollBar:SetScript("OnEnable", UpdateThumbTexture)
	scrollBar:SetScript("OnDisable", function(self)
		self.isPushed = false
		UpdateThumbTexture(self)
	end)

	frame.scrollUpButton = upButton
	frame.scrollDownButton = downButton
	frame.scrollBar = scrollBar
	UpdateScrollBarTrack(scrollBar)
end

local function CreateScrollableContent(frame)
	local insets = ScrollFrameData.contentInsets
	local scrollFrame = CreateFrame("ScrollFrame", nil, frame)
	scrollFrame:SetPoint("TOPLEFT", insets.left, -insets.top)
	scrollFrame:SetPoint("BOTTOMRIGHT", -insets.right, insets.bottom)
	scrollFrame:EnableMouseWheel(true)

	local content = CreateFrame("Frame", nil, scrollFrame)
	content:SetSize(1, 1)
	scrollFrame:SetScrollChild(content)
	scrollFrame:SetScript("OnMouseWheel", function(_, delta)
		frame:SetVerticalScroll(frame:GetVerticalScroll() - delta * frame.scrollStep)
	end)
	scrollFrame:SetScript("OnScrollRangeChanged", function(_, _, verticalRange)
		UpdateScrollRange(frame, verticalRange)
	end)

	frame.scrollFrame = scrollFrame
	frame.content = content
end

------------------------
--- Public Functions ---
------------------------

--- Creates a scroll area with a vertical slider and a content frame.
---
--- @param config ArcaneWizardLibraryScrollFrameConfig Scroll frame configuration.
---
--- @return ArcaneWizardLibraryScrollFrame frame The created scroll area.
function ArcaneWizardLibrary.ScrollFrames:CreateScrollFrame(config)
	assert(type(config) == "table", LIB.CommonData.debugPrefix .. "CreateScrollFrame config must be a table.")

	local background = ScrollFrameData.backgroundStyles[config.backgroundStyle]
	assert(config.parent ~= nil, LIB.CommonData.debugPrefix .. "CreateScrollFrame parent is required.")
	assert(type(config.width) == "number" and config.width >= ScrollFrameData.minimumWidth, LIB.CommonData.debugPrefix .. "CreateScrollFrame width must be at least " .. ScrollFrameData.minimumWidth .. ".")
	assert(type(config.height) == "number" and config.height >= ScrollFrameData.minimumHeight, LIB.CommonData.debugPrefix .. "CreateScrollFrame height must be at least " .. ScrollFrameData.minimumHeight .. ".")
	assert(type(config.showBorder) == "boolean", LIB.CommonData.debugPrefix .. "CreateScrollFrame showBorder must be a boolean.")
	assert(type(config.backgroundAlpha) == "number" and config.backgroundAlpha >= 0 and config.backgroundAlpha <= 1, LIB.CommonData.debugPrefix .. "CreateScrollFrame backgroundAlpha must be a number between 0 and 1.")
	assert(background, LIB.CommonData.debugPrefix .. "CreateScrollFrame backgroundStyle is not defined.")

	local frame = CreateFrame("Frame", nil, config.parent)
	frame:SetSize(config.width, config.height)
	frame.scrollStep = ScrollFrameData.scrollBar.wheelStep
	frame.requestedContentHeight = 1
	CreateBackground(frame, background, config.showBorder, config.backgroundAlpha)
	CreateBorder(frame, config.showBorder)
	CreateScrollableContent(frame)
	CreateScrollBar(frame)

	--- Updates the content height and scroll range, keeping at least the viewport height.
	---
	--- @param contentHeight number The non-negative content height in pixels.
	function frame:SetContentHeight(contentHeight)
		assert(type(contentHeight) == "number" and contentHeight >= 0, LIB.CommonData.debugPrefix .. "ScrollFrame SetContentHeight contentHeight must be a non-negative number.")

		self.requestedContentHeight = contentHeight
		UpdateContentSize(self)
	end

	--- Sets the scroll distance used by the mouse wheel and arrow buttons.
	---
	--- @param scrollStep number The positive scroll distance in pixels.
	function frame:SetScrollStep(scrollStep)
		assert(type(scrollStep) == "number" and scrollStep > 0, LIB.CommonData.debugPrefix .. "ScrollFrame SetScrollStep scrollStep must be greater than zero.")
		self.scrollStep = scrollStep
	end

	--- Sets the vertical scroll offset, clamped to the current scroll range.
	---
	--- @param value number The requested vertical offset in pixels.
	function frame:SetVerticalScroll(value)
		assert(type(value) == "number", LIB.CommonData.debugPrefix .. "ScrollFrame SetVerticalScroll value must be a number.")

		local minimum, maximum = self.scrollBar:GetMinMaxValues()
		self.scrollBar:SetValue(math.max(minimum, math.min(value, maximum)))
	end

	--- Returns the current vertical scroll offset.
	---
	--- @return number value The vertical offset in pixels.
	function frame:GetVerticalScroll()
		return self.scrollBar:GetValue()
	end

	--- Scrolls to the top of the content.
	function frame:ScrollToTop()
		self:SetVerticalScroll(0)
	end

	--- Scrolls to the bottom of the content.
	function frame:ScrollToBottom()
		local _, maximum = self.scrollBar:GetMinMaxValues()
		self:SetVerticalScroll(maximum)
	end

	frame:SetScript("OnSizeChanged", function(self)
		UpdateContentSize(self)
	end)
	UpdateContentSize(frame)

	return frame
end
