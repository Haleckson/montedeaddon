MI2_DropDownMixin = {}

local LibDD = LibStub:GetLibrary("LibUIDropDownMenu-4.0")

function MI2_DropDownMixin:OnLoad()
    LibDD:Create_UIDropDownMenu(self)
    LibDD:UIDropDownMenu_SetInitializeFunction(self, MI2_DropDownMixin.Initialize)
    LibDD:UIDropDownMenu_SetWidth(self, 120 )
    MI2_OPTIONS[self:GetName()].dd = 1
end

function MI2_DropDownMixin:Initialize()

	local dropDownName = self:GetName()
	local choice = MI2_OPTIONS[dropDownName].choice1
	local count = 1

	while choice do
		local info = { text = choice, value = count, func = _G[dropDownName.."_OnClick"] }
		LibDD:UIDropDownMenu_AddButton( info )
		count = count + 1
		choice = MI2_OPTIONS[dropDownName]["choice"..count]
	end
end

function MI2_DropDownMixin:OnShow()
	local frameName = self:GetName()
	local itemName = string.sub(frameName, 8)
	local text=MI2_OPTIONS[frameName]["choice"..MobInfoConfig[itemName]]

	LibDD:UIDropDownMenu_SetSelectedID( self, MobInfoConfig[itemName] )
	LibDD:UIDropDownMenu_SetText( self, text )
end
