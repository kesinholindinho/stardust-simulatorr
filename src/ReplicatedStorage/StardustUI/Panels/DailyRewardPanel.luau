local DailyRewardPanel = {}

local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PanelManager = require(ReplicatedStorage:WaitForChild("StardustUI"):WaitForChild("PanelManager"))
local NetworkClient = require(ReplicatedStorage:WaitForChild("StardustUI"):WaitForChild("NetworkClient"))

-- ============================================
-- CONSTANTS
-- ============================================
local CARD_WIDTH = 80
local CARD_HEIGHT = 110
local CARD_SIZE = UDim2.new(0, CARD_WIDTH, 0, CARD_HEIGHT)
local CONNECTOR_WIDTH = 20
local BUTTON_HEIGHT = 44
local PANEL_PADDING = 20
local CORNER_RADIUS = 8
local PANEL_CORNER_RADIUS = 10
local STROKE_THICKNESS = 1

-- Animation constants
local PULSE_DURATION = 1.5
local HOVER_TWEEN_DURATION = 0.15
local OPEN_TWEEN_DURATION = 0.4

-- ============================================
-- STATE VARIABLES
-- ============================================
local panel = nil
local claimButton = nil
local cardsContainer = nil
local scrollFrame = nil
local currentDayData = {currentDay = 1, claimedDays = {}}
local activeTweens = {} -- Track active pulse animations
local isClaiming = false -- Debounce for claim button
local connections = {} -- Track all event connections for cleanup
local claimTimeout = nil -- Timeout for claim operation
local CLAIM_TIMEOUT_DURATION = 5 -- Seconds to wait before resetting claim state
local isPanelVisible = false -- Track panel visibility state
local animationsEnabled = true -- Toggle for animations (performance/accessibility)
local cycleLabel = nil -- "CYCLE X — Xm multiplier" label
local streakLabel = nil -- "Streak: X days" label
local nextCycleLabel = nil -- "Next cycle: Xm multiplier" label
local hasShownInitially = false -- Track if panel was shown on game start

-- ============================================
-- COLOR PALETTE (Minimalist Elegant)
-- ============================================
local COLORS = {
	BG = Color3.fromRGB(10, 10, 10),
	PANEL = Color3.fromRGB(16, 16, 16),
	CARD = Color3.fromRGB(22, 22, 22),
	CARD_TODAY = Color3.fromRGB(28, 28, 28),
	CARD_CLAIMED = Color3.fromRGB(16, 16, 16),
	BORDER = Color3.fromRGB(255, 255, 255),
	BORDER_CARD = Color3.fromRGB(50, 50, 50),
	BORDER_CLAIMED = Color3.fromRGB(40, 40, 40),
	BORDER_FUTURE = Color3.fromRGB(40, 40, 40),
	BORDER_TODAY = Color3.fromRGB(255, 255, 255),
	CONNECTOR = Color3.fromRGB(50, 50, 50),
	CONNECTOR_CLAIMED = Color3.fromRGB(255, 255, 255),
	TEXT_WHITE = Color3.fromRGB(255, 255, 255),
	TEXT_GRAY = Color3.fromRGB(120, 120, 120),
	TEXT_DIM = Color3.fromRGB(80, 80, 80),
	BUTTON_WHITE = Color3.fromRGB(255, 255, 255),
	BUTTON_BLACK = Color3.fromRGB(0, 0, 0),
	BUTTON_HOVER = Color3.fromRGB(220, 220, 220),
	BUTTON_CLAIMING = Color3.fromRGB(180, 180, 180),
	BUTTON_DISABLED = Color3.fromRGB(30, 30, 30),
}

-- ============================================
-- 7-DAY REWARDS DATA
-- ============================================
local DAILY_REWARDS = {
	{day = 1, amount = 100, icon = "🪙", name = "Stardust"},
	{day = 2, amount = 200, icon = "🪙", name = "Stardust"},
	{day = 3, amount = 300, icon = "💎", name = "Stardust"},
	{day = 4, amount = 500, icon = "🪙", name = "Stardust"},
	{day = 5, amount = 800, icon = "💎", name = "Stardust"},
	{day = 6, amount = 1000, icon = "🪙", name = "Stardust"},
	{day = 7, amount = 2000, icon = "🌟", name = "Stardust", special = true}
}

-- Base reward amounts for multiplier calculation
local BASE_REWARDS = {100, 200, 300, 500, 800, 1000, 2000}

-- ============================================
-- CLEANUP ALL TWEENS
-- ============================================
local function cleanupAllTweens()
	for card, tweens in pairs(activeTweens) do
		for _, tween in ipairs(tweens) do
			if tween then
				tween:Cancel()
			end
		end
	end
	activeTweens = {}
