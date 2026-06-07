-- ============================================
-- STARDUST SIMULATOR - QUEST SERVER
-- ============================================
-- Handles quest tracking, progress, and rewards

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Quest Remotes
local QuestRemotes = ReplicatedStorage:WaitForChild("QuestRemotes")
local GetQuestData = QuestRemotes:WaitForChild("GetQuestData")
local QuestClaimed = QuestRemotes:WaitForChild("QuestClaimed")
local QuestProgressUpdated = QuestRemotes:WaitForChild("QuestProgressUpdated")
local ClaimQuest = QuestRemotes:WaitForChild("ClaimQuest")

-- Configuration
local QuestDefinitions = require(ReplicatedStorage:WaitForChild("QuestDefinitions"))

-- ============================================
-- PLAYER QUEST DATA
-- ============================================
local playerQuestData = {}

local function getPlayerQuestData(player)
	if not playerQuestData[player.UserId] then
		playerQuestData[player.UserId] = {
			daily = {},
			weekly = {},
			lifetime = {},
			lastDailyReset = 0,
			lastWeeklyReset = 0,
		}
		
		-- Initialize quest progress
		local data = playerQuestData[player.UserId]
		
		for _, quest in ipairs(QuestDefinitions.daily) do
			data.daily[quest.id] = {
				progress = 0,
				completed = false,
				claimed = false,
			}
		end
		
		for _, quest in ipairs(QuestDefinitions.weekly) do
			data.weekly[quest.id] = {
				progress = 0,
				completed = false,
				claimed = false,
			}
		end
		
		for _, quest in ipairs(QuestDefinitions.lifetime) do
			data.lifetime[quest.id] = {
				progress = 0,
				completed = false,
				claimed = false,
			}
		end
	end
	
	return playerQuestData[player.UserId]
end

local function checkResetQuests(player)
	local data = getPlayerQuestData(player)
	local currentTime = os.time()
	local currentDay = math.floor(currentTime / 86400)
	local currentWeek = math.floor(currentTime / 604800) -- Weeks since epoch
	
	-- Reset daily quests if new day
	if data.lastDailyReset ~= currentDay then
		for questId, questData in pairs(data.daily) do
			questData.progress = 0
			questData.completed = false
			questData.claimed = false
		end
		data.lastDailyReset = currentDay
	end
	
	-- Reset weekly quests if new week
	if data.lastWeeklyReset ~= currentWeek then
		for questId, questData in pairs(data.weekly) do
			questData.progress = 0
			questData.completed = false
			questData.claimed = false
		end
		data.lastWeeklyReset = currentWeek
	end
end

-- ============================================
-- QUEST DATA REQUEST
-- ============================================
GetQuestData.OnServerInvoke = function(player)
	local data = getPlayerQuestData(player)
	checkResetQuests(player)
	
	-- Build response with quest definitions and progress
	local response = {
			daily = {},
			weekly = {},
			lifetime = {},
		}
	
	for _, quest in ipairs(QuestDefinitions.daily) do
		table.insert(response.daily, {
			id = quest.id,
			name = quest.name,
			description = quest.description,
			objective = quest.objective,
			goal = quest.goal,
			reward = quest.reward,
			difficulty = quest.difficulty,
			progress = data.daily[quest.id].progress,
			completed = data.daily[quest.id].completed,
			claimed = data.daily[quest.id].claimed,
		})
	end
	
	for _, quest in ipairs(QuestDefinitions.weekly) do
		table.insert(response.weekly, {
			id = quest.id,
			name = quest.name,
			description = quest.description,
			objective = quest.objective,
			goal = quest.goal,
			reward = quest.reward,
			difficulty = quest.difficulty,
			progress = data.weekly[quest.id].progress,
			completed = data.weekly[quest.id].completed,
			claimed = data.weekly[quest.id].claimed,
		})
	end
	
	for _, quest in ipairs(QuestDefinitions.lifetime) do
		table.insert(response.lifetime, {
			id = quest.id,
			name = quest.name,
			description = quest.description,
			objective = quest.objective,
			goal = quest.goal,
			reward = quest.reward,
			difficulty = quest.difficulty,
			progress = data.lifetime[quest.id].progress,
			completed = data.lifetime[quest.id].completed,
			claimed = data.lifetime[quest.id].claimed,
		})
	end
	
	return response
end

-- ============================================
-- QUEST CLAIMING
-- ============================================
ClaimQuest.OnServerEvent:Connect(function(player, questId, questType)
	local data = getPlayerQuestData(player)
	
	local questList = nil
	if questType == "daily" then
		questList = data.daily
	elseif questType == "weekly" then
		questList = data.weekly
	elseif questType == "lifetime" then
		questList = data.lifetime
	end
	
	if not questList or not questList[questId] then
		warn("[QuestServer] Invalid quest: " .. tostring(questId))
		return
	end
	
	local questData = questList[questId]
	
	if not questData.completed then
		warn("[QuestServer] Quest not completed: " .. questId)
		return
	end
	
	if questData.claimed then
		warn("[QuestServer] Quest already claimed: " .. questId)
		return
	end
	
	-- Mark as claimed
	questData.claimed = true
	
	-- Find quest definition for reward
	local questDef = nil
	for _, quest in ipairs(QuestDefinitions[questType]) do
		if quest.id == questId then
			questDef = quest
			break
		end
	end
	
	if questDef and questDef.reward then
		-- Fire claimed event with reward info
		QuestClaimed:FireClient(player, questId, questDef.reward)
		print("[QuestServer] " .. player.Name .. " claimed quest: " .. questId)
	end
end)

-- ============================================
-- QUEST PROGRESS UPDATE (called from GameLogic)
-- ============================================
function UpdateQuestProgress(player, objectiveType, amount)
	local data = getPlayerQuestData(player)
	checkResetQuests(player)
	
	amount = amount or 1
	
	-- Update all quest types
	local questTypes = {"daily", "weekly", "lifetime"}
	
	for _, questType in ipairs(questTypes) do
		for _, quest in ipairs(QuestDefinitions[questType]) do
			if quest.objective == objectiveType then
				local questData = data[questType][quest.id]
				if questData and not questData.completed then
					questData.progress = questData.progress + amount
					
					-- Check if completed
					if questData.progress >= quest.goal then
						questData.completed = true
						print("[QuestServer] " .. player.Name .. " completed quest: " .. quest.id)
					end
					
					-- Notify client of progress
					QuestProgressUpdated:FireClient(player, quest.id, questType, questData.progress, questData.completed)
				end
			end
		end
	end
end

-- ============================================
-- PLAYER CONNECTIONS
-- ============================================
Players.PlayerAdded:Connect(function(player)
	-- Initialize quest data
	getPlayerQuestData(player)
end)

Players.PlayerRemoving:Connect(function(player)
	playerQuestData[player.UserId] = nil
end)

-- Handle players already in game
for _, player in ipairs(Players:GetPlayers()) do
	getPlayerQuestData(player)
end

print("[QuestServer] Loaded successfully")