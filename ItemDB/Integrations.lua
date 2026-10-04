-- LibItemDB-1.0 — third-party addon integrations
--
-- One place for "read what another addon knows, so a consumer's own tooltip can look like the one
-- the player already sees". A registry rather than a pile of functions, because the expectation is
-- that this list grows: adding the next addon should be a table entry, not new plumbing.
--
-- THE RULES, all learned the hard way and all enforced below:
--
--   * NEVER a hard dependency. Every provider is feature-detected at CALL time — some of these
--     addons load after this library, and a load-time capture of an absent global bakes nil in
--     permanently.
--   * NEVER raise. These are semi-public surfaces on addons nobody here controls. Every call is
--     wrapped; a provider that has moved or thrown drops out silently and the rest still answer.
--   * NEVER read a provider's data into ItemDB's own tables. If a fact is worth shipping, it gets
--     sourced from DBC like everything else. These functions hand a consumer values to draw and
--     keep nothing.
--   * Nothing here is called automatically. The consumer owns its tooltip.
--
-- WHAT IS AND IS NOT POSSIBLE, measured against the installed addons on 2026-08-06. Worth reading
-- before adding the next one, because the useful distinction is not "does the addon have an API":
--
--   MOST OF THESE ADDONS NEED NO BRIDGE AT ALL. RecipeMaster, SmexyMats and Leatrix Plus all hook
--   `GameTooltip`'s OnTooltipSetItem / OnTooltipSetSpell. So a consumer that builds its tooltip on
--   GameTooltip and calls SetItemByID / SetHyperlink / SetSpellByID gets every one of them for
--   free, in their own styling, with no code here. RecipeMaster hooks OnTooltipSetSpell
--   specifically (Source/Handlers/TooltipHandler.lua:176), which is the interesting one: a
--   trainer-taught recipe with no scroll item still fires it via SetSpellByID.
--
--   A bridge is only worth writing for the two cases those hooks cannot cover:
--     1. A HAND-BUILT tooltip (ClearLines + AddLine) that never sets an item or spell, so no hook
--        fires — that is what AllTheThings' entry point is for here.
--     2. Wanting the VALUES to render yourself, in your own layout — TradeSkillMaster and
--        Auctionator, both of which expose numbers and neither of which can draw into a tooltip.
--
--   Not bridged, deliberately:
--     * RecipeMaster — every function in its TooltipHandler is `local`. Nothing is callable, and
--       nothing needs to be: use SetSpellByID / SetItemByID on GameTooltip.
--     * Leatrix Plus — no public API of any kind; its vendor-price line is a user setting on its
--       own GameTooltip hook.
--     * SmexyMats — `SmexyMats.ModifyItemTooltip(tt)` IS a global, but it reads
--       `_G["GameTooltipTextLeft1"]` internally and latches a file-local `isTooltipDone`
--       (SmexyCore.lua:280-286), so it only behaves on GameTooltip itself. Calling it with a custom
--       tooltip would read the wrong frame's text. Left alone rather than wrapped unsafely.
--     * TSM's own tooltip module is `TSM:NewPackage("Tooltip")` on the addon-private table
--       (Core/Service/Tooltip/Core.lua:8), not reachable from another addon — the same shape as the
--       `TSM.UI.CraftingUI.Toggle()` problem TOGProfessionMaster documented. And
--       TradeSkillMaster_AppHelper is 28 lines of auction data with no tooltip code at all, so it
--       is not the way in either.

local MAJOR = "LibItemDB-1.0"
local lib = LibStub and LibStub(MAJOR, true)
if not lib then return end

-- Identifies us to Auctionator, which requires a non-empty caller string and raises without one.
local CALLER_ID = "LibItemDB"

-- Ordered so a consumer drawing several lines gets a stable layout between sessions.
-- Each provider: name, detect() -> truthy when usable, and at most one of prices()/attach().
local PROVIDERS = {}

-- ---------------------------------------------------------------------------
-- AllTheThings — attaches its OWN lines, so it is the only provider that draws
-- ---------------------------------------------------------------------------
-- Taken from ATT's Classic path, not its retail one — the two hand over different search
-- functions and only this one is what a Classic client runs:
--   src/Modules/Tooltip.lua:1214   AttachTooltipSearchResults(self, SearchForField, "spellID", id)
--   src/Modules/Tooltip.lua:1372   app.Modules.Tooltip = api          (the export path)
--   src/Cache.lua:110              app.SearchForField = function(field, id)
-- `SearchForObject` is ATT's link/ID path (Tooltip.lua:831) and a different lookup; it is kept
-- only as a fallback so a future reshuffle degrades rather than breaks.
--
-- Keying by SPELL is the point: src/Cache.lua:895-898 shows `fieldConverters.recipeID` also calls
-- `cacheSpellID`, so every ATT recipe row is dual-indexed under spellID and the lookup reaches it
-- whether or not a scroll item exists.
local function attMod()
    local ATT = _G.AllTheThings
    local mod = ATT and ATT.Modules and ATT.Modules.Tooltip
    local attach = mod and mod.AttachTooltipSearchResults
    local search = ATT and (ATT.SearchForField or ATT.SearchForObject)
    if type(attach) == "function" and type(search) == "function" then return attach, search end