end

-- ============================================
-- CLEANUP ALL CONNECTIONS
-- ============================================
local function cleanupAllConnections()
	for _, connection in ipairs(connections) do
		if connection then
			connection:Disconnect()
		end
	end
	connections = {}
end

-- ============================================
-- FULL CLEANUP (Tweens + Connections + Timeout)
-- ============================================
local function fullCleanup()
	cleanupAllTweens()
	cleanupAllConnections()
	
	-- Cancel any pending claim timeout
	if claimTimeout then
		task.cancel(claimTimeout)
		claimTimeout = nil
	end
	
	isClaiming = false
end

-- ============================================
-- VALIDATE REWARD DATA
-- ============================================
local function validateReward(reward)
	if not reward then
		return false, "reward is nil"
	end
	if not reward.day or type(reward.day) ~= "number" then
		return false, "reward.day is missing or invalid"
	end
	if not reward.amount or type(reward.amount) ~= "number" then
		return false, "reward.amount is missing or invalid"
	end
	if not reward.icon or type(reward.icon) ~= "string" then
		return false, "reward.icon is missing or invalid"
	end
	if not reward.name or type(reward.name) ~= "string" then
		return false, "reward.name is missing or invalid"
	end
	return true, nil
end

-- ============================================
-- CREATE CONNECTOR LINE BETWEEN CARDS
-- ============================================
local function createConnector(parent, index)
	local connector = Instance.new("Frame")
	connector.Name = "Connector" .. index
	connector.Size = UDim2.new(0, CONNECTOR_WIDTH, 0, 2)
	connector.Position = UDim2.new(0, 0, 0, 0)
	connector.BackgroundColor3 = COLORS.CONNECTOR
	connector.BorderSizePixel = 0
	connector.ZIndex = 1
	connector.Parent = parent
	
	-- Center the connector vertically relative to cards
	connector.AnchorPoint = Vector2.new(0, 0.5)
	
	return connector
end

-- ============================================
-- CREATE CARD FOR A DAY
-- ============================================
local function createDayCard(parent, reward)
	-- Validate reward data
	local isValid, errMsg = validateReward(reward)
	if not isValid then
		warn("[DailyRewardPanel] Invalid reward data:", errMsg)
		return nil
	end
	
	local card = Instance.new("Frame")
	card.Name = "Day" .. reward.day
	card.Size = CARD_SIZE
	card.BackgroundColor3 = COLORS.CARD
	card.BorderSizePixel = 0
	card.ZIndex = 2
	card.Parent = parent
	
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, CORNER_RADIUS)
	corner.Parent = card
	
	local stroke = Instance.new("UIStroke")
	stroke.Name = "CardStroke"
	stroke.Color = COLORS.BORDER_CARD
	stroke.Thickness = STROKE_THICKNESS
	stroke.Parent = card
	
	-- Day label: "DAY X"
	local dayLabel = Instance.new("TextLabel")
	dayLabel.Name = "DayLabel"
	dayLabel.Size = UDim2.new(1, 0, 0, 16)
	dayLabel.Position = UDim2.new(0, 0, 0, 10)
	dayLabel.BackgroundTransparency = 1
	dayLabel.Text = "DAY " .. reward.day
	dayLabel.TextColor3 = COLORS.TEXT_GRAY
	dayLabel.TextSize = 11
	dayLabel.Font = Enum.Font.GothamBold
	dayLabel.ZIndex = 3
	dayLabel.Parent = card
	
	-- Reward amount
	local amountLabel = Instance.new("TextLabel")
	amountLabel.Name = "AmountLabel"
	amountLabel.Size = UDim2.new(1, 0, 0, 28)
	amountLabel.Position = UDim2.new(0, 0, 0, 36)
	amountLabel.BackgroundTransparency = 1
	amountLabel.Text = tostring(reward.amount)
	amountLabel.TextColor3 = COLORS.TEXT_WHITE
	amountLabel.TextSize = 22
	amountLabel.Font = Enum.Font.GothamBold
	amountLabel.ZIndex = 3
	amountLabel.Parent = card
	
	-- Name label: "Stardust"
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "NameLabel"
	nameLabel.Size = UDim2.new(1, 0, 0, 16)
	nameLabel.Position = UDim2.new(0, 0, 0, 72)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = reward.name
	nameLabel.TextColor3 = COLORS.TEXT_GRAY
	nameLabel.TextSize = 11
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.ZIndex = 3
	nameLabel.Parent = card
	
	-- Claimed checkmark (hidden by default, top right corner)
	local checkLabel = Instance.new("TextLabel")
	checkLabel.Name = "CheckMark"
	checkLabel.Size = UDim2.new(0, 20, 0, 20)
	checkLabel.Position = UDim2.new(1, -22, 0, 4)
	checkLabel.BackgroundTransparency = 1
	checkLabel.Text = "✓"
	checkLabel.TextColor3 = COLORS.TEXT_WHITE
	checkLabel.TextSize = 14
	checkLabel.Font = Enum.Font.GothamBold
	checkLabel.Visible = false
	checkLabel.ZIndex = 4
	checkLabel.Parent = card
	
	return card
