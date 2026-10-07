--[[
  Forever Companion - UI/Fonts.lua
  Typography hierarchy. One FontObject per role; every font string uses a
  role, so changing a font, size, outline, shadow or spacing in Settings
  updates the whole addon instantly.

  Only fonts shipped with the game client are offered (no font files are
  packaged). If LibSharedMedia-3.0 is installed, its fonts are listed too.
]]

local _, FC = ...

local Fonts = FC:NewModule("Fonts")

local U = FC.Utils

Fonts.BUILTIN = {
    { name = "Friz Quadrata", path = "Fonts\\FRIZQT__.TTF" },
    { name = "Arial Narrow", path = "Fonts\\ARIALN.TTF" },
    { name = "Morpheus", path = "Fonts\\MORPHEUS.TTF" },
    { name = "Skurri", path = "Fonts\\SKURRI.TTF" },
}

-- role = { font source ("main" | "header"), size offset from the base size }
Fonts.ROLES = {
    title = { "header", 7 },
    header = { "header", 3 },
    cardTitle = { "main", 1 },
    body = { "main", 0 },
    secondary = { "main", -1 },
    meta = { "main", -2 },
    numeric = { "header", 10 },
    button = { "main", 0 },
}

Fonts.objects = {}

local function sharedMedia()
    local stub = _G.LibStub
    if not stub then return nil end
    local ok, lsm = pcall(stub, "LibSharedMedia-3.0", true)
    if ok then return lsm end
    return nil
end

--- All selectable fonts: { name, path }.
function Fonts:List()
    local list, seen = {}, {}
    for _, f in ipairs(self.BUILTIN) do
        list[#list + 1] = f
        seen[f.name] = true
    end
    local lsm = sharedMedia()
    if lsm and lsm.List and lsm.Fetch then
        local ok, names = pcall(lsm.List, lsm, "font")
        if ok and type(names) == "table" then
            for _, name in ipairs(names) do
                if not seen[name] then
                    local okFetch, path = pcall(lsm.Fetch, lsm, "font", name, true)
                    if okFetch and path then
                        list[#list + 1] = { name = name, path = path }
                        seen[name] = true
                    end
                end
            end
        end
    end
    return list
end

function Fonts:Path(name)
    for _, f in ipairs(self:List()) do
        if f.name == name then return f.path end
    end
    return self.BUILTIN[1].path
end

function Fonts:Get(role)
    return self.objects[role] or self.objects.body
end

function Fonts:Apply()
    local settings = FC.P.fonts
    local base = U.Clamp(tonumber(settings.size) or 12, 9, 20)
    local mainPath = self:Path(settings.main)
    local headerPath = self:Path(settings.header)
    local flags = settings.outline ~= "NONE" and settings.outline or ""
    for role, def in pairs(self.ROLES) do
        local object = self.objects[role]
        if not object then
            object = CreateFont("ForeverCompanionFont_" .. role)
            self.objects[role] = object
        end
        local path = def[1] == "header" and headerPath or mainPath
        local ok, applied = pcall(object.SetFont, object, path, base + def[2], flags)
        if not ok or applied == false then
            object:SetFont(self.BUILTIN[1].path, base + def[2], flags)
        end
        if settings.shadow then
            object:SetShadowOffset(1, -1)
            object:SetShadowColor(0, 0, 0, 0.75)
        else
            object:SetShadowOffset(0, 0)
        end
        if object.SetSpacing then object:SetSpacing(settings.spacing or 0) end
    end
    FC.Bus:Emit("FONTS_CHANGED")
end

function Fonts:OnInitialize()
    self:Apply()
    FC.Bus:On("SETTINGS_CHANGED", self, function(_, path)
        if path == "*" or path:find("^fonts") then self:Apply() end
    end)
end
