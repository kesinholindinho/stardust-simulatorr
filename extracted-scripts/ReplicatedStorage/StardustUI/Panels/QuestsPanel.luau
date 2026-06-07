local QuestsPanel = {}

local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PanelManager = require(ReplicatedStorage:WaitForChild("StardustUI"):WaitForChild("PanelManager"))
local SettingsPanel = require(ReplicatedStorage:WaitForChild("StardustUI"):WaitForChild("Panels"):WaitForChild("SettingsPanel"))

-- ============================================
-- STATE
-- ============================================
local panel = nil
local questList = nil
local template = nil
local tabContainer = nil
local dailyTab = nil
local weeklyTab = nil
local lifetimeTab = nil
local closeButton = nil

local currentTab = "daily"
local questData = nil
local questCards = {} -- [questId] = cardFrame
local questTypes = {} -- [questId] = "daily"/"weekly"/"lifetime"
local connections = {}

-- Remote references
local questRemotes = ReplicatedStorage:WaitForChild("QuestRemotes")
local getQuestDataRemote = questRemotes:WaitForChild("GetQuestData")
local claimQuestRemote = questRemotes:WaitForChild("ClaimQuest")
local questProgressUpdatedRemote = questRemotes:WaitForChild("QuestProgressUpdated")
local questClaimedRemote = questRemotes:WaitForChild("QuestClaimed")

-- ============================================
-- HELPER FUNCTIONS
-- ============================================

local function formatReward(reward)
	local parts = {}
	if reward.stardust and reward.stardust > 0 then
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
	if #parts == 0 then
		table.insert(parts, "Reward claimed!")
	end
	return table.concat(parts, ", ")
end

local function setActiveTab(tabName)
	currentTab = tabName

	local activeColor = Color3.fromRGB(76, 175, 80)
	local inactiveColor = Color3.fromRGB(66, 66, 66)

	if dailyTab then
		dailyTab.BackgroundColor3 = tabName == "daily" and activeColor or inactiveColor
	end
	if weeklyTab then
		weeklyTab.BackgroundColor3 = tabName == "weekly" and activeColor or inactiveColor
	end
	if lifetimeTab then
		lifetimeTab.BackgroundColor3 = tabName == "lifetime" and activeColor or inactiveColor
	end

	-- Show/hide cards based on type
	for questId, card in pairs(questCards) do
		local qType = questTypes[questId]
		if card then
			card.Visible = (qType == tabName)
		end
	end
end

-- ============================================
-- POPULATE UI
-- ============================================

local function PopulateUI(data)
	if not data then
		warn("[QuestsPanel] Cannot populate UI - no data")
		return
	end

	questData = data
	local quests = data.quests
	local progress = data.progress

	if not quests then
		warn("[QuestsPanel] Cannot populate UI - quests is nil")
		return
	end
	if not progress then
		warn("[QuestsPanel] Cannot populate UI - progress is nil")
		return
	end

	-- Clear existing cards (except template)
	for questId, card in pairs(questCards) do
		if card then card:Destroy() end
	end
	questCards = {}
	questTypes = {}

	if not questList or not template then return end

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
			local questNameLabel = card:FindFirstChild("QuestName")
			if questNameLabel then
				questNameLabel.Text = quest.name
			end

			local questDescLabel = card:FindFirstChild("QuestDesc")
			if questDescLabel then
				questDescLabel.Text = quest.description
			end

			local rewardLabel = card:FindFirstChild("RewardLabel")
			if rewardLabel then
				rewardLabel.Text = formatReward(quest.reward)
			end

			-- Set progress bar
			local pct = math.min(questProgress / quest.goal, 1)
			local progressBar = card:FindFirstChild("ProgressBar")
			if progressBar then
				local fill = progressBar:FindFirstChild("Fill")
				if fill then
					fill.Size = UDim2.new(pct, 0, 1, 0)
				end
			end

			local progressText = card:FindFirstChild("ProgressText")
			if progressText then
				progressText.Text = tostring(questProgress) .. " / " .. tostring(quest.goal)
			end

			-- Claim button state
			local claimBtn = card:FindFirstChild("ClaimBtn")
			local claimedLabel = card:FindFirstChild("ClaimedLabel")

			if isClaimed then
				-- Already claimed
				if claimBtn then claimBtn.Active = false; claimBtn.Visible = false end
				if claimedLabel then claimedLabel.Visible = true end
				card.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
			elseif questProgress >= quest.goal then
				-- Ready to claim
				if claimBtn then
					claimBtn.Active = true
					claimBtn.Visible = true
					claimBtn.BackgroundColor3 = Color3.fromRGB(255, 193, 7)
				end
				if claimedLabel then claimedLabel.Visible = false end
			else
				-- In progress
				if claimBtn then
					claimBtn.Active = false
					claimBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
					claimBtn.Visible = true
				end
				if claimedLabel then claimedLabel.Visible = false end
			end

			-- Connect claim button
			if claimBtn then
				claimBtn.MouseButton1Click:Connect(function()
					if not claimBtn.Active then return end
					claimBtn.Active = false
					claimBtn.Text = "..."
					claimQuestRemote:FireServer(quest.id)
				end)
			end
		end
	end

	-- Hide template
	template.Visible = false

	-- Update canvas size
	if questList then
		local layout = questList:FindFirstChildOfClass("UIListLayout")
		if layout then
			questList.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 20)
		end
	end
