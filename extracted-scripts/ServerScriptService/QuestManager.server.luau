-- QuestManager Server Script
-- Handles quest progress tracking, claiming, and synchronization

print("[QuestManager] Script starting...")

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Require QuestDefinitions module
local QuestDefinitions = require(ReplicatedStorage:WaitForChild("QuestDefinitions"))

-- DataStore for quest data (with error handling for Studio)
local dataStore
local success, err = pcall(function()
	dataStore = DataStoreService:GetDataStore("QuestData_v1")
end)
if not success then
	warn("[QuestManager] DataStore not available (expected in Studio without publishing): " .. tostring(err))
	dataStore = nil
end

-- Remote references
local questRemotes = ReplicatedStorage:WaitForChild("QuestRemotes")
local getQuestDataRemote = questRemotes:WaitForChild("GetQuestData")
local claimQuestRemote = questRemotes:WaitForChild("ClaimQuest")
local questProgressUpdatedRemote = questRemotes:WaitForChild("QuestProgressUpdated")
local questClaimedRemote = questRemotes:WaitForChild("QuestClaimed")

-- Bindable event references
local questEvents = ServerStorage:WaitForChild("QuestEvents")
local onClickEvent = questEvents:WaitForChild("OnClick")
local onStardustEarnedEvent = questEvents:WaitForChild("OnStardustEarned")
local onStardustSpentEvent = questEvents:WaitForChild("OnStardustSpent")
local onItemUsedEvent = questEvents:WaitForChild("OnItemUsed")
local onItemBoughtEvent = questEvents:WaitForChild("OnItemBought")
local onLevelUpEvent = questEvents:WaitForChild("OnLevelUp")

-- External system references for rewards
local itemStardustEvent = ReplicatedStorage:WaitForChild("ItemStardustEvent") -- For stardust rewards
local inventoryAction = ReplicatedStorage:WaitForChild("InventoryAction") -- For item rewards

-- BindableEvent for adding items from quests (server-side)
local questItemRewardEvent = Instance.new("BindableEvent")
questItemRewardEvent.Name = "QuestItemReward"
questItemRewardEvent.Parent = ServerStorage

-- In-memory cache of player data
local playerCache = {}

-- Track players currently loading data (race condition protection)
local loadingPlayers = {}

-- Track save debounce for each player
local saveDebounce = {}

-- Track dirty players for debounce save
local dirtyPlayers = {}

-- CPM tracking per player (sliding window)
local cpmTrackers = {} -- [userId] = { clickCount = 0, startTime = 0 }

-- Playtime tracking per player
local playtimeTrackers = {} -- [userId] = true (active tracking)

-- ============================================
-- DEFAULT DATA STRUCTURE
-- ============================================

local function GetDefaultData()
	return {
		daily = {
			resetTimestamp = 0,
			progress = {},
			claimed = {},
		},
		weekly = {
			resetTimestamp = 0,
			progress = {},
			claimed = {},
		},
		lifetime = {
			progress = {},
			claimed = {},
		},
		loginStreak = {
			count = 0,
			lastLoginDay = 0,
		},
		lifetimeStats = {
			totalClicks = 0,
			totalStardustEarned = 0,
			totalStardustSpent = 0,
			totalItemsBought = 0,
			totalPlaytimeMinutes = 0,
			maxLevel = 0,
		},
	}
end

-- ============================================
-- DATASTORE OPERATIONS
-- ============================================

local function SaveData(player)
	local userId = player.UserId
	local data = playerCache[userId]
	
	if not data then
		return
	end
	
	-- Skip if DataStore is not available
	if not dataStore then
		return
	end
	
	local success, err = pcall(function()
		dataStore:SetAsync(tostring(userId), data)
	end)
	
	if not success then
		warn("Failed to save quest data for " .. player.Name .. ": " .. tostring(err))
	end
	
	saveDebounce[userId] = nil
end

