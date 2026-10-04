-- BLib_Profiles.lua: one place to save, copy and share every addon's settings (the shared framework,
-- docs/suite-consolidation-analysis.md option A: "one profile, one theme. A new character or a new computer is one
-- import, not fifteen").
--
-- An addon registers what it can hand over, and checks what it is handed:
--   BLib.Profiles.Register("Lifeline", {
--       name   = "Lifeline",                        shown to the player
--       export = function() return data end,       a copy of its settings: plain data, no functions or frames
--       import = function(data) return true end,   check and apply them; or return nil and why, changing nothing
--   })
-- The player:
--   /blib profile save <name>     every registered addon's settings from this character, kept for the account
--   /blib profile load <name>     put them on this character (each addon checks its own first)
--   /blib profile list            what is saved;  /blib profile delete <name>
--   /blib profile export [name]   one string holding them all (this character's now, or a saved one): a backup,
--                                 or a layout to share
--   /blib profile import          paste a string: it is added to the saved profiles, to load like any other
-- Nothing is applied in combat: an addon's import may rebuild secure frames.

BLib = BLib or {}
local Pr = {}
BLib.Profiles = Pr

local PREFIX, VERSION = "BLIB1:", 1
local registered, order = {}, {}

local function Say(text) if BLib.Print then BLib.Print("BLib", text) else print("BLib: " .. text) end end

-- A copy holding only what saved variables can hold: no functions, frames, or tables met twice.
local function Plain(v, seen)
    local kind = type(v)
    if kind == "string" or kind == "number" or kind == "boolean" then return v end
    if kind ~= "table" or (v.GetObjectType and type(v.GetObjectType) == "function") then return nil end
    seen = seen or {}
    if seen[v] then return nil end
    seen[v] = true
    local out = {}
    for k, x in pairs(v) do
        local kk = (type(k) == "string" or type(k) == "number") and k or nil
        if kk ~= nil then out[kk] = Plain(x, seen) end
    end
    seen[v] = nil
    return out
end
Pr.Plain = Plain

-- For an addon's import: copies src into dst keeping dst's tables (its frames may hold them). Below the top level the
-- result is exactly src, so a set such as hidden zones or excluded guild banks loses an entry added since the profile
-- was saved (a plain merge never could); at the top level a key src lacks is left alone, so a profile saved by an
-- older version keeps the settings added since. Review of the imports, 2026-10-03.
local function Exact(dst, src)
    for k in pairs(dst) do if src[k] == nil then dst[k] = nil end end
    for k, v in pairs(src) do
        if type(v) == "table" then
            if type(dst[k]) ~= "table" then dst[k] = {} end
            Exact(dst[k], v)
        else
            dst[k] = v
        end
    end
end

function Pr.Put(dst, src)
    for k, v in pairs(src) do
        if type(v) == "table" then
            if type(dst[k]) ~= "table" then dst[k] = {} end
            Exact(dst[k], v)
        else
            dst[k] = v
        end
    end
end

local function Walk(t, path)
    local keys = {}
    for key in path:gmatch("[^.]+") do keys[#keys + 1] = key end
    local node = t
    for i = 1, #keys - 1 do
        node = type(node) == "table" and node[keys[i]] or nil
    end
    return node, keys[#keys], keys
end

-- What is not a setting, by dotted path ("vendor.filters", "minimapAngle"): taken out of an export with Strip, set
-- aside before Put with Keep and given back after with Restore (the same values, tables and all), so a window's
-- state, a record or this screen's positions stay where they are.
function Pr.Strip(t, paths)
    for _, path in ipairs(paths) do
        local node, last = Walk(t, path)
        if type(node) == "table" then node[last] = nil end
    end
    return t
end

function Pr.Keep(t, paths)
    local kept = {}
    for i, path in ipairs(paths) do
        local node, last, keys = Walk(t, path)
        kept[i] = { keys = keys, value = type(node) == "table" and node[last] or nil }
    end
    return kept
end

function Pr.Restore(t, kept)
    for _, k in ipairs(kept) do
        local node = t
        for i = 1, #k.keys - 1 do
            if type(node[k.keys[i]]) ~= "table" then
                if k.value == nil then node = nil break end
                node[k.keys[i]] = {}
            end
            node = node[k.keys[i]]
        end
        if node then node[k.keys[#k.keys]] = k.value end
    end
end

function Pr.Register(key, def)
    if type(key) ~= "string" or type(def) ~= "table" or type(def.export) ~= "function" or type(def.import) ~= "function" then
        return false
    end
    if not registered[key] then order[#order + 1] = key end
    registered[key] = { key = key, name = def.name or key, export = def.export, import = def.import }
    return true
end

function Pr.Registered()
    local list = {}
    for _, key in ipairs(order) do list[#list + 1] = registered[key] end
    return list
end

local function Store()
    BLibDB = BLibDB or {}
    BLibDB.profiles = BLibDB.profiles or {}
    return BLibDB.profiles
end

local function Who()
    local name = UnitName and UnitName("player")
    return type(name) == "string" and name or "?"
end

-- This character's settings, every registered addon's, as one table.
function Pr.Snapshot()
    local addons, names = {}, {}
    for _, key in ipairs(order) do
        local ok, data = pcall(registered[key].export)
        if ok and data ~= nil then
            addons[key] = Plain(data)
            names[#names + 1] = registered[key].name
        end
    end
    return { v = VERSION, saved = time and time() or 0, by = Who(), addons = addons }, names
end

-- A saved profile by name, the case of its letters aside.
local function Find(name)
    local store = Store()
    if store[name] then return name, store[name] end
    local lower = (name or ""):lower()
    for k, p in pairs(store) do if k:lower() == lower then return k, p end end
    return nil
end

function Pr.Save(name)
    if type(name) ~= "string" or name:match("^%s*$") then return nil, "a profile needs a name" end
    local snap, names = Pr.Snapshot()
    if #names == 0 then return nil, "no addon has registered settings to save" end
    local key = Find(name) or name
    Store()[key] = snap
    return key, names
end

-- Puts a profile's settings on this character. Returns the addons applied, the ones that refused (with why), and
-- the ones not installed here.
function Pr.Apply(profile)
    if InCombatLockdown and InCombatLockdown() then return nil, "not in combat: an addon may rebuild its frames" end
    if type(profile) ~= "table" or type(profile.addons) ~= "table" then return nil, "that profile holds nothing" end
    local done, refused, missing = {}, {}, {}
    for key, data in pairs(profile.addons) do
        local reg = registered[key]
        if not reg then
            missing[#missing + 1] = key
        else
            local ok, applied, why = pcall(reg.import, Plain(data))
            if ok and applied then done[#done + 1] = reg.name
            else refused[#refused + 1] = reg.name .. " (" .. tostring(ok and (why or "it said no") or applied) .. ")" end
        end
    end
    table.sort(done) table.sort(refused) table.sort(missing)
    return done, refused, missing
end

function Pr.Load(name)
    local key, profile = Find(name)
    if not key then return nil, ("there is no profile called %q"):format(tostring(name)) end
    return Pr.Apply(profile)
end

function Pr.Delete(name)
    local key = Find(name)
    if not key then return false end
    Store()[key] = nil
    return true
end

function Pr.List()
    local list = {}
    for name, p in pairs(Store()) do
        local addons = {}
        for key in pairs(p.addons or {}) do addons[#addons + 1] = registered[key] and registered[key].name or key end
        table.sort(addons)
        list[#list + 1] = { name = name, saved = p.saved, by = p.by, addons = addons }
    end
    table.sort(list, function(a, b) return a.name:lower() < b.name:lower() end)
    return list
end

-- ------------------------------------------------------------ the string (CBOR, compressed, base64: Lifeline's)

local CEU = C_EncodingUtil

function Pr.Encode(payload)
    if not CEU then return nil, "this client has no C_EncodingUtil" end
    local text
    for _, fn in ipairs({ CEU.SerializeCBOR, CEU.SerializeJSON }) do
        if type(text) ~= "string" and fn then
            local ok, r = pcall(fn, payload)
            if ok then text = r end
        end
    end
    if type(text) ~= "string" then return nil, "the settings could not be written out" end
    if CEU.CompressString then
        local ok, r = pcall(CEU.CompressString, text)
        if ok and type(r) == "string" then text = r end
    end
    local ok, encoded = pcall(CEU.EncodeBase64 or error, text)
    if not ok or type(encoded) ~= "string" then return nil, "the settings could not be encoded" end
    return PREFIX .. encoded
end

function Pr.Decode(text)
    if not CEU then return nil, "this client has no C_EncodingUtil" end
    text = (text or ""):gsub("%s+", "")
    if text:sub(1, #PREFIX) ~= PREFIX then return nil, "that is not a BLib profile (it starts " .. PREFIX .. ")" end
    local ok, raw = pcall(CEU.DecodeBase64 or error, text:sub(#PREFIX + 1))
    if not ok or type(raw) ~= "string" then return nil, "the text is damaged: copy all of it and try again" end
    if CEU.DecompressString then
        local okD, r = pcall(CEU.DecompressString, raw)
        if okD and type(r) == "string" then raw = r end
    end
    local payload
    for _, fn in ipairs({ CEU.DeserializeCBOR, CEU.DeserializeJSON }) do
        if type(payload) ~= "table" and fn then
            local okP, r = pcall(fn, raw)
            if okP then payload = r end
        end
    end
    if type(payload) ~= "table" or type(payload.addons) ~= "table" then return nil, "the text holds no settings" end
    return Plain(payload)
end

function Pr.ExportString(name)
    if name and name ~= "" then
        local key, profile = Find(name)
        if not key then return nil, ("there is no profile called %q"):format(name) end
        local p = Plain(profile)
        p.name = key
        return Pr.Encode(p)
    end
    local snap = Pr.Snapshot()
    snap.name = Who()
    return Pr.Encode(snap)
end

-- Adds a pasted profile to the saved ones, under its own name (a number after it if that name is taken).
function Pr.ImportString(text)
    local payload, err = Pr.Decode(text)
    if not payload then return nil, err end
    local base = (type(payload.name) == "string" and payload.name ~= "") and payload.name or "Imported"
    local name, n = base, 1
    while Find(name) do n = n + 1 name = base .. " " .. n end
    Store()[name] = payload
    return name, payload
end

-- ------------------------------------------------------------ the paste window

local pasteDialog

local function BuildPaste()
    local t = BLib.GetTheme and BLib.GetTheme() or nil
    local f, content = BLib.MakePopout("Import a profile", 420, 300, t, nil, "DIALOG")
    f:SetPoint("CENTER", UIParent, "CENTER", 0, 40)
    tinsert(UISpecialFrames, f:GetName())
    local box = CreateFrame("Frame", nil, content)
    box:SetPoint("TOPLEFT", 6, -6)
    box:SetPoint("BOTTOMRIGHT", -6, 34)
    BLib.MakeBg(box, t.panelBg)
    BLib.ApplyBorder(box, box, t.border)
    local eb = CreateFrame("EditBox", nil, box)
    eb:SetMultiLine(true)
    eb:SetAutoFocus(false)
    eb:SetPoint("TOPLEFT", 6, -6)
    eb:SetPoint("BOTTOMRIGHT", -6, 6)
    BLib.SetFontSafe(eb, BLib.FONT, BLib.FONT_SM, "")
    eb:SetScript("OnEscapePressed", function() f:Hide() end)
    box:EnableMouse(true)
    box:SetScript("OnMouseDown", function() eb:SetFocus() end)
    local add = BLib.MakeButton(content, "Add to my profiles", 160, 22, t)
    add:SetPoint("BOTTOMRIGHT", content, "BOTTOMRIGHT", -6, 6)
    local hint = BLib.MakeFS(content, BLib.FONT_SM, t.subText)
    hint:SetPoint("BOTTOMLEFT", content, "BOTTOMLEFT", 8, 11)
    hint:SetText("Paste a BLib profile (Ctrl-V).")
    add:SetScript("OnClick", function()
        local name, payload = Pr.ImportString(eb:GetText())
        if not name then hint:SetText("Not added: " .. tostring(payload)) return end
        local list = {}
        for key in pairs(payload.addons) do list[#list + 1] = registered[key] and registered[key].name or (key .. ", not installed") end
        table.sort(list)
        Say(("added the profile |cffffffff%s|r (%s). /blib profile load %s puts it on this character."):format(name, table.concat(list, ", "), name))
        f:Hide()
    end)
    f.editBox, f.hint = eb, hint
    return f
end

function Pr.ShowImport()
    pasteDialog = pasteDialog or BuildPaste()
    pasteDialog.editBox:SetText("")
    pasteDialog.hint:SetText("Paste a BLib profile (Ctrl-V).")
    pasteDialog:Show()
    pasteDialog.editBox:SetFocus()
end

-- ------------------------------------------------------------ /blib profile

local function Report(done, refused, missing)
    if not done then Say("not loaded: " .. tostring(refused)) return end
    if #done > 0 then Say("loaded for " .. table.concat(done, ", ") .. ".") end
    if #refused > 0 then Say("refused, nothing changed for them: " .. table.concat(refused, "; ") .. ".") end
    if #missing > 0 then Say("not installed here, so skipped: " .. table.concat(missing, ", ") .. ".") end
    if #done == 0 and #refused == 0 then Say("nothing in it is installed here.") end
end

function Pr.Slash(rest)
    local cmd, arg = (rest or ""):match("^%s*(%S*)%s*(.-)%s*$")
    cmd = (cmd or ""):lower()
    if cmd == "save" then
        local key, names = Pr.Save(arg)
        if key then Say(("saved |cffffffff%s|r: %s."):format(key, table.concat(names, ", ")))
        else Say("not saved: " .. tostring(names)) end
    elseif cmd == "load" then
        Report(Pr.Load(arg))
    elseif cmd == "delete" then
        Say(Pr.Delete(arg) and ("deleted the profile %q."):format(arg) or ("there is no profile called %q."):format(arg))
    elseif cmd == "export" then
        local text, err = Pr.ExportString(arg)
        if text and BLib.ShowCopyDialog then BLib.ShowCopyDialog("BLib profile" .. (arg ~= "" and (": " .. arg) or ""), text)
        else Say("no export: " .. tostring(err)) end
    elseif cmd == "import" then
        Pr.ShowImport()
    else
        local list = Pr.List()
        if #list == 0 then Say("no profiles saved yet.") end
        for _, p in ipairs(list) do
            Say(("|cffffffff%s|r, saved by %s%s: %s"):format(p.name, tostring(p.by),
                (date and p.saved and p.saved > 0) and (" on " .. date("%Y-%m-%d", p.saved)) or "", table.concat(p.addons, ", ")))
        end
        local regs = {}
        for _, r in ipairs(Pr.Registered()) do regs[#regs + 1] = r.name end
        Say("addons that take part: " .. (#regs > 0 and table.concat(regs, ", ") or "none yet") .. ".")
        Say("/blib profile save <name> | load <name> | delete <name> | export [name] | import")
    end
end
