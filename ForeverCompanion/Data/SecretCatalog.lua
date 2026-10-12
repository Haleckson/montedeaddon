-- Reviewed hidden activities present in the bundled Classic/Forever reference.
-- IDs identify an activity; words in titles, being outdoors and ordinary loot
-- never qualify. This is a classification index, not undiscovered map pins.
local _, FC = ...
local Catalog = { entries = {}, objects = {}, quests = {}, items = {} }
FC.SecretCatalog = Catalog

-- Documents, clues and collectibles can have a loot window too. They are
-- not opened chests. Keep container rewards (e.g. Cortello's chest) separate.
Catalog.nonContainers = {
    [34]=true, [36]=true, [142189]=true,
    [2553]=true, [2554]=true, [2555]=true, [13359]=true,
    [161505]=true, [175926]=true, [386759]=true, [408014]=true, [409562]=true,
    [406918]=true, [415106]=true, [415107]=true, [417072]=true,
    [424005]=true, [424006]=true, [424007]=true, [424010]=true, [424012]=true,
    [562131]=true,
    -- Ordinary quest props from Reference/World.lua, not containers.
    [2560]=true, [2842]=true, [2848]=true, [2858]=true, [124371]=true,
    [131474]=true, [141931]=true, [142088]=true, [142345]=true, [142475]=true,
    [142476]=true, [142696]=true, [144064]=true, [148832]=true,
    [152620]=true, [152621]=true, [152622]=true, [164820]=true, [165554]=true,
    [175385]=true, [176116]=true, [176142]=true, [176143]=true, [176213]=true,
    [177964]=true, [178609]=true, [179547]=true, [180327]=true, [180368]=true,
    [180456]=true, [180461]=true, [180466]=true, [180666]=true, [180667]=true,
    [180794]=true, [181287]=true,
}

Catalog.containers = {
    [33]=true, [35]=true, [2556]=true, [3239]=true, [3642]=true,
    [3714]=true, [19595]=true, [103815]=true, [105176]=true, [105570]=true,
    [113757]=true, [121264]=true, [123214]=true, [123329]=true, [123330]=true,
    [129127]=true, [141979]=true, [142184]=true,
    [160836]=true, [160845]=true, [161495]=true, [161504]=true, [175382]=true,
    [175924]=true, [178244]=true, [179486]=true, [179487]=true, [179488]=true,
    [179490]=true, [179491]=true, [179492]=true, [179493]=true, [179494]=true,
    [179496]=true, [179497]=true, [179498]=true, [179499]=true, [179501]=true,
    [179564]=true, [179697]=true, [180690]=true, [180691]=true, [181085]=true,
}
for id in pairs(FC.ReferenceData.reviewedContainers or {}) do Catalog.containers[id] = true end

local function add(key, objects, quests, items, sources)
    local entry = { key=key, objects=objects, quests=quests, items=items, sources=sources }
    Catalog.entries[#Catalog.entries+1] = entry
    for _,id in ipairs(objects) do Catalog.objects[id] = entry end
    for _,id in ipairs(quests) do Catalog.quests[id] = entry end
    for _,id in ipairs(items) do Catalog.items[id] = entry end
end

add("sanders", {33,34,35,36}, {136,138,139,140}, {}, {
    "https://www.wowhead.com/classic/quest=136/captain-sanders-hidden-treasure",
})
add("cortello", {2553,2554,2555,2556}, {624,625,626}, {}, {
    "https://www.wowhead.com/classic/quest=624/cortellos-riddle",
    "https://warcraft.wiki.gg/wiki/Cortello%27s_Riddle_quest_chain",
})
add("cuergo", {142189}, {2882}, {}, {
    "https://www.wowhead.com/classic/quest=2882/cuergos-gold",
})
add("linken", {161504,161505}, {3844}, {}, {
    "https://www.wowhead.com/classic/quest=3844/its-a-secret-to-everybody",
})
add("dalson", {175924,175925,175926}, {5058,5059,5060}, {}, {
    "https://www.wowhead.com/classic/quest=5058/mrs-dalsons-diary",
})
-- Seeing a normal chicken is not discovering the hidden emote quest.
add("cluck", {}, {3861}, {}, {
    "https://www.wowhead.com/forever/quest=3861/cluck",
})
add("ghost-saber", {13359}, {}, {}, {
    "https://www.wowhead.com/forever/object=13359/cat-figurine",
})
add("secret-safe", {161495}, {}, {}, {
    "https://www.wowhead.com/classic/object=161495/secret-safe",
    "https://warcraft.wiki.gg/wiki/Secret_Safe",
})
add("sleeping-bag", {406918,415106,415107,417072,424005,424006,424007,424010,424012},
    {79007,79008,79192,79974,79975,79976,79980}, {211527}, {
    "https://www.wowhead.com/forever/guide/cozy-sleeping-bag-locations-rewards",
    "https://www.warcrafttavern.com/forever/guides/cozy-sleeping-bag/",
})
add("library", {386759,408014,409562},
    {78124,78127,78142,78143,78145,78146,78147,78148,78149,78150,
     79091,79092,79093,79094,79095,79096,79097,79536,82208},
    {203755,208860,209845}, {
    "https://www.wowhead.com/forever/quest=78150/friend-of-the-library",
    "https://wowforevertools.com/books",
})
add("applejack", {562131}, {91736}, {}, {
    "https://www.wowhead.com/forever/quest=91736/applejack-still",
    "https://www.wowhead.com/forever/object=562131/applejack-still",
})
add("musical-gustjumper", {}, {}, {268109}, {
    "https://www.wowhead.com/forever/item=268109/musical-gustjumper",
})
add("excitable-slime", {}, {97583}, {275682}, {
    "https://www.wowhead.com/forever/quest=97583/wriggle",
    "https://www.wowhead.com/forever/news/earn-two-new-pets-in-capital-cities-in-wow-forever-383170",
})
add("keystone", {}, {}, {281350,281358}, {
    "https://www.wowhead.com/forever/item=281350/keystone-fragment",
    "https://www.wowhead.com/forever/item=281358/stone-key",
    "https://www.warcrafttavern.com/forever/news/secret-finders-are-investigating-a-keystone-fragment-in-wow-forever",
})

function Catalog:ObjectID(rec)
    if not rec or (rec.t ~= "object" and rec.t ~= "secret" and rec.t ~= "treasure") then return nil end
    local id = type(rec.id) == "string" and rec.id or ""
    return tonumber(id:match("^u:go:(%d+):") or id:match("^u:obj:(%d+):") or id:match("^u:read:(%d+):"))
end

function Catalog:Entry(rec)
    if not rec or rec.del then return nil end
    if rec.t == "quest" and rec.q then return self.quests[rec.q] end
    if rec.t == "item" and rec.it then return self.items[rec.it] end
    local objectID = self:ObjectID(rec)
    return objectID and self.objects[objectID] or nil
end

function Catalog:Contains(rec) return self:Entry(rec) ~= nil end

function Catalog:SourceText(entry)
    return entry and table.concat(entry.sources, "\n\n") or ""
end