local function LoadData(player)
	local userId = player.UserId
	
	-- Mark as loading to prevent race conditions
	loadingPlayers[userId] = true
	
	local data
	
	-- Check if DataStore is available
	if dataStore then
		local success, result = pcall(function()
			return dataStore:GetAsync(tostring(userId))
		end)
		
		-- Check if player left during load (race condition protection)
		if not loadingPlayers[userId] then
			-- Player left during load, don't cache orphaned data
			return nil
		end
		
		if success and result then
			data = result
		else
			if not success then
				warn("Failed to load quest data for " .. player.Name .. ": " .. tostring(result))
			end
			data = GetDefaultData()
		end
	else
		-- No DataStore, use default data
		data = GetDefaultData()
	end
	
	-- Ensure all required fields exist (migration safety)
	if not data.daily then
		data.daily = { resetTimestamp = 0, progress = {}, claimed = {} }
	end
	if not data.weekly then
		data.weekly = { resetTimestamp = 0, progress = {}, claimed = {} }
	end
	if not data.lifetime then
		data.lifetime = { progress = {}, claimed = {} }
	end
	if not data.loginStreak then
		data.loginStreak = { count = 0, lastLoginDay = 0 }
	end
	if not data.lifetimeStats then
		data.lifetimeStats = {
			totalClicks = 0,
			totalStardustEarned = 0,
			totalStardustSpent = 0,
			totalItemsBought = 0,
			totalPlaytimeMinutes = 0,
			maxLevel = 0,
		}
	end
	
	-- Clear loading flag and cache data
	loadingPlayers[userId] = nil
	playerCache[userId] = data
	return data
end

-- ============================================
-- RESET LOGIC
-- ============================================

local function CheckAndResetDaily(player)
	local userId = player.UserId
	local data = playerCache[userId]
	if not data then return end
	
	local currentTime = os.time()
	local resetTime = data.daily.resetTimestamp
	
	-- Check if more than 24 hours have passed
	if currentTime - resetTime >= 86400 then
		data.daily.progress = {}
		data.daily.claimed = {}
		data.daily.resetTimestamp = currentTime
	end
end

local function CheckAndResetWeekly(player)
	local userId = player.UserId
	local data = playerCache[userId]
	if not data then return end
	
	local currentWeek = tonumber(os.date("!%W", os.time()))
	local storedWeek = tonumber(os.date("!%W", data.weekly.resetTimestamp))
	local currentYear = tonumber(os.date("!%Y", os.time()))
	local storedYear = tonumber(os.date("!%Y", data.weekly.resetTimestamp))
	
	-- Check if we're in a different week (or year)
	if currentYear ~= storedYear or currentWeek ~= storedWeek then
		data.weekly.progress = {}
		data.weekly.claimed = {}
		data.weekly.resetTimestamp = os.time()
	end
end

-- ============================================
-- LOGIN STREAK LOGIC
-- ============================================

local function UpdateLoginStreak(player)
	local userId = player.UserId
	local data = playerCache[userId]
	if not data then return end
	
	local currentDay = math.floor(os.time() / 86400)
	local lastLoginDay = data.loginStreak.lastLoginDay
	
	if lastLoginDay == currentDay - 1 then
		-- Consecutive day login
		data.loginStreak.count = data.loginStreak.count + 1
	elseif lastLoginDay == currentDay then
		-- Already logged in today, do nothing
		return
	else
		-- Streak broken or first login
		data.loginStreak.count = 1
	end
	
	data.loginStreak.lastLoginDay = currentDay
	
	-- Update LOGIN_STREAK quest progress
	local streakCount = data.loginStreak.count
	for _, quest in ipairs(QuestDefinitions.daily) do
		if quest.objective == "LOGIN_STREAK" then
			data.daily.progress[quest.id] = math.min(streakCount, quest.goal)
		end
	end
	for _, quest in ipairs(QuestDefinitions.weekly) do
		if quest.objective == "LOGIN_STREAK" then
			data.weekly.progress[quest.id] = math.min(streakCount, quest.goal)
		end
	end
	for _, quest in ipairs(QuestDefinitions.lifetime) do
		if quest.objective == "LOGIN_STREAK" then
			data.lifetime.progress[quest.id] = math.min(streakCount, quest.goal)
		end
	end
