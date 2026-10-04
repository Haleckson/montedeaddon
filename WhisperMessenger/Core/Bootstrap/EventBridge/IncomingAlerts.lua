local addonName,ns=...
if type(ns)~="table"then
ns={}
end

local SoundPlayer=ns.SoundPlayer or require("WhisperMessenger.Core.SoundPlayer")



local IncomingAlerts={}


function IncomingAlerts.PlaySound(settings)
if type(settings)=="table"and settings.playSoundOnWhisper==true then
SoundPlayer.Play(settings)
end
end

function IncomingAlerts.Notify(settings)
if type(settings)~="table"then
return
end
IncomingAlerts.PlaySound(settings)



if settings.flashTaskbarOnWhisper~=false and type(_G.FlashClientIcon)=="function"then
_G.FlashClientIcon()
end
end

ns.BootstrapEventBridgeIncomingAlerts=IncomingAlerts
return IncomingAlerts
