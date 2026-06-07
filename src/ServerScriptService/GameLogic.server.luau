-- GAME LOGIC - SERVER SCRIPT
-- Stardust Simulator Main Game Logic
-- ============================================

print("[GameLogic] Script starting...")

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")
local MarketplaceService = game:GetService("MarketplaceService")

-- DataStore for player data (with error handling for Studio)
local dataStore
local success, err = pcall(function()
	dataStore = DataStoreService:GetDataStore("StardustPlayerData")
end)
if not success then
	warn("[GameLogic] DataStore not available (expected in Studio without publishing): " .. tostring(err))
	dataStore = nil
end

print("[GameLogic] DataStore initialized: " .. tostring(dataStore ~= nil))

-- Configuration
local Config = require(ReplicatedStorage:WaitForChild("StardustConfig"))

-- Remote Events
local gameAction = ReplicatedStorage:WaitForChild("GameAction")
local stardustSync = ReplicatedStorage:WaitForChild("StardustSync")
local tutorialSync = ReplicatedStorage:WaitForChild("TutorialSync")
local inventoryAction = ReplicatedStorage:WaitForChild("InventoryAction")

-- PetSpawnEvent for 3D pet following
local petSpawnEvent = Instance.new("BindableEvent")
petSpawnEvent.Name = "PetSpawnEvent"
petSpawnEvent.Parent = ReplicatedStorage

-- Gamepass IDs
local GAMEPASS_IDS = {
	TWO_X_STARDUST = 1817317562,
	MORE_PETS = 1816119729,
	TWO_X_XP = 1814337737,
	AUTO_CLICK_STAR = 1818211451
}

-- Player data cache
local playerDataCache = {}

-- Default player data
local DEFAULT_PLAYER_DATA = {
	stardust = 0,
	starcoins = 0,
	totalEarned = 0,
	level = 1,
	xp = 0,
	xpNeeded = 100,
	clickPower = 5,
	ownedPets = {},
	equippedPets = {},
	upgrades = {},
	gamepasses = {},
	boosts = {},
	inventory = {},
	tutorialCompleted = false,
	supernovaCount = 0,
	supernovaMultiplier = 1.0,
	supernovaTokens = 0,
	totalStardustEarned = 0,
	permanentUpgrades = {},
	selectedTitle = nil,
	ownedTitles = {},
	dailyRewardDay = 1,
	dailyRewardClaimed = false,
	lastDailyReward = 0,
	claimedDaysHistory = {},
	settings = {music = true, sound = true, particles = true, notifications = true}
}

-- Helper Functions
local function deepCopy(original)
	local copy = {}
	for key, value in pairs(original) do
		if type(value) == "table" then
			copy[key] = deepCopy(value)
		else
			copy[key] = value
		end
	end
	return copy
end

local function generatePetId()
	return tostring(tick()) .. "_" .. tostring(math.random(100000, 999999))
end

-- Data Persistence
local function loadPlayerData(player)
	local success, data = pcall(function()
		return dataStore:GetAsync("Player_" .. player.UserId)
	end)

	if success and data then
		local mergedData = deepCopy(DEFAULT_PLAYER_DATA)
		for key, value in pairs(data) do
			mergedData[key] = value
		end
		return mergedData
	else
		return deepCopy(DEFAULT_PLAYER_DATA)
	end
end

local function savePlayerData(player)
	local data = playerDataCache[player.UserId]
	if not data then return end

	pcall(function()
		dataStore:SetAsync("Player_" .. player.UserId, data)
	end)
end

