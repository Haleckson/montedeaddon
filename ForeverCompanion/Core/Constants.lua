--[[
  Forever Companion - Core/Constants.lua
  Versions, limits and default settings. No logic lives here.
]]

local _, FC = ...

local C = {}
FC.C = C

C.DB_VERSION = 7           -- ForeverCompanionDB schema version (see Core/Migration.lua)
C.CHAR_DB_VERSION = 1      -- ForeverCompanionCharDB schema version
C.PROTOCOL = 1             -- guild sync wire protocol version
C.COMM_PREFIX = "FCJ1"
C.EXPORT_PREFIX = "FC1"
C.THEME_EXPORT_PREFIX = "FCT1"
C.PROFILE_EXPORT_PREFIX = "FCP1"
C.MEDIA = "Interface\\AddOns\\ForeverCompanion\\Media\\"
C.WHITE = "Interface\\Buttons\\WHITE8X8"
C.CIRCLE_MASK = "Interface\\CharacterFrame\\TempPortraitAlphaMask"
C.FAVORITE_ICON = "Interface\\Common\\FavoritesIcon"
C.VERIFIED_ICON = "Interface\\RaidFrame\\ReadyCheck-Ready"
C.GUILD_ICON = "Interface\\GossipFrame\\TabardGossipIcon"

-- Size and safety limits. Every value that crosses a trust boundary
-- (SavedVariables, addon messages, import strings) is checked against these.
C.LIMITS = {
    TITLE = 80,
    DESCRIPTION = 1000,
    NOTE = 500,
    GUILD_NOTE = 300,
    GUILD_NOTES = 20,
    TAG = 24,
    TAGS = 10,
    NAME = 64,
    ZONE = 64,
    ID = 96,
    INVENTORY = 60,
    OBSERVATIONS = 12,
    VERIFIERS = 50,
    IMPORT_CHARS = 2000000,
    IMPORT_RECORDS = 5000,
    IMPORT_NODES = 800000, -- a full backup with quest knowledge and autobiographies
    DESERIALIZE_DEPTH = 8,
    DESERIALIZE_NODES = 200000,
    FEED = 60,
}

C.SYNC = {
    CHUNK_DATA = 225,            -- payload bytes per addon message (255 max incl. header)
    BURST = 6,                   -- token bucket size
    REFILL = 1.0,                -- seconds per token
    PARTIAL_TIMEOUT = 60,        -- drop incomplete multi-part messages after this
    MAX_PARTIALS = 32,
    HELLO_DELAY = 10,            -- seconds after login before announcing
    REQUEST_WINDOW = 6,          -- seconds to collect HELLO replies before choosing a peer
    RESPONSE_CAP = 400,          -- max records sent for one delta request
    BATCH_SIZE = 6,              -- records per BATCH message (before chunking)
    SINCE_MARGIN = 600,          -- overlap subtracted from lastOnline
    PEER_REPLY_COOLDOWN = 300,
    REQUEST_COOLDOWN = 60,
    INCOMING_PER_10S = 80,       -- max messages accepted from one sender per 10 s
    LORE_DELAY = 5,              -- quest knowledge learned is sent this long after the last fact
    LORE_BATCH = 30,             -- facts per quest knowledge message
    LORE_CAP = 1200,             -- max facts sent for one catch-up request
}

C.DISCOVERY = {
    RECORD_COOLDOWN = 60,        -- the same auto-detected id is processed at most once a minute
    SIGHTING_DEDUPE = 180,
    DEATH_DEDUPE = 300,
    MAX_RESPAWN_WINDOW = 4 * 3600,
    ESTIMATE_MIN_SAMPLES = 3,
    VEIL_RADIUS_YARDS = 45,
    VEIL_RADIUS_NORMALIZED = 0.015,
    OBJECT_GRID = 50,            -- 2% grid for object and manual dedupe keys
    OBJECT_NEAR = 0.03,          -- an object this close (normalized) to one already filed is the same object
    COMBAT_QUEUE = 200,          -- finds kept for after a fight (each thing once)
    CAVE_MIN_SECONDS = 12,       -- stay indoors this long ...
    CAVE_MIN_DISTANCE = 0.012,   -- ... and move this far (normalized) for a cave
    CHAIN_WINDOW = 180,          -- accepting a quest this soon after a turn-in links a chain
    GATHER_WINDOW = 4,           -- loot this soon after a gathering cast is a gathering node
    TRAIL_POINTS = 40,           -- remembered positions for routes
    TRAIL_SECONDS = 180,
    ROUTE_POINTS = 12,
    MAX_DROPS = 24,
    MAX_POINTS = 40,
    MAX_MECHANICS = 12,
}

C.STATUS = {
    PERSONAL = "personal",
    ALT = "alt",                 -- found by another of your characters (per-character progress)
    GUILD = "guild",
    VERIFIED = "verified",
    RUMORED = "rumored",
    FAVORITE = "favorite",
    ARCHIVED = "archived",
    PRIVATE = "private",
}

