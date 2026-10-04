local _, MI2 = ...
MI2.EntryMixin = {}

local HBD = LibStub("HereBeDragons-2.0")

function MI2.EntryMixin:Init( db, id, level, decode )
	if db == nil then error("Database required") end
	self.db = db.db
    self.id = id
	self.level = level
	if level == nil or id == nil then error("Id ("..(id or "nil")..") and Level ("..(level or nil)..")") end
	if decode == nil or decode == true then
		self:GetCharData()
		self:GetBasicMobData()
		self:GetItemList()
		self:GetLocations()
	end

	self.mobType = db.db.source[id].t
	if self.mobType and self.mobType > 10 then
		self.lowHpAction = floor(self.mobType / 10)
		self.mobType = self.mobType - self.lowHpAction * 10
	end

end

function MI2.EntryMixin:SaveAll()
--	print("SaveAll")
	self:SaveBasicInfo()
	self:SaveCharData()
	self:SaveLootItems()
	self:SaveLocations()
end

function MI2.EntryMixin:AddKill( time )
    self.kills = (self.kills or 0) + 1
	if not self.firstKill then
		self.firstKill = MI2.GetTime()
	end
	self.lastKill = MI2.GetTime()-self.firstKill
--	MI2.printf("AddKill() - %d - %d", self.kills, time)
    self:SaveCharData()
end

function MI2.EntryMixin:AddCurrency( loot, quantity)
	if not self.currencyList then
		self.currencyList = {}
	end

	self.currencyList[loot.ID] = (self.currencyList[loot.ID] or 0) + quantity
end

function MI2.EntryMixin:AddItem( loot, quantity, tradeSkillUsed )
	if not self.itemList then
		self.itemList = {}
	end
	if MobInfoConfig.SaveItems == 1 and loot.Quality >= MobInfoConfig.ItemsQuality
	then
		self.itemList[loot.ID] = (self.itemList[loot.ID] or 0) + quantity
	end

	-- record loot item quality
	if loot.Quality == 1 then
		self.r1 = (self.r1 or 0) + 1
	elseif loot.Quality == 2 then
		self.r2 = (self.r2 or 0) + 1
	elseif loot.Quality == 3 then
		self.r3 = (self.r3 or 0) + 1
	elseif loot.Quality == 4 then
		self.r4 = (self.r4 or 0) + 1
	elseif loot.Quality == 5 then
		self.r5 = (self.r5 or 0) + 1
	end

	if not tradeSkillUsed then
		local value = MI2.FindItemValue( loot.Link or loot.ID ) * quantity
		if value > 0 then
			self.itemValue = (self.itemValue or 0) + value
		end
	end
--	print("AddItem("..loot.ID..","..quantity..","..tostring(tradeSkillUsed)..") -> "..self.itemList[loot.ID])
end

function MI2.EntryMixin:SetXP(xp)
--	print("SetXP("..xp..") ")
	if self.xp ~= xp then
		self.xp = xp
		self:SaveCharData()
	end
end

function MI2.EntryMixin:AddCopper(copper)
    self.copper = (self.copper or 0) + copper
--	print("AddCopper("..copper..") -> "..self.copper)
end

function MI2.EntryMixin:AddLoot()
    self.loots = (self.loots or 0) + 1
--	print("AddLoots() -> "..self.loots)
end

function MI2.EntryMixin:AddEmptyLoot()
    self.emptyLoots = (self.emptyLoots or 0) + 1
--	print("AddEmptyLoot() -> "..self.emptyLoots)
end

function MI2.EntryMixin:AddSkin()
    self.skins = (self.skins or 0) + 1
	self.skinCount = (self.skinCount or 0) + 1
--	print("AddSkin() -> "..self.skins.."/"..self.skinCount)
end

function MI2.EntryMixin:AddCloth()
	self.clothCount = (self.clothCount or 0) + 1
--	print("AddCloth() -> "..self.clothCount)
end

function MI2.EntryMixin:SetLowHpAction(action)
--	print("SetLowHpAction("..action..")")
	if not self.lowHpAction then
    	self.lowHpAction = action
    	self:SaveBasicInfo()
	end
