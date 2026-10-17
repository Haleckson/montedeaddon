-- ForeverBrowser theme module v1.211. Load BEFORE ForeverBrowser.lua.
local WOW_THEME
local CreateSolidBackground,CopyThemeIntoActive,RegisterThemeVisual,ThemeColor,ResolveThemeModelDisplay,ApplyRegisteredThemeVisuals,SaveForeverTheme,LoadForeverTheme,AddWoWBorder,MakeEdge,AddWoWPanelTexture,AddWoWInset,AddWoWDivider,AddWoWCornerOrnaments,AddWoWHeaderAccent,AddWoWIconFrame,AddWoWSoftGlow,CreateWoWMedallion,CreateWoWBanner,CreateWoWCategoryTile,CreateWoWSectionRibbon,CreateLabel,CreateButton
function CreateSolidBackground(
    parent,
    r,
    g,
    b,
    a
)

    if r and g and b and math.max(r,g,b)<=0.15 then
        local c=WOW_THEME.panel or {0.045,0.038,0.029}
        r,g,b=c[1],c[2],c[3]
    end

    local texture =
        parent:CreateTexture(
            nil,
            "BACKGROUND"
        )


    texture:SetAllPoints(
        parent
    )


    texture:SetTexture(
        "Interface\\Buttons\\WHITE8X8"
    )


    texture:SetVertexColor(
        r or 0,
        g or 0,
        b or 0,
        a or 1
    )


    if type(ForeverBrowser_CodexSurface196)=="function" then
        ForeverBrowser_CodexSurface196(parent)
    end
    return texture
end


--------------------------------------------------
-- WORLD OF WARCRAFT VISUAL THEME
-- Presentation only: no database/navigation logic.
--------------------------------------------------

WOW_THEME = {
    gold = {1.00, 0.82, 0.22, 1},
    goldSoft = {0.82, 0.66, 0.30, 1},
    goldDim = {0.38, 0.27, 0.10, 1},
    ivory = {0.92, 0.86, 0.72, 1},
    muted = {0.62, 0.57, 0.48, 1},
    black = {0.010, 0.009, 0.008, 1},
    panel = {0.035, 0.026, 0.018, 0.98},
    inset = {0.018, 0.015, 0.012, 0.98},
    hover = {0.13, 0.085, 0.028, 1},
}

--------------------------------------------------
-- FOREVERBROWSER THEME ENGINE
--------------------------------------------------

