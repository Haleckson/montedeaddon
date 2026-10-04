local _, LIB = ...

local AWL = ArcaneWizardLibrary
local L = LIB.Localization
local ChangelogData = LIB.ChangelogData

---@class ArcaneWizardLibraryChangelogVersion
---@field version string Version label displayed as the section heading.
---@field date? string Optional release or build date.
---@field entries string[] Changelog entries displayed as bullet points.

local changelogWindows = {}

-----------------------
--- Local Functions ---
-----------------------

local function CreateChangelogRow(state)
	local row = CreateFrame("Frame", nil, state.scrollArea.content)

	local text = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	text:SetJustifyH("LEFT")
	text:SetJustifyV("TOP")
	text:SetSpacing(ChangelogData.lineSpacing)
	text:SetWordWrap(true)

	local bullet = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	bullet:SetPoint("TOPLEFT")
	bullet:SetWidth(ChangelogData.bulletWidth)
	bullet:SetJustifyH("CENTER")
	bullet:SetJustifyV("TOP")
	bullet:SetText("•")
	bullet:Hide()

	row.text = text
	row.bullet = bullet

	return row
end

local function AddChangelogRow(state, rowCount, text, isBullet, rowWidth, offset)
	local padding = ChangelogData.contentPadding
	local spacing = ChangelogData.lineSpacing
	local textInset = isBullet and ChangelogData.bulletWidth + ChangelogData.bulletSpacing or 0

	rowCount = rowCount + 1

	local row = state.rows[rowCount]

	if not row then
		row = CreateChangelogRow(state)
		state.rows[rowCount] = row
	end

	row:ClearAllPoints()
	row:SetPoint("TOPLEFT", state.scrollArea.content, "TOPLEFT", padding, -offset)
	row:SetWidth(rowWidth)
	row.bullet:SetShown(isBullet)

	row.text:ClearAllPoints()
	row.text:SetPoint("TOPLEFT", textInset, 0)
	row.text:SetWidth(math.max(1, rowWidth - textInset))
	row.text:SetText(text == "" and " " or text)

	local _, fontHeight = row.text:GetFont()
	local textHeight = row.text:GetStringHeight() or 0
	local rowHeight = math.ceil(math.max(textHeight, fontHeight or 1))

	row:SetHeight(rowHeight)
	row:Show()

	return rowCount, offset + rowHeight + spacing
end

local function RenderChangelog(state, versions)
	local padding = ChangelogData.contentPadding
	local spacing = ChangelogData.lineSpacing
	local rowWidth = math.max(1, state.scrollArea.content:GetWidth() - padding * 2)
	local offset = padding
	local rowCount = 0

	for versionIndex, versionData in ipairs(versions) do
		local heading = "|cffffd200" .. versionData.version

		if versionData.date then
			heading = heading .. " (" .. versionData.date .. ")"
		end

		heading = heading .. "|r"
		rowCount, offset = AddChangelogRow(state, rowCount, heading, false, rowWidth, offset)
		rowCount, offset = AddChangelogRow(state, rowCount, "", false, rowWidth, offset)

		for _, entry in ipairs(versionData.entries) do
			rowCount, offset = AddChangelogRow(state, rowCount, entry, true, rowWidth, offset)
		end

		if versionIndex < #versions then
			rowCount, offset = AddChangelogRow(state, rowCount, "", false, rowWidth, offset)
		end
	end

	for index = rowCount + 1, #state.rows do
		state.rows[index]:Hide()
	end

	state.scrollArea:SetContentHeight(math.ceil(offset - spacing + padding))
end

local function FinishChangelogLayout(frame)
	frame:SetScript("OnUpdate", nil)

	local state = frame.changelogState
	local versions = state.pendingVersions
	state.pendingVersions = nil

	if not versions or not frame:IsShown() then
		return
	end

	RenderChangelog(state, versions)
	state.scrollArea:ScrollToTop()
end

