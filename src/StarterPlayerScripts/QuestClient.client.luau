-- QuestClient script - DISABLED
-- Quest logic has been integrated into the QuestsPanel module
-- This script is no longer needed and is kept for reference only
return

local player = Players.LocalPlayer

-- Wait for GUI to load
local playerGui = player:WaitForChild("PlayerGui")
local stardustUI = playerGui:WaitForChild("StardustUI")

-- Remote references
local questRemotes = ReplicatedStorage:WaitForChild("QuestRemotes")
local getQuestDataRemote = questRemotes:WaitForChild("GetQuestData")
local claimQuestRemote = questRemotes:WaitForChild("ClaimQuest")
local questProgressUpdatedRemote = questRemotes:WaitForChild("QuestProgressUpdated")
local questClaimedRemote = questRemotes:WaitForChild("QuestClaimed")

-- UI references
local questsPanel = stardustUI:WaitForChild("QuestsPanel")
local questList = questsPanel:WaitForChild("QuestList")
local template = questList:WaitForChild("Template")
local tabContainer = questsPanel:WaitForChild("TabContainer")
local dailyTab = tabContainer:WaitForChild("DailyTab")
local weeklyTab = tabContainer:WaitForChild("WeeklyTab")
local lifetimeTab = tabContainer:WaitForChild("LifetimeTab")
local closeButton = questsPanel:WaitForChild("CloseButton")
local questsBtnFrame = stardustUI.BottomBar.ButtonContainer:WaitForChild("QuestsBtn")
local questsBtn = questsBtnFrame:WaitForChild("ClickDetector")
print("[QuestClient] questsBtn type:", questsBtn.ClassName)

-- State
local currentTab = "daily"
local questData = nil
local questCards = {} -- [questId] = cardFrame
local questTypes = {} -- [questId] = "daily"/"weekly"/"lifetime"
local toggleDebounce = false -- Prevent double clicks

-- ============================================
-- HELPER FUNCTIONS
-- ============================================

local function formatReward(reward)
	local parts = {}
	
	if reward.stardust then
		table.insert(parts, "+ " .. reward.stardust .. " Stardust")
	end
	
	if reward.title then
		table.insert(parts, "Title: " .. reward.title)
	end
	
	if reward.multiplier then
		table.insert(parts, "+" .. reward.multiplier .. "x Multiplier")
	end
	
	if reward.item then
		table.insert(parts, "Item: " .. reward.item)
	end
	
	return table.concat(parts, ", ")
end

local function setActiveTab(tabName)
	currentTab = tabName
	
	-- Update tab button colors
	local activeColor = Color3.fromRGB(76, 175, 80)
	local inactiveColor = Color3.fromRGB(66, 66, 66)
	
	dailyTab.BackgroundColor3 = tabName == "daily" and activeColor or inactiveColor
	weeklyTab.BackgroundColor3 = tabName == "weekly" and activeColor or inactiveColor
	lifetimeTab.BackgroundColor3 = tabName == "lifetime" and activeColor or inactiveColor
	
	-- Show/hide cards based on type
	for questId, card in pairs(questCards) do
		local questType = questTypes[questId]
		card.Visible = (questType == tabName)
	end
end

-- ============================================
-- POPULATE UI
-- ============================================

