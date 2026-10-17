local MCF=MyCharForever
if not MCF then return end
local T=function(k) return MCF:T(k) end

local function esc(v)
    v=tostring(v or "")
    v=v:gsub("\\","\\\\"):gsub('"','\\"'):gsub("\n","\\n"):gsub("\r","\\r"):gsub("\t","\\t")
    return '"'..v..'"'
end
local function isArray(t)
    if type(t)~="table" then return false end
    local n=0
    for k in pairs(t) do
        if type(k)~="number" or k<1 or k%1~=0 then return false end
        if k>n then n=k end
    end
    for i=1,n do if t[i]==nil then return false end end
    return true,n
end
-- flat=true writes the same JSON without indentation or line breaks (about 40 % of the pretty size).
local function serialize(v,depth,seen,flat)
    depth=depth or 0; seen=seen or {}
    local tv=type(v)
    if tv=="nil" then return "null"
    elseif tv=="boolean" or tv=="number" then return tostring(v)
    elseif tv=="string" then return esc(v)
    elseif tv~="table" then return "null" end
    if seen[v] then return esc("<circular>") end
    seen[v]=true
    local indent=flat and "" or string.rep("  ",depth)
    local child=flat and "" or string.rep("  ",depth+1)
    local nl=flat and "" or "\n"
    local colon=flat and ":" or ": "
    local sep=flat and "," or ",\n"
    local arr,n=isArray(v)
    local out={}
    if arr then
        local compact=(n>0 and n<=6)
        if compact then
            local parts={}
            for i=1,n do
                local t=type(v[i])
                if t~="number" and t~="boolean" and t~="string" then compact=false break end
                parts[#parts+1]=serialize(v[i],depth+1,seen,flat)
            end
            if compact then seen[v]=nil; return "["..table.concat(parts,flat and "," or ", ").."]" end
        end
        for i=1,n do out[#out+1]=child..serialize(v[i],depth+1,seen,flat) end
        seen[v]=nil
        return #out==0 and "[]" or "["..nl..table.concat(out,sep)..nl..indent.."]"
    end
    local keys={}
    for k in pairs(v) do if type(k)=="string" or type(k)=="number" then keys[#keys+1]=k end end
    table.sort(keys,function(a,b) return tostring(a)<tostring(b) end)
    for _,k in ipairs(keys) do out[#out+1]=child..esc(k)..colon..serialize(v[k],depth+1,seen,flat) end
    seen[v]=nil
    return #out==0 and "{}" or "{"..nl..table.concat(out,sep)..nl..indent.."}"
end

local function copyTable(src)
    if type(src)~="table" then return src end
    local out={}
    for k,v in pairs(src) do out[k]=copyTable(v) end
    return out
end

local function journeyPoint(p)
    if type(p)~="table" then return nil end
    return {
        tonumber(p.t or p.time) or 0,
        tonumber(p.m or p.mapID) or 0,
        tonumber(p.x) or 0,
        tonumber(p.y) or 0,
        tonumber(p.l or p.level) or 0,
    }
end

local function rdp(points,epsilon)
    return MCF.RDP(points,epsilon,function(p) return p[3] end,function(p) return p[4] end)
end

local function simplifyJourney(raw)
    local segments,current={},{}
    local previous=nil
    local function finish()
        if #current>0 then segments[#segments+1]=rdp(current,MCF.Maintenance.exportEpsilon) end
        current={}
    end
    for _,rawPoint in ipairs(raw or {}) do
        local p=journeyPoint(rawPoint)
        if p then
            local split=false
            if previous then
                if p[2]~=previous[2] then split=true end
                if p[1]>0 and previous[1]>0 and p[1]-previous[1]>MCF.Maintenance.exportSplitSeconds then split=true end
                local dx,dy=p[3]-previous[3],p[4]-previous[4]
                if math.sqrt(dx*dx+dy*dy)>MCF.Maintenance.maxRunJump then split=true end
            end
            if split then finish() end
            current[#current+1]=p
            previous=p
        end
    end
    finish()
    local count=0
    for _,s in ipairs(segments) do count=count+#s end
    return {format=2,fields={"timestamp","mapID","x","y","level"},
        simplified=true,epsilon=MCF.Maintenance.exportEpsilon,originalPoints=#(raw or {}),
        exportedPoints=count,segments=segments}
end

---------------------------------------------------------------------------
-- Export sources: THE single list of what leaves the addon.
-- Every top-level key of MyCharForeverDB must appear in exactly one place
-- here (groups, special or excluded); /mcf exportcheck reports any key that
-- does not. When you add tracking data, add its key here and document it in
-- docs/EXPORT_SCHEMA.md (bump MCF.EXPORT_VERSION only for breaking changes).
---------------------------------------------------------------------------
MCF.EXPORT_VERSION=3
MCF.ExportSources={
    groups={ -- option name -> db keys copied as they are
        character={"character","levels","levelSnapshots","gearByLevel","levelActivity","stats","afk"},
        adventure={"dungeons","goldHistory","goldByLevel","goldLooted","duels","travel","firstVisitedZones","locationTime","zoneTime",
                   "combat","worldDrops","crafting","gathering","professions","reputation","guild","achievements","statistics","iconic","camping","pvp","tracking"},
        events={"events","sessions"},
        journal={"journal"},
        screenshots={"screenshots"},
        settings={"settings"},
    },
    special={journey="Route; thinned into segments by simplifyJourney (raw only on request)"},
    computed={social="MCF:GetSocialSummary() replaces the raw db.social counters"},
    excluded={
        combatDebug="Diagnose",
        damageMeterDebug="Diagnose (own export: /mcfdmgdebug)",
        maintenance="Wartungsprotokoll, kein Chronik-Inhalt",
        dbVersion="intern; im Export als meta.dbVersion",
        gearBackfilled="interne Markierung der Ausrüstungs-Nachrechnung",
        migrations="Migrationsprotokoll, kein Chronik-Inhalt",
        recovered="Reparatur-Ablage für beschädigte Schlüssel",
        newerThanAddon="interne Markierung (Daten von neuerer Addon-Version)",
        lastAddonVersion="intern; zuletzt benutzte Addon-Version",
    },
}

-- Keys of MyCharForeverDB that no export rule covers (sorted).
function MCF:GetUnexportedKeys()
    local known={}
    local src=self.ExportSources
    for _,list in pairs(src.groups) do for _,k in ipairs(list) do known[k]=true end end
    for k in pairs(src.special) do known[k]=true end
    for k in pairs(src.computed) do known[k]=true end
    for k in pairs(src.excluded) do known[k]=true end
    local missing={}
    for k in pairs(MyCharForeverDB or {}) do
        if not known[k] then missing[#missing+1]=tostring(k) end
    end
    table.sort(missing)
    return missing
end

local function collectMapIDs(v,found,depth)
    if type(v)~="table" or depth>8 then return end
    for k,val in pairs(v) do
        if k=="mapID" and type(val)=="number" then found[val]=true
        elseif type(val)=="table" then collectMapIDs(val,found,depth+1) end
    end
end

local function buildMaps(data)
    local found={}
    collectMapIDs(data,found,0)
    local j=data.journey
    if type(j)=="table" and type(j.segments)=="table" then
        for _,seg in ipairs(j.segments) do for _,p in ipairs(seg) do if p[2] and p[2]>0 then found[p[2]]=true end end end
    elseif type(j)=="table" then
        for _,p in ipairs(j) do local m=type(p)=="table" and (p.m or p.mapID); if type(m)=="number" then found[m]=true end end
    end
    local maps={}
    for id in pairs(found) do
        local info=C_Map and C_Map.GetMapInfo and C_Map.GetMapInfo(id)
        maps[id]={name=info and info.name or nil,parent=info and info.parentMapID or nil}
    end
    return maps
end

local function utcOffset()
    local l=date("*t"); local u=date("!*t"); u.isdst=l.isdst
    return difftime(time(l),time(u))
end

local function buildMeta()
    local db=MyCharForeverDB or {}
    local ch=db.character or {}
    local faction=UnitFactionGroup and UnitFactionGroup("player") or nil
    local _,class=(UnitClass or function() end)("player") -- "A and f()" would keep only the first return value
    local _,_,_,toc=(GetBuildInfo or function() end)()
    return {
        name=ch.name,realm=ch.realm,faction=faction,class=class,race=ch.raceFile or ch.race,
        utcOffset=utcOffset(),
        gameBuild=toc,dbVersion=db.dbVersion,
        -- screenshots live in <WoW>/Screenshots; the file type comes from the client setting
        screenshotFormat=GetCVar and GetCVar("screenshotFormat") or nil,
        screenshotFolder="Screenshots",
    }
end

-- options.share=true references the live tables instead of copying them
-- (used for the SavedVariable, which is only read by WoW's serializer).
local function buildPayload(options)
    local db=MyCharForeverDB or {}
    options=options or {}
    local src=MCF.ExportSources
    local data={}
    local take=options.share and function(v) return v end or copyTable
    local function add(k) if db[k]~=nil then data[k]=take(db[k]) end end
    local function addGroup(name) for _,k in ipairs(src.groups[name]) do add(k) end end

    if options.character~=false then addGroup("character") end
    if options.adventure~=false then
        addGroup("adventure")
        if MCF.GetSocialSummary then data.social=MCF:GetSocialSummary() end
    end
    if options.events~=false then addGroup("events") end
    if options.journal~=false then addGroup("journal") end
    if options.screenshots~=false then addGroup("screenshots") end
    if options.journey~=false then
        data.journey=options.rawJourney and take(db.journey or {}) or simplifyJourney(db.journey or {})
    end
    if options.settings then addGroup("settings") end

    return {
        format="MyCharForever",exportVersion=MCF.EXPORT_VERSION,addonVersion=MCF.VERSION,
        exportedAt=time(),locale=GetLocale and GetLocale() or nil,
        journeySimplified=(options.journey~=false and not options.rawJourney) or false,
        note="Machine-readable chronicle export. Journey format 2 uses [timestamp,mapID,x,y,level] segments. See docs/EXPORT_SCHEMA.md.",
        meta=buildMeta(),
        maps=buildMaps(data),
        data=data,
    }
end

-- Write the export into its own SavedVariable (WoW saves it at logout/reload).
-- This is the file an external program should read.
function MCF:WriteExportDB()
    local ok,payload=pcall(buildPayload,{share=true})
    if not ok then return false,tostring(payload) end
    MyCharForeverExportDB=payload
    return true,payload
end

-- options.flat = true: compact JSON without indentation (used before compressing).
function MCF:BuildExport(options)
    return serialize(buildPayload(options),0,{},options and options.flat)
end

local frame=MCF.Kit.Window("MyCharForeverExportFrame",{w=720,h=560,level=850,title=T("Export chronicle")})

local help=frame.content:CreateFontString(nil,"ARTWORK","GameFontHighlight")
help:SetPoint("TOPLEFT",4,0)
help:SetPoint("TOPRIGHT",-4,0)
help:SetJustifyH("LEFT")
help:SetText(T("Export help"))

local textBg=MCF.Kit.Inset(frame.content)
-- The text area starts below the help text, however many lines that takes at the current font size.
textBg:SetPoint("TOPLEFT",help,"BOTTOMLEFT",-4,-10); textBg:SetPoint("BOTTOMRIGHT",0,0)
local scroll=CreateFrame("ScrollFrame","MyCharForeverExportScroll",textBg,"UIPanelScrollFrameTemplate")
scroll:SetPoint("TOPLEFT",8,-8)
scroll:SetPoint("BOTTOMRIGHT",-28,8)

local EXPORT_TEXT_W=630
local edit=CreateFrame("EditBox","MyCharForeverExportEditBox",scroll)
edit:SetMultiLine(true)
edit:SetAutoFocus(false)
edit:SetFontObject(ChatFontNormal)
edit:SetWidth(EXPORT_TEXT_W)
edit:SetMaxLetters(0)
edit:SetScript("OnEscapePressed",function() frame:Hide() end)
scroll:SetScrollChild(edit)

local measure=frame:CreateFontString(nil,"ARTWORK")
measure:SetFontObject(ChatFontNormal)
measure:SetWidth(EXPORT_TEXT_W)
measure:SetJustifyH("LEFT")
measure:SetJustifyV("TOP")
measure:Hide()

local function SetExportText(value)
    value=value or ""
    edit:SetText(value)
    edit:SetCursorPosition(0)
    measure:SetText(value)
    local measured=measure:GetStringHeight() or 0
    edit:SetHeight(math.max(420,math.ceil(measured)+24))
    scroll:SetVerticalScroll(0)
end

local Open
-- Bottom row: Select all (usable once the text is ready) and, for the chronicle, a pointer to the website's import.
local EXPORT_BUTTON_W=150
local select=CreateFrame("Button",nil,frame,"UIPanelButtonTemplate")
select:SetSize(EXPORT_BUTTON_W,24)
select:SetPoint("BOTTOMLEFT",18,16)
select:SetText(T("Select all"))
select:SetScript("OnClick",function()
    edit:SetFocus()
    edit:HighlightText(0,-1)
    C_Timer.After(0,function() scroll:SetVerticalScroll(0) end)
end)

-- WoW cannot open a web page from an addon, so the button shows the address to copy, after saying that it leaves the game.
MCF.WEBSITE_URL="https://www.mycharforever.com"
local link=MCF.Kit.Window("MyCharForeverExportLinkFrame",{w=470,h=210,level=870,title=T("External link")})
local linkInfo=link:CreateFontString(nil,"ARTWORK","GameFontHighlightSmall")
linkInfo:SetPoint("TOPLEFT",18,-40); linkInfo:SetPoint("RIGHT",-18,0); linkInfo:SetJustifyH("LEFT")
linkInfo:SetText(T("External link help"))
local linkBox=CreateFrame("EditBox",nil,link,"InputBoxTemplate")
linkBox:SetSize(420,24); linkBox:SetPoint("TOPLEFT",24,-120); linkBox:SetAutoFocus(false)
linkBox:SetFontObject(ChatFontNormal)
linkBox:SetScript("OnEscapePressed",function() link:Hide() end)
linkBox:SetScript("OnTextChanged",function(self) if self:GetText()~=MCF.WEBSITE_URL then self:SetText(MCF.WEBSITE_URL); self:HighlightText() end end)
link:SetScript("OnShow",function() linkBox:SetText(MCF.WEBSITE_URL); linkBox:SetFocus(); linkBox:HighlightText() end)

local siteButton=CreateFrame("Button",nil,frame,"UIPanelButtonTemplate")
siteButton:SetSize(EXPORT_BUTTON_W,24); siteButton:SetPoint("LEFT",select,"RIGHT",8,0); siteButton:SetText(T("Open website"))
siteButton:SetScript("OnClick",function()
    link:ClearAllPoints(); link:SetPoint("CENTER",frame,"CENTER",0,0)
    link:Show(); link:Raise()
end)

local siteHint=MCF.Kit.Hint.Button(frame); siteHint:SetPoint("LEFT",siteButton,"RIGHT",6,0)

-- What the window currently shows: set by Open().
local current
local plainText, packedText, showPacked
local packToken=0
local function ShowText()
    local text=showPacked and packedText or plainText
    SetExportText(text)
    if current then
        if current.compress and showPacked and packedText then
            help:SetText(string.format(T("Export packed help"),#plainText/1024,#packedText/1024))
        else help:SetText(current.help) end
    end
end
-- The chronicle is packed (MCF1 text, see Compress.lua) before Select all becomes available.
local function Pack()
    if not plainText then return end
    packToken=packToken+1
    local token=packToken
    showPacked=true
    MCF.Compress.Encode(plainText,
        function(p) if token==packToken then help:SetText(string.format(T("Packing export"),math.floor(p*100))) end end,
        function(result)
            if token~=packToken then return end
            packedText=result; ShowText(); select:Enable()
        end,
        function()
            if token~=packToken then return end
            showPacked=false; ShowText()
            help:SetText(T("Packing failed"))
            select:Enable()
        end)
end

-- Shows the export window with a title, a help text and a builder function. The text is generated on the
-- next frame so a failure in serialization is visible instead of looking like a dead button.
-- o = {title=, help=, build=function() -> text, expert=true to offer the expert options, compress=true to open packed}
function Open(o)
    current=o
    frame.title:SetText(o.title)
    siteButton:SetShown(o.compress and true or false)
    siteHint:SetShown(o.compress and true or false)
    link:Hide()
    packToken=packToken+1
    plainText, packedText, showPacked = nil, nil, false
    select:Disable()
    frame:Show(); frame:Raise()
    help:SetText(T("Preparing export"))
    C_Timer.After(0,function()
        local ok,result=pcall(o.build)
        if ok and o.compress then
            plainText=result; showPacked=false
            ShowText(); Pack()
        elseif ok then SetExportText(result); help:SetText(o.help); select:Enable()
        else SetExportText(T("Export failed")..": "..tostring(result)); help:SetText(T("Export failed")); select:Enable() end
    end)
end

function MCF:ShowExport()
    Open({title=T("Export chronicle"),help=T("Export help"),compress=true,build=function() return MCF:BuildExport({flat=true}) end})
end

function MCF:BuildSingleScreenshotExport(shot)
    return serialize({format="MyCharForeverScreenshot",exportVersion=1,addonVersion=MCF.VERSION,exportedAt=time(),locale=GetLocale and GetLocale() or nil,screenshot=shot},0,{})
end
function MCF:ShowSingleScreenshotExport(shot)
    if not shot then return end
    Open({title=T("Export screenshot title"),help=string.format(T("Export screenshot help"),T("Select all")),
        build=function() return MCF:BuildSingleScreenshotExport(shot) end})
end

-- Every recorded screenshot: our own (with comment) and the normal game screenshots; shot.reason tells them apart.
function MCF:BuildScreenshotsExport()
    local shots={}
    for _,shot in ipairs((MyCharForeverDB and MyCharForeverDB.screenshots) or {}) do shots[#shots+1]=shot end
    return serialize({format="MyCharForeverScreenshots",exportVersion=1,addonVersion=MCF.VERSION,exportedAt=time(),locale=GetLocale and GetLocale() or nil,count=#shots,screenshots=shots},0,{})
end
function MCF:ShowErrorsExport()
    Open({title=MCF:GetLanguage()=="deDE" and "Fehlerprotokoll" or "Error log",
        help=MCF:GetLanguage()=="deDE" and "Zum Kopieren in einen Fehlerbericht: Text markieren und mit Strg+C kopieren. Leeren mit /mcf errors clear."
            or "To paste into a bug report: select the text and copy it with Ctrl+C. Empty it with /mcf errors clear.",
        build=function() return MCF:BuildErrorReport() end})
end

function MCF:ShowSelfTestExport()
    Open({title=MCF:GetLanguage()=="deDE" and "Selbsttest" or "Self test",
        help=MCF:GetLanguage()=="deDE" and "OK = in Ordnung, WARN = bitte im Bericht erwähnen, FAIL = Fehler, INFO = nur zur Kenntnis. Zum Kopieren: Text markieren und Strg+C."
            or "OK = fine, WARN = please mention it in the report, FAIL = a problem, INFO = for your information. To copy: select the text and press Ctrl+C.",
        build=function() return (MCF:BuildSelfTestText()) end})
end

-- Every built-in test and diagnostic command with its explanation (single source: the command table, MCF:AddCommand).
function MCF:BuildCommandListText()
    local de = MCF:GetLanguage() == "deDE"
    local out = {}
    for _, g in ipairs({{"test", de and "TESTBEFEHLE (verändern nichts oder nur Testdaten)" or "TEST COMMANDS (change nothing or only test data)"},
                        {"debug", de and "DIAGNOSE" or "DIAGNOSTICS"}}) do
        out[#out + 1] = g[2]; out[#out + 1] = ""
        for _, c in ipairs(MCF.commands) do
            if c.group == g[1] and not c.hidden then
                out[#out + 1] = c.usage
                out[#out + 1] = "    " .. (de and c.de or c.en)
                if c.example then out[#out + 1] = "    " .. (de and "z. B. " or "e.g. ") .. c.example end
                out[#out + 1] = ""
            end
        end
    end
    return table.concat(out, "\n")
end

function MCF:ShowCommandList()
    local de = MCF:GetLanguage() == "deDE"
    Open({title = de and "Test- und Debug-Befehle" or "Test and debug commands",
        help = de and "Alle Befehle im Chat eingeben. Die Liste lässt sich markieren und mit Strg+C kopieren; die übrigen Befehle zeigt /mcf help."
            or "Type all commands in chat. The list can be selected and copied with Ctrl+C; /mcf help shows the other commands.",
        build = function() return MCF:BuildCommandListText() end})
end

function MCF:ShowBugReportExport()
    Open({title=MCF:GetLanguage()=="deDE" and "Fehlerbericht" or "Bug report",
        help=MCF:GetLanguage()=="deDE" and "Alles markieren, mit Strg+C kopieren und in die Fehlermeldung einfügen. Enthält keinen Charakter- oder Realmnamen und wird nirgends hin gesendet."
            or "Select everything, copy it with Ctrl+C and paste it into your bug report. It contains no character or realm name and is not sent anywhere.",
        build=function() return MCF:BuildBugReport() end})
end

function MCF:ShowDamageMeterDebugExport()
    Open({title="DamageMeter debug",help="DamageMeter debug - Ctrl+C",build=function()
        return serialize({format="MyCharForeverDamageMeterDebug",addonVersion=MCF.VERSION,exportedAt=time(),data=MCF:GetDamageMeterDebug()},0,{})
    end})
end

MCF:AddCommand{group="debug",usage="/mcfdmgdebug",de="Rohdaten des Schadensmessers als Export anzeigen",en="Show the raw damage-meter data as an export"}
SLASH_MYCHARFOREVERDMGDEBUG1="/mcfdmgdebug"
SlashCmdList.MYCHARFOREVERDMGDEBUG=function() MCF:ShowDamageMeterDebugExport() end

local function out(msg) print("|cff00ccffMyCharForever|r: "..msg) end
MCF:AddCommand{group="main",usage="/mcf export write",key="export write",
    de="Export-Datenbank (für externe Programme) jetzt schreiben; sonst automatisch beim Logout",
    en="Write the export database (for external programs) now; otherwise done automatically at logout",
    run=function()
        local ok,res=MCF:WriteExportDB()
        if ok then out((MCF:GetLanguage()=="deDE" and "Export-Datenbank geschrieben (Version " or "Export database written (version ")..MCF.EXPORT_VERSION..
            "). "..(MCF:GetLanguage()=="deDE" and "Die Datei wird beim Logout oder /reload gespeichert." or "The file is saved at logout or /reload."))
        else out("Export failed: "..tostring(res)) end
    end}
MCF:AddCommand{group="main",usage="/mcf exportcheck",key="exportcheck",
    de="Prüft, ob alle Tracking-Daten im Export berücksichtigt sind",
    en="Check that all tracked data is covered by the export",
    run=function()
        local missing=MCF:GetUnexportedKeys()
        local de=MCF:GetLanguage()=="deDE"
        if #missing==0 then out(de and "Export vollständig: jeder Schlüssel ist erfasst oder bewusst ausgeschlossen." or "Export complete: every key is exported or deliberately excluded.")
        else out((de and "NICHT im Export (Quellenliste in Export.lua ergänzen): " or "NOT in the export (add to the source list in Export.lua): ")..table.concat(missing,", ")) end
    end}
local exportFrame=CreateFrame("Frame")
exportFrame:RegisterEvent("PLAYER_LOGOUT")
exportFrame:SetScript("OnEvent",function() pcall(MCF.WriteExportDB,MCF) end)

tinsert(UISpecialFrames,"MyCharForeverExportFrame")
tinsert(UISpecialFrames,"MyCharForeverExpertExportFrame")
