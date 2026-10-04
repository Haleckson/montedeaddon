-- Shared optional EllesmereUI integration. Only explicitly registered addon surfaces.
local addon = ...
local A = {}; _G[addon.."EllesmereStyle"] = A
local saved = addon.."AppearanceDB"
local roots = setmetatable({}, {__mode="k"})
local controls = setmetatable({}, {__mode="k"})
local facade, registered
local WHITE="Interface\\Buttons\\WHITE8X8"
local valid={auto=true,eui=true,forever=true,blizzard=true,classic=true,original=true}
function A.Mode()
    local options=_G.EllesmereUIDB
    if options and (options.thirdPartySkinsOff or (options.thirdPartySkinAddons and options.thirdPartySkinAddons[addon]==false)) then return "original" end
    local mode=(_G[saved] or {}).style or "auto"
    if mode~="auto" then return mode end
    local e=_G.EllesmereUI
    if not e then return "original" end
    local p=e.GetActiveProfileData and e.GetActiveProfileData()
    local look=p and p.windowSkinLook
    if not look and p then
        if p.charSheetUseClassicStyle then look="classic"
        elseif p.charSheetUseBlizzardStyle or p.charSheetUseForeverStyle then look="blizzard"
        else
            for _,v in pairs(p.addons or {}) do
                if type(v)=="table" and (v.useBlizzardStyle or v.useBlizzardStyleBars or v.useForeverStyle or v.useForeverStyleBars) then look="blizzard";break end
            end
        end
    end
    if look=="classic" then return "classic" end
    if look=="blizzard" then
        -- Forever shares Blizzard's window slot; its sibling flags identify the variant.
        if p.charSheetUseForeverStyle then return "forever" end
        for _,v in pairs(p.addons or {}) do
            if type(v)=="table" and (v.useForeverStyle or v.useForeverStyleBars) then return "forever" end
        end
        return "blizzard"
    end
    return "eui"
end
local palettes={
    eui={bg={.08,.08,.09,.98},edge={.35,.30,.25,1},accent={.77,.58,.40,1}},
    forever={bg={.035,.028,.018,.98},edge={.54,.39,.22,1},accent={.80,.65,.30,1}},
    blizzard={bg={.045,.045,.045,.98},edge={.5,.5,.5,1},accent={1,.82,0,1}},
    classic={bg={.10,.075,.04,.98},edge={.65,.55,.35,1},accent={1,.82,0,1}},
}
function A.Palette()
    local mode=A.Mode();local c=palettes[mode]
    if mode=="eui" and facade then
        if facade.GetPanelColor then c.bg={facade.GetPanelColor()} end
        if facade.GetAccentColor then c.accent={facade.GetAccentColor()};c.accent[4]=1 end
    end
    return c
end
-- Let the client lay out its artwork; copied atlas slices cannot safely be stretched.
local function NativeChrome(root)
    if not (CreateFrame and NineSliceUtil and NineSliceUtil.ApplyLayoutByName and NineSliceLayouts and NineSliceLayouts.ButtonFrameTemplate) then return false end
    if not root.__exstyleNativeBorder then
        local border=CreateFrame("Frame",nil,root,"NineSlicePanelTemplate")
        border:SetAllPoints(root);border:EnableMouse(false)
        border:SetFrameLevel(root:GetFrameLevel()+1)
        NineSliceUtil.ApplyLayoutByName(border,"ButtonFrameTemplate")
        root.__exstyleNativeBorder=border
    end
    root.__exstyleNativeBorder:Show()
    return true
end
local nativeButtonReference
local function NativeButton(control,role)
    if (role~="button" and role~="tab") or not control.SetNormalTexture then return false end
    for _,region in ipairs({control.edge,control.bg,control.hl}) do if region.Hide then region:Hide() end end
    if control.SetBackdrop then control:SetBackdrop(nil) end
    local selected=role=="tab" and control.__euiSelected
    control:SetNormalTexture("Interface\\Buttons\\UI-Panel-Button-"..(selected and "Down" or "Up"))
    control:SetPushedTexture("Interface\\Buttons\\UI-Panel-Button-Down")
    control:SetDisabledTexture("Interface\\Buttons\\UI-Panel-Button-Disabled")
    control:SetHighlightTexture("Interface\\Buttons\\UI-Panel-Button-Highlight","ADD")
    -- Obtain the texture crop from the client's template, including its transparent padding.
    if not nativeButtonReference and CreateFrame then
        nativeButtonReference=CreateFrame("Button",nil,UIParent,"UIPanelButtonTemplate")
        if nativeButtonReference.Hide then nativeButtonReference:Hide() end
    end
    -- Texture setters retain the asset's native size unless explicitly anchored.
    for _,getter in ipairs({"GetNormalTexture","GetPushedTexture","GetDisabledTexture","GetHighlightTexture"}) do
        local texture=control[getter] and control[getter](control)
        if texture then
            local source=nativeButtonReference and nativeButtonReference[getter] and nativeButtonReference[getter](nativeButtonReference)

            -- Legacy panel-button files contain unused transparent space.
            -- A modern UIPanelButton uses separate slices, so its full UV is not a usable crop here.
            if texture.SetTexCoord then texture:SetTexCoord(0,.625,0,.6875) end
            texture:ClearAllPoints();texture:SetAllPoints(control)
        end
    end
    return true