end

-- ============================================
-- PROGRESS UPDATE HANDLER
-- ============================================

local function onProgressUpdated(data)
	local questId = data.questId
	local progress = data.progress
	local goal = data.goal

	local card = questCards[questId]
	if not card then return end

	-- Update progress bar
	local pct = math.min(progress / goal, 1)
	local progressBar = card:FindFirstChild("ProgressBar")
	if progressBar then
		local fill = progressBar:FindFirstChild("Fill")
		if fill then
			fill.Size = UDim2.new(pct, 0, 1, 0)
		end
	end

	local progressText = card:FindFirstChild("ProgressText")
	if progressText then
		progressText.Text = tostring(progress) .. " / " .. tostring(goal)
	end

	-- If complete and not claimed, enable claim button
	local claimBtn = card:FindFirstChild("ClaimBtn")
	local claimedLabel = card:FindFirstChild("ClaimedLabel")

	if progress >= goal and claimBtn and claimedLabel and not claimedLabel.Visible then
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
		if SettingsPanel.soundEnabled() then
			local successSound = SoundService:FindFirstChild("QuestComplete")
			if successSound then
				successSound:Play()
			end
		end
	end
end

-- ============================================
-- QUEST CLAIMED HANDLER
-- ============================================

local function onQuestClaimed(data)
	local questId = data.questId
	local reward = data.reward

	local card = questCards[questId]
	if not card then return end

	-- Update card state
	local claimBtn = card:FindFirstChild("ClaimBtn")
	local claimedLabel = card:FindFirstChild("ClaimedLabel")

	if claimBtn then
		claimBtn.Active = false
		claimBtn.Visible = false
	end
	if claimedLabel then
		claimedLabel.Visible = true
	end
	card.BackgroundColor3 = Color3.fromRGB(35, 35, 45)

	-- Build reward text
	local rewardText = ""
	if reward then
		if reward.stardust and reward.stardust > 0 then
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
	end

	-- Create reward popup
	if panel then
		local popup = Instance.new("Frame")
		popup.Name = "RewardPopup"
		popup.Size = UDim2.new(0, 300, 0, 80)
		popup.Position = UDim2.new(0.5, -150, 0.5, -40)
		popup.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
		popup.BorderSizePixel = 0
		popup.ZIndex = 100
		popup.Parent = panel

		local popupCorner = Instance.new("UICorner")
		popupCorner.CornerRadius = UDim.new(0, 12)
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
		popupText.Text = rewardText
		popupText.ZIndex = 101
		popupText.Parent = popup

		-- Animate popup
		popup.BackgroundTransparency = 1
		popupText.TextTransparency = 1

		local fadeIn = TweenService:Create(popup, TweenInfo.new(0.3), {BackgroundTransparency = 0})
		local textFadeIn = TweenService:Create(popupText, TweenInfo.new(0.3), {TextTransparency = 0})

		fadeIn:Play()
		textFadeIn:Play()

		task.delay(2, function()
			if not popup or not popup.Parent then return end
			local fadeOut = TweenService:Create(popup, TweenInfo.new(0.3), {BackgroundTransparency = 1})
			local textFadeOut = TweenService:Create(popupText, TweenInfo.new(0.3), {TextTransparency = 1})

			fadeOut:Play()
			textFadeOut:Play()

			task.delay(0.3, function()
				if popup and popup.Parent then
					popup:Destroy()
				end
			end)
		end)
	end
