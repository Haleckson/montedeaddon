-- Selected recipe materials. Bank stock is a per-character, dated snapshot.
SBL_Materials = {}
local M = SBL_Materials
local bankOpen, frame, selected, quantity = false, nil, nil, 1
local professionIDs = {Alchemy=171,Blacksmithing=164,Cooking=185,Enchanting=333,
    Engineering=202,["First Aid"]=129,Leatherworking=165,Mining=186,Tailoring=197}

local function Library()
    return LibStub and LibStub("LibProfessionDB-1.0", true)
end

local function Stock()
    SpellbookLevelsDB = SpellbookLevelsDB or {}
    local all = SpellbookLevelsDB.materialBanks or {}
    SpellbookLevelsDB.materialBanks = all
    local key = (UnitName("player") or "?") .. "-" .. (GetRealmName() or "?")
    all[key] = all[key] or { items={} }
    return all[key]
end

local function Count(id, bank)
    local fn = C_Item and C_Item.GetItemCount or GetItemCount
    if not fn then return nil end
    local ok, n = pcall(fn, id, bank or false, false, bank or false)
    if ok and type(n)=="number" then return n end
end

function M.SnapshotBank()
    if not bankOpen then return end
    local lib = Library()
    if not lib then return end
    local ids, items = {}, {}
    for _, profID in pairs(professionIDs) do
        for _, rec in pairs(lib:GetRecipes(profID) or {}) do
            for id in pairs(rec.reagents or {}) do ids[id]=true end
        end
    end
    if not next(ids) then return end
    for id in pairs(ids) do
        local bags, total = Count(id), Count(id,true)
        if bags == nil or total == nil then return end -- never save a partial snapshot
        items[id] = math.max(0,total-bags)
    end
    local stock=Stock()
    stock.items, stock.updated = items, time()
end

-- Pure calculation also used by regression tests. nil means unknown, never zero.
function M.Calculate(reagents, batch, bags, bank)
    local rows, bagCrafts, totalCrafts = {}, nil, nil
    local bagKnown, bankKnown = true, true
    for id, perCraft in pairs(reagents or {}) do
        if type(perCraft)=="number" and perCraft>0 then
            local b, k = bags[id], bank and bank[id]
            local need = perCraft * batch
            local total = b and k and b+k or nil
            rows[#rows+1] = {id=id,need=need,bags=b,bank=k,total=total,
                missing=total and math.max(0,need-total) or nil}
            if b then bagCrafts=math.min(bagCrafts or math.huge,math.floor(b/perCraft)) else bagKnown=false end
            if total then totalCrafts=math.min(totalCrafts or math.huge,math.floor(total/perCraft)) else bankKnown=false end
        end
    end
    table.sort(rows,function(a,b) return a.id<b.id end)
    return rows, bagKnown and bagCrafts or nil, bankKnown and totalCrafts or nil
end

local function NativeSelection()
    local form=ProfessionsFrame and ProfessionsFrame.CraftingPage and ProfessionsFrame.CraftingPage.SchematicForm
    if form and form.GetRecipeInfo then
        local ok,info=pcall(form.GetRecipeInfo,form)
        if ok and info and info.recipeID then return info.recipeID, info.name end
    end
    if C_TradeSkillUI and C_TradeSkillUI.GetSelectedRecipeID then
        local ok,id=pcall(C_TradeSkillUI.GetSelectedRecipeID)
        if ok and id and id > 0 then return id end
    end
    -- Classic-style profession windows expose a selected row rather than a schematic.
    if GetTradeSkillSelectionIndex and GetTradeSkillInfo then
        local index = GetTradeSkillSelectionIndex()
        if index and index > 0 then
            local name, kind = GetTradeSkillInfo(index)
            if kind ~= "header" then
                local link = GetTradeSkillRecipeLink and GetTradeSkillRecipeLink(index)
                local id = link and tonumber(link:match("enchant:(%d+)") or link:match("spell:(%d+)"))
                return id, name
            end
        end
    end
