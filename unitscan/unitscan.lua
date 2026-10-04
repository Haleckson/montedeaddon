-- event based scanning
local unitscan = CreateFrame'Frame'
unitscan:SetScript('OnUpdate', function() unitscan.UPDATE() end)
unitscan:SetScript('OnEvent', function(_, event, arg1, arg2, arg3, arg4, arg5)
    -- basic events
    if event == 'ADDON_LOADED' and arg1 == 'unitscan' then
        unitscan.LOAD()

    elseif event == 'PLAYER_ENTERING_WORLD' then
        C_Timer.After(4, unitscan._ensureCommsChannel)

    elseif event == 'PLAYER_TARGET_CHANGED' then
        unitscan._processUnitToken('target')

    elseif event == 'UPDATE_MOUSEOVER_UNIT' then
        unitscan._processUnitToken('mouseover')

    elseif event == 'NAME_PLATE_UNIT_ADDED' and arg1 then
        unitscan._processUnitToken(arg1)

    elseif event == 'UNIT_TARGET' and arg1 and strmatch(arg1, '^party%d$') then
        unitscan._processUnitToken(arg1 .. 'target')

    elseif event == 'CHAT_MSG_ADDON' and arg1 then
        local prefix, message, channel, sender = arg1, arg2, arg3, arg4
        unitscan._handleReceivedMessage(prefix, message, channel, sender)

    -- handle messages
    elseif event == 'CHAT_MSG_CHANNEL' and arg1 then
        if issecretvalue and (issecretvalue(arg1) or (arg4 and issecretvalue(arg4))) then
            return
        end
        local message = arg1
        local sender = arg2
        local channelName = arg4 -- channel name is arg4

        -- process substring
        if channelName and type(channelName) == "string" then
            local lname = strlower(channelName)
            local lcomm = strlower(COMMS_CHANNEL_NAME or "")
            if lname:find(lcomm, 1, true) then
                -- expected format
                local prefix_for_pattern = COMM_PREFIX or unitscan.COMM_PREFIX or "USHC"
                local pattern = '^' .. prefix_for_pattern .. '%s*(.*)$'
                local trimmed = nil
                local ok, err = pcall(function() trimmed = message:match(pattern) end)
                if not ok then return end

                if not trimmed or trimmed == "" then
                    -- find token
                    local b64match = message:match('[Bb]64:([A-Za-z0-9%+/%=]+)')
                    if b64match then
                        trimmed = 'B64:' .. b64match
                    else
                    end
                else
                end

                if trimmed and trimmed ~= '' then
                    -- determine prefix
                    local prefix_for_call = COMM_PREFIX or unitscan.COMM_PREFIX or "USHC"
                    unitscan._handleReceivedMessage(prefix_for_call, trimmed, channelName, sender)
                else
                end
            else
            end
        else
        end

    elseif event == 'ZONE_CHANGED_NEW_AREA' then
        -- only check if channel is missing to avoid unnecessary resets
        if not unitscan.commsChannelId or unitscan.commsChannelId <= 0 then
            C_Timer.After(4, unitscan._ensureCommsChannel)
        end
    end
end)

unitscan:RegisterEvent'ADDON_LOADED'
unitscan:RegisterEvent'PLAYER_TARGET_CHANGED'
unitscan:RegisterEvent'UPDATE_MOUSEOVER_UNIT'
unitscan:RegisterEvent'NAME_PLATE_UNIT_ADDED'
unitscan:RegisterEvent'UNIT_TARGET'
unitscan:RegisterEvent'CHAT_MSG_ADDON'
unitscan:RegisterEvent'CHAT_MSG_CHANNEL'
unitscan:RegisterEvent'PLAYER_ENTERING_WORLD'
unitscan:RegisterEvent'ZONE_CHANGED_NEW_AREA'


local RED = {.7, .15, .05}
local YELLOW = {1, 1, .15}

unitscan_targets = {}
local found = {}

local VISUAL_COOLDOWN = 60
local last_visual_alert = {}

local BROADCAST_COOLDOWN = 120
local last_broadcast = {}

local COMM_PREFIX = "USHC"

local COMMS_CHANNEL_NAME = "ushccomms"

unitscan.commsChannelId = nil
unitscan._joinAttempts = 0
unitscan._maxJoinAttempts = 3
unitscan._joinRetryInterval = 5

local TOLERANCE_POINTS = 6.0
local TOLERANCE_INT = math.floor(TOLERANCE_POINTS * 10 + 0.5)

unitscan._message_queue = {}

unitscan._hidden_chat_channels = unitscan._hidden_chat_channels or {}

local b64chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'

