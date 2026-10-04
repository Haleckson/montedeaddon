-- Generated from shared/ObsidianSkin.lua. Each addon remains independent.
-- ForeverIM intentionally uses flat edges; other addons retain artwork slices.
local addonName = ...
local Skin = {}
local flat = addonName == "ForeverIM"
_G[addonName .. "ObsidianSkin"] = Skin
local ART = "Interface\\AddOns\\" .. addonName .. "\\Art\\Cabinet.tga"
local registry = _G.WoWForeverAppearance or {}
_G.WoWForeverAppearance = registry
registry[addonName] = Skin
local savedName = addonName .. "AppearanceDB"
local backgrounds = setmetatable({}, {__mode="k"})
local frames = setmetatable({}, {__mode="k"})
function Skin.Variant()
    return (_G[savedName] or {}).variant or "obsidian"
end
local function Tint(texture)
    if Skin.Variant()=="forever" then texture:SetVertexColor(.30,.88,.92,1)
    else texture:SetVertexColor(1,1,1,1) end
end
function Skin.SetVariant(variant)
    if variant~="forever" and variant~="obsidian" then return end
    _G[savedName] = _G[savedName] or {}
    _G[savedName].variant=variant
    for texture in pairs(backgrounds) do Tint(texture) end
    for frame in pairs(frames) do
        frame.__foreverWash:SetColorTexture(.025,.26,.30,variant=="forever" and .72 or 0)
        if flat then
            for _,edge in ipairs(frame.__obsidianSlices or {}) do
                if variant=="forever" then edge:SetColorTexture(.15,.44,.48,.9)
                else edge:SetColorTexture(.38,.32,.22,.9) end
            end
        end
    end
end
function Skin.Background(texture)
    texture:SetTexture(ART)
    texture:SetTexCoord(.12,.88,.15,.85)
    backgrounds[texture]=true; Tint(texture)
end
function Skin.Apply(frame, cornerSize)
    if frame.__obsidianArt then Skin.SetShown(frame,true); return end
    -- Textures stay on the existing frame, below its text and interactive children.
    -- Nine slices keep the same corners on both tall books and wide chat windows.
    local background = frame:CreateTexture(nil,"BACKGROUND",nil,-7)
    background:SetAllPoints(); Skin.Background(background)
    frame.__obsidianArt = background
    local wash=frame:CreateTexture(nil,"BACKGROUND",nil,-6)
    wash:SetPoint("TOPLEFT",frame,"TOPLEFT",12,-12)
    wash:SetPoint("BOTTOMRIGHT",frame,"BOTTOMRIGHT",-12,12)
    frame.__foreverWash=wash;frames[frame]=true
    wash:SetColorTexture(.025,.26,.30,Skin.Variant()=="forever" and .72 or 0)
    frame.__obsidianSlices = {}
    if flat then
        local pixel = 1 / (frame:GetEffectiveScale() or 1)
        local function edge(a,b,horizontal)
            local t=frame:CreateTexture(nil,"BORDER",nil,7)
            if Skin.Variant()=="forever" then t:SetColorTexture(.15,.44,.48,.9)
            else t:SetColorTexture(.38,.32,.22,.9) end
            t:SetPoint(a,frame,a,0,0); t:SetPoint(b,frame,b,0,0)
            if horizontal then t:SetHeight(pixel) else t:SetWidth(pixel) end
            frame.__obsidianSlices[#frame.__obsidianSlices+1]=t
        end
        edge("TOPLEFT","TOPRIGHT",true); edge("BOTTOMLEFT","BOTTOMRIGHT",true)
        edge("TOPLEFT","BOTTOMLEFT",false); edge("TOPRIGHT","BOTTOMRIGHT",false)
        return
    end
    local function piece(coords,point,relative,relativePoint,x,y,w,h)
        local t=frame:CreateTexture(nil,"BORDER",nil,7)
        t:SetTexture(ART);t:SetTexCoord(unpack(coords))
        t:SetPoint(point,relative,relativePoint,x or 0,y or 0)
        if w then t:SetWidth(w) end
        if h then t:SetHeight(h) end
        frame.__obsidianSlices[#frame.__obsidianSlices+1]=t
        return t
    end
    local size=cornerSize or 32
    local tl=piece({0,.12,0,.15},"TOPLEFT",frame,"TOPLEFT",0,0,size,size)
    local tr=piece({.88,1,0,.15},"TOPRIGHT",frame,"TOPRIGHT",0,0,size,size)
    local bl=piece({0,.12,.85,.952},"BOTTOMLEFT",frame,"BOTTOMLEFT",0,0,size,size)
    local br=piece({.88,1,.85,.952},"BOTTOMRIGHT",frame,"BOTTOMRIGHT",0,0,size,size)
    local top=piece({.12,.88,0,.15},"TOPLEFT",tl,"TOPRIGHT",0,0,nil,size)
    top:SetPoint("TOPRIGHT",tr,"TOPLEFT")
    local bottom=piece({.12,.88,.85,.952},"BOTTOMLEFT",bl,"BOTTOMRIGHT",0,0,nil,size)
    bottom:SetPoint("BOTTOMRIGHT",br,"BOTTOMLEFT")
    local left=piece({0,.12,.15,.85},"TOPLEFT",tl,"BOTTOMLEFT",0,0,size,nil)
    left:SetPoint("BOTTOMLEFT",bl,"TOPLEFT")
    local right=piece({.88,1,.15,.85},"TOPRIGHT",tr,"BOTTOMRIGHT",0,0,size,nil)
    right:SetPoint("BOTTOMRIGHT",br,"TOPRIGHT")
end
function Skin.SetShown(frame,shown)
    if not frame.__obsidianArt then return end
    frame.__obsidianArt:SetShown(shown)
    frame.__foreverWash:SetShown(shown)
    -- The slices are saved separately so restoring other themes is immediate.
    for _,t in ipairs(frame.__obsidianSlices or {}) do t:SetShown(shown) end
end
-- One command updates every loaded participating addon and saves each preference.
if SlashCmdList then
    SLASH_WOWFOREVERAPPEARANCE1="/wowftheme"
    SlashCmdList.WOWFOREVERAPPEARANCE=function(message)
        local variant=string.lower((message or ""):match("^%s*(.-)%s*$"))
        if variant~="forever" and variant~="obsidian" then
            print("Forever appearance: /wowftheme forever or /wowftheme obsidian")
            return
        end
        for _,skin in pairs(registry) do skin.SetVariant(variant) end
        print("Forever appearance: "..variant.." (saved for all loaded addons)")
    end
end
if CreateFrame then
    local loader=CreateFrame("Frame")
    loader:RegisterEvent("ADDON_LOADED")
    loader:SetScript("OnEvent",function(_,_,name)
        if name==addonName then Skin.SetVariant(Skin.Variant());loader:UnregisterEvent("ADDON_LOADED") end
    end)
end
