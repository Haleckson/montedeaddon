-- SpellbookLevels v2.6.8  (WoW: Forever beta - Retail-based client, Interface 16001)
--
-- Two lists, two windows:
--   Class spells   (/sbl)        Data\<CLASS>.lua + class trainer      - attaches to the spellbook
--   Professions    (/sbl prof)   Data\PROFESSIONS.lua + profession trainers - attaches to the profession window
-- Trainer visits are saved automatically (per class for spells, account-wide for professions).
--
-- /sbl [prof]           toggle a window        /sbl export [prof]   copyable Lua for the data files
-- /sbl prof auto|all|<name>   choose which profession the list shows (auto follows the open profession tab)
-- /sbl profdump         print how the profession window is detected (for troubleshooting)
-- /sbl style [auto|native|parchment|dark]   window look: classic parchment spellbook or dark (button on each window too)
-- /sbl tabs [top|side|scan]   move the game's profession tabs to the top (default) or back to the side
-- /sbl native           switch the spellbook between our book and the game's own page
-- /sbl dock [on|off|top N|top auto]   show the book inside the game's own spellbook / profession window (default on)
-- /sbl pin [on|off]     (when docking is off) pin each window to its game window (spellbook / professions) so they move as one
--                       (also the Pin button on our windows)
-- /sbl probe            API check              /sbl trainerdump     raw trainer rows (open a trainer first)
-- /sbl icon             show/hide shortcut     /sbl reset           reset all window/button/host positions
-- /sbl wipe [prof]      clear saved data       Shortcut button: left-click = spells, right-click = professions

local className, class = UnitClass("player")
SBL_DATA = SBL_DATA or {}
SBL_PROF = SBL_PROF or {}
local PREFIX = "|cff00ff00SpellbookLevels|r: "

------------------------------------------------------------------ data
local lists = { class = {}, prof = {} }
local index = { class = {}, prof = {} }
local FIELDS = { "name", "rank", "level", "skill", "prof", "cost", "tree", "icon", "learned", "recipeID", "source", "sourceName", "sourceZone", "sourceMapID", "sourceX", "sourceY", "requirementKnown", "recipeItemID", "craftedItemID", "dataOrigin", "observedBuild", "observedAt", "dbSource" }

local function Clone(e)
    local t = {}
    for _, k in ipairs(FIELDS) do t[k] = e[k] end
    return t
end

