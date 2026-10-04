local _, LIB = ...

local FrameData = LIB.FrameData
local windowFrames = setmetatable({}, { __mode = "k" })
local specialFrameCounter = 0

---@class ArcaneWizardLibraryWindowFrame: Frame
---@field background Texture Configurable window background.
---@field content Frame Content area inside the window frame.
---@field titleBar Frame Integrated title bar and drag handle.
---@field titleBackground Texture Title bar background.
---@field titleShadowLayers Texture[] Fading shadow below the title transition.
---@field titleText FontString Title font string.
---@field portraitFrame? Frame Optional portrait frame.
---@field portraitBackground? Texture Optional opaque portrait background.
---@field portrait? Texture Optional portrait image.
---@field closeButton? Button Optional close button.
---@field closeOnEscape boolean Whether pressing Escape hides the window.
---@field tabGroup? ArcaneWizardLibraryTabGroup Optional attached tab group.

---@class ArcaneWizardLibraryPopupFrame: Frame
---@field background Texture Configurable popup background.
---@field content Frame Content area inside the popup frame.
---@field closeButton? Button Optional close button.
---@field closeOnEscape boolean Whether pressing Escape hides the popup.

---@class ArcaneWizardLibraryWindowConfig
---@field title string Text displayed in the title bar.
---@field width number Initial frame width.
---@field height number Initial frame height.
---@field backgroundStyle string Background style defined by Arcane Wizard: Library.
---@field backgroundAlpha number Initial background opacity from 0 to 1.
---@field titleTransitionStyle string Title transition style defined by Arcane Wizard: Library.
---@field borderStyle? "library"|"silver"|"gold" Window border style.
---@field showPortrait boolean Whether to create a portrait frame.
---@field showCloseButton boolean Whether to create a close button.
---@field movable boolean Whether the window can be dragged.
---@field closeOnEscape? boolean Whether Escape hides the window.

---@class ArcaneWizardLibraryPopupConfig
---@field width number Initial frame width.
---@field height number Initial frame height.
---@field backgroundStyle string Background style defined by Arcane Wizard: Library.
---@field backgroundAlpha number Initial background opacity from 0 to 1.
---@field showBorder boolean Whether to create a popup border.
---@field borderStyle? "library"|"silver"|"gold" Popup border style.
---@field showCloseButton boolean Whether to create a close button.
---@field movable boolean Whether the popup can be dragged.
---@field closeOnEscape? boolean Whether Escape hides the popup.

---@class ArcaneWizardLibraryTabPage: Frame
---@field tabId string Unique tab identifier.
---@field tabButton ArcaneWizardLibraryTabButton Button that selects this page.

---@class ArcaneWizardLibraryTabButton: Button
---@field tabId string Unique tab identifier.
---@field tabGroup ArcaneWizardLibraryTabGroup Owning tab group.
---@field label FontString Displayed tab label.

---@class ArcaneWizardLibraryTabGroup: Frame
---@field window ArcaneWizardLibraryWindowFrame Window that owns the tab group.
---@field selectedTabId? string Currently selected tab identifier.
---@field AddTab fun(self: ArcaneWizardLibraryTabGroup, id: string, text: string): ArcaneWizardLibraryTabPage
---@field SelectTab fun(self: ArcaneWizardLibraryTabGroup, id: string): ArcaneWizardLibraryTabPage
---@field GetSelectedTab fun(self: ArcaneWizardLibraryTabGroup): string?, ArcaneWizardLibraryTabPage?
---@field SetTabEnabled fun(self: ArcaneWizardLibraryTabGroup, id: string, enabled: boolean)
---@field SetOnTabChanged fun(self: ArcaneWizardLibraryTabGroup, callback: fun(id: string?, page: ArcaneWizardLibraryTabPage?)?)

-----------------------
--- Local Functions ---
-----------------------

