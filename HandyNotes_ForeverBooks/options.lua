local _, ns = ...

ns.defaults = {
    world = true, minimap = true, continents = true,
    scale = 1.5, alpha = 1, uncertain = true, factionOnly = false,
    autoCollect = true, hideCollected = false,
}

function ns.MakeOptions()
    local collection = {}
    for id, book in pairs(ns.books) do
        local bookID = id
        collection[id] = {
            type = "toggle", name = book.title, width = "full",
            get = function() return ns.IsCollected(bookID) end,
            set = function(_, value) ns.SetCollected(bookID, value) end,
        }
    end
    local function toggle(name, order)
        return { type = "toggle", name = name, order = order }
    end
    return {
        type = "group", name = "Forever Books",
        get = function(info) return ns.db[info[#info]] end,
        set = function(info, value)
            ns.db[info[#info]] = value
            if info[#info] == "autoCollect" and value then ns.ScanBags() end
            ns.Refresh()
        end,
        args = {
            description = { type = "description", order = 0,
                name = "40 Buchtitel aus dem WoWHead-Guide. Zugangspins und unbestätigte Fundorte sind im Tooltip gekennzeichnet. Fraktionsangaben stammen aus SoD." },
            world = toggle("Auf der Weltkarte anzeigen", 1),
            minimap = toggle("Auf der Minimap anzeigen", 2),
            continents = toggle("Auch auf Kontinentkarten anzeigen", 3),
            uncertain = toggle("Unbestätigten SoD-Phasenfundort anzeigen", 4),
            factionOnly = toggle("Andere SoD-Fraktion ausblenden", 5),
            scale = { type = "range", name = "Symbolgröße", min = 0.5, max = 3, step = 0.1, order = 6 },
            alpha = { type = "range", name = "Deckkraft", min = 0.2, max = 1, step = 0.05, order = 7 },
            autoCollect = toggle("Bücher in den Taschen automatisch abhaken", 8),
            hideCollected = toggle("Gefundene Bücher ausblenden", 9),
            collection = { type = "group", name = "Sammelliste (dieser Charakter)", order = 10, args = collection },
        },
    }
end
