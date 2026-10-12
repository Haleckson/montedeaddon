-- Local, optional narration of map pins and journal descriptions or short lore.
-- Speech is generated outside WoW. No credentials or network requests belong here.
local _, FC = ...
local Narrator = FC:NewModule("Narrator")
local Compat = FC.Compat
local ROOT = "Interface\\AddOns\\ForeverCompanion\\Media\\Narration\\"

local function plain(text)
    if type(text) ~= "string" then return "" end
    text = text:gsub("|H.-|h(.-)|h", "%1"):gsub("|T.-|t", " "):gsub("|A.-|a", " ")
    text = text:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|cn[^:]+:", ""):gsub("|r", "")
    text = text:gsub("||", "|"):gsub("\194\160", " "):gsub("\194\183", ", ")
    -- Lua's %s can classify individual UTF-8 bytes as whitespace under some
    -- Windows locales. Normalize ASCII whitespace without damaging accents.
    return (text:gsub("[ \t\r\n\f\v]+", " "):gsub("^ +", ""):gsub(" +$", ""))
end

-- The exporter calls this same function, keeping recordings and runtime text
-- aligned. Catalog accounts also cover discoveries made after the pack was built.
function Narrator:BuildText(rec, info)
    if not rec or rec.del then return nil end
    info = info or FC.UI.Display(rec)
    if info.rumored then return nil end
    local title, description, lore = plain(info.title), plain(info.description), plain(info.lore)
    if info.loreEntry and lore ~= "" then
        -- One recording per identity works for future sightings and entrances,
        -- regardless of the discovery's level, coordinates or observation text.
        title = plain(FC.DiscoveryLore:SpokenTitle(info.loreEntry, rec))
        description = ""
    end
    if title == "" or title == "?" then return nil end
    if description == title then description = "" end
    if not title:find("[.!?]$") then title = title .. "." end
    local text = description == "" and title or title .. " " .. description
    if lore ~= "" and lore ~= description then
        if not text:find("[.!?]$") then text = text .. "." end
        text = text .. " " .. lore
    end
    return text
end

function Narrator:Locale()
    return FC.Locale:Resolve(FC.Locale.active)
end

function Narrator:Clips()
    local pack = FC.NarrationManifest
    return pack and pack.version == 1 and pack.locales and pack.locales[self:Locale()] or {}
end

function Narrator:Path(text)
    local file = text and self:Clips()[text]
    -- Only generated filenames in the active language's directory are allowed.
    if type(file) ~= "string" or not file:match("^[a-f0-9]+%.mp3$") then return nil end
    return ROOT .. self:Locale() .. "\\" .. file
end

function Narrator:StatusText()
    local count = 0
    for text in pairs(self:Clips()) do if self:Path(text) then count = count + 1 end end
    if count == 0 then return FC.L.NARRATOR_PACK_MISSING end
    return string.format(FC.L.NARRATOR_PACK_READY, count, FC.Locale:Name(self:Locale()))
end

function Narrator:SampleText()
    local pack = FC.NarrationManifest
    return pack and pack.samples and pack.samples[self:Locale()]
end

function Narrator:HasSample()
    return self:Path(self:SampleText()) ~= nil
end

function Narrator:Volume()
    local value = FC.P and FC.P.narration and Compat.Safe(FC.P.narration.volume)
    value = tonumber(value) or 50
    if value ~= value then value = 50 end
    return math.floor(math.max(0, math.min(100, value)) / 25 + 0.5) * 25
end

function Narrator:PlaybackPath(text)
    local path, volume = self:Path(text), self:Volume()
    if not path or volume == 0 then return nil end
    if volume == 100 then return path end
    -- Pre-attenuated recordings provide independent volume on clients whose
    -- PlaySoundFile only accepts a channel. Never change global sound CVars.
    local pack = FC.NarrationManifest
    if not pack or not pack.volumes or pack.volumes[volume] ~= true then return nil end
    return ROOT .. self:Locale() .. "\\v" .. volume .. "\\" .. self:Clips()[text]
end

