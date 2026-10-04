-- LibItemDB-1.0 — item VALUE: the price ladder, its store, and its settings (MINOR 25)
--
-- Everything else in this library answers "what IS this item". This file answers "what is it
-- WORTH" — and it stops there. It never answers "what do we charge for it": guild discounts,
-- officer overrides, donation rates and rank tiers are a consumer's policy and none of them
-- belong here. The library reports the market; the consumer decides what to do with it.
--
-- MOVED HERE FROM TOGProfessionMaster (Modules/Price.lua) on 2026-09-14, at the operator's
-- direction: TOGPM carried the only AH scanner in the fleet plus a duplicate of the third-party
-- adapters this library already published in Integrations.lua, and TOGBankClassic needed the same
-- capability for its storefront. One copy, here, consumed by both. TOGPM's crafting-cost maths
-- (CraftCost / GetReagentCost) stay in TOGPM — they are policy, not market.
--
-- THE SHAPE, and every part of it is a requirement TOGBankClassic wrote down (their
-- docs/LIBRARY_CONTRACTS.md §7, LIBREQ-PRICE-001..008):
--
--   * Keyed by itemID, never by name or link. Same-name variants exist.
--   * Copper, as an integer. `nil` means NO DATA and is never confused with a zero — an unpriced
--     item that silently prices at 0 is given away for free.
--   * A NAMED STATISTIC on request. Minimum buyout, market value and historical are different
--     numbers, and one consumer legitimately wants two of them for the same item (a conservative
--     figure for valuing a donation, a different one for the sell side). The library does not
--     pick one on the consumer's behalf. `"best"` reproduces the old TOGPM ladder for a caller
--     that genuinely wants "whatever you have".
--   * PROVENANCE on every answer: which source, which statistic, how old. An estimate whose age
--     is unknown is worse than none — it looks authoritative and is not.
--   * A bulk form, because a banker resolves every distinct item in the bank at once.
--   * SCOPING, stated: the scan store is per REALM + FACTION (Vanilla and TBC factions have
--     separate auction houses); settings are per ACCOUNT. Third-party sources scope themselves.
--   * Standalone only, in its own SavedVariables (`LibItemDB_PriceDB`, declared in every TOC).
--     Derived per-item statistics are stored, never raw auction rows.
--
-- SOURCES, in default precedence (user-reorderable): Auctionator, Auctioneer, TradeSkillMaster,
-- then this library's own scan (Price/Scanner.lua). Every third-party source is OFF by default and
-- feature-detected at CALL time — never a hard dependency, never raises, never reads a provider's
-- data into our own tables. The same three rules Integrations.lua enforces, for the same reasons.
-- A FED source (MINOR 26, LIBREQ-PRICE-011) — a price list a consumer hands us, such as a guild's
-- published one — joins the ladder ahead of them by default; see the "Fed sources" section.
--
-- STATE ACROSS THE THREE PRICE FILES is reached through the underscore methods at the bottom
-- (`_PriceStore`, `_PriceSettings`, `_PriceFire`, `_PricePrint`). They are internal: a consumer
-- reads the public API above them, and nothing outside this addon should call an underscore.

local MAJOR = "LibItemDB-1.0"
local lib = LibStub and LibStub(MAJOR, true)
if not lib then return end

-- Identifies us to Auctionator, which requires a non-empty caller string and raises without one.
local CALLER_ID = "LibItemDB"

-- The SavedVariables global, declared as `## SavedVariables: LibItemDB_PriceDB` in every TOC.
local SV_NAME = "LibItemDB_PriceDB"

-- Auctionator's own price-history window, used for its "historical" statistic (a mean of daily
-- lows over this many days) so the number matches what Auctionator itself would show.
local HISTORY_DAYS = 14

-- ---------------------------------------------------------------------------
-- Callbacks
-- ---------------------------------------------------------------------------
-- CallbackHandler-1.0 ships with Ace3, a hard dependency of every TOC. `lib.RegisterCallback` /
-- `lib.UnregisterCallback` are installed on the library by `CBH:New`, so a consumer subscribes with
--   DB.RegisterCallback(myAddon, "LibItemDB_ScanComplete", function(event, kind, reason) ... end)
-- Events fired by the price files:
--   LibItemDB_ScanComplete   (kind, reason, results)   kind = "full" | "targeted"
--   LibItemDB_ScanProgress   (kind, scanned, total, item)
--   LibItemDB_AuctionHouse   (isOpen)
--   LibItemDB_PriceSettingsChanged (key, value)   key = a settings key, "order", or "external"
--                                                   (value = the fed source id: stored, cleared
--                                                   or toggled)
local CBH = LibStub("CallbackHandler-1.0", true)
if CBH and not lib.callbacks then lib.callbacks = CBH:New(lib) end

local function fire(event, ...)
    if lib.callbacks then lib.callbacks:Fire(event, ...) end
end

