local addonName, MCF = ...
local function T(key) return MCF:T(key) end

local frame=CreateFrame("Frame")

local function EscapePattern(s)
    return (tostring(s or ""):gsub("([%(%)%.%%%+%-%*%?%[%]%^%$])","%%%1"))
end

local function AmountPattern(fmt)
    if type(fmt)~="string" then return nil end
    local p=EscapePattern(fmt)
    p=p:gsub("%%%%d","(%%d+)")
    return p
end

local GOLD_PATTERN=AmountPattern(_G.GOLD_AMOUNT or "%d Gold")
local SILVER_PATTERN=AmountPattern(_G.SILVER_AMOUNT or "%d Silver")
local COPPER_PATTERN=AmountPattern(_G.COPPER_AMOUNT or "%d Copper")

local function CoinTextToCopper(text)
    if type(text)~="string" then return 0 end
    local gold=GOLD_PATTERN and tonumber(text:match(GOLD_PATTERN)) or 0
    local silver=SILVER_PATTERN and tonumber(text:match(SILVER_PATTERN)) or 0
    local copper=COPPER_PATTERN and tonumber(text:match(COPPER_PATTERN)) or 0
    return (gold or 0)*10000+(silver or 0)*100+(copper or 0)
end

local lastLootSignature,lastLootAt=nil,0
function MCF:CaptureLootedGold()
    if not MyCharForeverDB or not GetNumLootItems or not GetLootSlotInfo then return end
    local total=0
    local sig={}
    for slot=1,(GetNumLootItems() or 0) do
        local _,name,_,_,_,_,_,_,_,isCoin=GetLootSlotInfo(slot)
        if isCoin then
            local amount=CoinTextToCopper(name)
            if amount>0 then
                total=total+amount
                sig[#sig+1]=tostring(slot)..":"..tostring(name)
                if GetLootSourceInfo then
                    local sources={GetLootSourceInfo(slot)}
                    for i=1,#sources,2 do sig[#sig+1]=tostring(sources[i]) end
                end
            end
        end
    end
    if total<=0 then return end
    local signature=table.concat(sig,"|")
    local now=GetTime()
    if signature==lastLootSignature and now-lastLootAt<1.5 then return end
    lastLootSignature,lastLootAt=signature,now

    MyCharForeverDB.goldLooted=MyCharForeverDB.goldLooted or {total=0,byLevel={}}
    local gl=MyCharForeverDB.goldLooted
    gl.total=(tonumber(gl.total) or 0)+total
    gl.byLevel=gl.byLevel or {}
    local lvl=UnitLevel("player") or 0
    gl.byLevel[lvl]=(tonumber(gl.byLevel[lvl]) or 0)+total
    gl.last={time=time(),amount=total,level=lvl,zone=GetZoneText(),subZone=GetSubZoneText()}
    if self.RefreshUI then self:RefreshUI() end
end

-- Daily category totals only: no item, recipe, or spell details are stored.
-- Context is deliberately conservative; uncertain changes remain "other".
local lastMoney=nil
local activeContext=nil
local recentContext=nil
local recentUntil=0
local function SetContext(category,seconds)
    recentContext=category
    recentUntil=GetTime()+(seconds or 2)
end
-- One place for every gold category. Short "recent" contexts (a click just happened) win over open windows.
-- Whatever cannot be placed stays "other"; changes while offline are never sorted.
local function GoldCategory(delta)
    local recent=recentContext and GetTime()<=recentUntil and recentContext or nil
    if delta<0 then
        if recent=="mount" or recent=="riding" or recent=="respec" or recent=="repair" or recent=="bankSlot" or recent=="taxi" then return recent end
        if activeContext=="merchant" and InRepairMode and InRepairMode() then return "repair" end
    else
        if recent=="auctionSale" then return "auction" end
    end
    if activeContext=="merchant" then
        return delta<0 and "merchantBuy" or "merchantSell"
    elseif activeContext=="trainer" then return delta<0 and "training" or "other"
    elseif activeContext=="auction" then return "auction"
    elseif activeContext=="mail" then return "mail"
    elseif activeContext=="trade" then return "trade"
    elseif activeContext=="guildBank" then return "guildBank"
    elseif activeContext=="bank" then return delta<0 and "bankSlot" or "other"
    elseif activeContext=="taxi" and delta<0 then return "taxi"
    elseif recent then
        if recent=="loot" and delta>0 then return "loot" end
        if recent=="quest" and delta>0 then return "quest" end
    end
    return "other"
end
-- Gold by level: goldByLevel[level].src[category]={e=earned,s=spent}, plus the biggest single gain / spending of the level.
local function RecordLevelCategory(gl,category,delta)
    gl.src=gl.src or {}
    local c=gl.src[category] or {e=0,s=0}
    gl.src[category]=c
    if delta>0 then
        c.e=c.e+delta
        if delta>(gl.maxEarn and gl.maxEarn.amount or 0) then gl.maxEarn={amount=delta,category=category,time=time()} end
    else
        c.s=c.s-delta
        if -delta>(gl.maxSpend and gl.maxSpend.amount or 0) then gl.maxSpend={amount=-delta,category=category,time=time()} end
    end
end

local function DayKey(ts)
    return date("%Y-%m-%d",ts or time())
end

function MCF:RecordGold()
    if not MyCharForeverDB then return end
    MyCharForeverDB.goldHistory=MyCharForeverDB.goldHistory or {}

    local now=time()
    local key=DayKey(now)
    local amount=GetMoney() or 0
    MyCharForeverDB.goldByLevel=MyCharForeverDB.goldByLevel or {}
    local lvl=UnitLevel("player") or 0
    local gl=MyCharForeverDB.goldByLevel[lvl] or {earned=0,spent=0}
    MyCharForeverDB.goldByLevel[lvl]=gl
    local delta=lastMoney and (amount-lastMoney) or 0
    if lastMoney~=nil then
        if delta>0 then gl.earned=(gl.earned or 0)+delta
        elseif delta<0 then gl.spent=(gl.spent or 0)+(-delta) end
    end
    lastMoney=amount
    local category=delta~=0 and GoldCategory(delta) or nil
    if category then RecordLevelCategory(gl,category,delta) end
    local day=MyCharForeverDB.goldHistory[key]

    if not day then
        day={
            date=key,
            first=amount,
            last=amount,
            min=amount,
            max=amount,
            firstTime=now,
            lastTime=now,
            level=UnitLevel("player"),
        }
        MyCharForeverDB.goldHistory[key]=day
    else
        day.last=amount
        day.lastTime=now
        day.level=UnitLevel("player")
        if amount < (day.min or amount) then day.min=amount end
        if amount > (day.max or amount) then day.max=amount end
    end

    -- Only changes observed during this running session are categorized.
    -- Do not infer transactions across logouts or from older day snapshots.
    if delta~=0 then
        day.categories=day.categories or {}
        day.categories[category]=(day.categories[category] or 0)+delta
        day.categorizedNet=(day.categorizedNet or 0)+delta
    end
    MyCharForeverDB.stats=MyCharForeverDB.stats or {}
    MyCharForeverDB.stats.lastKnownMoney=amount

    if self.RefreshUI then self:RefreshUI() end
end

function MCF:GetGoldDays()
    local days={}
    if not MyCharForeverDB then return days end
    for key,day in pairs(MyCharForeverDB.goldHistory or {}) do
        days[#days+1]={key=key,data=day}
    end
    table.sort(days,function(a,b) return a.key < b.key end)
    return days
end

frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("PLAYER_MONEY")
-- Windows that make an exchange of gold belong to one category while they are open.
local WINDOWS={
    MERCHANT_SHOW="merchant", TRAINER_SHOW="trainer", AUCTION_HOUSE_SHOW="auction", MAIL_SHOW="mail",
    TRADE_SHOW="trade", GUILDBANKFRAME_OPENED="guildBank", BANKFRAME_OPENED="bank", TAXIMAP_OPENED="taxi",
}
local WINDOW_CLOSED={
    MERCHANT_CLOSED="merchant", TRAINER_CLOSED="trainer", AUCTION_HOUSE_CLOSED="auction", MAIL_CLOSED="mail",
    TRADE_CLOSED="trade", GUILDBANKFRAME_CLOSED="guildBank", BANKFRAME_CLOSED="bank", TAXIMAP_CLOSED="taxi",
}
for event in pairs(WINDOWS) do pcall(function() frame:RegisterEvent(event) end) end
for event in pairs(WINDOW_CLOSED) do pcall(function() frame:RegisterEvent(event) end) end
for _,event in ipairs({"QUEST_TURNED_IN","LOOT_READY"}) do
    pcall(function() frame:RegisterEvent(event) end)
end
frame:SetScript("OnEvent",function(_,event)
    if not MyCharForeverDB then return end
    if event=="LOOT_READY" then
        SetContext("loot",1.5)
        MCF:CaptureLootedGold()
    elseif WINDOWS[event] then activeContext=WINDOWS[event]
    elseif WINDOW_CLOSED[event] then
        if activeContext==WINDOW_CLOSED[event] then activeContext=nil end
        -- a flight is paid when the destination is chosen, the map closes right after
        if event=="TAXIMAP_CLOSED" then SetContext("taxi",3) end
    elseif event=="QUEST_TURNED_IN" then SetContext("quest",2)
    elseif event=="PLAYER_ENTERING_WORLD" then
        -- Re-establish baseline after logging in; never categorize offline changes.
        lastMoney=nil; activeContext=nil; recentContext=nil
        MCF:RecordGold()
    elseif event=="PLAYER_MONEY" then MCF:RecordGold() end
end)

-- Clicks that name the reason of a payment. Each hook only sets a short context; a missing function is simply skipped.
local function Hook(fname,fn)
    if type(_G[fname])=="function" and hooksecurefunc then pcall(hooksecurefunc,fname,function(...) pcall(fn,...) end) end
end
Hook("BuyMerchantItem",function(index)
    local link=GetMerchantItemLink and GetMerchantItemLink(index)
    local info=GetItemInfoInstant or (C_Item and C_Item.GetItemInfoInstant)
    if not link or not info then return end
    local _,_,_,_,_,classID,subClassID=info(link)
    if classID==15 and subClassID==5 then SetContext("mount",3) end -- Miscellaneous > Mount
end)
Hook("BuyTrainerService",function(index)
    local name=GetTrainerServiceInfo and GetTrainerServiceInfo(index)
    local n=tostring(name or ""):lower()
    if n:find("riding",1,true) or n:find("reit",1,true) then SetContext("riding",3) end
end)
Hook("ConfirmTalentWipe",function() SetContext("respec",3) end)
Hook("RepairAllItems",function() SetContext("repair",3) end)
Hook("PurchaseSlot",function() SetContext("bankSlot",3) end)
Hook("TakeTaxiNode",function() SetContext("taxi",5) end)
local function MailSale(index)
    local invoice=GetInboxInvoiceInfo and GetInboxInvoiceInfo(index)
    if invoice=="seller" then SetContext("auctionSale",3) end
end
Hook("TakeInboxMoney",MailSale)
Hook("AutoLootMailItem",MailSale)

function MCF:SimulateGoldHistory(daysToCreate)
    if not MyCharForeverDB then return end
    MyCharForeverDB.goldHistory=MyCharForeverDB.goldHistory or {}
    daysToCreate=daysToCreate or 200

    local now=time()
    local balance=12500 -- 1g 25s starting test balance
    for offset=daysToCreate,1,-1 do
        local ts=now-(offset*86400)
        local key=date("%Y-%m-%d",ts)
        -- deterministic wave + long-term growth; useful for visually testing the chart.
        local daily=math.floor(180 + (offset % 11)*37 + math.sin(offset/7)*420)
        balance=math.max(0,balance+daily)
        local first=math.max(0,balance-math.floor(daily*0.7))
        local low=math.max(0,math.min(first,balance)-((offset*23)%350))
        local high=math.max(first,balance)+((offset*41)%900)
        MyCharForeverDB.goldHistory[key]={
            date=key,first=first,last=balance,min=low,max=high,
            firstTime=ts,lastTime=ts+3600,
            level=math.max(1,math.min(60,math.floor((daysToCreate-offset)/10)+1)),
            simulated=true,
        }
    end
    print("|cff00ccffMyCharForever|r: "..daysToCreate..T(" simulated gold days created."))
    if self.RefreshUI then self:RefreshUI() end
end

function MCF:ClearSimulatedGoldHistory()
    if not MyCharForeverDB then return end
    for key,day in pairs(MyCharForeverDB.goldHistory or {}) do
        if day.simulated then MyCharForeverDB.goldHistory[key]=nil end
    end
    print("|cff00ccffMyCharForever|r: "..T("Simulated gold days removed."))
    if self.RefreshUI then self:RefreshUI() end
end