local function ValidateConfig(config, minimumWidth, minimumHeight, methodName)
	assert(type(config.width) == "number" and config.width >= minimumWidth, LIB.CommonData.debugPrefix .. methodName .. " width must be at least " .. minimumWidth .. ".")
	assert(type(config.height) == "number" and config.height >= minimumHeight, LIB.CommonData.debugPrefix .. methodName .. " height must be at least " .. minimumHeight .. ".")
	assert(type(config.showCloseButton) == "boolean", LIB.CommonData.debugPrefix .. methodName .. " showCloseButton must be a boolean.")
	assert(type(config.backgroundAlpha) == "number" and config.backgroundAlpha >= 0 and config.backgroundAlpha <= 1, LIB.CommonData.debugPrefix .. methodName .. " backgroundAlpha must be a number between 0 and 1.")
	assert(type(config.movable) == "boolean", LIB.CommonData.debugPrefix .. methodName .. " movable must be a boolean.")
	assert(config.closeOnEscape == nil or type(config.closeOnEscape) == "boolean", LIB.CommonData.debugPrefix .. methodName .. " closeOnEscape must be a boolean or nil.")
end

local function CreateTexture(frame, texturePath, coordinates, brightness)
	local texture = frame:CreateTexture(nil, "BACKGROUND")
	texture:SetTexture(texturePath)
	texture:SetTexCoord(unpack(coordinates))
	texture:SetTexelSnappingBias(0)
	texture:SetSnapToPixelGrid(false)
	texture:SetVertexColor(brightness, brightness, brightness)

	return texture
end

local function ApplyNineSlice(frame, textures, data)
	local sliceSize = textures.sliceSize or data.sliceSize
	local frameOutsets = data.frameOutsets or {}
	local rightOutset = frameOutsets.right or 0
	local bottomOutset = frameOutsets.bottom or 0
	local brightness = data.frameBrightness
	local topLeft = CreateTexture(frame, textures.path, textures.coordinates[1], brightness)
	topLeft:SetSize(sliceSize, sliceSize)
	topLeft:SetPoint("TOPLEFT")

	local topRight = CreateTexture(frame, textures.path, textures.coordinates[3], brightness)
	topRight:SetSize(sliceSize, sliceSize)
	topRight:SetPoint("TOPRIGHT", rightOutset, 0)

	local bottomLeft = CreateTexture(frame, textures.path, textures.coordinates[7], brightness)
	bottomLeft:SetSize(sliceSize, sliceSize)
	bottomLeft:SetPoint("BOTTOMLEFT", 0, -bottomOutset)

	local bottomRight = CreateTexture(frame, textures.path, textures.coordinates[9], brightness)
	bottomRight:SetSize(sliceSize, sliceSize)
	bottomRight:SetPoint("BOTTOMRIGHT", rightOutset, -bottomOutset)

	local top = CreateTexture(frame, textures.path, textures.coordinates[2], brightness)
	top:SetPoint("TOPLEFT", topLeft, "TOPRIGHT")
	top:SetPoint("BOTTOMRIGHT", topRight, "BOTTOMLEFT")

	local bottom = CreateTexture(frame, textures.path, textures.coordinates[8], brightness)
	bottom:SetPoint("TOPLEFT", bottomLeft, "TOPRIGHT")
	bottom:SetPoint("BOTTOMRIGHT", bottomRight, "BOTTOMLEFT")

	local left = CreateTexture(frame, textures.path, textures.coordinates[4], brightness)
	left:SetPoint("TOPLEFT", topLeft, "BOTTOMLEFT")
	left:SetPoint("BOTTOMRIGHT", bottomLeft, "TOPRIGHT")

	local right = CreateTexture(frame, textures.path, textures.coordinates[6], brightness)
	right:SetPoint("TOPLEFT", topRight, "BOTTOMLEFT")
	right:SetPoint("BOTTOMRIGHT", bottomRight, "TOPRIGHT")

	local center = CreateTexture(frame, textures.path, textures.coordinates[5], brightness)
	center:SetPoint("TOPLEFT", topLeft, "BOTTOMRIGHT")
	center:SetPoint("BOTTOMRIGHT", bottomRight, "TOPLEFT")
end

local function ConfigureBackgroundTiling(frame, background, tileSize, insets)
	local horizontalInsets = insets and insets.left + insets.right or 0
	local verticalInsets = insets and insets.top + insets.bottom or 0

	local function UpdateTextureCoordinates(_, width, height)
		background:SetTexCoord(
			0,
			(width - horizontalInsets) / tileSize,
			0,
			(height - verticalInsets) / tileSize
		)
	end

	background:SetHorizTile(true)
	background:SetVertTile(true)
	frame:HookScript("OnSizeChanged", UpdateTextureCoordinates)
	UpdateTextureCoordinates(frame, frame:GetSize())
