local _, GQ = ...

GQ.Indicator = GQ.Indicator or {}

local ARROW_TEXTURE = "Interface\\BUTTONS\\Arrow-Up-Up"
local ARROW_WIDTH = 16
local ARROW_HEIGHT = 21
local ARROW_OVERLAP = -2
local ARROW_COLOR = { 0.12, 1, 0.12 }
local ARROW_GLOW_COLOR = { 0.45, 1, 0.45 }
local ARROW_GLOW_SCALE = 1.24
local ARROW_LAYOUT_VERSION = 4
local PULSE_SPEED = 3.2
local PULSE_ALPHA_MIN = 0.82
local PULSE_ALPHA_MAX = 1.0
local PULSE_GLOW_MIN = 0.12
local PULSE_GLOW_MAX = 0.38

local function GetItemIdFromLink(link)
    if not link then
        return nil
    end
    return tonumber(link:match("item:(%d+)"))
end

local function ResolveLinkFromTooltip(setter)
    if not setter or not GameTooltip or not GameTooltip.GetItem then
        return nil
    end

    GameTooltip:SetOwner(UIParent, "ANCHOR_NONE")
    setter()
    if GameTooltip.Show then
        GameTooltip:Show()
    end
    local _, link = GameTooltip:GetItem()
    GameTooltip:Hide()
    return link
end

local TRAINER_SERVICE_TYPES = {
    header = true,
    available = true,
    unavailable = true,
    used = true,
}

local function GetTrainerServiceType(index)
    if not GetTrainerServiceInfo or not index or index <= 0 then
        return nil
    end

    local name, second, third = GetTrainerServiceInfo(index)
    if not name then
        return nil
    end

    if TRAINER_SERVICE_TYPES[second] then
        return second
    end

    if TRAINER_SERVICE_TYPES[third] then
        return third
    end

    return second
end

function GQ.Indicator:ResolveTradeSkillOutputLink(index)
    if not index or index <= 0 then
        return nil
    end

    if GetTradeSkillItemLink then
        local link = GetTradeSkillItemLink(index)
        if link then
            return link
        end
    end

    if GameTooltip and GameTooltip.SetTradeSkillItem then
        return ResolveLinkFromTooltip(function()
            GameTooltip:SetTradeSkillItem(index)
        end)
    end

    return nil
end

function GQ.Indicator:ResolveCraftOutputLink(index)
    if not index or index <= 0 then
        return nil
    end

    if GetCraftItemLink then
        local link = GetCraftItemLink(index)
        if link then
            return link
        end
    end

    if GameTooltip and GameTooltip.SetCraftItem then
        return ResolveLinkFromTooltip(function()
            GameTooltip:SetCraftItem(index)
        end)
    end

    return nil
end

local function IsExpandCollapseTexture(texture)
    if not texture or not texture.GetTexture then
        return false
    end

    local path = texture:GetTexture()
    if not path then
        return false
    end

    path = tostring(path)
    return path:find("PlusButton", 1, true) ~= nil
        or path:find("MinusButton", 1, true) ~= nil
        or path:find("UI-PlusMinus", 1, true) ~= nil
end

local function IsTrainerListRow(button)
    if not button or not button.GetName then
        return false
    end

    local name = button:GetName() or ""
    if name:find("ClassTrainerSkill", 1, true) and name ~= "ClassTrainerSkillIcon" then
        return true
    end

    if ClassTrainerFrame and ClassTrainerFrame.ScrollBox and button.GetParent then
        local parent = button:GetParent()
        if parent == ClassTrainerFrame.ScrollBox or (parent and parent.GetParent and parent:GetParent() == ClassTrainerFrame.ScrollBox) then
            return true
        end
    end

    return false
end

local function IsTradeSkillListRow(button)
    if not button or not button.GetName then
        return false
    end

    local name = button:GetName() or ""
    if name:match("^TradeSkillSkill%d+$") then
        return true
    end

    if TradeSkillFrame and TradeSkillFrame.RecipeList and button.GetParent then
        local parent = button:GetParent()
        if parent == TradeSkillFrame.RecipeList or (parent and parent.GetParent and parent:GetParent() == TradeSkillFrame.RecipeList) then
            return true
        end
    end

    if TradeSkillFrame and TradeSkillFrame.ScrollBox and button.GetParent then
        local parent = button:GetParent()
        if parent == TradeSkillFrame.ScrollBox or (parent and parent.GetParent and parent:GetParent() == TradeSkillFrame.ScrollBox) then
            return true
        end
    end

    return false
end

local function IsCraftListRow(button)
    if not button or not button.GetName then
        return false
    end

    local name = button:GetName() or ""
    return name:match("^Craft%d+$") ~= nil
end

local function IsProfessionListRow(button)
    return IsTrainerListRow(button) or IsTradeSkillListRow(button) or IsCraftListRow(button)
end

local function GetTrainerServiceName(index)
    if not GetTrainerServiceInfo or not index or index <= 0 then
        return nil
    end

    return select(1, GetTrainerServiceInfo(index))
end

local function IsTrainerDetailIconHost(button)
    if not button then
        return false
    end

    local name = button.GetName and button:GetName() or ""
    if name == "ClassTrainerSkillIcon" then
        return true
    end

    if ClassTrainerFrame and (button == ClassTrainerFrame.Icon or button == ClassTrainerFrame.skillIcon) then
        return true
    end

    local inset = ClassTrainerFrame and (ClassTrainerFrame.bottomInset or ClassTrainerFrame.BottomInset)
    if inset and button.GetParent then
        local parent = button:GetParent()
        if parent == inset and not IsTrainerListRow(button) then
            local width = button:GetWidth() or 0
            local height = button:GetHeight() or 0
            return width >= 28 and height >= 28 and width <= 80 and height <= 80
        end
    end

    return false
