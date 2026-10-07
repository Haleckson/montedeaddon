--[[
  Forever Companion - UI/Biography.lua
  The Autobiography page of the journal: a character's (or the whole
  account's) statistics and the timeline of its life. Nothing of it is on
  screen unless you open this page.
]]

local _, FC = ...

local UI = FC.UI
local U = FC.Utils
local L = FC.L
local Theme = FC.Theme
local Compat = FC.Compat

local ACCOUNT = "*account*"
local ROW = 19

local EVENT_ICONS = {
    level = "Interface\\Icons\\Spell_Holy_SurgeOfLight",
    death = "Interface\\Icons\\Ability_Rogue_FeignDeath",
    zone = "Interface\\Icons\\INV_Misc_Map_01",
    boss = "Interface\\Icons\\INV_Misc_Bone_HumanSkull_01",
    rare = "Interface\\Icons\\INV_Misc_Head_Dragon_01",
    skill = "Interface\\Icons\\INV_Misc_Book_11",
    duelWon = "Interface\\Icons\\Ability_Warrior_Challange",
    duelLost = "Interface\\Icons\\Ability_Warrior_Challange",
    guild = FC.C.GUILD_ICON,
    epic = "Interface\\Icons\\INV_Misc_Gem_Variety_02",
    flightpath = "Interface\\Minimap\\Tracking\\FlightMaster",
}

local function km(yards)
    return string.format(L.BIO_KM, FC.Biography.Km(yards))
end

local function describeEvent(e)
    local v = e.v ~= nil and U.Escape(tostring(e.v)) or ""
    local key = "BIO_EVENT_" .. e.k:upper()
    local template = rawget(L, key) or "%s"
    if e.v == nil and rawget(L, key .. "_UNKNOWN") then return L[key .. "_UNKNOWN"] end
    return string.format(template, v)
end