local function b64_encode(data)
    if not data or data == '' then return '' end
    local out = {}
    local len = #data
    local i = 1
    while i <= len do
        local a = string.byte(data, i) or 0
        local b = string.byte(data, i+1) or 0
        local c = string.byte(data, i+2) or 0
        local n = a * 65536 + b * 256 + c

        local i1 = math.floor(n / 262144) % 64   -- >> 18
        local i2 = math.floor(n / 4096) % 64     -- >> 12
        local i3 = math.floor(n / 64) % 64       -- >> 6
        local i4 = n % 64

        if (i + 2) > len then
            -- 3 bytes or less
            if (i + 1) > len then
                -- only one byte
                table.insert(out, b64chars:sub(i1+1, i1+1))
                table.insert(out, b64chars:sub(i2+1, i2+1))
                table.insert(out, '==')
            else
                -- two bytes
                table.insert(out, b64chars:sub(i1+1, i1+1))
                table.insert(out, b64chars:sub(i2+1, i2+1))
                table.insert(out, b64chars:sub(i3+1, i3+1))
                table.insert(out, '=')
            end
        else
            table.insert(out, b64chars:sub(i1+1, i1+1))
            table.insert(out, b64chars:sub(i2+1, i2+1))
            table.insert(out, b64chars:sub(i3+1, i3+1))
            table.insert(out, b64chars:sub(i4+1, i4+1))
        end
        i = i + 3
    end
    local res = table.concat(out)
    return res
end

local function b64_decode(data)
    if not data or data == '' then return '' end
    -- reverse map
    local rev = {}
    for i = 1, #b64chars do
        rev[b64chars:sub(i,i)] = i - 1
    end

    local out = {}
    local len = #data
    local i = 1
    while i <= len do
        local c1 = data:sub(i, i)
        local c2 = data:sub(i+1, i+1)
        local c3 = data:sub(i+2, i+2)
        local c4 = data:sub(i+3, i+3)

        local v1 = rev[c1] or 0
        local v2 = rev[c2] or 0
        local v3 = rev[c3] or 0
        local v4 = rev[c4] or 0

        local n = v1 * 262144 + v2 * 4096 + v3 * 64 + v4

        local byte1 = math.floor(n / 65536) % 256
        local byte2 = math.floor(n / 256) % 256
        local byte3 = n % 256

        if c3 == '=' and c4 == '=' then
            table.insert(out, string.char(byte1))
        elseif c4 == '=' then
            table.insert(out, string.char(byte1))
            table.insert(out, string.char(byte2))
        else
            table.insert(out, string.char(byte1))
            table.insert(out, string.char(byte2))
            table.insert(out, string.char(byte3))
        end

        i = i + 4
    end
    local res = table.concat(out)
    return res
end

