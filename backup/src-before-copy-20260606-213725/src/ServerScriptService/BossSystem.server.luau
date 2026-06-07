local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- DataStore reference removed - using GameLogic's global functions instead

-- Boss Configuration
local BASE_HP = 5000
local MAX_HP = 50000
local RESPAWN_TIME = 600 -- 10 minutes in seconds
local DAMAGE_COOLDOWN = 0.1 -- Anti-spam cooldown

-- Boss Reference
local bossModel = workspace:WaitForChild("Pet Boss")
local arenaPlatform = workspace:WaitForChild("ArenaBossStarPlatform", 10)
if not arenaPlatform then
	warn("[BossSystem] ArenaBossStarPlatform not found, boss disabled")
	return
end

-- RemoteEvents
local gameActionEvent = ReplicatedStorage:WaitForChild("GameAction")
local bossSyncEvent = Instance.new("RemoteEvent")
bossSyncEvent.Name = "BossSync"
bossSyncEvent.Parent = ReplicatedStorage

local bossAttackEvent = Instance.new("RemoteEvent")
bossAttackEvent.Name = "BossAttackEvent"
bossAttackEvent.Parent = ReplicatedStorage

-- Boss State
local currentHP = 0
local maxHP = 0
local isAlive = true
local damageContribution = {} -- [player] = totalDamage
local lastDamageTime = {} -- [player] = lastDamageTimestamp for anti-spam
local respawnTimer = nil
local attackLoopRunning = false
local attackLoopConnection = nil

-- Use GameLogic's global functions for player data access
local function getPlayerData(player)
	return _G.getPlayerData and _G.getPlayerData(player)
end

local function savePlayerData(player)
	return _G.savePlayerData and _G.savePlayerData(player)
end

-- Calculate max HP based on player count
local function calculateMaxHP()
	local playerCount = #Players:GetPlayers()
	local calculatedHP = BASE_HP * playerCount
	return math.min(calculatedHP, MAX_HP)
end

-- Get random position within arena platform bounds
local function getRandomArenaPosition()
	local platformSize = arenaPlatform.Size
	local platformPos = arenaPlatform.Position
	
	local minX = platformPos.X - (platformSize.X / 2)
	local maxX = platformPos.X + (platformSize.X / 2)
	local minZ = platformPos.Z - (platformSize.Z / 2)
	local maxZ = platformPos.Z + (platformSize.Z / 2)
	
	local randomX = math.random() * (maxX - minX) + minX
	local randomZ = math.random() * (maxZ - minZ) + minZ
	local y = platformPos.Y + 2 -- Slightly above platform
	
	return Vector3.new(randomX, y, randomZ)
end

-- Stake Attack System
local ATTACK_INTERVAL = 8 -- seconds between attacks
local WARNING_DURATION = 2.5 -- warning time before impact
local DAMAGE_RADIUS = 6 -- studs
local ATTACK_DAMAGE = 15

local function performStakeAttack()
	if not isAlive then
		return
	end
	
	-- Choose 1 to 3 random positions
	local numAttacks = math.random(1, 3)
	local positions = {}
	
	for i = 1, numAttacks do
		table.insert(positions, getRandomArenaPosition())
	end
	
	-- Send attack warning to all clients
	bossAttackEvent:FireAllClients({
		positions = positions,
		warningDuration = WARNING_DURATION,
		attackType = "stake"
	})
	
	-- Wait for warning duration + 0.5 seconds
	task.wait(WARNING_DURATION + 0.5)
	
	-- Check if boss is still alive (could have died during warning)
	if not isAlive then
		return
	end
	
	-- Deal damage to players within radius of each attack position
	for _, attackPos in ipairs(positions) do
		for _, player in ipairs(Players:GetPlayers()) do
			local character = player.Character
			if character then
				local hrp = character:FindFirstChild("HumanoidRootPart")
				local humanoid = character:FindFirstChildOfClass("Humanoid")
				
				if hrp and humanoid and humanoid.Health > 0 then
					local distance = (hrp.Position - attackPos).Magnitude
					
					if distance <= DAMAGE_RADIUS then
						-- Deal damage
						humanoid.Health = humanoid.Health - ATTACK_DAMAGE
						
						-- Notify client
						gameActionEvent:FireClient(player, "bossHitPlayer", {
							damage = ATTACK_DAMAGE
						})
					end
				end
			end
		end
	end
end

local function startAttackLoop()
	if attackLoopRunning then
		return
	end
	
	attackLoopRunning = true
	
	-- Start the attack loop
	spawn(function()
		while attackLoopRunning and isAlive do
			performStakeAttack()
			task.wait(ATTACK_INTERVAL)
		end
	end)
end

local function stopAttackLoop()
	attackLoopRunning = false
end

-- Initialize or reset boss HP
local function initializeBoss()
	maxHP = calculateMaxHP()
	currentHP = maxHP
	isAlive = true
	damageContribution = {}
	lastDamageTime = {}
	
	-- Notify all clients of boss spawn
	bossSyncEvent:FireAllClients({
		bossSpawned = true,
		currentHP = currentHP,
		maxHP = maxHP
	})
	
	-- Start attack loop
	startAttackLoop()