end

-- ============================================
-- CREATE PANEL
-- ============================================
function DailyRewardPanel.create(screenGui)
	-- Cleanup any existing state before creating
	fullCleanup()
	
	-- Validate screenGui parameter
	if not screenGui or not screenGui:IsA("ScreenGui") then
		warn("[DailyRewardPanel] Invalid screenGui parameter")
		return
	end
	
	panel = screenGui:FindFirstChild("DailyRewardPanel")
	if not panel then
		warn("[DailyRewardPanel] Panel not found in screenGui")
		return
	end
	
	print("[DailyRewardPanel] Creating panel UI...")
	
	-- Clear existing content
	for _, child in ipairs(panel:GetChildren()) do
		if child.Name ~= "CloseButton" then
			child:Destroy()
		end
	end
	
	-- Set panel background and border
	panel.BackgroundColor3 = COLORS.PANEL
	panel.BorderSizePixel = 0
	panel.ClipsDescendants = true
	
	local panelCorner = Instance.new("UICorner")
	panelCorner.CornerRadius = UDim.new(0, PANEL_CORNER_RADIUS)
	panelCorner.Parent = panel
	
	local panelStroke = Instance.new("UIStroke")
	panelStroke.Name = "PanelStroke"
	panelStroke.Color = COLORS.BORDER
	panelStroke.Thickness = STROKE_THICKNESS
	panelStroke.Parent = panel
	
	-- Title: "DAILY REWARDS"
	local titleLabel = Instance.new("TextLabel")
	titleLabel.Name = "TitleLabel"
	titleLabel.Size = UDim2.new(1, -40, 0, 28)
	titleLabel.Position = UDim2.new(0, PANEL_PADDING, 0, PANEL_PADDING)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = "DAILY REWARDS"
	titleLabel.TextColor3 = COLORS.TEXT_WHITE
	titleLabel.TextSize = 22
	titleLabel.Font = Enum.Font.GothamBold
	titleLabel.ZIndex = 2
	titleLabel.Parent = panel
	
	-- Subtitle: "Come back every day"
	local subtitleLabel = Instance.new("TextLabel")
	subtitleLabel.Name = "SubtitleLabel"
	subtitleLabel.Size = UDim2.new(1, -40, 0, 18)
	subtitleLabel.Position = UDim2.new(0, PANEL_PADDING, 0, 48)
	subtitleLabel.BackgroundTransparency = 1
	subtitleLabel.Text = "Come back every day"
	subtitleLabel.TextColor3 = COLORS.TEXT_GRAY
	subtitleLabel.TextSize = 13
	subtitleLabel.Font = Enum.Font.GothamBold
	subtitleLabel.ZIndex = 2
	subtitleLabel.Parent = panel
	
	-- Thin white separator line below title
	local separator = Instance.new("Frame")
	separator.Name = "Separator"
	separator.Size = UDim2.new(1, -40, 0, 1)
	separator.Position = UDim2.new(0, PANEL_PADDING, 0, 72)
	separator.BackgroundColor3 = COLORS.BORDER
	separator.BorderSizePixel = 0
	separator.ZIndex = 2
	separator.Parent = panel
	
	-- Horizontal scrolling frame for cards
	scrollFrame = Instance.new("ScrollingFrame")
	scrollFrame.Name = "CardsScroll"
	scrollFrame.Size = UDim2.new(1, -32, 0, CARD_HEIGHT + 20)
	scrollFrame.Position = UDim2.new(0, PANEL_PADDING, 0, 86)
	scrollFrame.BackgroundTransparency = 1
	scrollFrame.BorderSizePixel = 0
	scrollFrame.ScrollBarThickness = 0
	scrollFrame.ScrollBarImageColor3 = Color3.fromRGB(50, 50, 50)
	scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
	scrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.X
	scrollFrame.ClipsDescendants = false
	scrollFrame.ZIndex = 1
	scrollFrame.Parent = panel
	
	-- Inner container for cards + connectors
	cardsContainer = Instance.new("Frame")
	cardsContainer.Name = "CardsContainer"
	cardsContainer.Size = UDim2.new(0, 7 * CARD_WIDTH + 6 * CONNECTOR_WIDTH + 24, 0, CARD_HEIGHT)
	cardsContainer.Position = UDim2.new(0, 0, 0, 10)
	cardsContainer.BackgroundTransparency = 1
	cardsContainer.ClipsDescendants = false
	cardsContainer.ZIndex = 1
	cardsContainer.Parent = scrollFrame
	
	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, 12)
	padding.PaddingRight = UDim.new(0, 12)
	padding.PaddingTop = UDim.new(0, 8)
	padding.PaddingBottom = UDim.new(0, 8)
	padding.Parent = cardsContainer
	
	-- Create cards and connectors in horizontal row
	local xOffset = 0
	for i, reward in ipairs(DAILY_REWARDS) do
		local card = createDayCard(cardsContainer, reward)
		if card then
			card.Position = UDim2.new(0, xOffset, 0, 0)
			xOffset = xOffset + CARD_WIDTH
			
			-- Add connector between cards (not after the last one)
			if i < #DAILY_REWARDS then
				local connector = createConnector(cardsContainer, i)
				connector.Position = UDim2.new(0, xOffset, 0, CARD_HEIGHT / 2)
				xOffset = xOffset + CONNECTOR_WIDTH
			end
		end
	end
	
	-- Cycle info label: "CYCLE X — Xm multiplier"
	cycleLabel = Instance.new("TextLabel")
	cycleLabel.Name = "CycleLabel"
	cycleLabel.Size = UDim2.new(1, -40, 0, 18)
	cycleLabel.Position = UDim2.new(0, PANEL_PADDING, 0, 222)
	cycleLabel.BackgroundTransparency = 1
	cycleLabel.Text = "CYCLE 1 — 1x multiplier"
	cycleLabel.TextColor3 = COLORS.TEXT_WHITE
	cycleLabel.TextSize = 13
	cycleLabel.Font = Enum.Font.GothamBold
	cycleLabel.ZIndex = 2
	cycleLabel.Parent = panel
	
	-- Streak label: "Streak: X days"
	streakLabel = Instance.new("TextLabel")
	streakLabel.Name = "StreakLabel"
	streakLabel.Size = UDim2.new(1, -40, 0, 16)
	streakLabel.Position = UDim2.new(0, PANEL_PADDING, 0, 242)
	streakLabel.BackgroundTransparency = 1
	streakLabel.Text = "Streak: 1 days"
	streakLabel.TextColor3 = COLORS.TEXT_GRAY
	streakLabel.TextSize = 12
	streakLabel.Font = Enum.Font.GothamBold
	streakLabel.ZIndex = 2
	streakLabel.Parent = panel
	
	-- Next cycle preview: "Next cycle: Xm multiplier"
	nextCycleLabel = Instance.new("TextLabel")
	nextCycleLabel.Name = "NextCycleLabel"
	nextCycleLabel.Size = UDim2.new(1, -40, 0, 16)
	nextCycleLabel.Position = UDim2.new(0, PANEL_PADDING, 0, 260)
	nextCycleLabel.BackgroundTransparency = 1
	nextCycleLabel.Text = "Next cycle: 3x multiplier"
	nextCycleLabel.TextColor3 = COLORS.TEXT_DIM
	nextCycleLabel.TextSize = 11
	nextCycleLabel.Font = Enum.Font.GothamBold
	nextCycleLabel.ZIndex = 2
	nextCycleLabel.Parent = panel
	
	-- Claim button (bottom center, hidden by default)
	claimButton = Instance.new("TextButton")
	claimButton.Name = "ClaimButton"
	claimButton.Size = UDim2.new(0, 220, 0, BUTTON_HEIGHT)
	claimButton.Position = UDim2.new(0.5, -110, 1, -60)
	claimButton.BackgroundColor3 = COLORS.BUTTON_WHITE
	claimButton.BorderSizePixel = 0
	claimButton.Text = "CLAIM — 100 Stardust"
	claimButton.TextColor3 = COLORS.BUTTON_BLACK
	claimButton.TextSize = 16
	claimButton.Font = Enum.Font.GothamBold
	claimButton.Visible = false
	claimButton.ZIndex = 5
	claimButton.Parent = panel
	
	local btnCorner = Instance.new("UICorner")
	btnCorner.CornerRadius = UDim.new(0, CORNER_RADIUS)
	btnCorner.Parent = claimButton
	
	-- Button hover effects
	table.insert(connections, claimButton.MouseEnter:Connect(function()
		if not isClaiming and claimButton.Active and animationsEnabled then
			TweenService:Create(claimButton, TweenInfo.new(HOVER_TWEEN_DURATION, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
				BackgroundColor3 = COLORS.BUTTON_HOVER
			}):Play()
		end
	end))
	
	table.insert(connections, claimButton.MouseLeave:Connect(function()
		if not isClaiming and claimButton.Active and animationsEnabled then
			local targetColor = claimButton.Active and COLORS.BUTTON_WHITE or COLORS.BUTTON_DISABLED
			TweenService:Create(claimButton, TweenInfo.new(HOVER_TWEEN_DURATION, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
				BackgroundColor3 = targetColor
			}):Play()
		end
	end))
	
	-- Claim button click with debounce and timeout
	table.insert(connections, claimButton.MouseButton1Click:Connect(function()
		if isClaiming then 
			print("[DailyRewardPanel] Claim already in progress, ignoring click")
			return 
		end
		isClaiming = true
		
		print("[DailyRewardPanel] Claim button clicked! Current day: " .. tostring(currentDayData.currentDay))
		
		-- Visual feedback during claim
		claimButton.Text = "CLAIMING..."
		claimButton.BackgroundColor3 = COLORS.BUTTON_CLAIMING
		
		-- Set timeout to reset state if server doesn't respond
		claimTimeout = task.delay(CLAIM_TIMEOUT_DURATION, function()
			-- Check if button still exists before modifying
			if isClaiming and claimButton and claimButton.Parent then
				warn("[DailyRewardPanel] Claim timeout - server did not respond")
				local displayDay = ((currentDayData.currentDay - 1) % 7) + 1
				local cycleNum = math.floor((currentDayData.currentDay - 1) / 7)
				local mult = math.max(1, cycleNum * 3)
				if cycleNum == 0 then mult = 1 end
				local retryAmount = BASE_REWARDS[displayDay] * mult
				claimButton.Text = "CLAIM — " .. retryAmount .. " Stardust"
				claimButton.BackgroundColor3 = COLORS.BUTTON_WHITE
				isClaiming = false
				claimTimeout = nil
			end
		end)
		
		local success, err = pcall(function()
			print("[DailyRewardPanel] Firing claimDailyReward to server with day: " .. tostring(currentDayData.currentDay))
			NetworkClient.claimDailyReward(currentDayData.currentDay)
			print("[DailyRewardPanel] FireServer completed successfully")
		end)
		
		if not success then
			-- Cancel timeout on error
			if claimTimeout then
				task.cancel(claimTimeout)
				claimTimeout = nil
			end
			
			warn("[DailyRewardPanel] Failed to claim reward:", err)
			
			-- Check if button still exists before modifying
			if claimButton and claimButton.Parent then
				local displayDay = ((currentDayData.currentDay - 1) % 7) + 1
				local cycleNum = math.floor((currentDayData.currentDay - 1) / 7)
				local mult = math.max(1, cycleNum * 3)
				if cycleNum == 0 then mult = 1 end
				local retryAmount = BASE_REWARDS[displayDay] * mult
				claimButton.Text = "CLAIM — " .. retryAmount .. " Stardust"
				claimButton.BackgroundColor3 = COLORS.BUTTON_WHITE
			end
			isClaiming = false
		end
		-- Success handling is done via notifyClaimSuccess when server responds
	end))
	
	-- Close button
	local dailyClose = panel:FindFirstChild("CloseButton")
	if not dailyClose then
		dailyClose = PanelManager.createCloseButton(panel)
	end
	
	-- Validate close button exists
	if not dailyClose then
		warn("[DailyRewardPanel] Failed to create close button")
	else
		table.insert(connections, dailyClose.MouseButton1Click:Connect(function()
			PanelManager.closeActivePanel()
		end))
	end
	
	-- Register panel with error handling
	local registerSuccess, registerErr = pcall(function()
		PanelManager.registerPanel("DailyRewardPanel", panel)
	end)
	if not registerSuccess then
		warn("[DailyRewardPanel] Failed to register panel:", registerErr)
	end