local FOREVER_THEMES = {
    Classic = {
        displayName="Classic / Azeroth", themeTitle="AZEROTH", themeModelNPC=10667, themeModelNPC2=7999, themeModelNPCs1={10667,14720,7999,68}, themeModelNPCs2={7999,14721,68,4949}, modelScale1=0.38, modelScale2=0.36, modelZ1=0.00, modelZ2=0.00, themeSub="ADVENTURER'S CODEX", heroSymbol="Interface\\Icons\\INV_Misc_Spyglass_03",
        backdrop={0.20,0.15,0.10,0.98}, title={0.040,0.026,0.016,1},
        toolbar={0.020,0.016,0.012,0.98}, button={0.045,0.032,0.020,0.98},
        row={0.032,0.024,0.016,0.94}, watermark={0.72,0.52,0.18,0.055},
        gold={1.00,0.82,0.22,1}, goldSoft={0.82,0.66,0.30,1},
        goldDim={0.38,0.27,0.10,1}, ivory={0.92,0.86,0.72,1},
        muted={0.62,0.57,0.48,1}, black={0.010,0.009,0.008,1},
        panel={0.035,0.026,0.018,0.98}, inset={0.018,0.015,0.012,0.98},
        hover={0.13,0.085,0.028,1}, accent={0.72,0.52,0.18,1},
        icon="Interface\\Icons\\INV_Misc_Book_09",
        visualLeft="Interface\\Icons\\INV_Misc_Map_01",
        visualRight="Interface\\Icons\\INV_Misc_Book_11",
        visualCorner="Interface\\Icons\\INV_Misc_Compass_01",
        visualAlpha=0.22,
    },
    Halloween = {
        displayName="Hallow's End", themeTitle="HALLOW'S END", themeModelNPC=23682, themeModelNPC2=23543, themeModelNPCs1={23682,23543,23686,23679,13445}, themeModelNPCs2={23543,23686,23679,23682,13444}, modelScale1=0.38, modelScale2=0.36, modelZ1=0.00, modelZ2=0.00, themeSub="BEWARE THE SHADOWS", heroSymbol="Interface\\Icons\\INV_Misc_Bag_28_Halloween",
        backdrop={0.12,0.025,0.12,0.99}, title={0.075,0.012,0.070,1},
        toolbar={0.035,0.008,0.040,0.99}, button={0.11,0.025,0.10,0.98},
        row={0.065,0.015,0.070,0.95}, watermark={1.00,0.28,0.03,0.090},
        gold={1.00,0.48,0.08,1}, goldSoft={0.88,0.38,0.10,1},
        goldDim={0.42,0.16,0.05,1}, ivory={0.95,0.80,0.58,1},
        muted={0.68,0.52,0.62,1}, black={0.012,0.006,0.015,1},
        panel={0.055,0.018,0.055,0.98}, inset={0.020,0.008,0.024,0.98},
        hover={0.24,0.07,0.18,1}, accent={0.95,0.28,0.05,1},
        icon="Interface\\Icons\\INV_Misc_Bag_28_Halloween",
        visualLeft="Interface\\Icons\\INV_Misc_Bag_28_Halloween",
        visualRight="Interface\\Icons\\INV_Misc_Food_59",
        visualCorner="Interface\\Icons\\Spell_Shadow_Possession",
        visualAlpha=0.34,
    },
    WinterVeil = {
        displayName="Winter Veil", themeTitle="WINTER VEIL", themeModelNPC=13445, themeModelNPC2=13444, themeModelNPCs1={13445,15732,13444,15664}, themeModelNPCs2={13444,15664,15732,13445}, modelScale1=0.38, modelScale2=0.36, modelZ1=0.00, modelZ2=0.00, themeSub="FEAST OF WINTER VEIL", heroSymbol="Interface\\Icons\\INV_Holiday_Christmas_Present_01",
        backdrop={0.025,0.13,0.075,0.99}, title={0.18,0.025,0.025,1},
        toolbar={0.025,0.085,0.055,0.99}, button={0.12,0.025,0.025,0.98},
        row={0.025,0.080,0.050,0.95}, watermark={0.90,1.00,0.95,0.075},
        gold={1.00,0.86,0.38,1}, goldSoft={0.82,0.92,0.90,1},
        goldDim={0.34,0.45,0.36,1}, ivory={0.96,0.96,0.91,1},
        muted={0.68,0.78,0.74,1}, black={0.008,0.018,0.014,1},
        panel={0.025,0.075,0.048,0.98}, inset={0.012,0.030,0.022,0.98},
        hover={0.20,0.045,0.035,1}, accent={0.78,0.12,0.10,1},
        icon="Interface\\Icons\\INV_Holiday_Christmas_Present_01",
        visualLeft="Interface\\Icons\\INV_Holiday_Christmas_Present_01",
        visualRight="Interface\\Icons\\INV_Holiday_Christmas_Present_02",
        visualCorner="Interface\\Icons\\Spell_Frost_Frost",
        visualAlpha=0.32,
    },
    Alliance = {
        displayName="Alliance", themeTitle="ALLIANCE", themeModelNPC=29611, themeModelNPC2=1748, themeModelNPCs1={29611,1748,2784,7999}, themeModelNPCs2={1748,2784,29611,14721}, modelScale1=0.38, modelScale2=0.36, modelZ1=0.00, modelZ2=0.00, themeSub="FOR THE ALLIANCE", heroSymbol="Interface\\TargetingFrame\\UI-PVP-Alliance",
        backdrop={0.025,0.085,0.20,0.99}, title={0.020,0.060,0.18,1},
        toolbar={0.018,0.050,0.14,0.99}, button={0.025,0.075,0.19,0.98},
        row={0.018,0.055,0.15,0.95}, watermark={0.20,0.48,1.00,0.075},
        gold={1.00,0.82,0.22,1}, goldSoft={0.72,0.82,1.00,1},
        goldDim={0.24,0.35,0.58,1}, ivory={0.90,0.93,1.00,1},
        muted={0.58,0.67,0.82,1}, black={0.008,0.014,0.030,1},
        panel={0.025,0.060,0.135,0.98}, inset={0.010,0.025,0.070,0.98},
        hover={0.055,0.14,0.30,1}, accent={0.20,0.48,0.95,1},
        icon="Interface\\Icons\\INV_BannerPVP_02",
        visualLeft="Interface\\Icons\\INV_BannerPVP_02",
        visualRight="Interface\\Icons\\Ability_Warrior_BattleShout",
        visualCorner="Interface\\Icons\\INV_Shield_06",
        visualAlpha=0.30,
    },
    Horde = {
        displayName="Horde", themeTitle="HORDE", themeModelNPC=4949, themeModelNPC2=3057, themeModelNPCs1={4949,3057,10181,14720}, themeModelNPCs2={3057,4949,10181,14720}, modelScale1=0.38, modelScale2=0.36, modelZ1=0.00, modelZ2=0.00, themeSub="FOR THE HORDE", heroSymbol="Interface\\TargetingFrame\\UI-PVP-Horde",
        backdrop={0.16,0.025,0.020,0.99}, title={0.13,0.012,0.010,1},
        toolbar={0.085,0.012,0.010,0.99}, button={0.14,0.020,0.015,0.98},
        row={0.085,0.012,0.010,0.95}, watermark={0.90,0.08,0.04,0.075},
        gold={0.92,0.62,0.22,1}, goldSoft={0.92,0.66,0.40,1},
        goldDim={0.44,0.20,0.12,1}, ivory={0.92,0.82,0.70,1},
        muted={0.66,0.52,0.47,1}, black={0.020,0.006,0.006,1},
        panel={0.110,0.020,0.018,0.98}, inset={0.045,0.008,0.008,0.98},
        hover={0.25,0.035,0.025,1}, accent={0.78,0.08,0.05,1},
        icon="Interface\\Icons\\INV_BannerPVP_01",
        visualLeft="Interface\\Icons\\INV_BannerPVP_01",
        visualRight="Interface\\Icons\\Ability_Warrior_WarCry",
        visualCorner="Interface\\Icons\\INV_Axe_09",
        visualAlpha=0.30,
    },
    Fel = {
        displayName="Fel", themeTitle="FEL", themeModelNPC=18728, themeModelNPC2=11859, themeModelNPCs1={18728,14509,11859,8716}, themeModelNPCs2={11859,8716,14509,18728}, modelScale1=0.34, modelScale2=0.33, modelZ1=0.00, modelZ2=0.00, themeSub="CHAOTIC DEMONIC ENERGY", heroSymbol="Interface\\Icons\\Spell_Shadow_RainOfFire",
        backdrop={0.025,0.12,0.012,0.99}, title={0.018,0.070,0.008,1},
        toolbar={0.012,0.050,0.006,0.99}, button={0.025,0.11,0.012,0.98},
        row={0.015,0.070,0.008,0.95}, watermark={0.32,1.00,0.06,0.090},
        gold={0.48,1.00,0.12,1}, goldSoft={0.68,0.95,0.42,1},
        goldDim={0.18,0.40,0.08,1}, ivory={0.82,0.94,0.72,1},
        muted={0.48,0.68,0.42,1}, black={0.005,0.014,0.004,1},
        panel={0.020,0.060,0.015,0.98}, inset={0.008,0.026,0.006,0.98},
        hover={0.075,0.20,0.035,1}, accent={0.32,0.92,0.08,1},
        icon="Interface\\Icons\\Spell_Shadow_RainOfFire",
        visualLeft="Interface\\Icons\\Spell_Shadow_RainOfFire",
        visualRight="Interface\\Icons\\Spell_Fire_FelFlameRing",
        visualCorner="Interface\\Icons\\Spell_Shadow_DemonBreath",
        visualAlpha=0.34,
    },
    Scourge = {
        displayName="Scourge", themeTitle="SCOURGE", themeModelNPC=0, themeModelNPC2=0, themeModelNPCs1={0}, themeModelNPCs2={0}, themeDisplay1=137, themeDisplay2=16213, modelScale1=0.36, modelScale2=0.36, modelZ1=0.00, modelZ2=0.00, themeSub="THE FROZEN DEAD", heroSymbol="Interface\\Icons\\Spell_Shadow_AnimateDead",
        backdrop={0.018,0.085,0.12,0.99}, title={0.012,0.055,0.085,1},
        toolbar={0.010,0.040,0.060,0.99}, button={0.020,0.080,0.11,0.98},
        row={0.012,0.055,0.080,0.95}, watermark={0.20,0.80,1.00,0.085},
        gold={0.48,0.86,1.00,1}, goldSoft={0.70,0.88,0.94,1},
        goldDim={0.18,0.38,0.48,1}, ivory={0.86,0.94,0.96,1},
        muted={0.52,0.68,0.72,1}, black={0.005,0.014,0.020,1},
        panel={0.020,0.050,0.070,0.98}, inset={0.008,0.022,0.032,0.98},
        hover={0.035,0.14,0.19,1}, accent={0.20,0.72,0.92,1},
        icon="Interface\\Icons\\Spell_Shadow_AnimateDead",
        visualLeft="Interface\\Icons\\Spell_Shadow_AnimateDead",
        visualRight="Interface\\Icons\\Spell_Frost_FrostNova",
        visualCorner="Interface\\Icons\\Spell_Shadow_RaiseDead",
        visualAlpha=0.34,
    },
    Arcane = {
        displayName="Arcane", themeTitle="ARCANE", themeModelNPC=19644, themeModelNPC2=4275, themeModelNPCs1={19644,7999,4275,14721}, themeModelNPCs2={4275,14721,7999,19644}, modelScale1=0.38, modelScale2=0.36, modelZ1=0.00, modelZ2=0.00, themeSub="MYSTERIES OF MAGIC", heroSymbol="Interface\\Icons\\Spell_Arcane_Arcane01",
        backdrop={0.075,0.025,0.16,0.99}, title={0.055,0.015,0.13,1},
        toolbar={0.040,0.010,0.095,0.99}, button={0.075,0.025,0.16,0.98},
        row={0.050,0.015,0.115,0.95}, watermark={0.66,0.28,1.00,0.090},
        gold={0.76,0.52,1.00,1}, goldSoft={0.72,0.70,1.00,1},
        goldDim={0.32,0.20,0.52,1}, ivory={0.91,0.86,1.00,1},
        muted={0.62,0.56,0.78,1}, black={0.012,0.008,0.025,1},
        panel={0.050,0.025,0.105,0.98}, inset={0.020,0.010,0.050,0.98},
        hover={0.13,0.055,0.25,1}, accent={0.58,0.26,0.96,1},
        icon="Interface\\Icons\\Spell_Arcane_Arcane01",
        visualLeft="Interface\\Icons\\Spell_Arcane_Arcane01",
        visualRight="Interface\\Icons\\Spell_Arcane_PortalDalaran",
        visualCorner="Interface\\Icons\\Spell_Nature_StarFall",
        visualAlpha=0.34,
    },
    Dark = {
        displayName="Dark / Minimal", themeTitle="DARK", themeModelNPC=68, themeModelNPC2=0, themeModelNPCs1={68,7999,14720}, themeModelNPCs2={0}, modelScale1=0.38, modelScale2=0.36, modelZ1=0.00, modelZ2=0.00, themeSub="MINIMAL DATABASE", heroSymbol="Interface\\Icons\\INV_Misc_Book_11",
        backdrop={0.018,0.018,0.018,0.995}, title={0.012,0.012,0.012,1},
        toolbar={0.018,0.018,0.018,0.99}, button={0.040,0.040,0.040,0.98},
        row={0.025,0.025,0.025,0.95}, watermark={0.50,0.50,0.50,0.025},
        gold={0.78,0.78,0.78,1}, goldSoft={0.68,0.68,0.68,1},
        goldDim={0.30,0.30,0.30,1}, ivory={0.88,0.88,0.88,1},
        muted={0.52,0.52,0.52,1}, black={0.006,0.006,0.006,1},
        panel={0.025,0.025,0.025,0.99}, inset={0.012,0.012,0.012,0.99},
        hover={0.085,0.085,0.085,1}, accent={0.48,0.48,0.48,1},
        icon="Interface\\Icons\\INV_Misc_Book_11",
        visualLeft="Interface\\Icons\\INV_Misc_Book_11",
        visualRight="Interface\\Icons\\INV_Misc_Book_11",
        visualCorner="Interface\\Icons\\INV_Misc_Book_11",
        visualAlpha=0.06,
    },
}