end

-- Boss Pet Definitions
local BOSS_PETS = {
	PetMiniAstroKing = {
		name = "PetMiniAstroKing",
		rarity = "Legendary",
		multiplier = 6.0
	}
}

-- Generate unique pet ID
local function generatePetId()
	return "pet_" .. tostring(tick()) .. "_" .. tostring(math.random(1000, 9999))
end

-- Handle boss death
local function onBossDefeated()
	isAlive = false
	currentHP = 0
	
	-- Find top damage dealer for guaranteed PetMiniAstroKing
	local topDamageDealer = nil
	local topDamage = 0
	for player, damage in pairs(damageContribution) do
		if damage > topDamage then
			topDamage = damage
			topDamageDealer = player
		end
	end
	
	-- Distribute rewards to all players who dealt damage
	for player, damageDealt in pairs(damageContribution) do
		local data = getPlayerData(player)
		if data then
			-- Calculate damage percentage
			local damagePercent = (damageDealt / maxHP) * 100
			
			-- 1. PROPORTIONAL STARDUST
			local stardustReward = damagePercent * 200
			data.stardust = data.stardust + stardustReward
			
			-- 2. PET REWARD (chance based on contribution)
			local petReward = nil
			local rollChance = math.random() -- 0 to 1
			
			-- Top damage dealer always gets PetMiniAstroKing
			if player == topDamageDealer then
				petReward = BOSS_PETS.PetMiniAstroKing
			elseif damagePercent >= 20 then
				-- 30% chance for boss pet
				if rollChance < 0.3 then
					petReward = BOSS_PETS.PetMiniAstroKing
				end
			elseif damagePercent >= 10 then
				-- 15% chance
				if rollChance < 0.15 then
					petReward = BOSS_PETS.PetMiniAstroKing
				end
			else
				-- 5% chance for any damage dealer
				if rollChance < 0.05 then
					petReward = BOSS_PETS.PetMiniAstroKing
				end
			end
			
			-- Add pet to ownedPets if won
			local petName = nil
			if petReward then
				petName = petReward.name
				local newPet = {
					id = generatePetId(),
					name = petReward.name,
					rarity = petReward.rarity,
					multiplier = petReward.multiplier,
					equipped = false
				}
				table.insert(data.ownedPets, newPet)
			end
			
			-- 3. BONUS XP
			data.xp = data.xp + 500
			
			-- 4. Send reward info to client
			gameActionEvent:FireClient(player, "bossReward", {
				stardust = stardustReward,
				petName = petName,
				xp = 500,
				percentDamage = damagePercent
			})
			
			-- 5. Save player data
			savePlayerData(player)
		end
	end
	
	-- Reset damage contribution
	damageContribution = {}
	
	-- Stop attack loop
	stopAttackLoop()
	
	-- Notify all clients of boss defeat
	bossSyncEvent:FireAllClients({
		bossDefeated = true,
		respawnIn = RESPAWN_TIME
	})
	
	-- Start respawn timer
	if respawnTimer then
		respawnTimer:Cancel()
	end
	
	respawnTimer = task.delay(RESPAWN_TIME, function()
		initializeBoss()
	end)
end

-- Handle damage from player
local function onBossDamage(player)
	-- Check if boss is alive
	if not isAlive then
		return
	end
	
	-- Anti-spam check
	local now = tick()
	local lastTime = lastDamageTime[player]
	if lastTime and (now - lastTime) < DAMAGE_COOLDOWN then
		return
	end
	lastDamageTime[player] = now
	
	-- Get player's clickPower
	local data = getPlayerData(player)
	if not data then
		return
	end
	
	local damage = data.clickPower or 1
	
	-- Apply damage
	currentHP = currentHP - damage
	
	-- Track damage contribution
	if not damageContribution[player] then
		damageContribution[player] = 0
	end
	damageContribution[player] = damageContribution[player] + damage
	
	-- Check if boss is defeated
	if currentHP <= 0 then
		onBossDefeated()
	else
		-- Sync HP to all clients
		bossSyncEvent:FireAllClients({
			currentHP = currentHP,
			maxHP = maxHP,
			attackerName = player.Name,
			damageDealt = damage
		})
	end
end

-- Listen for GameAction events
local function onGameAction(player, action, ...)
	if action == "bossDamage" then
		onBossDamage(player)
	end
end

gameActionEvent.OnServerEvent:Connect(onGameAction)

-- Recalculate HP when players join/leave (only affects next spawn)
Players.PlayerAdded:Connect(function(player)
	-- If boss is alive, we don't change HP mid-fight
	-- HP will be recalculated on next spawn
end)

Players.PlayerRemoving:Connect(function(player)
	-- Clean up player's damage tracking
	lastDamageTime[player] = nil
end)

-- Initialize boss on game start
initializeBoss()