end

local function Preferences()
    local stock=Stock()
    stock.ui=stock.ui or {}
    return stock.ui
end
local Resolve
function M.ResolveEntry(entry)
    if not entry then return end
    local id = tonumber(entry.recipeID)
    local rec = id and Resolve(id, entry.prof)
    if rec and next(rec.reagents or {}) then return rec end
    -- Saved trainer/vendor entries may carry no recipe ID, or a teaching spell ID.
    -- Match an exact, unambiguous recipe name in the embedded profession dataset.
    local lib = Library()
    if not lib or not entry.name then return end
    local match
    local ids = entry.prof and professionIDs[entry.prof] and {professionIDs[entry.prof]} or professionIDs
    for _, profID in pairs(ids) do
        for _, candidate in pairs(lib:GetRecipes(profID) or {}) do
            if candidate.name == entry.name and next(candidate.reagents or {}) then
                if match and match ~= candidate then return end
                match = candidate
            end
        end
    end
    return match
end

Resolve = function(id, prof)
    local lib=Library()
    if not lib then return end
    if prof and professionIDs[prof] then
        local rec=lib:GetRecipe(professionIDs[prof],id)
        if rec then return rec end
    end
    for _, profID in pairs(professionIDs) do
        local rec=lib:GetRecipe(profID,id)
        if rec then return rec end
    end
end

local activeProfession, automatic = nil, true
local function RecipeChoices(prof)
    local lib = Library()
    local choices = {}
    if not lib or not professionIDs[prof] then return choices end
    for id, rec in pairs(lib:GetRecipes(professionIDs[prof]) or {}) do
        if next(rec.reagents or {}) then
            choices[#choices+1] = {recipeID=rec.spellID or rec.recipeID or id, name=rec.name, prof=prof,
                skill=rec.requiredSkill or 0}
        end
    end
    table.sort(choices,function(a,b)
        if a.skill ~= b.skill then return a.skill < b.skill end
        return (a.name or "") < (b.name or "")
    end)
    return choices
end

function M.SetProfession(prof)
    if not professionIDs[prof] or prof == activeProfession then return end
    activeProfession = prof
    if automatic then
        selected = RecipeChoices(prof)[1]
        M.Refresh()
    end
end

local function Text(parent,x,y,width,label)
    local fs=parent:CreateFontString(nil,"OVERLAY","GameFontNormalSmall")
    fs:SetPoint("TOPLEFT",x,y); fs:SetWidth(width); fs:SetJustifyH("LEFT")
    fs:SetText(label or "")
    return fs
end