end

-- ============================================
-- LOAD QUEST DATA
-- ============================================

local function loadQuestData()
	local maxRetries = 3
	local retryDelay = 2

	for attempt = 1, maxRetries do
		local success, data = pcall(function()
			return getQuestDataRemote:InvokeServer()
		end)

		if success and data and data.quests and data.progress then
			PopulateUI(data)
			setActiveTab("daily")

			local dailyCount = data.quests.daily and #data.quests.daily or 0
			local weeklyCount = data.quests.weekly and #data.quests.weekly or 0
			local lifetimeCount = data.quests.lifetime and #data.quests.lifetime or 0
			print("[QuestsPanel] Loaded " .. dailyCount .. " daily, " .. weeklyCount .. " weekly, " .. lifetimeCount .. " lifetime quests")
			return true
		else
			warn("[QuestsPanel] Attempt " .. attempt .. "/" .. maxRetries .. " failed to load quest data")
			if attempt < maxRetries then
				task.wait(retryDelay)
			end
		end
	end

	warn("[QuestsPanel] Failed to load quest data after " .. maxRetries .. " attempts")
	return false
end

-- ============================================
-- CREATE PANEL
-- ============================================

function QuestsPanel.create(screenGui)
	panel = screenGui:FindFirstChild("QuestsPanel")
	if not panel then
		warn("[QuestsPanel] Panel not found in screenGui")
		return
	end

	-- Find existing UI elements
	questList = panel:FindFirstChild("QuestList")
	template = questList and questList:FindFirstChild("Template")
	tabContainer = panel:FindFirstChild("TabContainer")
	closeButton = panel:FindFirstChild("CloseButton")

	if tabContainer then
		dailyTab = tabContainer:FindFirstChild("DailyTab")
		weeklyTab = tabContainer:FindFirstChild("WeeklyTab")
		lifetimeTab = tabContainer:FindFirstChild("LifetimeTab")
	end

	-- Remove the old "Content" frame if it was created by the previous version
	local oldContent = panel:FindFirstChild("Content")
	if oldContent then
		oldContent:Destroy()
	end

	-- Connect tab buttons
	if dailyTab then
		table.insert(connections, dailyTab.MouseButton1Click:Connect(function()
			setActiveTab("daily")
		end))
	end
	if weeklyTab then
		table.insert(connections, weeklyTab.MouseButton1Click:Connect(function()
			setActiveTab("weekly")
		end))
	end
	if lifetimeTab then
		table.insert(connections, lifetimeTab.MouseButton1Click:Connect(function()
			setActiveTab("lifetime")
		end))
	end

	-- Connect close button
	if closeButton then
		table.insert(connections, closeButton.MouseButton1Click:Connect(function()
			PanelManager.closeActivePanel()
		end))
	end

	-- Connect remote events
	table.insert(connections, questProgressUpdatedRemote.OnClientEvent:Connect(onProgressUpdated))
	table.insert(connections, questClaimedRemote.OnClientEvent:Connect(onQuestClaimed))

	-- Update canvas size when layout changes
	if questList then
		local layout = questList:FindFirstChildOfClass("UIListLayout")
		if layout then
			layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
				questList.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 20)
			end)
		end
	end

	-- Register panel with PanelManager
	PanelManager.registerPanel("QuestsPanel", panel)

	-- Load quest data asynchronously
	task.spawn(loadQuestData)

	print("[QuestsPanel] Created and registered")
end

-- ============================================
-- UPDATE (for external data pushes if needed)
-- ============================================

function QuestsPanel.update(data)
	if not panel then return end
	PopulateUI(data)
end

return QuestsPanel