end

local function CreateInteriorBackground(frame, backgroundStyle, insets, backgroundAlpha)
	local background = frame:CreateTexture(nil, "BACKGROUND", nil, -2)

	if backgroundStyle.color then
		local color = backgroundStyle.color
		background:SetColorTexture(color.red, color.green, color.blue, 1)
	else
		background:SetTexture(backgroundStyle.path, "REPEAT", "REPEAT")
		background:SetTexelSnappingBias(0)
		background:SetSnapToPixelGrid(false)
		ConfigureBackgroundTiling(frame, background, backgroundStyle.tileSize, insets)
	end

	background:SetAlpha(backgroundAlpha)

	if insets then
		background:SetPoint("TOPLEFT", insets.left, -insets.top)
		background:SetPoint("BOTTOMRIGHT", -insets.right, insets.bottom)
	else
		background:SetAllPoints()
	end

	frame.background = background
end

local function RegisterDragHandle(frame, handle)
	handle:RegisterForDrag("LeftButton")
	handle:SetScript("OnDragStart", function()
		frame:StartMoving()
	end)
	handle:SetScript("OnDragStop", function()
		frame:StopMovingOrSizing()
	end)
end

local function ConfigureMovability(frame, movable)
	if not movable then
		return
	end

	frame:SetMovable(true)
end

local function CreateContentFrame(frame, insets)
	local content = CreateFrame("Frame", nil, frame)
	content:SetPoint("TOPLEFT", insets.left, -insets.top)
	content:SetPoint("BOTTOMRIGHT", -insets.right, insets.bottom)

	frame.content = content
end

local function CreateCloseButton(frame, showCloseButton, template, horizontalOffset, verticalOffset)
	if not showCloseButton then
		return
	end

	local closeButton = CreateFrame("Button", nil, frame, template)
	closeButton:SetPoint("TOPRIGHT", -horizontalOffset, -(verticalOffset or horizontalOffset))
	closeButton:SetFrameLevel(frame:GetFrameLevel() + 10)

	frame.closeButton = closeButton
end

local function CreateTitleShadowLayer(frame, data, topOffset, color)
	local texture = frame:CreateTexture(nil, "BACKGROUND", nil, -1)
	texture:SetColorTexture(color.red, color.green, color.blue, color.alpha)
	texture:SetPoint("TOPLEFT", data.leftInset, -topOffset)
	texture:SetPoint("TOPRIGHT", -data.rightInset, -topOffset)
	texture:SetHeight(1)

	return texture
end

local function CreateTitleBar(frame, title, data, transitionStyle)
	local backgroundData = data.background
	local titleBackground = frame:CreateTexture(nil, "BACKGROUND", nil, -1)
	titleBackground:SetTexture(backgroundData.path)
	titleBackground:SetTexelSnappingBias(0)
	titleBackground:SetSnapToPixelGrid(false)
	titleBackground:SetPoint("TOPLEFT", backgroundData.leftInset, -backgroundData.topOffset)
	titleBackground:SetPoint("TOPRIGHT", -backgroundData.rightInset, -backgroundData.topOffset)
	titleBackground:SetHeight(backgroundData.height)

	local transitionData = data.transition
	local titleShadowLayers = {}
	for index, color in ipairs(transitionStyle.shadowColors) do
		titleShadowLayers[index] = CreateTitleShadowLayer(
			frame,
			transitionData,
			transitionData.topOffset + index - 1,
			color
		)
	end

	local titleBar = CreateFrame("Frame", nil, frame)
	titleBar:SetPoint("TOPLEFT", data.horizontalInset, -data.topOffset)
	titleBar:SetPoint("TOPRIGHT", -data.horizontalInset, -data.topOffset)
	titleBar:SetHeight(data.height)
	titleBar:SetFrameLevel(frame:GetFrameLevel() + 5)

	if frame:IsMovable() then
		titleBar:EnableMouse(true)
		RegisterDragHandle(frame, titleBar)
	end

	local titleText = titleBar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	titleText:SetPoint("LEFT")
	titleText:SetPoint("RIGHT")
	titleText:SetJustifyH("CENTER")
	titleText:SetWordWrap(false)
	titleText:SetText(title)

	frame.titleBar = titleBar
	frame.titleBackground = titleBackground
	frame.titleShadowLayers = titleShadowLayers
	frame.titleText = titleText