end

function MI2.EntryMixin:SetDamage(damage)
--	print("SetDamage("..damage..")")

	if not self.minDamage or self.minDamage <= 0 then
		self.minDamage, self.maxDamage = damage, damage
		self:SaveCharData() -- might not be needed once other are done
	elseif damage < self.minDamage then
		self.minDamage = damage
		self:SaveCharData() -- might not be needed once other are done
	elseif damage > self.maxDamage then
		self.maxDamage = damage
		self:SaveCharData() -- might not be needed once other are done
	end
end

function MI2.EntryMixin:SetDps(dps)
--	print("SetDps("..dps..") ")
	if not self.dps then self.dps = floor(dps) end
	local newDps = floor( ((2.0 * self.dps) + dps) / 3.0 )
	if self.dps ~= newDps then
		self.dps = newDps
		self:SaveCharData()
	end
end

function MI2.EntryMixin:LevelData()
	local levelData

	if self.level then
		local idData = self.db.source[self.id]

		if idData == nil then
			idData = {}
			self.db.source[self.id] = idData
		end

		levelData = idData[self.level]

		if levelData == nil then
			levelData = {}
			idData[self.level] = levelData
		end
	end
	return levelData
end

function MI2.EntryMixin:SaveCharData()
--	MI2.printf("SaveCharData "..self.id.."["..self.level.."]")
	local charSource
	local charData = self.db.character[MI2_PlayerName]
	if charData == nil then
		charData = {}
		self.db.character[MI2_PlayerName] = charData
	end
	if charData then
		charSource = charData[self.id]
		if charSource == nil then
			charSource = {}
			charData[self.id] = charSource
		end
	end

	local charInfo = {}
	charInfo.kc  = self.kills
	charInfo.mnd = self.minDamage
	charInfo.mxd = self.maxDamage
	charInfo.dps = self.dps
	charInfo.xp  = self.xp
	charInfo.sc  = self.skins
	charInfo.fk  = self.firstKill
	charInfo.lk  = self.lastKill
	charSource[self.level] = charInfo
end

function MI2.EntryMixin:GetCharData()
	local charData = self.db.character[MI2_PlayerName]
	if charData then
		local charSource = charData[self.id]
		if charSource then
			local charInfo = charSource[self.level]
			if charInfo then
				self.kills		= charInfo.kc
				self.minDamage	= charInfo.mnd
				self.maxDamage	= charInfo.mxd
				self.dps	    = charInfo.dps
				self.xp			= charInfo.xp
				self.skins		= charInfo.sc
				self.firstKill	= charInfo.fk
				self.lastKill	= charInfo.lk
			end
		end
	end
end

function MI2.EntryMixin:GetBasicMobData()
	local sourceInfo = self:LevelData()
	self.loots		= sourceInfo.lc
	self.emptyLoots	= sourceInfo.ec
	self.copper		= sourceInfo.cp
	self.itemValue	= sourceInfo.iv
	self.clothCount	= sourceInfo.cc
	self.skinCount	= sourceInfo.sc or 0 -- used for determine if cached or not

	self.r1	= sourceInfo.q1
	self.r2	= sourceInfo.q2
	self.r3	= sourceInfo.q3
	self.r4	= sourceInfo.q4
	self.r5	= sourceInfo.q5
end

function MI2.EntryMixin:SaveBasicInfo()

	-- encode the mobs low hp action within the mob type value
	local mobType = self.mobType
	if self.lowHpAction then
		mobType = (mobType or 1) + self.lowHpAction * 10
	end

	-- no need to store a mobType of 1 (normal mobs)
	if mobType == 1 then
		mobType = nil
	end

	local skinCount = self.skinCount
	if skinCount == 0 then skinCount = nil end

	local sourceInfo = self:LevelData()
	sourceInfo.lc = self.loots
	sourceInfo.ec = self.emptyLoots
	sourceInfo.cp = self.copper
	sourceInfo.iv = self.itemValue
	sourceInfo.cc = self.clothCount
	sourceInfo.sc = skinCount
	self.db.source[self.id].t = mobType

	sourceInfo.q1 = self.r1
	sourceInfo.q2 = self.r2
	sourceInfo.q3 = self.r3
	sourceInfo.q4 = self.r4
	sourceInfo.q5 = self.r5