FOREVER_THEMES.Codex = {
    displayName="Codex",themeTitle="AZEROTH CODEX",themeSub="ADVENTURER'S CODEX",
    backdrop={0.12,0.09,0.055,1},title={0.035,0.025,0.014,1},
    toolbar={0.025,0.022,0.017,1},button={0.055,0.045,0.033,1},
    row={0.055,0.045,0.033,1},panel={0.045,0.038,0.029,1},inset={0.025,0.022,0.017,1},
    black={0.018,0.015,0.012,1},gold={1,0.82,0.28,1},goldSoft={0.90,0.72,0.29,1},
    goldDim={0.40,0.29,0.12,1},ivory={0.92,0.86,0.72,1},text={0.92,0.86,0.72,1},
    muted={0.72,0.66,0.54,1},hover={0.12,0.09,0.045,1},accent={0.90,0.72,0.29,1},
    watermark={0.72,0.52,0.18,0.055},icon="Interface\\Icons\\INV_Misc_Book_09",
    heroSymbol="Interface\\Icons\\INV_Misc_Spyglass_03",
    visualLeft="Interface\\Icons\\INV_Misc_Map_01",visualRight="Interface\\Icons\\INV_Misc_Book_11",
    visualCorner="Interface\\Icons\\INV_Misc_Compass_01",visualAlpha=0.12,
}


local function CodexVariant(key,name,accent,paper,panel)
    local theme={}
    for field,value in pairs(FOREVER_THEMES.Codex) do theme[field]=value end
    theme.displayName=name theme.themeTitle=string.upper(name)
    theme.gold=accent theme.goldSoft=accent theme.accent=accent theme.buttonTint=accent
    theme.panel=panel theme.row=panel theme.button=panel theme.title=panel theme.toolbar=panel theme.inset=panel
    theme.backdrop={panel[1]*2,panel[2]*2,panel[3]*2,1}
    theme.paper=paper theme.paperMuted={paper[1]*.78,paper[2]*.78,paper[3]*.78,1}
    FOREVER_THEMES[key]=theme
