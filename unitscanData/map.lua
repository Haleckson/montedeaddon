local world_map_overlay = {}


function getCurrentMapId()
    local mapId = C_Map.GetBestMapForUnit("player")
    if mapId == nil then mapId = 1411 end
    return mapId
end

local UnitscanDataMainUI = _G["UnitscanDataMainUI"]

local map_container = CreateFrame("Frame", nil, UnitscanDataMainUI, nil)
map_container:SetPoint("BOTTOMLEFT", UnitscanDataMainUI, "BOTTOMRIGHT", 0, -40)
map_container:SetSize(350, 263)
map_container:Show()

local map_textures = {}
for i = 1, 12 do
	map_textures[i] = map_container:CreateTexture(nil, "OVERLAY")
	map_textures[i]:SetDrawLayer("OVERLAY", 2)
	map_textures[i]:SetVertexColor(1, 1, 1, 1)
end
map_textures[1]:SetPoint("TOPLEFT", map_container, "TOPLEFT", 0, 0)
map_textures[2]:SetPoint("LEFT", map_textures[1], "RIGHT", 0, 0)
map_textures[3]:SetPoint("LEFT", map_textures[2], "RIGHT", 0, 0)
map_textures[4]:SetPoint("LEFT", map_textures[3], "RIGHT", 0, 0)
map_textures[5]:SetPoint("TOP", map_textures[1], "BOTTOM", 0, 0)
map_textures[6]:SetPoint("LEFT", map_textures[5], "RIGHT", 0, 0)
map_textures[7]:SetPoint("LEFT", map_textures[6], "RIGHT", 0, 0)
map_textures[8]:SetPoint("LEFT", map_textures[7], "RIGHT", 0, 0)
map_textures[9]:SetPoint("TOP", map_textures[5], "BOTTOM", 0, 0)
map_textures[10]:SetPoint("LEFT", map_textures[9], "RIGHT", 0, 0)
map_textures[11]:SetPoint("LEFT", map_textures[10], "RIGHT", 0, 0)
map_textures[12]:SetPoint("LEFT", map_textures[11], "RIGHT", 0, 0)


local layers = C_Map.GetMapArtLayerTextures(getCurrentMapId(), 1)

for i = 1, 12 do
    map_textures[i]:SetHeight(map_container:GetWidth() / 4)
    map_textures[i]:SetWidth(map_container:GetWidth() / 4)
    map_textures[i]:SetTexture(layers[i])
    map_textures[i]:Hide()
end

map_container.tomb_tex = {}
for idx = 1, 100 do
    map_container.tomb_tex[idx] = map_container:CreateTexture(nil, "OVERLAY")
    map_container.tomb_tex[idx]:SetTexture("Interface\\TARGETINGFRAME\\UI-TargetingFrame-Skull")
    map_container.tomb_tex[idx]:SetDrawLayer("OVERLAY", 7)
    map_container.tomb_tex[idx]:SetHeight(15)
    map_container.tomb_tex[idx]:SetWidth(15)
    map_container.tomb_tex[idx]:Show()
end

local function getOverlayTextures(map_id)
    local textures = {}
    if overlay_info[map_id] == nil then
        return nil
    end
    for k, v in pairs(overlay_info[map_id]) do
        local textureWidth, textureHeight, offsetX, offsetY = string.split(":", k)
        local fileDataIDs = { string.split(",", v) }
        table.insert(textures, {
            ["fileDataIDs"] = fileDataIDs,
            ["textureWidth"] = textureWidth,
            ["textureHeight"] = textureHeight,
            ["offsetX"] = offsetX,
            ["offsetY"] = offsetY,
        })
    end
    return textures
end