end

--- Attach AllTheThings' own lines to any tooltip, for a recipe identified by its craft spell id.
--- @param tooltip table the tooltip to attach to
--- @param spellID number the recipe's trade-skill spell id
--- @return boolean attached true only when ATT actually added lines
function lib:AttachExternalRecipeInfo(tooltip, spellID)
    if type(tooltip) ~= "table" or type(spellID) ~= "number" then return false end
    if type(tooltip.NumLines) ~= "function" then return false end

    local attach, search = attMod()
    if not attach then return false end

    -- `AttachTooltipSearchResults` RETURNS NOTHING (Tooltip.lua:789-812) — it pcalls the search
    -- internally and swallows a miss — so its return cannot tell a caller whether anything landed.
    -- A line-count delta is the only honest answer, and it is what a consumer needs to decide
    -- whether to add its own "no data" line.
    local before = tooltip:NumLines() or 0
    if not pcall(attach, tooltip, search, "spellID", spellID) then return false end
    return (tooltip:NumLines() or 0) > before
end

-- ---------------------------------------------------------------------------
-- TradeSkillMaster — values only
-- ---------------------------------------------------------------------------
-- TSM_API is entirely value-fetch (Core/API.lua): ToItemString, GetCustomPriceValue,
-- FormatMoneyString, GetPlayerTotals. There is no tooltip entry point of any kind.
-- Every TSM_API function validates its arguments by RAISING, so all of this is wrapped.
--
-- The sources are TSM's own price-source keys. A key the user's TSM does not have simply returns
-- nil and is skipped, so an unconfigured or app-less TSM degrades to fewer lines rather than an
-- error — which is why the list is tried rather than gated on GetPriceSourceKeys.
-- SOURCES AND LABELS COME FROM TSM, NOT FROM A LIST HERE. `GetPriceSourceKeys` enumerates every
-- key this install supports and `GetPriceSourceDescription` returns TSM's own **localized** label
-- for each, so the bridge picks up Vendor Sell Price, the Region* block, anything TSM adds later,
-- and the right wording in the player's language — none of which a hardcoded English table would
-- do. Both raise on bad input, so both are wrapped.
--
-- The Region* values come from the TSM Desktop App via TradeSkillMaster_AppHelper rather than the
-- player's own scans (`AppData.lua` carries AUCTIONDB_REGION_SALE with `regionSale` /
-- `regionSoldPerDay` / `regionSalePercent` — 724 KB of it). Without the app they are simply absent,
-- return nil, and are skipped rather than shown as zero.
--
-- NOT EVERY SOURCE IS MONEY, and TSM will not tell us which are. It registers 41 sources across six
-- modules, and plenty are counts or ratios: `ItemLevel`, `ItemQuality`, `MaxStack`, `NumInventory`,
-- `RequiredLevel`, `SaleRate`, `NumExpires`, `DBRegionSaleRate`, `DBRegionSoldPerDay`. Running any
-- of those through `FormatMoneyString` prints a plausible, entirely wrong gold amount — TSM's own
-- tooltip shows "Region Sale Rate 0.038" as a bare number.
--
-- `CustomString.RegisterSource` DOES take a source type, and `CustomString.GetSourceInfo` returns
-- it — but `TSM_API.GetPriceSourceDescription` throws it away (`local _, label = …`), so the public
-- API cannot answer the question.
--
-- So this is an ALLOW-list, not a deny-list, and the direction matters: a source TSM adds later
-- that this file has never heard of comes back with a raw `value`, `isMoney = nil` and no
-- `formatted`, leaving the consumer to decide. The opposite default would silently money-format
-- the next count TSM invents.
--
-- Keys taken from TSM's own `RegisterSource` calls, and the split checked exhaustive rather than
-- eyeballed: the installed client registers 41 (AuctionDB 9, Accounting 9, External 8, Item 7,
-- Operations 5, Crafting 3); the 9 non-money ones are listed above; 32 remain and are all here.
-- If that arithmetic stops holding after a TSM update, a key has been added — which the allow-list
-- degrades safely on, but it is worth re-checking.
local TSM_MONEY_KEYS = {
    -- AuctionDB (9 registered; DBRegionSaleRate and DBRegionSoldPerDay are rates, not money)
    DBMarket = true, DBMinBuyout = true, DBHistorical = true, DBRecent = true,
    DBRegionMarketAvg = true, DBRegionHistorical = true, DBRegionSaleAvg = true,
    -- Item
    VendorSell = true, VendorBuy = true,
    -- Crafting
    Crafting = true, Destroy = true, MatPrice = true,
    -- Accounting (transaction history — money; SaleRate and NumExpires are NOT)
    AvgSell = true, MaxSell = true, MinSell = true,
    AvgBuy = true, MaxBuy = true, MinBuy = true, SmartAvgBuy = true,
    -- External (TSM bridging other price addons — all money)
    AtrValue = true, AucMarket = true, AucAppraiser = true, AucMinBuyout = true,
    AHDBMinBid = true, AHDBMinBuyout = true, OERealm = true, OERegion = true,
    -- Operations
    AuctioningOpMin = true, AuctioningOpMax = true, AuctioningOpNormal = true,
    ShoppingOpMax = true, SniperOpMax = true,
}

