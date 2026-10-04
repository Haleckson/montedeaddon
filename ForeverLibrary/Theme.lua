local _, A = ...
A.panels = {}

function A.StylePanel(panel, flat)
    panel.libraryFlat = flat
    panel:SetBackdrop({bgFile=flat and "Interface\\Buttons\\WHITE8X8" or "Interface\\FrameGeneral\\UI-Background-Marble", tile=not flat, tileSize=256, insets={left=0,right=0,top=0,bottom=0}})
    if not flat then
        panel.classicLight=panel:CreateTexture(nil,"BACKGROUND",nil,1)
        panel.classicLight:SetAllPoints()
        panel.classicLight:SetColorTexture(0.85,0.76,0.58,0.12)
    end
    A.panels[#A.panels+1] = panel
end

function A.ApplyTheme()
    local dark = A.db.darkSkin == true
    for _, panel in ipairs(A.panels) do
        if panel.libraryFlat then
            if dark then panel:SetBackdropColor(0,0,0,0.28)
            else panel:SetBackdropColor(0.18,0.12,0.05,0.12) end
        elseif dark then panel:SetBackdropColor(0.25,0.27,0.30,1)
        else panel:SetBackdropColor(1,0.94,0.80,1) end
        if panel.classicLight then panel.classicLight:SetShown(not dark) end
    end
    local function Tint(frame)
        if not frame or not frame.GetRegions then return end
        for _, region in ipairs({frame:GetRegions()}) do
            if region.GetObjectType and region:GetObjectType() == "Texture" then
                region:SetVertexColor(dark and 0.34 or 1, dark and 0.34 or 1, dark and 0.37 or 1)
            end
        end
    end
    for _, frame in ipairs({A.frame, A.rewardsFrame}) do
        if frame.TopTileStreaks then frame.TopTileStreaks:Hide() end
        Tint(frame.NineSlice)
        Tint(frame.TitleContainer)
        for _, key in ipairs({"TitleBg", "TopTileStreaks", "PortraitFrame", "TopRightCorner", "TopBorder", "BotLeftCorner", "BotRightCorner", "BottomBorder", "LeftBorder", "RightBorder"}) do
            local region=frame[key]
            if region and region.SetVertexColor then region:SetVertexColor(dark and 0.34 or 1,dark and 0.34 or 1,dark and 0.37 or 1) end
        end
        if frame.Bg then
            frame.Bg:SetTexture("Interface\\FrameGeneral\\UI-Background-Marble")
            frame.Bg:SetVertexColor(dark and 0.25 or 1,dark and 0.27 or 0.94,dark and 0.30 or 0.80)
        end
    end
    if A.frame.themeToggle then A.frame.themeToggle:SetText(dark and "Theme: dark" or "Theme: classic") end
end

function A.ToggleTheme()
    A.db.darkSkin = not A.db.darkSkin
    A.Refresh()
end