end

-- ============================================
-- SHOW PANEL
-- ============================================
function DailyRewardPanel.show()
	if panel then
		PanelManager.showPanel(panel)
		isPanelVisible = true
	end
end

-- ============================================
-- HIDE PANEL
-- ============================================
function DailyRewardPanel.hide()
	-- Only cleanup tweens when hiding (keep connections alive for re-show)
	cleanupAllTweens()
	
	if panel then
		-- Clear PanelManager state if this panel is the active one
		local activePanel = PanelManager.getActivePanel()
		if activePanel == panel then
			PanelManager.closeActivePanel()
		else
			PanelManager.hidePanel(panel)
		end
		isPanelVisible = false
	end
end

-- ============================================
-- IS PANEL VISIBLE
-- ============================================
function DailyRewardPanel.isVisible()
	return isPanelVisible and panel ~= nil
end

-- ============================================
-- SET ANIMATIONS ENABLED
-- ============================================
function DailyRewardPanel.setAnimationsEnabled(enabled)
	animationsEnabled = enabled or false
	
	-- If disabling animations, cancel all active tweens
	if not animationsEnabled then
		cleanupAllTweens()
	end
end

-- ============================================
-- DESTROY PANEL
-- ============================================
function DailyRewardPanel.destroy()
	-- Full cleanup
	fullCleanup()
	
	-- Clear references
	panel = nil
	claimButton = nil
	cardsContainer = nil
	cycleLabel = nil
	streakLabel = nil
	nextCycleLabel = nil
	currentDayData = {currentDay = 1, claimedDays = {}}
	isPanelVisible = false