local function tsmPrices(_, itemLink)
    local API = _G.TSM_API
    if type(API) ~= "table" or type(API.ToItemString) ~= "function"
        or type(API.GetCustomPriceValue) ~= "function" then return nil end
    if type(itemLink) ~= "string" then return nil end

    local ok, itemString = pcall(API.ToItemString, itemLink)
    if not ok or not itemString then return nil end

    -- Ask TSM what it supports rather than carrying a list. GetPriceSourceKeys fills a table the
    -- caller supplies and returns it.
    local gotKeys, keys = pcall(API.GetPriceSourceKeys, {})
    if not gotKeys or type(keys) ~= "table" then return nil end

    local out
    for _, key in ipairs(keys) do
        local gotValue, value = pcall(API.GetCustomPriceValue, key, itemString)
        if gotValue and type(value) == "number" and value > 0 then
            -- nil, not false, for a source we do not recognise: "unknown" and "known not money"
            -- are different answers and a consumer may want to treat them differently.
            local isMoney = TSM_MONEY_KEYS[key] or nil

            -- TSM's own localized description, so the label reads as it does in TSM's tooltip and
            -- in the player's language. Raises on an unknown key; fall back to the key itself,
            -- which is at least recognisable rather than blank.
            local label = key
            if type(API.GetPriceSourceDescription) == "function" then
                local gotLabel, text = pcall(API.GetPriceSourceDescription, key)
                if gotLabel and type(text) == "string" and text ~= "" then label = text end
            end

            local formatted
            if isMoney and type(API.FormatMoneyString) == "function" then
                local gotText, text = pcall(API.FormatMoneyString, value)
                if gotText then formatted = text end
            end

            out = out or {}
            out[#out + 1] = {
                key = key, label = label, value = value,
                formatted = formatted, isMoney = isMoney,
            }
        end
    end
    return out
end