end
FOREVER_THEMES.Codex.buttonTint={1,1,1,1}
FOREVER_THEMES.Codex.paper={.91,.83,.64,1}
FOREVER_THEMES.Codex.paperMuted={.68,.66,.59,1}
CodexVariant("Royal","Royal Codex",{.82,.65,1,1},{.85,.81,.94,1},{.045,.029,.065,1})
CodexVariant("Frost","Frost Codex",{.55,.85,1,1},{.80,.89,.94,1},{.025,.045,.060,1})
CodexVariant("Ember","Ember Codex",{1,.58,.28,1},{.94,.80,.66,1},{.065,.032,.022,1})

local FOREVER_THEME_ORDER = {"Codex","Royal","Frost","Ember"}

local CurrentThemeName = "Codex"
local ThemeVisuals = {}
local ThemeVisualLookup=setmetatable({}, {__mode="k"})

function CopyThemeIntoActive(themeName)
    if not FOREVER_THEMES[themeName] then themeName="Codex" end
    local source = FOREVER_THEMES[themeName] or FOREVER_THEMES.Classic
    for k in pairs(WOW_THEME) do WOW_THEME[k] = nil end
    for k,v in pairs(source) do
        if type(v) == "table" then
            WOW_THEME[k] = {v[1],v[2],v[3],v[4]}
        else
            WOW_THEME[k] = v
        end
    end
    CurrentThemeName = themeName
end

function RegisterThemeVisual(kind, object)
    if object then
        local existing=ThemeVisualLookup[object]
        if existing then existing.kind=kind return end
        local entry={kind=kind,object=object} ThemeVisualLookup[object]=entry table.insert(ThemeVisuals,entry)
    end
end

function ThemeColor(texture, field)
    if not texture then return end
    RegisterThemeVisual(field, texture)
end

function ResolveThemeModelDisplay(themeData, slot)
    if not themeData then
        return nil
    end

    if slot == 2 and themeData.themeDisplay2 then
        return themeData.themeDisplay2
    elseif slot ~= 2 and themeData.themeDisplay1 then
        return themeData.themeDisplay1
    end

    if not ForeverSourceData or not ForeverSourceData.npcModels then
        return nil
    end

    local candidates=nil
    if slot == 2 then
        candidates=themeData.themeModelNPCs2 or {themeData.themeModelNPC2}
    else
        candidates=themeData.themeModelNPCs1 or {themeData.themeModelNPC}
    end

    for _,npcID in ipairs(candidates or {}) do
        if npcID and npcID ~= 0 then
            local displayID=ForeverSourceData.npcModels[npcID]
            if type(displayID)=="table" then
                displayID=displayID[1] or displayID.displayID or displayID.modelID
            end
            if displayID then
                return displayID,npcID
            end
        end
    end
    return nil
end

function ApplyRegisteredThemeVisuals()
    local t = FOREVER_THEMES[CurrentThemeName] or FOREVER_THEMES.Classic
    for _,entry in ipairs(ThemeVisuals) do
        local o = entry.object
        local c = t[entry.kind]
        if o then
            if entry.kind == "themeModel" or entry.kind == "themeModel2" then
                local displayID=nil
                if entry.kind == "themeModel2" then
                    displayID=ResolveThemeModelDisplay(t,2)
                else
                    displayID=ResolveThemeModelDisplay(t,1)
                end
                if displayID and o.SetDisplayInfo then
                    o:SetDisplayInfo(displayID)
                    if o.SetModelScale then
                        if entry.kind == "themeModel2" then
                            o:SetModelScale(t.modelScale2 or 0.36)
                        else
                            o:SetModelScale(t.modelScale1 or 0.38)
                        end
                    end
                    if o.SetPosition then
                        if entry.kind == "themeModel2" then
                            o:SetPosition(0,0,t.modelZ2 or 0.00)
                        else
                            o:SetPosition(0,0,t.modelZ1 or 0.00)
                        end
                    end
                    if o.Show then o:Show() end
                elseif o.Hide then
                    o:Hide()
                end
            elseif entry.kind == "themeTitle" and o.SetText then
                o:SetText(t.themeTitle or t.displayName or CurrentThemeName)
                local cc=t.gold or {1,1,1,1}
                o:SetTextColor(cc[1],cc[2],cc[3],1)
            elseif entry.kind == "themeSub" and o.SetText then
                o:SetText(t.themeSub or "")
                local cc=t.goldSoft or {0.8,0.8,0.8,1}
                o:SetTextColor(cc[1],cc[2],cc[3],1)
            elseif entry.kind == "heroSymbol" and o.SetTexture then
                o:SetTexture(t.heroSymbol or t.icon or FOREVER_THEMES.Classic.icon)
                o:SetAlpha(1)
            elseif entry.kind == "icon" and o.SetTexture then
                o:SetTexture(t.icon or FOREVER_THEMES.Classic.icon)
            elseif entry.kind == "visualLeft" and o.SetTexture then
                o:SetTexture(t.visualLeft or t.icon)
                o:SetAlpha(t.visualAlpha or 0.25)
            elseif entry.kind == "visualRight" and o.SetTexture then
                o:SetTexture(t.visualRight or t.icon)
                o:SetAlpha(t.visualAlpha or 0.25)
            elseif entry.kind == "visualCorner" and o.SetTexture then
                o:SetTexture(t.visualCorner or t.icon)
                o:SetAlpha((t.visualAlpha or 0.25) * 0.75)
            elseif entry.kind == "visualCrest" and o.SetTexture then
                o:SetTexture(t.heroSymbol or t.icon or FOREVER_THEMES.Classic.icon)
                o:SetAlpha(0.13)
            elseif c and type(c) == "table" and o.SetVertexColor then
                o:SetVertexColor(c[1] or 1,c[2] or 1,c[3] or 1,c[4] or 1)
            elseif c and type(c) == "table" and o.SetTextColor then
                o:SetTextColor(c[1] or 1,c[2] or 1,c[3] or 1,c[4] or 1)
            elseif entry.kind == "gold" and o.SetVertexColor then
                c=t.gold; o:SetVertexColor(c[1],c[2],c[3],c[4] or 1)
            elseif entry.kind == "accent" and o.SetVertexColor then
                c=t.accent; o:SetVertexColor(c[1],c[2],c[3],c[4] or 1)
            end
        end
    end
end

function SaveForeverTheme(themeName)
    if type(ForeverDBDatabase) ~= "table" then
        ForeverDBDatabase = {}
    end
    ForeverDBDatabase.foreverBrowserTheme = themeName
end