local function PopulateUI(data)
	if not data then
		warn("[QuestClient] Cannot populate UI - no data")
		return
	end
	
	questData = data
	local quests = data.quests
	local progress = data.progress
	
	-- Validate quests and progress tables exist
	if not quests then
		warn("[QuestClient] Cannot populate UI - quests is nil")
		return
	end
	if not progress then
		warn("[QuestClient] Cannot populate UI - progress is nil")
		return
	end
	
	-- Clear existing cards (except template)
	for questId, card in pairs(questCards) do
		card:Destroy()
	end
	questCards = {}
	questTypes = {}
	
	-- Process each quest type
	local questTypesList = {"daily", "weekly", "lifetime"}
	
	for _, questType in ipairs(questTypesList) do
		local questListForType = quests[questType]
		if not questListForType then continue end
		
		for _, quest in ipairs(questListForType) do
			-- Clone template
			local card = template:Clone()
			card.Name = quest.id
			card.Visible = (questType == currentTab)
			card.Parent = questList
			
			-- Store references
			questCards[quest.id] = card
			questTypes[quest.id] = questType
			
			-- Get progress data (with nil safety)
			local progressData = progress[questType]
			if not progressData then continue end
			local questProgress = progressData.progress and progressData.progress[quest.id] or 0
			local isClaimed = progressData.claimed and progressData.claimed[quest.id] or false
			
			-- Set quest info
			card:FindFirstChild("QuestName").Text = quest.name
			card:FindFirstChild("QuestDesc").Text = quest.description
			card:FindFirstChild("RewardLabel").Text = formatReward(quest.reward)
			
			-- Set progress bar
			local pct = math.min(questProgress / quest.goal, 1)
			card:FindFirstChild("ProgressBar"):FindFirstChild("Fill").Size = UDim2.new(pct, 0, 1, 0)
			card:FindFirstChild("ProgressText").Text = tostring(questProgress) .. " / " .. tostring(quest.goal)
			
			-- Claim button state
			local claimBtn = card:FindFirstChild("ClaimBtn")
			local claimedLabel = card:FindFirstChild("ClaimedLabel")
			
			if isClaimed then
				-- Already claimed
				claimBtn.Active = false
				claimBtn.Visible = false
				claimedLabel.Visible = true
				card.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
			elseif questProgress >= quest.goal then
				-- Ready to claim
				claimBtn.Active = true
				claimBtn.Visible = true
				claimBtn.BackgroundColor3 = Color3.fromRGB(255, 193, 7)
				claimedLabel.Visible = false
			else
				-- In progress
				claimBtn.Active = false
				claimBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
				claimBtn.Visible = true
				claimedLabel.Visible = false
			end
			
			-- Connect claim button
			claimBtn.MouseButton1Click:Connect(function()
				if not claimBtn.Active then return end
				
				claimBtn.Active = false
				claimBtn.Text = "..."
				claimQuestRemote:FireServer(quest.id)
			end)
		end
	end
	
	-- Hide template
	template.Visible = false
end

-- ============================================
-- PROGRESS UPDATE HANDLER
-- ============================================

questProgressUpdatedRemote.OnClientEvent:Connect(function(data)
	local questId = data.questId
	local progress = data.progress
	local goal = data.goal
	
	local card = questCards[questId]
	if not card then return end
	
	-- Update progress bar
	local pct = math.min(progress / goal, 1)
	card:FindFirstChild("ProgressBar"):FindFirstChild("Fill").Size = UDim2.new(pct, 0, 1, 0)
	card:FindFirstChild("ProgressText").Text = tostring(progress) .. " / " .. tostring(goal)
	
	-- If complete and not claimed, enable claim button with animation
	local claimBtn = card:FindFirstChild("ClaimBtn")
	local claimedLabel = card:FindFirstChild("ClaimedLabel")
	
	if progress >= goal and not claimedLabel.Visible then
		claimBtn.Active = true
		claimBtn.BackgroundColor3 = Color3.fromRGB(255, 193, 7)
		
		-- Play highlight animation
		local originalSize = card.Size
		local tweenInfo = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		
		local scaleUp = TweenService:Create(card, tweenInfo, {
			Size = UDim2.new(card.Size.X.Scale, card.Size.X.Offset + 5, card.Size.Y.Scale, card.Size.Y.Offset + 5),
			BackgroundColor3 = Color3.fromRGB(65, 65, 80)
		})
		local scaleDown = TweenService:Create(card, tweenInfo, {
			Size = originalSize,
			BackgroundColor3 = Color3.fromRGB(45, 45, 55)
		})
		
		scaleUp:Play()
		task.wait(0.15)
		scaleDown:Play()
		
		-- Play sound if available
		local successSound = SoundService:FindFirstChild("QuestComplete")
		if successSound then
			successSound:Play()
		end
	end
end)

-- ============================================
-- QUEST CLAIMED HANDLER
-- ============================================

