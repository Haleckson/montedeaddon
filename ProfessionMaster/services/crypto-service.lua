--[[

@author Kurki
@copyright ©2026 Profession Master. All Rights Reserved.

--]]

-- create service
local CryptoService = _G.professionMaster:CreateService("crypto");

-- base64 encoding alphabet
local base64Chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

--- Initialize crypto service.
function CryptoService:Initialize()
end

--- Encode a string to base64.
function CryptoService:EncodeBase64(input)
    -- handle empty input
    if (not input or #input == 0) then
        return "";
    end

    local result = {};
    local length = #input;

    -- process 3 bytes at a time
    for i = 1, length, 3 do
        local byte1 = string.byte(input, i);
        local byte2 = (i + 1 <= length) and string.byte(input, i + 1) or 0;
        local byte3 = (i + 2 <= length) and string.byte(input, i + 2) or 0;

        -- combine into 24-bit number
        local combined = bit.lshift(byte1, 16) + bit.lshift(byte2, 8) + byte3;

        -- extract 4 base64 characters
        local index1 = bit.band(bit.rshift(combined, 18), 63) + 1;
        local index2 = bit.band(bit.rshift(combined, 12), 63) + 1;
        local index3 = bit.band(bit.rshift(combined, 6), 63) + 1;
        local index4 = bit.band(combined, 63) + 1;

        table.insert(result, string.sub(base64Chars, index1, index1));
        table.insert(result, string.sub(base64Chars, index2, index2));

        -- add padding if needed
        if (i + 1 <= length) then
            table.insert(result, string.sub(base64Chars, index3, index3));
        else
            table.insert(result, "=");
        end

        if (i + 2 <= length) then
            table.insert(result, string.sub(base64Chars, index4, index4));
        else
            table.insert(result, "=");
        end
    end

    return table.concat(result);
end