end

-- ============================================
-- PROGRESS UPDATE FUNCTION
-- ============================================

local function UpdateProgress(player, objective, amount)
	local userId = player.UserId
	local data = playerCache[userId]
	if not data then return end
	
	local questTypes = { "daily", "weekly", "lifetime" }
	
	for _, questType in ipairs(questTypes) do
		local quests = QuestDefinitions[questType]
		if not quests then continue end
		
		for _, quest in ipairs(quests) do
			if quest.objective ~= objective then continue end
			
			-- Skip if already claimed
			if data[questType].claimed[quest.id] then continue end
			
			local progress = data[questType].progress
			local currentProgress = progress[quest.id] or 0
			local newProgress
			
			-- Special handling for set-based objectives
			if objective == "CLICKS_PER_MINUTE" or objective == "LEVEL_REACHED" then
				newProgress = math.min(amount, quest.goal)
			else
				newProgress = math.min(currentProgress + amount, quest.goal)
			end
			
			progress[quest.id] = newProgress
			
			-- Mark player as dirty for save
			dirtyPlayers[userId] = true
			
			-- Fire progress update to client
			questProgressUpdatedRemote:FireClient(player, {
				questId = quest.id,
				progress = newProgress,
				goal = quest.goal,
			})
		end
	end
end

-- ============================================
-- CPM TRACKING (CLICKS PER MINUTE)
-- ============================================

local function StartCPMTracking(player)
	local userId = player.UserId
	cpmTrackers[userId] = {
		clickCount = 0,
		startTime = os.clock(),
	}
end

local function UpdateCPM(player)
	local userId = player.UserId
	local tracker = cpmTrackers[userId]
	if not tracker then
		StartCPMTracking(player)
		tracker = cpmTrackers[userId]
	end
	
	tracker.clickCount = tracker.clickCount + 1
	
	local elapsed = os.clock() - tracker.startTime
	if elapsed >= 60 then
		-- Reset window every 60 seconds
		tracker.clickCount = 1
		tracker.startTime = os.clock()
	elseif elapsed > 0 then
		-- Calculate current CPM
		local cpm = tracker.clickCount * (60 / elapsed)
		
		-- Check if CPM meets any quest goal
		local data = playerCache[userId]
		if not data then return end
		
		for _, questType in ipairs({"daily", "weekly", "lifetime"}) do
			local quests = QuestDefinitions[questType]
			if not quests then continue end
			
			for _, quest in ipairs(quests) do
				if quest.objective == "CLICKS_PER_MINUTE" then
					if cpm >= quest.goal and not data[questType].claimed[quest.id] then
						-- Mark as complete (binary: 1)
						UpdateProgress(player, "CLICKS_PER_MINUTE", 1)
					end
				end
			end
		end
	end
end

-- ============================================
-- PLAYTIME TRACKING
-- ============================================

local function StartPlaytimeTracking(player)
	local userId = player.UserId
	playtimeTrackers[userId] = true
	
	task.spawn(function()
		while playtimeTrackers[userId] and player.Parent do
			task.wait(60)
			if playtimeTrackers[userId] and player.Parent then
				local data = playerCache[userId]
				if data then
					data.lifetimeStats.totalPlaytimeMinutes = data.lifetimeStats.totalPlaytimeMinutes + 1
				end
				UpdateProgress(player, "PLAYTIME_MINUTES", 1)
			end
		end
	end)
end

local function StopPlaytimeTracking(player)
	playtimeTrackers[player.UserId] = nil
end

-- ============================================
-- PLAYER CONNECTIONS
-- ============================================

