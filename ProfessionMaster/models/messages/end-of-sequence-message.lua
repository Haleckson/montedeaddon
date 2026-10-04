--[[

@author Kurki
@copyright ©2026 Profession Master. All Rights Reserved.

--]]

-- create model
local EndOfSequenceMessage = _G.professionMaster:CreateModel("end-of-sequence-message");
EndOfSequenceMessage.prefix = "X";

--- Create message model.
-- @param sequenceType Type of sequence that completed ("DO" = DigestOffer, "DR" = DataRequest, "PP" = PlayerProfessions).
function EndOfSequenceMessage:Create(sequenceType)
    local message = {
        sequenceType = sequenceType
    };
    setmetatable(message, EndOfSequenceMessage);
    return message;
end

--- Parse message from string.
function EndOfSequenceMessage:Parse(value)
    local message = {
        sequenceType = value
    };
    setmetatable(message, EndOfSequenceMessage);
    return message;
end

--- Convert message to string.
function EndOfSequenceMessage:ToString()
    return self.sequenceType;
end