-- Default profile. Every key read by the UI must exist here; missing keys in
-- stored profiles are filled from this table on load (see Profiles).
FC.Defaults = {
    general = {
        minimap = { show = true, angle = 215 },
        targetButton = { show = false },
        chatLinks = true,
    },
    appearance = {
        style = "journal",       -- "journal" (painted leather and parchment) | "flat" (color themes)
        theme = "Forever Dark",
        colors = {},             -- per-role overrides on top of the theme ("rrggbb")
        scale = 1.0,
        alpha = 1.0,
        bgAlpha = 0.97,
        borderSize = 1,
        corners = "sharp",       -- "sharp" | "soft" (soft adds an inner shade)
        buttonStyle = "filled",  -- "filled" | "outlined"
        cardDensity = "comfortable", -- "comfortable" | "compact"
        tooltipStyle = "addon",  -- "addon" | "blizzard"
        animations = true,
        highContrast = false,
        window = { width = 1100, height = 660, detailWidth = 340 },
    },
    fonts = {
        main = "Friz Quadrata",
        header = "Friz Quadrata",
        size = 12,
        outline = "NONE",
        shadow = true,
        spacing = 1,
    },
    journal = {
        defaultPage = "overview",
        sort = "recent",
        showArchived = false,
        questSort = "zone",      -- Completed quests: "zone" | "name" | "level" | "recent"
    },
    knowledge = {
        mode = "all",            -- "mine" | "verified" | "all"
        veil = false,            -- guild discoveries stay "rumored" until you visit them
    },
    map = {
        enabled = true,
        showMine = true,
        showGuild = true,
        -- only the finds that matter are on the map by default; true = hidden,
        -- false = shown on purpose (so a default never overrides a choice)
        hiddenGroups = {
            quest = true, vendor = true, recipe = true, npc = true, creature = true,
            profession = true, path = true, explored = true, other = true,
        },
        showDeaths = false,      -- dangerous spots (where you died)
        minimap = true,          -- the same pins, small, on the minimap
        minimapScale = 1.0,
        iconScale = 1.0,
        iconAlpha = 1.0,
        altClickNotes = true,
        preferTomTom = false,
    },
    discovery = {
        -- every category has an automatic source; each can be switched off
        rares = true,
        creatures = true,        -- bestiary: every hostile or neutral creature you meet
        nameplates = true,
        vendors = true,
        trainers = true,
        travel = true,           -- flight masters
        gossip = true,           -- NPCs and objects you talk to or use
        readables = true,        -- books, plaques, letters in the world
        quests = true,
        questChains = true,
        loot = true,
        lootQuality = 3,
        recipes = true,
        recipesLearned = true,
        objects = true,          -- chests and caches (gathering nodes filtered out)
        gathering = true,        -- herb, ore and fishing locations per zone
        explored = true,         -- "Discovered: <area>" from the game
        caves = true,
        dungeons = true,
        dungeonAreas = true,
        bosses = true,
        mechanics = true,        -- boss emotes and yells during encounters
        routes = true,           -- the route that led to a hidden place
        deaths = true,           -- where you died (private)
        autoText = true,         -- generated descriptions and tags
        verifyThreshold = 2,
    },
    sync = {
        enabled = true,
        autoShare = true,
        channel = "GUILD",       -- "GUILD" | "PARTY" | "RAID" | "NONE"
        shareQuests = false,
        shareQuestKnowledge = true, -- who gives which quest, which creatures quests need
        shareNotes = false,
        shareCoords = true,
        shareCreatures = true,
        shareGathering = true,
        notifyVersion = true,
    },
    notifications = {
        enabled = true,
        duration = 6,
        scale = 1.0,
        maxVisible = 3,
        sound = true,
        soundKit = "MAP_PING",
        eventSounds = true,      -- rares, bosses, treasure, dungeons ... have their own sounds
        flightPathSound = true,  -- a short chime when you learn a flight path
        flash = false,           -- flash the game's taskbar icon when a rare is near
        animate = true,
        point = { "TOP", "TOP", 0, -150 },
        -- whose discoveries and which events make a toast
        types = {
            personal = true,         -- discoveries you make
            guild = true,            -- discoveries guild members share
            kill = true,             -- rares and world bosses you defeat
            nearby = true,           -- rares and treasure the game marks near you
            milestone = true,
            sync = true,
        },
        -- what counts as a discovery worth a toast. Everything is still written
        -- into the journal; routine finds (quests, creatures, explored areas,
        -- services, gathering spots, death spots) are quiet by default.
        categories = {
            rare = true, boss = true, dungeon = true, treasure = true, secret = true,
            cave = true, recipe = true, item = true, shortcut = true, other = true,
            profession = true,       -- recipes you learn (gathering spots are "gathering")
            npc = false, vendor = false, vendorrecipe = false, gathering = false,
            trainer = false, travel = false, creature = false,
            quest = false, questchain = false, landmark = false, path = false,
            entrance = false, room = false, mechanic = false, object = false,
            note = false,
        },
    },
    tooltips = {
        unit = true,
        item = true,
        quests = true,           -- quests an NPC gives and takes, with your progress
        questItems = true,       -- quest items creatures drop, and on the item itself
        npcID = true,
        spawn = true,            -- how long a rare has been up, and its layer
        alts = true,             -- which of your other characters already did a quest
        sources = true,          -- items: the creatures and vendors seen with them
    },
    biography = {
        enabled = true,          -- keep the autobiography (statistics and timeline)
        screenshots = false,     -- take a screenshot at level ups and boss kills
    },
    zoneGuide = {
        shown = false,           -- stays open across sessions once opened
        autoOpen = false,        -- open it when entering a new zone
        point = nil,
        hideDone = false,        -- hide finished lines
        collapsed = {},          -- folded sections by key
    },
    nameplates = {
        questMarker = true,      -- marker above creatures your active quests need
        hideInCombat = true,     -- markers step aside while you fight
        markerScale = 1.0,
    },
    milestones = {
        enabled = true,
    },
    debug = {
        enabled = false,
        level = 4,
    },
}