function LoadForeverTheme()
    local name=type(ForeverDBDatabase)=="table" and ForeverDBDatabase.foreverBrowserTheme or "Codex"
    if not FOREVER_THEMES[name] then name="Codex" end
    return name
end


function AddWoWBorder(frame, edgeSize, alpha)
    if type(ForeverBrowser_AchievementBorder)=="function" then
        ForeverBrowser_AchievementBorder(frame,true)
        return
    end
    if not frame or not frame.CreateTexture then return end

    local size = edgeSize or 1
    local a = alpha or 0.9

    function MakeEdge()
        local t = frame:CreateTexture(nil, "BORDER")
        t:SetTexture("Interface\\Buttons\\WHITE8X8")
        local c=WOW_THEME.accent or {0.44,0.32,0.12,1}
        t:SetVertexColor(c[1],c[2],c[3],a)
        ThemeColor(t, "accent")
        return t
    end

    local top = MakeEdge()
    top:SetHeight(size)
    top:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
    top:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)

    local bottom = MakeEdge()
    bottom:SetHeight(size)
    bottom:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 0)
    bottom:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)

    local left = MakeEdge()
    left:SetWidth(size)
    left:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
    left:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 0)

    local right = MakeEdge()
    right:SetWidth(size)
    right:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
    right:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)
end

function AddWoWPanelTexture(frame, alpha)
    if not frame or not frame.CreateTexture then return end
    local texture = frame:CreateTexture(nil, "BACKGROUND")
    texture:SetAllPoints(frame)
    texture:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Background")
    local c = WOW_THEME.backdrop or {0.20,0.15,0.10,1}
    texture:SetVertexColor(c[1],c[2],c[3],alpha or c[4] or 0.82)
    ThemeColor(texture, "backdrop")
    return texture
end

function AddWoWInset(frame)
    if not frame then return end
    local bg = frame:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(frame)
    bg:SetTexture("Interface\\Buttons\\WHITE8X8")
    local c = WOW_THEME.inset or {0.016,0.013,0.010,0.96}
    bg:SetVertexColor(c[1],c[2],c[3],c[4] or 0.96)
    ThemeColor(bg, "inset")
    AddWoWBorder(frame, 1, 0.65)
    return bg
end

function AddWoWDivider(parent, left, right, y)
    if not parent then return end
    local line = parent:CreateTexture(nil, "ARTWORK")
    line:SetTexture("Interface\\Buttons\\WHITE8X8")
    local accent = WOW_THEME.goldDim or {0.45, 0.32, 0.11, 1}
    line:SetVertexColor(accent[1], accent[2], accent[3], 0.65)
    ThemeColor(line, "goldDim")
    line:SetHeight(1)
    line:SetPoint("TOPLEFT", parent, "TOPLEFT", left or 20, y or -20)
    line:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -(right or 20), y or -20)
    return line
end


--------------------------------------------------
-- WOW ORNAMENTS / VISUAL ACCENTS
--------------------------------------------------

function AddWoWCornerOrnaments(frame)
    if not frame or not frame.CreateTexture then return end
    local corners = {
        {"TOPLEFT","TOPLEFT",1,-1},{"TOPRIGHT","TOPRIGHT",-1,-1},
        {"BOTTOMLEFT","BOTTOMLEFT",1,1},{"BOTTOMRIGHT","BOTTOMRIGHT",-1,1},
    }
    for _, info in ipairs(corners) do
        local t = frame:CreateTexture(nil, "OVERLAY")
        t:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
        t:SetSize(34,34)
        t:SetVertexColor(0.72,0.52,0.18,0.55)
        t:SetPoint(info[1],frame,info[2],info[3],info[4])
    end
end

function AddWoWHeaderAccent(parent, anchor, width)
    if not parent or not anchor then return end
    local left=parent:CreateTexture(nil,"ARTWORK")
    left:SetTexture("Interface\\Buttons\\WHITE8X8")
    left:SetVertexColor(0.50,0.34,0.10,0.58)
    left:SetHeight(1); left:SetWidth(width or 90)
    left:SetPoint("RIGHT",anchor,"LEFT",-10,0)
    local right=parent:CreateTexture(nil,"ARTWORK")
    right:SetTexture("Interface\\Buttons\\WHITE8X8")
    right:SetVertexColor(0.50,0.34,0.10,0.58)
    right:SetHeight(1); right:SetWidth(width or 90)
    right:SetPoint("LEFT",anchor,"RIGHT",10,0)
end

function AddWoWIconFrame(parent, icon, size)
    if not parent or not icon then return end
    local ring=parent:CreateTexture(nil,"OVERLAY")
    ring:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
    ring:SetSize((size or 36)+14,(size or 36)+14)
    ring:SetVertexColor(0.80,0.60,0.22,0.78)
    ring:SetPoint("CENTER",icon,"CENTER",0,0)
    return ring
end

function AddWoWSoftGlow(parent, point, relativeTo, relativePoint, x, y, width, height)
    local glow=parent:CreateTexture(nil,"BACKGROUND")
    glow:SetTexture("Interface\\Buttons\\WHITE8X8")
    glow:SetVertexColor(0.34,0.20,0.055,0.12)
    glow:SetSize(width or 220,height or 50)
    glow:SetPoint(point,relativeTo or parent,relativePoint or point,x or 0,y or 0)
    return glow
end


--------------------------------------------------
-- WOW SHOWCASE VISUALS
--------------------------------------------------

local WOW_PAGE_ICONS = {
    home = "Interface\\Icons\\INV_Misc_Book_09",
    item = "Interface\\Icons\\INV_Misc_Bag_10",
    quest = "Interface\\Icons\\INV_Misc_Note_01",
    npc = "Interface\\Icons\\INV_Misc_GroupLooking",
    profession = "Interface\\Icons\\Trade_BlackSmithing",
    recipe = "Interface\\Icons\\INV_Scroll_03",
}

function CreateWoWMedallion(parent, texturePath, size)
    if not parent then return nil end
    local holder = CreateFrame("Frame", nil, parent)
    holder:SetSize(size or 52, size or 52)

    local glow = holder:CreateTexture(nil, "BACKGROUND")
    glow:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
    glow:SetAllPoints(holder)
    glow:SetVertexColor(0.78, 0.56, 0.18, 0.50)

    local icon = holder:CreateTexture(nil, "ARTWORK")
    icon:SetTexture(texturePath or WOW_PAGE_ICONS.home)
    icon:SetPoint("TOPLEFT", holder, "TOPLEFT", 8, -8)
    icon:SetPoint("BOTTOMRIGHT", holder, "BOTTOMRIGHT", -8, 8)

    local ring = holder:CreateTexture(nil, "OVERLAY")
    ring:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
    ring:SetAllPoints(holder)
    ring:SetVertexColor(0.94, 0.70, 0.22, 0.88)

    return holder, icon