function UI.BiographyPage(parent)
    local page = CreateFrame("Frame", nil, parent)
    local area = UI.ScrollArea(page)
    area:SetAllPoints()
    local content = area.content
    page.area = area
    page.selected = nil -- nil = the character you play

    -- title and subtitle are shown by the journal's page header
    page.title, page.subtitle = "", ""

    page.character = UI.Dropdown(content, nil, function()
        local items = { { value = ACCOUNT, text = L.BIO_ACCOUNT } }
        local keys = U.SortedKeys(FC.db.bio)
        for _, key in ipairs(keys) do
            local char = FC.db.characters[key]
            items[#items + 1] = { value = key, text = (char and char.n or U.ShortName(key)) .. (char and char.l and ("  (" .. char.l .. ")") or "") }
        end
        return items
    end, function() return page.selected or FC.Store.me end, function(value)
        page.selected = value
        page:Refresh()
    end, 200)

    page.tiles = {}
    for i = 1, 5 do
        local tile = UI.Panel(content, { bg = "panelAlt", bgAlpha = 1, border = "border", shade = false, skin = "panel", corner = 10 })
        tile:SetHeight(64)
        tile.value = UI.Text(tile, "numeric", "text")
        tile.value:SetPoint("TOPLEFT", 12, -10)
        tile.value:SetPoint("RIGHT", -8, 0)
        tile.label = UI.Text(tile, "meta", "muted")
        tile.label:SetPoint("BOTTOMLEFT", 12, 10)
        tile.label:SetPoint("RIGHT", -8, 0)
        page.tiles[i] = tile
    end

    page.headers = UI.Pool(function() return UI.SectionHeader(content) end)
    page.rows = UI.Pool(function()
        local row = CreateFrame("Frame", nil, content)
        row:SetHeight(ROW)
        row.icon = UI.Icon(row, 14)
        row.icon:SetPoint("LEFT", 0, 0)
        row.left = UI.Text(row, "secondary", "muted")
        row.left:SetPoint("LEFT", 0, 0)
        row.right = UI.Text(row, "secondary", "text")
        row.right:SetPoint("RIGHT", 0, 0)
        row.right:SetJustifyH("RIGHT")
        return row
    end, function(row) row.icon:Hide() end)

    function page:Stats()
        local key = self.selected or FC.Store.me
        if key == ACCOUNT then return FC.Biography:Account(), true end
        return FC.Biography:Get(key), false
    end

    function page:Refresh()
        local Bio = FC.Biography
        local s, account = self:Stats()
        local width = area:ContentWidth() - 8
        local key = self.selected or FC.Store.me
        local char = FC.db.characters[key]
        if account then
            self.title = L.BIO_TITLE_ACCOUNT
            self.subtitle = (string.format(L.BIO_SINCE, U.FormatDate(s.started)))
        else
            self.title = (string.format(L.BIO_TITLE, char and char.n or U.ShortName(key)))
            local level = char and char.l and string.format(L.TIP_LEVEL, char.l) or ""
            self.subtitle = (level .. (level ~= "" and "  \194\183  " or "") .. string.format(L.BIO_SINCE, U.FormatDate(s.started)))
        end
        self.character:Refresh()

        -- headline numbers
        local y = 4
        local gap = 10
        local tileWidth = (width - gap * 4) / 5
        local tiles = {
            { km(Bio:TotalDistance(s)), L.BIO_DISTANCE },
            { U.FormatNumber(s.deaths), L.BIO_DEATHS },
            { U.FormatNumber(s.kills), L.BIO_KILLS },
            { U.FormatNumber(Bio:QuestsCompleted(not account and key or nil)), L.BIO_QUESTS },
            { U.FormatLongDuration(s.time.online), L.BIO_ONLINE },
        }
        for i, tile in ipairs(self.tiles) do
            tile:ClearAllPoints()
            tile:SetPoint("TOPLEFT", (i - 1) * (tileWidth + gap) + 4, -y)
            tile:SetWidth(tileWidth)
            tile.value:SetText(tiles[i][1])
            tile.label:SetText(tiles[i][2]:upper())
        end
        y = y + 64 + 20

        self.headers:ReleaseAll()
        self.rows:ReleaseAll()
        local columnWidth = math.floor((width - 24) / 2)
        local columns = { { x = 4, y = y }, { x = columnWidth + 28, y = y } }

        local function section(column, title)
            local c = columns[column]
            local h = self.headers:Acquire()
            h:SetText(title)
            h:SetPoint("TOPLEFT", c.x, -c.y)
            h:SetWidth(columnWidth)
            c.y = c.y + 26
        end
        local function line(column, label, value, icon)
            if value == nil or value == "" then return end
            local c = columns[column]
            local row = self.rows:Acquire()
            row:SetPoint("TOPLEFT", c.x, -c.y)
            row:SetWidth(columnWidth)
            row.left:SetText(label)
            row.right:SetText(value)
            if icon then
                row.icon:Show()
                UI.SetIcon(row.icon, icon)
                row.left:SetPoint("LEFT", 20, 0)
            else
                row.left:SetPoint("LEFT", 0, 0)
            end
            c.y = c.y + ROW
        end
        local function top(column, map, count, format, field)
            for _, entry in ipairs(Bio.Top(map, count, field)) do
                -- "?" was an unknown killer in older versions
                if entry.key ~= "?" then
                    line(column, "  " .. U.Escape(tostring(entry.key)), format and format(entry.value) or U.FormatNumber(entry.value))
                end
            end
        end
        local function n(v) return U.FormatNumber(v) end
        local function time(v) return U.FormatLongDuration(v) end

        -- left column: travel, life and fights
        section(1, L.BIO_SEC_TRAVEL)
        line(1, L.BIO_ON_FOOT, km(s.dist.foot))
        line(1, L.BIO_MOUNTED, km(s.dist.mount))
        line(1, L.BIO_SWIMMING, km(s.dist.swim))
        line(1, L.BIO_ON_FLIGHTS, km(s.dist.taxi))
        line(1, L.BIO_AS_GHOST, km(s.dist.ghost))
        line(1, L.BIO_FLIGHTS, n(s.flights))
        if not account and char and char.fp then line(1, L.BIO_FLIGHT_PATHS, n(U.Count(char.fp))) end
        line(1, L.BIO_HEARTHS, n(s.hearths))
        line(1, L.BIO_ZONES, n(U.Count(s.zones)))
        line(1, L.BIO_FAVORITE_ZONE, (Bio.Top(s.zones, 1, "t")[1] or {}).key)
        line(1, L.BIO_LONGEST_WALK_ZONE, (Bio.Top(s.zones, 1, "d")[1] or {}).key)
        columns[1].y = columns[1].y + 10

        section(1, L.BIO_SEC_LIFE)
        line(1, L.BIO_DEATHS, n(s.deaths))
        line(1, L.BIO_LONGEST_LIFE, s.longestLife > 0 and time(s.longestLife) or nil)
        line(1, L.BIO_DEADLIEST_ZONE, (Bio.Top(s.zones, 1, "deaths")[1] or {}).key)
        line(1, L.BIO_TIME_DEAD, time(s.time.dead))
        if next(s.killers) and not (s.killers["?"] and U.Count(s.killers) == 1) then
            line(1, L.BIO_KILLED_BY, " ")
            top(1, s.killers, 3)
        end
        columns[1].y = columns[1].y + 10

        section(1, L.BIO_SEC_FIGHTS)
        line(1, L.BIO_KILLS, n(s.kills))
        line(1, L.BIO_UNIQUE_KILLS, n(U.Count(s.killed)))
        line(1, L.BIO_TIME_COMBAT, time(s.time.combat))
        if next(s.killed) then
            line(1, L.BIO_FAVORITE_PREY, " ")
            top(1, s.killed, 3)
        end
        line(1, L.BIO_XP_KILLS, n(s.xp.kill))
        line(1, L.BIO_XP_QUESTS, n(s.xp.quest))
        line(1, L.BIO_XP_EXPLORE, n(s.xp.explore))

        -- right column: supplies, wealth, items, trades, people, misc
        section(2, L.BIO_SEC_SUPPLIES)
        for _, kind in ipairs(Bio.SUPPLIES) do line(2, L["BIO_SUPPLY_" .. kind:upper()], n(s.supplies[kind])) end
        local favorite = Bio.Top(s.supplyItems, 1)[1]
        if favorite then line(2, L.BIO_FAVORITE_SUPPLY, Compat.GetItemName(favorite.key) or ("item:" .. favorite.key)) end
        columns[2].y = columns[2].y + 10

        section(2, L.BIO_SEC_WEALTH)
        local m = s.money
        line(2, L.BIO_MONEY_LOOT, Compat.FormatMoney(m.loot))
        line(2, L.BIO_MONEY_QUEST, Compat.FormatMoney(m.quest))
        line(2, L.BIO_MONEY_SOLD, Compat.FormatMoney(m.sold))
        line(2, L.BIO_MONEY_BOUGHT, Compat.FormatMoney(m.bought))
        line(2, L.BIO_MONEY_REPAIR, Compat.FormatMoney(m.repair))
        line(2, L.BIO_MONEY_TRAINER, Compat.FormatMoney(m.trainer))
        line(2, L.BIO_MONEY_FLIGHTS, Compat.FormatMoney(m.flights))
        line(2, L.BIO_MONEY_MAIL, Compat.FormatMoney(m.mailIn) .. "  /  " .. Compat.FormatMoney(m.mailOut))
        line(2, L.BIO_MONEY_AUCTION, Compat.FormatMoney(m.auctionIn) .. "  /  " .. Compat.FormatMoney(m.auctionOut))
        line(2, L.BIO_MONEY_TRADE, Compat.FormatMoney(m.tradeIn) .. "  /  " .. Compat.FormatMoney(m.tradeOut))
        columns[2].y = columns[2].y + 10

        section(2, L.BIO_SEC_ITEMS)
        line(2, L.BIO_ITEMS_LOOTED, n(s.items.looted))
        line(2, L.BIO_ITEMS_CREATED, n(s.items.created))
        line(2, L.BIO_ITEMS_RECEIVED, n(s.items.received))
        line(2, L.BIO_ITEMS_UNIQUE, n(s.items.unique))
        line(2, L.BIO_GATHER_HERBS, n(s.gather.herbalism))
        line(2, L.BIO_GATHER_ORE, n(s.gather.mining))
        line(2, L.BIO_GATHER_FISH, n(s.gather.fishing))
        line(2, L.BIO_GATHER_SKINS, n(s.gather.skinning))
        columns[2].y = columns[2].y + 10

        section(2, L.BIO_SEC_PEOPLE)
        line(2, L.BIO_DUELS_WON, n(s.duels.won))
        line(2, L.BIO_DUELS_LOST, n(s.duels.lost))
        line(2, L.BIO_DUELS_TOTAL, n(s.duels.won + s.duels.lost))
        line(2, L.BIO_GROUPED_WITH, n(U.Count(s.grouped)))
        line(2, L.BIO_TIME_GROUP, time(s.time.group))
        if next(s.rep) then
            line(2, L.BIO_REPUTATION, " ")
            top(2, s.rep, 3)
        end
        columns[2].y = columns[2].y + 10

        section(2, L.BIO_SEC_MISC)
        line(2, L.BIO_JUMPS, n(s.jumps))
        line(2, L.BIO_SPELLS, n(s.spells))
        line(2, L.BIO_TIME_AFK, time(s.time.afk))
        line(2, L.BIO_TIME_RESTING, time(s.time.resting))
        line(2, L.BIO_TIME_TAXI, time(s.time.taxi))

        -- the timeline, full width
        y = math.max(columns[1].y, columns[2].y) + 14
        local h = self.headers:Acquire()
        h:SetText(L.BIO_SEC_TIMELINE)
        h:SetPoint("TOPLEFT", 4, -y)
        h:SetWidth(width)
        y = y + 26
        local events = s.timeline
        if account then
            events = {}
            for _, stats in pairs(FC.db.bio) do
                for _, e in ipairs(stats.timeline) do events[#events + 1] = e end
            end
            table.sort(events, function(a, b) return a.t > b.t end)
        end
        if #events == 0 then
            local row = self.rows:Acquire()
            row:SetPoint("TOPLEFT", 4, -y)
            row:SetWidth(width)
            row.left:SetText(L.BIO_TIMELINE_EMPTY)
            row.right:SetText("")
            y = y + ROW
        end
        for i = 1, math.min(60, #events) do
            local e = events[i]
            local row = self.rows:Acquire()
            row:SetPoint("TOPLEFT", 4, -y)
            row:SetWidth(width)
            row.icon:Show()
            UI.SetIcon(row.icon, EVENT_ICONS[e.k] or "Interface\\Icons\\INV_Misc_Note_01")
            row.left:SetPoint("LEFT", 20, 0)
            row.left:SetText(U.Colorize(U.FormatDate(e.t), Theme:Hex("muted")) .. "   " .. U.Colorize(describeEvent(e), Theme:Hex("text")))
            row.right:SetText(U.Colorize((e.z or "") .. (e.l and ("  \194\183  " .. string.format(L.TIP_LEVEL, e.l)) or ""), Theme:Hex("muted")))
            y = y + ROW
        end
        area:SetContentHeight(y + 16)
        FC.MainWindow:PageChanged(self)
    end

    -- the numbers keep moving while you read: redraw now and then, only while shown
    page:SetScript("OnShow", function(self)
        self.ticker = C_Timer.NewTicker(10, function() FC:SafeCall("Biography:Refresh", self.Refresh, self) end)
    end)
    page:SetScript("OnHide", function(self)
        if self.ticker then self.ticker:Cancel() end
        self.ticker = nil
    end)
    return page
end