function M.Refresh()
    if not frame or not frame:IsShown() then return end
    if automatic and not selected and activeProfession then selected=RecipeChoices(activeProfession)[1] end
    local id, name = NativeSelection()
    if automatic and (id or name) then
        local native={recipeID=id,name=name,prof=activeProfession}
        if M.ResolveEntry(native) then selected=native end
    end
    local rec = M.ResolveEntry(selected or {recipeID=id, name=name})
    local e=selected or {}
    local source=e.sourceName or e.source
    if not source and C_TradeSkillUI and C_TradeSkillUI.GetRecipeSourceText and (e.recipeID or id) then
        local ok,value=pcall(C_TradeSkillUI.GetRecipeSourceText,e.recipeID or id)
        if ok and type(value)=="string" and value~="" then source=value end
    end
    source=source or "Source not recorded"
    local location=e.sourceZone or "Location not recorded"
    if e.sourceX and e.sourceY then location=location..string.format(" (%.1f, %.1f)",e.sourceX*100,e.sourceY*100) end
    frame.details:SetText(source.." • "..location.."\n"..(e.prof or activeProfession or "Profession").." skill "..tostring(e.skill or (rec and rec.requiredSkill) or "?")..(e.level and e.level>0 and (" • Character level "..e.level) or ""))
    frame.recipe:SetText((rec and rec.name) or (selected and selected.name) or "Select a recipe")
    for _, row in ipairs(frame.rows) do row:Hide() end
    if not rec or not next(rec.reagents or {}) then
        frame.summary:SetText("Select a recipe with reagent data. You can click a recipe in Skill Levels.")
        frame.bankNote:SetText("")
        return
    end
    local stock=Stock()
    local bags={}
    for item in pairs(rec.reagents) do bags[item]=Count(item) end
    local rows,bagCrafts,totalCrafts=M.Calculate(rec.reagents,quantity,bags,stock.updated and stock.items)
    frame.summary:SetText("Material capacity: " .. (bagCrafts or "?") .. " crafts from bags; " .. (totalCrafts or "?") .. " with bank.")
    frame.bankNote:SetText(stock.updated and ("Bank snapshot: "..date("%b %d, %H:%M",stock.updated)..". Visit your bank to refresh.")
        or "Bank stock unknown. Open your bank once to record it.")
    for i,r in ipairs(rows) do
        local row=frame.rows[i]
        if not row then
            row=CreateFrame("Frame",nil,frame.content); row:SetSize(520,26)
            row.name=Text(row,0,0,180)
            row.values={}
            for col=1,5 do row.values[col]=Text(row,180+(col-1)*64,0,60) end
            frame.rows[i]=row
        end
        row:SetPoint("TOPLEFT",0,-(i-1)*26)
        local fn=C_Item and C_Item.GetItemInfo or GetItemInfo
        local name=fn and fn(r.id)
        if not name and C_Item and C_Item.RequestLoadItemDataByID then C_Item.RequestLoadItemDataByID(r.id) end
        row.name:SetText(name or ("Item "..r.id))
        local values={r.bags,r.bank,r.total,r.need,r.missing}
        for col=1,5 do row.values[col]:SetText(values[col]~=nil and tostring(values[col]) or "?") end
        if r.missing and r.missing>0 then row.values[5]:SetTextColor(1,.35,.3)
        else row.values[5]:SetTextColor(.8,.8,.8) end
        row:Show()
    end
    frame.content:SetHeight(math.max(1,#rows*26))
end

function M.Show(entry,owner,prof)
    automatic = not entry
    if prof then M.SetProfession(prof) end
    selected=entry or (activeProfession and RecipeChoices(activeProfession)[1])
    if not frame then
        frame=CreateFrame("Frame","SpellbookLevelsMaterials",UIParent,"BackdropTemplate")
        frame:SetSize(560,410); frame:SetPoint("CENTER"); frame:SetFrameStrata("DIALOG")
        frame:SetClampedToScreen(true); frame:SetMovable(true); frame:EnableMouse(true)
        frame:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=1})
        frame:SetBackdropColor(.04,.035,.025,.98); frame:SetBackdropBorderColor(.4,.32,.15,1)
        frame:RegisterForDrag("LeftButton"); frame:SetScript("OnDragStart",frame.StartMoving)
        frame:SetScript("OnDragStop",function(self)
            self:StopMovingOrSizing()
            local point,_,relative,x,y=self:GetPoint()
            Preferences().position={point,relative,x,y}
        end)
        local saved=Preferences().position
        if saved then frame:ClearAllPoints(); frame:SetPoint(saved[1],UIParent,saved[2],saved[3],saved[4]) end
        Text(frame,16,-14,420,"Recipe Details & Materials")
        local close=CreateFrame("Button",nil,frame,"UIPanelCloseButton")
        close:SetPoint("TOPRIGHT"); close:SetScript("OnClick",function() frame:Hide() end)
        frame.recipe=Text(frame,16,-42,370)
        local picker = CreateFrame("Button",nil,frame,"UIPanelButtonTemplate")
        picker:SetSize(135,22); picker:SetPoint("TOPRIGHT",-16,-36); picker:SetText("Choose recipe")
        picker:SetScript("OnClick",function(self)
            local choices = RecipeChoices(activeProfession or (selected and selected.prof))
            if MenuUtil and MenuUtil.CreateContextMenu then
                MenuUtil.CreateContextMenu(self,function(_,root)
                    for _, choice in ipairs(choices) do
                        local entry = choice
                        root:CreateButton(entry.name or "Recipe",function() automatic=false; selected=entry; M.Refresh() end)
                    end
                end)
            else
                local nextIndex = 1
                for i, choice in ipairs(choices) do
                    if selected and choice.name == selected.name then nextIndex=i % #choices + 1; break end
                end
                automatic=false; selected=choices[nextIndex]; M.Refresh()
            end
        end)
        frame.details=Text(frame,16,-68,524)
        frame.details:SetHeight(42)
        Text(frame,16,-122,140,"Number of crafts:")
        local input=CreateFrame("EditBox",nil,frame,"InputBoxTemplate")
        input:SetSize(70,22); input:SetPoint("TOPLEFT",175,-116); input:SetAutoFocus(false)
        input:SetNumeric(true); input:SetMaxLetters(4); quantity=math.max(1,math.min(9999,math.floor(tonumber(Preferences().quantity) or 1))); input:SetText(tostring(quantity))
        input:SetScript("OnTextChanged",function(self)
            quantity=math.max(1,math.min(9999,math.floor(tonumber(self:GetText()) or 1))); Preferences().quantity=quantity; M.Refresh()
        end)
        input:SetScript("OnEnterPressed",function(self) self:SetText(tostring(quantity)); self:ClearFocus() end)
        input:SetScript("OnEscapePressed",function(self) self:ClearFocus() end)
        frame.summary=Text(frame,16,-152,524)
        Text(frame,16,-183,180,"Material")
        for col,label in ipairs({"Bags","Bank","Total","Need","Missing"}) do Text(frame,196+(col-1)*64,-183,60,label) end
        local scroll=CreateFrame("ScrollFrame",nil,frame,"UIPanelScrollFrameTemplate")
        scroll:SetPoint("TOPLEFT",16,-208); scroll:SetPoint("BOTTOMRIGHT",-34,48)
        frame.content=CreateFrame("Frame",nil,scroll); frame.content:SetSize(520,1)
        scroll:SetScrollChild(frame.content)
        frame.rows={}; frame.bankNote=Text(frame,16,-376,528)
        frame:SetScript("OnShow",M.Refresh)
        local elapsed,lastID,lastName=0,nil,nil
        frame:SetScript("OnUpdate",function(_,dt)
            if selected and not automatic then return end
            elapsed=elapsed+dt
            if elapsed<.3 then return end
            elapsed=0
            local id,name=NativeSelection()
            if id~=lastID or name~=lastName then
                lastID,lastName=id,name
                if M.ResolveEntry({recipeID=id,name=name}) then
                    selected={recipeID=id,name=name}; M.Refresh()
                end
            end
        end)
        tinsert(UISpecialFrames,"SpellbookLevelsMaterials")
    end
    frame:Show(); M.Refresh()
end

local events=CreateFrame("Frame")
for _,event in ipairs({"BANKFRAME_OPENED","BANKFRAME_CLOSED","BAG_UPDATE_DELAYED","PLAYERBANKSLOTS_CHANGED","ITEM_DATA_LOAD_RESULT","TRADE_SKILL_LIST_UPDATE"}) do
    pcall(events.RegisterEvent,events,event)
end
local pending=false
events:SetScript("OnEvent",function(_,event)
    if event=="BANKFRAME_OPENED" then bankOpen=true
    elseif event=="BANKFRAME_CLOSED" then bankOpen=false end
    if pending then return end
    pending=true
    C_Timer.After(.15,function()
        pending=false
        if bankOpen then M.SnapshotBank() end
        M.Refresh()
    end)
end)
