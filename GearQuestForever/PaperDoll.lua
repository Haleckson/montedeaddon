local _, GQ = ...

GQ.PaperDoll = GQ.PaperDoll or {}

function GQ.PaperDoll:Init()
    if self.initialized then
        return
    end
    self.initialized = true

    local slots = GQ.Data and GQ.Data.PAPER_DOLL_SLOTS
    if not slots then
        return
    end

    for _, slotName in ipairs(slots) do
        local button = _G["Character" .. slotName .. "Slot"]
        if button and not button.GearQuestHooked then
            button.GearQuestHooked = true
            button:HookScript("OnClick", function(self, mouseButton)
                if mouseButton == "RightButton" and CharacterFrame and CharacterFrame:IsShown() then
                    local gq = _G.GearQuest
                    if gq and gq.Popup then
                        gq.Popup:ShowForSlot(slotName, self)
                    end
                end
            end)
        end
    end
end