end

-- ============================================
-- UPDATE CONNECTOR VISUALS
-- ============================================
local function updateConnectorVisuals(connector, isClaimed)
	if not connector then return end
	
	if isClaimed then
		-- Animate connector turning white
		if animationsEnabled then
			TweenService:Create(connector, TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
				BackgroundColor3 = COLORS.CONNECTOR_CLAIMED
			}):Play()
		else
			connector.BackgroundColor3 = COLORS.CONNECTOR_CLAIMED
		end
	else
		connector.BackgroundColor3 = COLORS.CONNECTOR
	end
end

-- ============================================
-- UPDATE CARD VISUALS
-- ============================================
local function updateCardVisuals(card, reward, state)
	if not card then return end
	
	local stroke = card:FindFirstChild("CardStroke")
	local dayLabel = card:FindFirstChild("DayLabel")
	local amountLabel = card:FindFirstChild("AmountLabel")
	local nameLabel = card:FindFirstChild("NameLabel")
	local checkMark = card:FindFirstChild("CheckMark")
	
	-- Cancel any existing pulse animation for this card
	if activeTweens[card] then
		for _, tween in ipairs(activeTweens[card]) do
			if tween then
				tween:Cancel()
			end
		end
		activeTweens[card] = nil
	end
	
	if state == "claimed" then
		-- CLAIMED: dark bg, dim border, gray text, white checkmark
		card.BackgroundColor3 = COLORS.CARD_CLAIMED
		if stroke then
			stroke.Color = COLORS.BORDER_CLAIMED
			stroke.Thickness = STROKE_THICKNESS
		end
		if dayLabel then dayLabel.TextColor3 = COLORS.TEXT_DIM end
		if amountLabel then amountLabel.TextColor3 = COLORS.TEXT_DIM end
		if nameLabel then nameLabel.TextColor3 = COLORS.TEXT_DIM end
		if checkMark then checkMark.Visible = true end
		
	elseif state == "today" then
		-- TODAY: white border thickness 2, brighter bg, white text, glow pulse
		card.BackgroundColor3 = COLORS.CARD_TODAY
		if dayLabel then dayLabel.TextColor3 = COLORS.TEXT_GRAY end
		if amountLabel then amountLabel.TextColor3 = COLORS.TEXT_WHITE end
		if nameLabel then nameLabel.TextColor3 = COLORS.TEXT_GRAY end
		if checkMark then checkMark.Visible = false end
		
		-- White border glow pulse animation
		if stroke and animationsEnabled then
			stroke.Color = COLORS.BORDER_TODAY
			stroke.Thickness = 2
			
			-- Ping-pong glow: white <-> slightly dimmer white
			local pulseInfo = TweenInfo.new(PULSE_DURATION, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
			local pulseTween = TweenService:Create(stroke, pulseInfo, {
				Color = Color3.fromRGB(180, 180, 180)
			})
			
			activeTweens[card] = {pulseTween}
			pulseTween:Play()
		elseif stroke then
			stroke.Color = COLORS.BORDER_TODAY
			stroke.Thickness = 2
		end
		
	else
		-- FUTURE: dim border, dimmed text
		card.BackgroundColor3 = COLORS.CARD
		if stroke then
			stroke.Color = COLORS.BORDER_FUTURE
			stroke.Thickness = STROKE_THICKNESS
		end
		if dayLabel then dayLabel.TextColor3 = COLORS.TEXT_DIM end
		if amountLabel then amountLabel.TextColor3 = COLORS.TEXT_DIM end
		if nameLabel then nameLabel.TextColor3 = COLORS.TEXT_DIM end
		if checkMark then checkMark.Visible = false end
	end
end

-- ============================================
-- NOTIFY CLAIM SUCCESS
-- Called when server confirms a daily reward was claimed
-- ============================================
function DailyRewardPanel.notifyClaimSuccess(dayClaimed, rewardAmount, multiplier)
	if not dayClaimed then return end
	
	-- Cancel any pending claim timeout
	if claimTimeout then
		task.cancel(claimTimeout)
		claimTimeout = nil
	end
	
	-- Reset claiming state
	isClaiming = false
	
	-- Reset button state if it exists
	if claimButton and claimButton.Parent then
		claimButton.Text = "CLAIMED — " .. (rewardAmount or 0) .. " Stardust"
		claimButton.BackgroundColor3 = COLORS.BUTTON_WHITE
	end
	
	-- Mark the claimed day in our local data so update() can reflect it
	if currentDayData then
		if not currentDayData.claimedDays then
			currentDayData.claimedDays = {}
		end
		currentDayData.claimedDays[dayClaimed] = true
		-- Update lastClaimTime so canClaim check works correctly
		currentDayData.lastClaimTime = os.time()
		-- Increment currentDay locally to match server state
		currentDayData.currentDay = dayClaimed + 1
	end
	
	-- Update the card for the claimed day to show claimed state
	local displayDay = ((dayClaimed - 1) % 7) + 1
	if cardsContainer then
		local card = cardsContainer:FindFirstChild("Day" .. displayDay)
		if card then
			local reward = DAILY_REWARDS[displayDay]
			if reward then
				updateCardVisuals(card, reward, "claimed")
			end
		end
		
		-- Update connector before this card (if exists) to white
		if displayDay > 1 then
			local connector = cardsContainer:FindFirstChild("Connector" .. (displayDay - 1))
			if connector then
				updateConnectorVisuals(connector, true)
			end
		end
	end
	
	-- Hide claim button immediately
	if claimButton then
		claimButton.Visible = false
		claimButton.Active = false
	end
	
	-- Close panel after a short delay
	task.delay(0.5, function()
		DailyRewardPanel.hide()
	end)
	
	print("[DailyRewardPanel] Claim success confirmed for day " .. dayClaimed)
end

-- ============================================
-- NOTIFY CLAIM ALREADY CLAIMED
-- Called when server says reward was already claimed
-- ============================================
function DailyRewardPanel.notifyAlreadyClaimed()
	-- Cancel any pending claim timeout
	if claimTimeout then
		task.cancel(claimTimeout)
		claimTimeout = nil
	end
	
	-- Reset claiming state
	isClaiming = false
	
	-- Reset button state
	if claimButton and claimButton.Parent then
		claimButton.BackgroundColor3 = COLORS.BUTTON_WHITE
	end
	
	-- Hide the claim button since nothing to claim
	if claimButton then
		claimButton.Visible = false
		claimButton.Active = false
	end
	
	print("[DailyRewardPanel] Reward already claimed")
end

-- ============================================
-- UPDATE PANEL
-- ============================================
function DailyRewardPanel.update(dailyRewardData)
	-- Validate panel exists
	if not panel then
		warn("[DailyRewardPanel] Cannot update - panel not created")
		return
	end
	
	-- Validate data
	if not dailyRewardData then
		warn("[DailyRewardPanel] Cannot update - no data provided")
		return
	end
	
	-- Provide defaults for missing fields instead of rejecting
	if not dailyRewardData.currentDay then
		dailyRewardData.currentDay = 1
	end
	if not dailyRewardData.claimedDays then
		dailyRewardData.claimedDays = {}
	end
	
	-- Validate field types and coerce if needed
	if type(dailyRewardData.currentDay) ~= "number" then
		dailyRewardData.currentDay = 1
	end
	
	if type(dailyRewardData.claimedDays) ~= "table" then
		dailyRewardData.claimedDays = {}
	end
	
	currentDayData = dailyRewardData
	local currentDay = dailyRewardData.currentDay or 1
	local claimedDays = dailyRewardData.claimedDays or {}
	local lastClaimTime = dailyRewardData.lastClaimTime or 0
	
	-- Determine if player can claim: current day not yet claimed AND enough time has passed
	local secondsInDay = 86400
	local timeSinceLastClaim = os.time() - lastClaimTime
	local canClaim = not claimedDays[currentDay] and (lastClaimTime == 0 or timeSinceLastClaim >= secondsInDay)
	
	-- Map currentDay to the 7-day cycle for display purposes
	local displayDay = ((currentDay - 1) % 7) + 1
	
	-- Calculate cycle number and multiplier
	local cycleNumber = math.floor((currentDay - 1) / 7)
	local multiplier = math.max(1, cycleNumber * 3)
	if cycleNumber == 0 then multiplier = 1 end
	
	-- Calculate next cycle multiplier
	local nextCycleNumber = cycleNumber + 1
	local nextMultiplier = nextCycleNumber * 3
	
	-- Update cycle label
	if cycleLabel then
		cycleLabel.Text = "CYCLE " .. (cycleNumber + 1) .. " — " .. multiplier .. "x multiplier"
	end
	
	-- Update streak label
	if streakLabel then
		streakLabel.Text = "Streak: " .. currentDay .. " days"
	end
	
	-- Update next cycle preview
	if nextCycleLabel then
		nextCycleLabel.Text = "Next cycle: " .. nextMultiplier .. "x multiplier"
	end
	
	-- Find cards container
	if not cardsContainer then
		cardsContainer = panel:FindFirstChild("CardsContainer")
		if cardsContainer then
			scrollFrame = cardsContainer.Parent
		end
	end
	if not cardsContainer then
		warn("[DailyRewardPanel] CardsContainer not found")
		return
	end
	
	-- Track which days are claimed for connector logic
	local claimedDayFlags = {}
	
	-- Update each card
	for _, reward in ipairs(DAILY_REWARDS) do
		local card = cardsContainer:FindFirstChild("Day" .. reward.day)
		if card then
			-- Update amount label with multiplied value
			local amountLabel = card:FindFirstChild("AmountLabel")
			if amountLabel then
				local multipliedAmount = BASE_REWARDS[reward.day] * multiplier
				amountLabel.Text = tostring(multipliedAmount)
			end
			
			-- Check if this reward day has been claimed in the current cycle
			local isClaimed = false
			for claimedDayNum, claimed in pairs(claimedDays) do
				if claimed and ((claimedDayNum - 1) % 7) + 1 == reward.day then
					local cycleStart = currentDay - displayDay
					if claimedDayNum > cycleStart and claimedDayNum <= currentDay then
						isClaimed = true
						break
					end
				end
			end
			
			claimedDayFlags[reward.day] = isClaimed
			
			local isCurrent = reward.day == displayDay
			
			if isClaimed then
				updateCardVisuals(card, reward, "claimed")
			elseif isCurrent and canClaim then
				updateCardVisuals(card, reward, "today")
			elseif isCurrent then
				-- Current day but on cooldown (not yet claimable, not claimed)
				-- Show as "today" visually but the claim button will be disabled
				updateCardVisuals(card, reward, "today")
			else
				updateCardVisuals(card, reward, "future")
			end
		end
	end
	
	-- Update connectors between cards
	for i = 1, 6 do
		local connector = cardsContainer:FindFirstChild("Connector" .. i)
		if connector then
			-- Connector i connects Day i to Day i+1
			-- It turns white if both Day i and Day i+1 are claimed
			local bothClaimed = claimedDayFlags[i] and claimedDayFlags[i + 1]
			updateConnectorVisuals(connector, bothClaimed)
		end
	end
	
	-- Update claim button
	if claimButton then
		if canClaim then
			claimButton.Visible = true
			local currentRewardAmount = BASE_REWARDS[displayDay] * multiplier
			claimButton.Text = "CLAIM — " .. currentRewardAmount .. " Stardust"
			claimButton.BackgroundColor3 = COLORS.BUTTON_WHITE
			claimButton.TextColor3 = COLORS.BUTTON_BLACK
			claimButton.Active = true
			
			-- Subtle pulse animation on claim button when available
			if animationsEnabled then
				local btnPulseInfo = TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
				local btnPulse = TweenService:Create(claimButton, btnPulseInfo, {
					BackgroundColor3 = Color3.fromRGB(230, 230, 230)
				})
				activeTweens["claimButton"] = {btnPulse}
				btnPulse:Play()
			end
		else
			-- Already claimed: show disabled state
			claimButton.Visible = true
			claimButton.Text = "CLAIMED"
			claimButton.BackgroundColor3 = COLORS.BUTTON_DISABLED
			claimButton.TextColor3 = COLORS.TEXT_DIM
			claimButton.Active = false
			
			-- Cancel any button pulse
			if activeTweens["claimButton"] then
				for _, tween in ipairs(activeTweens["claimButton"]) do
					if tween then tween:Cancel() end
				end
				activeTweens["claimButton"] = nil
			end
		end
	end
	
	-- Auto-show panel ONLY ONCE when player joins the game
	-- After that, player must manually open the panel
	if canClaim and not hasShownInitially then
		hasShownInitially = true
		DailyRewardPanel.show()
	end
end

return DailyRewardPanel