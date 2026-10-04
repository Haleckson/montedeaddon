local addonName,ns=...
if type(ns)~="table"then
ns={}
end

local Theme=ns.Theme or require("WhisperMessenger.UI.Theme")
local UIHelpers=ns.UIHelpers or require("WhisperMessenger.UI.Helpers")
local Localization=ns.Localization or require("WhisperMessenger.Locale.Localization")




local HeaderContactExtras={}

local MUTED_ICON_SIZE=14
local NOTE_RIGHT_INSET=8

local NOTE_MAX_WIDTH_PCT=0.4
local NOTE_FALLBACK_WIDTH=200

local NOTE_GAP=12

local NOTE_MIN_WIDTH=60

local NAME_ROW_GAP=6

local function mutedIconEscape()
local color=Theme.COLORS.text_secondary or{1,1,1}
local function byte(value)
return math.floor((tonumber(value)or 1)*255+0.5)
end
return string.format(
"|T%s:%d:%d:0:0:64:64:0:64:0:64:%d:%d:%d|t",
Theme.TEXTURES.muted_icon,
MUTED_ICON_SIZE,
MUTED_ICON_SIZE,
byte(color[1]),
byte(color[2]),
byte(color[3])
)
end


function HeaderContactExtras.Title(selectedContact,baseTitle,isGroup)
local title=baseTitle or""
if not isGroup and selectedContact.nickname then
title=selectedContact.nickname.."  "..UIHelpers.colorEscape(Theme.COLORS.text_secondary)..title.."|r"
end
if selectedContact.muted==true then
title=title.." "..mutedIconEscape()
end
return title
end

local function showNoteTooltip(owner)
local tooltip=_G.GameTooltip
if tooltip==nil or type(tooltip.SetOwner)~="function"or owner._wmNote==nil then
return
end
tooltip:SetOwner(owner,"ANCHOR_BOTTOM")


pcall(tooltip.AddLine,tooltip,owner._wmNote,1,1,1,true)
tooltip:Show()
end

local function hideNoteTooltip()
local tooltip=_G.GameTooltip
if tooltip and type(tooltip.Hide)=="function"then
tooltip:Hide()
end
end


function HeaderContactExtras.Create(factory,view,headerFrame,headerName)
local note=headerFrame:CreateFontString(nil,"OVERLAY",Theme.FONTS.header_status)
note:SetJustifyH("RIGHT")
if type(note.SetWordWrap)=="function"then
note:SetWordWrap(false)
end
if type(note.SetMaxLines)=="function"then
note:SetMaxLines(1)
end
note:SetPoint("RIGHT",headerFrame,"RIGHT",-NOTE_RIGHT_INSET,0)
note:SetPoint("TOP",headerName,"TOP",0,0)
note:Hide()

local hitArea=factory.CreateFrame("Frame",nil,headerFrame)
hitArea:SetAllPoints(note)
if hitArea.EnableMouse then
hitArea:EnableMouse(true)
end
hitArea:SetScript("OnEnter",showNoteTooltip)
hitArea:SetScript("OnLeave",hideNoteTooltip)
hitArea:Hide()

view.headerNote=note
view.headerNoteHitArea=hitArea
end

local function isShown(region)
return region~=nil and type(region.IsShown)=="function"and region:IsShown()
end



local function nameRowRight(view)
local right=Theme.LAYOUT.TRANSCRIPT_LEFT_GUTTER+Theme.LAYOUT.HEADER_ICON_SIZE+Theme.LAYOUT.HEADER_NAME_GAP
if isShown(view.headerName)then
right=right+view.headerName:GetStringWidth()
end
for _,region in ipairs({view.headerFactionIcon,view.headerAddonBadgeButton})do
if isShown(region)then
right=right+NAME_ROW_GAP+region:GetWidth()
end
end
return right
end

local function hideNote(note,hitArea)
note:SetText("")
note:Hide()
hitArea:Hide()
end


function HeaderContactExtras.RefitNote(view)
local note,hitArea=view.headerNote,view.headerNoteHitArea
if note==nil then
return
end
local text=hitArea._wmNote
if text==nil then
hideNote(note,hitArea)
return
end
local headerWidth=type(view._headerWidth)=="number"and view._headerWidth>0 and view._headerWidth or nil
local maxWidth=NOTE_FALLBACK_WIDTH
if headerWidth then
local roomLeft=headerWidth-NOTE_RIGHT_INSET-NOTE_GAP-nameRowRight(view)
maxWidth=math.min(math.floor(headerWidth*NOTE_MAX_WIDTH_PCT),math.floor(roomLeft))
end


if maxWidth<NOTE_MIN_WIDTH then
hideNote(note,hitArea)
return
end
note:SetWidth(maxWidth)


local label=Localization.Text("Note:")
note:SetText(label.." ")
local labelWidth=type(note.GetStringWidth)=="function"and note:GetStringWidth()or 0
local fitted=UIHelpers.fitTextWithEllipsis(note,text,math.max(1,maxWidth-labelWidth))
local gold,primary=UIHelpers.colorEscape(Theme.TAG_GOLD),UIHelpers.colorEscape(Theme.COLORS.text_primary)
note:SetText(gold..label.."|r "..primary..fitted.."|r")
UIHelpers.applyColor(note,Theme.COLORS.text_primary)
note:Show()
hitArea:Show()
end

function HeaderContactExtras.Refresh(view,selectedContact,isGroup)
if view.headerNoteHitArea==nil then
return
end
view.headerNoteHitArea._wmNote=not isGroup and selectedContact and selectedContact.note or nil
HeaderContactExtras.RefitNote(view)
end

ns.ConversationPaneHeaderContactExtras=HeaderContactExtras
return HeaderContactExtras