local function syncToClient(player)
	local data = playerDataCache[player.UserId]
	if not data then return end

	local supernovaInfo = {
		count = data.supernovaCount or 0,
		multiplier = data.supernovaMultiplier or 1.0,
		tokens = data.supernovaTokens or 0,
		requirement = Config.ECONOMY.SUPERNOVA_REQUIREMENT,
		totalStardustEarned = data.totalStardustEarned or data.totalEarned or 0
	}

	-- Check if daily reward should reset (24 hours passed)
	local now = os.time()
	local secondsInDay = 86400
	local lastClaim = data.lastDailyReward or 0
	local timeSinceLastClaim = now - lastClaim

	if timeSinceLastClaim >= secondsInDay or lastClaim == 0 then
		-- Reset daily reward claim status for new day
		data.dailyRewardClaimed = false
	end

	-- Build claimedDays table for client from history
	-- Clean up old entries (keep only last 14 days to cover 2 cycles)
	local currentDay = data.dailyRewardDay or 1
	local minDay = math.max(1, currentDay - 14)
	local cleanedHistory = {}
	for _, dayNum in ipairs(data.claimedDaysHistory or {}) do
		if dayNum >= minDay then
			table.insert(cleanedHistory, dayNum)
		end
	end
	data.claimedDaysHistory = cleanedHistory

	local claimedDays = {}
	for _, dayNum in ipairs(cleanedHistory) do
		claimedDays[dayNum] = true
	end

	local dailyRewardData = {
		currentDay = data.dailyRewardDay or 1,
		claimedDays = claimedDays,
		lastClaimTime = data.lastDailyReward or 0
	}

	local upgradesData = data.upgrades or {}

	stardustSync:FireClient(player, 
		data.stardust, 
		data.starcoins, 
		data.level, 
		data.xp, 
		data.xpNeeded,
		data.ownedPets,
		data.equippedPets,
		dailyRewardData,
		supernovaInfo,
		upgradesData,
		data.permanentUpgrades or {},
		data.selectedTitle,
		data.ownedTitles or {}
	)
end

-- Gamepass Check
local function checkGamepasses(player)
	local data = playerDataCache[player.UserId]
	if not data then return end

	local has2xStardust = MarketplaceService:UserOwnsGamePassAsync(player.UserId, GAMEPASS_IDS.TWO_X_STARDUST)
	data.gamepasses.has2xStardust = has2xStardust

	local has2xXP = MarketplaceService:UserOwnsGamePassAsync(player.UserId, GAMEPASS_IDS.TWO_X_XP)
	data.gamepasses.has2xXP = has2xXP

	local hasAutoClickStar = MarketplaceService:UserOwnsGamePassAsync(player.UserId, GAMEPASS_IDS.AUTO_CLICK_STAR)
	data.gamepasses.hasAutoClickStar = hasAutoClickStar

	local hasMorePets = MarketplaceService:UserOwnsGamePassAsync(player.UserId, GAMEPASS_IDS.MORE_PETS)
	data.gamepasses.hasMorePets = hasMorePets
end

-- Click System
local function calculateClickReward(player)
	local data = playerDataCache[player.UserId]
	if not data then return 0 end

	local basePower = Config.ECONOMY.BASE_CLICK_POWER
	local multiplier = 1.0

	if data.gamepasses.has2xStardust then
		multiplier = multiplier * 2
	end

	for _, equippedId in ipairs(data.equippedPets) do
		for _, pet in ipairs(data.ownedPets) do
			if pet.id == equippedId then
				local petMultiplier = (pet.multiplier or getPetMultiplier(pet.rarity)) + ((pet.stars or 1) - 1) * 1.0
				multiplier = multiplier + petMultiplier
			end
		end
	end

	if data.upgrades then
		local clickPowerLevel = data.upgrades["Click Power"] or 0
		multiplier = multiplier * (1 + clickPowerLevel * 0.05)
	end

	local supernovaMult = (data.supernovaMultiplier or 1.0) - 1.0
	multiplier = multiplier + supernovaMult

	local now = os.time()
	for i = #data.boosts, 1, -1 do
		local boost = data.boosts[i]
		if boost.endTime and now >= boost.endTime then
			table.remove(data.boosts, i)
		elseif boost.effect == "stardustBoost" then
			multiplier = multiplier * boost.multiplier
		end
	end

	return math.floor(basePower * multiplier)
end

local function addXP(player, amount)
	local data = playerDataCache[player.UserId]
	if not data then return end

	local xpMultiplier = 1.0
	if data.gamepasses.has2xXP then
		xpMultiplier = 2.0
	end

	local now = os.time()
	for _, boost in ipairs(data.boosts) do
		if boost.endTime and now < boost.endTime and boost.effect == "xpBoost" then
			xpMultiplier = xpMultiplier * boost.multiplier
		end
	end

	data.xp = data.xp + math.floor(amount * xpMultiplier)

	while data.xp >= data.xpNeeded do
		data.xp = data.xp - data.xpNeeded
		data.level = data.level + 1
		data.xpNeeded = math.floor(100 * (data.level ^ 1.5))
	end