questClaimedRemote.OnClientEvent:Connect(function(data)
	local questId = data.questId
	local reward = data.reward
	
	local card = questCards[questId]
	if not card then return end
	
	-- Update card state
	local claimBtn = card:FindFirstChild("ClaimBtn")
	local claimedLabel = card:FindFirstChild("ClaimedLabel")
	
	claimBtn.Active = false
	claimBtn.Visible = false
	claimedLabel.Visible = true
	card.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
	
	-- Create reward popup
	local popup = Instance.new("Frame")
	popup.Name = "RewardPopup"
	popup.Size = UDim2.new(0, 300, 0, 80)
	popup.Position = UDim2.new(0.5, -150, 0.5, -40)
	popup.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
	popup.BorderSizePixel = 0
	popup.Parent = stardustUI
	
	local popupCorner = Instance.new("UICorner")
	popupCorner.Parent = popup
	
	local popupStroke = Instance.new("UIStroke")
	popupStroke.Color = Color3.fromRGB(76, 175, 80)
	popupStroke.Thickness = 2
	popupStroke.Parent = popup
	
	local popupText = Instance.new("TextLabel")
	popupText.Size = UDim2.new(1, 0, 1, 0)
	popupText.BackgroundTransparency = 1
	popupText.TextColor3 = Color3.new(1, 1, 1)
	popupText.Font = Enum.Font.GothamBold
	popupText.TextSize = 18
	popupText.Text = ""
	
	-- Build reward text
	local rewardText = ""
	if reward.stardust then
		rewardText = "+ " .. reward.stardust .. " Stardust!"
	elseif reward.title then
		rewardText = "Title unlocked: " .. reward.title .. "!"
	elseif reward.multiplier then
		rewardText = "+" .. reward.multiplier .. "x Multiplier!"
	elseif reward.item then
		rewardText = "Item received: " .. reward.item .. "!"
	else
		rewardText = "Reward claimed!"
	end
	
	popupText.Text = rewardText
	popupText.Parent = popup
	
	-- Animate popup
	popup.BackgroundTransparency = 1
	popupText.TextTransparency = 1
	
	local fadeIn = TweenService:Create(popup, TweenInfo.new(0.3), {BackgroundTransparency = 0})
	local textFadeIn = TweenService:Create(popupText, TweenInfo.new(0.3), {TextTransparency = 0})
	
	fadeIn:Play()
	textFadeIn:Play()
	
	task.wait(2)
	
	local fadeOut = TweenService:Create(popup, TweenInfo.new(0.3), {BackgroundTransparency = 1})
	local textFadeOut = TweenService:Create(popupText, TweenInfo.new(0.3), {TextTransparency = 1})
	
	fadeOut:Play()
	textFadeOut:Play()
	
	task.wait(0.3)
	popup:Destroy()
end)

-- ============================================
-- TAB BUTTON HANDLERS
-- ============================================

dailyTab.MouseButton1Click:Connect(function()
	setActiveTab("daily")
end)

weeklyTab.MouseButton1Click:Connect(function()
	setActiveTab("weekly")
end)

lifetimeTab.MouseButton1Click:Connect(function()
	setActiveTab("lifetime")
end)

-- ============================================
-- PANEL TOGGLE
-- ============================================

questsBtn.MouseButton1Click:Connect(function()
	if toggleDebounce then return end
	toggleDebounce = true
	
	questsPanel.Visible = not questsPanel.Visible
	
	task.wait(0.2)
	toggleDebounce = false
end)

closeButton.MouseButton1Click:Connect(function()
	questsPanel.Visible = false
end)

-- ============================================
-- INITIALIZATION
-- ============================================

-- Wait for character to load
if not player.Character then
	player.CharacterAdded:Wait()
end

task.wait(1) -- Give GUI time to fully load

-- Request quest data from server (with retry)
local maxRetries = 3
local retryDelay = 2
local dataLoaded = false

for attempt = 1, maxRetries do
	local success, data = pcall(function()
		return getQuestDataRemote:InvokeServer()
	end)
	
	if success and data and data.quests and data.progress then
		PopulateUI(data)
		setActiveTab("daily") -- Default to daily tab
		
		local dailyCount = data.quests.daily and #data.quests.daily or 0
		local weeklyCount = data.quests.weekly and #data.quests.weekly or 0
		local lifetimeCount = data.quests.lifetime and #data.quests.lifetime or 0
		print("[QuestClient] Loaded " .. dailyCount .. " daily, " .. weeklyCount .. " weekly, " .. lifetimeCount .. " lifetime quests")
		dataLoaded = true
		break
	else
		warn("[QuestClient] Attempt " .. attempt .. "/" .. maxRetries .. " failed to load quest data")
		if attempt < maxRetries then
			task.wait(retryDelay)
		end
	end
end

if not dataLoaded then
	warn("[QuestClient] Failed to load quest data after " .. maxRetries .. " attempts")
end

-- PART 4 COMPLETE