end
local function Font(label)
    if not label or not label.GetFont or not label.SetFont then return end
    local mode=A.Mode(); if mode=="original" then return end
    local _,size,flags=label:GetFont()
    local e=_G.EllesmereUI
    local path=mode=="eui" and e and e.GetFontPath and e.GetFontPath("blizzardSkin") or STANDARD_TEXT_FONT
    if path then label:SetFont(path,size or 12,flags or "") end
end
local function Paint(control,hover)
    if control.__exstyleSkip then return end
    local c=A.Palette(); if not c then return end
    local db=_G.EllesmereUIDB
    if db and (db.thirdPartySkinsOff or (db.thirdPartySkinAddons and db.thirdPartySkinAddons[addon]==false)) then return end
    local role=controls[control]
    local edge=role=="tab" and control.__euiSelected and c.accent or c.edge
    if A.Mode()=="eui" and facade then
        if role=="tab" then facade.Tab(control); if facade.SetTabSelection then facade.SetTabSelection(control,control.__euiSelected or false) end
        elseif role=="edit" then facade.EditBox(control)
        elseif role=="check" then facade.Checkbox(control)
        else facade.Button(control,{"Icon","icon"}); facade.StateButtonLabel(control) end
    elseif NativeButton(control,role) then
        -- Native textures supply normal, pressed, disabled and hover states.
    elseif control.edge and control.bg then
        control.edge:SetColorTexture(unpack(edge))
        control.bg:SetColorTexture(c.bg[1]+(hover and .06 or 0),c.bg[2]+(hover and .06 or 0),c.bg[3]+(hover and .06 or 0),1)
    elseif control.SetBackdrop then
        control:SetBackdrop({bgFile=WHITE,edgeFile=WHITE,edgeSize=1/(control:GetEffectiveScale() or 1)})
        control:SetBackdropColor(c.bg[1]+(hover and .06 or 0),c.bg[2]+(hover and .06 or 0),c.bg[3]+(hover and .06 or 0),1)
        control:SetBackdropBorderColor(unpack(edge))
    end
    local label=control.Text or control.label or control.title or (control.GetFontString and control:GetFontString())
    Font(label)
    if label and label.SetTextColor then label:SetTextColor(1,1,1,control.IsEnabled and not control:IsEnabled() and .45 or 1) end
end
function A.Control(control,role)
    if not control or A.Mode()=="original" then return end
    if not controls[control] then
        controls[control]=role or "button"
        if control.HookScript then
            control:HookScript("OnEnter",function() Paint(control,true) end)
            control:HookScript("OnLeave",function() Paint(control,false) end)
            control:HookScript("OnShow",function() Paint(control,false) end)
        end
    end
    controls[control]=role or controls[control] or "button"
    Paint(control,false)
end
function A.Selected(control,selected)
    control.__euiSelected=selected; Paint(control,false)