end

-- Pet System
local function getPetMultiplier(rarity)
	local multipliers = {
		["Common"] = 1,
		["Raro"] = 2,
		["Epico"] = 5,
		["Lendario"] = 10,
		["Especial"] = 15,
		["Supernova"] = 25
	}
	return multipliers[rarity] or 1
end

local function hatchEgg(player, eggName, quantity)
	local data = playerDataCache[player.UserId]
	if not data then return nil end

	local eggConfig = nil
	for _, egg in ipairs(Config.EGGS) do
		if egg.name == eggName then
			eggConfig = egg
			break
		end
	end

	if not eggConfig then return nil end

	local hatchedPets = {}

	for i = 1, quantity do
		local totalWeight = 0
		local weights = {}
		for j, rarity in ipairs(eggConfig.petRarities) do
			local weight = rarity == "Lendario" and 1 or 
				rarity == "Epico" and 5 or 
				rarity == "Raro" and 15 or 50
			table.insert(weights, {index = j, weight = totalWeight + weight})
			totalWeight = totalWeight + weight
		end

		local roll = math.random() * totalWeight
		local selectedIndex = 1
		for _, w in ipairs(weights) do
			if roll <= w.weight then
				selectedIndex = w.index
				break
			end
		end

		local petName = eggConfig.petNames[selectedIndex]
		local petRarity = eggConfig.petRarities[selectedIndex]
		local petEmoji = eggConfig.pets[selectedIndex]

		local newPet = {
			id = generatePetId(),
			name = petName,
			emoji = petEmoji,
			rarity = petRarity,
			multiplier = getPetMultiplier(petRarity),
			stars = 1,
			equipped = false,
			locked = false
		}

		table.insert(data.ownedPets, newPet)
		table.insert(hatchedPets, newPet)
	end

	return hatchedPets
end

-- Shop System
local function purchaseBoost(player, boostName)
	local data = playerDataCache[player.UserId]
	if not data then return false, "No data" end

	local boostConfig = nil
	for _, boost in ipairs(Config.BOOST_ITEMS) do
		if boost.name == boostName then
			boostConfig = boost
			break
		end
	end

	if not boostConfig then return false, "Boost not found" end

	if data.stardust < boostConfig.price then
		return false, "Insufficient Stardust"
	end

	data.stardust = data.stardust - boostConfig.price

	local boost = {
		name = boostConfig.name,
		effect = boostConfig.effect,
		multiplier = boostConfig.multiplier,
		duration = boostConfig.duration,
		endTime = os.time() + boostConfig.duration
	}
	table.insert(data.boosts, boost)

	return true, boost
end

local function purchaseShopItem(player, itemName)
	local data = playerDataCache[player.UserId]
	if not data then return false, "No data" end

	local itemConfig = nil
	for _, item in ipairs(Config.SHOP_ITEMS) do
		if item.name == itemName then
			itemConfig = item
			break
		end
	end

	if not itemConfig then return false, "Item not found" end

	if data.stardust < itemConfig.price then
		return false, "Insufficient Stardust"
	end

	data.stardust = data.stardust - itemConfig.price
	data.stardust = data.stardust + itemConfig.stardustGain
	data.totalEarned = data.totalEarned + itemConfig.stardustGain

	return true, itemConfig.stardustGain
end

-- Supernova System
local function performSupernova(player)
	local data = playerDataCache[player.UserId]
	if not data then return false, "No data" end

	local requirement = Config.ECONOMY.SUPERNOVA_REQUIREMENT
	if data.totalEarned < requirement then
		return false, "Need " .. requirement .. " total Stardust earned"
	end

	local tokensEarned = 1 + (data.supernovaCount or 0)
	if data.permanentUpgrades then
		for _, upgrade in ipairs(data.permanentUpgrades) do
			if upgrade == "extraTokens" then
				tokensEarned = tokensEarned + 1
			end
		end
	end

	data.supernovaCount = (data.supernovaCount or 0) + 1
	data.supernovaTokens = (data.supernovaTokens or 0) + tokensEarned
	data.supernovaMultiplier = 1.0 + (data.supernovaCount * 0.1)

	local startStardust = 0
	local startLevel = 1

	if data.permanentUpgrades then
		for _, upgrade in ipairs(data.permanentUpgrades) do
			if upgrade == "startStardust" then
				startStardust = 500
			elseif upgrade == "startLevel" then
				startLevel = 5
			end
		end
	end

	data.stardust = startStardust
	data.starcoins = 0
	data.totalEarned = 0
	data.level = startLevel
	data.xp = 0
	data.xpNeeded = startLevel > 1 and math.floor(100 * (startLevel ^ 1.5)) or 100

	return true, tokensEarned