-- ---------------------------------------------------------------------------
-- Auctionator — values only, and the best-behaved of the five
-- ---------------------------------------------------------------------------
-- A properly versioned public API (Source/API/v1/*). Every entry point takes a callerID first and
-- RAISES on a bad one or a wrong argument type (Source/API/Internal.lua), so all of this is
-- wrapped and CALLER_ID is a non-empty string. The ID is not registered or authorised — the
-- source's own comment says maintaining authorization keys is a TODO — it only names us in errors.
local AUCTIONATOR_SOURCES = {
    { fn = "GetAuctionPriceByItemLink",    label = "Auction Price" },
    { fn = "GetVendorPriceByItemLink",     label = "Vendor Price" },
    { fn = "GetDisenchantPriceByItemLink", label = "Disenchant Value" },
}

local function auctionatorPrices(_, itemLink)
    local A = _G.Auctionator
    local v1 = A and A.API and A.API.v1
    if type(v1) ~= "table" or type(itemLink) ~= "string" then return nil end

    local out
    for _, src in ipairs(AUCTIONATOR_SOURCES) do
        local fn = v1[src.fn]
        if type(fn) == "function" then
            local ok, value = pcall(fn, CALLER_ID, itemLink)
            if ok and type(value) == "number" and value > 0 then
                out = out or {}
                out[#out + 1] = { label = src.label, value = value }
            end
        end
    end
    return out
end

-- ---------------------------------------------------------------------------
-- SmexyMats — REMOVED 2026-09-22, and the `materials` provider KIND went with it
-- ---------------------------------------------------------------------------
-- This file used to carry a SmexyMats reader for "which professions use this material". The
-- library now ships that itself (GetReagentUses / IsReagent, MINOR 32) for every version, derived
-- from the client's own recipe tables, so the bridge answered a question we answer better and only
-- for the players who happened to have an abandoned addon installed. Operator, 2026-09-22: "i don't
-- want a smexymats bridge, i want full feature parity IN ItemDB, that addon is abandoned."
--
-- ONE THING FROM IT IS WORTH KEEPING, because our own tooltip hook has to avoid the same trap:
-- `SmexyMats.ModifyItemTooltip` read `_G["GameTooltipTextLeft1"]` and latched a file-local
-- `isTooltipDone` (SmexyCore.lua:280-286), so it only ever behaved on GameTooltip itself and broke
-- on any custom tooltip frame. Ours is written against the tooltip it is handed, never against a
-- global by name.

PROVIDERS[#PROVIDERS + 1] = {
    name   = "TradeSkillMaster",
    detect = function() return type(_G.TSM_API) == "table" end,
    prices = tsmPrices,
}
PROVIDERS[#PROVIDERS + 1] = {
    name   = "Auctionator",
    detect = function() return _G.Auctionator and _G.Auctionator.API and _G.Auctionator.API.v1 end,
    prices = auctionatorPrices,
}
PROVIDERS[#PROVIDERS + 1] = {
    name   = "AllTheThings",
    detect = function() return attMod() ~= nil end,
    attach = true,
}

-- ---------------------------------------------------------------------------
-- The universal bridge: fan the hook chain out onto YOUR tooltip
-- ---------------------------------------------------------------------------
-- Everything above reads a specific addon through a specific API, which only works for addons that
-- expose one. This does not care: it replays the hooks themselves.
--
-- WHY IT WORKS. `HookScript` COMPOSES — the frame's script becomes a function that calls the
-- previous handler and then the new one, and `GetScript` hands that whole chain back. Every handler
-- in it takes the tooltip as its argument and operates on that argument:
--
--     RecipeMaster  function(tooltip, ...) … appendMessage(tooltip, msg) … tooltip:AddLine(msg)
--     AllTheThings  function(self)         … AttachTooltipSearchResults(self, …)
--
-- So calling `GameTooltip:GetScript("OnTooltipSetItem")` with a DIFFERENT tooltip runs every
-- addon's handler against that one instead. `tooltip:GetItem()` returns what you set on yours, and
-- every `AddLine` lands on yours.
--
-- **GameTooltip is never read, written, shown, hidden or re-owned.** This is a parallel fan-out,
-- not a scratchpad: the live tooltip's state is untouched, so nothing flickers and nothing has to be
-- saved and restored. That is the whole reason to prefer it over driving GameTooltip and scraping
-- its text back.
--
-- WHAT IT CANNOT DO. Two distinct failure modes, both SILENT — the handler runs, adds nothing, and
-- reports nothing. Worth knowing before assuming an addon is covered:
--
--   1. **Reads the GLOBAL instead of its argument.** It then reads GameTooltip's contents, not
--      yours. SmexyMats' `ModifyItemTooltip` is exactly this (`_G["GameTooltipTextLeft1"]`).
--
--   2. **Gates on its OWN registry of tooltips it wrapped.** TradeSkillMaster is this, and it is
--      the more dangerous pattern because the handler looks perfectly argument-driven:
--
--          function private.OnTooltipSetItem(tooltip, data)     -- TooltipWrapper.lua:113
--              local reg = private.tooltipRegistry[tooltip]
--              if not reg then return end                       -- <- ours is not registered
--
--      TSM genuinely does hook `GameTooltip:HookScript("OnTooltipSetItem", …)` on Classic
--      (TooltipWrapper.lua:91 — the `C_TOOLTIP_INFO` feature test at :88 sends retail down
--      `TooltipDataProcessor` instead), so the chain contains its handler and replaying it looks
--      like it should work. It returns at the first line. There is no way in: the registry lives on
--      `TSM.LibTSMWoW:Include("TooltipWrapper")`, which is addon-private.
--
-- Both are covered by their per-addon reads above instead, and the two routes do not overlap —
-- use whichever fits. Expect this second pattern from any carefully-written addon.
--   * Your tooltip MUST be a named frame inheriting `GameTooltipTemplate`. RecipeMaster's
--     de-duplication reads `_G[tooltip:GetName().."TextLeft"..i]`, so an anonymous tooltip makes
--     that concat fail, and without the template those font strings do not exist at all.
--   * Populate your tooltip BEFORE calling this. Handlers ask it what item or spell it is showing;
--     an empty tooltip tells them nothing and they will correctly do nothing.
--
-- Only GameTooltip's chain is replayed, deliberately. Several addons hook `ItemRefTooltip` with the
-- same body, and replaying both would add every line twice.
local FANOUT_SCRIPTS = { OnTooltipSetItem = true, OnTooltipSetSpell = true }

--- Replay every installed addon's tooltip hooks against YOUR tooltip.
---
--- The universal bridge — it works for an addon whether or not it exposes any API, because it
--- replays the addon's own handler rather than calling into it. That covers the ones that cannot be
--- reached any other way (RecipeMaster keeps its whole namespace private, Leatrix Plus exposes
--- nothing), and it costs nothing when none are installed.
---
--- Populate the tooltip first, then call this:
---
---     myTooltip:SetOwner(parent, "ANCHOR_RIGHT")
---     myTooltip:SetSpellByID(craftSpellID)      -- or SetItemByID / SetHyperlink
---     lib:ApplyExternalTooltipHooks(myTooltip, "OnTooltipSetSpell")
---     myTooltip:Show()
---
--- @param tooltip table a NAMED tooltip inheriting GameTooltipTemplate, already populated
--- @param scriptType string "OnTooltipSetItem" or "OnTooltipSetSpell"
--- @return boolean ran true only when a chain existed and completed; false is not an error
function lib:ApplyExternalTooltipHooks(tooltip, scriptType)
    if type(tooltip) ~= "table" or not FANOUT_SCRIPTS[scriptType] then return false end
    if type(tooltip.AddLine) ~= "function" or type(tooltip.GetName) ~= "function" then return false end
    -- An anonymous tooltip is a guaranteed error inside at least one known handler, so refuse it
    -- here where the cause is obvious rather than there where it is not.
    if not tooltip:GetName() then return false end

    local source = _G.GameTooltip
    if type(source) ~= "table" or type(source.GetScript) ~= "function" then return false end

    local gotChain, chain = pcall(source.GetScript, source, scriptType)
    if not gotChain or type(chain) ~= "function" then return false end

    -- One pcall around the whole chain: these are other addons' handlers, and one that raises must
    -- not take the consumer's tooltip down with it. A handler that throws halfway leaves whatever
    -- earlier handlers already added, which is the right outcome — partial lines beat none.
    return pcall(chain, tooltip) and true or false
end

--- Which integrations are actually usable right now, in display order.
--- Resolved at call time, never cached — these addons can load after this library.
--- @return table names array of provider names; empty when none are present
function lib:GetAvailableIntegrations()
    local out = {}
    for _, p in ipairs(PROVIDERS) do
        local ok, present = pcall(p.detect)
        if ok and present then out[#out + 1] = p.name end
    end
    return out
end

--- Prices for an item, from every price-providing addon the player has.
---
--- Values are in COPPER and are the provider's own numbers, unmodified — the point is that a
--- consumer's tooltip can show the same figure the player already sees elsewhere. `formatted` is
--- present only where the provider supplies its own money formatting (TSM does; Auctionator does
--- not), so a consumer should fall back to its own formatter rather than assume it.
---
--- @param itemLink string the item's link. A bare id is NOT accepted: both providers key off links
---        or their own item strings, and passing an id silently returns nothing.
--- @return table|nil results `{ [providerName] = { { label, value, formatted? }, ... } }`, or nil
---         when no provider had anything. Never an empty table — absence is one check, not two.
function lib:GetExternalPrices(itemLink)
    if type(itemLink) ~= "string" then return nil end

    local out
    for _, p in ipairs(PROVIDERS) do
        if p.prices then
            local ok, present = pcall(p.detect)
            if ok and present then
                local gotRows, rows = pcall(p.prices, self, itemLink)
                if gotRows and rows and #rows > 0 then
                    out = out or {}
                    out[p.name] = rows
                end
            end
        end
    end
    return out
end

-- GetExternalMaterialInfo IS GONE, and this note is here so nobody re-adds it. It bridged to
-- SmexyMats for "which professions use this material", which the library now answers from its own
-- shipped data (GetReagentUses / IsReagent, LibItemDB-1.0 MINOR 32) on every version. The operator,
-- 2026-09-22: "i don't want a smexymats bridge, i want full feature parity IN ItemDB, that addon is
-- abandoned." Bridging to an abandoned addon for a fact we hold ourselves would leave the better
-- answer behind whether that addon happens to be installed, which is exactly what a bridge is for
-- and exactly wrong here. A consumer that called it calls GetReagentUses instead; see README.