end

local function IsTradeSkillDetailIconHost(button)
    if not button then
        return false
    end

    local name = button.GetName and button:GetName() or ""
    if name == "TradeSkillSkillIcon" or name == "TradeSkillDetailIcon" or name == "TradeSkillDetailItemIcon" then
        return true
    end

    if TradeSkillFrame and (button == TradeSkillFrame.DetailIcon or button == TradeSkillFrame.SkillIcon) then
        return true
    end

    local detailFrame = TradeSkillFrame and (TradeSkillFrame.Details or TradeSkillFrame.detailsFrame or TradeSkillFrame.DetailsFrame)
    if detailFrame and button.GetParent then
        local parent = button:GetParent()
        if parent == detailFrame and not IsTradeSkillListRow(button) then
            local width = button:GetWidth() or 0
            local height = button:GetHeight() or 0
            return width >= 28 and height >= 28 and width <= 80 and height <= 80
        end
    end

    return false
end

local function IsCraftDetailIconHost(button)
    if not button then
        return false
    end

    local name = button.GetName and button:GetName() or ""
    if name == "CraftIcon" then
        return true
    end

    return CraftFrame and button == CraftFrame.DetailIcon
end

local function IsDetailIconHost(button)
    return IsTrainerDetailIconHost(button) or IsTradeSkillDetailIconHost(button) or IsCraftDetailIconHost(button)
end

local function IsUsableIconTexture(texture, hostButton)
    if not texture or not texture.GetObjectType or texture:GetObjectType() ~= "Texture" then
        return false
    end

    if IsExpandCollapseTexture(texture) then
        return false
    end

    local width = texture:GetWidth() or 0
    local height = texture:GetHeight() or 0
    if width >= 14 and height >= 14 then
        return true
    end

    local sizeHost = hostButton or (texture.GetParent and texture:GetParent())
    if sizeHost and IsDetailIconHost(sizeHost) and sizeHost.GetWidth and sizeHost.GetHeight then
        local hostWidth = sizeHost:GetWidth() or 0
        local hostHeight = sizeHost:GetHeight() or 0
        if hostWidth >= 28 and hostHeight >= 28 and hostWidth <= 80 and hostHeight <= 80 then
            return true
        end
    end

    return false
end

local function AcceptIconAnchor(texture, hostButton)
    if IsUsableIconTexture(texture, hostButton) then
        return texture
    end
    return nil
end

local function GetSelectedTrainerServiceIndex()
    if ClassTrainerFrame and ClassTrainerFrame.selectedService then
        return ClassTrainerFrame.selectedService
    end

    if GetTrainerSelectionIndex then
        return GetTrainerSelectionIndex()
    end
end

local function IsTrainerServiceHeader(serviceIndex)
    return GetTrainerServiceType(serviceIndex) == "header"
end

function GQ.Indicator:PrimeDataItemInfo()
    -- Only prime upgrade-tracked IDs; never walk all BiS rows (10k+).
    self.itemNameCache = self.itemNameCache or {}
    if not self.upgradeItems then
        return
    end

    for itemId in pairs(self.upgradeItems) do
        local name = GQ.Data and GQ.Data.GetItemDisplayName and GQ.Data:GetItemDisplayName(itemId)
        if name then
            self.itemNameCache[itemId] = name
        end
    end
end

function GQ.Indicator:PrimeUpgradeItemInfo()
    if not self.upgradeItems then
        return
    end

    for itemId in pairs(self.upgradeItems) do
        if GQ.Data and GQ.Data.RequestItemInfo then
            GQ.Data:RequestItemInfo(itemId)
        else
            GetItemInfo(itemId)
        end
    end
end