end

function CreateWoWBanner(parent, titleText, subtitleText, iconPath, y)
    local banner = CreateFrame("Frame", nil, parent)
    banner:SetPoint("TOPLEFT", parent, "TOPLEFT", 18, y or -18)
    banner:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -18, y or -18)
    banner:SetHeight(72)

    local bg = banner:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(banner)
    bg:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Background")
    local c=WOW_THEME.panel or {0.24,0.15,0.07,0.72}
    bg:SetVertexColor(c[1],c[2],c[3],0.86)
    ThemeColor(bg,"panel")
    AddWoWBorder(banner, 1, 0.75)

    local shine = banner:CreateTexture(nil, "ARTWORK")
    shine:SetTexture("Interface\\Buttons\\WHITE8X8")
    shine:SetVertexColor(0.72, 0.49, 0.13, 0.10)
    shine:SetPoint("TOPLEFT", banner, "TOPLEFT", 2, -2)
    shine:SetPoint("BOTTOMRIGHT", banner, "BOTTOMRIGHT", -2, 2)

    local medallion = CreateWoWMedallion(banner, iconPath, 54)
    medallion:SetPoint("LEFT", banner, "LEFT", 10, 0)

    local title = CreateLabel(banner, titleText or "", 18, WOW_THEME.gold)
    title:SetPoint("TOPLEFT", banner, "TOPLEFT", 72, -13)

    if subtitleText and subtitleText ~= "" then
        local subtitle = CreateLabel(banner, subtitleText, 11, WOW_THEME.muted)
        subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -7)
    end

    local lower = banner:CreateTexture(nil, "ARTWORK")
    lower:SetTexture("Interface\\Buttons\\WHITE8X8")
    lower:SetVertexColor(0.60, 0.42, 0.12, 0.52)
    lower:SetHeight(1)
    lower:SetPoint("BOTTOMLEFT", banner, "BOTTOMLEFT", 70, 8)
    lower:SetPoint("BOTTOMRIGHT", banner, "BOTTOMRIGHT", -12, 8)

    return banner
end

function CreateWoWCategoryTile(parent, titleText, subtitleText, iconPath, width, height)
    local tile = CreateFrame("Button", nil, parent)
    tile:SetSize(width or 210, height or 72)

    local bg = tile:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(tile)
    bg:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Background")
    local c=WOW_THEME.row or {0.18,0.115,0.055,0.82}
    bg:SetVertexColor(c[1],c[2],c[3],c[4] or 0.82)
    ThemeColor(bg,"row")
    tile.bg = bg

    AddWoWBorder(tile, 1, 0.72)

    local medallion = CreateWoWMedallion(tile, iconPath, 46)
    medallion:SetPoint("LEFT", tile, "LEFT", 8, 0)

    local title = CreateLabel(tile, titleText, 14, WOW_THEME.gold)
    title:SetPoint("TOPLEFT", tile, "TOPLEFT", 61, -14)

    local sub = CreateLabel(tile, subtitleText or "", 10, WOW_THEME.muted)
    sub:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -6)

    tile:SetScript("OnEnter", function(self)
        if self.bg then self.bg:SetVertexColor(0.30, 0.18, 0.055, 0.94) end
        title:SetTextColor(1, 0.88, 0.35, 1)
    end)
    tile:SetScript("OnLeave", function(self)
        if self.bg then
            local c = WOW_THEME.row or {0.18,0.115,0.055,0.82}
            self.bg:SetVertexColor(c[1],c[2],c[3],c[4] or 0.82)
        end
        title:SetTextColor(WOW_THEME.gold[1], WOW_THEME.gold[2], WOW_THEME.gold[3], 1)
    end)

    return tile
end

function CreateWoWSectionRibbon(parent, text, y, iconPath)
    local ribbon = CreateFrame("Frame", nil, parent)
    ribbon:SetPoint("TOPLEFT", parent, "TOPLEFT", 20, y)
    ribbon:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -20, y)
    ribbon:SetHeight(28)

    local bg = ribbon:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(ribbon)
    bg:SetTexture("Interface\\Buttons\\WHITE8X8")
    local c=WOW_THEME.row or {0.10,0.060,0.022,0.88}
    bg:SetVertexColor(c[1],c[2],c[3],0.92)
    ThemeColor(bg,"row")

    local top = ribbon:CreateTexture(nil, "ARTWORK")
    top:SetTexture("Interface\\Buttons\\WHITE8X8")
    top:SetVertexColor(0.55, 0.38, 0.11, 0.55)
    top:SetHeight(1)
    top:SetPoint("TOPLEFT", ribbon, "TOPLEFT", 0, 0)
    top:SetPoint("TOPRIGHT", ribbon, "TOPRIGHT", 0, 0)

    local bottom = ribbon:CreateTexture(nil, "ARTWORK")
    bottom:SetTexture("Interface\\Buttons\\WHITE8X8")
    bottom:SetVertexColor(0.35, 0.24, 0.08, 0.45)
    bottom:SetHeight(1)
    bottom:SetPoint("BOTTOMLEFT", ribbon, "BOTTOMLEFT", 0, 0)
    bottom:SetPoint("BOTTOMRIGHT", ribbon, "BOTTOMRIGHT", 0, 0)

    local x = 10
    if iconPath then
        local icon = ribbon:CreateTexture(nil, "ARTWORK")
        icon:SetTexture(iconPath)
        icon:SetSize(18, 18)
        icon:SetPoint("LEFT", ribbon, "LEFT", 8, 0)
        x = 32
    end

    local label = CreateLabel(ribbon, text, 12, WOW_THEME.goldSoft)
    label:SetPoint("LEFT", ribbon, "LEFT", x, 0)
    return ribbon
end

--------------------------------------------------
-- LABEL
--------------------------------------------------

