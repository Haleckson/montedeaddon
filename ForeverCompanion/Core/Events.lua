--[[
  Forever Companion - Core/Events.lua
  Two dispatchers:

  FC.Events - WoW game events. One frame for the whole addon. Registration is
              protected because this client throws on unknown event names.
              Events are only registered while at least one listener wants them.

  FC.Bus    - internal messages between layers (data -> UI, data -> sync).
              Emitters never know who listens, which keeps the layers apart.
]]

local _, FC = ...

local Events = { listeners = {}, unsupported = {} }
FC.Events = Events

local frame = CreateFrame("Frame")

local function dispatch(event, ...)
    local list = Events.listeners[event]
    if not list then return end
    for owner, handler in pairs(list) do
        FC:SafeCall(event, handler, owner, event, ...)
    end
end

frame:SetScript("OnEvent", function(_, event, ...)
    dispatch(event, ...)
end)

--- Registers handler(owner, event, ...) for a game event. Returns false if the
--- client does not know the event.
function Events:Register(event, owner, handler)
    if self.unsupported[event] then return false end
    local list = self.listeners[event]
    if not list then
        local ok, err = pcall(frame.RegisterEvent, frame, event)
        if not ok then
            self.unsupported[event] = true
            FC.Log:Debug("Event %s is not available on this client (%s)", event, tostring(err))
            return false
        end
        list = {}
        self.listeners[event] = list
    end
    list[owner] = handler
    return true
end

function Events:Unregister(event, owner)
    local list = self.listeners[event]
    if not list then return end
    list[owner] = nil
    if next(list) == nil then
        self.listeners[event] = nil
        pcall(frame.UnregisterEvent, frame, event)
    end
end

function Events:UnregisterAll(owner)
    for event in pairs(self.listeners) do
        self:Unregister(event, owner)
    end
end

function Events:IsSupported(event)
    return not self.unsupported[event]
end

------------------------------------------------------------------------
-- Internal message bus
------------------------------------------------------------------------

local Bus = { handlers = {} }
FC.Bus = Bus

function Bus:On(message, owner, handler)
    local list = self.handlers[message]
    if not list then
        list = {}
        self.handlers[message] = list
    end
    list[owner] = handler
end

function Bus:Off(message, owner)
    local list = self.handlers[message]
    if list then list[owner] = nil end
end

function Bus:Emit(message, ...)
    local list = self.handlers[message]
    if not list then return end
    FC.Log:Trace("bus %s", message)
    for owner, handler in pairs(list) do
        FC:SafeCall(message, handler, owner, ...)
    end
end