end
function A.Refresh(root)
    if root.__exstyleDisabled then return end
    local c=A.Palette(); if not c then return end
    -- Respect EllesmereUI's master and per-addon third-party opt-out.
    local db=_G.EllesmereUIDB
    if db and (db.thirdPartySkinsOff or (db.thirdPartySkinAddons and db.thirdPartySkinAddons[addon]==false)) then return end
    local obs=_G[addon.."ObsidianSkin"]
    if obs and root.__obsidianArt then obs.SetShown(root,false) end
    if A.Mode()=="eui" and facade then
        if root.__exstyleChrome then root.__exstyleChrome:Hide() end
        if root.__exstyleNativeBorder then root.__exstyleNativeBorder:Hide() end
        if root.__exstyleOpaque then root.__exstyleOpaque:Hide() end
        facade.Shell(root,{bottomBar=false})
    elseif root.SetBackdrop then
        -- Opaque underlay is independent of translucent client artwork.
        if root.CreateTexture then
            if not root.__exstyleOpaque then
                root.__exstyleOpaque=root:CreateTexture(nil,"BACKGROUND",nil,-8)
                root.__exstyleOpaque:SetAllPoints(root)
            end
            root.__exstyleOpaque:SetColorTexture(.035,.028,.018,1)
            root.__exstyleOpaque:Show()
        end
        local chrome=root.__exstyleChrome
        if not chrome and CreateFrame and root.GetFrameLevel then
            chrome=CreateFrame("Frame",nil,root,"BackdropTemplate")
            chrome:SetAllPoints(root);chrome:EnableMouse(false)
            chrome:SetFrameLevel(root:GetFrameLevel()+1)
            root.__exstyleChrome=chrome
        end
        chrome=chrome or root
        local native=NativeChrome(chrome)
        chrome:SetBackdrop({bgFile=chrome==root and "Interface\\DialogFrame\\UI-DialogBox-Background" or nil,edgeFile="Interface\\DialogFrame\\UI-DialogBox-Border",edgeSize=24,tile=true,tileSize=32,insets={left=6,right=6,top=6,bottom=6}})
        chrome:SetBackdropColor(1,1,1,1);chrome:SetBackdropBorderColor(1,1,1,1)
        if chrome~=root then root:SetBackdrop(nil);chrome:Show() end
    end
    local function Visit(frame)
        if frame.GetRegions then
            for _,r in ipairs({frame:GetRegions()}) do if r.IsObjectType and r:IsObjectType("FontString") then Font(r) end end
        end
        if not frame.GetChildren then return end
        for _,child in ipairs({frame:GetChildren()}) do
            if child.IsObjectType and child:IsObjectType("EditBox") then A.Control(child,"edit")
            elseif child.IsObjectType and child:IsObjectType("CheckButton") then A.Control(child,"check")
            elseif child.IsObjectType and child:IsObjectType("Button") and (child.Text or child.label or child.title or (child.GetText and child:GetText() and child:GetText()~="")) then A.Control(child,"button") end
            Visit(child)
        end
    end
    -- A native nine-slice may contain irregular shared atlas pieces and offsets.
    -- Do not clone it onto unrelated window geometry.
    for _,texture in pairs(root.__exstyleSlices or {}) do texture:Hide() end
    for _,texture in ipairs(root.__exstyleBackgrounds or {}) do texture:SetColorTexture(unpack(c.bg)) end
    Visit(root)
end
function A.Attach(root,reference)
    if not root or A.Mode()=="original" then return end
    if reference then root.__exstyleReference=reference end
    if not roots[root] then
        roots[root]=true
        if root.HookScript then root:HookScript("OnShow",function() A.Refresh(root) end) end
    end
    A.Refresh(root)
end
local function Register()
    local e=_G.EllesmereUI
    if registered or not (e and e.RegisterSkin) then return end
    registered=true
    e.RegisterSkin(addon,function(S)
        facade=S
        for root in pairs(roots) do A.Refresh(root) end
        if S.OnLooksChanged then S.OnLooksChanged(function() for root in pairs(roots) do A.Refresh(root) end end) end
    end)
end
Register()
if CreateFrame and EllesmereUI then
local events=CreateFrame("Frame")
events:RegisterEvent("ADDON_LOADED");events:RegisterEvent("PLAYER_LOGIN")
events:SetScript("OnEvent",function()
    Register()
    for root in pairs(roots) do A.Refresh(root) end
end)
end
local registry=_G.ExordiumsAddonStyles or {};_G.ExordiumsAddonStyles=registry;registry[addon]=A
if SlashCmdList then
    SLASH_EXORDIUMSSTYLE1="/exstyle"
    SlashCmdList.EXORDIUMSSTYLE=function(message)
        local mode=string.lower((message or ""):match("^%s*(.-)%s*$"))
        if not valid[mode] then print("Addon style: /exstyle auto, eui, forever, blizzard, classic, or original. Reload after changing styles.");return end
        for name in pairs(registry) do _G[name.."AppearanceDB"]=_G[name.."AppearanceDB"] or {};_G[name.."AppearanceDB"].style=mode end
        print("Addon style saved for all loaded Exordiums addons: "..mode..". /reload to apply.")
    end
end