local function OnPlayerAdded(player)
	-- Load player data
	LoadData(player)
	
	-- Check and reset daily/weekly quests
	CheckAndResetDaily(player)
	CheckAndResetWeekly(player)
	
	-- Update login streak
	UpdateLoginStreak(player)
	
	-- Start CPM tracking
	StartCPMTracking(player)
	
	-- Start playtime tracking
	StartPlaytimeTracking(player)
end

local function OnPlayerRemoving(player)
	local userId = player.UserId
	
	-- Mark as no longer loading (race condition protection)
	loadingPlayers[userId] = nil
	
	-- Stop playtime tracking
	StopPlaytimeTracking(player)
	
	-- Clean up CPM tracker
	cpmTrackers[userId] = nil
	
	-- Save data immediately when player leaves
	SaveData(player)
	
	-- Clean up cache and dirty flag
	playerCache[userId] = nil
	dirtyPlayers[userId] = nil
end

-- ============================================
-- REMOTE FUNCTION HANDLERS
-- ============================================

getQuestDataRemote.OnServerInvoke = function(player)
	local userId = player.UserId
	local data = playerCache[userId]
	
	if not data then
		-- Try to load if not in cache
		data = LoadData(player)
	end
	
	return {
		quests = QuestDefinitions,
		progress = data,
	}
end

-- ============================================
-- CLAIM QUEST HANDLER
-- ============================================

claimQuestRemote.OnServerEvent:Connect(function(player, questId)
	local userId = player.UserId
	local data = playerCache[userId]
	if not data then return end
	
	-- Find the quest definition
	local quest = nil
	local questType = nil
	
	for _, qType in ipairs({"daily", "weekly", "lifetime"}) do
		for _, q in ipairs(QuestDefinitions[qType]) do
			if q.id == questId then
				quest = q
				questType = qType
				break
			end
		end
		if quest then break end
	end
	
	if not quest then
		warn("Quest not found: " .. tostring(questId))
		return
	end
	
	-- Check if already claimed
	if data[questType].claimed[questId] then
		return -- Already claimed
	end
	
	-- Check if quest is complete
	local progress = data[questType].progress[questId] or 0
	if progress < quest.goal then
		return -- Not complete yet
	end
	
	-- Mark as claimed
	data[questType].claimed[questId] = true
	dirtyPlayers[userId] = true
	
	-- Update leaderstats
	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		local statName = string.upper(string.sub(questType, 1, 1)) .. string.lower(string.sub(questType, 2))
		local statValue = leaderstats:FindFirstChild(statName)
		if statValue then
			statValue.Value = statValue.Value + 1
		end
	end
	
	-- ============================================
	-- GIVE REWARDS
	-- ============================================
	
	local reward = quest.reward
	
	-- Give Stardust reward
	if reward.stardust and reward.stardust > 0 then
		-- Use existing ItemStardustEvent that GameLogic listens to
		itemStardustEvent:Fire(player, reward.stardust)
		print("[QuestManager] " .. player.Name .. " earned " .. reward.stardust .. " stardust from quest " .. questId)
	end
	
	-- Give Title reward
	if reward.title then
		-- Store title in player's quest data (no existing title system)
		if not data.unlockedTitles then
			data.unlockedTitles = {}
		end
		table.insert(data.unlockedTitles, reward.title)
		print("[QuestManager] " .. player.Name .. " unlocked title: " .. reward.title)
	end
	
	-- Give Multiplier reward
	if reward.multiplier then
		-- Store multiplier bonus in player's quest data
		if not data.multiplierBonuses then
			data.multiplierBonuses = {}
		end
		table.insert(data.multiplierBonuses, {
			source = "Quest: " .. quest.name,
			multiplier = reward.multiplier,
			unlockedAt = os.time(),
		})
		print("[QuestManager] " .. player.Name .. " unlocked multiplier: " .. reward.multiplier .. "x from quest " .. questId)
	end
	
	-- Give Item reward
	if reward.item then
		-- Use BindableEvent to add item to player's inventory (server-side)
		questItemRewardEvent:Fire(player, reward.item, 1)
		print("[QuestManager] " .. player.Name .. " received item: " .. reward.item .. " from quest " .. questId)
	end
	
	-- Fire claimed event to client
	questClaimedRemote:FireClient(player, {
		questId = questId,
		reward = quest.reward,
	})
end)

