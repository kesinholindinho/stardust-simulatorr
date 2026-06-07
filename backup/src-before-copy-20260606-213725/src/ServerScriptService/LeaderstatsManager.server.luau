local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Reference to QuestManager's questRemotes
local questRemotes = ReplicatedStorage:WaitForChild("QuestRemotes")
local getQuestDataRemote = questRemotes:WaitForChild("GetQuestData")

-- ============================================
-- CREATE LEADERSTATS FOR PLAYER
-- ============================================

local function CreateLeaderstats(player)
	-- Check if leaderstats already exists
	local existingLeaderstats = player:FindFirstChild("leaderstats")
	if existingLeaderstats then
		existingLeaderstats:Destroy()
	end
	
	-- Create leaderstats folder
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player
	
	-- Create Daily quests completed
	local dailyValue = Instance.new("IntValue")
	dailyValue.Name = "Daily"
	dailyValue.Value = 0
	dailyValue.Parent = leaderstats
	
	-- Create Weekly quests completed
	local weeklyValue = Instance.new("IntValue")
	weeklyValue.Name = "Weekly"
	weeklyValue.Value = 0
	weeklyValue.Parent = leaderstats
	
	-- Create Lifetime quests completed
	local lifetimeValue = Instance.new("IntValue")
	lifetimeValue.Name = "Lifetime"
	lifetimeValue.Value = 0
	lifetimeValue.Parent = leaderstats
	
	return leaderstats
end

-- ============================================
-- UPDATE LEADERSTATS FROM QUEST DATA
-- ============================================

local function UpdateLeaderstats(player, questData)
	if not questData then return end
	
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then
		leaderstats = CreateLeaderstats(player)
	end
	
	local dailyValue = leaderstats:FindFirstChild("Daily")
	local weeklyValue = leaderstats:FindFirstChild("Weekly")
	local lifetimeValue = leaderstats:FindFirstChild("Lifetime")
	
	-- Count completed quests for each type
	local dailyCount = 0
	local weeklyCount = 0
	local lifetimeCount = 0
	
	if questData.daily and questData.daily.claimed then
		for _ in pairs(questData.daily.claimed) do
			dailyCount = dailyCount + 1
		end
	end
	
	if questData.weekly and questData.weekly.claimed then
		for _ in pairs(questData.weekly.claimed) do
			weeklyCount = weeklyCount + 1
		end
	end
	
	if questData.lifetime and questData.lifetime.claimed then
		for _ in pairs(questData.lifetime.claimed) do
			lifetimeCount = lifetimeCount + 1
		end
	end
	
	-- Update values
	if dailyValue then
		dailyValue.Value = dailyCount
	end
	if weeklyValue then
		weeklyValue.Value = weeklyCount
	end
	if lifetimeValue then
		lifetimeValue.Value = lifetimeCount
	end
end

-- ============================================
-- PLAYER CONNECTIONS
-- ============================================

local function OnPlayerAdded(player)
	-- Wait a bit for QuestManager to load data
	task.wait(1)
	
	-- Create leaderstats
	CreateLeaderstats(player)
	
	-- Request quest data from QuestManager and update leaderstats
	local success, result = pcall(function()
		return getQuestDataRemote:InvokeServer()
	end)
	
	if success and result and result.progress then
		UpdateLeaderstats(player, result.progress)
	end
end

-- Handle existing players
for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(function()
		OnPlayerAdded(player)
	end)
end

-- Handle new players
Players.PlayerAdded:Connect(function(player)
	task.spawn(function()
		OnPlayerAdded(player)
	end)
end)

-- Clean up when player leaves
Players.PlayerRemoving:Connect(function(player)
	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		leaderstats:Destroy()
	end
end)

print("[LeaderstatsManager] Loaded successfully!")