end

-- Helper to notify PetFollowSystem about equipped pets
local function notifyPetSpawn(player)
	local data = playerDataCache[player.UserId]
	if not data then return end
	petSpawnEvent:Fire(player, data.equippedPets, data.ownedPets)
end

-- Expose functions for TradeSystem
_G.getPlayerData = function(player)
	return playerDataCache[player.UserId]
end
_G.savePlayerData = savePlayerData
_G.syncToClient = syncToClient
_G.notifyPetSpawn = notifyPetSpawn

-- Game Action Handler
gameAction.OnServerEvent:Connect(function(player, action, ...)
	local args = {...}
	local data = playerDataCache[player.UserId]

	if not data then
		warn("[GameLogic] No data for player:", player.Name)
		return
	end

	if action == "click" or action == "autoClick" then
		local reward = calculateClickReward(player)
		data.stardust = data.stardust + reward
		data.totalEarned = data.totalEarned + reward
		addXP(player, 1)

		gameAction:FireClient(player, "clickEarned", reward, false, 
			data.gamepasses.has2xStardust or false,
			data.gamepasses.has2xXP or false,
			data.gamepasses.hasAutoClickStar or false
		)

	elseif action == "buyEgg" then
		local eggName = args[1]
		local quantity = args[2] or 1

		local eggConfig = nil
		for _, egg in ipairs(Config.EGGS) do
			if egg.name == eggName then
				eggConfig = egg
				break
			end
		end

		if not eggConfig then
			gameAction:FireClient(player, "insufficientFunds", "Egg", 0, 0)
			return
		end

		local price
		if eggConfig.starcoinsOnly then
			price = quantity == 1 and eggConfig.price1Starcoins or eggConfig.price3Starcoins
		else
			price = quantity == 1 and eggConfig.price1 or eggConfig.price3
		end
		local currencyType = eggConfig.starcoinsOnly and "starcoins" or "stardust"

		if currencyType == "stardust" then
			if data.stardust < price then
				gameAction:FireClient(player, "insufficientFunds", "Stardust", price, data.stardust)
				return
			end
			data.stardust = data.stardust - price
		else
			if data.starcoins < price then
				gameAction:FireClient(player, "insufficientFunds", "Starcoins", price, data.starcoins)
				return
			end
			data.starcoins = data.starcoins - price
		end

		local hatchedPets = hatchEgg(player, eggName, quantity)
		if hatchedPets then
			gameAction:FireClient(player, "eggPurchased", eggName, quantity, hatchedPets)
		end

	elseif action == "equipPet" then
		local petId = args[1]
		local equip = args[2]
		print("[GameLogic] equipPet received - petId:", petId, "equip:", equip, "type:", type(equip))

		local maxPets = data.gamepasses.hasMorePets and 6 or 3

		if equip then
			if #data.equippedPets >= maxPets then
				table.remove(data.equippedPets, 1)
			end
			local alreadyEquipped = false
			for _, id in ipairs(data.equippedPets) do
				if id == petId then
					alreadyEquipped = true
					break
				end
			end
			if not alreadyEquipped then
				table.insert(data.equippedPets, petId)
			end
		else
			for i, id in ipairs(data.equippedPets) do
				if id == petId then
					table.remove(data.equippedPets, i)
					break
				end
			end
		end

		local totalMult = 0
		for _, equippedId in ipairs(data.equippedPets) do
			for _, pet in ipairs(data.ownedPets) do
				if pet.id == equippedId then
					local petMultiplier = (pet.multiplier or getPetMultiplier(pet.rarity)) + ((pet.stars or 1) - 1) * 1.0
					totalMult = totalMult + petMultiplier
				end
			end
		end

		gameAction:FireClient(player, "petEquipped", data.equippedPets, totalMult, data.ownedPets)

		-- Notify PetFollowSystem to update 3D pets
		notifyPetSpawn(player)

	elseif action == "deletePet" then
		local petIds = args[1]
		if type(petIds) ~= "table" then
			petIds = {petIds}
		end

		-- Check for locked pets and filter them out
		local lockedCount = 0
		local filteredIds = {}
		for _, id in ipairs(petIds) do
			local isLocked = false
			for _, pet in ipairs(data.ownedPets) do
				if pet.id == id and pet.locked then
					isLocked = true
					lockedCount = lockedCount + 1
					break
				end
			end
			if not isLocked then
				table.insert(filteredIds, id)
			end
		end

		if lockedCount > 0 then
			gameAction:FireClient(player, "petsLockedError", lockedCount)
		end

		if #filteredIds == 0 then
			syncToClient(player)
			return
		end

		local deletedCount = 0
		local newPets = {}
		for _, pet in ipairs(data.ownedPets) do
			local shouldDelete = false
			for _, id in ipairs(filteredIds) do
				if pet.id == id and not pet.equipped then
					shouldDelete = true
					break
				end
			end
			if not shouldDelete then
				table.insert(newPets, pet)
			else
				deletedCount = deletedCount + 1
			end
		end
		data.ownedPets = newPets

		-- Remove deleted pets from equippedPets list (safety)
		local newEquipped = {}
		for _, equippedId in ipairs(data.equippedPets) do
			local stillExists = false
			for _, pet in ipairs(data.ownedPets) do
				if pet.id == equippedId then
					stillExists = true
					break
				end
			end
			if stillExists then
				table.insert(newEquipped, equippedId)
			end
		end
		data.equippedPets = newEquipped

		if _G.savePlayerData then
			pcall(_G.savePlayerData, player)
		end

		gameAction:FireClient(player, "petsDeleted", deletedCount, data.ownedPets, data.equippedPets)

	elseif action == "mergePets" then
		local petIds = args[1]
		if type(petIds) ~= "table" or #petIds ~= 3 then
			gameAction:FireClient(player, "mergeError", "Invalid selection")
			return
		end

		-- Find the 3 pets
		local petsToMerge = {}
		for _, id in ipairs(petIds) do
			for _, pet in ipairs(data.ownedPets) do
				if pet.id == id then
					table.insert(petsToMerge, pet)
					break
				end
			end
		end

		if #petsToMerge ~= 3 then
			gameAction:FireClient(player, "mergeError", "Could not find all 3 pets")
			return
		end

		-- Validate: same name, same stars, not equipped, not locked
		local firstName = petsToMerge[1].name
		local firstStars = petsToMerge[1].stars or 1
		for _, pet in ipairs(petsToMerge) do
			if pet.name ~= firstName then
				gameAction:FireClient(player, "mergeError", "Pets must be the same type")
				return
			end
			if (pet.stars or 1) ~= firstStars then
				gameAction:FireClient(player, "mergeError", "Pets must be the same star level")
				return
			end
			if pet.equipped then
				gameAction:FireClient(player, "mergeError", "Unequip pets before merging")
				return
			end
			if pet.locked then
				gameAction:FireClient(player, "mergeError", "Unlock pets before merging")
				return
			end
		end

		-- Check max stars
		if firstStars >= 5 then
			gameAction:FireClient(player, "mergeError", "Already at maximum stars!")
			return
		end

		-- Remove the 3 pets
		local removedIds = {}
		for _, id in ipairs(petIds) do
			removedIds[id] = true
		end
		local newPets = {}
		for _, pet in ipairs(data.ownedPets) do
			if not removedIds[pet.id] then
				table.insert(newPets, pet)
			end
		end
		data.ownedPets = newPets

		-- Create merged pet with +1 star
		local basePet = petsToMerge[1]
		local newStars = firstStars + 1
		local mergedPet = {
			id = basePet.name .. "_merged_" .. tostring(os.time()) .. "_" .. tostring(math.random(1000, 9999)),
			name = basePet.name,
			emoji = basePet.emoji,
			rarity = basePet.rarity,
			multiplier = basePet.multiplier,
			stars = newStars,
			equipped = false,
			locked = false,
			obtainedAt = os.time(),
			isMerged = true
		}
		table.insert(data.ownedPets, mergedPet)

		-- Save
		if _G.savePlayerData then pcall(_G.savePlayerData, player) end

		-- Sync
		syncToClient(player)

		gameAction:FireClient(player, "mergeSuccess", mergedPet, data.ownedPets, data.equippedPets)

		print(string.format("[Merge] %s merged 3x %s ★%d → ★%d", player.Name, firstName, firstStars, newStars))

	elseif action == "autoMerge" then
		-- Auto-merge: find all possible merges, prioritize lowest stars, exclude locked/equipped
		local totalMerges = 0
		local mergedPets = {}

		local function findMergeableGroups()
			-- Group pets by (name, stars) that are eligible for merge
			local groups = {}
			for _, pet in ipairs(data.ownedPets) do
				if not pet.equipped and not pet.locked and (pet.stars or 1) < 5 then
					local key = pet.name .. "_" .. tostring(pet.stars or 1)
					if not groups[key] then
						groups[key] = {
							name = pet.name,
							stars = pet.stars or 1,
							emoji = pet.emoji,
							rarity = pet.rarity,
							multiplier = pet.multiplier,
							pets = {}
						}
					end
					table.insert(groups[key].pets, pet)
				end
			end
			return groups
		end

		local function getLowestStarGroup(groups)
			local lowest = nil
			for _, group in pairs(groups) do
				if #group.pets >= 3 then
					if not lowest or group.stars < lowest.stars then
						lowest = group
					end
				end
			end
			return lowest
		end

		-- Iteratively merge until no more merges possible
		local maxIterations = 100 -- Safety limit
		local iterations = 0

		while iterations < maxIterations do
			iterations = iterations + 1
			local groups = findMergeableGroups()
			local group = getLowestStarGroup(groups)

			if not group then
				break -- No more merges possible
			end

			-- Take the first 3 pets from this group
			local petsToMerge = {group.pets[1], group.pets[2], group.pets[3]}

			-- Remove the 3 pets from ownedPets
			local removedIds = {}
			for _, pet in ipairs(petsToMerge) do
				removedIds[pet.id] = true
			end
			local newPets = {}
			for _, pet in ipairs(data.ownedPets) do
				if not removedIds[pet.id] then
					table.insert(newPets, pet)
				end
			end
			data.ownedPets = newPets

			-- Create merged pet with +1 star
			local basePet = petsToMerge[1]
			local newStars = group.stars + 1
			local mergedPet = {
				id = basePet.name .. "_merged_" .. tostring(os.time()) .. "_" .. tostring(math.random(1000, 9999)),
				name = basePet.name,
				emoji = basePet.emoji,
				rarity = basePet.rarity,
				multiplier = basePet.multiplier,
				stars = newStars,
				equipped = false,
				locked = false,
				obtainedAt = os.time(),
				isMerged = true
			}
			table.insert(data.ownedPets, mergedPet)
			table.insert(mergedPets, mergedPet)

			totalMerges = totalMerges + 1
			print(string.format("[AutoMerge] %s merged 3x %s ★%d → ★%d", player.Name, group.name, group.stars, newStars))
		end

		if totalMerges > 0 then
			-- Save
			if _G.savePlayerData then pcall(_G.savePlayerData, player) end

			-- Sync
			syncToClient(player)

			gameAction:FireClient(player, "autoMergeSuccess", totalMerges, mergedPets, data.ownedPets, data.equippedPets)
		else
			gameAction:FireClient(player, "mergeError", "No pets available for auto-merge")
		end

elseif action == "petLockToggled" then
		local petId = args[1]
		if not petId then return end

		for _, pet in ipairs(data.ownedPets) do
			if pet.id == petId then
				pet.locked = not pet.locked
				gameAction:FireClient(player, "petLockUpdated", pet.id, pet.locked, data.ownedPets, data.equippedPets)
				break
			end
		end

		syncToClient(player)

	elseif action == "buyBoost" or action == "buyBoostItem" then
		local boostName = args[1]
		local success, result = purchaseBoost(player, boostName)

		if success then
			gameAction:FireClient(player, "boostActivated", boostName, result, data.boosts)
		else
			gameAction:FireClient(player, "insufficientFunds", "Stardust", 
				Config.BOOST_ITEMS[1].price, data.stardust)
		end

	elseif action == "buyShopItem" then
		local itemName = args[1]
		local success, result = purchaseShopItem(player, itemName)

		if success then
			gameAction:FireClient(player, "shopItemPurchased", itemName, result)
		else
			gameAction:FireClient(player, "insufficientFunds", "Stardust", 100, data.stardust)
		end

	elseif action == "sellStardust" then
		local amount = args[1]
		if data.stardust < amount then
			gameAction:FireClient(player, "insufficientFunds", "Stardust", amount, data.stardust)
			return
		end

		local rate = Config.ECONOMY.STARCOIN_CONVERSION_RATE
		local starcoinsGained = math.floor(amount / rate)

		if starcoinsGained > 0 then
			data.stardust = data.stardust - (starcoinsGained * rate)
			data.starcoins = data.starcoins + starcoinsGained
		end

	elseif action == "supernova" then
		local success, result = performSupernova(player)

		if success then
			gameAction:FireClient(player, "supernovaSuccess", data.supernovaCount, result, data.supernovaMultiplier)
		else
			gameAction:FireClient(player, "supernovaFailed", result)
		end

	elseif action == "buyUpgrade" then
		local upgradeName = args[1]

		local upgradeConfig = nil
		for _, upgrade in ipairs(Config.UPGRADES) do
			if upgrade.name == upgradeName then
				upgradeConfig = upgrade
				break
			end
		end

		if not upgradeConfig then return end

		local currentLevel = data.upgrades[upgradeName] or 0
		local price = upgradeConfig.price * (currentLevel + 1)

		if data.stardust < price then
			gameAction:FireClient(player, "insufficientFunds", "Stardust", price, data.stardust)
			return
		end

		data.stardust = data.stardust - price
		data.upgrades[upgradeName] = currentLevel + 1

		gameAction:FireClient(player, "upgradePurchased", upgradeName, data.upgrades[upgradeName])

	elseif action == "claimDailyReward" then
		local now = os.time()
		local day = data.dailyRewardDay or 1
		local secondsInDay = 86400
		local lastClaim = data.lastDailyReward or 0

		-- Check if enough time has passed to claim again
		local canClaim = not data.dailyRewardClaimed or (now - lastClaim >= secondsInDay)

		if not canClaim then
			gameAction:FireClient(player, "dailyRewardAlreadyClaimed")
			return
		end

		local rewards = Config.DAILY_REWARDS
		local rewardIndex = math.min(day, #rewards)
		local reward = rewards[rewardIndex]

		local amount = tonumber(string.match(reward.reward, "%d+")) or 100

		data.stardust = data.stardust + amount
		data.totalEarned = data.totalEarned + amount
		data.dailyRewardClaimed = true
		data.lastDailyReward = now

		-- Add to claimed history
		if not data.claimedDaysHistory then
			data.claimedDaysHistory = {}
		end
		table.insert(data.claimedDaysHistory, day)

		-- Increment day for next claim
		if day < #rewards then
			data.dailyRewardDay = day + 1
		else
			-- Reset cycle after day 7
			data.dailyRewardDay = 1
		end

		gameAction:FireClient(player, "dailyRewardClaimed", day, amount, 1)

	elseif action == "travel" or action == "travelToWorld" then
		local worldName = args[1]

		local worldConfig = nil
		for _, world in ipairs(Config.WORLDS) do
			if world.name == worldName then
				worldConfig = world
				break
			end
		end

		if not worldConfig then
			gameAction:FireClient(player, "travelFailed", "World not found")
			return
		end

		if data.totalEarned < worldConfig.required then
			gameAction:FireClient(player, "travelFailed", "Need " .. worldConfig.required .. " total Stardust")
			return
		end

		local teleportPart = workspace:FindFirstChild(worldConfig.teleportPart, true)
		if not teleportPart then
			for _, desc in ipairs(workspace:GetDescendants()) do
				if desc:IsA("BasePart") and desc.Name == worldConfig.teleportPart then
					teleportPart = desc
					break
				end
			end
		end
		if teleportPart then
			local char = player.Character
			if char then
				local targetCFrame = teleportPart.CFrame * CFrame.new(0, 5, 0)
				char:PivotTo(targetCFrame)
			end
			gameAction:FireClient(player, "travelSuccess", worldName)
		else
			gameAction:FireClient(player, "travelFailed", "Teleport location not found")
		end
	end

	syncToClient(player)
end)

-- Inventory Action Handler
inventoryAction.OnServerEvent:Connect(function(player, action, ...)
	local args = {...}
	local data = playerDataCache[player.UserId]
	if not data then return end

	if action == "GetInventory" then
		inventoryAction:FireClient(player, "InventoryUpdate", data.inventory or {})
	elseif action == "UseItem" then
		local itemName = args[1]
		local quantity = data.inventory[itemName] or 0

		if quantity <= 0 then return end

		local itemValues = {
			["Star Fragment"] = 100,
			["Shooting Star"] = 300,
			["Moon Stone"] = 1000,
			["Magic Dust"] = 200,
			["Bright Star"] = 600,
			["Comet Tail"] = 450
		}

		local stardustGain = itemValues[itemName] or 0
		data.inventory[itemName] = quantity - 1
		if data.inventory[itemName] <= 0 then
			data.inventory[itemName] = nil
		end

		data.stardust = data.stardust + stardustGain
		data.totalEarned = data.totalEarned + stardustGain

		inventoryAction:FireClient(player, "ItemUsed", itemName, stardustGain)
		syncToClient(player)
	end
end)

-- Tutorial Sync Handler
tutorialSync.OnServerEvent:Connect(function(player, action)
	local data = playerDataCache[player.UserId]
	if not data then return end

	if action == "completed" or action == "skip" then
		data.tutorialCompleted = true
		savePlayerData(player)
	end
end)

-- Player Connections
local function onPlayerAdded(player)
	playerDataCache[player.UserId] = loadPlayerData(player)
	checkGamepasses(player)

	local data = playerDataCache[player.UserId]
	tutorialSync:FireClient(player, data.tutorialCompleted or false)

	task.wait(1)
	syncToClient(player)

	-- Spawn equipped pets in 3D world after character loads
	player.CharacterAdded:Connect(function(character)
		task.wait(2)
		notifyPetSpawn(player)
	end)

	-- Also spawn for current character if it exists
	if player.Character then
		task.wait(2)
		notifyPetSpawn(player)
	end

	print("[GameLogic] Player loaded:", player.Name)
end

local function onPlayerRemoving(player)
	savePlayerData(player)
	playerDataCache[player.UserId] = nil
	print("[GameLogic] Player saved and removed:", player.Name)
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)