end

local function CreatePortrait(frame, showPortrait)
	if not showPortrait then
		return
	end

	local data = FrameData.portrait
	local portraitFrame = CreateFrame("Frame", nil, frame)
	portraitFrame:SetSize(data.size, data.size)
	portraitFrame:SetPoint("CENTER", frame, "TOPLEFT", data.offsetX, data.offsetY)
	portraitFrame:SetFrameLevel(frame:GetFrameLevel() + 8)

	local backgroundColor = data.backgroundColor
	local portraitBackground = portraitFrame:CreateTexture(nil, "BACKGROUND")
	portraitBackground:SetSize(data.imageSize, data.imageSize)
	portraitBackground:SetPoint("CENTER")
	portraitBackground:SetColorTexture(backgroundColor.red, backgroundColor.green, backgroundColor.blue, 1)

	local backgroundMask = portraitFrame:CreateMaskTexture(nil, "BACKGROUND")
	backgroundMask:SetTexture(data.maskPath)
	backgroundMask:SetAllPoints(portraitBackground)
	portraitBackground:AddMaskTexture(backgroundMask)

	local portrait = portraitFrame:CreateTexture(nil, "ARTWORK")
	portrait:SetSize(data.imageSize, data.imageSize)
	portrait:SetPoint("CENTER")

	local mask = portraitFrame:CreateMaskTexture(nil, "ARTWORK")
	mask:SetTexture(data.maskPath)
	mask:SetAllPoints(portrait)
	portrait:AddMaskTexture(mask)

	local border = portraitFrame:CreateTexture(nil, "OVERLAY")
	border:SetTexture(data.borderPath)
	border:SetAllPoints()

	frame.portraitFrame = portraitFrame
	frame.portraitBackground = portraitBackground
	frame.portrait = portrait
end

local function CreateBaseFrame(width, height, movable, closeOnEscape)
	local frameName

	if closeOnEscape then
		specialFrameCounter = specialFrameCounter + 1
		frameName = "ArcaneWizardLibrarySpecialFrame" .. specialFrameCounter
	end

	local frame = CreateFrame("Frame", frameName, UIParent)
	frame:SetSize(width, height)
	frame:SetPoint("CENTER")
	frame:SetFrameStrata("MEDIUM")
	frame:SetToplevel(true)
	frame:SetClampedToScreen(true)
	frame:EnableMouse(true)
	frame.closeOnEscape = closeOnEscape == true
	ConfigureMovability(frame, movable)
	frame:HookScript("OnShow", function(self)
		self:Raise()
	end)

	if closeOnEscape then
		table.insert(UISpecialFrames, frameName)
	end

	return frame
end

local function CreateTabBackground(button)
	local placement = FrameData.tabs.placement

	local left = button:CreateTexture(nil, "BACKGROUND")
	left:SetPoint("TOPLEFT")
	left:SetPoint("BOTTOMLEFT")
	left:SetWidth(placement.capWidth)
	left:SetTexCoord(0, 0.25, 0, 1)

	local center = button:CreateTexture(nil, "BACKGROUND")
	center:SetPoint("TOPLEFT", left, "TOPRIGHT")
	center:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -placement.capWidth, 0)
	center:SetTexCoord(0.25, 0.75, 0, 1)

	local right = button:CreateTexture(nil, "BACKGROUND")
	right:SetPoint("TOPRIGHT")
	right:SetPoint("BOTTOMRIGHT")
	right:SetWidth(placement.capWidth)
	right:SetTexCoord(0.75, 1, 0, 1)

	button.backgroundTextures = { left, center, right }
end

local function SetTabButtonState(button, state)
	local data = FrameData.tabs
	local stateData = data.states[state]
	local texturePath = data.placement.textures[state]

	for _, texture in ipairs(button.backgroundTextures) do
		texture:SetTexture(texturePath)
		texture:SetTexelSnappingBias(0)
		texture:SetSnapToPixelGrid(false)
	end

	button.label:ClearAllPoints()
	button.label:SetPoint("CENTER", 0, stateData.textOffset)
	button.label:SetTextColor(unpack(stateData.text))
end