function CreateLabel(
    parent,
    text,
    size,
    color
)

    local label =
        parent:CreateFontString(
            nil,
            "OVERLAY"
        )


    if label.SetFontObject then

        if size
            and size >= 18 then

            label:SetFontObject(
                "GameFontNormalLarge"
            )

        elseif size
            and size >= 14 then

            label:SetFontObject(
                "GameFontNormal"
            )

        else

            label:SetFontObject(
                "GameFontHighlightSmall"
            )

        end

    end


    if label.GetFont and label.SetFont then
        local _,fontSize,flags=label:GetFont()
        label:SetFont("Fonts\\FRIZQT__.TTF",fontSize or 12,flags or "")
    end

    if color then
        if color[1] and color[2] and color[3] then
            if color[1]>=.95 and color[2]>=.70 and color[2]<=.85 and color[3]<=.30 then color=WOW_THEME.gold
            elseif color[1]>=.65 and color[1]<.95 and color[2]>=.55 and color[3]>=.45 and color[3]<.85 then color=WOW_THEME.text or color end
        end

        label:SetTextColor(
            color[1] or 1,
            color[2] or 1,
            color[3] or 1,
            color[4] or 1
        )

    end


    for _,field in ipairs({"gold","goldSoft","text","ivory","muted"}) do if color==WOW_THEME[field] then RegisterThemeVisual(field,label) break end end
    label:SetText(
        text or ""
    )


    return label
end


--------------------------------------------------
-- BUTTON
--------------------------------------------------

function CreateButton(parent,text,width,height)
    local button=CreateFrame("Button",nil,parent,"UIPanelButtonTemplate")
    button:SetSize(width or 100,height or 30)
    button:SetText(text or "")
    button.text=button:GetFontString()
    if button.text and button.text.SetFont then
        button.text:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
        if button.text.SetJustifyH then button.text:SetJustifyH("CENTER") end
        if button.text.SetJustifyV then button.text:SetJustifyV("MIDDLE") end
        -- Keep short action labels on one line where the client supports it.
        if button.text.SetWordWrap then button.text:SetWordWrap(false) end
    end
    button:EnableMouse(true) button:RegisterForClicks("LeftButtonUp")
    ForeverBrowserTheme.StyleButton(button)
    return button
end

--------------------------------------------------
-- CLEAR PAGE
--------------------------------------------------

function ForeverBrowser_AchievementLabel(parent,text,size,color)
    local label=CreateLabel(parent,text,size,color)
    -- CreateLabel selects font objects, which ignored most requested sizes.
    if label.SetFont then label:SetFont("Fonts\\FRIZQT__.TTF",size or 12,"") end
    if label.SetShadowOffset then label:SetShadowOffset(0,0) end
    return label
end

