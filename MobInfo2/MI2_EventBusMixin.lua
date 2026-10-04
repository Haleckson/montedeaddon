local _, MI2 = ...
local MI2_EventBusMixin = {}

function MI2_EventBusMixin:Init()
  self.registeredListeners = {}
  self.sources = {}
end

function MI2_EventBusMixin:Register(listener, eventNames)
  if listener.ReceiveEvent == nil then
    error("Attempted to register an invalid listener! ReceiveEvent method must be defined.")
    return self
  end

  for _, eventName in ipairs(eventNames) do
    if self.registeredListeners[eventName] == nil then
      self.registeredListeners[eventName] = {}
    end

    table.insert(self.registeredListeners[eventName], listener)
  end

  return self
end

-- Assumes events have been registered exactly once
function MI2_EventBusMixin:Unregister(listener, eventNames)
  for _, eventName in ipairs(eventNames) do
    local index = tIndexOf(self.registeredListeners[eventName], listener)
    if index ~= nil then
      table.remove(self.registeredListeners[eventName], index)
    end
  end

  return self
end

function MI2_EventBusMixin:IsSourceRegistered(source)
  return self.sources[source] ~= nil
end

function MI2_EventBusMixin:RegisterSource(source, name)
  self.sources[source] = name

  return self
end

function MI2_EventBusMixin:UnregisterSource(source)
  self.sources[source] = nil

  return self
end

function MI2_EventBusMixin:Fire(source, eventName, ...)
  if self.sources[source] == nil then
    error("All sources must be registered (" .. eventName .. ")")
  end

  if self.registeredListeners[eventName] ~= nil then
    for index, listener in ipairs(self.registeredListeners[eventName]) do
      listener:ReceiveEvent(eventName, ...)
    end
  end

  return self
end

MI2.EventBus = CreateAndInitFromMixin(MI2_EventBusMixin)
