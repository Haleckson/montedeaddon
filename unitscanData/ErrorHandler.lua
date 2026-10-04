local OriginalErrorHandler = geterrorhandler()
seterrorhandler(function(message)
    if message:find("unitscan") and message:find("ADDON_ACTION_FORBIDDEN") then
        return
    end
    OriginalErrorHandler(message)
end)