-- ============================================
-- BINDABLE EVENT CONNECTIONS
-- ============================================

onClickEvent.Event:Connect(function(player, amount)
	print("[QuestManager] OnClick event received from " .. player.Name .. " for " .. amount .. " clicks")
	local data = playerCache[player.UserId]
	if data then
		data.lifetimeStats.totalClicks = data.lifetimeStats.totalClicks + amount
		print("[QuestManager] Total clicks for " .. player.Name .. ": " .. data.lifetimeStats.totalClicks)
	else
		warn("[QuestManager] No data found for " .. player.Name)
	end
	
	UpdateProgress(player, "CLICKS", amount)
	UpdateProgress(player, "TOTAL_LIFETIME_CLICKS", amount)
	UpdateCPM(player)
end)

onStardustEarnedEvent.Event:Connect(function(player, amount)
	local data = playerCache[player.UserId]
	if data then
		data.lifetimeStats.totalStardustEarned = data.lifetimeStats.totalStardustEarned + amount
	end
	
	UpdateProgress(player, "STARDUST_EARNED", amount)
	UpdateProgress(player, "TOTAL_LIFETIME_STARDUST", amount)
end)

onStardustSpentEvent.Event:Connect(function(player, amount)
	local data = playerCache[player.UserId]
	if data then
		data.lifetimeStats.totalStardustSpent = data.lifetimeStats.totalStardustSpent + amount
	end
	
	UpdateProgress(player, "STARDUST_SPENT", amount)
end)

onItemUsedEvent.Event:Connect(function(player)
	UpdateProgress(player, "ITEMS_USED", 1)
end)

onItemBoughtEvent.Event:Connect(function(player)
	local data = playerCache[player.UserId]
	if data then
		data.lifetimeStats.totalItemsBought = data.lifetimeStats.totalItemsBought + 1
	end
	
	UpdateProgress(player, "ITEMS_BOUGHT", 1)
end)

onLevelUpEvent.Event:Connect(function(player, newLevel)
	local data = playerCache[player.UserId]
	if data and newLevel > data.lifetimeStats.maxLevel then
		data.lifetimeStats.maxLevel = newLevel
	end
	
	UpdateProgress(player, "LEVELS_GAINED", 1)
	UpdateProgress(player, "LEVEL_REACHED", newLevel)
end)

-- ============================================
-- DEBOUNCE SAVE LOOP
-- ============================================

task.spawn(function()
	while true do
		task.wait(5)
		for userId, isDirty in pairs(dirtyPlayers) do
			if isDirty then
				local player = Players:GetPlayerByUserId(userId)
				if player then
					SaveData(player)
					dirtyPlayers[userId] = false
				end
			end
		end
	end
end)

-- ============================================
-- GAME CLOSE HANDLER
-- ============================================

game:BindToClose(function()
	-- Save all players
	for _, player in ipairs(Players:GetPlayers()) do
		SaveData(player)
	end
end)

-- ============================================
-- INITIALIZE FOR EXISTING PLAYERS
-- ============================================

-- Handle players already in the game
for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(function()
		OnPlayerAdded(player)
	end)
end

-- Connect events for new players (use task.spawn to avoid blocking)
Players.PlayerAdded:Connect(function(player)
	task.spawn(function()
		OnPlayerAdded(player)
	end)
end)
Players.PlayerRemoving:Connect(OnPlayerRemoving)

-- PART 3 COMPLETE