local function ValidateChangelog(versions, addonName)
	assert(type(versions) == "table" and #versions > 0, LIB.CommonData.debugPrefix .. "Changelog versions must be a non-empty table for " .. tostring(addonName) .. ".")

	for versionIndex, versionData in ipairs(versions) do
		local versionPrefix = LIB.CommonData.debugPrefix .. "Changelog version " .. versionIndex .. " for " .. tostring(addonName)

		assert(type(versionData) == "table", versionPrefix .. " must be a table.")
		assert(type(versionData.version) == "string" and versionData.version ~= "", versionPrefix .. " must define a non-empty version string.")
		assert(versionData.date == nil or type(versionData.date) == "string" and versionData.date ~= "", versionPrefix .. " date must be a non-empty string or nil.")
		assert(type(versionData.entries) == "table" and #versionData.entries > 0, versionPrefix .. " entries must be a non-empty table.")

		for entryIndex, entry in ipairs(versionData.entries) do
			assert(type(entry) == "string" and entry ~= "", versionPrefix .. " entry " .. entryIndex .. " must be a non-empty string.")
		end
	end
end

local function CreateChangelogWindow(addonName)
	local windowData = ChangelogData.window
	local frame = AWL.Frames:CreateWindow({
		title = "",
		width = windowData.width,
		height = windowData.height,
		backgroundStyle = windowData.backgroundStyle,
		backgroundAlpha = windowData.backgroundAlpha,
		titleTransitionStyle = windowData.titleTransitionStyle,
		showPortrait = false,
		showCloseButton = true,
		movable = true,
		closeOnEscape = true
	})
	local scrollData = ChangelogData.scrollFrame
	local contentWidth = math.max(frame.content:GetWidth() - ChangelogData.outerInset * 2, 96)
	local contentHeight = math.max(frame.content:GetHeight() - ChangelogData.footerHeight, 72)

	local scrollArea = AWL.ScrollFrames:CreateScrollFrame({
		parent = frame.content,
		width = contentWidth,
		height = contentHeight,
		backgroundStyle = scrollData.backgroundStyle,
		backgroundAlpha = scrollData.backgroundAlpha,
		showBorder = scrollData.showBorder
	})
	scrollArea:SetPoint("TOPLEFT", ChangelogData.outerInset, 0)
	scrollArea:SetPoint("BOTTOMRIGHT", -ChangelogData.outerInset, ChangelogData.footerHeight)

	local closeButton = AWL.Controls:CreateButton({
		parent = frame.content,
		width = ChangelogData.closeButtonWidth,
		label = L["changelog.window.close"],
		onClick = function()
			frame:Hide()
		end
	})
	closeButton:SetPoint("BOTTOMRIGHT", -ChangelogData.outerInset, ChangelogData.outerInset)

	local state = {
		frame = frame,
		scrollArea = scrollArea,
		rows = {}
	}
	frame.changelogState = state
	changelogWindows[addonName] = state

	return state
end

------------------------
--- Public Functions ---
------------------------

--- Opens the addon's changelog window, creating it on first use.
---
--- @param addonName string The addon name.
--- @param versions ArcaneWizardLibraryChangelogVersion[] Changelog versions.
---
--- @return ArcaneWizardLibraryWindowFrame frame The changelog window.
function ArcaneWizardLibrary.Frames:OpenChangelog(addonName, versions)
	assert(type(addonName) == "string" and addonName ~= "", LIB.CommonData.debugPrefix .. "OpenChangelog addonName must be a non-empty string.")
	ValidateChangelog(versions, addonName)

	local state = changelogWindows[addonName] or CreateChangelogWindow(addonName)
	local frame = state.frame
	frame.titleText:SetText(string.format(L["changelog.window.title"], addonName))
	frame:Show()
	RenderChangelog(state, versions)
	state.scrollArea:ScrollToTop()

	state.pendingVersions = versions
	frame:SetScript("OnUpdate", FinishChangelogLayout)

	return frame
end
