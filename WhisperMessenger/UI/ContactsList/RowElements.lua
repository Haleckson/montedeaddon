local addonName,ns=...
if type(ns)~="table"then
ns={}
end

local Theme=ns.Theme or require("WhisperMessenger.UI.Theme")
local UIHelpers=ns.UIHelpers or require("WhisperMessenger.UI.Helpers")
local Badge=ns.Badge or require("WhisperMessenger.UI.Badge")
local ReactionAssets=ns.ChatBubbleReactionAssets or require("WhisperMessenger.UI.ChatBubble.ReactionAssets")
local Localization=ns.Localization or require("WhisperMessenger.Locale.Localization")
local RowMarkers=ns.ContactsListRowMarkers or require("WhisperMessenger.UI.ContactsList.RowMarkers")
local createCircularIcon=UIHelpers.createCircularIcon
local applyClassColor=UIHelpers.applyClassColor
local setTextColor=UIHelpers.setTextColor
local fitTextWithEllipsis=UIHelpers.fitTextWithEllipsis

local UNREAD_BADGE_SIZE=16
local UNREAD_BADGE_BOTTOM_OFFSET=12

local RowElements={}

local NAME_LABEL_LEFT_INSET=10
local NAME_TO_ICON_GAP=4
local NAME_TO_TIME_GAP=2
local TIME_LABEL_FALLBACK_WIDTH=14
local TIME_LABEL_RIGHT_INSET=6
local FACTION_ICON_RIGHT_PADDING=1
local PREVIEW_RIGHT_RESERVE=40

local function previewLabelWidth(parentWidth)
return parentWidth-Theme.LAYOUT.CONTACT_ICON_SIZE-Theme.LAYOUT.CONTACT_PADDING-PREVIEW_RIGHT_RESERVE
end

local function timestampReserveWidth(row)
local reserve=TIME_LABEL_RIGHT_INSET+TIME_LABEL_FALLBACK_WIDTH+NAME_TO_TIME_GAP
local timeLabel=row and row.timeLabel or nil
if timeLabel==nil then
return reserve
end

local liveWidth=0
if type(timeLabel.GetStringWidth)=="function"then
liveWidth=timeLabel:GetStringWidth()or 0
end
if liveWidth<=0 and type(timeLabel.GetWidth)=="function"then
liveWidth=timeLabel:GetWidth()or 0
end
if type(liveWidth)=="number"and liveWidth>0 then
reserve=TIME_LABEL_RIGHT_INSET+liveWidth+NAME_TO_TIME_GAP
end

return reserve
end

local function nameLabelWidth(row,parentWidth)
local mutedReserve=row.item and row.item.muted==true and RowMarkers.MUTED_RESERVE or 0
return math.max(
0,
(parentWidth or 0)
-Theme.LAYOUT.CONTACT_ICON_SIZE
-Theme.LAYOUT.CONTACT_PADDING
-NAME_LABEL_LEFT_INSET
-timestampReserveWidth(row)
-mutedReserve
)
end


local function rowName(item)
return item and(item.nickname or item.displayName)or""
end

function RowElements.updateNameLabel(row,item,parentWidth)
if row.title==nil then
return
end

local width=nameLabelWidth(row,parentWidth)
row.title:SetWidth(width)
row.title:SetText(fitTextWithEllipsis(row.title,rowName(item),width))
applyClassColor(row.title,item and item.classTag or nil,Theme.COLORS.text_primary)
end

function RowElements.createClassIcon(factory,row,item)
local icon=createCircularIcon(factory,row,Theme.LAYOUT.CONTACT_ICON_SIZE)
row.classIconFrame=icon.frame
row.classIcon=icon.texture
row.classIconFrame:SetPoint("LEFT",row,"LEFT",Theme.LAYOUT.CONTACT_PADDING,0)

local iconPath=Theme.ClassIcon(item.classTag)
if iconPath then
row.classIcon:SetTexture(iconPath)
else
row.classIcon:SetTexture(Theme.TEXTURES.bnet_icon)
end

return icon
end

function RowElements.createNameLabel(row,item,parentWidth)
local label=row:CreateFontString(nil,"OVERLAY",Theme.FONTS.contact_name)
label:SetPoint("TOPLEFT",row.classIconFrame,"TOPRIGHT",NAME_LABEL_LEFT_INSET,Theme.LAYOUT.CONTACT_NAME_OFFSET_Y)
label:SetWidth(nameLabelWidth(row,parentWidth))
label:SetJustifyH("LEFT")
label:SetWordWrap(false)
if label.SetMaxLines then
label:SetMaxLines(1)
end
row.title=label
RowElements.updateNameLabel(row,item,parentWidth)
return label
end



local function isPlayerFaction(faction)
local unitFactionGroup=_G.UnitFactionGroup
if type(unitFactionGroup)~="function"then
return false
end
return unitFactionGroup("player")==faction
end

function RowElements.updateFactionIcon(row,item,ns_ref)
if row.factionIcon==nil then
return
end

local inferredFaction=item.raceTag
and(ns_ref and ns_ref.Identity and ns_ref.Identity.InferFaction and ns_ref.Identity.InferFaction(item.raceTag))
or nil
local factionForIcon=inferredFaction or item.factionName
local reliableFaction=factionForIcon and Theme.FactionIcon(factionForIcon)or nil
if reliableFaction and isPlayerFaction(factionForIcon)then
reliableFaction=nil
end