function setMapTexture(textures)
    for i = 1, #world_map_overlay do
        world_map_overlay[i]:SetTexture(nil, nil, nil, nil)
    end
    if textures == nil then return end

    local textureCount = 0
    for k, v in ipairs(textures) do
        local numTexturesWide = ceil(v["textureWidth"] / 256)
        local numTexturesTall = ceil(v["textureHeight"] / 256)
        local neededTextures = textureCount +( numTexturesWide * numTexturesTall )


        if neededTextures > #world_map_overlay then
            for j = #world_map_overlay + 1, neededTextures do
                if world_map_overlay[j] == nill then
                    world_map_overlay[j] = map_container:CreateTexture(nil, "OVERLAY")
                end
            end
        end
        local texturePixelWidth, textureFileWidth, texturePixelHeight, textureFileHeight
        for j = 1, numTexturesTall do
            if j < numTexturesTall then
                texturePixelHeight = 256
                textureFileHeight = 256
            else
                texturePixelHeight = mod(v["textureHeight"], 256)
                if texturePixelHeight == 0 then
                    texturePixelHeight = 256
                end
                textureFileHeight = 16
                while textureFileHeight < texturePixelHeight do
                    textureFileHeight = textureFileHeight * 2
                end
            end

            for k = 1, numTexturesWide do
                textureCount = textureCount + 1
                local texture = world_map_overlay[textureCount]
                if k < numTexturesWide then
                    texturePixelWidth = 256
                    textureFileWidth = 256
                else
                    texturePixelWidth = mod(v["textureWidth"], 256)
                    if texturePixelWidth == 0 then
                        texturePixelWidth = 256
                    end
                    textureFileWidth = 16
                    while textureFileWidth < texturePixelWidth do
                        textureFileWidth = textureFileWidth * 2
                    end
                end
                texture:SetWidth(texturePixelWidth * map_container:GetWidth() / 1000)
                texture:SetHeight(texturePixelHeight * map_container:GetWidth() / 1000)
                texture:SetTexCoord(
                        0,
                        texturePixelWidth / textureFileWidth,
                        0,
                        texturePixelHeight / textureFileHeight
                )
                texture:SetPoint(
                        "TOPLEFT",
                        map_textures[1],
                        "TOPLEFT",
                        (v["offsetX"] + (256 * (k - 1))) * map_container:GetWidth() / 1000 - 5,
                        -(v["offsetY"] + (256 * (j - 1))) * map_container:GetWidth() / 1000 + 5
                )
                texture:SetTexture(v["fileDataIDs"][((j - 1) * numTexturesWide) + k], nil, nil, "TRILINEAR")
                texture:SetVertexColor(1, 1, 1)

                texture:SetDrawLayer("OVERLAY", 5)
                texture:Show()
            end
        end
    end
end

setMapTexture(getOverlayTextures(getCurrentMapId()))

function hideAllSkullMarks()
    for i=1,100 do
        map_container.tomb_tex[i]:Hide()
    end
end

function showSkulls(map_id, mob_id)
    if map_id == nil or mob_id == nil then
        hideAllSkullMarks()
        return nil
    end
    local my_region = mobs_location[map_id]
    if my_region == nil then
        hideAllSkullMarks()
        return nil
    end
    local my_skulls = my_region[mob_id]
    if my_skulls == nil then
        hideAllSkullMarks()
        return nil
    end

    local idx = 1
    local modified_width = map_container:GetWidth() * 0.98
    local modified_height = map_container:GetHeight() * 0.87
    for _, v in ipairs(my_skulls) do
        if idx > 100 then
            break
        end

        map_container.tomb_tex[idx]:SetVertexColor(1, 1, 1, 1)
        map_container.tomb_tex[idx]:SetPoint(
            "CENTER",
            map_container,
            "TOPLEFT",
            modified_width * v[1] / 100.0,
            -modified_height * v[2] / 100.0
        )
        map_container.tomb_tex[idx]:Show()
        map_container.tomb_tex[idx]:SetVertexColor(1, 1, 1, 1)
        idx = idx + 1
    end
    if idx < 100 then
        for i=idx,100 do
            map_container.tomb_tex[i]:Hide()
        end
    end
end

for index=1,75 do
    local MyCheckButton = _G["MyCheckButton" .. index]
    MyCheckButton:HookScript("OnEnter", function()
        if MyCheckButton:IsShown() then
            local activeGrid = getActiveGrid()
            if activeGrid[index].active == false then return end
            showSkulls(getCurrentMapId(), activeGrid[index].id)
            map_container:Show()
        end
    end)
end
UnitscanDataMainUI:HookScript("OnHide", function() map_container:Hide() end)

map_container:RegisterEvent("ZONE_CHANGED_NEW_AREA");
local function onAddonMapEvent(self, event, arg1, ...)
    if event == "ZONE_CHANGED" or event == "ZONE_CHANGED_INDOORS" or event == "ZONE_CHANGED_NEW_AREA" then
        setMapTexture(getOverlayTextures(getCurrentMapId()));
        showSkulls(nil, nil);
 	end
end
map_container:SetScript("OnEvent", onAddonMapEvent);