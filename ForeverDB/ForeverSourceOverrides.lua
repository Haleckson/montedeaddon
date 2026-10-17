-- Generated from persistent owner-approved corrections. Load after enrichment.
local patches={}
local generatedAt="2026-10-09"

local source=ForeverSourceData
ForeverCorrectionsSummary225={applied={},skipped={}}
if type(source)~="table" then return end
local correctedNPCs={}
local buckets={item="items",npc="npcs",quest="quests",recipe="recipes",object="objects",dungeon="dungeons"}
local function find(e)
 local bucket=source[buckets[e.kind]] or {}
 if e.kind~="dungeon" then return bucket[e.id] or bucket[tostring(e.id)] end
 for _,r in pairs(bucket) do if type(r)=="table" and r.name==e.id then return r end end
end
for _,e in ipairs(patches) do
 local record=find(e)
 local reason=type(record)~="table" and "Record missing" or nil
 if not reason and e.field=="rates" then
  for _,rate in ipairs(e.values.dropRates) do
   local found=false
   for _,s in ipairs(record.sources or {}) do if s.type=="drop" and tonumber(s.id)==rate.sourceID then found=true end end
   if not found then reason="Drop source missing" break end
  end
 end
 if reason then
  table.insert(ForeverCorrectionsSummary225.skipped,{kind=e.kind,id=e.id,field=e.field,reason=reason})
 else
  if e.field=="locations" then
   local key=e.kind=="quest" and "giverLocations" or e.kind=="dungeon" and "entranceLocations" or "locations"
   record[key]=e.values.locations
   -- Clear stale single-coordinate fields so the reviewed locations take precedence.
   record.x=nil record.y=nil record.uiMapID=nil
   if e.kind=="npc" then source.npcLocations=source.npcLocations or {} source.npcLocations[e.id]=e.values.locations correctedNPCs[e.id]=e.values.locations end
  elseif e.field=="sources" then
   record.sources=record.sources or {}
   for _,patch in ipairs(e.values.sources) do
    local target
    for _,s in ipairs(record.sources) do if s.type==patch.type and tonumber(s.id)==patch.id then target=s break end end
    if not target then target={} table.insert(record.sources,target) end
    for k,v in pairs(patch) do target[k]=v end
   end
  elseif e.field=="rates" then
   for _,rate in ipairs(e.values.dropRates) do
    for _,s in ipairs(record.sources or {}) do if s.type=="drop" and tonumber(s.id)==rate.sourceID then s.chance=rate.chance s.dropChance=rate.chance end end
   end
  else for k,v in pairs(e.values) do record[k]=v end end
  record.correctionSource="Owner-approved override"
  record.correctionAppliedAt=generatedAt
  record.correctionEvidence=e.evidence
  if e.verifiedAt then record.verifiedAt=e.verifiedAt end
  table.insert(ForeverCorrectionsSummary225.applied,{kind=e.kind,id=e.id,field=e.field})
 end
end

-- Refresh embedded acquisition markers once after all NPC coordinate overrides.
if next(correctedNPCs) then
 for _,item in pairs(source.items or {}) do
  for _,s in ipairs(item.sources or {}) do
   if s.type=="drop" or s.type=="vendor" or s.type=="pickpocket" or s.type=="skinning" then
    local points=correctedNPCs[tonumber(s.id)]
    if points then
     s.locations=points
     s.uiMapID=points[1].uiMapID s.x=points[1].x s.y=points[1].y
    end
   end
  end
 end
end