local titleMaxWidth=row.title and row.title.GetWidth and row.title:GetWidth()or 0
local textBudget=titleMaxWidth
if reliableFaction then
textBudget=math.max(0,titleMaxWidth-Theme.LAYOUT.CONTACT_FACTION_SIZE-NAME_TO_ICON_GAP-FACTION_ICON_RIGHT_PADDING)
end
if row.title then
row.title:SetText(UIHelpers.fitTextWithEllipsis(row.title,rowName(item),textBudget))
applyClassColor(row.title,item.classTag,Theme.COLORS.text_primary)
end

local titleTextWidth=row.title and row.title.GetStringWidth and row.title:GetStringWidth()or 0
local textW=math.min(titleTextWidth,textBudget)
row.factionIcon:ClearAllPoints()
if row.title then
row.factionIcon:SetPoint("LEFT",row.title,"LEFT",textW+NAME_TO_ICON_GAP,0)
end

if reliableFaction then
row.factionIcon:SetTexture(reliableFaction)
row.factionIcon:Show()
else
row.factionIcon:Hide()
end
end

function RowElements.createFactionIcon(_factory,row,item,ns_ref)
local tex=row:CreateTexture(nil,"ARTWORK")
tex:SetSize(Theme.LAYOUT.CONTACT_FACTION_SIZE,Theme.LAYOUT.CONTACT_FACTION_SIZE)
row.factionIcon=tex

RowElements.updateFactionIcon(row,item,ns_ref)

return tex
end

function RowElements.updateTimestamp(row,item,ns_ref)
if row.timeLabel==nil then
return
end

if ns_ref and ns_ref.TimeFormat and ns_ref.TimeFormat.ContactPreview then
row.timeLabel:SetText(ns_ref.TimeFormat.ContactPreview(item.lastActivityAt))
else
row.timeLabel:SetText("")
end
end

function RowElements.createTimestamp(row,item,ns_ref)
local label=row:CreateFontString(nil,"OVERLAY",Theme.FONTS.contact_time)
label:SetPoint("TOPRIGHT",row,"TOPRIGHT",-TIME_LABEL_RIGHT_INSET,0)
if row.title then
label:SetPoint("TOP",row.title,"TOP",0,4)
end
setTextColor(label,Theme.COLORS.text_secondary)
row.timeLabel=label
RowElements.updateTimestamp(row,item,ns_ref)

return label
end



local function draftPreviewText(draft,hideMessagePreview)
local color=UIHelpers.colorEscape(Theme.COLORS.danger_text or Theme.COLORS.text_secondary)
if hideMessagePreview then
return color..Localization.Text("Draft").."|r"
end
return color..Localization.Text("Draft:").."|r "..ReactionAssets.FormatTextForDisplay(draft)
end



function RowElements.updatePreview(row,item,parentWidth,hideMessagePreview,selectedConversationKey)
if row.preview==nil then
return
end

row.preview:SetWidth(previewLabelWidth(parentWidth))


if item.isTyping then
setTextColor(row.preview,Theme.COLORS.online or Theme.COLORS.text_secondary)
row.preview:SetText(Localization.Text("typing…"))
return
end
setTextColor(row.preview,Theme.COLORS.text_secondary)
if item.draft~=nil and item.conversationKey~=selectedConversationKey then
row.preview:SetText(draftPreviewText(item.draft,hideMessagePreview))
return
end
row.preview:SetText(hideMessagePreview and""or ReactionAssets.FormatTextForDisplay(item.lastPreview))
end

function RowElements.createPreview(row,item,parentWidth)
local label=row:CreateFontString(nil,"OVERLAY",Theme.FONTS.contact_preview)
label:SetPoint("BOTTOMLEFT",row.classIconFrame,"BOTTOMRIGHT",NAME_LABEL_LEFT_INSET,Theme.LAYOUT.CONTACT_PREVIEW_OFFSET_Y)
setTextColor(label,Theme.COLORS.text_secondary)
label:SetWidth(previewLabelWidth(parentWidth))
label:SetJustifyH("LEFT")
label:SetWordWrap(false)
if label.SetMaxLines then
label:SetMaxLines(1)
end
row.preview=label
RowElements.updatePreview(row,item,parentWidth,false)
return label
end

function RowElements.updateLocation(row,item,parentWidth)
if row.location==nil then
return
end

local areaName=item and item.areaName or nil
if type(areaName)=="string"and areaName~=""then
row.location:SetWidth(previewLabelWidth(parentWidth))
row.location:SetText(areaName)
row.location:Show()
else
row.location:SetText("")
row.location:Hide()
end
end

function RowElements.createLocation(row,item,parentWidth)
local label=row:CreateFontString(nil,"OVERLAY",Theme.FONTS.contact_preview)
label:SetPoint("TOPLEFT",row.title,"BOTTOMLEFT",0,-1)
setTextColor(label,Theme.COLORS.text_timestamp)
label:SetWidth(previewLabelWidth(parentWidth))
label:SetJustifyH("LEFT")
label:SetWordWrap(false)
if label.SetMaxLines then
label:SetMaxLines(1)
end
row.location=label
RowElements.updateLocation(row,item,parentWidth)
return label
end

function RowElements.updateUnreadBadge(row,item)
if row.unreadBadge==nil then
return
end

row.unreadBadge.paint()
row.unreadBadge.setCount(item and item.unreadCount)
end

function RowElements.createUnreadBadge(factory,row)
local badge=Badge.Create(factory,row,{size=UNREAD_BADGE_SIZE})

badge.frame:SetPoint("BOTTOMRIGHT",row,"BOTTOMRIGHT",-TIME_LABEL_RIGHT_INSET,UNREAD_BADGE_BOTTOM_OFFSET)
row.unreadBadge=badge
return badge
end

RowElements.NAME_LABEL_LEFT_INSET=NAME_LABEL_LEFT_INSET

ns.ContactsListRowElements=RowElements
return RowElements
