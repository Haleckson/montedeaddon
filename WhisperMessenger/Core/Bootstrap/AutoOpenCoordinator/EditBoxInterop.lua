local addonName,ns=...
if type(ns)~="table"then
ns={}
end

local EditBoxInterop={}





local combatDraftBoxes={}
function EditBoxInterop.readEditBoxState(editBox,key)
if type(editBox.GetAttribute)=="function"then
local attribute=editBox:GetAttribute(key)
if attribute~=nil and attribute~=""then
return attribute
end
end

local direct=editBox[key]
if direct~=nil and direct~=""then
return direct
end

return nil
end

local function readEditBoxText(editBox)
if type(editBox)=="table"and type(editBox.GetText)=="function"then
local ok,text=pcall(editBox.GetText,editBox)

if not ok then
return nil
end
return text or""
end
return""
end

function EditBoxInterop.markCombatDraft(editBox)
local chatType=EditBoxInterop.readEditBoxState(editBox,"chatType")
if chatType~="WHISPER"and chatType~="BN_WHISPER"then
return
end

local typed=readEditBoxText(editBox)

if typed==nil or typed~=""then
combatDraftBoxes[editBox]=true
end
end

function EditBoxInterop.shouldPreserveCombatDraft(editBox)
if type(editBox)~="table"then
return false
end

local typed=readEditBoxText(editBox)

if typed==""then
combatDraftBoxes[editBox]=nil
return false
end

if not combatDraftBoxes[editBox]then
return false
end

local chatType=EditBoxInterop.readEditBoxState(editBox,"chatType")
if chatType=="WHISPER"or chatType=="BN_WHISPER"then
return true
end

combatDraftBoxes[editBox]=nil
return false
end

function EditBoxInterop.closeEditBox(runtime,editBox,deactivateChat,composerTextOverride)
local typed=readEditBoxText(editBox)
local composerText=typed
if composerTextOverride~=nil then
composerText=composerTextOverride
end


if composerText~=nil and composerText~=""and runtime.setComposerText then
runtime.setComposerText(composerText)
end










if type(editBox.SetAttribute)=="function"then
local stickyType=EditBoxInterop.readEditBoxState(editBox,"stickyType")
if stickyType=="WHISPER"or stickyType=="BN_WHISPER"then
pcall(editBox.SetAttribute,editBox,"chatType","SAY")
pcall(editBox.SetAttribute,editBox,"stickyType","SAY")
pcall(editBox.SetAttribute,editBox,"tellTarget",nil)
elseif stickyType then
pcall(editBox.SetAttribute,editBox,"chatType",stickyType)
pcall(editBox.SetAttribute,editBox,"tellTarget",nil)
end
end



if typed~=nil then
pcall(editBox.SetText,editBox,"")
end
combatDraftBoxes[editBox]=nil

if type(deactivateChat)=="function"then
deactivateChat(editBox)
elseif editBox.Hide then
editBox:Hide()
end
end

function EditBoxInterop.findBattleNetAccountInfo(target,bnetApi,getNumFriends)
if not bnetApi or not bnetApi.GetFriendAccountInfo then
return nil
end

local numFriends=type(getNumFriends)=="function"and getNumFriends()or 0
for friendIndex=1,numFriends do
local accountInfo=bnetApi.GetFriendAccountInfo(friendIndex)
if accountInfo then
local characterName=accountInfo.gameAccountInfo and accountInfo.gameAccountInfo.characterName
local battleTag=accountInfo.battleTag
local battleTagBase=battleTag and string.match(battleTag,"^([^#]+)")
local accountName=accountInfo.accountName
if
(characterName and characterName==target)
or(battleTag and battleTag==target)
or(battleTagBase and battleTagBase==target)
or(accountName and accountName==target)
then
return accountInfo
end
end
end

return nil
end

function EditBoxInterop.interceptEditBox(runtime,hooks,deps,editBox)
if EditBoxInterop.shouldPreserveCombatDraft(editBox)then
return false
end

local chatType=EditBoxInterop.readEditBoxState(editBox,"chatType")
local target=EditBoxInterop.readEditBoxState(editBox,"tellTarget")

if chatType=="BN_WHISPER"and target then
local opened=false
pcall(function()
local accountInfo=EditBoxInterop.findBattleNetAccountInfo(target,deps.bnetApi,deps.getNumFriends)
if not accountInfo then
return
end
local conversationKey=deps.ensureBattleNetConversation(runtime,deps.identity,accountInfo)
if conversationKey and hooks.onOutgoingWhisper(conversationKey)then
opened=true
end
end)
if opened then
EditBoxInterop.closeEditBox(runtime,editBox,deps.deactivateChat)
end
return true
end

if chatType=="WHISPER"and target and target~=""then
if hooks.onSendTell(target)then
EditBoxInterop.closeEditBox(runtime,editBox,deps.deactivateChat)
end
return true
end

return false
end

function EditBoxInterop.findFocusedEditBox(deps)
for index=1,deps.getNumChatWindows()do
local editBox=deps.getEditBox(index)
if editBox and type(editBox.HasFocus)=="function"then



local ok,focused=pcall(function()
if editBox:HasFocus()then
return true
end
return false
end)
if ok and focused then
return editBox
end
end
end
return nil
end

ns.BootstrapAutoOpenEditBoxInterop=EditBoxInterop

return EditBoxInterop
