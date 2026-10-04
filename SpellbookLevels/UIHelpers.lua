SBL_UIHelpers = {}
local function MakePanel(name, w, h, titleText)
    local f
    local ok, r = pcall(CreateFrame, "Frame", name, UIParent, "BasicFrameTemplateWithInset")
    if ok and r then
        f = r
    else
        f = CreateFrame("Frame", name, UIParent, "BackdropTemplate")
        if f.SetBackdrop then
            f:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
            f:SetBackdropColor(0.08, 0.08, 0.1, 0.95)
            f:SetBackdropBorderColor(0.6, 0.5, 0.2, 1)
        end
        local okc, close = pcall(CreateFrame, "Button", nil, f, "UIPanelCloseButton")
        if okc and close then close:SetPoint("TOPRIGHT", 2, 2) end
    end
    f:SetSize(w, h)
    local t = f.TitleText or (f.TitleContainer and f.TitleContainer.TitleText)
    if not t then
        t = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        t:SetPoint("TOP", 0, -8)
    end
    t:SetText(titleText)
    f.__title = t
    return f
end

local function MakeScroll(name, parent)
    local ok, s = pcall(CreateFrame, "ScrollFrame", name, parent, "UIPanelScrollFrameTemplate")
    if not (ok and s) then
        s = CreateFrame("ScrollFrame", nil, parent)
        s:EnableMouseWheel(true)
        s:SetScript("OnMouseWheel", function(self, d)
            local cur, max = self:GetVerticalScroll(), self:GetVerticalScrollRange()
            self:SetVerticalScroll(math.max(0, math.min(max, cur - d * 36)))
        end)
    end
    return s
end


SBL_UIHelpers.MakePanel = MakePanel
SBL_UIHelpers.MakeScroll = MakeScroll