local function Add(kind, e)
    e.rank = e.rank or ""
    local key = e.name .. "|" .. e.rank
    if kind == "prof" then key = key .. "|" .. (e.prof or "") end
    if e.rank == "" then key = key .. "|" .. tostring(kind == "prof" and (e.skill or 0) or (e.level or 0)) end
    local old = index[kind][key]
    if old then
        for k, v in pairs(e) do if v and v ~= 0 and v ~= "" then old[k] = v end end
    else
        index[kind][key] = e
        local l = lists[kind]
        l[#l + 1] = e
    end
end

for _, e in ipairs(SBL_DATA[class] or {}) do Add("class", Clone(e)) end
for _, e in ipairs(SBL_PROF or {}) do Add("prof", Clone(e)) end

local function Money(c)
    if not c or c <= 0 then return "" end
    local f = (C_CurrencyInfo and C_CurrencyInfo.GetCoinTextureString) or GetCoinTextureString
    return f and (" - " .. f(c)) or (" - " .. c .. "c")
end

local function SortClass(a, b)
    if (a.level or 0) ~= (b.level or 0) then return (a.level or 0) < (b.level or 0) end
    return a.name < b.name
end

-- Classic/Forever class trainers use a level-based base price schedule for normal class
-- abilities/ranks.  The actual price shown by a trainer can be lower because of faction
-- reputation; ScanTrainer() remains authoritative and overwrites this fallback whenever
-- the character visits a trainer.  This table lets a fresh character see useful prices
-- for FutureSpell entries immediately, before the first trainer visit.
local CLASS_BASE_COST = {
    [1]=10, [4]=100, [6]=100, [8]=200, [10]=400, [12]=600, [14]=900, [16]=1500,
    [18]=1800, [20]=2000, [22]=3000, [24]=4000, [26]=5000, [28]=7000, [30]=8000,
    [32]=10000, [34]=12000, [36]=13000, [38]=14000, [40]=15000, [42]=18000,
    [44]=23000, [46]=26000, [48]=28000, [50]=32000, [52]=35000, [54]=36000,
    [56]=38000, [58]=40000, [60]=42000,
}
local function ClassBaseCost(level)
    return CLASS_BASE_COST[tonumber(level) or 0] or 0
end

local function SortProf(a, b)
    local pa, pb = a.prof or "", b.prof or ""
    if pa ~= pb then return pa < pb end
    if (a.skill or 0) ~= (b.skill or 0) then return (a.skill or 0) < (b.skill or 0) end
    return a.name < b.name
end

-- The trainer API returns a row's category ("available" / "unavailable" / "used" / "header") and, in some
-- versions, its rank text. Which position holds which differs between clients, so tell them apart by value.
local TRAINER_CATEGORY = { available = true, unavailable = true, used = true, header = true }

local function SplitTrainerInfo(v2, v3)
    local rank, category = "", nil
    local vals = { v2, v3 }
    for i = 1, 2 do
        local v = vals[i]
        if type(v) == "string" then
            if TRAINER_CATEGORY[v] then category = v elseif v ~= "" then rank = v end
        end
    end
    return rank, category
end

local loaded = false   -- true once saved variables are available

local function LoadSaved()
    local db = SpellbookLevelsDB
    if db then
        -- migrate keys from older versions
        if db.winPos and not db.winPos_class then db.winPos_class = db.winPos end
        if db.wantOpen ~= nil and db.wantOpen_class == nil then db.wantOpen_class = db.wantOpen end
        if db.bookPos and not db.hostPos_book then db.hostPos_book = db.bookPos end
        if db.winPos_main == nil then db.winPos_main = db.winPos_class end
        if db.wantOpen_main == nil and (db.wantOpen_class ~= nil or db.wantOpen_prof ~= nil) then
            db.wantOpen_main = (db.wantOpen_class or db.wantOpen_prof) and true or false
        end
        if db.data and db.data[class] then
            for _, e in ipairs(db.data[class]) do
                if e.name then
                    local c = Clone(e)
                    if TRAINER_CATEGORY[c.rank] then c.rank = "" end
                    Add("class", c)
                end
            end
        end
        if db.prof then
            for _, e in ipairs(db.prof) do
                if e.name then
                    local c = Clone(e)
                    if TRAINER_CATEGORY[c.rank] then c.rank = "" end
                    Add("prof", c)
                end
            end
        end
    end
    if GetBuildInfo then
        local _,build=GetBuildInfo()
        if db and db.lastClientBuild and db.lastClientBuild~=build then db.trainingDataNeedsReview=true end
        SpellbookLevelsDB=SpellbookLevelsDB or {}; SpellbookLevelsDB.lastClientBuild=build
    end
    loaded = true
end

local function SaveLists()
    if not loaded then return end
    SpellbookLevelsDB = SpellbookLevelsDB or {}
    local db = SpellbookLevelsDB
    db.data = db.data or {}
    local c, p = {}, {}
    for _, e in ipairs(lists.class) do c[#c + 1] = Clone(e) end
    for _, e in ipairs(lists.prof) do p[#p + 1] = Clone(e) end
    db.data[class] = c
    db.prof = p
end

local function DB()
    SpellbookLevelsDB = SpellbookLevelsDB or {}
    return SpellbookLevelsDB
end

-- Account catalogs remain shared; presentation preferences belong to the character.
local function Preferences()
    local db = DB()
    db.characters = db.characters or {}
    local key = (UnitName("player") or "?") .. "-" .. (GetRealmName() or "?")
    if not db.characters[key] then
        local pref={}
        for name,value in pairs(db) do
            if type(name)=="string" and (name:match("^winPos_") or name:match("^hostPos_") or name:match("^winSize_") or name:match("^sourceMode_")) then pref[name]=value end
        end
        db.characters[key]=pref
    end
    return db.characters[key]
end

local function TrainingViewMatches(kind,mode,entry,state,level)
    if mode=="learned" then return state=="learned" end
    if state=="learned" then return false end
    if mode=="now" then return state=="avail" end
    if kind=="class" then
        local required=tonumber(entry.level) or 0
        if mode=="next" then return required==level+1 end
        if mode=="plus5" then return required<=level+5 end
    end
    return true
end

-- Explicit menus work on clients with or without MenuUtil.
local activeMenu
local function ChoiceMenu(owner, choices, current, choose)
    if activeMenu and activeMenu:IsShown() and activeMenu.owner==owner then activeMenu:Hide(); return end
    local menu=activeMenu
    if not menu then
        menu=CreateFrame("Frame","SpellbookLevelsChoiceMenu",UIParent,"BackdropTemplate")
        menu.buttons={}; activeMenu=menu
        tinsert(UISpecialFrames,"SpellbookLevelsChoiceMenu")
    end
    menu.owner=owner
    menu:SetFrameStrata("TOOLTIP")
    menu:SetSize(210, #choices * 24 + 8)
    menu:ClearAllPoints()
    menu:SetPoint("TOPLEFT", owner, "BOTTOMLEFT", 0, -2)
    menu:SetClampedToScreen(true)
    menu:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8", edgeFile="Interface\\Buttons\\WHITE8X8", edgeSize=1})
    menu:SetBackdropColor(.06,.05,.035,1)
    for i, choice in ipairs(choices) do
        local value, label = choice.value or choice, choice.label or choice
        local button=menu.buttons[i]
        if not button then button=CreateFrame("Button",nil,menu,"UIPanelButtonTemplate"); menu.buttons[i]=button end
        button:Show()
        button:SetSize(202,22); button:SetPoint("TOPLEFT",4,-4-(i-1)*24)
        button:SetText((value == current and "✓ " or "") .. label)
        button:SetScript("OnClick",function() menu:Hide(); choose(value) end)
    end
    for i=#choices+1,#menu.buttons do menu.buttons[i]:Hide() end
    menu:Show(); menu:EnableMouse(true)
    menu:SetScript("OnUpdate",function() if not owner:IsShown() then menu:Hide() end end)
end

------------------------------------------------------------------ profession source observation helpers (v2.7.1)
local function TrainerRecipeID(i)
    local id
    if GetTrainerServiceItemLink then
        local ok, link = pcall(GetTrainerServiceItemLink, i)
        if ok and type(link) == "string" then
            id = tonumber(link:match("spell:(%d+)")) or tonumber(link:match("enchant:(%d+)"))
        end
    end
    if not id and GetTrainerServiceSpellID then
        pcall(function() id = GetTrainerServiceSpellID(i) end)
    end
    return tonumber(id)
end

local function PlayerSourcePosition()
    if not (C_Map and C_Map.GetBestMapForUnit and C_Map.GetPlayerMapPosition) then return nil end
    local ok, mapID = pcall(C_Map.GetBestMapForUnit, "player")
    if not ok or not mapID then return nil end
    local ok2, pos = pcall(C_Map.GetPlayerMapPosition, mapID, "player")
    if not ok2 or not pos then return mapID end
    local x, y
    pcall(function() x, y = pos:GetXY() end)
    return mapID, x, y
end

------------------------------------------------------------------ trainer scan
local function ScanTrainer()
    if not (GetNumTrainerServices and GetTrainerServiceInfo) then return end
    local tradeTrainer = IsTradeskillTrainer and IsTradeskillTrainer()
    for i = 1, GetNumTrainerServices() do
        local name, v2, v3 = GetTrainerServiceInfo(i)
        local rank, category = SplitTrainerInfo(v2, v3)
        if name and category ~= "header" then
            local skillName, skillRank
            if GetTrainerServiceSkillReq then skillName, skillRank = GetTrainerServiceSkillReq(i) end
            local skillLine = GetTrainerServiceSkillLine and GetTrainerServiceSkillLine(i)
            local profName = (skillName and skillName ~= "" and skillName) or (skillLine and skillLine ~= "" and skillLine) or nil
            local isProf
            if IsTradeskillTrainer then isProf = tradeTrainer and true or false else isProf = profName ~= nil end

            local trainerName = UnitName and UnitName("npc") or nil
            local trainerZone = GetRealZoneText and GetRealZoneText() or nil
            local recipeID = TrainerRecipeID(i)
            local sourceMapID, sourceX, sourceY = PlayerSourcePosition()
            local e = {
                name = name, rank = rank, dataOrigin = "Trainer",
                observedBuild = GetBuildInfo and select(4, GetBuildInfo()), observedAt = time and time(),
                level = GetTrainerServiceLevelReq and GetTrainerServiceLevelReq(i) or 0,
                icon = GetTrainerServiceIcon and GetTrainerServiceIcon(i),
                cost = GetTrainerServiceCost and GetTrainerServiceCost(i),
                learned = (category == "used") or nil,
                recipeID = recipeID, source = isProf and "Trainer" or nil, requirementKnown = isProf and true or nil,
                sourceName = isProf and trainerName or nil, sourceZone = isProf and trainerZone or nil,
                sourceMapID = isProf and sourceMapID or nil, sourceX = isProf and sourceX or nil, sourceY = isProf and sourceY or nil,
            }
            if isProf then
                e.prof = profName or "Unknown profession"
                e.skill = skillRank or 0
                Add("prof", e)
            else
                Add("class", e)
            end
        end
    end
end

------------------------------------------------------------------ what the player knows
local function KnownSet()
    local known, SB = {}, C_SpellBook
    if not (SB and SB.GetNumSpellBookSkillLines and SB.GetSpellBookSkillLineInfo and SB.GetSpellBookItemName) then
        return known
    end
    local bank = Enum and Enum.SpellBookSpellBank and Enum.SpellBookSpellBank.Player or 0
    for line = 1, SB.GetNumSpellBookSkillLines() do
        local info = SB.GetSpellBookSkillLineInfo(line)
        if info then
            for slot = info.itemIndexOffset + 1, info.itemIndexOffset + info.numSpellBookItems do
                local name, sub = SB.GetSpellBookItemName(slot, bank)
                if name then known[name .. "|" .. (sub or "")] = true; known[name .. "|"] = true end
            end
        end
    end
    return known
end

-- Does the player actually know this spell? (The spellbook can also list spells that are still to come.)
local SpellKnown, ScanSpellbook, BuildClassEntries = SBL_ClassSpells.Create(lists, Clone, ClassBaseCost)

-- Current skill level in a profession, or nil if this client won't tell us.
local function PlayerSkill(prof)
    local result
    pcall(function()
        if GetProfessions and GetProfessionInfo then
            local t = { GetProfessions() }
            for i = 1, 6 do
                local idx = t[i]
                if idx then
                    local name, _, rank = GetProfessionInfo(idx)
                    if name == prof then result = rank; return end
                end
            end
        end
        if GetNumSkillLines and GetSkillLineInfo then
            for i = 1, GetNumSkillLines() do
                local name, header, _, rank = GetSkillLineInfo(i)
                if not header and name == prof then result = rank; return end
            end
        end
    end)
    return result
end

-- Which profession is currently selected in the profession window (nil if it can't be told).
local GENERIC_TITLES = { ["professions"] = true, ["trade skills"] = true, ["profession"] = true }

local function DetectProfession()
    local name
    pcall(function()
        local C = C_TradeSkillUI
        if C and C.GetBaseProfessionInfo then
            local info = C.GetBaseProfessionInfo()
            if info then
                local parent = info.parentProfessionName
                name = (parent and parent ~= "" and parent) or info.professionName
            end
        end
        if (not name or name == "") and C and C.GetTradeSkillLine then
            local _, lineName, _, _, _, _, parentName = C.GetTradeSkillLine()
            name = (parentName and parentName ~= "" and parentName) or lineName
        end
        if (not name or name == "") and GetTradeSkillLine then
            name = GetTradeSkillLine()
        end
        if (not name or name == "") then
            local h = ProfessionsFrame or TradeSkillFrame
            local t = h and h.TitleContainer and h.TitleContainer.TitleText and h.TitleContainer.TitleText:GetText()
            if t and t ~= "" and not GENERIC_TITLES[t:lower()] then name = t end
        end
    end)
    if name == "" or name == "UNKNOWN" then name = nil end
    return name
end

-- Loose profession-name match ("First Aid" vs "Khaz Algar First Aid", any capitalization).
local function SameProf(a, b)
    if not a or not b then return false end
    a, b = a:lower(), b:lower()
    return a == b or a:find(b, 1, true) ~= nil or b:find(a, 1, true) ~= nil
end

-- The profession's own icon from the player's profession list, if the client provides it.
local function ProfessionIcon(prof)
    local icon
    pcall(function()
        if GetProfessions and GetProfessionInfo then
            local t = { GetProfessions() }
            for i = 1, 6 do
                if t[i] then
                    local name, tex = GetProfessionInfo(t[i])
                    if name and SameProf(name, prof) then icon = tex; return end
                end
            end
        end
    end)
    return icon
end

------------------------------------------------------------------ themes
-- { key found in the profession name, r, g, b, fallback icon }
local PROF_THEMES = {
    { "alchemy",      0.35, 0.85, 0.45, "Interface\\Icons\\Trade_Alchemy" },
    { "blacksmith",   0.90, 0.55, 0.25, "Interface\\Icons\\Trade_BlackSmithing" },
    { "enchant",      0.70, 0.45, 1.00, "Interface\\Icons\\Trade_Engraving" },
    { "engineer",     0.95, 0.75, 0.20, "Interface\\Icons\\Trade_Engineering" },
    { "herb",         0.50, 0.85, 0.30, "Interface\\Icons\\Trade_Herbalism" },
    { "leatherwork",  0.75, 0.50, 0.30, "Interface\\Icons\\Trade_LeatherWorking" },
    { "mining",       0.60, 0.70, 0.85, "Interface\\Icons\\Trade_Mining" },
    { "skinning",     0.80, 0.65, 0.45, "Interface\\Icons\\INV_Misc_Pelt_Wolf_01" },
    { "tailor",       0.90, 0.55, 0.85, "Interface\\Icons\\Trade_Tailoring" },
    { "cooking",      1.00, 0.60, 0.30, "Interface\\Icons\\INV_Misc_Food_15" },
    { "first aid",    0.95, 0.30, 0.30, "Interface\\Icons\\INV_Misc_Bandage_15" },
    { "fishing",      0.30, 0.65, 1.00, "Interface\\Icons\\Trade_Fishing" },
}
local DEFAULT_ICON = "Interface\\Icons\\INV_Misc_Book_09"

local function ClassTheme()
    local c = RAID_CLASS_COLORS and RAID_CLASS_COLORS[class]
    return {
        r = c and c.r or 1, g = c and c.g or 0.82, b = c and c.b or 0,
        icon = "Interface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES",
        coords = CLASS_ICON_TCOORDS and CLASS_ICON_TCOORDS[class],
        title = tostring(className or class) .. " Spells",
    }
end

local function ProfTheme(p)
    local prof = (p.filter == "Auto" and p.current)
        or ((p.filter ~= "All" and p.filter ~= "Auto") and p.filter) or nil
    local th = { r = 1, g = 0.82, b = 0, icon = DEFAULT_ICON, title = "Profession Skills" }
    if prof then
        th.title = prof .. " Skills"
        local pl = prof:lower()
        for _, t in ipairs(PROF_THEMES) do
            if pl:find(t[1], 1, true) then th.r, th.g, th.b, th.icon = t[2], t[3], t[4], t[5]; break end
        end
        th.icon = ProfessionIcon(prof) or th.icon
    end
    return th
end

local function TintBorder(f, r, g, b)
    if f.NineSlice and f.NineSlice.SetBorderColor then
        f.NineSlice:SetBorderColor(r, g, b)
    elseif f.SetBackdropBorderColor then
        f:SetBackdropBorderColor(r, g, b, 1)
    end
end

local function SetIcon(tex, th)
    tex:SetTexture(th.icon)
    if th.coords then tex:SetTexCoord(unpack(th.coords)) else tex:SetTexCoord(0, 1, 0, 1) end
end

------------------------------------------------------------------ UI helpers (with fallbacks)
local MakePanel, MakeScroll = SBL_UIHelpers.MakePanel, SBL_UIHelpers.MakeScroll

------------------------------------------------------------------ what each row means
local function ClassState(e, ctx)
    if e.learned or ctx.known[e.name .. "|" .. e.rank] then return "learned" end
    if ctx.myLevel >= (e.level or 0) then return "avail" end
    return "notyet"
end
local function ClassReq(e)
    return ((e.level or 0) > 0) and ("Level " .. e.level) or "\226\128\148"
end

local KnownProfessionRecipes, ScanMerchant, ProfState, ProfReq, InvalidateProfession = SBL_Professions.Create(lists, Add, SameProf, DetectProfession, PlayerSkill)

------------------------------------------------------------------ panels
local panels = {}
local professionTabWatcher
local btn, exportFrame, exportBox
local linked = false   -- "pinned": each of our windows is attached to its game window and moves with it

local function SetLinked(v)
    v = v and true or false
    if v == linked then return end
    linked = v
    DB().linked = v
    for _, pn in pairs(panels) do
        if v then pn.PinToHost(true) else pn.Unpin() end
        pn.UpdatePin()
    end
end

-- Window style helpers are defined with the theme table below.

    -- Used by every Pin button: toggles, and says what happened in chat so a click is never silent.
local function TogglePin()
    local good, e = pcall(SetLinked, not linked)
    if not good then
        print(PREFIX .. "pin error: " .. tostring(e))
    elseif linked then
        print(PREFIX .. "pinned: each window now moves together with its game window")
    else
        print(PREFIX .. "unpinned: windows move independently")
    end
end

------------------------------------------------------------------ book look
-- Two-page "open spellbook" window: left page + right page, sections (Available Now / Not Yet Available /
-- Learned), columns Spell / Rank / Required level, page turning, and a ribbon showing the class or profession.
------------------------------------------------------------------ book look
-- A single full-width page per window. Class: learned spells shown as an icon grid grouped by
-- spellbook tab, exactly like the game's own spellbook page, with a "Training" list of what you can
-- still learn (rank / required level / cost) underneath. Professions: the same training list, split
-- into Available Now / Not Yet Available / Learned, grouped by profession when showing more than one.
local WHITE = "Interface\\Buttons\\WHITE8X8"
local BOOK_W, BOOK_H = 760, 540    -- floating (undocked) default size
local MARGIN = 20
local LINE_H = 22                  -- a training row
local HEAD_MAJOR_H, HEAD_SECTION_H, HEAD_MINOR_H, HEAD_COL_H = 30, 22, 18, 18
local GRID_ICON, GRID_CELL_W, GRID_ROW_H = 34, 250, 72
local MAXCOLS = 4                  -- most grid columns we'll ever build cells for

local function CoinText(c)
    if not c or c <= 0 then return "" end
    local f = (C_CurrencyInfo and C_CurrencyInfo.GetCoinTextureString) or GetCoinTextureString
    if f then return f(c) end
    local g, rem = math.floor(c / 10000), c % 10000
    local si, cp = math.floor(rem / 100), rem % 100
    local parts = {}
    if g > 0 then parts[#parts + 1] = g .. "g" end
    if si > 0 or g > 0 then parts[#parts + 1] = si .. "s" end
    parts[#parts + 1] = cp .. "c"
    return table.concat(parts, " ")
end

------------------------------------------------------------------ docking geometry helpers
-- Frame strata, lowest to highest. The game window's own content can sit in a higher strata than the
-- window itself, so we go one above the highest one used anywhere inside it.
local STRATA = { "BACKGROUND", "LOW", "MEDIUM", "HIGH", "DIALOG", "FULLSCREEN", "FULLSCREEN_DIALOG", "TOOLTIP" }
local function StrataIndex(name)
    for i, v in ipairs(STRATA) do if v == name then return i end end
    return 4
end

local function MaxStrata(h, skip)
    local m = StrataIndex(h:GetFrameStrata())
    local function walk(fr, depth)
        if depth > 3 then return end
        for _, c in ipairs({ fr:GetChildren() }) do
            if c ~= skip and c ~= h.__sblDock then
                m = math.max(m, StrataIndex(c:GetFrameStrata()))
                walk(c, depth + 1)
            end
        end
    end
    walk(h, 1)
    return m
end

local function SetStrataDeep(fr, strata)
    fr:SetFrameStrata(strata)
    for _, c in ipairs({ fr:GetChildren() }) do SetStrataDeep(c, strata) end
end

-- How much room the game window keeps at the top for its title bar, tabs and search box: the lowest
-- bottom edge of the small frames in its top strip. Returns nil if they can't be found.
local function AutoTop(h, skip1, skip2)
    local ht = h:GetTop()
    if not ht then return nil end
    local best = 0
    local function walk(fr, depth)
        if depth > 2 then return end
        for _, c in ipairs({ fr:GetChildren() }) do
            if c ~= skip1 and c ~= skip2 then
                local n = c.GetName and c:GetName()
                local ours = type(n) == "string" and n:find("^SpellbookLevels") ~= nil
                if c:IsShown() and not ours then
                    local t, b = c:GetTop(), c:GetBottom()
                    if t and b then
                        local topOff, botOff, hgt = ht - t, ht - b, t - b
                        if topOff >= -4 and topOff <= 120 and hgt >= 8 and hgt <= 90 and botOff <= 135 then
                            best = math.max(best, botOff)
                        end
                    end
                end
                walk(c, depth + 1)
            end
        end
    end
    walk(h, 1)
    if best >= 50 then return best + 6 end
    return nil
end

-- Where the window's own real content actually stops, so our strip can use whatever's genuinely left
-- below it instead of a guessed height that either wastes space or overlaps something (e.g. the
-- profession window's per-profession columns, which extend much lower than the spellbook's content
-- ever does). Unlike AutoTop this deliberately has no narrow width/height filter - a native panel worth
-- avoiding can be as wide as the whole window (a column of recipes) or as small as a single icon.
-- Checks both child frames (GetChildren) and plain text/texture regions attached directly to a frame
-- (GetRegions) - a label like "Journeyman" under a skill bar is typically just a region, not a frame in
-- its own right, and would otherwise never be seen at all. Regions are filtered to the ARTWORK/OVERLAY
-- draw layers so a frame's own large BACKGROUND/BORDER decoration doesn't get mistaken for content
-- spanning the whole window.
local function AutoBottom(h, skip1, skip2)
    local hb, ht = h:GetBottom(), h:GetTop()
    if not (hb and ht) then return nil end
    local lowest, found = ht, false
    local function consider(c)
        if c == skip1 or c == skip2 then return end
        local n = c.GetName and c:GetName()
        local ours = type(n) == "string" and n:find("^SpellbookLevels") ~= nil
        if c:IsShown() and not ours then
            local b, t, l, r = c:GetBottom(), c:GetTop(), c:GetLeft(), c:GetRight()
            if b and t and l and r and (t - b) >= 6 and (r - l) >= 20 and b >= hb + 2 and b < lowest then
                lowest, found = b, true
            end
        end
    end
    local function walk(fr, depth)
        if depth > 4 then return end
        for _, c in ipairs({ fr:GetRegions() }) do
            local layer = c.GetDrawLayer and c:GetDrawLayer()
            if layer == "ARTWORK" or layer == "OVERLAY" then consider(c) end
        end
        for _, c in ipairs({ fr:GetChildren() }) do
            consider(c)
            walk(c, depth + 1)
        end
    end
    walk(h, 1)
    if not found then return nil end
    return ht - lowest   -- distance from the window's top down to the lowest real content's bottom edge
end

local function DockOn()
    local db = SpellbookLevelsDB
    return not (db and db.dock == false)
end
local function DockTop(key)
    local db = SpellbookLevelsDB
    local v = db and db["dockTop_" .. key]
    if v then return v end
    -- The profession window's own top chrome (title, progress bar, search/filter row, and the
    -- recipe-preview panel) runs noticeably taller than the spellbook's (just tabs + search), and our
    -- geometry auto-detection is built to find narrow tab-sized pieces, not that wide preview panel -
    -- so it needs a taller default reservation. /sbl dock top <number> overrides this per window.
    return (key == "prof") and 165 or 92
end

------------------------------------------------------------------ section styles
local SECTIONS = {
    { key = "avail",   label = "Available Now",     bg = { 0.10, 0.12, 0.10, 0.78 }, fg = { 0.55, 0.90, 0.38 } },
    { key = "notyet",  label = "Not Yet Available",  bg = { 0.12, 0.10, 0.10, 0.78 }, fg = { 0.92, 0.45, 0.38 } },
    { key = "unknown", label = "Source / Requirement Unknown", bg = { 0.12, 0.11, 0.08, 0.78 }, fg = { 0.95, 0.72, 0.30 } },
    { key = "learned", label = "Learned",            bg = { 0.10, 0.10, 0.11, 0.78 }, fg = { 0.72, 0.72, 0.76 } },
}
local SECTION_BY_KEY = {}
for _, s in ipairs(SECTIONS) do SECTION_BY_KEY[s.key] = s end

------------------------------------------------------------------ flat buttons (reskin per style)
local function FlatButton(parent, w, h, registry)
    local b = CreateFrame("Button", nil, parent)
    b:SetSize(w, h)
    b.edge = b:CreateTexture(nil, "BACKGROUND")
    b.edge:SetAllPoints()
    b.bg = b:CreateTexture(nil, "BORDER")
    b.bg:SetPoint("TOPLEFT", 1, -1)
    b.bg:SetPoint("BOTTOMRIGHT", -1, 1)
    b.label = b:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    b.label:SetPoint("CENTER", 0, 0)
    b.hl = b:CreateTexture(nil, "HIGHLIGHT")
    b.hl:SetAllPoints()
    b.hl:SetColorTexture(1, 1, 1, 0.12)
    function b:SetText(t) self.label:SetText(t) end
    function b:GetFontString() return self.label end
    function b:SetEnabled(on)
        if on then self:Enable() else self:Disable() end
        self.label:SetAlpha(on and 1 or 0.35)
    end
    function b:Skin(S)
        self.edge:SetColorTexture(S.btnEdge[1], S.btnEdge[2], S.btnEdge[3], S.btnEdge[4])
        self.bg:SetColorTexture(S.btnBg[1], S.btnBg[2], S.btnBg[3], S.btnBg[4])
        self.label:SetTextColor(S.btnText[1], S.btnText[2], S.btnText[3])
        if SpellbookLevelsEllesmereStyle then SpellbookLevelsEllesmereStyle.Control(self) end
    end
    if registry then registry[#registry + 1] = b end
    if SpellbookLevelsEllesmereStyle then SpellbookLevelsEllesmereStyle.Control(b) end
    return b
end

------------------------------------------------------------------ window styles
-- v18: four presentation modes. The class Spellbook uses a host-wide tint so the
-- Blizzard page and Training page read as one continuous two-page surface instead
-- of two differently-coloured rectangles. Professions keeps its existing styling.
local STYLE_ORDER = { "obsidian", "auto", "native", "parchment", "dark", "match" }
local STYLES = {
    auto = {
        label = "Auto",
        chrome = { 0.055, 0.045, 0.030, 0.98 }, border = { 0.28, 0.22, 0.12, 1 },
        top = { 0.115, 0.095, 0.060 }, bottom = { 0.070, 0.058, 0.038 }, shade = { 0.18, 0.12, 0.05, 0.30 },
        title = { 0.92, 0.82, 0.56 }, name = { 0.94, 0.91, 0.82 }, sub = { 0.67, 0.63, 0.54 },
        unmet = { 1.00, 0.34, 0.27 }, ok = { 0.43, 0.92, 0.35 }, learned = { 0.54, 0.51, 0.45 },
        hint = { 0.55, 0.52, 0.45 }, btnBg = { 0.10, 0.09, 0.075, 0.96 }, btnEdge = { 0.32, 0.28, 0.18, 1 }, btnText = { 0.92, 0.88, 0.72 },
    },
    native = {
        label = "Native",
        chrome = { 0.060, 0.047, 0.030, 0.98 }, border = { 0.34, 0.25, 0.12, 1 },
        top = { 0.135, 0.105, 0.060 }, bottom = { 0.075, 0.060, 0.038 }, shade = { 0.20, 0.12, 0.04, 0.32 },
        title = { 0.95, 0.83, 0.52 }, name = { 0.95, 0.92, 0.84 }, sub = { 0.68, 0.63, 0.53 },
        unmet = { 1.00, 0.34, 0.27 }, ok = { 0.43, 0.92, 0.35 }, learned = { 0.54, 0.51, 0.45 },
        hint = { 0.55, 0.52, 0.45 }, btnBg = { 0.11, 0.09, 0.06, 0.96 }, btnEdge = { 0.38, 0.29, 0.14, 1 }, btnText = { 0.95, 0.84, 0.55 },
    },
    parchment = {
        label = "Parchment",
        chrome = { 0.10, 0.07, 0.04, 0.98 }, border = { 0.45, 0.33, 0.15, 1 },
        top = { 0.90, 0.82, 0.64 }, bottom = { 0.80, 0.70, 0.50 }, shade = { 0.25, 0.15, 0.05, 0.42 },
        title = { 0.24, 0.14, 0.04 }, name = { 0.16, 0.09, 0.03 }, sub = { 0.34, 0.24, 0.14 },
        unmet = { 0.70, 0.10, 0.08 }, ok = { 0.08, 0.45, 0.10 }, learned = { 0.42, 0.37, 0.32 },
        hint = { 0.35, 0.26, 0.16 }, btnBg = { 0.24, 0.16, 0.08, 0.96 }, btnEdge = { 0.58, 0.44, 0.20, 1 }, btnText = { 1.0, 0.88, 0.55 },
    },
    dark = {
        label = "Dark",
        chrome = { 0.025, 0.025, 0.030, 0.99 }, border = { 0.24, 0.24, 0.28, 1 },
        top = { 0.075, 0.075, 0.085 }, bottom = { 0.035, 0.035, 0.045 }, shade = { 0, 0, 0, 0.55 },
        title = { 0.92, 0.86, 0.70 }, name = { 0.92, 0.92, 0.94 }, sub = { 0.62, 0.62, 0.68 },
        unmet = { 1.00, 0.36, 0.30 }, ok = { 0.45, 0.90, 0.40 }, learned = { 0.55, 0.55, 0.58 },
        hint = { 0.55, 0.55, 0.60 }, btnBg = { 0.12, 0.12, 0.15, 0.96 }, btnEdge = { 0.30, 0.30, 0.36, 1 }, btnText = { 0.92, 0.92, 0.95 },
    },
}

-- A flat warm-dark palette matching Ellesmere's Blizzard window controls.
-- Kept in the existing style system so the View button and saved preference agree.
STYLES.match = {
    label = "Match Skin",
    chrome = {0.03, 0.03, 0.03, 1}, border = {0.18, 0.18, 0.18, 1},
    top = {0.068, 0.056, 0.052}, bottom = {0.03, 0.03, 0.03}, shade = {0, 0, 0, 0.4},
    title = {1, 1, 1}, name = {0.94, 0.94, 0.94}, sub = {0.65, 0.65, 0.65},
    unmet = {1, 0.36, 0.30}, ok = {0.45, 0.90, 0.40}, learned = {0.55, 0.55, 0.55},
    hint = {0.55, 0.55, 0.55}, btnBg = {0.03, 0.03, 0.03, 1},
    btnEdge = {0.18, 0.18, 0.18, 1}, btnText = {1, 1, 1},
}

STYLES.obsidian = {}
for key,value in pairs(STYLES.dark) do STYLES.obsidian[key]=value end
STYLES.obsidian.label="Obsidian Gold"
STYLES.obsidian.title={.91,.80,.57}
STYLES.obsidian.border={.70,.58,.36,1}
STYLES.obsidian.name={.91,.91,.88}
STYLES.obsidian.sub={.65,.69,.75}
local function GetStyle()
    local db = SpellbookLevelsDB
    if db and not db.obsidianDesignVersion then
        db.styleBeforeObsidian=db.style
        db.style="obsidian";db.obsidianDesignVersion=1
    end
    local st = db and db.style
    if STYLES[st] then return st end
    return "obsidian"
end

local function CycleStyle(st)
    if not st or not STYLES[st] then
        local cur = GetStyle()
        for i, v in ipairs(STYLE_ORDER) do
            if v == cur then st = STYLE_ORDER[i % #STYLE_ORDER + 1]; break end
        end
        st = st or "auto"
    end
    local db = DB()
    db.style = st
    db.plainTheme = nil
    for _, pn in pairs(panels) do
        if pn.ApplyTheme then pn.ApplyTheme() end
        if pn.frame:IsShown() then pn.Refresh() end
    end
    return st
end

local function VGradient(tex, top, bottom)
    tex:SetColorTexture(top[1], top[2], top[3], 1)
    if tex.SetGradient and CreateColor then
        pcall(tex.SetGradient, tex, "VERTICAL",
            CreateColor(bottom[1], bottom[2], bottom[3], 1), CreateColor(top[1], top[2], top[3], 1))
    end
end

------------------------------------------------------------------ frame helpers
local function MakeBookFrame(name)
    local okb, fr = pcall(CreateFrame, "Frame", name, UIParent, "BackdropTemplate")
    local f = (okb and fr) or CreateFrame("Frame", name, UIParent)
    f:SetSize(BOOK_W, BOOK_H)
    if f.SetBackdrop then f:SetBackdrop({ edgeFile = WHITE, edgeSize = 2 }) end
    return f
end

local function BookFont(fs, size)
    local okf = fs:SetFont("Fonts\\MORPHEUS.TTF", size, "")
    if not okf then fs:SetFontObject("GameFontNormalLarge") end
end

local function MakeScroll(name, parent)
    local ok2, s = pcall(CreateFrame, "ScrollFrame", name, parent, "UIPanelScrollFrameTemplate")
    if not (ok2 and s) then
        s = CreateFrame("ScrollFrame", nil, parent)
        s:EnableMouseWheel(true)
        s:SetScript("OnMouseWheel", function(self, d)
            local cur, max = self:GetVerticalScroll(), self:GetVerticalScrollRange()
            self:SetVerticalScroll(math.max(0, math.min(max, cur - d * 36)))
        end)
    end
    return s
end

------------------------------------------------------------------ item list construction
-- Build the flat, page-agnostic list of things to draw for one panel, given its (already filtered)
-- entries. Each item carries a "kind" and an "h" (height in pixels).
local function BuildItems(cfg, entries, ctx, pageTitle, gridCols)
    gridCols = math.max(1, gridCols or 1)
    local items = {}
    local function push(it) items[#items + 1] = it end
    local function pushLearnedCards(list, state)
        local col, row = 0, nil
        for _, e in ipairs(list) do
            if col == 0 then
                row = { kind = "grid", entries = {}, state = state, h = GRID_ROW_H }
                push(row)
            end
            row.entries[#row.entries + 1] = e
            col = col + 1
            if col >= gridCols then col = 0 end
        end
    end
    local function pushTrainingRows(list, state)
        push({ kind = "colhead", h = HEAD_COL_H })
        for _, e in ipairs(list) do push({ kind = "train", e = e, state = state, h = LINE_H }) end
    end

    push({ kind = "head", style = "major", text = pageTitle or "", h = HEAD_MAJOR_H })
    local groups = { avail = {}, notyet = {}, unknown = {}, learned = {} }
    for _, e in ipairs(entries) do
        local st = cfg.state(e, ctx)
        table.insert(groups[st], e)
    end
    local showSub = cfg.subKey and cfg.wantSub and cfg.wantSub(ctx)
    for _, def in ipairs(SECTIONS) do
        local g = groups[def.key]
        if #g > 0 then
            table.sort(g, cfg.sort)
            push({ kind = "head", style = "section", def = def, text = def.label .. " \194\183 " .. #g, h = HEAD_SECTION_H })
            if showSub then
                local counts, order, seen, bucket = {}, {}, {}, {}
                for _, e in ipairs(g) do
                    local k = cfg.subKey(e) or "Other"
                    counts[k] = (counts[k] or 0) + 1
                    if not seen[k] then seen[k] = true; order[#order + 1] = k end
                    bucket[k] = bucket[k] or {}
                    table.insert(bucket[k], e)
                end
                for _, k in ipairs(order) do
                    push({ kind = "head", style = "minor", text = k .. " \194\183 " .. counts[k], h = HEAD_MINOR_H })
                    if cfg.kind == "class" then
                        pushLearnedCards(bucket[k], def.key)
                    else
                        pushTrainingRows(bucket[k], def.key)
                    end
                end
            else
                if cfg.kind == "class" then
                    pushLearnedCards(g, def.key)
                else
                    pushTrainingRows(g, def.key)
                end
            end
        end
    end
    return items
end

local function PushContinuation(cur, it, style)
    cur[#cur + 1] = { kind = "head", style = style, def = it.def, text = it.text:gsub(" \194\183 %d+$", "") .. " (continued)", h = it.h }
end

-- Split a flat item list into pages that fit `pageHeight`. A header is never left as the last thing
-- on a page with no real row under it - any trailing header(s) are carried forward onto the next page
-- instead. Interrupted major/section headings not already carried are repeated ("continued") too, so
-- context is never lost.
local function IsContentKind(k) return k == "grid" or k == "train" end

local function PaginateH(items, pageHeight)
    local pages, cur, curH = {}, {}, 0
    local lastMajor, lastSection
    local function flush()
        local carry = {}
        while #cur > 0 and not IsContentKind(cur[#cur].kind) do
            table.insert(carry, 1, table.remove(cur))
        end
        if #cur > 0 then pages[#pages + 1] = cur end
        cur, curH = {}, 0
        for _, it in ipairs(carry) do
            cur[#cur + 1] = it
            curH = curH + it.h
        end
    end
    for _, it in ipairs(items) do
        if it.kind == "head" then
            if it.style == "major" then lastMajor, lastSection = it, nil
            elseif it.style == "section" then lastSection = it end
        end
        if curH + it.h > pageHeight and #cur > 0 then
            flush()
            local haveMajor, haveSection = false, false
            for _, it2 in ipairs(cur) do
                if it2.kind == "head" and it2.style == "major" then haveMajor = true end
                if it2.kind == "head" and it2.style == "section" then haveSection = true end
            end
            if lastMajor and not haveMajor then
                PushContinuation(cur, lastMajor, "major"); curH = curH + HEAD_MAJOR_H
            end
            if lastSection and not haveSection then
                PushContinuation(cur, lastSection, "section"); curH = curH + HEAD_SECTION_H
            end
        end
        cur[#cur + 1] = it
        curH = curH + it.h
    end
    while #cur > 0 and not IsContentKind(cur[#cur].kind) do table.remove(cur) end
    if #cur > 0 then pages[#pages + 1] = cur end
    return pages
end

------------------------------------------------------------------ build one panel (window)
local IsTalentPage

local function SearchMatches(e, query)
    local text = table.concat({ e.name or "", e.rank or "", e.prof or "",
        e.source or "", e.sourceName or "", e.sourceZone or "" }, " "):lower()
    for word in (query or ""):lower():gmatch("%S+") do
        if not text:find(word, 1, true) then return false end
    end
    return true
end

local function NewPanel(cfg)
    local p = { key = cfg.key, filter = cfg.defaultFilter or "All", userOpen = false, autoShown = false,
                suppress = false, page = 1, pageCount = 1, pages = {}, total = 0, docked = false,
                planMode = "all",
                native = false, gridCols = 1, hostKey = cfg.hostKey, hiddenByTab = false }

    local f = MakeBookFrame(cfg.frameName)
    p.frame = f
    f:SetPoint("CENTER", 0, 0)
    do
        local sz = Preferences()["winSize_" .. cfg.key]
        if sz and sz[1] and sz[2] then
            f:SetSize(math.max(420, sz[1]), math.max(320, sz[2]))
        end
    end
    f:SetMovable(true)
    f:EnableMouse(true)
    f:EnableMouseWheel(true)
    f:SetClampedToScreen(true)

    -- A real resize grip instead of a fixed 760x540 window.  When docked, the grip resizes
    -- the reserved native-window area; when floating, it resizes the addon window itself.
    local resize = CreateFrame("Button", nil, f)
    resize:SetSize(18, 18)
    resize:SetPoint("BOTTOMRIGHT", -2, 2)
    resize:SetFrameLevel(f:GetFrameLevel() + 20)
    resize:EnableMouse(true)
    resize:RegisterForDrag("LeftButton")
    resize.tex = resize:CreateTexture(nil, "OVERLAY")
    resize.tex:SetSize(12, 12)
    resize.tex:SetPoint("BOTTOMRIGHT", -1, 1)
    resize.tex:SetTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
    resize:SetScript("OnEnter", function()
        resize.tex:SetTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
    end)
    resize:SetScript("OnLeave", function()
        resize.tex:SetTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
    end)
    resize:SetScript("OnDragStart", function()
        if p.docked then
            if p.dockResize then p.dockResize(true) end
        elseif not InCombatLockdown() then
            f:StartSizing("BOTTOMRIGHT")
        end
    end)
    resize:SetScript("OnDragStop", function()
        if p.docked then
            if p.dockResize then p.dockResize(false) end
        else
            f:StopMovingOrSizing()
            local w, h = f:GetSize()
            local db = DB()
            Preferences()["winSize_" .. p.key] = { w, h }
            p.Refresh()
        end
    end)
    f.__sblResize = resize
    f:Hide()
    tinsert(UISpecialFrames, cfg.frameName)

    local chromeBg = f:CreateTexture(nil, "BACKGROUND")
    chromeBg:SetAllPoints()

    local function SetEsc(on)
        for i = #UISpecialFrames, 1, -1 do
            if UISpecialFrames[i] == cfg.frameName then table.remove(UISpecialFrames, i) end
        end
        if on then tinsert(UISpecialFrames, cfg.frameName) end
    end

    ---------------------------------------------------------------- dragging (drags the game window when docked/pinned)
    local function StartDrag()
        if p.docked then return end   -- the native window's own title bar already moves it; dragging
                                       -- our strip too is redundant and risks moving the whole game
                                       -- window from an accidental drag started near one of our buttons
        local h = p.host
        if linked and h and h:IsShown() and not InCombatLockdown() then
            p.dragHost = h
            pcall(h.StartMoving, h)
        else
            f:StartMoving()
        end
    end
    local function SavePos()
        local h = p.dragHost
        p.dragHost = nil
        if h then
            h:StopMovingOrSizing()
            local point, _, relPoint, x, y = h:GetPoint()
            Preferences()["hostPos_" .. p.hostKey] = { point, relPoint, x, y }
        else
            f:StopMovingOrSizing()
            local point, _, relPoint, x, y = f:GetPoint()
            Preferences()["winPos_" .. p.key] = { point, relPoint, x, y }
        end
    end
    -- Only the top strip (grip) drags the window - not the whole frame, which would otherwise fight
    -- with dragging a card to your action bar the moment the drag starts anywhere over a card.
    local grip = CreateFrame("Frame", nil, f)
    grip:SetPoint("TOPLEFT", 0, 0)
    grip:SetPoint("TOPRIGHT", 0, 0)
    grip:SetHeight(30)
    grip:SetFrameLevel(f:GetFrameLevel() + 2)
    grip:EnableMouse(true)
    grip:RegisterForDrag("LeftButton")
    grip:SetScript("OnDragStart", StartDrag)
    grip:SetScript("OnDragStop", SavePos)

    ---------------------------------------------------------------- top bar
    local btns = {}
    p.filterBtn = FlatButton(f, cfg.kind=="prof" and 130 or 164, 22, btns)
    p.filterBtn:SetPoint("TOPLEFT", 12, -5)
    p.filterBtn:SetFrameLevel(f:GetFrameLevel() + 10)

    p.styleBtn = FlatButton(f, cfg.kind=="prof" and 92 or 108, 22, btns)
    p.styleBtn:SetPoint("LEFT", p.filterBtn, "RIGHT", 6, 0)
    p.styleBtn:SetScript("OnClick", function(self)
        local choices={}
        for _,value in ipairs(STYLE_ORDER) do choices[#choices+1]={value=value,label=STYLES[value].label} end
        ChoiceMenu(self,choices,GetStyle(),function(value) CycleStyle(value) end)
    end)
    p.styleBtn:SetFrameLevel(f:GetFrameLevel() + 10)

    p.search = CreateFrame("EditBox", nil, f, "InputBoxTemplate")
    p.search:SetAutoFocus(false)
    p.search:SetHeight(22)
    p.search:SetPoint("TOPLEFT", f, "TOPLEFT", 20, -36)
    p.search:SetPoint("TOPRIGHT", f, "TOPRIGHT", -48, -36)
    p.search:SetFrameLevel(f:GetFrameLevel() + 10)
    p.search:SetMaxLetters(120)
    p.searchHint = p.search:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    p.searchHint:SetPoint("LEFT", 0, 0)
    p.searchHint:SetText(cfg.kind == "prof" and "Search recipes or sources" or "Search spells or ranks")
    p.search:SetScript("OnTextChanged", function(self)
        p.searchQuery = self:GetText() or ""
        p.searchHint:SetShown(p.searchQuery == "")
        p.page = 1
        if p.Refresh then p.Refresh() end
    end)
    p.search:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    p.search:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
    p.searchClear = FlatButton(f, 22, 22, btns)
    p.searchClear:SetPoint("LEFT", p.search, "RIGHT", 8, 0)
    p.searchClear:SetFrameLevel(f:GetFrameLevel() + 10)
    p.searchClear:SetText("x")
    p.searchClear:SetScript("OnClick", function() p.search:SetText(""); p.search:ClearFocus() end)
    if cfg.kind == "prof" then
        p.search:ClearAllPoints()
        p.search:SetPoint("TOPLEFT", f, "TOPLEFT", 20, -36)
        p.search:SetPoint("TOPRIGHT", f, "TOPRIGHT", -148, -36)
        local materials=FlatButton(f,90,22,btns)
        materials:SetPoint("TOPRIGHT",f,"TOPRIGHT",-12,-36)
        materials:SetFrameLevel(f:GetFrameLevel()+10)
        materials:SetText("Materials")
        materials:SetScript("OnClick",function()
            SBL_Materials.Show(nil,f,DetectProfession() or p.current or (lists.prof[1] and lists.prof[1].prof))
        end)
    end
    if cfg.kind == "prof" then
        p.sourceMode = (DB()["sourceMode_" .. p.key] or "known")
        p.sourceBtn = FlatButton(f, 98, 22, btns)
        p.sourceBtn:SetPoint("LEFT", p.styleBtn, "RIGHT", 6, 0)
        p.sourceBtn:SetFrameLevel(f:GetFrameLevel() + 10)
        local function UpdateSourceButton()
            if not p.sourceBtn then return end
            local labels={known="Known",all="All",unknown="Unknown"}
            p.sourceBtn:SetText("Sources: "..(labels[p.sourceMode] or "Known"))
        end
        p.UpdateSourceButton=UpdateSourceButton
        p.sourceBtn:SetScript("OnClick", function(self)
            ChoiceMenu(self, {{value="known",label="Known sources"},{value="all",label="All sources"},{value="unknown",label="Unknown sources"}}, p.sourceMode, function(value)
                p.sourceMode=value; Preferences()["sourceMode_"..p.key]=value
                UpdateSourceButton(); p.page=1; p.Refresh()
            end)
        end)
        UpdateSourceButton()
    end
    do
        p.planBtn = FlatButton(f, 122, 22, btns)
        p.planBtn:SetFrameLevel(f:GetFrameLevel() + 10)
        p.planSummary = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        p.planSummary:SetJustifyH("LEFT")
        local modes = { "now", "next", "plus5", "all", "learned" }
        local labels = { now="Available now", next="Next level", plus5="Next 5 levels", all="All upcoming", learned="Learned" }
        p.planBtn:SetScript("OnClick", function(self)
            local choices={}
            for _,value in ipairs(modes) do
                if cfg.kind=="class" or (value~="next" and value~="plus5") then choices[#choices+1]={value=value,label=labels[value]} end
            end
            ChoiceMenu(self,choices,p.planMode,function(value)
                p.planMode=value; Preferences()["planMode_"..p.key]=value; p.page=1; p.Refresh()
            end)
        end)
        function p.UpdatePlannerText() p.planBtn:SetText(labels[p.planMode] or "Available Now") end
        p.UpdatePlannerText()
    end

    local pin = FlatButton(f, 54, 20, btns)
    pin:SetPoint("TOPRIGHT", -32, -7)
    pin:SetFrameLevel(f:GetFrameLevel() + 10)
    pin:EnableMouse(true)
    pin:SetScript("OnClick", TogglePin)
    pin:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:AddLine("Pin to the game window")
        GameTooltip:AddLine("When pinned, this window and the game's own window move together as one. Drag either one.", 1, 1, 1, true)
        GameTooltip:Show()
    end)
    pin:SetScript("OnLeave", function() GameTooltip:Hide() end)
    function p.UpdatePin()
        pin:SetText(linked and "Pinned" or "Pin")
        local fs = pin.GetFontString and pin:GetFontString()
        if fs then
            if linked then fs:SetTextColor(0.3, 1, 0.3) else fs:SetTextColor(1, 0.82, 0) end
        end
    end
    p.UpdatePin()

    local okc, close = pcall(CreateFrame, "Button", nil, f, "UIPanelCloseButton")
    if okc and close then
        close:SetPoint("TOPRIGHT", 2, 2)
        close:SetFrameLevel(f:GetFrameLevel() + 10)
        close:SetScript("OnClick", function() f:Hide() end)
    end

    function p.UpdateChrome()
        local showSearch = not (p.docked and cfg.dockAnchor == "inlineSpellbook")
        p.search:SetShown(showSearch)
        p.searchClear:SetShown(showSearch)
        if close then close:SetShown(not p.docked) end
        pin:SetShown((not p.docked) and not DockOn())
        p.styleBtn:SetShown(true)
        p.styleBtn:ClearAllPoints()
        if p.docked and cfg.kind == "class" then
            p.styleBtn:SetPoint("TOPRIGHT", f, "TOPRIGHT", -16, -8)
            if p.planBtn then
                p.planBtn:ClearAllPoints(); p.planBtn:SetPoint("TOPLEFT", f, "TOPLEFT", 16, -8); p.planBtn:Show()
                p.planSummary:ClearAllPoints(); p.planSummary:SetPoint("LEFT", p.planBtn, "RIGHT", 12, 0)
                p.planSummary:SetPoint("RIGHT", p.styleBtn, "LEFT", -12, 0); p.planSummary:Show()
            end
        else
            p.styleBtn:SetPoint("LEFT", p.filterBtn, "RIGHT", 6, 0)
            if p.sourceBtn then
                p.sourceBtn:ClearAllPoints(); p.sourceBtn:SetPoint("LEFT", p.styleBtn, "RIGHT", 6, 0); p.sourceBtn:Show()
                if p.UpdateSourceButton then p.UpdateSourceButton() end
            end
            if p.planBtn then
                p.planBtn:ClearAllPoints(); p.planBtn:SetPoint("LEFT", p.sourceBtn or p.styleBtn, "RIGHT", 6, 0)
                p.planBtn:Show(); p.planSummary:Hide()
            end
        end
        p.filterBtn:SetShown((not p.docked) or cfg.kind == "prof")
        resize:SetShown(not p.docked)
    end

    ---------------------------------------------------------------- content area + pools
    local page = CreateFrame("Frame", nil, f)
    page:SetPoint("TOPLEFT", f, "TOPLEFT", MARGIN, -68)
    page:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -MARGIN, 40)
    if page.SetClipsChildren then page:SetClipsChildren(true) end
    page.bg = page:CreateTexture(nil, "BACKGROUND")
    page.bg:SetPoint("TOPLEFT", -10, 6)
    page.bg:SetPoint("BOTTOMRIGHT", 10, -6)

    local total = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    if cfg.kind == "prof" then
        -- The second header row belongs to search and Materials. Keep the
        -- training-price summary in the reserved footer, clear of the pager.
        total:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", MARGIN, 14)
        total:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -190, 14)
        total:SetJustifyH("LEFT")
        total:SetWordWrap(false)
    else
        total:SetPoint("TOPRIGHT", page, "TOPRIGHT", 0, 16)
    end
    local hint = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    hint:SetPoint("BOTTOMLEFT", page, "BOTTOMLEFT", 0, -22)
    hint:SetText(cfg.kind == "prof" and "Hover a skill for details"
        or "Hover for details \194\183 drag learned spells to your bars \194\183 Shift-click to link")
    local empty = page:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    empty:SetPoint("TOPLEFT", 4, -4)
    empty:SetPoint("TOPRIGHT", -4, -4)
    empty:SetJustifyH("LEFT")
    empty:SetWordWrap(true)
    empty:SetSpacing(4)
    empty:Hide()

    local pageText = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    pageText:SetPoint("BOTTOMRIGHT", page, "BOTTOMRIGHT", -70, -22)
    local navPrev = FlatButton(f, 50, 24, btns)
    navPrev:SetPoint("RIGHT", pageText, "LEFT", -6, 0)
    local navNext = FlatButton(f, 50, 24, btns)
    navNext:SetPoint("LEFT", pageText, "RIGHT", 6, 0)
    navPrev:SetText("Prev"); navNext:SetText("Next")
    local function Turn(delta)
        p.page = math.max(1, math.min(p.pageCount, p.page + delta))
        p.Render()
    end
    navPrev:SetScript("OnClick", function() Turn(-1) end)
    navNext:SetScript("OnClick", function() Turn(1) end)
    f:SetScript("OnMouseWheel", function(_, d) if d > 0 then Turn(-1) else Turn(1) end end)

    -- pooled row frames, reused between renders -------------------------------------------------
    local headPool, gridPool, trainPool = {}, {}, {}

    local function GetHead(i)
        if headPool[i] then return headPool[i] end
        local h = CreateFrame("Frame", nil, page)
        h:SetPoint("LEFT", page, "LEFT", 0, 0)
        h:SetPoint("RIGHT", page, "RIGHT", 0, 0)
        h.bar = h:CreateTexture(nil, "BACKGROUND")
        h.bar:SetAllPoints()
        h.rule = h:CreateTexture(nil, "ARTWORK")
        h.rule:SetPoint("BOTTOMLEFT", 0, 0)
        h.rule:SetPoint("BOTTOMRIGHT", 0, 0)
        h.rule:SetHeight(1)
        h.text = h:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        h.text:SetPoint("LEFT", 6, 0)
        h.c1 = h:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        h.c1:SetPoint("LEFT", 30, 0)
        h.c2 = h:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        h.c2:SetPoint("RIGHT", h, "RIGHT", -200, 0)
        h.c2:SetWidth(76); h.c2:SetJustifyH("LEFT")
        h.c3 = h:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        h.c3:SetPoint("RIGHT", h, "RIGHT", -98, 0)
        h.c3:SetWidth(96); h.c3:SetJustifyH("LEFT")
        h.c4 = h:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        h.c4:SetPoint("RIGHT", h, "RIGHT", -2, 0)
        h.c4:SetWidth(90); h.c4:SetJustifyH("LEFT")
        h.c1:SetPoint("RIGHT", h.c2, "LEFT", -6, 0)
        h.c1:SetJustifyH("LEFT")
        h.c1:SetText("Name")
        h.c2:SetText(cfg.kind == "prof" and "Source" or "Rank")
        h.c3:SetText("Required"); h.c4:SetText("Cost")
        headPool[i] = h
        return h
    end

    local function GetGrid(i)
        if gridPool[i] then return gridPool[i] end
        local r = CreateFrame("Frame", nil, page)
        r:SetPoint("LEFT", page, "LEFT", 0, 0)
        r:SetPoint("RIGHT", page, "RIGHT", 0, 0)
        r.cells = {}
        for c = 1, MAXCOLS do
            local cell = CreateFrame("Frame", nil, r)
            cell:SetPoint("TOPLEFT", (c - 1) * GRID_CELL_W, 0)
            cell:SetSize(GRID_CELL_W, GRID_ROW_H)
            cell:EnableMouse(true)
            cell.icon = cell:CreateTexture(nil, "ARTWORK")
            cell.icon:SetSize(GRID_ICON, GRID_ICON)
            cell.icon:SetPoint("LEFT", 0, 0)
            cell.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)   -- trim the icon's own edge bleed
            if cfg.kind == "class" and cell.CreateMaskTexture then
                local mask = cell:CreateMaskTexture()
                mask:SetTexture("Interface\\CharacterFrame\\TempPortraitAlphaMask", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
                mask:SetAllPoints(cell.icon)
                cell.icon:AddMaskTexture(mask)
                cell.iconMask = mask
            end
            cell.iconBorder = cell:CreateTexture(nil, "BORDER")
            cell.iconBorder:SetPoint("TOPLEFT", cell.icon, "TOPLEFT", -1, 1)
            cell.iconBorder:SetPoint("BOTTOMRIGHT", cell.icon, "BOTTOMRIGHT", 1, -1)
            if cfg.kind == "class" then cell.iconBorder:SetAlpha(0)
            else cell.iconBorder:SetColorTexture(0, 0, 0, 1) end
            cell.name = cell:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            cell.name:SetPoint("TOPLEFT", cell.icon, "TOPRIGHT", 8, -1)
            cell.name:SetPoint("RIGHT", -4, 0)
            cell.name:SetJustifyH("LEFT")
            cell.name:SetWordWrap(false)
            cell.sub = cell:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            cell.sub:SetPoint("BOTTOMLEFT", cell.icon, "BOTTOMRIGHT", 8, 1)
            cell.sub:SetJustifyH("LEFT")
            cell:SetScript("OnEnter", function(self)
                local e = self.entry
                if not e then return end
                self.hl:Show()
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                if self.state == "learned" and e.id and GameTooltip.SetSpellByID then
                    GameTooltip:SetSpellByID(e.id); SBL_Provenance.Tooltip(e, SpellbookLevelsDB); GameTooltip:Show(); return
                end
                GameTooltip:AddLine(e.name .. ((e.rank or "") ~= "" and (" (" .. e.rank .. ")") or ""), 1, 1, 1)
                if cfg.kind == "prof" then
                    GameTooltip:AddLine("Requires " .. (e.prof or "profession") .. " skill " .. (e.skill or 0))
                    if e.source then GameTooltip:AddLine("Source: " .. e.source .. (e.sourceName and (" - "..e.sourceName) or ""), .82,.82,.82) end
                    if e.sourceZone then
                        local loc = e.sourceZone
                        if e.sourceX and e.sourceY then loc = loc .. string.format(" (%.1f, %.1f)", e.sourceX*100, e.sourceY*100) end
                        GameTooltip:AddLine("Location: " .. loc, .72,.72,.72)
                    end
                    if (e.level or 0) > 0 then GameTooltip:AddLine("Character level " .. e.level) end
                else
                    GameTooltip:AddLine("Requires level " .. (e.level or 0))
                    if e.tree then GameTooltip:AddLine("Talent tree: " .. e.tree) end
                end
                if e.cost and e.cost > 0 then GameTooltip:AddLine("Cost: " .. CoinText(e.cost), 1, 1, 1) end
                SBL_Provenance.Tooltip(e, SpellbookLevelsDB)
                GameTooltip:AddLine(self.state == "learned" and "Already learned"
                    or (self.state == "avail" and "You can train this now" or "Not available yet"),
                    self.state == "avail" and 0.3 or 0.8, self.state == "avail" and 1 or 0.8, self.state == "avail" and 0.3 or 0.8)
                GameTooltip:Show()
            end)
            cell:SetScript("OnLeave", function(self) self.hl:Hide(); GameTooltip:Hide() end)
            cell.hl = cell:CreateTexture(nil, "BACKGROUND")
            cell.hl:SetAllPoints()
            cell.hl:SetColorTexture(1, 1, 1, 0.06)
            cell.hl:Hide()
            cell:RegisterForDrag("LeftButton")
            cell:SetScript("OnDragStart", function(self)
                local e = self.entry
                local pick = (C_Spell and C_Spell.PickupSpell) or PickupSpell
                if self.state == "learned" and e and e.id and pick and not InCombatLockdown() then pick(e.id) else StartDrag() end
            end)
            cell:SetScript("OnDragStop", function() SavePos() end)
            cell:SetScript("OnMouseUp", function(self, button)
                local e = self.entry
                if button == "LeftButton" and self.state == "learned" and e and e.id and IsShiftKeyDown and IsShiftKeyDown() then
                    local link = C_Spell and C_Spell.GetSpellLink and C_Spell.GetSpellLink(e.id)
                    if link and ChatEdit_InsertLink then ChatEdit_InsertLink(link) end
                end
            end)
            r.cells[c] = cell
        end
        gridPool[i] = r
        return r
    end

    local function GetTrain(i)
        if trainPool[i] then return trainPool[i] end
        local r = CreateFrame("Frame", nil, page)
        r:SetPoint("LEFT", page, "LEFT", 0, 0)
        r:SetPoint("RIGHT", page, "RIGHT", 0, 0)
        r:SetHeight(LINE_H)
        r:EnableMouse(true)
        r.zebra = r:CreateTexture(nil, "BACKGROUND", nil, 0)
        r.zebra:SetAllPoints()
        r.zebra:SetColorTexture(1, 1, 1, (i % 2 == 0) and 0.05 or 0)
        r.hl = r:CreateTexture(nil, "BACKGROUND", nil, 1)
        r.hl:SetAllPoints()
        r.hl:SetColorTexture(1, 1, 1, 0.07)
        r.hl:Hide()
        r.icon = r:CreateTexture(nil, "ARTWORK")
        r.icon:SetSize(16, 16)
        r.icon:SetPoint("LEFT", 2, 0)
        r.name = r:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        r.name:SetPoint("LEFT", r.icon, "RIGHT", 6, 0)
        r.name:SetJustifyH("LEFT")
        r.name:SetWordWrap(false)
        r.cost = r:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        r.cost:SetPoint("RIGHT", r, "RIGHT", -2, 0)
        r.cost:SetWidth(90)
        r.cost:SetJustifyH("LEFT")
        r.req = r:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        r.req:SetPoint("RIGHT", r.cost, "LEFT", -6, 0)
        r.req:SetWidth(96)
        r.req:SetJustifyH("LEFT")
        r.rank = r:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        r.rank:SetPoint("RIGHT", r.req, "LEFT", -6, 0)
        r.rank:SetWidth(76)
        r.rank:SetJustifyH("LEFT")
        r.name:SetPoint("RIGHT", r.rank, "LEFT", -6, 0)
        r:SetScript("OnEnter", function(self)
            local e = self.entry
            if not e then return end
            self.hl:Show()
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            if e.learned and e.id and GameTooltip.SetSpellByID then GameTooltip:SetSpellByID(e.id); SBL_Provenance.Tooltip(e, SpellbookLevelsDB); GameTooltip:Show(); return end
            GameTooltip:AddLine(e.name .. ((e.rank or "") ~= "" and (" (" .. e.rank .. ")") or ""), 1, 1, 1)
            if cfg.kind == "prof" then
                GameTooltip:AddLine("Requires " .. (e.prof or "profession") .. " skill " .. (e.skill or 0))
                GameTooltip:AddLine("Left-click to view materials and batch requirements", .7,.85,1)
                if e.source then GameTooltip:AddLine("Source: " .. e.source .. (e.sourceName and (" - "..e.sourceName) or ""), .82,.82,.82) end
                if e.sourceZone then
                        local loc = e.sourceZone
                        if e.sourceX and e.sourceY then loc = loc .. string.format(" (%.1f, %.1f)", e.sourceX*100, e.sourceY*100) end
                        GameTooltip:AddLine("Location: " .. loc, .72,.72,.72)
                    end
                if (e.level or 0) > 0 then GameTooltip:AddLine("Character level " .. e.level) end
            else
                GameTooltip:AddLine("Requires level " .. (e.level or 0))
                if e.tree then GameTooltip:AddLine("Talent tree: " .. e.tree) end
            end
            if e.cost and e.cost > 0 then GameTooltip:AddLine("Cost: " .. CoinText(e.cost), 1, 1, 1) end
                SBL_Provenance.Tooltip(e, SpellbookLevelsDB)
            local st = self.state
            GameTooltip:AddLine(st == "learned" and "Already learned"
                or (st == "avail" and "You can train this now" or "Not available yet"),
                st == "avail" and 0.3 or 0.8, st == "avail" and 1 or 0.8, st == "avail" and 0.3 or 0.8)
            GameTooltip:Show()
        end)
        r:SetScript("OnLeave", function(self) self.hl:Hide(); GameTooltip:Hide() end)
        if cfg.kind == "prof" then
            r:SetScript("OnMouseDown",function(self,button)
                if button=="LeftButton" and self.entry then SBL_Materials.Show(self.entry,p.frame) end
            end)
        end
        trainPool[i] = r
        return r
    end

    ---------------------------------------------------------------- theming
    local function ApplySpellbookHostTheme(styleKey, style)
        if not (cfg.kind == "class" and p.docked and p.host and cfg.dockAnchor == "extendRight") then return end
        local h = p.host
        if not h.__sblUnifiedTint then
            local t = h:CreateTexture(nil, "ARTWORK", nil, -7)
            t:SetPoint("TOPLEFT", h, "TOPLEFT", 8, -64)
            t:SetPoint("BOTTOMRIGHT", h, "BOTTOMRIGHT", -8, 8)
            h.__sblUnifiedTint = t
        end
        local t = h.__sblUnifiedTint
        -- Auto/Native deliberately leave Blizzard's left page untouched and make our
        -- new page match that same warm book surface. Dark/Parchment apply a light
        -- host-wide tint so both halves shift together while native spell controls stay visible.
        if styleKey == "dark" then
            t:SetColorTexture(0.0, 0.0, 0.0, 0.34); t:Show()
        elseif styleKey == "parchment" then
            t:SetColorTexture(0.72, 0.52, 0.25, 0.12); t:Show()
        else
            t:Hide()
        end
    end

    function p.ApplyTheme()
        local th = cfg.theme(p)
        local styleKey = GetStyle()
        local style = STYLES[styleKey]
        local suiteMode=SpellbookLevelsEllesmereStyle and SpellbookLevelsEllesmereStyle.Mode()
        local matchParchment=styleKey=="match" and cfg.kind=="class" and
            (suiteMode=="forever" or suiteMode=="classic" or suiteMode=="blizzard")
        p.matchParchment=matchParchment
        if matchParchment and SpellbookLevelsNativeBookArt then p.nativeFonts=SpellbookLevelsNativeBookArt.Fonts(p.host) end
        if p.nativeBookBackdrop and not matchParchment then
            if page.bg.SetParent then page.bg:SetParent(page) end
            p.nativeBookBackdrop:Hide()
        end
        if matchParchment then
            style={};for key,value in pairs(STYLES.parchment) do style[key]=value end
            style.label="Match Skin"
            -- Chrome stays dark like the host; only the book page is parchment.
            style.chrome=STYLES.native.chrome;style.btnBg=STYLES.native.btnBg
            style.btnEdge=STYLES.native.btnEdge;style.btnText=STYLES.native.btnText
            style.name={.10,.07,.03}
            style.sub={.16,.10,.04}
            style.unmet={.16,.10,.04}
            style.ok={.16,.10,.04}
            style.shade={.35,.22,.08,.13}
        end
        for _, b in ipairs(btns) do b:Skin(style) end
        -- Copy the live host tab font when available; retain each original font
        -- so changing back to another presentation mode restores it immediately.
        local tabSystem = p.host and (p.host.CategoryTabSystem or
            (p.host.SpellBookFrame and p.host.SpellBookFrame.CategoryTabSystem))
        local hostFont
        if styleKey == "match" and tabSystem and tabSystem.GetChildren then
            for _, tab in ipairs({tabSystem:GetChildren()}) do
                hostFont = tab.Text or (tab.GetFontString and tab:GetFontString())
                if hostFont then break end
            end
        end
        for _, b in ipairs(btns) do
            b.originalFont = b.originalFont or {b.label:GetFont()}
            if hostFont then b.label:SetFont(hostFont:GetFont())
            else b.label:SetFont(unpack(b.originalFont)) end
        end
        p.styleBtn:SetText(cfg.kind=="prof" and style.label or ("Style: " .. style.label))
        chromeBg:SetColorTexture(style.chrome[1], style.chrome[2], style.chrome[3], style.chrome[4])
        if f.SetBackdropBorderColor then f:SetBackdropBorderColor(style.border[1], style.border[2], style.border[3], style.border[4]) end
        if cfg.kind == "class" and p.docked and cfg.dockAnchor == "extendRight" then
            -- The native Forever spellbook is a very dark warm brown. Use that as the
            -- physical page underneath every mode, then tint the whole host for modes
            -- that intentionally change the book. This removes the black-box seam.
            if styleKey == "match" then
                VGradient(page.bg, style.top, style.bottom)
            elseif styleKey == "parchment" then
                VGradient(page.bg, {0.19, 0.145, 0.085}, {0.095, 0.070, 0.040})
            elseif styleKey == "dark" then
                VGradient(page.bg, {0.055, 0.048, 0.045}, {0.028, 0.025, 0.024})
            else
                VGradient(page.bg, {0.075, 0.055, 0.030}, {0.040, 0.029, 0.017})
            end
            ApplySpellbookHostTheme(styleKey, style)
        else
            VGradient(page.bg, style.top, style.bottom)
        end
        total:SetTextColor(style.sub[1], style.sub[2], style.sub[3])
        hint:SetTextColor(style.hint[1], style.hint[2], style.hint[3])
        empty:SetTextColor(style.hint[1], style.hint[2], style.hint[3])
        pageText:SetTextColor(style.sub[1], style.sub[2], style.sub[3])
        if cfg.kind=="prof" then empty:SetTextColor(.85,.81,.72) end
        p.style, p.theme = style, th
        if SpellbookLevelsObsidianSkin then
            if styleKey=="obsidian" then
                SpellbookLevelsObsidianSkin.Apply(f)
                if f.SetBackdrop then f:SetBackdrop(nil) end
                chromeBg:SetColorTexture(0,0,0,0)
                SpellbookLevelsObsidianSkin.Background(page.bg)
                page.bg:Show()
            else
                SpellbookLevelsObsidianSkin.SetShown(f,false)
                if f.SetBackdrop then f:SetBackdrop({ edgeFile = WHITE, edgeSize = 2 }) end
            end
        end
        f.__exstyleDisabled=styleKey~="match"
        if SpellbookLevelsEllesmereStyle and styleKey=="match" then
            f.__exstyleBackgrounds={chromeBg}
            SpellbookLevelsEllesmereStyle.Attach(f,p.host)
            for _,b in ipairs(btns) do SpellbookLevelsEllesmereStyle.Control(b) end
        end
        if matchParchment then
            -- The client exposes its complete single-page spellbook atlas,
            -- including the shaded parchment edges and inner frame.
            -- Keep artwork in a sibling frame: the root's opaque chrome otherwise
            -- paints over a background texture reparented directly onto it.
            if SpellbookLevelsNativeBookArt then SpellbookLevelsNativeBookArt.Layer(page.bg,page,f,p) end
            page.bg:ClearAllPoints()
            page.bg:SetPoint("TOPLEFT",f,"TOPLEFT",4,-24)
            page.bg:SetPoint("BOTTOMRIGHT",f,"BOTTOMRIGHT",-4,4)
            if SpellbookLevelsNativeBookArt then SpellbookLevelsNativeBookArt.Apply(page.bg,p.host) end
            page.bg:Show()
        end
        return style
    end

    ---------------------------------------------------------------- rendering one page's items
    local shownHead, shownGrid, shownTrain = 0, 0, 0
    function p.Render()
        pageText:ClearAllPoints()
        pageText:SetPoint("BOTTOMRIGHT", page, "BOTTOMRIGHT", -70, -22)
        local S, th = p.style, p.theme
        shownHead, shownGrid, shownTrain = 0, 0, 0
        local items = p.pages[p.page] or {}
        local y = p.matchParchment and 24 or 0
        -- Guard against showing anything that would visually overflow the strip's real, current height -
        -- pagination uses page:GetHeight() read earlier, which can be a few pixels stale by the time
        -- this actually renders (WoW doesn't always resolve anchor-based sizing in the same tick a
        -- resize happens), so this re-checks against the height as it stands right now and simply stops
        -- rather than showing a row whose text would get clipped.
        local realH = page:GetHeight()
        local suppressFirstTrainingHead = false
        for _, it in ipairs(items) do
            if realH and realH > 10 and y + it.h > realH then break end
            if it.kind=="head" and suppressFirstTrainingHead then
                suppressFirstTrainingHead=false
                y=y+2
            elseif it.kind == "head" then
                shownHead = shownHead + 1
                local h = GetHead(shownHead)
                h:ClearAllPoints(); h:SetPoint("TOPLEFT", page, "TOPLEFT", 0, -y); h:SetPoint("TOPRIGHT", page, "TOPRIGHT", 0, -y)
                h:SetHeight(it.h)
                if it.style == "major" then
                    h.bar:Hide(); h.rule:Show(); h.c1:Hide(); h.c2:Hide(); h.c3:Hide(); h.c4:Hide()
                    h.text:Show(); BookFont(h.text, 20); h.text:SetPoint("LEFT", 0, 2)
                    h.text:SetText(it.text); h.text:SetTextColor(S.title[1], S.title[2], S.title[3])
                    h.rule:SetColorTexture(S.sub[1], S.sub[2], S.sub[3], 0.35)
                elseif it.style == "section" then
                    h.rule:Hide(); h.c1:Hide(); h.c2:Hide(); h.c3:Hide(); h.c4:Hide()
                    h.bar:Show(); h.bar:SetColorTexture(it.def.bg[1], it.def.bg[2], it.def.bg[3], it.def.bg[4])
                    h.text:Show(); h.text:SetFontObject("GameFontNormal"); h.text:SetPoint("LEFT", 6, 0)
                    h.text:SetText(it.text); h.text:SetTextColor(it.def.fg[1], it.def.fg[2], it.def.fg[3])
                elseif it.style == "minor" then
                    h.bar:Hide(); h.rule:Hide(); h.c1:Hide(); h.c2:Hide(); h.c3:Hide(); h.c4:Hide()
                    h.text:Show(); h.text:SetFontObject("GameFontNormalSmall"); h.text:SetPoint("LEFT", 6, 0)
                    h.text:SetText(it.text); h.text:SetTextColor(S.sub[1], S.sub[2], S.sub[3])
                end
                h:Show()
            elseif it.kind == "colhead" then
                shownHead = shownHead + 1
                local h = GetHead(shownHead)
                h:ClearAllPoints(); h:SetPoint("TOPLEFT", page, "TOPLEFT", 0, -y); h:SetPoint("TOPRIGHT", page, "TOPRIGHT", 0, -y)
                h:SetHeight(it.h)
                h.bar:Hide(); h.rule:Hide(); h.text:Hide()
                for _, fs in ipairs({ h.c1, h.c2, h.c3, h.c4 }) do fs:Show(); fs:SetTextColor(S.sub[1], S.sub[2], S.sub[3]) end
                h:Show()
            elseif it.kind == "grid" then
                shownGrid = shownGrid + 1
                local r = GetGrid(shownGrid)
                r:ClearAllPoints(); r:SetPoint("TOPLEFT", page, "TOPLEFT", 0, -y); r:SetPoint("TOPRIGHT", page, "TOPRIGHT", 0, -y)
                r:SetHeight(it.h)
                local cols = math.max(1, p.gridCols or 1)
                local usableW = math.max(1, page:GetWidth() or 1)
                local cellW = math.floor(usableW / cols)
                for ci, cell in ipairs(r.cells) do
                    cell:ClearAllPoints()
                    cell:SetPoint("TOPLEFT", r, "TOPLEFT", (ci - 1) * cellW, 0)
                    cell:SetSize(cellW, GRID_ROW_H)
                    local e = it.entries[ci]
                    if e then
                        cell.entry = e
                        cell.state = (cfg.kind == "class" and p.docked and e.__sblState) or it.state
                        local icon = e.icon
                        if not icon and C_Spell and C_Spell.GetSpellInfo then
                            local si = C_Spell.GetSpellInfo(e.name); icon = si and si.iconID
                        end
                        cell.icon:SetTexture(icon or 134400)
                        if p.matchParchment then
                            if SpellbookLevelsNativeBookArt and p.nativeFonts then
                                SpellbookLevelsNativeBookArt.CopyFont(cell.name,p.nativeFonts.name)
                                SpellbookLevelsNativeBookArt.CopyFont(cell.sub,p.nativeFonts.sub)
                            end
                        end
                        cell.name:SetText(e.name)
                        cell.name:SetTextColor(S.name[1], S.name[2], S.name[3])
                        if e.__sblChangedUntil and e.__sblChangedUntil>GetTime() then cell.name:SetTextColor(.45,1,.45) end
                        if cfg.kind == "class" and cell.state ~= "learned" then
                            local req = (e.level or 0) > 0 and ("Level " .. e.level) or "Trainable"
                            local cost = (e.cost and e.cost > 0) and ("  ·  " .. CoinText(e.cost)) or ""
                            local rank = (e.rank and e.rank ~= "") and (e.rank .. "  ·  ") or ""
                            cell.sub:SetText(rank .. req .. cost)
                            local cc = (cell.state == "avail") and S.ok or S.unmet
                            cell.sub:SetTextColor(cc[1], cc[2], cc[3])
                        else
                            cell.sub:SetText(e.rank ~= "" and e.rank or " ")
                            cell.sub:SetTextColor(S.sub[1], S.sub[2], S.sub[3])
                        end
                        cell:Show()
                    else
                        cell.entry = nil
                        cell:Hide()
                    end
                end
                r:Show()
            elseif it.kind == "train" then
                shownTrain = shownTrain + 1
                local r = GetTrain(shownTrain)
                r:ClearAllPoints(); r:SetPoint("TOPLEFT", page, "TOPLEFT", 0, -y); r:SetPoint("TOPRIGHT", page, "TOPRIGHT", 0, -y)
                local e = it.e
                r.entry, r.state = e, it.state
                local icon = e.icon
                if not icon and C_Spell and C_Spell.GetSpellInfo then
                    local si = C_Spell.GetSpellInfo(e.name); icon = si and si.iconID
                end
                r.icon:SetTexture(icon or 134400)
                r.name:SetText(e.name)
                local c = (it.state == "learned") and S.learned or S.name
                r.name:SetTextColor(c[1], c[2], c[3])
                if e.__sblChangedUntil and e.__sblChangedUntil>GetTime() then r.name:SetTextColor(.45,1,.45) end
                if cfg.kind == "prof" then
                    local source = e.source
                    if not source or source == "" or source == "Source" then
                        source = (e.sourceName and e.sourceName ~= "") and e.sourceName or "Unknown"
                    end
                    if #source > 18 then source = source:sub(1, 15) .. "..." end
                    r.rank:SetText(source)
                else
                    r.rank:SetText(e.rank or "")
                end
                r.rank:SetTextColor(S.sub[1], S.sub[2], S.sub[3])
                r.req:SetText(cfg.req(e))
                local rc = (it.state == "avail") and S.ok or ((it.state == "learned") and S.learned or S.unmet)
                r.req:SetTextColor(rc[1], rc[2], rc[3])
                r.cost:SetText(CoinText(e.cost))
                r.cost:SetTextColor(S.sub[1], S.sub[2], S.sub[3])
                r:Show()
            end
            y = y + it.h
        end
        for i = shownHead + 1, #headPool do headPool[i]:Hide() end
        for i = shownGrid + 1, #gridPool do gridPool[i]:Hide() end
        for i = shownTrain + 1, #trainPool do trainPool[i]:Hide() end
        p.shownCount = shownHead + shownGrid + shownTrain

        if cfg.kind == "class" and p.docked and cfg.dockAnchor == "extendRight" then
            hint:Hide(); total:Hide()
            if p.pageCount and p.pageCount > 1 then
                pageText:ClearAllPoints(); pageText:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -70, 14)
                pageText:Show(); navPrev:Show(); navNext:Show()
                pageText:SetText(("Page %d/%d"):format(p.page, p.pageCount))
                navPrev:SetEnabled(p.page > 1)
                navNext:SetEnabled(p.page < p.pageCount)
            else
                pageText:Hide(); navPrev:Hide(); navNext:Hide()
            end
        elseif cfg.kind == "class" and p.host and p.host:IsShown() then
            pageText:Hide(); navPrev:Hide(); navNext:Hide(); hint:Hide(); total:Hide()
        elseif cfg.kind == "prof" and p.docked then
            -- The native profession window owns the bottom action bar (Create All / quantity / Create).
            -- Keep addon chrome out of that region.  Single-page lists need no pager at all; for
            -- multi-page lists the pager remains inside our reserved right-side pane above the footer.
            hint:Hide(); total:Show()
            if p.pageCount and p.pageCount > 1 then
                -- Stable footer: this pager controls the entire Profession Skills page.
                pageText:ClearAllPoints()
                pageText:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -70, 14)
                pageText:Show(); navPrev:Show(); navNext:Show()
                pageText:SetText(("Page %d/%d"):format(p.page, p.pageCount))
                navPrev:SetEnabled(p.page > 1)
                navNext:SetEnabled(p.page < p.pageCount)
            else
                pageText:Hide(); navPrev:Hide(); navNext:Hide()
            end
        else
            hint:Show(); total:Show(); pageText:Show(); navPrev:Show(); navNext:Show()
            if cfg.kind == "prof" then
                hint:Hide()
                pageText:ClearAllPoints()
                pageText:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -70, 14)
            end
            pageText:SetText(("Page %d/%d"):format(p.page, p.pageCount))
            navPrev:SetEnabled(p.page > 1)
            navNext:SetEnabled(p.page < p.pageCount)
        end
        total:SetText(p.total and p.total > 0 and ("Available total: " .. CoinText(p.total)) or "")
        if p.matchParchment and SpellbookLevelsNativeBookArt then
            SpellbookLevelsNativeBookArt.Pager(f,pageText,navPrev,navNext,p.host,p.page,p.pageCount)
        end
        empty:SetShown(#p.pages == 0)
    end

    p.updateNote=f:CreateFontString(nil,"OVERLAY","GameFontNormalSmall")
    p.updateNote:SetPoint("BOTTOMLEFT",f,"BOTTOMLEFT",MARGIN,34)
    p.updateNote:SetTextColor(.45,1,.45); p.updateNote:Hide()
    local updateSerial=0
    function p.MarkUpdated()
        updateSerial=updateSerial+1; local serial=updateSerial
        p.updateNote:SetTextColor(.45,1,.45); p.updateNote:SetText("Updated after training / skill change"); p.updateNote:Show()
        C_Timer.After(3,function() if serial==updateSerial then p.updateNote:Hide() end end)
    end

    ---------------------------------------------------------------- refresh (rebuild + repaginate)
    function p.Refresh()
        if cfg.detect then p.current = cfg.detect() end
        if cfg.kind == "prof" then
            KnownProfessionRecipes()
            SBL_Materials.SetProfession(DetectProfession())
        end
        if DB().trainingDataNeedsReview and not p.buildNoticeShown then
            p.buildNoticeShown=true
            p.updateNote:SetText("Game updated: visit trainers to recheck saved levels and prices.")
            p.updateNote:SetTextColor(1,.82,.3); p.updateNote:Show()
        end
        p.ApplyTheme()
        local raw = (cfg.build and cfg.build()) or lists[cfg.kind]
        local shown = p.filter
        if p.filter == "Auto" then shown = "Auto (" .. (p.current or "all") .. ")" end
        p.filterBtn:SetText("Show: " .. shown)

        local ctx = { known = {}, myLevel = UnitLevel("player"), skills = {}, filter = p.filter, current = p.current }
        ctx.showProf = (cfg.kind == "prof") and ((p.filter == "All") or (p.filter == "Auto" and not p.current))

        p.previousStates=p.previousStates or {}
        local matched = {}
        local changed=false
        for _, e in ipairs(raw) do
            local key=(e.prof or "").."|"..e.name.."|"..(e.rank or "").."|"..tostring(e.skill or e.level or 0)
            local state=cfg.state(e,ctx)
            if p.previousStates[key] and p.previousStates[key]~=state then
                e.__sblChangedUntil=GetTime()+3; changed=true
            end
            p.previousStates[key]=state
            if cfg.matches(e, p.filter, ctx) then
                local include = true
                if cfg.kind == "prof" and p.sourceMode then
                    local knownSource = e.source and e.source ~= "" and e.source ~= "Unknown"
                    if p.sourceMode == "known" then include = knownSource
                    elseif p.sourceMode == "unknown" then include = not knownSource end
                end
                include=include and TrainingViewMatches(cfg.kind,p.planMode,e,state,ctx.myLevel)
                if include and SearchMatches(e, p.searchQuery) then matched[#matched + 1] = e end
            end
        end
        if changed then
            p.MarkUpdated()
            C_Timer.After(3.1,function() if p.frame:IsShown() then p.Render() end end)
        end
        if p.UpdatePlannerText then p.UpdatePlannerText() end

        local pageW = page:GetWidth()
        if pageW and pageW > 10 then
            p.gridCols = math.max(1, math.min(MAXCOLS, math.floor(pageW / GRID_CELL_W)))
        end
        if cfg.kind=="class" and p.docked and cfg.dockAnchor=="extendRight" then p.gridCols=2 end

        local pageTitle = p.theme and p.theme.title
        if cfg.kind == "class" and p.docked and cfg.dockAnchor == "extendRight" then pageTitle = "Training" end
        local items
        if cfg.kind == "class" and p.docked and cfg.dockAnchor == "inlineSpellbook" then
            -- Native spellbook integration: do not create a second section, heading, filter block,
            -- or pager.  Only future/trainable spells are drawn, as ordinary spell cards, into the
            -- next open rows of Blizzard's existing three-column spell grid.
            p.gridCols = 3
            local future = {}
            for _, e in ipairs(matched) do
                if not e.learned then future[#future + 1] = e end
            end
            table.sort(future, cfg.sort)
            items = {}
            local row
            for i, e in ipairs(future) do
                if ((i - 1) % 3) == 0 then
                    row = { kind = "grid", entries = {}, state = "notyet", h = GRID_ROW_H }
                    items[#items + 1] = row
                end
                local st = cfg.state(e, ctx)
                -- Keep state on each entry because one row can contain both trainable-now and future spells.
                e.__sblState = st
                row.entries[#row.entries + 1] = e
            end
        else
            items = BuildItems(cfg, matched, ctx, pageTitle, p.gridCols)
            if cfg.kind=="class" and p.docked and cfg.dockAnchor=="extendRight" then
                for _, it in ipairs(items) do
                    if it.kind=="grid" then it.h=72 end
                end
                local compact={}
                for _,it in ipairs(items) do
                    if not (it.kind=="head" and (it.style=="major" or (it.style=="section" and it.def and it.def.key=="avail"))) then compact[#compact+1]=it end
                end
                items=compact
            end
        end
        p.total = 0
        local planCount, planCost = 0, 0
        if cfg.kind == "class" then
            for _,e in ipairs(matched) do
                if p.planMode=="learned" or not e.learned then planCount=planCount+1; if not e.learned then planCost=planCost+(e.cost or 0) end end
            end
        end
        for _, it in ipairs(items) do
            if it.state == "avail" then
                if it.kind == "train" then p.total = p.total + (it.e.cost or 0)
                elseif it.kind == "grid" then for _, e in ipairs(it.entries) do p.total = p.total + (e.cost or 0) end end
            end
        end
        if cfg.kind == "class" and p.planSummary then
            local modeLabel=({now="trainable",next="at level "..tostring(ctx.myLevel+1),plus5="through level "..tostring(ctx.myLevel+5),all="future"})[p.planMode] or "future"
            p.planSummary:SetText(string.format("%d spell%s • %s",planCount,planCount==1 and "" or "s",CoinText(planCost)))
        end

        local pageH = page:GetHeight()
        if not (pageH and pageH > 10) then pageH = 400 end
        pageH = pageH - 20 - (p.matchParchment and 24 or 0)   -- a small safety margin: a card's text can render a couple of pixels below
                              -- its nominal row height (font descenders, baseline offset), so packing
                              -- pagination right up to the exact clip boundary let the last row's text
                              -- get cut off even though the row itself fit
        p.pages = PaginateH(items, pageH)
        p.pageCount = math.max(1, #p.pages)
        p.page = math.max(1, math.min(p.page, p.pageCount))

        local which = (p.filter == "Auto" and p.current) or (cfg.kind == "prof" and p.filter ~= "All" and p.filter ~= "Auto" and p.filter) or nil
        if p.searchQuery and p.searchQuery:match("%S") then
            empty:SetText("No matches for \"" .. p.searchQuery .. "\" with the current filters.")
        elseif cfg.kind == "class" then
            if #raw==0 then empty:SetText("No training data recorded yet. Visit a class trainer to record levels and prices.")
            elseif p.planMode=="now" then empty:SetText("Nothing available to train in this view at your level. Choose All upcoming to plan ahead.")
            elseif p.planMode=="learned" then empty:SetText("No learned spells match this tab. Choose All in the Show menu to check every tab.")
            else empty:SetText("No upcoming spells match this tab. Try All in the Show menu or visit your trainer.") end
        elseif which then
            empty:SetText(p.planMode=="learned" and "No learned recipes match these filters. Try All sources."
                or "No training matches these filters. Try All upcoming and All sources, or visit your profession trainer.")
        else
            empty:SetText(cfg.emptyText)
        end
        p.Render()
    end

    p.filterBtn:SetScript("OnClick", function(self)
        local choices=cfg.filters((cfg.build and cfg.build()) or lists[cfg.kind])
        ChoiceMenu(self,choices,p.filter,function(value)
            p.filter=value; Preferences()["filter_"..p.key]=value; p.page=1; p.Refresh()
        end)
    end)
    f:SetScript("OnShow", function() p.Refresh() end)
    f:SetScript("OnSizeChanged", function() if f:IsShown() then p.Refresh() end end)

    if cfg.detect then
        local acc = 0
        local poll = CreateFrame("Frame", nil, f)
        poll:SetScript("OnUpdate", function(_, dt)
            if p.filter ~= "Auto" then return end
            acc = acc + dt
            if acc < 0.3 then return end
            acc = 0
            local now = cfg.detect()
            if now ~= p.current then
                p.current = now
                SBL_Materials.SetProfession(now)
                p.page = 1; p.Refresh()
            end
        end)
    end

    if cfg.hostTitleOk then
        p.talentSession = false
        -- PlayerSpellsFrame is only the shared shell. Its SpellBookFrame and TalentsFrame
        -- children are the authoritative pages. The Training companion is therefore allowed
        -- ONLY while SpellBookFrame itself is visible; host titles/timers are never enough.
        local tabPoll = CreateFrame("Frame", nil, UIParent)
        -- Attach to the native host when it becomes available. A hidden ancestor
        -- stops OnUpdate entirely during ordinary gameplay.
        tabPoll:Hide()
        p.tabPoll = tabPoll
        local tabWatchAcc = 0
        tabPoll:SetScript("OnUpdate", function(_, dt)
            tabWatchAcc = tabWatchAcc + (dt or 0)
            if tabWatchAcc < 0.03 then return end
            tabWatchAcc = 0
            local h = p.host
            if not (h and h:IsShown()) then
                p.talentSession = false
                p.hiddenByTab = true
                if f:IsShown() then p.suppress=true; f:Hide(); p.suppress=false end
                return
            end

            local talentFrame = h.TalentsFrame
            local spellFrame = h.SpellBookFrame
            local talentVisible = talentFrame and talentFrame.IsShown and talentFrame:IsShown()
            local spellVisible = spellFrame and spellFrame.IsShown and spellFrame:IsShown()

            -- Fallback only for older clients that do not expose the child frames.
            if not talentFrame and IsTalentPage and IsTalentPage(h) then talentVisible = true end
            if not spellFrame and not talentVisible then
                local t = h.TitleContainer and h.TitleContainer.TitleText and h.TitleContainer.TitleText:GetText()
                spellVisible = cfg.hostTitleOk(t)
            end

            p.talentSession = talentVisible and true or false
            local allowTraining = spellVisible and not talentVisible
            if allowTraining then
                p.hiddenByTab = false
                if not f:IsShown() then
                    p.Attach()
                    if not p.docked and not p.ApplyPos() then
                        f:ClearAllPoints()
                        f:SetPoint("TOPLEFT", h, "TOPRIGHT", 4, 0)
                    end
                    p.suppress = true; f:Show(); p.suppress = false
                    p.Refresh()
                end
            else
                p.hiddenByTab = true
                if f:IsShown() then p.suppress=true; f:Hide(); p.suppress=false end
                if cfg.kind=="class" and cfg.dockAnchor=="extendRight" and h.__sblUnifiedTint then h.__sblUnifiedTint:Hide() end
            end
        end)
    end

    f:HookScript("OnShow", function()
        if not p.suppress then p.userOpen = true; DB()["wantOpen_" .. p.key] = true end
    end)
    f:HookScript("OnHide", function()
        if not p.suppress and not (p.docked and p.host and not p.host:IsShown()) then
            p.userOpen = false; DB()["wantOpen_" .. p.key] = false
        end
    end)

    ---------------------------------------------------------------- docking into the game's window
    function p.dockResize(start)
        if not p.docked then return end
        local h = p.host
        local dock = h and h.__sblDock
        if not (h and dock) then return end
        if start then
            p._resizeStart = {
                mouseX = GetCursorPosition(),
                mouseY = select(2, GetCursorPosition()),
                width = dock:GetWidth(),
                height = dock:GetHeight(),
            }
            return
        end
        local startState = p._resizeStart
        p._resizeStart = nil
        if not startState then return end
        local scale = UIParent:GetEffectiveScale() or 1
        local mx, my = GetCursorPosition()
        local dx = (mx - startState.mouseX) / scale
        local dy = (my - startState.mouseY) / scale
        local newW = startState.width + dx
        local newH = startState.height - dy
        if cfg.dockAnchor == "side" or cfg.dockAnchor == "side-left" then
            newW = math.max(360, math.min(620, newW))
            dock:SetWidth(newW)
            DB()["dockWidth_" .. p.key] = newW
        else
            newH = math.max(180, math.min(520, newH))
            dock:SetHeight(newH)
            DB()["dockHeight_" .. p.key] = newH
        end
        p.Refresh()
    end

    function p.Dock(h)
        local dock = h.__sblDock
        if not dock then
            dock = CreateFrame("Frame", nil, (p.key=="class" and cfg.dockAnchor=="extendRight") and UIParent or h)
            h.__sblDock = dock
        end
        local db = SpellbookLevelsDB
        dock:ClearAllPoints()
        if cfg.dockAnchor == "inlineSpellbook" then
            -- Continue Blizzard's three-column spell grid. AutoBottom cannot be used here because
            -- the native spellbook has footer/status regions near the bottom; those made v10 think
            -- the spell list itself extended to the footer and recreated the giant void.
            -- The native grid begins below the tab/search/header chrome and its first three rows end
            -- around this inset on the Forever spellbook. Our frame starts at row four and has no
            -- independent chrome, headings, background, or pager.
            -- v12: line the overlay up with Blizzard's own three-column grid.
            -- The native icon columns sit at roughly 90px from the left edge and repeat at
            -- ~250px; the first addon row begins one full native row below row three.
            -- These values deliberately match the Forever spellbook geometry instead of the
            -- old generic book-grid constants that caused v11 to overlap row three.
            local winH = h:GetHeight() or 600
            local top = math.min(410, math.max(360, winH * 0.60))
            dock:SetPoint("TOPLEFT", h, "TOPLEFT", 90, -top)
            dock:SetPoint("BOTTOMRIGHT", h, "BOTTOMRIGHT", -28, 58)
            page:ClearAllPoints()
            page:SetPoint("TOPLEFT", dock, "TOPLEFT", 0, 0)
            page:SetPoint("BOTTOMRIGHT", dock, "BOTTOMRIGHT", 0, 0)
        elseif cfg.dockAnchor == "extendRight" then
            if not h.__sblBaseW then h.__sblBaseW, h.__sblBaseH = h:GetSize() end
            if p.key == "class" then
                -- v2.6: PlayerSpellsFrame is shared by Spellbook and Talents. Never resize it.
                -- Training is an independent companion immediately to the right of Blizzard's frame.
                dock:SetParent(UIParent)
                dock:SetSize(540, math.max(520, h:GetHeight() or 620))
                dock:SetPoint("TOPLEFT", h, "TOPRIGHT", 4, 0)
                page:ClearAllPoints()
                page:SetPoint("TOPLEFT", dock, "TOPLEFT", 14, -76)
                page:SetPoint("BOTTOMRIGHT", dock, "BOTTOMRIGHT", -14, 44)
            else
                -- Professions genuinely needs an added right-hand page, so preserve its expansion.
                local extra = math.max(460, math.min((db and db["dockWidth_" .. p.key]) or 500, 600))
                h:SetWidth(h.__sblBaseW + extra)
                -- Align our page to the top of Blizzard's first primary-profession box.
                dock:SetPoint("TOPLEFT", h, "TOPLEFT", h.__sblBaseW + 6, -58)
                -- Keep Blizzard's bottom action row (Create/Create All/quantity) unobstructed
                -- when an individual profession is selected.
                dock:SetPoint("BOTTOMRIGHT", h, "BOTTOMRIGHT", -12, 58)
                page:ClearAllPoints()
                page:SetPoint("TOPLEFT", dock, "TOPLEFT", 12, -68)
                page:SetPoint("BOTTOMRIGHT", dock, "BOTTOMRIGHT", -12, 44)
            end
        elseif cfg.dockAnchor == "extendBottom" then
            -- Grow the native spellbook downward; native content keeps its original coordinates.
            if not h.__sblBaseW then h.__sblBaseW, h.__sblBaseH = h:GetSize() end
            local extra = math.max(190, math.min((db and db["dockHeight_" .. p.key]) or 220, 330))
            h:SetHeight(h.__sblBaseH + extra)
            dock:SetPoint("TOPLEFT", h, "TOPLEFT", 14, -(h.__sblBaseH + 2))
            dock:SetPoint("BOTTOMRIGHT", h, "BOTTOMRIGHT", -14, 10)
        elseif cfg.dockAnchor == "bottom" then
            -- Use whatever space genuinely exists below the window's lowest real content, rather than
            -- a guessed height - a fixed guess either wastes most of the spellbook's usually-generous
            -- blank area, or overlaps the profession window's per-profession columns, which extend much
            -- lower. No border or fill of our own, so whatever's behind us shows through underneath.
            -- The strip itself has ~74px of fixed overhead (the button row at the top, the hint/page-nav
            -- row at the bottom) before any actual content can render, so the floor here has to clear
            -- that overhead by enough to fit a header plus at least one row - not just be "some number".
            local manual = db and db["dockHeight_" .. p.key]
            local hgt = manual
            if not hgt then
                local topInset = AutoBottom(h, f, dock)
                local winH = (h:GetTop() or 0) - (h:GetBottom() or 0)
                hgt = topInset and (winH - topInset - 26) or 220
            end
            hgt = math.max(180, math.min(hgt, 460))
            dock:SetPoint("BOTTOMLEFT", h, "BOTTOMLEFT", 14, 8)
            dock:SetPoint("BOTTOMRIGHT", h, "BOTTOMRIGHT", -14, 8)
            dock:SetHeight(hgt)
        else
            local manual = db and db["dockTop_" .. p.key]
            local top = manual or AutoTop(h, f, dock) or DockTop(p.key)
            dock:SetPoint("TOPLEFT", h, "TOPLEFT", 6, -top)
            dock:SetPoint("BOTTOMRIGHT", h, "BOTTOMRIGHT", -6, 8)
        end
        if p.key == "class" and cfg.dockAnchor == "extendRight" then
            -- Training must stay independent of PlayerSpellsFrame (the shell is shared with
            -- Talents), but it must also beat HUD/unit frames.  The profession companion gets
            -- that naturally from its native-parent hierarchy; the independent Training page
            -- therefore needs an explicit foreground strata of its own.
            if f:GetParent() ~= UIParent then f:SetParent(UIParent) end
            dock:SetParent(UIParent)
            dock:SetFrameStrata("DIALOG")
            dock:SetFrameLevel(100)
            SetStrataDeep(f, "DIALOG")
            f:SetFrameLevel(110)
        else
            -- Do not alter the working Profession companion layering.
            if f:GetParent() ~= h then f:SetParent(h) end
            SetStrataDeep(f, STRATA[math.min(MaxStrata(h, f) + 1, 7)])
            f:SetFrameLevel(h:GetFrameLevel() + 100)
        end
        f:ClearAllPoints()
        f:SetAllPoints(dock)
        p.docked = true
        if cfg.dockAnchor == "side" or cfg.dockAnchor == "side-left" then
            chromeBg:Show(); page.bg:Show()
            if f.SetBackdrop then pcall(f.SetBackdrop, f, { edgeFile = WHITE, edgeSize = 2 }) end
            p.ApplyTheme()
        else
            chromeBg:SetShown(p.key=="class" and cfg.dockAnchor=="extendRight")
            -- v16: the Spellbook training pane is intentionally rendered as a second book page,
            -- while the profession pane remains visually open to the profession window.
            page.bg:SetShown(cfg.kind == "class" and cfg.dockAnchor == "extendRight")
            if f.SetBackdrop then pcall(f.SetBackdrop, f, nil) end
            -- p.docked is now true, so ApplyTheme can style the complete integrated book.
            p.ApplyTheme()
        end
        SetEsc(false)
        p.UpdateChrome()
    end

    function p.Undock()
        local was = p.docked
        if cfg.kind == "class" and p.host and p.host.__sblUnifiedTint then p.host.__sblUnifiedTint:Hide() end
        p.docked = false
        if was or f:GetParent() ~= UIParent then
            f:SetParent(UIParent)
            SetStrataDeep(f, "MEDIUM")
            f:SetFrameLevel(10)
            local sz = Preferences()["winSize_" .. p.key]
            f:SetSize(sz and sz[1] or BOOK_W, sz and sz[2] or BOOK_H)
            f:ClearAllPoints()
            f:SetPoint("CENTER", 0, 0)
        end
        chromeBg:Show()
        page.bg:Show()
        page:ClearAllPoints()
        page:SetPoint("TOPLEFT", f, "TOPLEFT", MARGIN, -68)
        page:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -MARGIN, 40)
        if f.SetBackdrop then pcall(f.SetBackdrop, f, { edgeFile = WHITE, edgeSize = 2 }) end
        p.ApplyTheme()
        SetEsc(true)
        p.UpdateChrome()
    end

    function p.Attach()
        local h = p.host
        if DockOn() and h and h:IsShown() then p.Dock(h) else p.Undock() end
    end

    function p.PinToHost(capture)
        if p.docked then return false end
        local h = p.host
        if not (h and h:IsShown()) then return false end
        local db = DB()
        local off = db["pinOff_" .. p.key]
        if capture and f:IsShown() then
            local fl, ft, hl, ht = f:GetLeft(), f:GetTop(), h:GetLeft(), h:GetTop()
            if fl and ft and hl and ht then
                off = { fl - hl, ft - ht }
                db["pinOff_" .. p.key] = off
            end
        end
        f:ClearAllPoints()
        if off then f:SetPoint("TOPLEFT", h, "TOPLEFT", off[1], off[2]) else f:SetPoint("TOPLEFT", h, "TOPRIGHT", 4, 0) end
        return true
    end

    function p.Unpin()
        if p.docked then return end
        local l, t = f:GetLeft(), f:GetTop()
        if l and t and f:IsShown() then
            f:ClearAllPoints()
            f:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", l, t)
            Preferences()["winPos_" .. p.key] = { "TOPLEFT", "BOTTOMLEFT", l, t }
        end
    end

    function p.ApplyPos()
        if p.docked then return true end
        if linked and p.PinToHost(false) then return true end
        local db = SpellbookLevelsDB
        local w = Preferences()["winPos_" .. p.key] or (db and db["winPos_" .. p.key])
        if w then
            f:ClearAllPoints()
            f:SetPoint(w[1], UIParent, w[2], w[3], w[4])
            return true
        end
        return false
    end

    -- Whether this window should open by itself when its game window opens.
    local function AutoOpen()
        if cfg.key ~= "class" then return p.userOpen end
        local db = SpellbookLevelsDB
        return DockOn() and not p.native and not (db and db.autoOpen == false)
    end

    local function ResettleShortly()
        if C_Timer and C_Timer.After then
            C_Timer.After(0, function() if f:IsShown() then p.Refresh() end end)
        end
    end

    function p.OnHostShow()
        local h = p.host
        if not (h and AutoOpen()) then return end

        -- v2.6.9: PlayerSpellsFrame is a shared shell for Spellbook and Talents.
        -- Never auto-show the class Training companion from the shell's OnShow, because
        -- at that instant Blizzard has not necessarily exposed which child page is active.
        -- The authoritative child-frame watcher above is solely responsible for showing
        -- Training after SpellBookFrame is actually visible.  This prevents the one-frame
        -- Training flash when opening Talents while preserving normal Spellbook auto-open.
        if cfg.hostTitleOk then
            p.hiddenByTab = true
            if f:IsShown() then
                p.suppress = true
                f:Hide()
                p.suppress = false
            end
            return
        end

        if f:IsShown() then return end
        p.Attach()
        if not p.docked and not p.ApplyPos() then
            f:ClearAllPoints()
            f:SetPoint("TOPLEFT", h, "TOPRIGHT", 4, 0)
        end
        p.autoShown = true
        f:Show()
        ResettleShortly()
    end

    function p.OnHostHide()
        if cfg.key == "class" then p.native = false end
        p.autoShown = false
        p.hiddenByTab = false
        if f:IsShown() then
            p.suppress = true
            f:Hide()
            p.suppress = false
        end
    end

    function p.Toggle()
        if f:IsShown() then
            if cfg.key == "class" then p.native = true end
            f:Hide()
            return
        end
        if cfg.key == "class" then p.native = false end
        p.Attach()
        if not p.docked and not p.ApplyPos() and p.host and p.host:IsShown() then
            f:ClearAllPoints()
            f:SetPoint("TOPLEFT", p.host, "TOPRIGHT", 4, 0)
        end
        f:Show()
        ResettleShortly()
    end

    p.UpdateChrome()
    panels[cfg.key] = p
    return p
end

------------------------------------------------------------------ export window
local function Export(kind)
    local list, out = lists[kind], {}
    if kind == "prof" then
        table.sort(list, SortProf)
        out[1] = "SBL_PROF = {"
        for _, e in ipairs(list) do
            out[#out + 1] = string.format('    { name = %q, rank = %q, prof = %q, skill = %d, level = %d, cost = %d },',
                e.name, e.rank, e.prof or "", e.skill or 0, e.level or 0, e.cost or 0)
        end
    else
        table.sort(list, SortClass)
        out[1] = "SBL_DATA = SBL_DATA or {}"
        out[2] = "SBL_DATA." .. class .. " = {"
        for _, e in ipairs(list) do
            out[#out + 1] = string.format('    { name = %q, rank = %q, level = %d, cost = %d%s },',
                e.name, e.rank, e.level or 0, e.cost or 0, e.tree and string.format(", tree = %q", e.tree) or "")
        end
    end
    out[#out + 1] = "}"
    exportBox:SetText(table.concat(out, "\n"))
    exportFrame:Show()
    exportBox:HighlightText()
    exportBox:SetFocus()
end

------------------------------------------------------------------ build everything
local function BuildUI()
    -- Follow the native Spellbook's currently visible skill-line page (General / Elemental Combat /
    -- Enhancement / Restoration, etc.).  The Forever spellbook API gives us the authoritative
    -- skill-line names; the native page heading is a FontString inside the shared PlayerSpells frame.
    -- Matching those two lets the training pane follow Blizzard's own tab selection without owning a
    -- second category selector.
    local function DetectSpellbookSkillLine()
        local h = PlayerSpellsFrame or SpellBookFrame
        local SB = C_SpellBook
        if not (h and h:IsShown() and SB and SB.GetNumSpellBookSkillLines and SB.GetSpellBookSkillLineInfo) then
            return nil
        end

        local names = {}
        for i = 1, SB.GetNumSpellBookSkillLines() do
            local info = SB.GetSpellBookSkillLineInfo(i)
            if info and info.name and info.name ~= "" then names[info.name] = true end
        end

        local best, bestY
        local seen = {}
        local function Scan(frame, depth)
            if not frame or seen[frame] or depth > 10 then return end
            seen[frame] = true
            if frame.IsShown and not frame:IsShown() then return end
            if frame.GetRegions then
                local regions = { frame:GetRegions() }
                for _, r in ipairs(regions) do
                    if r and r.GetObjectType and r:GetObjectType() == "FontString" and r.IsShown and r:IsShown() and r.GetText then
                        local t = r:GetText()
                        if t and names[t] then
                            -- Prefer the large page heading nearest the top of the spell content.
                            local y = r.GetTop and r:GetTop() or 0
                            if not best or y > (bestY or -math.huge) then best, bestY = t, y end
                        end
                    end
                end
            end
            if frame.GetChildren then
                local kids = { frame:GetChildren() }
                for _, child in ipairs(kids) do Scan(child, depth + 1) end
            end
        end
        Scan(h, 0)
        return best
    end

    NewPanel({
        key = "class", kind = "class", frameName = "SpellbookLevelsFrame", hostKey = "book",
        dockAnchor = "extendRight", -- v2.6: attach an independent Training companion to the native Spellbook.
                                 -- PlayerSpellsFrame itself is never resized because Talents shares it.
        hostTitleOk = function(t)
            -- PlayerSpellsFrame is shared.  Be conservative: Training belongs only to the
            -- literal Spellbook page; transient/blank titles must never be treated as Spellbook.
            if type(t) ~= "string" then return false end
            return t:lower():find("spellbook", 1, true) ~= nil
        end,
        defaultFilter = "Auto",
        detect = DetectSpellbookSkillLine,
        emptyText = "No trainable spells found.",
        sort = SortClass, state = ClassState, req = ClassReq, theme = ClassTheme, build = BuildClassEntries,
        subKey = function(e) return e.tree or "Other" end,
        wantSub = function(ctx) return ctx.filter == "All" end,
        filters = function(list)
            local out, seen = { "Auto", "All", "To learn" }, {}
            for _, e in ipairs(list) do
                if e.tree and not seen[e.tree] then seen[e.tree] = true; out[#out + 1] = e.tree end
            end
            return out
        end,
        matches = function(e, f, ctx)
            if f == "Auto" then
                -- v16: General is the training overview.  On General, show every unlearned class spell
                -- regardless of skill line; on a class-specific tab, mirror that native skill line.
                -- If Blizzard's heading is briefly unavailable while rebuilding, show nothing rather
                -- than flash entries from the wrong tab.
                if not ctx.current then return false end
                if ctx.current == "General" then return true end
                return e.tree == ctx.current
            end
            if f == "All" then return true end
            if f == "To learn" then return not e.learned end
            return e.tree == f
        end,
    })

    NewPanel({
        key = "prof", kind = "prof", frameName = "SpellbookLevelsProfFrame", hostKey = "prof",
        dockAnchor = "extendRight", -- integrated by extending the native profession window to the right,
                                   -- so neither Blizzard's recipe list/details nor its side tabs are covered
        defaultFilter = "Auto",
        emptyText = "No profession training data yet.\n\nVisit a profession trainer to save its available skills. You can then browse skill requirements and training costs here.",
        sort = SortProf, state = ProfState, req = ProfReq, detect = DetectProfession, theme = ProfTheme,
        subKey = function(e) return e.prof or "Other profession" end,
        wantSub = function(ctx) return ctx.showProf end,
        filters = function(list)
            local out, seen = { "Auto", "All" }, {}
            for _, e in ipairs(list) do
                if e.prof and not seen[e.prof] and PlayerSkill(e.prof) then seen[e.prof] = true; out[#out + 1] = e.prof end
            end
            table.sort(out, function(a, b)
                local ra = (a == "Auto" and 0) or (a == "All" and 1) or 2
                local rb = (b == "Auto" and 0) or (b == "All" and 1) or 2
                if ra ~= rb then return ra < rb end
                return a < b
            end)
            return out
        end,
        matches = function(e, f, ctx)
            -- Never show a profession the character hasn't actually learned, even if we have seed or
            -- trainer data for it (from another character, or the shipped reference data).
            if ctx.skills[e.prof] == nil then ctx.skills[e.prof] = PlayerSkill(e.prof) or false end
            if not ctx.skills[e.prof] then return false end
            if f == "All" then return true end
            local target = f
            if f == "Auto" then
                target = ctx.current
                if not target then return false end
                -- Auto is the profession-training view: already-known recipes belong in All,
                -- not in the list of things the character can still learn.
                -- Learned visibility is controlled by the explicit training-view menu.
            end
            return SameProf(e.prof, target)
        end,
    })

    exportFrame = MakePanel("SpellbookLevelsExport", 520, 360, "Export - Ctrl+A, Ctrl+C to copy")
    exportFrame:SetPoint("CENTER")
    exportFrame:SetFrameStrata("DIALOG")
    exportFrame:Hide()
    tinsert(UISpecialFrames, "SpellbookLevelsExport")
    local es = MakeScroll("SpellbookLevelsExportScroll", exportFrame)
    es:SetPoint("TOPLEFT", 12, -32)
    es:SetPoint("BOTTOMRIGHT", -30, 12)
    exportBox = CreateFrame("EditBox", nil, es)
    exportBox:SetMultiLine(true)
    exportBox:SetAutoFocus(false)
    exportBox:SetFontObject("ChatFontNormal")
    exportBox:SetWidth(460)
    exportBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    es:SetScrollChild(exportBox)

    -- Shortcut button: drag anywhere, left-click = class spells, right-click = professions.
    btn = CreateFrame("Button", "SpellbookLevelsButton", UIParent)
    btn:SetSize(31, 31)
    btn:SetFrameStrata("HIGH")
    btn:SetFrameLevel(8)
    btn:SetClampedToScreen(true)
    btn:SetMovable(true)
    btn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    btn:RegisterForDrag("LeftButton")
    btn:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    btn:Show()

    local icon = btn:CreateTexture(nil, "BACKGROUND")
    icon:SetSize(20, 20)
    icon:SetPoint("CENTER", 0, 1)
    icon:SetTexture("Interface\\Icons\\INV_Misc_Book_09")
    local border = btn:CreateTexture(nil, "OVERLAY")
    border:SetSize(53, 53)
    border:SetPoint("TOPLEFT")
    border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    btn:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

    local dragging = false
    btn:SetScript("OnDragStart", function(self)
        dragging = true
        GameTooltip:Hide()
        self:StartMoving()
    end)
    btn:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local point, _, relPoint, x, y = self:GetPoint()
        DB().pos = { point, relPoint, x, y }
    end)
    btn:SetScript("OnMouseUp", function(_, button)
        if dragging then dragging = false; return end
        if button == "RightButton" then panels.prof.Toggle() else panels.class.Toggle() end
    end)
    btn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:AddLine("Spellbook Levels")
        GameTooltip:AddLine("Left-click: class spells", 1, 1, 1)
        GameTooltip:AddLine("Right-click: professions", 1, 1, 1)
        GameTooltip:AddLine("Drag: move anywhere", 1, 1, 1)
        GameTooltip:Show()
    end)
    btn:SetScript("OnLeave", function() GameTooltip:Hide() end)
end

local ok, err = xpcall(BuildUI, function(e)
    return tostring(e) .. ((debugstack and ("\n" .. debugstack(2, 4, 0))) or "")
end)

------------------------------------------------------------------ attach to the game's own windows
-- Make a game window draggable and remember where it was left.
local function MakeMovable(h, hostKey)
    if h.__sblMovable then return end
    h.__sblMovable = true
    h:SetMovable(true)
    h:SetClampedToScreen(true)

    local posKey = "hostPos_" .. hostKey
    local function ApplyHostPos()
        local db = SpellbookLevelsDB
        local w = Preferences()[posKey] or (db and db[posKey])
        if w and not InCombatLockdown() then
            h:ClearAllPoints()
            h:SetPoint(w[1], UIParent, w[2], w[3], w[4])
        end
    end
    local function StartDrag()
        if not InCombatLockdown() then h:StartMoving() end
    end
    local function StopDrag()
        h:StopMovingOrSizing()
        local point, _, relPoint, x, y = h:GetPoint()
        Preferences()[posKey] = { point, relPoint, x, y }
    end

    for _, f in ipairs({ h, h.TitleContainer }) do
        if f and f.RegisterForDrag then
            f:EnableMouse(true)
            f:RegisterForDrag("LeftButton")
            f:HookScript("OnDragStart", StartDrag)
            f:HookScript("OnDragStop", StopDrag)
        end
    end

    h:HookScript("OnShow", function()
        ApplyHostPos()
        if C_Timer and C_Timer.After then C_Timer.After(0, ApplyHostPos) end
    end)
    if UpdateUIPanelPositions then
        hooksecurefunc("UpdateUIPanelPositions", function()
            if h:IsShown() then ApplyHostPos() end
        end)
    end
    if h:IsShown() then ApplyHostPos() end
end

-- Toggle button on the profession window (the spellbook gets no button: it shows automatically).
local function AttachPanel(h, p, label)
    p.host = h
    if p.tabPoll then
        p.tabPoll:SetParent(h)
        p.tabPoll:Show()
    end
    if p.key == "prof" and professionTabWatcher then
        professionTabWatcher:SetParent(h)
        professionTabWatcher:Show()
    end
    local btnKey, hookKey = "__sblButton_" .. p.key, "__sblHooked_" .. p.key

    if p.key == "prof" and not h[btnKey] then
        local b = CreateFrame("Button", "SpellbookLevelsHostButton_" .. p.key, h, "UIPanelButtonTemplate")
        b:SetSize(110, 22)
        b:SetText(label)
        b:SetPoint("BOTTOMRIGHT", h, "TOPRIGHT", -4, 2)
        b:SetScript("OnClick", function() p.Toggle() end)
        b:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:AddLine("Spellbook Levels")
            GameTooltip:AddLine("Show / hide the trainable list", 1, 1, 1)
            GameTooltip:Show()
        end)
        b:SetScript("OnLeave", function() GameTooltip:Hide() end)
        h[btnKey] = b
    end

    if not h[hookKey] then
        h[hookKey] = true
        h:HookScript("OnShow", function() p.OnHostShow() end)
        h:HookScript("OnHide", function() p.OnHostHide() end)
    end
end

------------------------------------------------------------------ profession tabs: right side -> top
-- The game's profession window has one tab per profession in a column just outside its right edge.
-- We find that column by geometry (small frames standing beside the window, lined up vertically),
-- remember their original anchors, and lay them out along the top edge instead.
-- "/sbl tabs side" restores the original layout.
local tabStore = { list = {}, seen = {}, orig = {}, order = {} }

local function ProfHost()
    return ProfessionsFrame or TradeSkillFrame
end

local function IsOurs(c)
    local n = c.GetName and c:GetName()
    return type(n) == "string" and n:find("^SpellbookLevels") ~= nil
end

local function Descendants(h)
    local out, count = {}, 0
    local function walk(fr, depth)
        if depth > 3 or count > 3000 then return end
        for _, c in ipairs({ fr:GetChildren() }) do
            count = count + 1
            out[#out + 1] = c
            walk(c, depth + 1)
        end
    end
    walk(h, 1)
    return out
end

-- Returns (column, allCandidates): the best vertical column of small frames beside the window.
local function FindSideTabs(h)
    local hl, hr, ht, hb = h:GetLeft(), h:GetRight(), h:GetTop(), h:GetBottom()
    local cands = {}
    if not (hl and hr and ht and hb) then return {}, cands end
    local seen = {}
    local function consider(c, needAnchor)
        if seen[c] or c == h or IsOurs(c) or not c:IsShown() then return end
        seen[c] = true
        local l, r, t, b = c:GetLeft(), c:GetRight(), c:GetTop(), c:GetBottom()
        if not (l and r and t and b) then return end
        local w, hgt = r - l, t - b
        if w < 12 or w > 100 or hgt < 12 or hgt > 100 then return end
        if l < hr - 6 or l > hr + 120 or t > ht + 4 or b < hb - 4 then return end
        if needAnchor then
            local anchored = false
            for i = 1, c:GetNumPoints() do
                local _, rel = c:GetPoint(i)
                if rel == h then anchored = true end
            end
            if not anchored then return end
        end
        cands[#cands + 1] = c
    end
    for _, c in ipairs(Descendants(h)) do consider(c, false) end
    for _, c in ipairs({ UIParent:GetChildren() }) do consider(c, true) end

    local set = {}
    for _, c in ipairs(cands) do set[c] = true end
    local top = {}
    for _, c in ipairs(cands) do
        local nested, par = false, c:GetParent()
        while par and par ~= h and par ~= UIParent do
            if set[par] then nested = true; break end
            par = par:GetParent()
        end
        if not nested then top[#top + 1] = c end
    end

    local best = {}
    for _, a in ipairs(top) do
        local group = {}
        for _, b2 in ipairs(top) do
            if math.abs(b2:GetLeft() - a:GetLeft()) <= 8 then group[#group + 1] = b2 end
        end
        if #group > #best then best = group end
    end
    if #best < 2 then best = {} end
    return best, top
end

local function RememberTab(t)
    if tabStore.seen[t] then return end
    tabStore.seen[t] = true
    tabStore.list[#tabStore.list + 1] = t
    local pts = {}
    for i = 1, t:GetNumPoints() do
        local a, b, c, d, e = t:GetPoint(i)
        pts[#pts + 1] = { a, b, c, d, e }
    end
    tabStore.orig[t] = pts
    tabStore.order[t] = -(t:GetTop() or 0)
end

local function LayoutTabs(h)
    table.sort(tabStore.list, function(a, b) return tabStore.order[a] < tabStore.order[b] end)
    local prev, n = nil, 0
    for _, t in ipairs(tabStore.list) do
        if t:IsShown() then
            t:ClearAllPoints()
            if prev then
                t:SetPoint("BOTTOMLEFT", prev, "BOTTOMRIGHT", 3, 0)
            else
                t:SetPoint("BOTTOMLEFT", h, "TOPLEFT", 14, -3)
            end
            prev = t
            n = n + 1
        end
    end
    return n
end

local function MoveTabsToTop(h, detect)
    if InCombatLockdown() then return 0 end
    if detect or #tabStore.list == 0 then
        for _, t in ipairs((FindSideTabs(h))) do RememberTab(t) end
    end
    return LayoutTabs(h)
end

local function RestoreTabsToSide()
    if InCombatLockdown() then return 0 end
    local n = 0
    for _, t in ipairs(tabStore.list) do
        t:ClearAllPoints()
        for _, pt in ipairs(tabStore.orig[t]) do t:SetPoint(pt[1], pt[2], pt[3], pt[4], pt[5]) end
        n = n + 1
    end
    return n
end

local function TabsInPlace(h)
    local prev
    for _, t in ipairs(tabStore.list) do
        if t:IsShown() then
            local _, rel = t:GetPoint(1)
            if t:GetNumPoints() ~= 1 or rel ~= (prev or h) then return false end
            prev = t
        end
    end
    return true
end

local function ApplyTabs()
    local h = ProfHost()
    if not h then return end
    local db = SpellbookLevelsDB
    if not (db and db.tabsTop == true) then return end
    pcall(MoveTabsToTop, h, true)
end

local tabsScheduled = false
local function ScheduleTabs()
    if tabsScheduled then return end
    tabsScheduled = true
    if C_Timer and C_Timer.After then
        C_Timer.After(0, ApplyTabs)
        C_Timer.After(0.3, function() tabsScheduled = false; ApplyTabs() end)
    else
        tabsScheduled = false
        ApplyTabs()
    end
end

local tabAcc, tabProbe = 0, 0
local tabWatcher = CreateFrame("Frame")
professionTabWatcher = tabWatcher
tabWatcher:Hide()
if panels.prof and panels.prof.host then
    tabWatcher:SetParent(panels.prof.host)
    tabWatcher:Show()
end
tabWatcher:SetScript("OnUpdate", function(_, dt)
    tabAcc = tabAcc + dt
    if tabAcc < 0.5 then return end
    tabAcc = 0
    local h = ProfHost()
    if not (h and h:IsShown()) or InCombatLockdown() then return end
    local db = SpellbookLevelsDB
    if not (db and db.tabsTop == true) then return end
    if #tabStore.list == 0 then
        tabProbe = tabProbe + 1
        if tabProbe % 4 == 1 then pcall(MoveTabsToTop, h, true) end
    elseif not TabsInPlace(h) then
        pcall(MoveTabsToTop, h, true)
    end
end)

local function TabsScan()
    local h = ProfHost()
    if not h then
        print(PREFIX .. "no profession window found (open it once, then run /sbl tabs scan again)")
        return
    end
    local col, cands = FindSideTabs(h)
    print(string.format("%stab scan: window %s, right edge %d. %d tab(s) in the side column, %d remembered.",
        PREFIX, tostring(h:GetName()), h:GetRight() or 0, #col, #tabStore.list))
    for i, c in ipairs(cands) do
        if i <= 20 then
            print(string.format("  candidate %s (%s) left=%d top=%d size=%dx%d", tostring(c:GetName()),
                c:GetObjectType(), c:GetLeft(), c:GetTop(), c:GetRight() - c:GetLeft(), c:GetTop() - c:GetBottom()))
        end
    end
    for _, t in ipairs(tabStore.list) do
        print(string.format("  remembered %s (%s)", tostring(t:GetName()), t:GetObjectType()))
    end
    if #col == 0 and #tabStore.list == 0 then
        print("  no column of small frames beside the window. Open the profession window, make sure the tabs are visible, and run this again. If it still finds nothing, paste this output here.")
    end
end

local hostDefs = {
    { key = "book", find = function() return PlayerSpellsFrame or SpellBookFrame end, label = "Spell Levels" },
    { key = "prof", find = function() return ProfessionsFrame or TradeSkillFrame end, label = "Skill Levels" },
}

local function HookHosts()
    for _, d in ipairs(hostDefs) do
        local h = d.find()
        if h then
            pcall(MakeMovable, h, d.key)
            local p = (d.key == "book") and panels.class or panels.prof
            if ok and p then pcall(AttachPanel, h, p, d.label) end
            if d.key == "prof" and not h.__sblTabsHooked then
                h.__sblTabsHooked = true
                h:HookScript("OnShow", ScheduleTabs)
                if h:IsShown() then ScheduleTabs() end
            end
        end
    end
end

-- Restore saved positions / preferences (runs once saved variables are available).
local preferencesApplied=false
local function ApplyAll()
    if not ok or not loaded then return end
    local db = SpellbookLevelsDB
    if db then linked = db.linked and true or false end
    for _, p in pairs(panels) do
        if not preferencesApplied then
            local pref=Preferences()
            p.filter=pref["filter_"..p.key] or p.filter
            p.planMode=pref["planMode_"..p.key] or p.planMode
            p.sourceMode=pref["sourceMode_"..p.key] or p.sourceMode
        end
        p.ApplyPos()
        p.UpdatePin()
        if db then p.userOpen = db["wantOpen_" .. p.key] and true or false end
    end
    preferencesApplied=true
    if db and db.pos then
        btn:ClearAllPoints()
        btn:SetPoint(db.pos[1], UIParent, db.pos[2], db.pos[3], db.pos[4])
    end
    if db and db.hideButton then btn:Hide() else btn:Show() end
end


------------------------------------------------------------------ talent heatmap
-- SpellbookLevels intentionally does not modify Blizzard's Talent UI.

------------------------------------------------------------------ events / slash
local ev = CreateFrame("Frame")
local merchantErrorReported = false
local function RefreshMerchant()
    local success, err = pcall(ScanMerchant)
    if not success and not merchantErrorReported then
        merchantErrorReported = true
        print(PREFIX .. "merchant scan failed: " .. tostring(err))
    end
    if success then pcall(SaveLists) end
    if ok and panels.prof.frame:IsShown() then panels.prof.Refresh() end
end
local function RefreshClassAfterTraining()
    if ok and panels.class.frame:IsShown() then panels.class.Refresh(); panels.class.MarkUpdated() end
end
for _, e in ipairs({ "MERCHANT_SHOW", "MERCHANT_UPDATE", "TRAINER_SHOW", "TRAINER_UPDATE", "TRADE_SKILL_SHOW", "TRADE_SKILL_LIST_UPDATE",
                     "TRADE_SKILL_DATA_SOURCE_CHANGED", "TRADE_SKILL_UPDATE", "NEW_RECIPE_LEARNED", "SKILL_LINES_CHANGED", "SPELLS_CHANGED", "LEARNED_SPELL_IN_TAB", "PLAYER_LEVEL_UP", "ADDON_LOADED", "PLAYER_LOGIN", "PLAYER_LOGOUT",
                     }) do
    pcall(ev.RegisterEvent, ev, e)
end
local professionHighlightPending=false
local professionRefreshPending = false
local professionRecheckPending = false
local function ScheduleProfessionRefresh(recheck)
    if recheck then professionHighlightPending=true end
    InvalidateProfession()
    if not professionRefreshPending then
        professionRefreshPending = true
        C_Timer.After(.15, function()
            professionRefreshPending = false
            pcall(HookHosts)
            ScheduleTabs()
            if ok and panels.prof.frame:IsShown() then panels.prof.Refresh(); if professionHighlightPending then if panels.prof.MarkUpdated then panels.prof.MarkUpdated() end; professionHighlightPending=false end end
        end)
    end
    if recheck and not professionRecheckPending then
        professionRecheckPending = true
        C_Timer.After(.6, function()
            professionRecheckPending = false
            ScheduleProfessionRefresh(false)
        end)
    end
end
ev:SetScript("OnEvent", function(_, event, arg1)
    if event == "PLAYER_LOGOUT" then SaveLists(); return end
    if event:find("TRADE_SKILL", 1, true) then
        ScheduleProfessionRefresh(false)
        return
    end
    if event == "NEW_RECIPE_LEARNED" or event == "SKILL_LINES_CHANGED" then
        ScheduleProfessionRefresh(true)
        return
    end
    if event == "MERCHANT_SHOW" or event == "MERCHANT_UPDATE" then
        RefreshMerchant()
        if event == "MERCHANT_SHOW" and C_Timer and C_Timer.After then
            C_Timer.After(0.3, function()
                if MerchantFrame and MerchantFrame:IsShown() then RefreshMerchant() end
            end)
        end
    elseif event == "TRAINER_SHOW" or event == "TRAINER_UPDATE" then
        ScheduleProfessionRefresh(event == "TRAINER_UPDATE")
        local before = #lists.class + #lists.prof
        pcall(ScanTrainer)
        pcall(SaveLists)
        if #lists.class + #lists.prof ~= before then
            print(PREFIX .. "trainer read: " .. #lists.class .. " class spells and "
                .. #lists.prof .. " profession skills saved")
        end
        if ok then
            for _, p in pairs(panels) do
                if p.frame:IsShown() then p.Refresh() end
            end
        end
    else
        if (event == "ADDON_LOADED" and arg1 == "SpellbookLevels") or (event == "PLAYER_LOGIN" and not loaded) then
            LoadSaved()
        end
        pcall(HookHosts)
        pcall(ApplyAll)
        if event == "SPELLS_CHANGED" or event == "LEARNED_SPELL_IN_TAB" or event == "PLAYER_LEVEL_UP" then
            ScheduleProfessionRefresh(event ~= "PLAYER_LEVEL_UP")
            RefreshClassAfterTraining()
            if C_Timer and C_Timer.After then C_Timer.After(0.1, RefreshClassAfterTraining) end
        end

    end
end)

local function Probe()
    print(PREFIX .. "probe (class " .. tostring(class) .. ", interface " .. select(4, GetBuildInfo()) .. ")")
    for _, n in ipairs({ "GetNumTrainerServices", "GetTrainerServiceInfo", "GetTrainerServiceLevelReq",
                         "GetTrainerServiceCost", "GetTrainerServiceIcon", "GetTrainerServiceSkillReq",
                         "GetTrainerServiceSkillLine", "IsTradeskillTrainer", "C_ClassTrainer",
                         "C_SpellBook", "C_Spell", "C_Traits", "PlayerSpellsFrame", "SpellBookFrame",
                         "GetProfessions", "GetProfessionInfo", "C_TradeSkillUI", "ProfessionsFrame",
                         "TradeSkillFrame" }) do
        print("  " .. n .. ": " .. (_G[n] and "yes" or "NO"))
    end
end

local function ProfDump()
    print(PREFIX .. "profession detection:")
    local C = C_TradeSkillUI
    print("  C_TradeSkillUI: " .. tostring(C ~= nil))
    pcall(function()
        if C and C.GetBaseProfessionInfo then
            local info = C.GetBaseProfessionInfo()
            if info then
                for k, v in pairs(info) do print("  base." .. tostring(k) .. " = " .. tostring(v)) end
            else
                print("  GetBaseProfessionInfo: nil")
            end
        end
    end)
    print("  detected: " .. tostring(DetectProfession()))
    local h = ProfessionsFrame or TradeSkillFrame
    if not h then
        print("  no profession window found (open it once, then run this again)")
        return
    end
    print("  window: " .. tostring(h:GetName()))
end

local function DockDump()
    for _, key in ipairs({ "class", "prof" }) do
        local p = panels[key]
        if not p then
            print(PREFIX .. key .. ": panel not built")
        else
            local h = p.host
            print(PREFIX .. key .. ": host=" .. tostring(h and h:GetName()) .. " shown=" .. tostring(h and h:IsShown())
                .. " docked=" .. tostring(p.docked) .. " ourShown=" .. tostring(p.frame:IsShown()))
            local dock = h and h.__sblDock
            if dock then
                local dh, dw = dock:GetHeight(), dock:GetWidth()
                print("    dock width=" .. tostring(dw) .. " height=" .. tostring(dh)
                    .. " (estimated page content height=" .. tostring(dh and dh - 74) .. ")")
            end
            print("    gridCols=" .. tostring(p.gridCols) .. " filter=" .. tostring(p.filter)
                .. " page=" .. tostring(p.page) .. "/" .. tostring(p.pageCount))
            local pg = p.pages and p.pages[p.page]
            if pg then
                print("    page " .. p.page .. " has " .. #pg .. " item(s), " .. tostring(p.shownCount)
                    .. " actually rendered (fewer means the overflow guard held some back)")
                for idx, it in ipairs(pg) do
                    if idx <= 12 then
                        if it.kind == "head" then print("      [" .. idx .. "] head/" .. it.style .. ": " .. tostring(it.text))
                        elseif it.kind == "grid" then print("      [" .. idx .. "] grid row, " .. #it.entries .. " card(s), state=" .. tostring(it.state))
                        else print("      [" .. idx .. "] " .. tostring(it.kind)) end
                    end
                end
            else
                print("    no page data (pages table empty or index out of range)")
            end
        end
    end
end

local function TrainerDump()
    local n = GetNumTrainerServices and GetNumTrainerServices() or 0
    if n == 0 then
        print(PREFIX .. "no trainer rows found. Open a trainer window first, then run /sbl trainerdump.")
        return
    end
    print(PREFIX .. "trainer rows: " .. n .. ", tradeskill trainer: "
        .. tostring(IsTradeskillTrainer and IsTradeskillTrainer()))
    for i = 1, math.min(n, 20) do
        local good, line = pcall(function()
            local name, rank, category = GetTrainerServiceInfo(i)
            local lvl = GetTrainerServiceLevelReq and GetTrainerServiceLevelReq(i)
            return string.format("%d %s | %s | %s | lvl %s", i, tostring(name), tostring(rank), tostring(category), tostring(lvl))
        end)
        print("  " .. tostring(line))
    end
end

SLASH_SPELLBOOKLEVELS1 = "/sbl"
SlashCmdList.SPELLBOOKLEVELS = function(msg)
    msg = (msg or ""):lower()
    local cmd, arg = msg:match("^(%S*)%s*(.-)$")
    if cmd == "materials" then
        SBL_Materials.Show()
    elseif cmd == "learncheck" then
        local target=arg~="" and arg or "Ghost Wolf"
        print(PREFIX.."learned check: "..target)
        for _,entry in ipairs(ScanSpellbook()) do
            if entry.name:lower()==target:lower() then
                print("Book: "..entry.name.." | "..entry.rank.." | ID "..tostring(entry.id).." | level "..tostring(entry.level).." | future "..tostring(entry.future).." | API known "..tostring(SpellKnown(entry.id)))
            end
        end
        for _,entry in ipairs(BuildClassEntries()) do
            if entry.name:lower()==target:lower() then print("Row: "..entry.name.." | "..entry.rank.." | learned "..tostring(entry.learned).." | level "..tostring(entry.level)) end
        end
    elseif cmd == "version" then
        print(PREFIX .. "v" .. tostring((GetAddOnMetadata and GetAddOnMetadata("SpellbookLevels", "Version"))
            or (C_AddOns and C_AddOns.GetAddOnMetadata and C_AddOns.GetAddOnMetadata("SpellbookLevels", "Version"))
            or "?") .. " loaded. If this isn't the version you just installed, run /reload or fully relog -"
            .. " WoW only reads addon file changes at login or reload, never while already playing.")
    elseif cmd == "probe" then
        Probe()
    elseif cmd == "trainerdump" then
        TrainerDump()
    elseif cmd == "profdump" then
        ProfDump()
    elseif cmd == "dockdump" then
        DockDump()
    elseif not ok then
        print(PREFIX .. "UI failed to build. Error:")
        print(err)
    elseif cmd == "export" then
        Export(arg == "prof" and "prof" or "class")
    elseif cmd == "prof" or cmd == "professions" then
        local p = panels.prof
        if arg == "" then
            p.Toggle()
        else
            if arg == "auto" then
                p.filter = "Auto"
            elseif arg == "all" then
                p.filter = "All"
            else
                p.filter = arg
                for _, e in ipairs(lists.prof) do
                    if e.prof and SameProf(e.prof, arg) then p.filter = e.prof; break end
                end
            end
            p.page = 1
            p.frame:Show()
            p.Refresh()
        end
    elseif cmd == "tabs" then
        local db = DB()
        if arg == "scan" then
            TabsScan()
        elseif arg == "side" then
            db.tabsTop = false
            print(PREFIX .. "profession tabs back on the side (" .. RestoreTabsToSide() .. " tabs)")
        else
            db.tabsTop = true
            local n = ProfHost() and MoveTabsToTop(ProfHost(), true) or 0
            if n > 0 then
                print(PREFIX .. "moved " .. n .. " profession tabs to the top")
            else
                print(PREFIX .. "no profession tabs found. Open the profession window, then try /sbl tabs scan")
            end
        end
    elseif cmd == "native" then
        panels.class.Toggle()
        print(PREFIX .. (panels.class.native and "showing the game's own spellbook page (type /sbl native again to bring the book back)"
            or "showing the book inside the spellbook"))
    elseif cmd == "dock" then
        local db = DB()
        local a, b, c = arg:match("^(%S*)%s*(%S*)%s*(.-)$")
        if a == "off" then
            db.dock = false
        elseif a == "on" then
            db.dock = nil
        end
        local onlyKey, val = nil, b
        if (a == "top" or a == "height" or a == "width") and panels[b] then onlyKey, val = b, c end
        for key, p in pairs(panels) do
            if not onlyKey or onlyKey == key then
                if a == "top" and val == "auto" then db["dockTop_" .. key] = nil
                elseif a == "top" and tonumber(val) then db["dockTop_" .. key] = math.max(20, math.min(220, tonumber(val)))
                elseif a == "height" and val == "auto" then db["dockHeight_" .. key] = nil
                elseif a == "height" and tonumber(val) then db["dockHeight_" .. key] = math.max(80, math.min(500, tonumber(val)))
                elseif a == "width" and val == "auto" then db["dockWidth_" .. key] = nil
                elseif a == "width" and tonumber(val) then db["dockWidth_" .. key] = math.max(260, math.min(480, tonumber(val))) end
            end
            p.Attach()
            if not p.docked then p.ApplyPos() end
            if p.frame:IsShown() then p.Refresh() end
        end
        print(PREFIX .. "docking " .. (DockOn() and "on" or "off")
            .. ". /sbl dock height <number>|auto sets the class training strip's height; "
            .. "/sbl dock width prof <number>|auto sets the profession panel's width (it docks beside"
            .. " the profession window rather than inside it, to avoid overlapping its columns).")
    elseif cmd == "pin" then
        if arg == "on" then
            pcall(SetLinked, true)
        elseif arg == "off" then
            pcall(SetLinked, false)
        else
            pcall(SetLinked, not linked)
        end
        print(PREFIX .. (linked and "pinned: each window now moves together with its game window"
            or "unpinned: windows move independently"))
        for key, pn in pairs(panels) do
            print("  " .. key .. ": game window " .. ((pn.host and (pn.host:IsShown() and "open" or "closed"))
                or "not found yet (open it once)"))
        end
    elseif cmd == "skin" then
        local db = DB()
        if arg == "match" or arg == "on" then
            if GetStyle() ~= "match" then db.styleBeforeMatch = GetStyle() end
            CycleStyle("match")
        elseif arg == "classic" or arg == "off" then
            CycleStyle(STYLES[db.styleBeforeMatch] and db.styleBeforeMatch or "auto")
        else
            print(PREFIX .. "use /sbl skin match or /sbl skin classic")
            return
        end
        print(PREFIX .. "window style: " .. STYLES[GetStyle()].label)
    elseif cmd == "style" or cmd == "theme" then
        local st
        if arg == "auto" then st = "auto"
        elseif arg == "native" then st = "native"
        elseif arg == "dark" then st = "dark"
        elseif arg == "match" then st = "match"
        elseif arg == "parchment" or arg == "classic" or arg == "themed" or arg == "on" then st = "parchment" end
        st = CycleStyle(st)
        print(PREFIX .. "window style: " .. STYLES[st].label .. " (auto / native / parchment / dark / match)")
    elseif cmd == "icon" then
        local db = DB()
        db.hideButton = btn:IsShown() or nil
        btn:SetShown(not db.hideButton)
    elseif cmd == "wipe" then
        local db = DB()
        if arg == "prof" then
            db.prof = nil
            print(PREFIX .. "saved profession data cleared. /reload to rebuild from the Data files.")
        else
            if db.data then db.data[class] = nil end
            print(PREFIX .. "saved data for " .. tostring(class) .. " cleared. /reload to rebuild from the Data files.")
        end
    elseif cmd == "reset" then
        local db = DB()
        db.pos = nil
        for key, p in pairs(panels) do
            local pref=Preferences()
            pref["winPos_"..key],pref["hostPos_"..(p.hostKey or key)],pref["winSize_"..key]=nil,nil,nil
            db["winPos_" .. key], db["hostPos_" .. (p.hostKey or key)], db["pinOff_" .. key] = nil, nil, nil
            db["dockTop_" .. key], db["dockHeight_" .. key], db["dockWidth_" .. key] = nil, nil, nil
            db["winSize_" .. key] = nil
            p.frame:ClearAllPoints()
            p.frame:SetPoint("CENTER", 0, 0)
        end
        btn:ClearAllPoints()
        btn:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
        btn:Show()
        print(PREFIX .. "positions reset. Close and reopen the game windows to put them back in their default spots.")
    else
        panels.class.Toggle()
    end
end

if ok then
    print(PREFIX .. "v" .. tostring((GetAddOnMetadata and GetAddOnMetadata("SpellbookLevels", "Version"))
        or (C_AddOns and C_AddOns.GetAddOnMetadata and C_AddOns.GetAddOnMetadata("SpellbookLevels", "Version"))
        or "?") .. " ready. /sbl = class spells, /sbl prof = professions (shortcut button: left/right-click)")
else
    print(PREFIX .. "UI failed to build. Type /sbl to see the error.")
end
