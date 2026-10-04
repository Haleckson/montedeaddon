ArcaneWizardLibrary_SettingsPanelTextMixin = {}

function ArcaneWizardLibrary_SettingsPanelTextMixin:Init(initializer)
	local data = initializer:GetData()
	self.LeftText:SetTextToFit(data.leftText)
	self.RightText:SetTextToFit(data.rightText)
end

ArcaneWizardLibrary_SettingsSeparatorMixin = {}

function ArcaneWizardLibrary_SettingsSeparatorMixin:Init(initializer)
	local data = initializer:GetData()
	-- Keep texture filtering inside each atlas slice, away from transparent neighbors.
	local inset = data.texCoordInset
	for _, texture in ipairs({ self.Left, self.LeftLine, self.Center, self.RightLine, self.Right }) do
		texture:ClearAllPoints()
		texture:SetTexture(data.texture)
		texture:SetDesaturated(true)
		texture:SetVertexColor(data.brightness, data.brightness, data.brightness)
		texture:SetHeight(data.textureHeight)
	end

	self.Left:SetWidth(data.capWidth)
	self.Left:SetTexCoord(inset, 0.25 - inset, 0, 1)
	self.Left:SetPoint("LEFT", self, "LEFT", data.leftInset, 0)

	self.Right:SetWidth(data.capWidth)
	self.Right:SetTexCoord(0.75 + inset, 1 - inset, 0, 1)
	self.Right:SetPoint("RIGHT", self, "RIGHT", -data.rightInset, 0)

	self.Center:SetWidth(data.centerWidth)
	self.Center:SetTexCoord(0.5 + inset, 0.75 - inset, 0, 1)
	self.Center:SetPoint("CENTER", self, "CENTER", (data.leftInset - data.rightInset) / 2, 0)

	self.LeftLine:SetTexCoord(0.25 + inset, 0.5 - inset, 0, 1)
	self.LeftLine:SetPoint("LEFT", self.Left, "RIGHT")
	self.LeftLine:SetPoint("RIGHT", self.Center, "LEFT")

	self.RightLine:SetTexCoord(0.25 + inset, 0.5 - inset, 0, 1)
	self.RightLine:SetPoint("LEFT", self.Center, "RIGHT")
	self.RightLine:SetPoint("RIGHT", self.Right, "LEFT")
end

ArcaneWizardLibrary_SettingsExpandMixin = CreateFromMixins(SettingsExpandableSectionMixin)

function ArcaneWizardLibrary_SettingsExpandMixin:Init(initializer)
	SettingsExpandableSectionMixin.Init(self, initializer)
	self.data = initializer.data
end

function ArcaneWizardLibrary_SettingsExpandMixin:CalculateHeight()
	return 30
end

function ArcaneWizardLibrary_SettingsExpandMixin:OnExpandedChanged(expanded)
	if self.data then
		self.data.expanded = expanded
	end

	self:EvaluateVisibility(expanded)
	SettingsInbound.RepairDisplay()
end

function ArcaneWizardLibrary_SettingsExpandMixin:EvaluateVisibility(expanded)
	if expanded then
		self.Button.Right:SetAtlas("Options_ListExpand_Right_Expanded", TextureKitConstants.UseAtlasSize)
	else
		self.Button.Right:SetAtlas("Options_ListExpand_Right", TextureKitConstants.UseAtlasSize)
	end
end