local function RefreshTabButton(button)
	if not button:IsEnabled() then
		SetTabButtonState(button, "disabled")
	elseif button.tabGroup.selectedTabId == button.tabId then
		SetTabButtonState(button, "selected")
	elseif button.mouseDown then
		SetTabButtonState(button, "pushed")
	elseif button.mouseOver then
		SetTabButtonState(button, "highlight")
	else
		SetTabButtonState(button, "normal")
	end
end

local function LayoutTabGroup(tabGroup)
	local placement = FrameData.tabs.placement
	local offset = 0
	for _, entry in ipairs(tabGroup.tabEntries) do
		local height = tabGroup.selectedTabId == entry.id and placement.selectedHeight or placement.height
		entry.button:ClearAllPoints()
		entry.button:SetPoint("TOPLEFT", tabGroup, "TOPLEFT", offset, 0)
		entry.button:SetSize(entry.width, height)
		offset = offset + entry.width + placement.spacing
	end

	tabGroup:SetSize(math.max(offset - placement.spacing, 1), placement.selectedHeight)
end

local function CreateTabButton(tabGroup, id, text)
	local placement = FrameData.tabs.placement
	local button = CreateFrame("Button", nil, tabGroup)
	button:SetSize(placement.minimumWidth, placement.height)
	button:SetFrameLevel(tabGroup:GetFrameLevel() + 1)
	button:RegisterForClicks("LeftButtonUp")
	button.tabId = id
	button.tabGroup = tabGroup

	CreateTabBackground(button)

	local label = button:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	label:SetPoint("CENTER")
	label:SetWordWrap(false)
	label:SetText(text)
	button.label = label

	button:SetScript("OnEnter", function(self)
		self.mouseOver = true
		RefreshTabButton(self)
	end)
	button:SetScript("OnLeave", function(self)
		self.mouseOver = false
		self.mouseDown = false
		RefreshTabButton(self)
	end)
	button:SetScript("OnMouseDown", function(self, mouseButton)
		if mouseButton == "LeftButton" then
			self.mouseDown = true
			RefreshTabButton(self)
		end
	end)
	button:SetScript("OnMouseUp", function(self, mouseButton)
		if mouseButton == "LeftButton" then
			self.mouseDown = false
			RefreshTabButton(self)
		end
	end)
	button:SetScript("OnClick", function(self)
		self.tabGroup:SelectTab(self.tabId)
	end)
	button:SetScript("OnEnable", RefreshTabButton)
	button:SetScript("OnDisable", RefreshTabButton)

	RefreshTabButton(button)

	return button, math.max(
		placement.minimumWidth,
		math.ceil(button.label:GetStringWidth()) + placement.horizontalPadding * 2
	)
end