end

function MI2.EntryMixin:GetItemList()
	local l = self:LevelData().i
	if l then
		self.itemList = CopyTable(l)
	else
		self.itemList = {}
	end

	l = self:LevelData().c
	if l then
		self.currencyList = CopyTable(l)
	else
		self.currencyList = {}
	end
end

function MI2.EntryMixin:SaveLootItems()
	if self.itemList and next(self.itemList) then
		self:LevelData().i = CopyTable(self.itemList)
	end

	if self.currencyList and next(self.currencyList) then
		self:LevelData().c = CopyTable(self.currencyList)
	end
end

-----------------------------------------------------------------------------
-- add the data for two mobs
--
function MI2.EntryMixin:Union( entry )
	if entry == nil or entry.level == nil then return end
	if entry.id ~= self.id then
		if self.ids == nil then
			self.ids = { self.id, entry.id }
			self.id = nil
		else
			local found = false
			for _,id in next, self.ids do
				if id == entry.id then
					found = true
					break
				end
			end
			if not found then
				self.ids[#self.ids+1] = entry.id
			end
		end
	end
	self.minLevel = min( self.minLevel or self.level, entry.level)
	self.maxLevel = max( self.maxLevel or self.level, entry.level)
	if ( self.minLevel ~= self.maxLevel) then
		self.levelInfo =  self.minLevel.."-"..self.maxLevel
		self.level = nil
	else
		self.levelInfo = self.level
	end

	-- add up basic mob data
	if entry.loots then self.loots = (self.loots or 0) + entry.loots end
	if entry.kills then self.kills = (self.kills or 0) + entry.kills end
	if entry.emptyLoots then self.emptyLoots = (self.emptyLoots or 0) + entry.emptyLoots end
	if entry.clothCount then self.clothCount = (self.clothCount or 0) + entry.clothCount end
	if entry.copper then self.copper = (self.copper or 0) + entry.copper end
	if entry.itemValue then self.itemValue = (self.itemValue or 0) + entry.itemValue end
	if entry.skinCount then self.skinCount = (self.skinCount or 0) + entry.skinCount end
	if entry.skins then self.skins = (self.skins or 0) + entry.skins end
	if entry.r1 then self.r1 = (self.r1 or 0) + entry.r1 end
	if entry.r2 then self.r2 = (self.r2 or 0) + entry.r2 end
	if entry.r3 then self.r3 = (self.r3 or 0) + entry.r3 end
	if entry.r4 then self.r4 = (self.r4 or 0) + entry.r4 end
	if entry.r5 then self.r5 = (self.r5 or 0) + entry.r5 end
	if entry.mobType then self.mobType = entry.mobType end
	if not self.xp then self.xp = entry.xp end
	if not self.lowHpAction then self.lowHpAction = entry.lowHpAction end

	local firstKill, lastKill
	if self.firstKill then
		firstKill = self.firstKill
	end
	if self.lastKill then
		lastKill = self.lastKill + self.firstKill
	end
	if entry.firstKill then
		if not firstKill or entry.firstKill < firstKill then
			firstKill = entry.firstKill
		end
		if not lastKill or entry.firstKill > lastKill then
			lastKill = entry.firstKill
		end
	end
	if entry.lastKill then
		local t = entry.firstKill + entry.lastKill
		if not firstKill or t < firstKill then
			firstKill = t
		end
		if not lastKill or t > lastKill then
			lastKill = t
		end
	end

	if firstKill then self.firstKill = firstKill end
	if lastKill then self.lastKill = lastKill - firstKill end

	self:UnionLocation(entry)

	-- combine DPS
	if not self.dps then
		self.dps = entry.dps
	elseif entry.dps then
		self.dps = floor( ((2.0 * self.dps) + entry.dps) / 3.0 )
	end

	-- combine minimum and maximum damage	
	if (entry.minDamage or 99999) < (self.minDamage or 99999) then
		self.minDamage = entry.minDamage
	end
	if (entry.maxDamage or 0) > (self.maxDamage or 0) then
		self.maxDamage = entry.maxDamage
	end

	-- add loot item tables
	if entry.itemList then
		if not self.itemList then self.itemList = {} end
		for itemID, amount in pairs(entry.itemList) do
			self.itemList[itemID] = (self.itemList[itemID] or 0) + amount
		end
	end

	-- add loot currency tables
	if entry.currencyList then
		if not self.currencyList then self.currencyList = {} end
		for currencyID, amount in pairs(entry.currencyList) do
			self.currencyList[currencyID] = (self.currencyList[currencyID] or 0) + amount
		end
	end

end

function MI2.EntryMixin:UnionLocation(entry)
	if entry.locations then
		if not self.locations then
			self.locations = {}
		end

		for entryMapID, entryLocationData in pairs(entry.locations) do
			if type(entryMapID) == "number" then
				local locationData = self.locations[entryMapID]
				if not locationData then
					locationData = {}
					self.locations[entryMapID] = entryLocationData --DeepCopy?
				else
					for _, ec in next,entryLocationData do
						local x = ec[1]
						local y = ec[2]
						local found = false
						for _, c in next,locationData do
							local distance = HBD:GetZoneDistance(entryMapID,x/100,y/100,entryMapID,c[1]/100,c[2]/100)
							if distance < 15 then
								found = true
								break
							end
						end
						if not found then
							locationData[#locationData+1] = {x,y}
							if self.location and self.location.m == entryMapID then
								if x/1 < self.location.x1 then self.location.x1 = x/1 end
								if x/1 > self.location.x2 then self.location.x2 = x/1 end
								if y/1 < self.location.y1 then self.location.y1 = y/1 end
								if y/1 > self.location.y2 then self.location.y2 = y/1 end
							end
						end
					end
				end
			end
		end
	end
end

function MI2.EntryMixin:GetLocations()
	local sourceData = self.db.location[self.id]
	if sourceData then
		self.locations = CopyTable(sourceData)
		local zone = self.locations.zone
		if zone then
			self.location = {}
			self.location.z	= zone[1] or 0
			self.location.m = zone[2]
			if zone[2] then
				local locData = self.locations[zone[2]]
				if locData then
					for _, c in next,locData do
						if self.location.x1 == nil then
							self.location.x1 = c[1]
							self.location.x2 = c[1]
							self.location.y1 = c[2]
							self.location.y2 = c[2]
						else
							if c[1] < self.location.x1 then self.location.x1 = c[1] end
							if c[1] > self.location.x2 then self.location.x2 = c[1] end
							if c[2] < self.location.y1 then self.location.y1 = c[2] end
							if c[2] > self.location.y2 then self.location.y2 = c[2] end
						end
					end
				end
			end
		end
	end
end

function MI2.EntryMixin:SaveLocations()
	if self.locations then
		self.db.location[self.id] = CopyTable(self.locations)
	end
end

function MI2.EntryMixin:AddLocation()
	local mapID = C_Map.GetBestMapForUnit("player")
	if mapID and mapID > 0 then
		if not self.locations then
			self.locations = {}
		end
		local locationData = self.locations[mapID]
		if not locationData then
			locationData = {}
			self.locations[mapID] = locationData
		end

		local x, y = GetPlayerMapPosition(mapID)
		if x == 0 and y == 0 then return end

		local found = false
		for _,c in next,locationData do
			local distance = HBD:GetZoneDistance(mapID,x/100,y/100,mapID,c[1]/100,c[2]/100)
			if distance < 15 then
				found = true
				break
			end
		end
		if not found then
			locationData[#locationData+1] = {x,y}
			self.locations.zone = {MI2.CurZone,mapID}
			return true
    	end
	end
	return false
end
