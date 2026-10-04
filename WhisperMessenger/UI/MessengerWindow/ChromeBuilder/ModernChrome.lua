local addonName,ns=...
if type(ns)~="table"then
ns={}
end

local Theme=ns.Theme or require("WhisperMessenger.UI.Theme")
local WindowShadow=ns.MessengerWindowChromeBuilderWindowShadow or require("WhisperMessenger.UI.MessengerWindow.ChromeBuilder.WindowShadow")
local IconButtonStyle=ns.MessengerWindowChromeBuilderIconButtonStyle or require("WhisperMessenger.UI.MessengerWindow.ChromeBuilder.IconButtonStyle")
local UIHelpers=ns.UIHelpers or require("WhisperMessenger.UI.Helpers")
local applyColorTexture=UIHelpers.applyColorTexture
local applyVertexColor=UIHelpers.applyVertexColor
local setTextColor=UIHelpers.setTextColor

local Localization=ns.Localization or require("WhisperMessenger.Locale.Localization")

local ModernChrome={}



local function applyTitleStyle(title,theme,explicitTitle)
title:SetText(explicitTitle or theme.MODERN_TITLE)
UIHelpers.setFontObject(title,theme.FONTS.window_title)
end








function ModernChrome.Build(factory,frame,options,theme)
options=options or{}
theme=theme or Theme


local background=frame:CreateTexture(nil,"BACKGROUND")
background:SetAllPoints(frame)
applyColorTexture(background,theme.COLORS.bg_primary)
frame.background=background
local shadow=WindowShadow.Create(frame)


local edgeTextures=UIHelpers.createBorderBox(frame,theme.COLORS.window_border,theme.LAYOUT.DIVIDER_THICKNESS,"BORDER")


local titleBar=factory.CreateFrame("Frame",nil,frame)
titleBar:SetPoint("TOPLEFT",frame,"TOPLEFT",1,-1)
titleBar:SetPoint("TOPRIGHT",frame,"TOPRIGHT",-1,-1)
titleBar:SetHeight(theme.TOP_BAR_HEIGHT)
local titleBarBg=titleBar:CreateTexture(nil,"ARTWORK")
titleBarBg:SetAllPoints(titleBar)
applyColorTexture(titleBarBg,theme.COLORS.bg_header)
local titleSheen=UIHelpers.createSheen(titleBar,"ARTWORK",1)






local title=titleBar:CreateFontString(nil,"OVERLAY",theme.FONTS.header_name)
applyTitleStyle(title,theme,options.title)
setTextColor(title,theme.COLORS.text_title or theme.COLORS.text_primary)
frame.title=title


local closeButton=factory.CreateFrame("Button",nil,frame)
closeButton:SetSize(theme.LAYOUT.CHROME_BUTTON_SIZE,theme.LAYOUT.CHROME_BUTTON_SIZE)
local closeBg=closeButton:CreateTexture(nil,"BACKGROUND")
closeBg:SetAllPoints(closeButton)
IconButtonStyle.Attach(closeButton,closeBg)
local closeIcon=closeButton:CreateTexture(nil,"ARTWORK")
IconButtonStyle.SetGlyph(closeButton,closeIcon,theme.TEXTURES.title_close_icon)
closeIcon:SetSize(theme.LAYOUT.CHROME_BUTTON_ICON_SIZE,theme.LAYOUT.CHROME_BUTTON_ICON_SIZE)
closeIcon:SetPoint("CENTER",closeButton,"CENTER",0,0)
closeIcon:SetDesaturated(true)
local function applyCloseVisuals(hovered)
applyVertexColor(closeIcon,IconButtonStyle.Paint(closeButton,hovered,theme.COLORS,true))
end
applyCloseVisuals(false)
if closeButton.SetScript then
closeButton:SetScript("OnEnter",function()
applyCloseVisuals(true)
if _G.GameTooltip and _G.GameTooltip.SetOwner then
_G.GameTooltip:SetOwner(closeButton,"ANCHOR_TOP")
_G.GameTooltip:SetText(Localization.Text("Close"))
_G.GameTooltip:Show()
end
end)
closeButton:SetScript("OnLeave",function()
applyCloseVisuals(false)
if _G.GameTooltip and _G.GameTooltip.Hide then
_G.GameTooltip:Hide()
end
end)
end
closeButton:EnableMouse(true)

local function applyChromePaint(activeTheme)
theme=activeTheme
applyColorTexture(background,activeTheme.COLORS.bg_primary)
if titleBarBg then
applyColorTexture(titleBarBg,activeTheme.COLORS.bg_header)
end
applyTitleStyle(title,activeTheme,options.title)
UIHelpers.applySheen(titleSheen)
setTextColor(title,activeTheme.COLORS.text_title or activeTheme.COLORS.text_primary)
if edgeTextures then
UIHelpers.applyBorderBoxColor(edgeTextures,activeTheme.COLORS.window_border)
end
applyCloseVisuals(closeButton:IsMouseOver())
end

return{
background=background,
title=title,
closeButton=closeButton,
applyChromePaint=applyChromePaint,
titleBar=titleBar,
shadow=shadow,
}
end

ns.MessengerWindowChromeBuilderModern=ModernChrome

return ModernChrome
