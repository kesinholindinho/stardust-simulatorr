local RS = game:GetService("ReplicatedStorage")
local function ensureRemote(name)
	if not RS:FindFirstChild(name) then
		local re = Instance.new("RemoteEvent")
		re.Name = name
		re.Parent = RS
	end
end
ensureRemote("BossAttackEvent")
ensureRemote("BossSync")
ensureRemote("CrystalBossSync")

-- CrystalTreeBossSystem - Handles the Crystal Tree boss HP, combat system, and gacha rewards
-- Integrates with GameLogic for player data and damage calculations

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")

local ok, err = pcall(function()
	while not _G.playerData do task.wait(0.5) end

-- ============================================
-- CONFIGURATION
-- ============================================
local CONFIG = {
	RESPAWN_TIME = 600, -- 10 minutes in seconds
	BASE_HP_MULTIPLIER = 500, -- HP formula multiplier
	AREA_CHECK_INTERVAL = 2, -- How often to check for players in area
	BOSS_MODEL_PATH = "Workspace.Crstal Tree pasta.Boss Crystal Tree",
	AREA_PART_PATH = "Workspace.Crstal Tree pasta.Area Crystal",
	-- REBALANCED: Reduced rewards for better economy balance
	REWARD_STARDUST = 3000, -- Base stardust reward for defeating boss (was 5000)
	REWARD_STARCOINS = 300, -- Base starcoins reward for defeating boss (was 500)
	GACHA_SHOTS_PER_DEFEAT = 3, -- Shots given when boss is defeated (was 5)
	HIGH_DAMAGE_THRESHOLD = 0.30, -- 30% of total HP = high damage
	HIGH_DAMAGE_BONUS = 5, -- +5% chance on scaling rewards for high damage
	
	-- Drop system configuration (legacy, kept for backwards compat)
	DROPS = {
		{type = "stardust", amount = 500, chance = 100, color = Color3.fromRGB(255, 255, 100)}, -- 100% chance
		{type = "starcoins", amount = 35, chance = 80, color = Color3.fromRGB(255, 200, 50)}, -- 80% chance
		{type = "pet", name = "Crystal Pet", emoji = "💎", rarity = "Lendario", multiplier = 5.0, chance = 30, color = Color3.fromRGB(100, 200, 255)} -- 30% chance
	},
	
	-- Gacha reward table - REBALANCED: Reduced amounts for better economy
	GACHA_REWARDS = {
		{type = "stardust", name = "300 Stardust", emoji = "★", baseAmount = 300, maxAmount = 900, chance = 100, scalesWithDamage = true, color = Color3.fromRGB(255, 255, 100)},
		{type = "starcoins", name = "25 Starcoins", emoji = "◆", baseAmount = 25, maxAmount = 75, chance = 80, scalesWithDamage = true, color = Color3.fromRGB(255, 200, 50)},
		{type = "item", name = "Crystal Shard", emoji = "◈", chance = 60, scalesWithDamage = false, color = Color3.fromRGB(100, 220, 255)},
		{type = "item", name = "XP Boost", emoji = "▲", chance = 50, scalesWithDamage = false, color = Color3.fromRGB(180, 100, 255)},
		{type = "pet", name = "PetMiniCrystal", emoji = "✦", rarity = "Raro", multiplier = 2.0, chance = 12, scalesWithDamage = true, color = Color3.fromRGB(100, 200, 255)},
		{type = "pet", name = "PetCrystalTree", emoji = "✤", rarity = "Lendario", multiplier = 6.0, chance = 4, scalesWithDamage = true, color = Color3.fromRGB(255, 200, 50)}
	}
}

-- ============================================
-- BOSS STATE
-- ============================================
local bossState = {
	currentHP = 0,
	maxHP = 0,
	isAlive = false,
	isUnderground = false,
	respawnEndTime = 0,
	playersInArea = {}, -- Players currently in the boss area
	totalDamageDealt = {} -- Track damage per player for rewards
}

-- ============================================
-- CREATE REMOTEEVENTS
-- ============================================
local function getOrCreateRemote(name)
	local remote = ReplicatedStorage:FindFirstChild(name)
	if not remote then
		remote = Instance.new("RemoteEvent")
		remote.Name = name
		remote.Parent = ReplicatedStorage
	end
	return remote
end

local crystalBossSync = getOrCreateRemote("CrystalBossSync")
local gameAction = ReplicatedStorage:FindFirstChild("GameAction")

-- ============================================
-- HELPER FUNCTIONS
-- ============================================

-- Get player's clickPower from GameLogic's playerData
local function getPlayerClickPower(player)
	local playerData = _G.playerData
	if not playerData then
		warn("[CrystalBoss] _G.playerData not found - GameLogic may not be loaded")
		return 1
	end
	
	local data = playerData[player]
	if not data then
		warn("[CrystalBoss] No data found for player:", player.Name)
		return 1
	end
	
	return data.clickPower or 1
end

-- Calculate player's damage bonus (pets + upgrades) - mirrors GameLogic.calculateMultiplier
local function calculatePlayerBonus(player)
	local playerData = _G.playerData
	if not playerData then return 0 end
	
	local data = playerData[player]
	if not data then return 0 end
	
	local bonus = 0
	
	-- Add pet multipliers
	if data.equippedPets and data.ownedPets then
		for _, petId in ipairs(data.equippedPets) do
			for _, pet in ipairs(data.ownedPets) do
				if pet.id == petId then
					bonus = bonus + (pet.multiplier or 0)
					break
				end
			end
		end
	end
	
	-- Add upgrade multipliers (Click Power adds 5% per level)
	if data.upgrades then
		bonus = bonus + (data.upgrades["Click Power"] or 0) * 0.05
	end
	
	-- Add supernova multiplier
	if data.supernova and data.supernova.multiplier then
		bonus = bonus + (data.supernova.multiplier - 1.0)
	end
	
	return bonus
end

-- Calculate full click damage for a player
local function calculateClickDamage(player)
	local clickPower = getPlayerClickPower(player)
	local bonus = calculatePlayerBonus(player)
	return clickPower + bonus
end

-- Check if player is in the Crystal Area
local function isPlayerInArea(player)
	local character = player.Character
	if not character then return false end
	
	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoidRootPart then return false end
	
	local areaPart = game:GetService("Workspace"):FindFirstChild("Crstal Tree pasta")
	if not areaPart then return false end
	areaPart = areaPart:FindFirstChild("Area Crystal")
	if not areaPart then return false end
	
	local playerPos = humanoidRootPart.Position
	local areaCFrame = areaPart.CFrame
	local areaSize = areaPart.Size
	
	local relativePos = areaCFrame:PointToObjectSpace(playerPos)
	return math.abs(relativePos.X) <= areaSize.X / 2 and
		   math.abs(relativePos.Y) <= areaSize.Y / 2 and
		   math.abs(relativePos.Z) <= areaSize.Z / 2
end

-- Get all players currently in the boss area (cached for 2 seconds)
local cachedPlayersInArea = {}
local cachedPlayersTime = 0
local function getPlayersInArea()
	if os.clock() - cachedPlayersTime < 2 then
		return cachedPlayersInArea
	end
	cachedPlayersInArea = {}
	for _, player in ipairs(Players:GetPlayers()) do
		if isPlayerInArea(player) then
			table.insert(cachedPlayersInArea, player)
		end
	end
	cachedPlayersTime = os.clock()
	return cachedPlayersInArea
end

-- Calculate boss HP based on players in area
local function calculateBossHP()
	local players = getPlayersInArea()
	if #players == 0 then
		return 1000 -- Default HP when no players
	end
	
	local totalClickPower = 0
	for _, player in ipairs(players) do
		totalClickPower = totalClickPower + getPlayerClickPower(player)
	end
	
	local avgClickPower = totalClickPower / #players
	local bossHP = avgClickPower * #players * CONFIG.BASE_HP_MULTIPLIER
	
	-- Ensure minimum HP
	return math.max(bossHP, 1000)
end

-- ============================================
-- SYNC FUNCTIONS
-- ============================================

-- Sync boss state to all clients (debounced to max every 0.5s)
local lastSyncTime = 0
local function syncBossToAllClients(force)
	if not force and os.clock() - lastSyncTime < 0.5 then return end
	lastSyncTime = os.clock()
	for _, player in ipairs(Players:GetPlayers()) do
		crystalBossSync:FireClient(player, "bossStateUpdate", {
			currentHP = bossState.currentHP,
			maxHP = bossState.maxHP,
			isAlive = bossState.isAlive,
			isUnderground = bossState.isUnderground,
			respawnEndTime = bossState.respawnEndTime,
			isInArea = isPlayerInArea(player)
		})
	end
end

-- Sync boss state to specific player
local function syncBossToClient(player)
	crystalBossSync:FireClient(player, "bossStateUpdate", {
		currentHP = bossState.currentHP,
		maxHP = bossState.maxHP,
		isAlive = bossState.isAlive,
		isUnderground = bossState.isUnderground,
		respawnEndTime = bossState.respawnEndTime,
		isInArea = isPlayerInArea(player)
	})
end

-- ============================================
-- BOSS LIFECYCLE
-- ============================================

-- Spawn the boss with calculated HP
local function spawnBoss()
	bossState.maxHP = calculateBossHP()
	bossState.currentHP = bossState.maxHP
	bossState.isAlive = true
	bossState.isUnderground = false
	bossState.totalDamageDealt = {}
	
	-- Show boss model on respawn
	local stored = ServerStorage:FindFirstChild("Boss Crystal Tree")
	if stored then
		local bossFolder = game.Workspace:FindFirstChild("Crstal Tree pasta")
		if bossFolder then
			stored.Parent = bossFolder
			print("[CrystalBoss] Boss model restored")
		end
	end
	
	print(string.format("[CrystalBoss] Boss spawned with HP: %d (based on %d players)", bossState.maxHP, #getPlayersInArea()))
	
	syncBossToAllClients(true)
end

-- Calculate drops for a player
local function calculateDrops()
	local drops = {}
	
	for _, dropConfig in ipairs(CONFIG.DROPS) do
		local roll = math.random(1, 100)
		if roll <= dropConfig.chance then
			table.insert(drops, {
				type = dropConfig.type,
				amount = dropConfig.amount,
				name = dropConfig.name,
				emoji = dropConfig.emoji,
				rarity = dropConfig.rarity,
				multiplier = dropConfig.multiplier,
				color = dropConfig.color
			})
		end
	end
	
	return drops
end

-- Apply drops to player
local function applyDrops(player, drops)
	local playerData = _G.playerData
	if not playerData or not playerData[player] then return end
	
	local data = playerData[player]
	local appliedDrops = {}
	
	for _, drop in ipairs(drops) do
		if drop.type == "stardust" then
			data.stardust = data.stardust + drop.amount
			if data.supernova then
				data.supernova.totalStardustEarned = data.supernova.totalStardustEarned + drop.amount
			end
			table.insert(appliedDrops, drop)
			
		elseif drop.type == "starcoins" then
			data.starcoins = data.starcoins + drop.amount
			table.insert(appliedDrops, drop)
			
		elseif drop.type == "pet" then
			-- Create new pet
			local newPet = {
				id = drop.name .. "_" .. tostring(os.time()) .. "_" .. tostring(math.random(1000, 9999)),
				name = drop.name,
				emoji = drop.emoji,
				rarity = drop.rarity,
				multiplier = drop.multiplier,
				equipped = false,
				obtainedAt = os.time(),
				isBossReward = true
			}
			table.insert(data.ownedPets, newPet)
			table.insert(appliedDrops, drop)
		end
	end
	
	return appliedDrops
end

-- ============================================
-- GACHA ROLL SYSTEM
-- ============================================

-- Roll a single gacha shot for a player
local function rollGacha(player, contributionPercent)
	local playerData = _G.playerData
	if not playerData or not playerData[player] then return nil end
	local data = playerData[player]
	
	-- Check if player has shots
	if not data.crystalTreeShots or data.crystalTreeShots <= 0 then
		return nil
	end
	
	-- Determine if player is high damage (>30% of boss HP)
	local isHighDamage = contributionPercent >= CONFIG.HIGH_DAMAGE_THRESHOLD
	
	-- Roll against the reward table
	local roll = math.random(1, 100)
	local cumulative = 0
	local selectedReward = nil
	
	for _, reward in ipairs(CONFIG.GACHA_REWARDS) do
		local effectiveChance = reward.chance
		-- Add +5% for high damage players on scaling rewards
		if isHighDamage and reward.scalesWithDamage then
			effectiveChance = effectiveChance + CONFIG.HIGH_DAMAGE_BONUS
		end
		cumulative = cumulative + effectiveChance
		if roll <= cumulative then
			selectedReward = reward
			break
		end
	end
	
	-- If nothing selected (shouldn't happen with 100% stardust), default to stardust
	if not selectedReward then
		selectedReward = CONFIG.GACHA_REWARDS[1]
	end
	
	-- Consume the shot
	data.crystalTreeShots = data.crystalTreeShots - 1
	
	-- Apply the reward
	local rewardResult = {
		type = selectedReward.type,
		name = selectedReward.name,
		emoji = selectedReward.emoji,
		color = selectedReward.color,
		rarity = selectedReward.rarity,
		multiplier = selectedReward.multiplier,
		isHighDamage = isHighDamage
	}
	
	if selectedReward.type == "stardust" then
		-- Scale with damage contribution
		local amount = selectedReward.baseAmount
		if isHighDamage then
			local scale = contributionPercent / CONFIG.HIGH_DAMAGE_THRESHOLD
			amount = math.floor(amount + (selectedReward.maxAmount - selectedReward.baseAmount) * math.clamp(scale, 0, 1))
		end
		data.stardust = data.stardust + amount
		data.supernova.totalStardustEarned = data.supernova.totalStardustEarned + amount
		rewardResult.amount = amount
		
	elseif selectedReward.type == "starcoins" then
		-- Scale with damage contribution
		local amount = selectedReward.baseAmount
		if isHighDamage then
			local scale = contributionPercent / CONFIG.HIGH_DAMAGE_THRESHOLD
			amount = math.floor(amount + (selectedReward.maxAmount - selectedReward.baseAmount) * math.clamp(scale, 0, 1))
		end
		data.starcoins = data.starcoins + amount
		rewardResult.amount = amount
		
	elseif selectedReward.type == "item" then
		-- Add consumable to inventory
		data.inventory = data.inventory or {}
		data.inventory[selectedReward.name] = (data.inventory[selectedReward.name] or 0) + 1
		rewardResult.amount = 1
		

	elseif selectedReward.type == "pet" then
		-- Create new pet
		local newPet = {
			id = selectedReward.name .. "_" .. tostring(os.time()) .. "_" .. tostring(math.random(1000, 9999)),
			name = selectedReward.name,
			emoji = selectedReward.emoji,
			rarity = selectedReward.rarity,
			multiplier = selectedReward.multiplier,
			equipped = false,
			obtainedAt = os.time(),
			isBossReward = true
		}
		table.insert(data.ownedPets, newPet)
		rewardResult.amount = 1
	end
	
	-- Save and sync
	if _G.savePlayerData then
		pcall(_G.savePlayerData, player)
	elseif _G.SaveData then
		pcall(_G.SaveData, player)
	elseif _G.saveData then
		pcall(_G.saveData, player)
	end
	
	-- Sync stardust/starcoins to client via StardustSync
	local stardustSync = ReplicatedStorage:FindFirstChild("StardustSync")
	if stardustSync and data then
		stardustSync:FireClient(player, data.stardust, data.starcoins, data.level, data.xp, data.xpNeeded, data.ownedPets, data.equippedPets, data.dailyReward, data.supernova, data.upgrades)
	end
	
	return rewardResult
end

-- Handle boss defeat
local function defeatBoss()
	bossState.isAlive = false
	bossState.isUnderground = true
	bossState.respawnEndTime = os.time() + CONFIG.RESPAWN_TIME
	
	-- Hide boss model on defeat
	local bossFolder = game.Workspace:FindFirstChild("Crstal Tree pasta")
	if bossFolder then
		local bossPart = bossFolder:FindFirstChild("Boss Crystal Tree")
		if bossPart then
			bossPart.Parent = ServerStorage
			print("[CrystalBoss] Boss model hidden")
		end
	end
	
	print("[CrystalBoss] Boss defeated! Starting respawn timer...")
	
	-- Give rewards to all players in area
	local playersInArea = getPlayersInArea()
	for _, player in ipairs(playersInArea) do
		-- Calculate reward based on damage contribution
		local damageDealt = bossState.totalDamageDealt[player] or 0
		local totalDamage = 0
		for _, dmg in pairs(bossState.totalDamageDealt) do
			totalDamage = totalDamage + dmg
		end
		
		local contributionPercent = totalDamage > 0 and (damageDealt / totalDamage) or 0
		local stardustReward = math.floor(CONFIG.REWARD_STARDUST * (0.5 + contributionPercent * 0.5))
		local starcoinsReward = math.floor(CONFIG.REWARD_STARCOINS * (0.5 + contributionPercent * 0.5))
		
		-- Calculate drops (legacy)
		local drops = calculateDrops()
		local appliedDrops = applyDrops(player, drops)
		
		-- Add base rewards to player data
		local playerData = _G.playerData
		if playerData and playerData[player] then
			local data = playerData[player]
			data.stardust = data.stardust + stardustReward
			data.starcoins = data.starcoins + starcoinsReward
			if data.supernova then
				data.supernova.totalStardustEarned = data.supernova.totalStardustEarned + stardustReward
			end
			
			-- Give gacha shots (initialize if nil)
			data.crystalTreeShots = (data.crystalTreeShots or 0) + CONFIG.GACHA_SHOTS_PER_DEFEAT
			
			-- Sync to client
			if _G.savePlayerData then
				pcall(_G.savePlayerData, player)
			elseif _G.SaveData then
				pcall(_G.SaveData, player)
			elseif _G.saveData then
				pcall(_G.saveData, player)
			end
			
			-- Notify client of rewards, drops, and gacha shots
			crystalBossSync:FireClient(player, "bossDefeated", {
				stardust = stardustReward,
				starcoins = starcoinsReward,
				contribution = contributionPercent,
				drops = appliedDrops,
				gachaShots = data.crystalTreeShots
			})
		end
	end
	
	syncBossToAllClients(true)
	
	-- Teleport players back to spawn after 5 seconds
	task.delay(5, function()
		for _, p in ipairs(playersInArea) do
			local character = p.Character
			if character then
				local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
				if humanoidRootPart then
					-- Notify player before teleport
					crystalBossSync:FireClient(p, "teleportingToSpawn", 5)
					
					-- Find spawn location
					local spawnLocation = game.Workspace:FindFirstChildOfClass("SpawnLocation")
					if spawnLocation then
						humanoidRootPart.CFrame = spawnLocation.CFrame + Vector3.new(0, 5, 0)
					else
						-- Fallback: teleport to world origin
						humanoidRootPart.CFrame = CFrame.new(0, 10, 0)
					end
				end
			end
		end
	end)
	
	-- Start respawn timer
	task.delay(CONFIG.RESPAWN_TIME, function()
		if #getPlayersInArea() > 0 then
			spawnBoss()
		else
			bossState.isUnderground = false
			bossState.isAlive = false
			print("[CrystalBoss] Respawn timer ended, waiting for players...")
		end
	end)
end

-- Deal damage to boss
local function damageBoss(player, amount)
	if not bossState.isAlive or bossState.isUnderground then
		return false, "Boss is not available"
	end
	
	if amount <= 0 then
		return false, "Invalid damage amount"
	end
	
	-- Track damage per player
	bossState.totalDamageDealt[player] = (bossState.totalDamageDealt[player] or 0) + amount
	
	-- Apply damage
	bossState.currentHP = math.max(0, bossState.currentHP - amount)
	
	-- Check if boss is defeated
	if bossState.currentHP <= 0 then
		bossState.currentHP = 0
		defeatBoss()
	else
		syncBossToAllClients()
	end
	
	return true, amount
end

-- ============================================
-- GLOBAL FUNCTIONS (for external scripts)
-- ============================================

_G.GetCrystalBossHP = function()
	return {
		current = bossState.currentHP,
		max = bossState.maxHP,
		isAlive = bossState.isAlive,
		isUnderground = bossState.isUnderground
	}
end

_G.DamageCrystalBoss = function(player, amount)
	return damageBoss(player, amount)
end

_G.GetCrystalBossState = function()
	return bossState
end

_G.GetPlayersInCrystalArea = function()
	return getPlayersInArea()
end

-- ============================================
-- PLAYER AREA TRACKING
-- ============================================

local playerInArea = {} -- Track which players are in the area

-- Check for players entering/leaving the area
local function updatePlayersInArea()
	cachedPlayersTime = 0
	cachedPlayersTime = 0
	cachedPlayersTime = 0
	local currentPlayers = getPlayersInArea()
	local currentSet = {}local currentSet = {}local currentSet = {}local currentSet = {}
	
	for _, player in ipairs(currentPlayers) do
		currentSet[player] = true
		
		-- Player just entered the area
		if not playerInArea[player] then
			playerInArea[player] = true
			
			-- If boss is not alive and not underground, spawn it
			if not bossState.isAlive and not bossState.isUnderground then
				spawnBoss()
			elseif bossState.isAlive then
				-- Sync current boss state to new player
				syncBossToClient(player)
			end
		end
	end
	
	-- Check for players who left the area
	for player in pairs(playerInArea) do
		if not currentSet[player] then
			playerInArea[player] = nil
		end
	end
end

-- ============================================
-- REMOTEEVENT HANDLERS
-- ============================================

crystalBossSync.OnServerEvent:Connect(function(player, action, ...)
	local args = {...}
	
	if action == "clickBoss" then
		-- Player clicked on the boss
		if not bossState.isAlive or bossState.isUnderground then
			crystalBossSync:FireClient(player, "bossNotAvailable")
			return
		end
		
		-- Calculate and apply damage
		local damage = calculateClickDamage(player)
		local success, result = damageBoss(player, damage)
		
		if success then
			crystalBossSync:FireClient(player, "damageDealt", damage, bossState.currentHP, bossState.maxHP)
		end
		
	elseif action == "requestState" then
		-- Player requests current boss state
		syncBossToClient(player)
		
	elseif action == "getClickDamage" then
		-- Player requests their click damage value
		local damage = calculateClickDamage(player)
		crystalBossSync:FireClient(player, "clickDamageValue", damage)
	
	elseif action == "useGachaShot" then
		-- Player wants to use a gacha shot - roll 7 independent cards
		local playerData = _G.playerData
		if not playerData or not playerData[player] then
			crystalBossSync:FireClient(player, "gachaError", "No player data")
			return
		end
		
		local data = playerData[player]
		if not data.crystalTreeShots or data.crystalTreeShots <= 0 then
			crystalBossSync:FireClient(player, "gachaError", "No shots available")
			return
		end
		
		-- Consume 1 shot
		data.crystalTreeShots = data.crystalTreeShots - 1
		
		-- Calculate damage contribution
		local damageDealt = bossState.totalDamageDealt[player] or 0
		local totalDamage = 0
		for _, dmg in pairs(bossState.totalDamageDealt) do
			totalDamage = totalDamage + dmg
		end
		local contributionPercent = totalDamage > 0 and (damageDealt / totalDamage) or 0
		local isHighDamage = contributionPercent >= CONFIG.HIGH_DAMAGE_THRESHOLD
		
		-- REBALANCED: Roll 5 independent cards (was 7)
		local results = {}
		for i = 1, 5 do
			local roll = math.random(1, 100)
			local cardResult = {type = "miss", name = "MISS", emoji = "✕", color = Color3.fromRGB(120, 30, 30)}
			
			-- Check each reward independently - REBALANCED: Reduced chances
			if roll <= 4 then
				-- Pet Crystal Tree (4%)
				cardResult = {type = "pet", name = "PetCrystalTree", emoji = "✤", rarity = "Lendario", multiplier = 6.0, color = Color3.fromRGB(255, 200, 50)}
			elseif roll <= 16 then
				-- Mini Crystal Pet (12%)
				cardResult = {type = "pet", name = "PetMiniCrystal", emoji = "✦", rarity = "Raro", multiplier = 2.0, color = Color3.fromRGB(100, 200, 255)}
			elseif roll <= 31 then
				-- XP Boost (15%)
				cardResult = {type = "item", name = "XP Boost", emoji = "▲", color = Color3.fromRGB(180, 100, 255)}
			elseif roll <= 46 then
				-- Crystal Shard (15%)
				cardResult = {type = "item", name = "Crystal Shard", emoji = "◈", color = Color3.fromRGB(100, 220, 255)}
			elseif roll <= 66 then
				-- Starcoins (20%)
				local amount = isHighDamage and math.random(50, 75) or math.random(25, 50)
				cardResult = {type = "starcoins", name = "Starcoins", emoji = "◆", amount = amount, color = Color3.fromRGB(255, 200, 50)}
			elseif roll <= 91 then
				-- Stardust (25%)
				local amount = isHighDamage and math.random(600, 900) or math.random(300, 600)
				cardResult = {type = "stardust", name = "Stardust", emoji = "★", amount = amount, color = Color3.fromRGB(255, 255, 100)}
			else
				-- MISS (9%)
				cardResult = {type = "miss", name = "MISS", emoji = "✕", color = Color3.fromRGB(120, 30, 30)}
			end
			
			-- Apply the reward
			if cardResult.type == "stardust" then
				data.stardust = data.stardust + cardResult.amount
				if data.supernova then
					data.supernova.totalStardustEarned = data.supernova.totalStardustEarned + cardResult.amount
				end
			elseif cardResult.type == "starcoins" then
				data.starcoins = data.starcoins + cardResult.amount
			elseif cardResult.type == "item" then
				data.inventory = data.inventory or {}
				data.inventory[cardResult.name] = (data.inventory[cardResult.name] or 0) + 1
			elseif cardResult.type == "pet" then
				local newPet = {
					id = cardResult.name .. "_" .. tostring(os.time()) .. "_" .. tostring(math.random(1000, 9999)),
					name = cardResult.name,
					emoji = cardResult.emoji,
					rarity = cardResult.rarity,
					multiplier = cardResult.multiplier,
					equipped = false,
					obtainedAt = os.time(),
					isBossReward = true
				}
				table.insert(data.ownedPets, newPet)
			end
			
			table.insert(results, cardResult)
		end
		
		-- Save and sync
		if _G.savePlayerData then
			pcall(_G.savePlayerData, player)
		elseif _G.SaveData then
			pcall(_G.SaveData, player)
		elseif _G.saveData then
			pcall(_G.saveData, player)
		end
		
		-- Sync stardust/starcoins to client
		local stardustSync = ReplicatedStorage:FindFirstChild("StardustSync")
		if stardustSync and data then
			stardustSync:FireClient(player, data.stardust, data.starcoins, data.level, data.xp, data.xpNeeded, data.ownedPets, data.equippedPets, data.dailyReward, data.supernova, data.upgrades)
		end
		
		-- Send all 7 results to client
		crystalBossSync:FireClient(player, "gachaResults", results, data.crystalTreeShots)
		
	elseif action == "getGachaShots" then
		-- Player requests their current shot count
		local playerData = _G.playerData
		if playerData and playerData[player] then
			local shots = playerData[player].crystalTreeShots or 0
			crystalBossSync:FireClient(player, "gachaShotsUpdate", shots)
		end
	end
end)

-- ============================================
-- INTEGRATION WITH GAMEACTION (AUTO-CLICK)
-- ============================================

local gameAction = ReplicatedStorage:FindFirstChild("GameAction")
if gameAction then
	gameAction.OnServerEvent:Connect(function(player, action, ...)
		-- Only process click and autoClick actions
		if action ~= "click" and action ~= "autoClick" then
			return
		end
		
		-- Check if player is in the Crystal area
		if not playerInArea[player] then
			return
		end
		
		-- Check if boss is alive
		if not bossState.isAlive or bossState.isUnderground then
			return
		end
		
		-- Calculate and apply damage to boss
		local damage = calculateClickDamage(player)
		local success, result = damageBoss(player, damage)
		
		if success then
			-- Optionally notify client of boss damage
			crystalBossSync:FireClient(player, "bossDamageFromClick", damage, bossState.currentHP, bossState.maxHP)
		end
	end)
else
	warn("[CrystalBoss] GameAction RemoteEvent not found!")
end

-- ============================================
-- PLAYER JOIN/LEAVE HANDLING
-- ============================================

Players.PlayerAdded:Connect(function(player)
	-- Will be handled by area tracking
end)

Players.PlayerRemoving:Connect(function(player)
	playerInArea[player] = nil
	bossState.totalDamageDealt[player] = nil
end)

-- ============================================
-- MAIN UPDATE LOOP
-- ============================================

task.spawn(function()
	while true do
		task.wait(CONFIG.AREA_CHECK_INTERVAL)
		updatePlayersInArea()
		
		-- If boss is underground and respawn time has passed
		if bossState.isUnderground and os.time() >= bossState.respawnEndTime then
			if #getPlayersInArea() > 0 then
				spawnBoss()
			else
				bossState.isUnderground = false
			end
		end
	end
end)

-- ============================================
-- INITIAL SPAWN CHECK
-- ============================================

task.wait(2) -- Wait for GameLogic to initialize

-- Check if any players are already in the area
local initialPlayers = getPlayersInArea()
if #initialPlayers > 0 then
	spawnBoss()
end

end)
if not ok then
	warn("[CrystalBoss] STARTUP ERROR: " .. tostring(err))
end