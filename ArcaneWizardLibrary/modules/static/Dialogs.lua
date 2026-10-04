local _, LIB = ...

local L = LIB.Localization

----------------------------
--- Static Popup Dialogs ---
----------------------------

StaticPopupDialogs["ARCANE_WIZARD_LIB_LINK"] = {
	text = L["dialog.link.text"],
	button1 = CLOSE,
	hasEditBox = true,
	editBoxWidth = 300,
	OnShow = function(self, data)
		self:GetEditBox():SetText(data)
		self:GetEditBox():HighlightText()
		self:GetEditBox():SetFocus()
		self:SetWidth(350)
	end,
	EditBoxOnTextChanged = function(self, data)
		if self:GetText() ~= data then
			self:SetText(data)
			self:HighlightText()
		end
	end,
	EditBoxOnEnterPressed = function(self)
		self:GetParent():Hide()
	end,
	EditBoxOnEscapePressed = function(self)
		self:GetParent():Hide()
	end,
	timeout = 0,
	whileDead = true,
	hideOnEscape = true,
	preferredIndex = 3,
	fullScreenCover = true
}

StaticPopupDialogs["ARCANE_WIZARD_LIB_CONFIRM"] = {
	text = "%s",
	button1 = YES,
	button2 = NO,
	OnAccept = function(self, data)
		if data and type(data.onAccept) == "function" then
			data.onAccept()
		end
	end,
	OnCancel = function(self, data, reason)
		if data and type(data.onCancel) == "function" then
			data.onCancel()
		end
	end,
	timeout = 0,
	whileDead = true,
	showAlert = true,
	hideOnEscape = false,
	preferredIndex = 3,
	fullScreenCover = true
}

------------------------
--- Public Functions ---
------------------------

--- Shows a dialog with preselected, copyable text.
---
--- @param address string The URL or text to display.
function ArcaneWizardLibrary.Dialogs:ShowLinkDialog(address)
	StaticPopup_Show("ARCANE_WIZARD_LIB_LINK", nil, nil, address)
end

--- Shows a standard confirmation dialog with 'Yes' and 'No' buttons.
---
--- @param text string The question or message to display in the dialog.
--- @param onConfirmCallback function The function to execute if the user clicks "Yes".
--- @param onCancelCallback? function (Optional) The function to execute if the user clicks "No".
function ArcaneWizardLibrary.Dialogs:ShowConfirmDialog(text, onConfirmCallback, onCancelCallback)
	local callbacks = {
		onAccept = onConfirmCallback,
		onCancel = onCancelCallback
	}

	StaticPopup_Show("ARCANE_WIZARD_LIB_CONFIRM", text, nil, callbacks)
end