--- Adds a tab and its content page; selects the first tab automatically.
---
--- @param tabGroup ArcaneWizardLibraryTabGroup The owning tab group.
--- @param id string The unique, non-empty tab identifier.
--- @param text string The non-empty tab label.
---
--- @return ArcaneWizardLibraryTabPage page The created content page.
local function AddTab(tabGroup, id, text)
	assert(type(id) == "string" and id ~= "", LIB.CommonData.debugPrefix .. "AddTab id must be a non-empty string.")
	assert(type(text) == "string" and text ~= "", LIB.CommonData.debugPrefix .. "AddTab text must be a non-empty string.")
	assert(not tabGroup.tabsById[id], LIB.CommonData.debugPrefix .. "AddTab id is already registered.")
	local button, width = CreateTabButton(tabGroup, id, text)
	local page = CreateFrame("Frame", nil, tabGroup.window.content)
	page:SetAllPoints()
	page:Hide()
	page.tabId = id
	page.tabButton = button

	local entry = {
		id = id,
		button = button,
		page = page,
		width = width
	}
	tabGroup.tabEntries[#tabGroup.tabEntries + 1] = entry
	tabGroup.tabsById[id] = entry
	LayoutTabGroup(tabGroup)

	if not tabGroup.selectedTabId then
		tabGroup:SelectTab(id)
	end

	return page
end

--- Selects an enabled tab; calls onTabChanged only when the selection changes.
---
--- @param tabGroup ArcaneWizardLibraryTabGroup The owning tab group.
--- @param id string The registered tab identifier.
---
--- @return ArcaneWizardLibraryTabPage page The selected content page.
local function SelectTab(tabGroup, id)
	local entry = tabGroup.tabsById[id]
	assert(entry, LIB.CommonData.debugPrefix .. "SelectTab id is not registered.")
	assert(entry.button:IsEnabled(), LIB.CommonData.debugPrefix .. "SelectTab cannot select a disabled tab.")

	if tabGroup.selectedTabId == id then
		return entry.page
	end

	local previousEntry = tabGroup.selectedTabId and tabGroup.tabsById[tabGroup.selectedTabId]
	if previousEntry then
		previousEntry.page:Hide()
	end

	tabGroup.selectedTabId = id
	entry.page:Show()

	if previousEntry then
		RefreshTabButton(previousEntry.button)
	end
	RefreshTabButton(entry.button)
	LayoutTabGroup(tabGroup)

	if tabGroup.onTabChanged then
		tabGroup.onTabChanged(id, entry.page)
	end

	return entry.page
end

--- Returns the selected tab and its content page.
---
--- @param tabGroup ArcaneWizardLibraryTabGroup The owning tab group.
---
--- @return string|nil id The selected tab identifier, or nil when no tab is selected.
--- @return ArcaneWizardLibraryTabPage|nil page The selected content page, or nil.
local function GetSelectedTab(tabGroup)
	local entry = tabGroup.selectedTabId and tabGroup.tabsById[tabGroup.selectedTabId]
	if not entry then
		return nil, nil
	end

	return entry.id, entry.page
end

--- Enables or disables a tab, selecting an enabled replacement when necessary.
---
--- @param tabGroup ArcaneWizardLibraryTabGroup The owning tab group.
--- @param id string The registered tab identifier.
--- @param enabled boolean Whether the tab can be selected.
local function SetTabEnabled(tabGroup, id, enabled)
	local entry = tabGroup.tabsById[id]
	assert(entry, LIB.CommonData.debugPrefix .. "SetTabEnabled id is not registered.")
	assert(type(enabled) == "boolean", LIB.CommonData.debugPrefix .. "SetTabEnabled enabled must be a boolean.")

	if enabled then
		entry.button:Enable()
		if not tabGroup.selectedTabId then
			tabGroup:SelectTab(id)
		end
		return
	end

	entry.button:Disable()
	if tabGroup.selectedTabId ~= id then
		return
	end

	entry.page:Hide()
	tabGroup.selectedTabId = nil
	for _, replacement in ipairs(tabGroup.tabEntries) do
		if replacement.button:IsEnabled() then
			tabGroup:SelectTab(replacement.id)
			return
		end
	end

	RefreshTabButton(entry.button)
	LayoutTabGroup(tabGroup)
	if tabGroup.onTabChanged then
		tabGroup.onTabChanged(nil, nil)
	end
end

--- Sets the callback invoked when the selected tab changes.
---
--- @param tabGroup ArcaneWizardLibraryTabGroup The owning tab group.
--- @param callback fun(id: string|nil, page: ArcaneWizardLibraryTabPage|nil)|nil The callback, or nil to remove it.
local function SetOnTabChanged(tabGroup, callback)
	assert(callback == nil or type(callback) == "function", LIB.CommonData.debugPrefix .. "SetOnTabChanged callback must be a function or nil.")
	tabGroup.onTabChanged = callback
end

------------------------
--- Public Functions ---
------------------------

--- Creates a hidden, centered window with a title bar and frame.content.
---
--- @param config ArcaneWizardLibraryWindowConfig Window configuration.
---
--- @return ArcaneWizardLibraryWindowFrame frame The created window.
function ArcaneWizardLibrary.Frames:CreateWindow(config)
	assert(type(config) == "table", LIB.CommonData.debugPrefix .. "CreateWindow config must be a table.")

	local data = FrameData.window
	assert(type(config.title) == "string", LIB.CommonData.debugPrefix .. "CreateWindow title must be a string.")
	assert(type(config.showPortrait) == "boolean", LIB.CommonData.debugPrefix .. "CreateWindow showPortrait must be a boolean.")

	local minimumWidth = config.showPortrait and data.portraitMinimumWidth or data.minimumWidth
	local minimumHeight = config.showPortrait and data.portraitMinimumHeight or data.minimumHeight
	ValidateConfig(config, minimumWidth, minimumHeight, "CreateWindow")

	local background = FrameData.backgroundStyles[config.backgroundStyle]
	local titleTransition = FrameData.titleTransitionStyles[config.titleTransitionStyle]
	local border = FrameData.windowBorderStyles[config.borderStyle or "library"]
	assert(background, LIB.CommonData.debugPrefix .. "CreateWindow backgroundStyle is not defined.")
	assert(titleTransition, LIB.CommonData.debugPrefix .. "CreateWindow titleTransitionStyle is not defined.")
	assert(border, LIB.CommonData.debugPrefix .. "CreateWindow borderStyle is not defined.")

	local frame = CreateBaseFrame(config.width, config.height, config.movable, config.closeOnEscape)
	ApplyNineSlice(frame, border, data)
	CreateInteriorBackground(frame, background, data.backgroundInsets, config.backgroundAlpha)
	CreateContentFrame(frame, data.contentInsets)
	CreateTitleBar(frame, config.title, data.title, titleTransition)
	CreatePortrait(frame, config.showPortrait)
	CreateCloseButton(
		frame,
		config.showCloseButton,
		data.closeButton.template,
		data.closeButton.horizontalOffset,
		data.closeButton.verticalOffset
	)
	windowFrames[frame] = true
	frame:Hide()

	return frame
end

--- Creates a hidden, centered popup with frame.content and an optional border.
---
--- @param config ArcaneWizardLibraryPopupConfig Popup configuration.
---
--- @return ArcaneWizardLibraryPopupFrame frame The created popup.
function ArcaneWizardLibrary.Frames:CreatePopup(config)
	assert(type(config) == "table", LIB.CommonData.debugPrefix .. "CreatePopup config must be a table.")

	local data = FrameData.popup
	ValidateConfig(config, data.minimumWidth, data.minimumHeight, "CreatePopup")
	assert(type(config.showBorder) == "boolean", LIB.CommonData.debugPrefix .. "CreatePopup showBorder must be a boolean.")

	local background = FrameData.backgroundStyles[config.backgroundStyle]
	local border = FrameData.popupBorderStyles[config.borderStyle or "library"]
	assert(background, LIB.CommonData.debugPrefix .. "CreatePopup backgroundStyle is not defined.")
	assert(border, LIB.CommonData.debugPrefix .. "CreatePopup borderStyle is not defined.")

	local frame = CreateBaseFrame(config.width, config.height, config.movable, config.closeOnEscape)
	if config.movable then
		RegisterDragHandle(frame, frame)
	end

	if config.showBorder then
		ApplyNineSlice(frame, border, data)
	end
	CreateInteriorBackground(
		frame,
		background,
		config.showBorder and (border.backgroundInsets or data.backgroundInsets) or nil,
		config.backgroundAlpha
	)
	CreateContentFrame(frame, data.contentInsets)
	local closeButtonPosition = config.showBorder and data.closeButton.border or data.closeButton.borderless
	CreateCloseButton(
		frame,
		config.showCloseButton,
		data.closeButton.template,
		closeButtonPosition.horizontalOffset,
		closeButtonPosition.verticalOffset
	)
	frame:Hide()

	return frame
end

--- Creates window tabs whose pages fill window.content; the first added tab is selected.
---
--- @param window ArcaneWizardLibraryWindowFrame The owning window.
---
--- @return ArcaneWizardLibraryTabGroup tabGroup The created tab group.
function ArcaneWizardLibrary.Frames:CreateTabGroup(window)
	local placement = FrameData.tabs.placement

	assert(windowFrames[window], LIB.CommonData.debugPrefix .. "CreateTabGroup window must be a Library window.")
	assert(not window.tabGroup, LIB.CommonData.debugPrefix .. "CreateTabGroup window already has a tab group.")

	local tabGroup = CreateFrame("Frame", nil, window)
	tabGroup:SetPoint(
		placement.anchorPoint,
		window,
		placement.relativePoint,
		placement.offsetX,
		placement.offsetY
	)
	tabGroup:SetSize(1, placement.selectedHeight)
	tabGroup:SetFrameLevel(window:GetFrameLevel() + 8)
	tabGroup.window = window
	tabGroup.tabEntries = {}
	tabGroup.tabsById = {}
	tabGroup.AddTab = AddTab
	tabGroup.SelectTab = SelectTab
	tabGroup.GetSelectedTab = GetSelectedTab
	tabGroup.SetTabEnabled = SetTabEnabled
	tabGroup.SetOnTabChanged = SetOnTabChanged

	window.tabGroup = tabGroup

	return tabGroup
end