-- ---------------------------------------------------------------------------
-- Settings (per ACCOUNT) — defaults exactly as TOGPM shipped them
-- ---------------------------------------------------------------------------
-- `useOwnScan` was TOGPM's `useTOGPMAH`; `autoScan` its `autoScanAH`; `scanDelay` its
-- `ahScanDelay` (0 = this client's default: 1.5s on Classic Era, 3.0s elsewhere — resolved at scan
-- time in Price/Scanner.lua). The three parent toggles keep their names and their OFF default;
-- each parent's sub-toggle defaults ON so enabling a source gets its whole ladder.
--
-- Two departures from TOGPM, both from the operator on 2026-09-14 after the first in-game pass:
--   * `useTSMAppHelper` defaults ON. The TSM Desktop App's REGION figures are the one complete,
--     always-current picture of the auction house; the realm figures go stale the moment the app
--     stops publishing a realm (Old Blanchy's were 664 days old) and the own scan is piecemeal.
--   * `defaultStatistic` is "best", not "minBuyout". A minimum buyout is a LISTING statistic —
--     only Auctionator, the realm half of TSM and the own scan carry one — so a caller that names
--     nothing was skipping Auctioneer entirely and every region figure TSM had. "best" walks each
--     source's own preference (see BEST_ORDER and the per-source `best` lists) and lands on the
--     same minimum buyout when that is all a source has.
local DEFAULTS = {
    useOwnScan               = true,
    autoScan                 = false,
    scanDelay                = 0,
    useAuctionator           = false,
    useAuctionatorHistorical = true,
    useAuctioneer            = false,
    useAuctioneerCached      = true,
    useTSM                   = false,
    useTSMAppHelper          = true,
    defaultStatistic         = "best",
}
local BOOLEAN_KEYS = {
    useOwnScan = true, autoScan = true,
    useAuctionator = true, useAuctionatorHistorical = true,
    useAuctioneer = true, useAuctioneerCached = true,
    useTSM = true, useTSMAppHelper = true,
}
local DEFAULT_ORDER = { "auctionator", "auctioneer", "tsm", "scan" }
local SCAN_DELAY_MIN, SCAN_DELAY_MAX = 0.5, 10

-- ---------------------------------------------------------------------------
-- Storage
-- ---------------------------------------------------------------------------
-- Everything lives in one SavedVariables table:
--   settings = { <DEFAULTS keys>, order = { sourceID, ... },
--                external = { [sourceID] = { name = display, enabled = bool } } }   -- fed-source registry
--   realms   = { ["<Realm> - <Faction>"] = { ah = { [itemID] = { p = copper, at = epoch, n = listings } },
--                                            vendor = { [itemID] = copper },
--                                            external = { [sourceID] = { items, stats, at, storedAt } },
--                                            lastScanAt = epoch, lastScanCount = n } }
--   window   = { width, height, top, left }   -- the configuration window's saved geometry
--
-- SavedVariables do not exist until ADDON_LOADED fires for this addon. Anything written before
-- that (a consumer pricing an item during its own load) goes into a pending table, which is
-- PROMOTED to the global on ADDON_LOADED when the client handed us nothing — so an early write
-- survives — and discarded when the client did hand us a saved table, which is the truth.
local pending

local function now()
    return (GetServerTime and GetServerTime()) or time()
end

local function copyList(t)
    local out = {}
    for i, v in ipairs(t) do out[i] = v end
    return out
end

-- Keep only known source ids, in the order given, then append any built-in id the list omitted in
-- default order. A saved order from an older build therefore gains a new source at the bottom
-- rather than losing it, and a typo can never make a source unreachable. A fed source (one the
-- account's registry knows) the list omits goes to the FRONT instead — that is its default
-- position, see the "Fed sources" section.
local KNOWN_SOURCE = {}
for _, id in ipairs(DEFAULT_ORDER) do KNOWN_SOURCE[id] = true end

local function normaliseOrder(list, external)
    local out, seen = {}, {}
    if type(list) == "table" then
        for _, id in ipairs(list) do
            if (KNOWN_SOURCE[id] or external[id]) and not seen[id] then
                seen[id] = true
                out[#out + 1] = id
            end
        end
    end
    local front = {}
    for id in pairs(external) do
        if not seen[id] then front[#front + 1] = id end
    end
    table.sort(front)
    for i = #front, 1, -1 do table.insert(out, 1, front[i]) end
    for _, id in ipairs(DEFAULT_ORDER) do
        if not seen[id] then out[#out + 1] = id end
    end
    return out
end

-- The settings-table stamp. `ensure` materialises every default into the saved table, so a
-- default that CHANGES cannot tell a value the user chose from one it wrote itself. Version 1 is
-- the 2026-09-14 pre-release cut-over (defaultStatistic minBuyout -> best, useTSMAppHelper
-- off -> on): a table with no stamp was written by the build before it, and those two values are
-- reset to the new defaults once. Bump this only with another such migration.
local SETTINGS_VERSION = 1

local function ensure(db)
    db.settings = db.settings or {}
    db.realms   = db.realms   or {}
    db.window   = db.window   or {}
    local s = db.settings
    if (tonumber(s.version) or 0) < 1 then
        s.defaultStatistic = DEFAULTS.defaultStatistic
        s.useTSMAppHelper  = DEFAULTS.useTSMAppHelper
    end
    s.version = SETTINGS_VERSION
    for k, v in pairs(DEFAULTS) do
        if s[k] == nil then s[k] = v end
    end
    if type(s.external) ~= "table" then s.external = {} end
    s.order = normaliseOrder(s.order, s.external)
    return db
end

local function priceDB()
    local sv = _G[SV_NAME]
    if type(sv) == "table" then return ensure(sv) end
    pending = pending or {}
    return ensure(pending)
end

local function settings() return priceDB().settings end

-- Realm + faction, the scope every scanned or captured price is stored under. Vanilla and TBC
-- keep separate auction houses per faction, so a Horde scan must never answer an Alliance lookup.
local function scopeKey()
    local realm   = (GetRealmName and GetRealmName()) or "Unknown"
    local faction = (UnitFactionGroup and UnitFactionGroup("player")) or "Neutral"
    return realm .. " - " .. faction
end

local function store()
    local db  = priceDB()
    local key = scopeKey()
    local s   = db.realms[key]
    if not s then
        s = {}
        db.realms[key] = s
    end
    s.ah       = s.ah       or {}
    s.vendor   = s.vendor   or {}
    s.external = s.external or {}
    return s
end

--- The scope key the scan store is keyed under — "<Realm> - <Faction>". Exposed so a consumer can
--- say WHICH realm's data an estimate came from, and so the scoping is a fact rather than a promise.
function lib:GetPriceScope() return scopeKey() end

-- ---------------------------------------------------------------------------
-- Statistics
-- ---------------------------------------------------------------------------
local STATISTICS = {
    { id = "minBuyout",  label = "Minimum buyout" },
    { id = "market",     label = "Market value" },
    { id = "historical", label = "Historical" },
}
local STAT_LABEL = {}
for _, s in ipairs(STATISTICS) do STAT_LABEL[s.id] = s.label end
-- What "best" tries within a source, in order, unless the source declares its own `best` list.
-- This IS TOGPM's old ladder: the live number beats the derived one beats the historical one, and
-- only then does the next source get a turn. `best` is a ladder, not a statistic — it is never
-- reported as one. TradeSkillMaster overrides it (market first) because its market figure is the
-- region-wide App Helper average and its minimum buyout is realm-only — see the TSM section.
local BEST_ORDER = { "minBuyout", "market", "historical" }

--- The statistics a consumer can ask for, in display order: `{ { id, label }, ... }`.
--- `"best"` is accepted by the lookups too, and means "walk every source's statistics in order";
--- it is not listed here because an answer is never labelled `best` — provenance names the real one.
function lib:GetPriceStatistics()
    local out = {}
    for i, s in ipairs(STATISTICS) do out[i] = { id = s.id, label = s.label } end
    return out
end

--- Display label for a statistic id; the id itself for one this build does not know.
function lib:GetPriceStatisticLabel(id)
    return STAT_LABEL[id] or (id == "best" and "Best available") or tostring(id)
end

-- ---------------------------------------------------------------------------
-- Adapter helpers
-- ---------------------------------------------------------------------------
-- A third-party price is accepted only as a positive number, rounded to whole copper. Zero,
-- negative, a string, an error — all become nil, so nothing a provider returns can escape as a
-- price it did not mean.
local function positive(ok, v)
    if ok and type(v) == "number" and v > 0 then return math.floor(v + 0.5) end
    return nil
end

local function firstNumeric(...)
    for i = 1, select("#", ...) do
        local v = select(i, ...)
        if type(v) == "number" and v > 0 then return math.floor(v + 0.5) end
    end
    return nil
end

local function getItemInfo(itemID)
    local fn = (C_Item and C_Item.GetItemInfo) or _G.GetItemInfo
    if type(fn) ~= "function" then return nil end
    return fn(itemID)
end

-- ---------------------------------------------------------------------------
-- Auctionator
-- ---------------------------------------------------------------------------
-- A properly versioned public API (Source/API/v1/*). Every entry point takes a callerID first and
-- RAISES on a bad argument, so all of this is wrapped. `GetAuctionPriceByItemID` is Auctionator's
-- own headline number — the lowest unit price it last saw — which is this library's `minBuyout`.
-- `GetAuctionAgeByItemID` answers in DAYS (nil past 21, nil when never seen), so the age carried
-- here is day-granular; that is what the provider knows, and it is reported rather than invented.
local function auctionatorAPI()
    local A  = _G.Auctionator
    local v1 = A and A.API and A.API.v1
    if type(v1) == "table" then return v1 end
    return nil
end

local function auctionatorAge(itemID)
    local v1 = auctionatorAPI()
    if not v1 or type(v1.GetAuctionAgeByItemID) ~= "function" then return nil end
    local ok, days = pcall(v1.GetAuctionAgeByItemID, CALLER_ID, itemID)
    if ok and type(days) == "number" and days >= 0 then return days * 86400 end
    return nil
end

local function auctionatorMinBuyout(itemID)
    local v1 = auctionatorAPI()
    if not v1 or type(v1.GetAuctionPriceByItemID) ~= "function" then return nil end
    local p = positive(pcall(v1.GetAuctionPriceByItemID, CALLER_ID, itemID))
    if not p then return nil end
    return p, auctionatorAge(itemID)
end

-- Auctionator has no historical entry point in API v1 (TOGPM's adapter reached for a
-- `GetHistoricalPriceByItemID` that does not exist and silently fell back to the live price). What
-- it does have is `Auctionator.Database:GetMeanPrice(dbKey, days)` — a public mixin method, not a
-- versioned API, so it is feature-detected AND wrapped, and a future v1 function of the expected
-- name is preferred if one ever appears. Gated by `useAuctionatorHistorical`.
local function auctionatorHistorical(itemID)
    if not settings().useAuctionatorHistorical then return nil end
    local v1 = auctionatorAPI()
    if not v1 then return nil end
    if type(v1.GetHistoricalPriceByItemID) == "function" then
        local p = positive(pcall(v1.GetHistoricalPriceByItemID, CALLER_ID, itemID))
        if p then return p, auctionatorAge(itemID) end
    end
    local db = _G.Auctionator.Database
    if type(db) ~= "table" or type(db.GetMeanPrice) ~= "function" then return nil end
    local p = positive(pcall(db.GetMeanPrice, db, tostring(itemID), HISTORY_DAYS))
    if not p then return nil end
    return p, auctionatorAge(itemID)
end

local function auctionatorVendor(itemID)
    local v1 = auctionatorAPI()
    if not v1 or type(v1.GetVendorPriceByItemID) ~= "function" then return nil end
    return positive(pcall(v1.GetVendorPriceByItemID, CALLER_ID, itemID))
end

-- ---------------------------------------------------------------------------
-- Auctioneer (Auc-Advanced)
-- ---------------------------------------------------------------------------
-- Auctioneer's call shapes differ by branch and plugin set, so each probe tries the known
-- signatures in turn and takes the first positive number. The item is offered as the real link
-- when the client has it cached, then as the canonical 8-field item string, then the bare one —
-- BUILT BY APPENDING, because the real link is nil for an uncached item and a literal table with a
-- nil first element stops `ipairs` before the synthetic forms that exist precisely for that case.
local function auctioneerAPI()
    local AA = _G.AucAdvanced
    if type(AA) == "table" and type(AA.API) == "table" then return AA end
    return nil
end

local function auctioneerLinks(itemID)
    local links = {}
    local link = select(2, getItemInfo(itemID))
    if type(link) == "string" and link ~= "" then links[#links + 1] = link end
    links[#links + 1] = ("item:%d:0:0:0:0:0:0:0"):format(itemID)
    links[#links + 1] = ("item:%d"):format(itemID)
    return links
end

local function auctioneerMarket(itemID)
    local AA = auctioneerAPI()
    local fn = AA and AA.API.GetMarketValue
    if type(fn) ~= "function" then return nil end
    local serverKey = AA.Resources and AA.Resources.ServerKey
    for _, link in ipairs(auctioneerLinks(itemID)) do
        local ok, r1, r2, r3 = pcall(fn, link, serverKey, 0.5)
        local p = ok and firstNumeric(r1, r2, r3)
        if not p then
            ok, r1, r2, r3 = pcall(fn, link, serverKey)
            p = ok and firstNumeric(r1, r2, r3)
        end
        if not p then
            ok, r1, r2, r3 = pcall(fn, link)
            p = ok and firstNumeric(r1, r2, r3)
        end
        if p then return p end
    end
    return nil
end

local AUCTIONEER_ENGINES = {
    "stat_simple", "stat_histogram", "stat_stddev", "stat_iLevel",
    "Simple", "Histogram", "StdDev", "iLevel",
    "stat:simple", "stat:histogram", "stat:stddev", "stat:ilevel",
}

-- The cached stat-engine value: Auctioneer's "historical". Gated by `useAuctioneerCached`.
local function auctioneerCached(itemID)
    if not settings().useAuctioneerCached then return nil end
    local AA = auctioneerAPI()
    if not AA then return nil end
    local serverKey = AA.Resources and AA.Resources.ServerKey
    local links = auctioneerLinks(itemID)

    local fn = AA.API.GetAlgorithmValue
    if type(fn) == "function" then
        for _, link in ipairs(links) do
            for _, engine in ipairs(AUCTIONEER_ENGINES) do
                local ok, r1, r2, r3 = pcall(fn, engine, link, serverKey)
                local p = ok and firstNumeric(r1, r2, r3)
                if not p then
                    ok, r1, r2, r3 = pcall(fn, link, engine, serverKey)
                    p = ok and firstNumeric(r1, r2, r3)
                end
                if not p then
                    ok, r1, r2, r3 = pcall(fn, engine, link)
                    p = ok and firstNumeric(r1, r2, r3)
                end
                if not p then
                    ok, r1, r2, r3 = pcall(fn, link, engine)
                    p = ok and firstNumeric(r1, r2, r3)
                end
                if p then return p end
            end
        end
    end

    -- Some builds expose cached data only through their Stat modules. Prefer the module with the
    -- most observations behind its number.
    if type(AA.GetAllModules) == "function" then
        local okMods, modules = pcall(AA.GetAllModules, nil, "Stat")
        if okMods and type(modules) == "table" then
            local bestPrice, bestSeen
            for _, link in ipairs(links) do
                for _, mod in ipairs(modules) do
                    if type(mod) == "table" and type(mod.GetPriceArray) == "function" then
                        local okArr, arr = pcall(mod.GetPriceArray, link, serverKey)
                        if okArr and type(arr) == "table" then
                            local p = firstNumeric(arr.price, arr.minBuyout, arr.mean, arr[1])
                            if p then
                                local seen = tonumber(arr.seen or arr.auctionsCount or arr.dayCount or 0) or 0
                                if not bestPrice or seen > bestSeen then bestPrice, bestSeen = p, seen end
                            end
                        end
                    end
                end
            end
            if bestPrice then return bestPrice end
        end
    end
    return nil
end

-- ---------------------------------------------------------------------------
-- TradeSkillMaster
-- ---------------------------------------------------------------------------
-- TSM_API.GetCustomPriceValue(expression, itemString) — every TSM_API function validates by
-- RAISING, and the argument order has differed between builds, so both orders and both item-string
-- spellings are tried.
--
-- TSM holds TWO pictures of the auction house, and the REGION one comes first (the operator,
-- 2026-09-14: "use tsm app helper to populate the TSM regional data, that is correct ALL THE TIME
-- FULL AH data -- not piecemeal data from the AH we're getting now"):
--
--   * REGION — `DBRegion*`. Every realm in the region, aggregated by the TSM Desktop App and handed
--     to the addon through TradeSkillMaster_AppHelper (`AUCTIONDB_REGION_STAT` / `_HISTORICAL` /
--     `_SALE`). Complete and refreshed by the app; the number a machine WITH the app should trust.
--   * REALM — `DBMinBuyout` / `DBMarket` / `DBRecent` / `DBHistorical`. This realm's own listings
--     (`AUCTIONDB_NON_COMMODITY_*`), only as fresh as the app's last publish for THIS realm — a
--     realm the app has stopped covering keeps serving its last snapshot with no age on it (Old
--     Blanchy's was 664 days old, found in the first in-game pass).
--
-- Read through TSM_API rather than by capturing TSM_APPHELPER_LOAD_DATA ourselves: TSM already
-- resolves which region dataset this client belongs to (Classic / HC / SoD / Fresh × US / EU),
-- decodes the app's base-32 packing, and the App Helper addon cannot even load without TSM
-- (`## Dependency: TradeSkillMaster`), so there is nothing to gain by going underneath it and a
-- load-order trap in doing so. `useTSMAppHelper` (default ON) gates the region half; with it off
-- TSM answers from realm figures alone. There is no region minimum buyout — a minimum buyout is a
-- listing, not an aggregate — so `minBuyout` is realm-only and TSM's `best` prefers `market`.
local TSM_EXPRESSIONS = {
    minBuyout  = { realm = { "DBMinBuyout" } },
    market     = { region = { "DBRegionMarketAvg" },                   realm = { "DBMarket", "DBRecent" } },
    historical = { region = { "DBRegionHistorical", "DBRegionSaleAvg" }, realm = { "DBHistorical" } },
}
local TSM_BEST_ORDER = { "market", "minBuyout", "historical" }

local function tsmAPI()
    local API = _G.TSM_API
    if type(API) == "table" and type(API.GetCustomPriceValue) == "function" then return API end
    return nil
end

local function tsmValue(API, itemID, expr)
    for _, itemString in ipairs({ "i:" .. itemID, "item:" .. itemID }) do
        local p = positive(pcall(API.GetCustomPriceValue, expr, itemString))
        if p then return p end
        p = positive(pcall(API.GetCustomPriceValue, itemString, expr))
        if p then return p end
    end
    return nil
end

local function tsmFirst(API, itemID, exprs)
    for _, expr in ipairs(exprs or {}) do
        local p = tsmValue(API, itemID, expr)
        if p then return p end
    end
    return nil
end

local function tsmStatistic(statistic)
    local exprs = TSM_EXPRESSIONS[statistic]
    return function(itemID)
        local API = tsmAPI()
        if not API then return nil end
        if settings().useTSMAppHelper then
            local p = tsmFirst(API, itemID, exprs.region)
            if p then return p end
        end
        return tsmFirst(API, itemID, exprs.realm)
    end
end

-- ---------------------------------------------------------------------------
-- This library's own scan (Price/Scanner.lua writes; this reads)
-- ---------------------------------------------------------------------------
local function scanMinBuyout(itemID)
    local entry = store().ah[itemID]
    if not entry or type(entry.p) ~= "number" or entry.p <= 0 then return nil end
    return entry.p, now() - (entry.at or 0)
end

local function scanInfo()
    local s = store()
    local n = 0
    for _ in pairs(s.ah) do n = n + 1 end
    return s.lastScanAt and (now() - s.lastScanAt) or nil, n
end

-- ---------------------------------------------------------------------------
-- Fed sources (MINOR 26 — TOGBankClassic's LIBREQ-PRICE-011)
-- ---------------------------------------------------------------------------
-- A consumer hands the library a price list observed somewhere this client cannot see, and it
-- rides the ladder like any other source: a row in the window, a toggle, a precedence, named
-- statistics, provenance with an age. The case it was built for: TOGBankClassic publishes ONE
-- officer's price list to the guild so every banker values a donation at the same figure — a
-- banker without TSM would otherwise price a donated stack at their own scan or the vendor floor,
-- the officer's client would say something else, and the donation ledger is permanent. The
-- library still reports the market, not a policy: this is a named, aged, scoped market figure
-- that happened to be observed on someone else's client.
--
-- Two tables, deliberately split:
--   * the REGISTRY (settings.external, per ACCOUNT) — every fed source id this account has been
--     given, its display name and its on/off toggle. It outlives a Clear, so the toggle and the
--     precedence the user chose are still there when the same id is fed again.
--   * the DATA (realms[scope].external[id], per REALM + FACTION like the own scan) — the entries,
--     which statistics any of them carries, and the newest `at`. A fed source is "detected" when
--     the CURRENT scope holds data for it: a list fed on one realm never answers on another.
--
-- Default precedence FIRST the first time a source is fed: a guild list exists precisely to
-- override the client's own view. User-reorderable after that. (TOGBank never feeds on the
-- authority's own client — its sources ARE the list — so a fed copy ranked first cannot make the
-- next build read yesterday's figures back as today's.)
local function externalRegistry() return settings().external end

-- The scope's table for a fed source, or nil when it holds nothing — including a saved table
-- that is not the shape this build writes, which is ignored like a corrupt scan entry is.
local function externalHeld(id)
    local held = store().external[id]
    if type(held) == "table" and type(held.items) == "table" and type(held.stats) == "table"
        and type(held.at) == "number" and next(held.items) ~= nil then
        return held
    end
    return nil
end

local function externalStatistic(id, statistic)
    return function(itemID)
        local held = externalHeld(id)
        local e = held and held.items[itemID]
        local p = e and e[statistic]
        if type(p) ~= "number" or p <= 0 then return nil end
        return p, now() - (e.at or held.at)
    end
end

-- A registry entry as a source descriptor of the same shape as the built-ins below. Resolved per
-- call, like detection is: which statistics it offers depends on what the current scope holds.
local function externalSource(id)
    local reg = externalRegistry()[id]
    if type(reg) ~= "table" then return nil end
    local held  = externalHeld(id)
    local stats = {}
    if held then
        for statistic in pairs(held.stats) do stats[statistic] = externalStatistic(id, statistic) end
    end
    return {
        name     = reg.name or id,
        external = true,
        detect   = function() return externalHeld(id) ~= nil end,
        enabled  = function() return externalRegistry()[id].enabled ~= false end,
        stats    = stats,
        info     = function()
            local h = externalHeld(id)
            if not h then return nil, 0 end
            local n = 0
            for _ in pairs(h.items) do n = n + 1 end
            return now() - h.at, n
        end,
    }
end

-- ---------------------------------------------------------------------------
-- The registry
-- ---------------------------------------------------------------------------
-- `detect` — is the provider actually present on this machine right now (resolved per call: these
--            addons can load after this library).
-- `enabled` — has the user opted in. Every third party defaults OFF; the own scan defaults ON.
-- `toggle` — the settings key `enabled` reads, for SetPriceSourceEnabled. A fed source has none;
--            its toggle lives in the registry.
-- `stats`  — statistic id -> function(itemID) -> copper, ageSeconds|nil.
-- `best`   — optional: the order "best" tries this source's statistics in; BEST_ORDER otherwise.
-- `info`   — optional: function() -> ageSeconds|nil, itemCount, for sources whose data the library
--            holds itself and can therefore date and count.
local SOURCES = {
    auctionator = {
        name    = "Auctionator",
        detect  = function() return auctionatorAPI() ~= nil end,
        enabled = function() return settings().useAuctionator == true end,
        toggle  = "useAuctionator",
        stats   = { minBuyout = auctionatorMinBuyout, historical = auctionatorHistorical },
    },
    auctioneer = {
        name    = "Auctioneer",
        detect  = function() return auctioneerAPI() ~= nil end,
        enabled = function() return settings().useAuctioneer == true end,
        toggle  = "useAuctioneer",
        stats   = { market = auctioneerMarket, historical = auctioneerCached },
    },
    tsm = {
        name    = "TradeSkillMaster",
        detect  = function() return tsmAPI() ~= nil end,
        enabled = function() return settings().useTSM == true end,
        toggle  = "useTSM",
        stats   = {
            minBuyout  = tsmStatistic("minBuyout"),
            market     = tsmStatistic("market"),
            historical = tsmStatistic("historical"),
        },
        best    = TSM_BEST_ORDER,
    },
    scan = {
        name    = "ItemDB scan",
        detect  = function() return true end,
        enabled = function() return settings().useOwnScan == true end,
        toggle  = "useOwnScan",
        stats   = { minBuyout = scanMinBuyout },
        info    = scanInfo,
    },
}

local function sourceFor(id)
    return SOURCES[id] or externalSource(id)
end

-- The sources that can answer right now, in the user's precedence. Resolved ONCE per lookup (and
-- once per BULK lookup), which is the whole point of the bulk form: the detection pcalls are the
-- expensive part, not the arithmetic.
local function activeSources()
    local out = {}
    for _, id in ipairs(settings().order) do
        local src = sourceFor(id)
        if src then
            local okDetect, present = pcall(src.detect)
            if okDetect and present and src.enabled() then
                out[#out + 1] = { id = id, src = src }
            end
        end
    end
    return out
end

local function try(entry, statistic, itemID)
    local fn = entry.src.stats[statistic]
    if not fn then return nil end
    local ok, price, age = pcall(fn, itemID)
    if not ok or type(price) ~= "number" or price <= 0 then return nil end
    local info = {
        source     = entry.id,
        sourceName = entry.src.name,
        statistic  = statistic,
        age        = age,
        at         = age and (now() - age) or nil,
    }
    return price, info
end

local function lookup(active, itemID, statistic)
    if statistic == "best" then
        for _, entry in ipairs(active) do
            for _, stat in ipairs(entry.src.best or BEST_ORDER) do
                local price, info = try(entry, stat, itemID)
                if price then return price, info end
            end
        end
        return nil
    end
    if not STAT_LABEL[statistic] then return nil end
    for _, entry in ipairs(active) do
        local price, info = try(entry, statistic, itemID)
        if price then return price, info end
    end
    return nil
end

-- ---------------------------------------------------------------------------
-- Public lookups
-- ---------------------------------------------------------------------------
--- What an item is worth, in copper, from the first enabled source that knows it.
---
--- @param itemID number the item id. A link or a name is NOT accepted and answers nil.
--- @param statistic string|nil "minBuyout" | "market" | "historical" | "best"; nil = the
---        account's default statistic (settings `defaultStatistic`, "best" out of the box).
---        A named statistic is answered ONLY by sources that carry that statistic — asking for
---        "market" never quietly hands back a minimum buyout. "best" walks each source's
---        statistics in that source's own preference (minBuyout, market, historical for most;
---        TradeSkillMaster tries market first, because that is its region-wide App Helper figure)
---        before moving to the next source.
--- @return number|nil copper nil when NO enabled source has data — never 0 for "no data".
--- @return table|nil provenance `{ source, sourceName, statistic, age, at }`. `age` is seconds since
---         the figure was observed, `at` the matching epoch; both nil when the provider does not
---         say (Auctioneer, TSM). Auctionator reports whole days. The own scan is exact.
function lib:GetPrice(itemID, statistic)
    if type(itemID) ~= "number" then return nil end
    return lookup(activeSources(), itemID, statistic or settings().defaultStatistic)
end

--- Many items in one call, with the source list resolved once rather than per item.
---
--- @param itemIDs table an ARRAY of item ids, or a SET `{ [itemID] = anything }` — a table with
---        no array part is read by its keys, which is the shape a bank inventory naturally has.
--- @param statistic string|nil as GetPrice.
--- @return table results `{ [itemID] = { value = copper, source, sourceName, statistic, age, at } }`
---         — only items that priced are present; look an id up and test for nil. Always a table.
--- @return number count how many of the ids priced.
function lib:GetPrices(itemIDs, statistic)
    local out, n = {}, 0
    if type(itemIDs) ~= "table" then return out, 0 end
    local active = activeSources()
    local stat   = statistic or settings().defaultStatistic
    local function resolve(id)
        if type(id) == "number" and out[id] == nil then
            local price, info = lookup(active, id, stat)
            if price then
                info.value = price
                out[id] = info
                n = n + 1
            end
        end
    end
    if #itemIDs > 0 then
        for _, id in ipairs(itemIDs) do resolve(id) end
    else
        for id in pairs(itemIDs) do resolve(id) end
    end
    return out, n
end

--- Every known source, in the user's precedence, with what it can do right now.
--- @return table sources array of `{ id, name, detected, enabled, precedence, statistics,
---         external, age, count }`, where `statistics` lists the statistic ids the source can
---         answer. `detected` is whether the provider is present on this machine (for a fed
---         source: whether this realm + faction holds its data); `enabled` whether the user
---         turned it on. Both must hold for the source to take part in a lookup. `external` is
---         true for a fed source. `age` (seconds) and `count` are set only for sources whose data
---         the library holds itself — the own scan (its last full scan, its priced items) and a
---         fed source (its newest entry, its entries); a third party does not say, so both are nil.
function lib:GetPriceSources()
    local out = {}
    for i, id in ipairs(settings().order) do
        local src = sourceFor(id)
        local okDetect, present = pcall(src.detect)
        local stats = {}
        for _, s in ipairs(STATISTICS) do
            if src.stats[s.id] then stats[#stats + 1] = s.id end
        end
        local age, count
        if src.info then age, count = src.info() end
        out[#out + 1] = {
            id         = id,
            name       = src.name,
            detected   = (okDetect and present) and true or false,
            enabled    = src.enabled(),
            precedence = i,
            statistics = stats,
            external   = src.external == true,
            age        = age,
            count      = count,
        }
    end
    return out
end

--- Whether one source is switched on — the same answer `GetPriceSources` gives for it, for a
--- caller (the window's row toggle) that has one id in hand. `false` for an unknown id.
function lib:IsPriceSourceEnabled(id)
    local src = sourceFor(id)
    return src ~= nil and src.enabled() == true
end

--- Switch one source on or off by id, whichever kind it is: a built-in routes to its settings key
--- (so `LibItemDB_PriceSettingsChanged` carries that key, and a parent's fallback still goes off
--- with it); a fed source flips its registry toggle and fires `("external", sourceID)`.
--- @return boolean ok
--- @return string|nil reason when the id names no source
function lib:SetPriceSourceEnabled(id, on)
    local src = sourceFor(id)
    if not src then return false, "unknown source: " .. tostring(id) end
    if src.toggle then return self:SetPriceSetting(src.toggle, on) end
    externalRegistry()[id].enabled = on and true or false
    fire("LibItemDB_PriceSettingsChanged", "external", id)
    return true
end

--- Whether ANY enabled source could answer a lookup on this machine — the difference between
--- "this item has no price" and "you have no price data at all", which need different messages.
--- The own scan counts only once it holds at least one price for this realm and faction.
function lib:HasPriceData()
    for _, entry in ipairs(activeSources()) do
        if entry.id ~= "scan" then return true end
        if next(store().ah) ~= nil then return true end
    end
    return false
end

--- What a VENDOR CHARGES for an item, in copper, best source first:
---   1. Auctionator's vendor cache (when Auctionator is enabled and present),
---   2. a price this account actually saw at a merchant (captured on MERCHANT_SHOW, which is the
---      only source that knows the player's reputation discount),
---   3. the shipped BASE (Neutral) price, `GetVendorBasePrice`.
--- The order is the correctness argument: 3 is a worse estimate than 2 for anyone above Neutral,
--- so it stays last. Distinct from GetPrice on purpose — a vendor price is a fact in its own
--- right, not a fallback for a missing auction price.
--- @return number|nil copper
--- @return table|nil provenance `{ source = "auctionator-vendor" | "merchant" | "vendor-static" }`
function lib:GetVendorBuyPrice(itemID)
    if type(itemID) ~= "number" then return nil end
    if settings().useAuctionator == true then
        local p = auctionatorVendor(itemID)
        if p then return p, { source = "auctionator-vendor", sourceName = "Auctionator" } end
    end
    local captured = store().vendor[itemID]
    if type(captured) == "number" and captured > 0 then
        return captured, { source = "merchant", sourceName = "Merchant" }
    end
    local base = self:GetVendorBasePrice(itemID)
    if type(base) == "number" and base > 0 then
        return base, { source = "vendor-static", sourceName = "ItemDB" }
    end
    return nil
end

--- Copper as a coin string, with a plain-text fallback where the client cannot draw coins.
function lib:FormatMoney(copper)
    if type(copper) ~= "number" then return "" end
    if GetCoinTextureString then return GetCoinTextureString(copper) end
    local g = math.floor(copper / 10000)
    local s = math.floor((copper % 10000) / 100)
    local c = math.floor(copper % 100)
    return ("%dg %ds %dc"):format(g, s, c)
end

-- ---------------------------------------------------------------------------
-- Writers
-- ---------------------------------------------------------------------------
--- Record a scanned per-UNIT buyout for an item under this realm + faction. Called by the scanner;
--- public so another scanner (PersonalShopper's targeted one) can feed the same store. Refuses
--- junk rather than storing it: a non-number, a zero or a negative is ignored.
--- @param count number|nil how many listings the figure was taken from (kept, not required)
function lib:StoreScannedPrice(itemID, copper, count)
    if type(itemID) ~= "number" or type(copper) ~= "number" or copper <= 0 then return false end
    store().ah[itemID] = { p = math.floor(copper + 0.5), at = now(), n = tonumber(count) }
    return true
end

--- Record a vendor price this account actually saw (per single item, not per stack).
function lib:StoreVendorPrice(itemID, copper)
    if type(itemID) ~= "number" or type(copper) ~= "number" or copper <= 0 then return false end
    store().vendor[itemID] = math.floor(copper + 0.5)
    return true
end

--- Feed the ladder a price list from outside this client (MINOR 26). REPLACES that source's whole
--- table for the current realm + faction — a feed is the list, not a delta — and it survives a
--- reload in `LibItemDB_PriceDB` beside the own scan.
--- @param sourceID string a short id of the consumer's choosing ("guildpricelist"); not one of the
---        built-in ids. The first feed of a new id puts it FIRST in the precedence.
--- @param sourceName string|nil display text ("guild list (Pimptasty)"); kept from the last feed
---        that gave one, the id itself until then.
--- @param entries table `{ [itemID] = { minBuyout = copper|nil, market = copper|nil,
---        historical = copper|nil, at = epoch|nil } }`. Each statistic is kept only as a positive
---        number, rounded to whole copper — a non-number, a zero or a negative is dropped exactly as
---        StoreScannedPrice drops it — and an entry with no statistic left is not stored. `at` is
---        when the figure was observed; an entry without one is dated by the newest `at` in the
---        list, or by this call when no entry carries one.
--- @return number|nil count entries stored; nil (with a reason) when the arguments are refused
--- @return string|nil reason
function lib:StoreExternalPrices(sourceID, sourceName, entries)
    if type(sourceID) ~= "string" or sourceID == "" or KNOWN_SOURCE[sourceID] then
        return nil, "sourceID must be a non-empty string that is not a built-in source id"
    end
    if type(entries) ~= "table" then return nil, "entries must be a table keyed by itemID" end
    local items, stats, newest, count = {}, {}, nil, 0
    for key, entry in pairs(entries) do
        local itemID = tonumber(key)
        if itemID and type(entry) == "table" then
            local kept
            for _, s in ipairs(STATISTICS) do
                local v = entry[s.id]
                if type(v) == "number" and v > 0 then
                    kept = kept or {}
                    kept[s.id] = math.floor(v + 0.5)
                    stats[s.id] = true
                end
            end
            if kept then
                local at = tonumber(entry.at)
                if at and at > 0 then
                    kept.at = math.floor(at)
                    if not newest or kept.at > newest then newest = kept.at end
                end
                items[itemID] = kept
                count = count + 1
            end
        end
    end
    local reg = externalRegistry()
    if not reg[sourceID] then
        reg[sourceID] = { enabled = true }
        table.insert(settings().order, 1, sourceID)
    end
    if type(sourceName) == "string" and sourceName ~= "" then reg[sourceID].name = sourceName end
    store().external[sourceID] = { items = items, stats = stats, at = newest or now(), storedAt = now() }
    fire("LibItemDB_PriceSettingsChanged", "external", sourceID)
    return count
end

--- Drop a fed source's data for the current realm + faction. Its registry entry — the toggle and
--- the precedence the user chose — is kept, so the row stays in the window as "not detected" and
--- the next feed of the same id lands where the user put it.
--- @return boolean held whether anything was held for this scope
function lib:ClearExternalPrices(sourceID)
    if type(sourceID) ~= "string" then return false end
    local ext = store().external
    local had = ext[sourceID] ~= nil
    ext[sourceID] = nil
    if had then fire("LibItemDB_PriceSettingsChanged", "external", sourceID) end
    return had
end

--- Number of items with a scanned price for this realm + faction.
function lib:GetScannedItemCount()
    return (select(2, scanInfo()))
end

--- When the last full scan finished for this realm + faction, and how many items it priced.
--- @return number|nil epoch  nil when no scan has ever completed here
--- @return number|nil count
function lib:GetLastScan()
    local s = store()
    return s.lastScanAt, s.lastScanCount
end

-- ---------------------------------------------------------------------------
-- Settings API
-- ---------------------------------------------------------------------------
--- Read one setting. Keys: useOwnScan, autoScan, scanDelay, useAuctionator,
--- useAuctionatorHistorical, useAuctioneer, useAuctioneerCached, useTSM, useTSMAppHelper,
--- defaultStatistic. (Precedence is read with GetPriceSourceOrder.)
function lib:GetPriceSetting(key)
    if key == "order" then return self:GetPriceSourceOrder() end
    return settings()[key]
end

--- Write one setting, validated. Booleans are coerced; `scanDelay` is 0 (this client's default)
--- or clamped to 0.5–10 seconds; `defaultStatistic` must name a statistic (or "best").
--- Fires LibItemDB_PriceSettingsChanged(key, value) on success.
--- @return boolean ok
--- @return string|nil reason when refused
function lib:SetPriceSetting(key, value)
    local s = settings()
    if BOOLEAN_KEYS[key] then
        s[key] = value and true or false
        -- A parent toggle going off takes its sub-toggle with it, as TOGPM's settings did, so the
        -- window never shows a live-looking fallback under a dead source.
        if key == "useAuctionator" and not s[key] then s.useAuctionatorHistorical = false end
        if key == "useAuctioneer"  and not s[key] then s.useAuctioneerCached      = false end
        -- `useTSMAppHelper` is deliberately NOT cascaded: it is TSM's PRIMARY half, not a fallback,
        -- and a source toggled off and on again must come back reading the region figures.
    elseif key == "scanDelay" then
        local n = tonumber(value)
        if not n then return false, "scanDelay must be a number of seconds" end
        if n <= 0 then n = 0
        elseif n < SCAN_DELAY_MIN then n = SCAN_DELAY_MIN
        elseif n > SCAN_DELAY_MAX then n = SCAN_DELAY_MAX end
        s.scanDelay = n
    elseif key == "defaultStatistic" then
        if value ~= "best" and not STAT_LABEL[value] then
            return false, "unknown statistic: " .. tostring(value)
        end
        s.defaultStatistic = value
    elseif key == "order" then
        return self:SetPriceSourceOrder(value)
    else
        return false, "unknown setting: " .. tostring(key)
    end
    fire("LibItemDB_PriceSettingsChanged", key, s[key])
    return true
end

--- The source precedence, as a fresh array of source ids.
function lib:GetPriceSourceOrder() return copyList(settings().order) end

--- Replace the precedence. Unknown ids are dropped, omitted built-in ids are appended in default
--- order and an omitted fed source goes to the front, so the result is always a complete
--- permutation.
function lib:SetPriceSourceOrder(list)
    if type(list) ~= "table" then return false, "order must be a list of source ids" end
    local s = settings()
    s.order = normaliseOrder(list, s.external)
    fire("LibItemDB_PriceSettingsChanged", "order", self:GetPriceSourceOrder())
    return true
end

--- Move one source up (delta < 0) or down (delta > 0) the precedence. A move past either end is
--- clamped, not refused.
function lib:MovePriceSource(id, delta)
    local order = settings().order
    local from
    for i, v in ipairs(order) do if v == id then from = i end end
    if not from then return false, "unknown source: " .. tostring(id) end
    local to = from + (tonumber(delta) or 0)
    if to < 1 then to = 1 elseif to > #order then to = #order end
    if to == from then return true end
    table.remove(order, from)
    table.insert(order, to, id)
    fire("LibItemDB_PriceSettingsChanged", "order", self:GetPriceSourceOrder())
    return true
end

-- ---------------------------------------------------------------------------
-- Internal seams for Price/Scanner.lua and Price/Window.lua
-- ---------------------------------------------------------------------------
function lib:_PriceStore()    return store() end
function lib:_PriceSettings() return settings() end
function lib:_PriceDB()       return priceDB() end
function lib:_PriceFire(event, ...) fire(event, ...) end
function lib:_PriceNow()      return now() end
function lib:_PricePrint(msg) print("|cffFF8000LibItemDB|r: " .. tostring(msg)) end

-- Mark a completed full scan for this realm + faction.
function lib:_PriceRecordScan(count)
    local s = store()
    s.lastScanAt, s.lastScanCount = now(), count
end

-- ---------------------------------------------------------------------------
-- Merchant capture — cache vendor buy prices as the user opens vendors.
-- ---------------------------------------------------------------------------
-- numAvailable == -1 means unlimited stock, i.e. a true vendor-sold item (limited-quantity and
-- special-currency wares are skipped). price is per stack; divide. Mirrors Auctionator's
-- CraftingInfo.CacheVendorPrices.
--
-- C_MerchantFrame.GetItemInfo (a MerchantItemInfo table) is preferred wherever it exists: WoW
-- Forever still defines the bare GetMerchantItemInfo global, but calling it errors ("attempt to
-- call a nil value" from inside the C function) -- its own MerchantFrame.lua calls the namespaced
-- form only. The bare global is the fallback for the flavours that lack the namespace.
local function merchantItem(i)
    local C = C_MerchantFrame
    if C and C.GetItemInfo then
        local info = C.GetItemInfo(i)
        if not info then return end
        return info.price, info.stackCount, info.numAvailable
    end
    if not GetMerchantItemInfo then return end
    local _, _, price, stack, numAvailable = GetMerchantItemInfo(i)
    return price, stack, numAvailable
end

local function captureMerchant()
    local n = (GetMerchantNumItems and GetMerchantNumItems()) or 0
    for i = 1, n do
        local price, stack, numAvailable = merchantItem(i)
        local link   = GetMerchantItemLink and GetMerchantItemLink(i)
        local itemID = link and tonumber(link:match("item:(%d+)"))
        if itemID and price and price > 0 and stack and stack > 0 and numAvailable == -1 then
            lib:StoreVendorPrice(itemID, math.floor(price / stack))
        end
    end
end

-- ---------------------------------------------------------------------------
-- Events: SavedVariables binding and the merchant hook
-- ---------------------------------------------------------------------------
-- One frame, kept on the library (`lib.priceEvents`) so it is reachable offline and cannot be
-- collected out from under its handler.
local frame = lib.priceEvents or CreateFrame("Frame")
lib.priceEvents = frame
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("MERCHANT_SHOW")
frame:SetScript("OnEvent", function(_, event, arg1)
    if event == "ADDON_LOADED" then
        if arg1 ~= "ItemDB" then return end
        if type(_G[SV_NAME]) ~= "table" then
            _G[SV_NAME] = pending or {}
        end
        pending = nil
        ensure(_G[SV_NAME])
    elseif event == "MERCHANT_SHOW" then
        captureMerchant()
    end
end)