for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(onPlayerAdded, player)
end

task.spawn(function()
	while true do
		task.wait(60)
		for _, player in ipairs(Players:GetPlayers()) do
			savePlayerData(player)
		end
		print("[GameLogic] Auto-saved all player data")
	end
end)

-- Passive Pet Income System
-- Equipped pets generate stardust every second based on their multiplier
local PET_INCOME_INTERVAL = 1 -- seconds between income ticks

task.spawn(function()
	while true do
		task.wait(PET_INCOME_INTERVAL)

		for _, player in ipairs(Players:GetPlayers()) do
			local data = playerDataCache[player.UserId]
			if not data then continue end

			local totalIncome = 0
			for _, equippedId in ipairs(data.equippedPets) do
				for _, pet in ipairs(data.ownedPets) do
					if pet.id == equippedId then
						local petMultiplier = (pet.multiplier or getPetMultiplier(pet.rarity)) + ((pet.stars or 1) - 1) * 1.0
						totalIncome = totalIncome + petMultiplier
					end
				end
			end

			if totalIncome > 0 then
				-- Apply 2x gamepass
				if data.gamepasses.has2xStardust then
					totalIncome = totalIncome * 2
				end

				-- Apply supernova multiplier
				local supernovaMult = (data.supernovaMultiplier or 1.0) - 1.0
				totalIncome = totalIncome + (totalIncome * supernovaMult)

				-- Apply active stardust boosts
				local now = os.time()
				for _, boost in ipairs(data.boosts) do
					if boost.endTime and now < boost.endTime and boost.effect == "stardustBoost" then
						totalIncome = totalIncome * boost.multiplier
					end
				end

				totalIncome = math.floor(totalIncome)

				if totalIncome > 0 then
					data.stardust = data.stardust + totalIncome
					data.totalEarned = data.totalEarned + totalIncome
					syncToClient(player)
				end
			end
		end
	end
end)

print("[GameLogic] Stardust Simulator Game Logic Loaded!")