function GQ.Indicator:MatchTrainerServiceName(serviceName)
    if not serviceName then
        return nil
    end

    local trimmed = strtrim(serviceName)
    local keys = { trimmed:lower() }
    local stripped = trimmed:match("^[^:]+:%s*(.+)$")
    if stripped then
        keys[#keys + 1] = strtrim(stripped):lower()
    end

    for _, key in ipairs(keys) do
        if self.upgradeItemNames and self.upgradeItemNames[key] then
            return self.upgradeItemNames[key]
        end
    end

    self.itemNameCache = self.itemNameCache or {}

    for _, key in ipairs(keys) do
        for itemId, name in pairs(self.itemNameCache) do
            if self.upgradeItems[itemId] and name:lower() == key then
                return itemId
            end
        end
    end

    if self.upgradeItems then
        for itemId in pairs(self.upgradeItems) do
            local name = (GQ.Data and GQ.Data.GetItemDisplayName and GQ.Data:GetItemDisplayName(itemId))
                or self.itemNameCache[itemId]
            if name and not (GQ.Data and GQ.Data.IsPlaceholderItemName and GQ.Data:IsPlaceholderItemName(name, itemId)) then
                self.itemNameCache[itemId] = name
                local lowerName = name:lower()
                for _, key in ipairs(keys) do
                    if lowerName == key then
                        self.upgradeItemNames = self.upgradeItemNames or {}
                        self.upgradeItemNames[key] = itemId
                        return itemId
                    end
                end
            end
        end
    end

    return nil
end

function GQ.Indicator:ResolveTrainerServiceItemId(index)
    local link = self:ResolveTrainerServiceLink(index)
    return link and GetItemIdFromLink(link) or nil
end

function GQ.Indicator:ResolveTrainerServiceLink(index)
    return nil
end

function GQ.Indicator:UpdateTrainerDetailIcon()
end

function GQ.Indicator:FindTrainerDetailIconHost()
    if _G.ClassTrainerSkillIcon and _G.ClassTrainerSkillIcon:IsShown() then
        return _G.ClassTrainerSkillIcon
    end

    if not ClassTrainerFrame then
        return _G.ClassTrainerSkillIcon
    end

    local inset = ClassTrainerFrame.bottomInset or ClassTrainerFrame.BottomInset
    if inset then
        local bestHost
        local bestSize = 0

        local function ScanFrame(frame, depth)
            if not frame or depth > 8 then
                return
            end

            if frame.IsObjectType and (frame:IsObjectType("Button") or frame:IsObjectType("Frame")) then
                if IsTrainerDetailIconHost(frame) or (not IsTrainerListRow(frame) and self:GetIconAnchor(frame)) then
                    local width = frame:GetWidth() or 0
                    if width > bestSize then
                        bestHost = frame
                        bestSize = width
                    end
                end
            end

            if frame.GetChildren then
                local ok, children = pcall(frame.GetChildren, frame)
                if ok and children then
                    for _, child in ipairs(children) do
                        ScanFrame(child, depth + 1)
                    end
                end
            end
        end

        ScanFrame(inset, 0)
        if bestHost then
            return bestHost
        end
    end

    if _G.ClassTrainerSkillIcon then
        return _G.ClassTrainerSkillIcon
    end

    for _, key in ipairs({ "Icon", "skillIcon", "SkillIcon", "detailIcon" }) do
        if ClassTrainerFrame[key] then
            return ClassTrainerFrame[key]
        end
    end

    return nil
end

function GQ.Indicator:FindTradeSkillDetailIconHost()
    local candidates = {
        _G.TradeSkillSkillIcon,
        _G.TradeSkillDetailIcon,
        _G.TradeSkillDetailItemIcon,
        TradeSkillFrame and TradeSkillFrame.DetailIcon,
        TradeSkillFrame and TradeSkillFrame.SkillIcon,
    }

    for _, candidate in ipairs(candidates) do
        if candidate and candidate.IsShown and candidate:IsShown() then
            return candidate
        end
    end

    for _, candidate in ipairs(candidates) do
        if candidate then
            return candidate
        end
    end

    return nil
end

function GQ.Indicator:GetTradeSkillSelectionIndex()
    if TradeSkillFrame and TradeSkillFrame.selectedSkill then
        return TradeSkillFrame.selectedSkill
    end

    if GetTradeSkillSelectionIndex then
        return GetTradeSkillSelectionIndex()
    end
end

local function IsTradeSkillHeader(index)
    if not index or index <= 0 or not GetTradeSkillInfo then
        return true
    end

    local _, skillType = GetTradeSkillInfo(index)
    return skillType == "header"
end

function GQ.Indicator:UpdateTradeSkillDetailIcon()
    local detailIcon = self:FindTradeSkillDetailIconHost()
    if detailIcon then
        self:HideButton(detailIcon)
    end
end

function GQ.Indicator:HideProfessionListRows(getButton, count)
    count = count or 0
    for i = 1, count do
        local button = getButton(i)
        if button then
            self:HideButton(button)
        end
    end
end

function GQ.Indicator:UpdateClassTrainerFrame()
end

function GQ.Indicator:ScheduleTrainerRefresh()
end

function GQ.Indicator:StartTrainerDetailWatcher()
end

function GQ.Indicator:StopTrainerDetailWatcher()
    if self.trainerDetailWatcher then
        self.trainerDetailWatcher:SetScript("OnUpdate", nil)
        self.trainerDetailWatcher = nil
    end
end

function GQ.Indicator:EnsureTrainerListButtonHooks()
end

function GQ.Indicator:EnsureTrainerFrameHooks()
end

function GQ.Indicator:OnTrainerOpen()
end

function GQ.Indicator:GetIconAnchor(button)
    if not button then
        return nil
    end

    if IsProfessionListRow(button) then
        return nil
    end

    if button.IsObjectType and button:IsObjectType("Texture") then
        local parent = button.GetParent and button:GetParent()
        if IsUsableIconTexture(button, parent) then
            return button
        end
        return nil
    end

    if IsDetailIconHost(button) then
        if button.icon and not IsExpandCollapseTexture(button.icon) then
            return button.icon
        end
        if button.IconTexture and not IsExpandCollapseTexture(button.IconTexture) then
            return button.IconTexture
        end
        if button.GetNormalTexture then
            local normal = button:GetNormalTexture()
            if normal and not IsExpandCollapseTexture(normal) then
                return normal
            end
        end
        return button
    end

    if button.icon then
        local anchor = AcceptIconAnchor(button.icon, button)
        if anchor then
            return anchor
        end
    end

    if button.Icon then
        local anchor = AcceptIconAnchor(button.Icon, button)
        if anchor then
            return anchor
        end
    end

    if button.IconTexture then
        local anchor = AcceptIconAnchor(button.IconTexture, button)
        if anchor then
            return anchor
        end
    end

    local name = button.GetName and button:GetName()
    if name then
        local named = _G[name .. "IconTexture"] or _G[name .. "Icon"]
        local anchor = AcceptIconAnchor(named, button)
        if anchor then
            return anchor
        end
    end

    if button.IconFrame then
        local frameIcon = button.IconFrame.icon or button.IconFrame.Icon
        local anchor = AcceptIconAnchor(frameIcon, button)
        if anchor then
            return anchor
        end
    end

    if IsDetailIconHost(button) and button.GetNormalTexture then
        local normal = button:GetNormalTexture()
        local anchor = AcceptIconAnchor(normal, button)
        if anchor then
            return anchor
        end
    end

    return nil
end

function GQ.Indicator:EnsurePulseTicker()
    if self.pulseTicker then
        return
    end

    self.pulseOverlays = {}

    local ticker = CreateFrame("Frame")
    ticker:Hide()
    ticker:SetScript("OnUpdate", function()
        local tracker = GQ.Indicator
        local overlays = tracker.pulseOverlays
        if not overlays or not next(overlays) then
            ticker:Hide()
            return
        end

        local wave = 0.5 + 0.5 * math.sin(GetTime() * PULSE_SPEED)
        local arrowAlpha = PULSE_ALPHA_MIN + (PULSE_ALPHA_MAX - PULSE_ALPHA_MIN) * wave
        local glowAlpha = PULSE_GLOW_MIN + (PULSE_GLOW_MAX - PULSE_GLOW_MIN) * wave
        local glowScale = ARROW_GLOW_SCALE + (0.1 * wave)

        for overlay in pairs(overlays) do
            if overlay:IsShown() and overlay.gqArrow then
                overlay.gqArrow:SetAlpha(arrowAlpha)
                if overlay.gqGlow then
                    overlay.gqGlow:SetAlpha(glowAlpha)
                    overlay.gqGlow:SetSize(ARROW_WIDTH * glowScale, ARROW_HEIGHT * glowScale)
                end
            else
                overlays[overlay] = nil
            end
        end
    end)

    self.pulseTicker = ticker
end

function GQ.Indicator:RegisterOverlayPulse(overlay)
    if not overlay then
        return
    end

    self:EnsurePulseTicker()
    self.pulseOverlays[overlay] = true
    self.pulseTicker:Show()
end

function GQ.Indicator:UnregisterOverlayPulse(overlay)
    if not overlay then
        return
    end

    if self.pulseOverlays then
        self.pulseOverlays[overlay] = nil
    end

    if overlay.gqArrow then
        overlay.gqArrow:SetAlpha(1)
    end
    if overlay.gqGlow then
        overlay.gqGlow:SetAlpha(0)
    end
end

function GQ.Indicator:CreateOverlayTextures(overlay)
    local glow = overlay:CreateTexture(nil, "BACKGROUND")
    glow:SetTexture(ARROW_TEXTURE)
    glow:SetTexCoord(0.08, 0.92, 0.02, 0.72)
    glow:SetVertexColor(ARROW_GLOW_COLOR[1], ARROW_GLOW_COLOR[2], ARROW_GLOW_COLOR[3])
    if glow.SetBlendMode then
        glow:SetBlendMode("ADD")
    end
    glow:SetAlpha(0)

    local arrow = overlay:CreateTexture(nil, "ARTWORK")
    arrow:SetTexture(ARROW_TEXTURE)
    arrow:SetTexCoord(0.08, 0.92, 0.02, 0.72)
    arrow:SetVertexColor(ARROW_COLOR[1], ARROW_COLOR[2], ARROW_COLOR[3])

    overlay.gqGlow = glow
    overlay.gqArrow = arrow
    overlay.gqArrowVersion = ARROW_LAYOUT_VERSION
end

function GQ.Indicator:ApplyOverlayLayout(overlay, anchor)
    local arrow = overlay.gqArrow
    local glow = overlay.gqGlow
    if not arrow then
        return
    end

    overlay:SetSize(ARROW_WIDTH, ARROW_HEIGHT)
    overlay:ClearAllPoints()
    overlay:SetPoint("BOTTOMRIGHT", anchor, "TOPRIGHT", 0, ARROW_OVERLAP)

    arrow:ClearAllPoints()
    arrow:SetAllPoints(overlay)

    if glow then
        glow:ClearAllPoints()
        glow:SetPoint("CENTER", arrow, "CENTER", 0, 0)
        glow:SetSize(ARROW_WIDTH * ARROW_GLOW_SCALE, ARROW_HEIGHT * ARROW_GLOW_SCALE)
    end
end

function GQ.Indicator:EnsureOverlay(button)
    if not button then
        return nil
    end

    local anchor = self:GetIconAnchor(button)
    if not anchor then
        self:HideButton(button)
        return nil
    end

    local parent = anchor.GetParent and anchor:GetParent() or button
    if not parent or (parent.IsObjectType and not parent:IsObjectType("Frame") and not parent:IsObjectType("Button")) then
        parent = button
    end

    local overlay = button.gqUpgradeOverlay
    if overlay and overlay.gqArrowVersion ~= ARROW_LAYOUT_VERSION then
        overlay:Hide()
        overlay:SetParent(nil)
        button.gqUpgradeOverlay = nil
        overlay = nil
    end

    if not overlay then
        overlay = CreateFrame("Frame", nil, parent)
        local frameLevel = parent.GetFrameLevel and parent:GetFrameLevel() or 1
        if ClassTrainerFrame and ClassTrainerFrame.GetFrameLevel then
            frameLevel = math.max(frameLevel, ClassTrainerFrame:GetFrameLevel() + 12)
        end
        if TradeSkillFrame and TradeSkillFrame.GetFrameLevel then
            frameLevel = math.max(frameLevel, TradeSkillFrame:GetFrameLevel() + 12)
        end
        overlay:SetFrameLevel(frameLevel + 10)
        if IsTrainerDetailIconHost(button) then
            overlay:SetFrameStrata("HIGH")
            overlay:SetFrameLevel(frameLevel + 25)
        elseif IsTradeSkillDetailIconHost(button) then
            overlay:SetFrameStrata("HIGH")
            overlay:SetFrameLevel(frameLevel + 25)
        end
        self:CreateOverlayTextures(overlay)
        button.gqUpgradeOverlay = overlay
        overlay.gqAnchor = anchor
    elseif overlay.gqAnchor ~= anchor then
        overlay.gqAnchor = anchor
    end

    self:ApplyOverlayLayout(overlay, anchor)
    overlay:Hide()
    return overlay
end

function GQ.Indicator:HideButton(button)
    if button and button.gqUpgradeOverlay then
        self:UnregisterOverlayPulse(button.gqUpgradeOverlay)
        button.gqUpgradeOverlay:Hide()
    end
end

function GQ.Indicator:UpdateButton(button, link)
    if not button then
        return
    end

    -- No upgrade arrows on profession windows (craft / trade skill): avoids
    -- link resolution and full cache rebuilds while browsing recipes.
    if IsProfessionListRow(button) or IsTradeSkillDetailIconHost(button) or IsCraftDetailIconHost(button) then
        self:HideButton(button)
        return
    end

    local itemId = GetItemIdFromLink(link)
    local overlay = self:EnsureOverlay(button)
    if not overlay then
        return
    end

    local isUpgrade = itemId and self:IsUpgradeItem(itemId)
    local isObtained = itemId and GQ.Log and GQ.Log.IsItemIdObtained and GQ.Log:IsItemIdObtained(itemId)

    if isUpgrade and not isObtained then
        overlay:Show()
        self:RegisterOverlayPulse(overlay)
    else
        self:UnregisterOverlayPulse(overlay)
        overlay:Hide()
    end
end

local REBUILD_DEBOUNCE = 0.35

function GQ.Indicator:ScheduleRebuildCache()
    if self._rebuildDebounce then
        return
    end
    self._rebuildDebounce = true
    local function fire()
        self._rebuildDebounce = false
        if self.RebuildCacheAsync then
            self:RebuildCacheAsync(function()
                self:RefreshAll()
            end)
        else
            self:RebuildCache()
            self:RefreshAll()
        end
    end
    if C_Timer and C_Timer.After then
        C_Timer.After(REBUILD_DEBOUNCE, fire)
    else
        fire()
    end
end

function GQ.Indicator:RebuildCache()
    self.upgradeItems = {}
    self.upgradeItemNames = {}
    self.itemNameCache = self.itemNameCache or {}

    if not GQ.Data or not GQ.Data.GetSlotsForClass then
        return
    end

    local classFile = GQ:GetEffectiveClass()
    if not classFile then
        return
    end

    for _, slotName in ipairs(GQ.Data:GetSlotsForClass(classFile)) do
        self:RebuildCacheForSlot(slotName)
    end
end

function GQ.Indicator:RebuildCacheForSlot(slotName)
    if not self.upgradeItems then
        self.upgradeItems = {}
    end
    if not self.upgradeItemNames then
        self.upgradeItemNames = {}
    end
    self.itemNameCache = self.itemNameCache or {}

    local maxUpgrades = GQ.Data.GetMaxUpgradesForSlot and GQ.Data:GetMaxUpgradesForSlot(slotName) or 3
    local upgrades
    if GQ.Log and GQ.Log.SourceFilterActive and GQ.Log:SourceFilterActive() and GQ.Log.GetFilteredTopForSlot then
        upgrades = GQ.Log:GetFilteredTopForSlot(slotName)
    else
        upgrades = GQ.Data:GetTopUpgradesForSlot(slotName, maxUpgrades)
    end
    for _, entry in ipairs(upgrades) do
        local hide = GQ.Log and GQ.Log.ShouldHideFromActiveList
            and GQ.Log:ShouldHideFromActiveList(entry, slotName)
        if entry.itemId and not hide then
            self.upgradeItems[entry.itemId] = true
            local itemName = (GQ.Data.GetItemDisplayName and GQ.Data:GetItemDisplayName(entry.itemId))
                or self.itemNameCache[entry.itemId]
            if itemName and GQ.Data.IsPlaceholderItemName and GQ.Data:IsPlaceholderItemName(itemName, entry.itemId) then
                itemName = nil
            end
            if itemName then
                self.itemNameCache[entry.itemId] = itemName
                self.upgradeItemNames[itemName:lower()] = entry.itemId
            elseif GQ.Data and GQ.Data.RequestItemInfo then
                GQ.Data:RequestItemInfo(entry.itemId)
            else
                GetItemInfo(entry.itemId)
            end
        end
    end
end

local REBUILD_SLOTS_PER_FRAME = 5

function GQ.Indicator:RebuildCacheAsync(onComplete)
    if not GQ.Data or not GQ.Data.GetSlotsForClass then
        if onComplete then
            onComplete()
        end
        return
    end

    local classFile = GQ:GetEffectiveClass()
    if not classFile then
        if onComplete then
            onComplete()
        end
        return
    end

    if self._rebuildCacheTimer and self._rebuildCacheTimer.Cancel then
        self._rebuildCacheTimer:Cancel()
        self._rebuildCacheTimer = nil
    end

    self.upgradeItems = {}
    self.upgradeItemNames = {}
    self.itemNameCache = self.itemNameCache or {}

    local slots = GQ.Data:GetSlotsForClass(classFile)
    local index = 1

    local function step()
        local last = math.min(index + REBUILD_SLOTS_PER_FRAME - 1, #slots)
        for i = index, last do
            self:RebuildCacheForSlot(slots[i])
        end
        index = last + 1

        if index <= #slots then
            if C_Timer and C_Timer.After then
                self._rebuildCacheTimer = C_Timer.After(0, step)
            else
                step()
            end
            return
        end

        self._rebuildCacheTimer = nil
        self:RefreshAll()
        if onComplete then
            onComplete()
        end
    end

    if C_Timer and C_Timer.After then
        self._rebuildCacheTimer = C_Timer.After(0, step)
    else
        step()
    end
end

function GQ.Indicator:IsUpgradeItem(itemId)
    return itemId and self.upgradeItems and self.upgradeItems[itemId] == true
end

function GQ.Indicator:CollectItemButtons(root, results, depth, seen)
    if not root or depth > 8 then
        return
    end

    seen = seen or {}
    if seen[root] then
        return
    end
    seen[root] = true

    if root.GetObjectType and root:GetObjectType() == "Button" and self:GetIconAnchor(root) then
        table.insert(results, root)
    end

    if root.GetChildren then
        local ok, children = pcall(root.GetChildren, root)
        if ok and children then
            for _, child in ipairs(children) do
                self:CollectItemButtons(child, results, depth + 1, seen)
            end
        end
    end

    if root.GetNumChildren then
        local ok, count = pcall(root.GetNumChildren, root)
        if ok and count then
            for i = 1, count do
                local okChild, child = pcall(root.GetChild, root, i)
                if okChild and child then
                    self:CollectItemButtons(child, results, depth + 1, seen)
                end
            end
        end
    end
end

function GQ.Indicator:GetQuestLogRewardButtons()
    local results = {}
    local seen = {}
    local roots = {
        _G.QuestLogQuestDetail,
        _G.QuestLogDetailScrollChildFrame,
        _G.QuestLogDetailScrollFrameScrollChild,
        QuestLogDetailScrollFrame and QuestLogDetailScrollFrame.ScrollChild,
    }

    for _, root in ipairs(roots) do
        if root then
            local rewardsFrame = root.rewardsFrame or root.RewardsFrame or _G.QuestLogQuestDetailRewardsFrame
            if rewardsFrame then
                if rewardsFrame.RewardFrames then
                    for _, frame in ipairs(rewardsFrame.RewardFrames) do
                        local btn = frame.Item or frame.item or frame
                        if btn and not seen[btn] then
                            seen[btn] = true
                            table.insert(results, btn)
                        end
                    end
                end

                for i = 1, 12 do
                    local btn = rewardsFrame["Item" .. i]
                    if btn and not seen[btn] then
                        seen[btn] = true
                        table.insert(results, btn)
                    end
                end

                self:CollectItemButtons(rewardsFrame, results, 0, seen)
            end
        end
    end

    return results
end

function GQ.Indicator:CollectQuestOfferButtons()
    local results = {}
    local seen = {}
    local function add(btn)
        if btn and not seen[btn] then
            seen[btn] = true
            table.insert(results, btn)
        end
    end

    local rewards = _G.QuestInfoRewardsFrame
        or (QuestInfoFrame and (QuestInfoFrame.rewardsFrame or QuestInfoFrame.RewardsFrame))
    if rewards then
        if rewards.RewardButtons then
            for _, btn in ipairs(rewards.RewardButtons) do
                add(btn)
            end
        end
        for i = 1, 12 do
            add(rewards["Item" .. i] or rewards["QuestInfoItem" .. i])
        end
    end

    for i = 1, 10 do
        add(_G["QuestInfoItem" .. i])
        add(_G["QuestRewardItem" .. i])
        add(_G["QuestProgressItem" .. i])
    end

    if #results == 0 and QuestFrame then
        self:CollectItemButtons(QuestFrame, results, 0, seen)
    end
    return results
end

function GQ.Indicator:UpdateQuestOfferRewards()
    if not QuestFrame or not QuestFrame:IsShown() then
        return
    end
    if not GetQuestItemLink then
        return
    end

    local buttons = self:CollectQuestOfferButtons()
    local buttonIndex = 1

    local function ApplyLinks(itemType, countFn)
        local count = countFn and countFn() or 0
        for i = 1, count do
            local link = GetQuestItemLink(itemType, i)
            local button = buttons[buttonIndex]
            if button and link then
                self:UpdateButton(button, link)
                buttonIndex = buttonIndex + 1
            elseif link then
                buttonIndex = buttonIndex + 1
            end
        end
    end

    ApplyLinks("choice", GetNumQuestChoices)
    ApplyLinks("reward", GetNumQuestRewards)

    for i = buttonIndex, #buttons do
        if buttons[i] then
            self:HideButton(buttons[i])
        end
    end
end

function GQ.Indicator:UpdateQuestLogRewards()
    if not QuestLogFrame or not QuestLogFrame:IsShown() then
        return
    end

    if not GetQuestLogSelection or not GetQuestLogItemLink then
        return
    end

    local questIndex = GetQuestLogSelection()
    if not questIndex or questIndex <= 0 then
        return
    end

    local buttons = self:GetQuestLogRewardButtons()
    local buttonIndex = 1

    local function ApplyLinks(itemType, countFn)
        local count = countFn and countFn(questIndex) or 0
        for i = 1, count do
            local link = GetQuestLogItemLink(itemType, i)
            local button = buttons[buttonIndex]
            if button then
                self:UpdateButton(button, link)
                buttonIndex = buttonIndex + 1
            end
        end
    end

    ApplyLinks("choice", GetNumQuestLogChoices)
    ApplyLinks("reward", GetNumQuestLogRewards)

    for i = buttonIndex, #buttons do
        self:HideButton(buttons[i])
    end
end

function GQ.Indicator:UpdateLootFrame()
    if not LootFrame or not LootFrame:IsShown() or not GetLootSlotLink then
        return
    end

    local numLootItems = LootFrame.numLootItems or 0
    local numLootToShow = LOOTFRAME_NUMBUTTONS or 4
    if numLootItems > numLootToShow then
        numLootToShow = numLootToShow - 1
    end

    local page = LootFrame.page or 1
    for i = 1, LOOTFRAME_NUMBUTTONS or 4 do
        local button = _G["LootButton" .. i]
        if button then
            if button:IsShown() then
                local slot = ((page - 1) * numLootToShow) + i
                if slot <= numLootItems and GetLootSlotLink then
                    self:UpdateButton(button, GetLootSlotLink(slot))
                else
                    self:HideButton(button)
                end
            else
                self:HideButton(button)
            end
        end
    end
end

function GQ.Indicator:UpdateGroupLootFrames()
    local maxFrames = NUM_GROUP_LOOT_FRAMES or 4
    for i = 1, maxFrames do
        local frame = _G["GroupLootFrame" .. i]
        if frame and frame:IsShown() and frame.rollID and GetLootRollItemLink then
            self:UpdateButton(frame, GetLootRollItemLink(frame.rollID))
        elseif frame then
            self:HideButton(frame)
        end
    end
end

function GQ.Indicator:UpdateTradeSkillFrame()
    if not TradeSkillFrame or not TradeSkillFrame:IsShown() then
        return
    end

    local displayed = TRADE_SKILLS_DISPLAYED or 8
    self:HideProfessionListRows(function(i)
        return _G["TradeSkillSkill" .. i]
    end, displayed)

    if TradeSkillFrame.ScrollBox and TradeSkillFrame.ScrollBox.ForEachFrame then
        TradeSkillFrame.ScrollBox:ForEachFrame(function(button)
            GQ.Indicator:HideButton(button)
        end)
    end

    self:UpdateTradeSkillDetailIcon()
end

function GQ.Indicator:IsMerchantBuybackTab()
    if not MerchantFrame then
        return false
    end

    if MerchantFrame.selectedTab == 2 then
        return true
    end

    local tab = _G.MerchantFrameTab2
    if tab and tab.IsEnabled and tab:IsEnabled() and tab.GetButtonState then
        return tab:GetButtonState() == "PUSHED"
    end

    return false
end

function GQ.Indicator:GetMerchantSlotIndex(slotOnPage)
    local itemsPerPage = MERCHANT_ITEMS_PER_PAGE or 10
    local page = (MerchantFrame and MerchantFrame.page) or 1
    return ((page - 1) * itemsPerPage) + slotOnPage
end

function GQ.Indicator:ResolveMerchantLink(index, itemButton)
    if itemButton and itemButton.link then
        return itemButton.link
    end

    if index and index > 0 and GetMerchantItemLink then
        local link = GetMerchantItemLink(index)
        if link then
            return link
        end
    end

    if index and index > 0 and GameTooltip and GameTooltip.SetMerchantItem then
        GameTooltip:SetOwner(UIParent, "ANCHOR_NONE")
        GameTooltip:SetMerchantItem(index)
        local _, link = GameTooltip:GetItem()
        GameTooltip:Hide()
        return link
    end

    return nil
end

function GQ.Indicator:UpdateMerchantFrame()
    if not MerchantFrame or not MerchantFrame:IsShown() then
        return
    end

    local itemsPerPage = MERCHANT_ITEMS_PER_PAGE or 10

    if self:IsMerchantBuybackTab() and GetBuybackItemLink then
        for i = 1, itemsPerPage do
            local itemButton = _G["MerchantItem" .. i .. "ItemButton"]
            if itemButton then
                if itemButton:IsShown() then
                    self:UpdateButton(itemButton, GetBuybackItemLink(i))
                else
                    self:HideButton(itemButton)
                end
            end
        end
        return
    end

    for i = 1, itemsPerPage do
        local itemButton = _G["MerchantItem" .. i .. "ItemButton"]
        if itemButton then
            if itemButton:IsShown() then
                local index = itemButton.GetID and itemButton:GetID()
                if not index or index <= 0 then
                    index = self:GetMerchantSlotIndex(i)
                end
                self:UpdateButton(itemButton, self:ResolveMerchantLink(index, itemButton))
            else
                self:HideButton(itemButton)
            end
        end
    end
end

function GQ.Indicator:UpdateCraftFrame()
    if not CraftFrame or not CraftFrame:IsShown() then
        return
    end

    local displayed = CRAFTS_DISPLAYED or 8
    self:HideProfessionListRows(function(i)
        return _G["Craft" .. i]
    end, displayed)

    local detailIcon = _G.CraftIcon or (CraftFrame and CraftFrame.DetailIcon)
    if detailIcon then
        self:HideButton(detailIcon)
    end
end

function GQ.Indicator:ScheduleProfessionRefresh()
    self:UpdateTradeSkillFrame()
    self:UpdateCraftFrame()
end

function GQ.Indicator:RefreshAll()
    self:UpdateLootFrame()
    self:UpdateGroupLootFrames()
    self:UpdateQuestLogRewards()
    self:UpdateQuestOfferRewards()
    self:UpdateTradeSkillFrame()
    self:UpdateCraftFrame()
    self:UpdateMerchantFrame()
end

function GQ.Indicator:EnsureTrainerHooks()
end

function GQ.Indicator:EnsureMerchantHooks()
    if self.merchantHooksReady then
        return
    end

    if type(MerchantFrame_Update) ~= "function" then
        return
    end

    self.merchantHooksReady = true

    self:HookFunction("MerchantFrame_Update", function()
        GQ.Indicator:UpdateMerchantFrame()
    end)

    if type(MerchantFrame_UpdateMerchantInfo) == "function" then
        self:HookFunction("MerchantFrame_UpdateMerchantInfo", function()
            GQ.Indicator:UpdateMerchantFrame()
        end)
    end
end

function GQ.Indicator:HookFunction(name, handler)
    if type(_G[name]) == "function" and not self.hooks[name] then
        self.hooks[name] = true
        hooksecurefunc(name, handler)
    end
end

function GQ.Indicator:Init()
    self.hooks = {}
    self.itemNameCache = {}

    self:RebuildCache()
    self:PrimeUpgradeItemInfo()

    self:HookFunction("LootFrame_Update", function()
        self:UpdateLootFrame()
    end)

    self:HookFunction("GroupLootFrame_OpenNewFrame", function()
        self:UpdateGroupLootFrames()
    end)

    self:HookFunction("QuestLog_UpdateQuestDetails", function()
        self:UpdateQuestLogRewards()
    end)

    self:HookFunction("QuestLog_Update", function()
        self:UpdateQuestLogRewards()
    end)

    self:HookFunction("QuestInfo_ShowRewards", function()
        self:UpdateQuestOfferRewards()
    end)

    self:HookFunction("QuestFrameItems_Update", function()
        self:UpdateQuestOfferRewards()
    end)

    self:HookFunction("QuestFrame_UpdatePortrait", function()
        self:UpdateQuestOfferRewards()
    end)

    self:HookFunction("TradeSkillFrame_Update", function()
        self:UpdateTradeSkillFrame()
    end)

    self:HookFunction("CraftFrame_Update", function()
        self:UpdateCraftFrame()
    end)

    self:HookFunction("TradeSkillFrame_SetSelection", function()
        self:ScheduleProfessionRefresh()
    end)

    self:HookFunction("CraftFrame_SetSelection", function()
        self:ScheduleProfessionRefresh()
    end)

    self:EnsureMerchantHooks()

    local eventFrame = CreateFrame("Frame")
    local events = {
        "ADDON_LOADED",
        "START_LOOT_ROLL",
        "LOOT_OPENED",
        "LOOT_CLOSED",
        "MERCHANT_SHOW",
        "MERCHANT_UPDATE",
        "TRADE_SKILL_SHOW",
        "TRADE_SKILL_UPDATE",
        "TRADE_SKILL_LIST_UPDATE",
        "TRADE_SKILL_DATA_SOURCE_CHANGED",
        "TRADE_SKILL_DETAILS_UPDATE",
        "CRAFT_SHOW",
        "CRAFT_UPDATE",
        "GET_ITEM_INFO_RECEIVED",
        "PLAYER_ENTERING_WORLD",
        "QUEST_DETAIL",
        "QUEST_PROGRESS",
        "QUEST_COMPLETE",
        "QUEST_FINISHED",
    }
    for i = 1, #events do
        GQ.RegisterEvent(eventFrame, events[i])
    end
    eventFrame:SetScript("OnEvent", function(_, event, arg1, arg2)
        if event == "ADDON_LOADED" and arg1 == "Blizzard_TradeSkillUI" then
            GQ.Indicator:HookFunction("TradeSkillFrame_Update", function()
                GQ.Indicator:UpdateTradeSkillFrame()
            end)
            GQ.Indicator:HookFunction("TradeSkillFrame_SetSelection", function()
                GQ.Indicator:ScheduleProfessionRefresh()
            end)
            return
        end

        if event == "MERCHANT_SHOW" then
            GQ.Indicator:EnsureMerchantHooks()
            GQ.Indicator:RebuildCache()
        end

        if event == "TRADE_SKILL_SHOW" or event == "TRADE_SKILL_UPDATE"
            or event == "TRADE_SKILL_LIST_UPDATE" or event == "TRADE_SKILL_DATA_SOURCE_CHANGED"
            or event == "TRADE_SKILL_DETAILS_UPDATE"
            or event == "CRAFT_SHOW" or event == "CRAFT_UPDATE"
        then
            if event == "TRADE_SKILL_SHOW" or event == "CRAFT_SHOW" then
                if GQ.Log and GQ.Log.ReleaseMouseForGameUI then
                    GQ.Log:ReleaseMouseForGameUI()
                end
                if GQ.Popup and GQ.Popup.dismissLayer and (not CharacterFrame or not CharacterFrame:IsShown()) then
                    GQ.Popup.dismissLayer:Hide()
                end
                if GQ.Tracker and GQ.Tracker.ClampRowMouse then
                    GQ.Tracker:ClampRowMouse()
                end
            end
            GQ.Indicator:ScheduleProfessionRefresh()
            return
        end

        if event == "PLAYER_ENTERING_WORLD" then
            GQ.Indicator:RebuildCache()
            GQ.Indicator:PrimeDataItemInfo()
            GQ.Indicator:PrimeUpgradeItemInfo()
            return
        end

        if event == "GET_ITEM_INFO_RECEIVED" then
            local itemId = arg1
            if itemId then
                GQ.Indicator.itemNameCache = GQ.Indicator.itemNameCache or {}
                local name = GQ.Data and GQ.Data.GetItemDisplayName and GQ.Data:GetItemDisplayName(itemId)
                if name then
                    GQ.Indicator.itemNameCache[itemId] = name
                end
            end
            return
        end

        GQ.Indicator:RefreshAll()

        if event == "QUEST_DETAIL" or event == "QUEST_PROGRESS" or event == "QUEST_COMPLETE" then
            if C_Timer and C_Timer.After then
                C_Timer.After(0, function()
                    if GQ.Indicator then
                        GQ.Indicator:UpdateQuestOfferRewards()
                    end
                end)
            end
        end

        if (event == "MERCHANT_SHOW" or event == "MERCHANT_UPDATE") and C_Timer and C_Timer.After then
            C_Timer.After(0, function()
                if GQ.Indicator then
                    GQ.Indicator:UpdateMerchantFrame()
                end
            end)
        end
    end)
end