local function split_escaped_fields(s, max_fields)
    local fields = {}
    local cur = {}
    local len = #s
    local i = 1
    local field_count = 1
    while i <= len do
        local ch = s:sub(i,i)
        if ch == '|' then
            local nextch = s:sub(i+1, i+1)
            if nextch == '|' then
                -- escaped pipe -> literal '|'
                cur[#cur+1] = '|'
                i = i + 2
            else
                -- separator
                fields[#fields+1] = table.concat(cur)
                cur = {}
                i = i + 1
                field_count = field_count + 1
                if max_fields and field_count == max_fields then
                    -- remainder olast
                    fields[#fields+1] = s:sub(i) or ""
                    --for idx
                    return fields
                end
            end
        else
            cur[#cur+1] = ch
            i = i + 1
        end
    end
    fields[#fields+1] = table.concat(cur)
    --maybe fix this later
    return fields
end

do
    local last_played = {}     -- table keyed unit name
    local delay = 1
    local SOUND_COOLDOWN = 60  -- match others for now

    function unitscan.play_sound(key)
        if not key then return end

        -- taxi
        if UnitOnTaxi("player") then
            return
        end

        local now = GetTime()
        local lp = last_played[key]

        -- first time (lp == nil) plays; subsequent plays only after cooldown
        if not lp or (now - lp) > SOUND_COOLDOWN then
            PlaySoundFile([[Interface\AddOns\unitscan\alarmx.wav]], 'Master')
            last_played[key] = now
            C_Timer.After(delay, function()
                PlaySoundFile([[Interface\AddOns\unitscan\alarmx.wav]], 'Master')
            end)
        end
    end
end


unitscan._suppress_broadcast = false

local function GetPlayerMapCoordsNormalized()
    if not (C_Map and C_Map.GetBestMapForUnit and C_Map.GetPlayerMapPosition) then
        return nil
    end
    local mapID = C_Map.GetBestMapForUnit("player")
    if not mapID or mapID == 0 then
        return nil
    end
    local uiPos = C_Map.GetPlayerMapPosition(mapID, "player")
    if not uiPos then
        return nil
    end
    local x, y
    if type(uiPos.GetXY) == "function" then
        x, y = uiPos:GetXY()
    else
        x = uiPos.x
        y = uiPos.y
    end
    if type(x) ~= "number" or type(y) ~= "number" then
        return nil
    end
    if x < 0 or x > 1 or y < 0 or y > 1 then
        return nil
    end
    return mapID, x, y
end

function unitscan._hideChannelFromChatFrames(channelName)
    if not channelName or channelName == '' then return end
    -- avoid repeating
    if unitscan._hidden_chat_channels[channelName] then
        return
    end

    for i = 1, 10 do
        local frame = _G["ChatFrame" .. i]
        if frame and ChatFrame_RemoveChannel then
            pcall(function()
                ChatFrame_RemoveChannel(frame, channelName)
            end)
        end
    end
    unitscan._hidden_chat_channels[channelName] = true
end

function unitscan._ensureCommsChannel()
    -- prevent overlapping
    if unitscan._lastEnsureCall and (GetTime() - unitscan._lastEnsureCall) < 2.0 then
        return
    end
    unitscan._lastEnsureCall = GetTime()

    -- check if already joined
    local existingID, existingName = GetChannelName(COMMS_CHANNEL_NAME)
    if existingID and existingID > 0 then
        unitscan.commsChannelId = existingID
        unitscan._hideChannelFromChatFrames(existingName)
        unitscan._emptyRetries = 0 -- reset defer counter on success
        return
    end

    if UnitOnTaxi("player") then
        return
    end

    -- delay forced join
    local chanList = { GetChannelList() }
    if #chanList == 0 then
        unitscan._emptyRetries = (unitscan._emptyRetries or 0) + 1
        if unitscan._emptyRetries < 5 then -- defer up to 5 times (20s max)
            C_Timer.After(4, unitscan._ensureCommsChannel)
            return
        end
    end

    if unitscan._joinAttempts >= unitscan._maxJoinAttempts then
        return
    end
    unitscan._joinAttempts = unitscan._joinAttempts + 1

    local function doJoin(name)
        pcall(function()
            JoinChannelByName(name)
        end)
    end

    -- initial join
    C_Timer.After(3.0, function()
        doJoin(COMMS_CHANNEL_NAME)

        -- fallback ticker
        -- append b
        local remaining_attempts = unitscan._maxJoinAttempts
        local current_channel_name = COMMS_CHANNEL_NAME
        local ticker = C_Timer.NewTicker(4, function(self)
            -- resolve id
            local cid = unitscan._resolveCommsChannelId()
            if cid and cid > 0 then
                unitscan._joinAttempts = 0
                self:Cancel()
                return
            end

            remaining_attempts = remaining_attempts - 1
            if remaining_attempts < 1 then
                -- limit fallback
                self:Cancel()
                return
            end

            -- append b
            current_channel_name = current_channel_name .. "b"
            doJoin(current_channel_name)
        end)
    end)
end

function unitscan._resolveCommsChannelId()
    -- Check direct name first for speed/stability
    local id, name = GetChannelName(COMMS_CHANNEL_NAME)
    if id and id > 0 then
        unitscan.commsChannelId = id
        unitscan._hideChannelFromChatFrames(name)
        return id
    end

    local chanList = { GetChannelList() }
    for i = 1, #chanList, 3 do
        local cid = chanList[i]
        local name = chanList[i+1]
        if name and type(name) == "string" then
            local lname = strlower(name)
            if lname == strlower(COMMS_CHANNEL_NAME) or lname:find(strlower(COMMS_CHANNEL_NAME), 1, true) then
                -- update cached id
                unitscan.commsChannelId = cid
                -- hide from frames
                unitscan._hideChannelFromChatFrames(name)
                return cid
            end
        end
    end
    -- not found -> clear cached id
    unitscan.commsChannelId = nil
    return nil
end

function unitscan._on_found(name)
    if not found[name] then
        found[name] = true
    end

    FlashClientIcon()
    unitscan.play_sound(name)

    local now = GetTime()
    if not last_visual_alert[name] or (now - last_visual_alert[name]) >= VISUAL_COOLDOWN then
        unitscan.flash.animation:Play()
        unitscan.discovered_unit = name
        last_visual_alert[name] = now
    else
    end

    if not unitscan._suppress_broadcast then
        unitscan._broadcastDetection(name)
    else
    end
end

function unitscan._processUnitToken(unitToken)
    if not unitToken or not UnitExists(unitToken) or UnitOnTaxi("player") then
        return
    end
    local uname = UnitName(unitToken)
    if not uname or (issecretvalue and issecretvalue(uname)) then
        return
    end
    local key = strupper(uname)
    if unitscan_targets[key] then
        unitscan._on_found(key)
    else
    end
end

function unitscan.target(name)
    if not name then return end
    unitscan._processUnitToken('target')
    unitscan._processUnitToken('mouseover')

    if C_NamePlate and C_NamePlate.GetNamePlates then
        local plates = C_NamePlate.GetNamePlates()
        if plates then
            for _, plate in ipairs(plates) do
                local unitToken
                if plate.UnitFrame and plate.UnitFrame.unit then
                    unitToken = plate.UnitFrame.unit
                elseif plate.unit then
                    unitToken = plate.unit
                elseif plate.namePlateUnitToken then
                    unitToken = plate.namePlateUnitToken
                end
                if unitToken and UnitExists(unitToken) then
                    local pname = UnitName(unitToken)
                    if pname and not (issecretvalue and issecretvalue(pname)) and strupper(pname) == name then
                        unitscan._on_found(name)
                        return
                    end
                end
            end
        end
    else
        for i = 1, 40 do
            local token = 'nameplate' .. i
            if UnitExists(token) then
                local pname = UnitName(token)
                if pname and not (issecretvalue and issecretvalue(pname)) and strupper(pname) == name then
                    unitscan._on_found(name)
                    return
                end
            end
        end
    end
end

function unitscan._broadcastDetection(key)
    -- channel/guild/group
    if not unitscan.commsChannelId and not IsInGuild() and not IsInGroup() then
        return
    end

    local now = GetTime()
    if last_broadcast[key] and (now - last_broadcast[key]) < BROADCAST_COOLDOWN then
        return
    end

    local layer = tonumber(_G["NWB_CurrentLayer"]) or 0
    if not layer or layer == 0 then
        return
    end

    local mapID, x, y = GetPlayerMapCoordsNormalized()
    if not mapID or not x or not y then
        return
    end

    local xi = math.floor(x * 1000 + 0.5)
    local yi = math.floor(y * 1000 + 0.5)
    local raw_msg = key .. "|" .. tostring(mapID) .. "|" .. tostring(xi) .. "|" .. tostring(yi) .. "|" .. tostring(layer)

    if C_ChatInfo and C_ChatInfo.RegisterAddonMessagePrefix then
        C_ChatInfo.RegisterAddonMessagePrefix(COMM_PREFIX)
    end

    local sent = false
    -- resolve channel id on send
    local cid = unitscan._resolveCommsChannelId()
    if cid then
        -- channel id
        -- b64 msg
        local b64 = b64_encode(raw_msg)
        local final_message = COMM_PREFIX .. " " .. "B64:" .. b64
        table.insert(unitscan._message_queue, { msg = final_message, cid = cid })
        sent = true
    end

    -- fallback using addon comms
    if not sent then
        if IsInGuild() and C_ChatInfo and C_ChatInfo.SendAddonMessage then
            pcall(function() C_ChatInfo.SendAddonMessage(COMM_PREFIX, raw_msg, "GUILD") end)
            sent = true
        end
        if IsInGroup() and C_ChatInfo and C_ChatInfo.SendAddonMessage then
            local channel = IsInRaid() and "RAID" or "PARTY"
            pcall(function() C_ChatInfo.SendAddonMessage(COMM_PREFIX, raw_msg, channel) end)
            sent = true
        end
    end

    last_broadcast[key] = now
end

function unitscan._sendNextInQueue()
    if not unitscan._message_queue or #unitscan._message_queue == 0 then
        return
    end

    -- resolve channel id at send
    local cid = unitscan._resolveCommsChannelId()
    if not cid or cid == 0 then
        -- unavailable
        return
    end

    local entry = unitscan._message_queue[1]
    if not entry or not entry.msg then
        table.remove(unitscan._message_queue, 1)
        return
    end


    -- safe message parse literally
    -- dont change raw msg, fix later
    local chat_safe_msg = tostring(entry.msg):gsub("|", "||")

    -- attempt send
    local ok, err = pcall(function()
        -- tostring(cid)
        SendChatMessage(chat_safe_msg, "CHANNEL", nil, tostring(cid))
    end)

    if ok then
        -- remove from queue
        table.remove(unitscan._message_queue, 1)
    else
        -- keep entry
    end
end

function unitscan._handleReceivedMessage(prefix, message, channel, sender)
    -- abort if nil
    if not message or message == "" or (issecretvalue and issecretvalue(message)) then
        return
    end
    if prefix ~= COMM_PREFIX then
    end

    -- detect b64 msg
    local key, fld2, fld3, fld4, fld5

    -- tolerance
    local b64payload = message:match('^%s*[Bb]64:(.+)$')
    if b64payload then
        -- pref
        local decoded = b64_decode(b64payload)
        if decoded and decoded ~= '' then
            key, fld2, fld3, fld4, fld5 = strsplit("|", decoded, 5)
			unitscan._rememberRemote(key, tonumber(fld2) or 0, tonumber(fld3) or 0, tonumber(fld4) or 0, tonumber(fld5) or 0)
        else
            return
        end
    else
        -- fallback
        local fields = split_escaped_fields(message, 5)
        key = fields[1]
        fld2 = fields[2]
        fld3 = fields[3]
        fld4 = fields[4]
        fld5 = fields[5]
    end

    if not key or not fld2 then
        return
    end

    local recvMapID = tonumber(fld2) or 0
    local recvXi = tonumber(fld3)
    if recvXi and fld4 and tonumber(fld4) and fld5 then
        local recvYi = tonumber(fld4) or 0
        local recvLayer = tonumber(fld5) or 0


        local localMapID = 0
        local localXInt, localYInt = nil, nil
        if C_Map and C_Map.GetBestMapForUnit then
            localMapID = C_Map.GetBestMapForUnit('player') or 0
            local mapID, lx, ly = GetPlayerMapCoordsNormalized()
            if mapID and lx and ly then
                localXInt = math.floor(lx * 1000 + 0.5)
                localYInt = math.floor(ly * 1000 + 0.5)
            end
        end
        local localNWBLayer = tonumber(_G["NWB_CurrentLayer"]) or 0


        if localMapID == recvMapID and localNWBLayer == recvLayer and localXInt and localYInt then
            if math.abs(localXInt - recvXi) <= TOLERANCE_INT and math.abs(localYInt - recvYi) <= TOLERANCE_INT then
                local keyU = strupper(key)
                if unitscan_targets[keyU] then
                    unitscan._suppress_broadcast = true
                    unitscan._on_found(keyU)
					last_broadcast[keyU] = GetTime()
                    unitscan._suppress_broadcast = false
                else
                end
            else
            end
        else
        end
    else
        local keySub = key
        local recvSubzone = fld3 or ""
        local recvLayer = tonumber(fld4) or 0

        local localMapID = 0
        if C_Map and C_Map.GetBestMapForUnit then
            localMapID = C_Map.GetBestMapForUnit('player') or 0
        end
        local localSubzone = GetSubZoneText() or ""
        local localNWBLayer = tonumber(_G["NWB_CurrentLayer"]) or 0


        if localMapID == recvMapID and localSubzone == recvSubzone and localNWBLayer == recvLayer then
            local keyU = strupper(keySub)
            if unitscan_targets[keyU] then
                unitscan._suppress_broadcast = true
                unitscan._on_found(keyU)
				last_broadcast[keyU] = GetTime()
                unitscan._suppress_broadcast = false
            else
            end
        else
        end
    end
end

function unitscan.LOAD()
    if C_ChatInfo and C_ChatInfo.RegisterAddonMessagePrefix then
        C_ChatInfo.RegisterAddonMessagePrefix(COMM_PREFIX)
    end

    C_Timer.After(4, unitscan._ensureCommsChannel)

	do
		local flash = CreateFrame'Frame'
		unitscan.flash = flash
		flash:Show()
		flash:SetAllPoints()
		flash:SetAlpha(0)
		flash:SetFrameStrata'FULLSCREEN_DIALOG'
		
		local texture = flash:CreateTexture()
		texture:SetBlendMode'ADD'
		texture:SetAllPoints()
		texture:SetTexture[[Interface\FullScreenTextures\LowHealth]]

		flash.animation = CreateFrame'Frame'
		flash.animation:Hide()
		flash.animation:SetScript('OnUpdate', function(self)
			local t = GetTime() - self.t0
			if t <= .5 then
				flash:SetAlpha(t * 2)
			elseif t <= 1 then
				flash:SetAlpha(1)
			elseif t <= 1.5 then
				flash:SetAlpha(1 - (t - 1) * 2)
			else
				flash:SetAlpha(0)
				self.loops = self.loops - 1
				if self.loops == 0 then
					self.t0 = nil
					self:Hide()
				else
					self.t0 = GetTime()
				end
			end
		end)
		function flash.animation:Play()
			if self.t0 then
				self.loops = 4
			else
				self.t0 = GetTime()
				self.loops = 3
			end
			self:Show()
		end
	end
	
	local button = CreateFrame('Button', 'unitscan_button', UIParent, 'BackdropTemplate')
button:SetAttribute('type', 'macro')
button:Hide()
unitscan.button = button
button:SetPoint('BOTTOM', UIParent, 0, 190)
button:SetWidth(177)
button:SetHeight(37)
button:SetScale(1.25)
button:SetMovable(true)
button:EnableMouse(true)
button:RegisterForDrag('LeftButton')
button:SetScript('OnMouseDown', function(self, button)
    if button == 'LeftButton' and IsControlKeyDown() then
        self:RegisterForClicks('LeftButtonDown', 'LeftButtonUp')
        self:StartMoving()
    end
end)
button:SetScript('OnMouseUp', function(self, button)
    if button == 'LeftButton' then
        self:StopMovingOrSizing()
        self:RegisterForClicks('LeftButtonDown')
    end
end)
button:SetFrameStrata('FULLSCREEN_DIALOG')
button:SetNormalTexture([[Interface\AddOns\unitscan\UI-Achievement-Parchment-Horizontal]])
button:SetBackdrop{
    tile = true,
    edgeSize = 16,
    edgeFile = [[Interface\AddOns\unitscan\UI-Achievement-Parchment-Horizontal]],
}
button:SetBackdropBorderColor(unpack(RED))
button:SetScript('OnEnter', function(self)
    self:SetBackdropBorderColor(unpack(RED))
end)
button:SetScript('OnLeave', function(self)
    self:SetBackdropBorderColor(unpack(RED))
end)

function button:set_target(name)
    self:SetText(name)
    self:SetAttribute('macrotext', '/cleartarget\n/targetexact ' .. name)
    self:Show()
    self.glow.animation:Play()
    self.shine.animation:Play()

    C_Timer.After(7, function()
        if not InCombatLockdown() then self:Hide() end
    end)
end

do
    local background = button:GetNormalTexture()
    background:SetDrawLayer'BACKGROUND'
    background:ClearAllPoints()
    background:SetPoint('BOTTOMLEFT', 3, 3)
    background:SetPoint('TOPRIGHT', -3, -3)
    background:SetTexCoord(0, 1, 0, .25)
end

do
    local title_background = button:CreateTexture(nil, 'BORDER')
    title_background:SetTexture[[Interface\AddOns\unitscan\UI-Achievement-Title]]
    title_background:SetPoint('TOPRIGHT', -5, -5)
    title_background:SetPoint('LEFT', 5, 0)
    title_background:SetHeight(18)
    title_background:SetTexCoord(0, .9765625, 0, .3125)
    title_background:SetAlpha(.8)

    local title = button:CreateFontString(nil, 'OVERLAY', 'GameFontHighlightMedium')
    title:SetWordWrap(false)
    title:SetPoint('TOPLEFT', title_background, 0, 0)
    title:SetPoint('RIGHT', title_background)
    button:SetFontString(title)

    local subtitle = button:CreateFontString(nil, 'OVERLAY', 'GameFontNormalLarge')
    subtitle:SetPoint('TOPLEFT', title, 'BOTTOMLEFT', 0, -1)
    subtitle:SetPoint('RIGHT', title)
    subtitle:SetText'Elite Detected'
end

	
	do
		local model = CreateFrame('PlayerModel', nil, button)
		button.model = model
		model:SetPoint('BOTTOMLEFT', button, 'TOPLEFT', 0, -4)
		model:SetPoint('RIGHT', 0, 0)
		model:SetHeight(button:GetWidth() * .6)
	end
	
	do
    local close = CreateFrame('Button', nil, button, 'UIPanelCloseButton')
    close:SetPoint('TOPRIGHT', 0, 0)
    close:SetWidth(0)
    close:SetHeight(0)
    close:SetHitRectInsets(0, 0, 0, 0)
    close:Hide()
end

	
	do
		local glow = button.model:CreateTexture(nil, 'OVERLAY')
		button.glow = glow
		glow:SetPoint('CENTER', button, 'CENTER')
		glow:SetWidth(400 / 300 * button:GetWidth())
		glow:SetHeight(171 / 70 * button:GetHeight())
		glow:SetTexture[[Interface\AddOns\unitscan\UI-Achievement-Alert-Glow]]
		glow:SetBlendMode'ADD'
		glow:SetTexCoord(0, .78125, 0, .66796875)
		glow:SetAlpha(0)

		glow.animation = CreateFrame'Frame'
		glow.animation:Hide()
		glow.animation:SetScript('OnUpdate', function(self)
			local t = GetTime() - self.t0
			if t <= .2 then
				glow:SetAlpha(t * 5)
			elseif t <= .7 then
				glow:SetAlpha(1 - (t - .2) * 2)
			else
				glow:SetAlpha(0)
				self:Hide()
			end
		end)
		function glow.animation:Play()
			self.t0 = GetTime()
			self:Show()
		end
	end

	do
		local shine = button:CreateTexture(nil, 'ARTWORK')
		button.shine = shine
		shine:SetPoint('TOPLEFT', button, 0, 8)
		shine:SetWidth(67 / 300 * button:GetWidth())
		shine:SetHeight(1.28 * button:GetHeight())
		shine:SetTexture[[Interface\AddOns\unitscan\UI-Achievement-Alert-Glow]]
		shine:SetBlendMode'ADD'
		shine:SetTexCoord(.78125, .912109375, 0, .28125)
		shine:SetAlpha(0)
		
		shine.animation = CreateFrame'Frame'
		shine.animation:Hide()
		shine.animation:SetScript('OnUpdate', function(self)
			local t = GetTime() - self.t0
			if t <= .3 then
				shine:SetPoint('TOPLEFT', button, 0, 8)
			elseif t <= .7 then
				shine:SetPoint('TOPLEFT', button, (t - .3) * 2.5 * self.distance, 8)
			end
			if t <= .3 then
				shine:SetAlpha(0)
			elseif t <= .5 then
				shine:SetAlpha(1)
			elseif t <= .7 then
				shine:SetAlpha(1 - (t - .5) * 5)
			else
				shine:SetAlpha(0)
				self:Hide()
			end
		end)
		function shine.animation:Play()
			self.t0 = GetTime()
			self.distance = button:GetWidth() - shine:GetWidth() + 8
			self:Show()
		end
	end
end

do
	function unitscan.UPDATE()
		if unitscan.discovered_unit and InCombatLockdown() then
			unitscan.button:set_target(unitscan.discovered_unit)
			unitscan.discovered_unit = nil
		elseif unitscan.discovered_unit and not InCombatLockdown() then
			unitscan.button_nocombat:set_target(unitscan.discovered_unit)
			unitscan.discovered_unit = nil
		end
		
		-- remote proximity report
		unitscan._checkProximityRemotes()
	end
end

function unitscan.print(msg)
	if DEFAULT_CHAT_FRAME then
		DEFAULT_CHAT_FRAME:AddMessage(LIGHTYELLOW_FONT_COLOR_CODE .. '|| UnitScan Hardcore || ' .. msg)
	end
end

function unitscan.sorted_targets()
	local sorted_targets = {}
	for key in pairs(unitscan_targets) do
		tinsert(sorted_targets, key)
	end
	sort(sorted_targets, function(key1, key2) return key1 < key2 end)
	return sorted_targets
end

function unitscan.toggle_target(name)
	local key = strupper(name)
	if unitscan_targets[key] then
		unitscan_targets[key] = nil
		found[key] = nil
		unitscan.print('|cFFFF0000removed: "' .. key .. '" from global tracking.|r')
	else
		if key ~= '' then
			unitscan_targets[key] = true
			unitscan.print('|cFF00FF00added: "' .. key .. '" to global tracking.|r')
		end
	end
end
	
SLASH_UNITSCAN1 = '/unitscan'
function SlashCmdList.UNITSCAN(parameter)
	local _, _, name = strfind(parameter, '^%s*(.-)%s*$')
	
	if name == '' then
		for _, key in ipairs(unitscan.sorted_targets()) do
			unitscan.print(key)
		end
	else
		unitscan.toggle_target(name)
	end
end

local function HideButtonFrame()
    if unitscan and unitscan.button then
        unitscan.button:Hide()
    end
    if unitscan and unitscan.button_nocombat then
        unitscan.button_nocombat:Hide()
    end
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
eventFrame:SetScript("OnEvent", HideButtonFrame)

local button_nocombat = CreateFrame('Button', 'unitscan_button_nocombat', UIParent, 'SecureActionButtonTemplate,BackdropTemplate')
button_nocombat:SetAttribute('type', 'macro')
button_nocombat:Hide()
unitscan.button_nocombat = button_nocombat
button_nocombat:SetPoint('BOTTOM', UIParent, 0, 190)
button_nocombat:SetWidth(177)
button_nocombat:SetHeight(37)
button_nocombat:SetScale(1.25)
button_nocombat:SetMovable(true)
button_nocombat:EnableMouse(true)
button_nocombat:RegisterForDrag('LeftButton')
button_nocombat:SetScript('OnMouseDown', function(self, button)
    if button == 'LeftButton' and IsControlKeyDown() then
        self:RegisterForClicks('LeftButtonDown', 'LeftButtonUp')
        self:StartMoving()
    end
end)
button_nocombat:SetScript('OnMouseUp', function(self, button)
    if button == 'LeftButton' then
        self:StopMovingOrSizing()
        self:RegisterForClicks('LeftButtonDown')
    end
end)
button_nocombat:SetFrameStrata('FULLSCREEN_DIALOG')
button_nocombat:SetNormalTexture([[Interface\AddOns\unitscan\UI-Achievement-Parchment-Horizontal]])
button_nocombat:SetBackdrop({
    tile = true,
    edgeSize = 16,
    edgeFile = [[Interface\AddOns\unitscan\UI-Achievement-Parchment-Horizontal]],
})
button_nocombat:SetBackdropBorderColor(unpack(RED))
button_nocombat:SetScript('OnEnter', function(self)
    self:SetBackdropBorderColor(unpack(RED))
end)
button_nocombat:SetScript('OnLeave', function(self)
    self:SetBackdropBorderColor(unpack(RED))
end)

function button_nocombat:set_target(name)
    self:SetText(name)
    self:SetAttribute('macrotext', '/cleartarget\n/targetexact ' .. name)
    self:Show()
    self.glow.animation:Play()
    self.shine.animation:Play()

    C_Timer.After(7, function()
        self:Hide()
    end)
end

do
    local background = button_nocombat:GetNormalTexture()
    background:SetDrawLayer'BACKGROUND'
    background:ClearAllPoints()
    background:SetPoint('BOTTOMLEFT', 3, 3)
    background:SetPoint('TOPRIGHT', -3, -3)
    background:SetTexCoord(0, 1, 0, .25)
end

do
    local title_background = button_nocombat:CreateTexture(nil, 'BORDER')
    title_background:SetTexture[[Interface\AddOns\unitscan\UI-Achievement-Title]]
    title_background:SetPoint('TOPRIGHT', -5, -5)
    title_background:SetPoint('LEFT', 5, 0)
    title_background:SetHeight(18)
    title_background:SetTexCoord(0, .9765625, 0, .3125)
    title_background:SetAlpha(.8)

    local title = button_nocombat:CreateFontString(nil, 'OVERLAY', 'GameFontHighlightMedium')
    title:SetWordWrap(false)
    title:SetPoint('TOPLEFT', title_background, 0, 0)
    title:SetPoint('RIGHT', title_background)
    button_nocombat:SetFontString(title)

    local subtitle = button_nocombat:CreateFontString(nil, 'OVERLAY', 'GameFontNormalLarge')
    subtitle:SetPoint('TOPLEFT', title, 'BOTTOMLEFT', 0, -1)
    subtitle:SetPoint('RIGHT', title)
    subtitle:SetText'Elite Detected'
end

do
    local model = CreateFrame('PlayerModel', nil, button_nocombat)
    button_nocombat.model = model
    model:SetPoint('BOTTOMLEFT', button_nocombat, 'TOPLEFT', 0, -4)
    model:SetPoint('RIGHT', 0, 0)
    model:SetHeight(button_nocombat:GetWidth() * .6)
end

do
    local close = CreateFrame('Button', nil, button_nocombat, 'UIPanelCloseButton')
    close:SetPoint('TOPRIGHT', 0, 0)
    close:SetWidth(0)
    close:SetHeight(0)
    close:SetHitRectInsets(0, 0, 0, 0)
    close:Hide()
end

do
    local glow = button_nocombat.model:CreateTexture(nil, 'OVERLAY')
    button_nocombat.glow = glow
    glow:SetPoint('CENTER', button_nocombat, 'CENTER')
    glow:SetWidth(400 / 300 * button_nocombat:GetWidth())
    glow:SetHeight(171 / 70 * button_nocombat:GetHeight())
    glow:SetTexture[[Interface\AddOns\unitscan\UI-Achievement-Alert-Glow]]
    glow:SetBlendMode'ADD'
    glow:SetTexCoord(0, .78125, 0, .66796875)
    glow:SetAlpha(0)

    glow.animation = CreateFrame'Frame'
    glow.animation:Hide()
    glow.animation:SetScript('OnUpdate', function(self)
        local t = GetTime() - self.t0
        if t <= .2 then
            glow:SetAlpha(t * 5)
        elseif t <= .7 then
            glow:SetAlpha(1 - (t - .2) * 2)
        else
            glow:SetAlpha(0)
            self:Hide()
        end
    end)
    function glow.animation:Play()
        self.t0 = GetTime()
        self:Show()
    end
end

do
    local shine = button_nocombat:CreateTexture(nil, 'ARTWORK')
    button_nocombat.shine = shine
    shine:SetPoint('TOPLEFT', button_nocombat, 0, 8)
    shine:SetWidth(67 / 300 * button_nocombat:GetWidth())
    shine:SetHeight(1.28 * button_nocombat:GetHeight())
    shine:SetTexture[[Interface\AddOns\unitscan\UI-Achievement-Alert-Glow]]
    shine:SetBlendMode'ADD'
    shine:SetTexCoord(.78125, .912109375, 0, .28125)
    shine:SetAlpha(0)

    shine.animation = CreateFrame'Frame'
    shine.animation:Hide()
    shine.animation:SetScript('OnUpdate', function(self)
        local t = GetTime() - self.t0
        if t <= .3 then
            shine:SetPoint('TOPLEFT', button_nocombat, 0, 8)
        elseif t <= .7 then
            shine:SetPoint('TOPLEFT', button_nocombat, (t - .3) * 2.5 * self.distance, 8)
        end
        if t <= .3 then
            shine:SetAlpha(0)
        elseif t <= .5 then
            shine:SetAlpha(1)
        elseif t <= .7 then
            shine:SetAlpha(1 - (t - .5) * 5)
        else
            shine:SetAlpha(0)
            self:Hide()
        end
    end)
    function shine.animation:Play()
        self.t0 = GetTime()
        self.distance = button_nocombat:GetWidth() - shine:GetWidth() + 8
        self:Show()
    end
end

local USHCverify = USHCverify or {}
USHCverify.isMainLoaded = true
_G["USHCverify"] = USHCverify

-- non-blocking WorldFrame hook(propagation)
do
    -- hook WorldFrame non-fuckeduply. this will not block clicks. hopefully
    if WorldFrame and WorldFrame.HookScript then
        WorldFrame:HookScript("OnMouseDown", function(self, button)
            -- send queued message
            unitscan._sendNextInQueue()
        end)
    end

    -- propagation for keys
    local kf = CreateFrame("Frame", "UnitScanKeyTrigger", UIParent)
    kf:EnableKeyboard(true)
    kf:SetPropagateKeyboardInput(true)
    kf:SetScript("OnKeyDown", function(self, key)
        -- send queued message
        unitscan._sendNextInQueue()
    end)
    kf:Show()
end

-- Remote-proximity

unitscan._recent_remote = unitscan._recent_remote or {}

function unitscan._rememberRemote(key, mapID, xi, yi, layer)
    if not key then return end
    local k = strupper(key)
    unitscan._recent_remote = unitscan._recent_remote or {}
    unitscan._recent_remote[k] = {
        t = GetTime(),
        mapID = tonumber(mapID) or 0,
        xi = tonumber(xi) or 0,
        yi = tonumber(yi) or 0,
        layer = tonumber(layer) or 0
    }
end

function unitscan._checkProximityRemotes()
    if not unitscan._recent_remote then return end
    local now = GetTime()

    -- get position
    local mapID, lx, ly = GetPlayerMapCoordsNormalized()
    if not mapID or not lx or not ly then
        -- no valid position
        return
    end
    local localXInt = math.floor(lx * 1000 + 0.5)
    local localYInt = math.floor(ly * 1000 + 0.5)
    local localLayer = tonumber(_G["NWB_CurrentLayer"]) or 0

    for key, rec in pairs(unitscan._recent_remote) do
        -- expire old
        if not rec or (now - rec.t) > 120 then
            unitscan._recent_remote[key] = nil
        else
            -- map/layer req
            if rec.mapID == mapID and rec.layer == localLayer then
                if math.abs(localXInt - (rec.xi or 0)) <= TOLERANCE_INT and math.abs(localYInt - (rec.yi or 0)) <= TOLERANCE_INT then
                    -- check keys ofc
                    if unitscan_targets[key] then
                        -- trigger local
                        unitscan._on_found(key)
                        -- remove stored
                        unitscan._recent_remote[key] = nil
                    end
                end
            end
        end
    end
end