function Narrator:Stop()
    self.generation = (self.generation or 0) + 1
    if self.timer and self.timer.Cancel then self.timer:Cancel() end
    self.timer, self.owner, self.record, self.pendingText = nil, nil, nil, nil
    if self.handle then Compat.SafeCall(_G.StopSound, self.handle, 100) end
    self.handle = nil
end

function Narrator:Play(text)
    local path = self:PlaybackPath(text)
    if not path or type(_G.PlaySoundFile) ~= "function" or type(_G.StopSound) ~= "function" then return false end
    local played, handle = Compat.SafeCall(_G.PlaySoundFile, path, "Dialog")
    if played == true and type(handle) == "number" then
        self.handle = handle
        return true
    end
    return false
end

function Narrator:Preview()
    self:Stop()
    return self:Play(self:SampleText())
end

function Narrator:Hover(owner, rec, info)
    -- Keep one playback per continuous hover, including after it finishes.
    -- Leave clears the owner so returning can restart an interrupted line.
    if self.owner == owner and self.record == rec then return end
    self:Stop()
    local settings = FC.P and FC.P.narration
    if not settings or not settings.enabled or self:Volume() == 0 or not owner or owner.veiled then return end
    local text = self:BuildText(rec, info)
    if not self:Path(text) then return end
    self.owner, self.record, self.pendingText = owner, rec, text
    local generation, locale = self.generation, self:Locale()
    local delay = math.max(0.1, math.min(2, tonumber(settings.delay) or 0.5))
    local function start()
        if generation ~= self.generation then return end
        self.timer = nil
        if self.owner ~= owner or owner.rec ~= rec or owner.veiled or rec.del
            or locale ~= self:Locale() or not FC.P.narration.enabled
            or Compat.SafeCall(owner.IsVisible, owner) == false then self:Stop(); return end
        -- The record can have changed while the timer was waiting (sync/edit/fog).
        if self:BuildText(rec) ~= text then self:Stop(); return end
        self:Play(text)
    end
    if C_Timer and C_Timer.NewTimer then self.timer = C_Timer.NewTimer(delay, start)
    elseif C_Timer and C_Timer.After then C_Timer.After(delay, start)
    else self:Stop() end
end

function Narrator:Leave(owner)
    if self.owner == owner then self:Stop() end
end

function Narrator:CreateStatusControl(parent, width)
    local frame = CreateFrame("Frame", nil, parent)
    frame.text = FC.UI.WrappedText(frame, "secondary", "muted")
    frame.text:SetPoint("TOPLEFT")
    function frame:Layout(available)
        self:SetWidth(available)
        self.text:SetWidth(available)
        self.text:SetText(Narrator:StatusText())
        self:SetHeight(self.text:GetStringHeight() + 12)
        return self:GetHeight()
    end
    function frame:Refresh() self:Layout(self:GetWidth()) end
    return frame, frame:Layout(width)
end

function Narrator:OnEnable()
    FC.Bus:On("SETTINGS_CHANGED", self, function(self, path)
        if path == "*" or path:match("^narration%.") or path:match("^knowledge%.") then self:Stop() end
    end)
    FC.Bus:On("LANGUAGE_PREFERENCE_CHANGED", self, self.Stop)
    FC.Bus:On("STORE_RESET", self, self.Stop)
    FC.Bus:On("DISCOVERY_UPDATED", self, function(self, rec)
        if self.record and rec.id == self.record.id then self:Stop() end
    end)
    local function recordRemovedOrHidden(self, id)
        if self.record and id == self.record.id then self:Stop() end
    end
    FC.Bus:On("DISCOVERY_REMOVED", self, recordRemovedOrHidden)
    FC.Bus:On("DISCOVERY_STATE", self, recordRemovedOrHidden)
    FC.Events:Register("PLAYER_LEAVING_WORLD", self, self.Stop)
    FC.Events:Register("SOUNDKIT_FINISHED", self, function(self, _, handle)
        handle = Compat.Safe(handle)
        if handle and handle == self.handle then self.handle = nil end
    end)
end