function ForeverBrowser_AchievementBorder(frame,gold)
    if frame.foreverCodexBorder196 then return end
    frame.foreverCodexBorder196=true
    frame.foreverThemeEdges211={}
    -- Explicit texture bevels also work on clients without SetBackdrop.
    for layer=1,3 do
        local inset=layer-1
        local r=gold and (layer==2 and 0.90 or 0.40) or (layer==2 and 0.53 or 0.18)
        local g=gold and (layer==2 and 0.72 or 0.29) or (layer==2 and 0.51 or 0.17)
        local b=gold and (layer==2 and 0.29 or 0.12) or (layer==2 and 0.47 or 0.15)
        for _,edge in ipairs({"TOP","BOTTOM","LEFT","RIGHT"}) do
            local t=frame:CreateTexture(nil,"OVERLAY")
            t:SetTexture("Interface\\Buttons\\WHITE8X8")
            local c=layer==2 and WOW_THEME.accent or WOW_THEME.goldDim
            if gold and c then r,g,b=c[1],c[2],c[3] end
            t:SetVertexColor(r,g,b,1)
            if gold then local field=layer==2 and "accent" or "goldDim" RegisterThemeVisual(field,t) frame.foreverThemeEdges211[#frame.foreverThemeEdges211+1]={texture=t,field=field} end
            if edge=="TOP" or edge=="BOTTOM" then
                t:SetHeight(1)
                t:SetPoint(edge.."LEFT",frame,edge.."LEFT",inset,edge=="TOP" and -inset or inset)
                t:SetPoint(edge.."RIGHT",frame,edge.."RIGHT",-inset,edge=="TOP" and -inset or inset)
            else
                t:SetWidth(1)
                t:SetPoint("TOP"..edge,frame,"TOP"..edge,edge=="LEFT" and inset or -inset,-inset)
                t:SetPoint("BOTTOM"..edge,frame,"BOTTOM"..edge,edge=="LEFT" and inset or -inset,inset)
            end
        end
    end
end

function ForeverBrowser_AchievementPaper(frame,earned)
    local base=frame:CreateTexture(nil,"BACKGROUND")
    base:SetPoint("TOPLEFT",frame,"TOPLEFT",3,-3)
    base:SetPoint("BOTTOMRIGHT",frame,"BOTTOMRIGHT",-3,3)
    base:SetTexture("Interface\\Buttons\\WHITE8X8")
    local c=earned and WOW_THEME.paper or WOW_THEME.paperMuted
    c=c or {.91,.83,.64,1} base:SetVertexColor(c[1],c[2],c[3],1)
    RegisterThemeVisual(earned and "paper" or "paperMuted",base)
    local texture=frame:CreateTexture(nil,"BORDER")
    texture:SetPoint("TOPLEFT",frame,"TOPLEFT",3,-3)
    texture:SetPoint("BOTTOMRIGHT",frame,"BOTTOMRIGHT",-3,3)
    texture:SetTexture("Interface\\AchievementFrame\\UI-Achievement-Parchment-Horizontal")
    texture:SetTexCoord(0,1,0,0.72)
    texture:SetVertexColor(1,1,1,earned and 0.22 or 0.12)
    ForeverBrowser_AchievementBorder(frame,earned)
end

function ForeverBrowser_AchievementNativeButton(button)
    if button.SetNormalTexture then button:SetNormalTexture("Interface\\Buttons\\UI-Panel-Button-Up") end
    if button.SetPushedTexture then button:SetPushedTexture("Interface\\Buttons\\UI-Panel-Button-Down") end
    if button.SetHighlightTexture then button:SetHighlightTexture("Interface\\Buttons\\UI-Panel-Button-Highlight") end
    for _,getter in ipairs({"GetNormalTexture","GetPushedTexture","GetHighlightTexture"}) do
        if type(button[getter])=="function" then
            local texture=button[getter](button)
            if texture and texture.SetTexCoord then texture:SetTexCoord(0,0.625,0,0.6875) end
        end
    end
end


function ForeverBrowser_CodexSurface196(frame)
    if not frame or not frame.GetWidth or not frame.GetHeight then return end
    if (frame:GetWidth() or 0)>=100 and (frame:GetHeight() or 0)>=20 then
        ForeverBrowser_AchievementBorder(frame,true)
    end
end

function ForeverBrowser_CodexTitle196(label)
    local point,relative,relativePoint,x,y=label:GetPoint(1)
    local bar=CreateFrame("Frame",nil,label:GetParent())
    bar:SetSize(700,40) bar:SetPoint(point,relative,relativePoint,x,(y or 0)+6)
    ForeverBrowser_AchievementPaper(bar,true)
    label:SetParent(bar) label:ClearAllPoints()
    label:SetPoint(point,bar,point,point=="TOPLEFT" and 12 or 0,-6)
    label:SetWidth(676) label:SetHeight(28) label:SetJustifyH(point=="TOPLEFT" and "LEFT" or "CENTER")
    label:SetTextColor(0.31,0.22,0.10,1)
end

function ForeverBrowser_ItemButton190(parent, text, width, height)
    local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    button:SetSize(width or 120, height or 30)
    button:SetText(text or "")
    button.text = button:GetFontString()
    if button.text and button.text.SetFont then
        button.text:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
    end
    button:EnableMouse(true)
    button:RegisterForClicks("LeftButtonUp")
    ForeverBrowserTheme.StyleButton(button)
    return button
end



ForeverBrowserTheme={palette=WOW_THEME,themes=FOREVER_THEMES,order=FOREVER_THEME_ORDER,GetName=function() return CurrentThemeName end}
ForeverBrowserTheme.CreateSolidBackground=CreateSolidBackground
ForeverBrowserTheme.CopyThemeIntoActive=CopyThemeIntoActive
ForeverBrowserTheme.RegisterThemeVisual=RegisterThemeVisual
ForeverBrowserTheme.ThemeColor=ThemeColor
ForeverBrowserTheme.ResolveThemeModelDisplay=ResolveThemeModelDisplay
ForeverBrowserTheme.ApplyRegisteredThemeVisuals=ApplyRegisteredThemeVisuals
ForeverBrowserTheme.SaveForeverTheme=SaveForeverTheme
ForeverBrowserTheme.LoadForeverTheme=LoadForeverTheme
ForeverBrowserTheme.AddWoWBorder=AddWoWBorder
ForeverBrowserTheme.MakeEdge=MakeEdge
ForeverBrowserTheme.AddWoWPanelTexture=AddWoWPanelTexture
ForeverBrowserTheme.AddWoWInset=AddWoWInset
ForeverBrowserTheme.AddWoWDivider=AddWoWDivider
ForeverBrowserTheme.AddWoWCornerOrnaments=AddWoWCornerOrnaments
ForeverBrowserTheme.AddWoWHeaderAccent=AddWoWHeaderAccent
ForeverBrowserTheme.AddWoWIconFrame=AddWoWIconFrame
ForeverBrowserTheme.AddWoWSoftGlow=AddWoWSoftGlow
ForeverBrowserTheme.CreateWoWMedallion=CreateWoWMedallion
ForeverBrowserTheme.CreateWoWBanner=CreateWoWBanner
ForeverBrowserTheme.CreateWoWCategoryTile=CreateWoWCategoryTile
ForeverBrowserTheme.CreateWoWSectionRibbon=CreateWoWSectionRibbon
ForeverBrowserTheme.CreateLabel=CreateLabel
ForeverBrowserTheme.CreateButton=CreateButton

function ForeverBrowserTheme.Apply(themeName,refresh,rebuild)
    if not FOREVER_THEMES[themeName] then themeName="Codex" end
    CopyThemeIntoActive(themeName) SaveForeverTheme(themeName) ApplyRegisteredThemeVisuals()
    if refresh then refresh() end
    if rebuild then rebuild() end
end

-- Remove retired page objects from the live recoloring registry.
function ForeverBrowserTheme.ForgetSubtree(root)
    for i=#ThemeVisuals,1,-1 do local object=ThemeVisuals[i].object local cursor=object local found=false
        for depth=1,32 do if cursor==root then found=true break end if not cursor or type(cursor.GetParent)~="function" then break end local ok,parent=pcall(cursor.GetParent,cursor) if not ok then break end cursor=parent end
        if found then ThemeVisualLookup[object]=nil table.remove(ThemeVisuals,i) end
    end
end
function ForeverBrowserTheme.StyleButton(button)
    local tint=WOW_THEME.buttonTint or {1,1,1,1}
    for _,getter in ipairs({"GetNormalTexture","GetPushedTexture"}) do if type(button[getter])=="function" then local texture=button[getter](button)
        if texture and type(texture.SetVertexColor)=="function" then texture:SetVertexColor(tint[1],tint[2],tint[3],1) RegisterThemeVisual("buttonTint",texture) end
    end end
    if button.text then
        button.text:SetTextColor(unpack(WOW_THEME.gold or {1,.82,.28,1}))
        if button.text.SetJustifyH then button.text:SetJustifyH("CENTER") end
        if button.text.SetJustifyV then button.text:SetJustifyV("MIDDLE") end
        RegisterThemeVisual("gold",button.text)
    end
    -- A highlight texture is visual-only and respects the existing click handlers.
    if not button.foreverPolishHighlight and type(button.CreateTexture)=="function" then
        local highlight=button:CreateTexture(nil,"HIGHLIGHT")
        highlight:SetTexture("Interface\\Buttons\\WHITE8X8")
        highlight:SetVertexColor(1,0.82,0.32,0.10)
        highlight:SetAllPoints(button)
        button.foreverPolishHighlight=highlight
    end
end
function ForeverBrowserTheme.StyleTooltip(tooltip)
    if tooltip and type(tooltip.SetBackdropBorderColor)=="function" then local c=WOW_THEME.accent or {1,.82,.28,1} pcall(tooltip.SetBackdropBorderColor,tooltip,c[1],c[2],c[3],1) end
end

function ForeverBrowserTheme.RestyleBorder(frame)
    for _,edge in ipairs(frame.foreverThemeEdges211 or {}) do local c=WOW_THEME[edge.field] if c then edge.texture:SetVertexColor(unpack(c)) RegisterThemeVisual(edge.field,edge.texture) end end
end
