local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ContentProvider = game:GetService("ContentProvider")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- ─── TIPS ────────────────────────────────────────────────────────────
local TIPS = {
	"Tip: Equip pets to increase your Stardust multiplier!",
	"Tip: Defeat the Crystal Tree boss for rare rewards!",
	"Tip: Use the Supernova to reset and gain permanent multipliers!",
	"Tip: Check daily rewards every day to build your streak!",
	"Tip: Explore all 6 worlds to find bonus zones!",
	"Tip: Premium eggs contain the rarest pets!",
	"Tip: High damage on Crystal Tree boss improves gacha rewards!",
}

-- ─── MILESTONES ──────────────────────────────────────────────────────
local milestones = {
	{name = "Initializing game...",      weight = 10},
	{name = "Loading world...",          weight = 20},
	{name = "Loading pets...",           weight = 15},
	{name = "Loading eggs...",           weight = 15},
	{name = "Loading UI...",             weight = 20},
	{name = "Connecting to server...",   weight = 10},
	{name = "Almost ready...",           weight = 10},
}

-- ─── SCREEN GUI ────────────────────────────────────────────────────
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "LoadingScreen"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.IgnoreGuiInset = true
screenGui.DisplayOrder = 100
screenGui.Parent = playerGui

-- ─── BACKGROUND ────────────────────────────────────────────────────
local bg = Instance.new("CanvasGroup")
bg.Name = "Background"
bg.Size = UDim2.fromScale(1, 1)
bg.Position = UDim2.fromScale(0, 0)
bg.BackgroundColor3 = Color3.fromRGB(5, 5, 10)
bg.BorderSizePixel = 0
bg.ZIndex = 1
bg.Parent = screenGui

-- ─── STARS ─────────────────────────────────────────────────────────
local STAR_COUNT = 50
local stars = {}

for i = 1, STAR_COUNT do
	local star = Instance.new("Frame")
	star.Name = "Star_" .. i
	star.Size = UDim2.fromOffset(2, 2)
	star.Position = UDim2.fromScale(math.random(), math.random())
	star.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	star.BorderSizePixel = 0
	star.ZIndex = 1
	star.BackgroundTransparency = math.random(30, 100) / 100
	star.Parent = bg

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(1, 0)
	corner.Parent = star

	table.insert(stars, star)
end

-- Twinkle loop: each star has its own independent fast loop
task.spawn(function()
	while screenGui and screenGui.Parent do
		for _, star in ipairs(stars) do
			if not star or not star.Parent then continue end
				local targetTransparency = math.random(0, 70) / 100
			local duration = math.random(8, 35) / 100
			local tween = TweenService:Create(
				star,
				TweenInfo.new(duration, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
				{BackgroundTransparency = targetTransparency}
			)
			tween:Play()
		end
		task.wait(0.06)
	end
end)

-- ─── MAIN CONTAINER ────────────────────────────────────────────────
local container = Instance.new("Frame")
container.Name = "Container"
container.Size = UDim2.fromScale(0.5, 0.55)
container.Position = UDim2.fromScale(0.5, 0.5)
container.AnchorPoint = Vector2.new(0.5, 0.5)
container.BackgroundColor3 = Color3.fromRGB(5, 5, 10)
container.BackgroundTransparency = 1
container.ZIndex = 2
container.Parent = bg

-- ─── TITLE ─────────────────────────────────────────────────────────
local title = Instance.new("TextLabel")
title.Name = "Title"
title.Size = UDim2.fromScale(1, 0.15)
title.Position = UDim2.fromScale(0, 0.1)
title.BackgroundTransparency = 1
title.Text = "STARDUST SIMULATOR"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextSize = 36
title.Font = Enum.Font.GothamBold
title.ZIndex = 3
title.Parent = container

-- Title glow pulse
task.spawn(function()
	while title and title.Parent do
		local glowUp = TweenService:Create(
			title,
			TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
			{TextTransparency = 0}
		)
		local glowDown = TweenService:Create(
			title,
			TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
			{TextTransparency = 0.3}
		)
		glowUp:Play()
		glowUp.Completed:Connect(function()
			if title and title.Parent then
				glowDown:Play()
			end
		end)
		glowDown.Completed:Wait()
	end
end)

-- ─── SUBTITLE ──────────────────────────────────────────────────────
local subtitle = Instance.new("TextLabel")
subtitle.Name = "Subtitle"
subtitle.Size = UDim2.fromScale(1, 0.06)
subtitle.Position = UDim2.fromScale(0, 0.26)
subtitle.BackgroundTransparency = 1
subtitle.Text = "Loading your universe..."
subtitle.TextColor3 = Color3.fromRGB(120, 120, 120)
subtitle.TextSize = 14
subtitle.Font = Enum.Font.GothamBold
subtitle.ZIndex = 3
subtitle.Parent = container

-- ─── LOADING BAR ───────────────────────────────────────────────────
local barContainer = Instance.new("Frame")
barContainer.Name = "BarContainer"
barContainer.Size = UDim2.fromScale(0.8, 0.025)
barContainer.Position = UDim2.fromScale(0.1, 0.38)
barContainer.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
barContainer.BorderSizePixel = 0
barContainer.ZIndex = 3
barContainer.Parent = container

local barCorner = Instance.new("UICorner")
barCorner.CornerRadius = UDim.new(0, 6)
barCorner.Parent = barContainer

local barBorder = Instance.new("UIStroke")
barBorder.Color = Color3.fromRGB(255, 255, 255)
barBorder.Thickness = 1
barBorder.Transparency = 0.5
barBorder.Parent = barContainer

local barFill = Instance.new("Frame")
barFill.Name = "BarFill"
barFill.Size = UDim2.fromScale(0, 1)
barFill.Position = UDim2.fromScale(0, 0)
barFill.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
barFill.BorderSizePixel = 0
barFill.ZIndex = 4
barFill.Parent = barContainer

local fillCorner = Instance.new("UICorner")
fillCorner.CornerRadius = UDim.new(0, 6)
fillCorner.Parent = barFill

-- ─── PERCENTAGE ────────────────────────────────────────────────────
local percentage = Instance.new("TextLabel")
percentage.Name = "Percentage"
percentage.Size = UDim2.fromScale(1, 0.05)
percentage.Position = UDim2.fromScale(0, 0.42)
percentage.BackgroundTransparency = 1
percentage.Text = "0%"
percentage.TextColor3 = Color3.fromRGB(120, 120, 120)
percentage.TextSize = 14
percentage.Font = Enum.Font.GothamBold
percentage.ZIndex = 3
percentage.Parent = container

-- ─── TIPS ──────────────────────────────────────────────────────────
local tipLabel = Instance.new("TextLabel")
tipLabel.Name = "TipLabel"
tipLabel.Size = UDim2.fromScale(0.9, 0.08)
tipLabel.Position = UDim2.fromScale(0.05, 0.55)
tipLabel.BackgroundTransparency = 1
tipLabel.Text = TIPS[1]
tipLabel.TextColor3 = Color3.fromRGB(120, 120, 120)
tipLabel.TextSize = 13
tipLabel.Font = Enum.Font.GothamBold
tipLabel.TextWrapped = true
tipLabel.ZIndex = 3
tipLabel.Parent = container

-- Tip cycling
task.spawn(function()
	local tipIndex = 1
	while tipLabel and tipLabel.Parent do
		-- Fade out
		local fadeOut = TweenService:Create(
			tipLabel,
			TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
			{TextTransparency = 1}
		)
		fadeOut:Play()
		fadeOut.Completed:Wait()

		tipIndex = (tipIndex % #TIPS) + 1
		tipLabel.Text = TIPS[tipIndex]

		-- Fade in
		local fadeIn = TweenService:Create(
			tipLabel,
			TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
			{TextTransparency = 0}
		)
		fadeIn:Play()
		fadeIn.Completed:Wait()

		task.wait(3)
	end
end)

-- ─── SKIP BUTTON ───────────────────────────────────────────────────
local skipBtn = Instance.new("TextButton")
skipBtn.Name = "SkipButton"
skipBtn.Size = UDim2.fromOffset(80, 30)
skipBtn.Position = UDim2.new(1, -20, 1, -20)
skipBtn.AnchorPoint = Vector2.new(1, 1)
skipBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
skipBtn.Text = "SKIP"
skipBtn.TextColor3 = Color3.fromRGB(180, 180, 180)
skipBtn.TextSize = 14
skipBtn.Font = Enum.Font.GothamBold
skipBtn.BorderSizePixel = 0
skipBtn.ZIndex = 10
skipBtn.Visible = false
skipBtn.Parent = screenGui

local skipCorner = Instance.new("UICorner")
skipCorner.CornerRadius = UDim.new(0, 4)
skipCorner.Parent = skipBtn

local skipBorder = Instance.new("UIStroke")
skipBorder.Color = Color3.fromRGB(100, 100, 100)
skipBorder.Thickness = 1
skipBorder.Parent = skipBtn

-- ─── FADE IN ON START ──────────────────────────────────────────────
bg.GroupTransparency = 1
local fadeIn = TweenService:Create(
	bg,
	TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
	{GroupTransparency = 0}
)
fadeIn:Play()

-- ─── LOADING LOGIC ─────────────────────────────────────────────────
local currentProgress = 0
local totalWeight = 0
for _, m in ipairs(milestones) do
	totalWeight = totalWeight + m.weight
end

local function setProgress(value, subtitleText)
	if value < currentProgress then return end
	currentProgress = value

	-- Animate bar fill
	local barTween = TweenService:Create(
		barFill,
		TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{Size = UDim2.fromScale(currentProgress / 100, 1)}
	)
	barTween:Play()

	-- Update percentage text
	percentage.Text = math.floor(currentProgress) .. "%"

	-- Update subtitle
	if subtitleText then
		subtitle.Text = subtitleText
	end

	-- At 100%
	if currentProgress >= 100 then
		subtitle.Text = "Ready!"
		barFill.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	end
end

local function fadeOutAndDestroy()
	local fadeOut = TweenService:Create(
		bg,
		TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
		{GroupTransparency = 1}
	)
	fadeOut:Play()
	fadeOut.Completed:Connect(function()
		screenGui:Destroy()
	end)
end

local loadingComplete = false

skipBtn.MouseButton1Click:Connect(function()
	if loadingComplete then
		fadeOutAndDestroy()
	end
end)

-- ─── RUN MILESTONES ────────────────────────────────────────────────
task.spawn(function()
	local accumulated = 0

	for i, milestone in ipairs(milestones) do
		local targetPercent = (accumulated + milestone.weight) / totalWeight * 100

		-- Milestone 1: Initializing
		if i == 1 then
			setProgress(targetPercent, milestone.name)
			task.wait(0.3)

		-- Milestone 2: Loading world
		elseif i == 2 then
			setProgress(targetPercent, milestone.name)
			-- Preload workspace assets
			local workspaceAssets = {}
			for _, desc in ipairs(workspace:GetDescendants()) do
				if desc:IsA("Model") or desc:IsA("BasePart") then
					table.insert(workspaceAssets, desc)
				end
			end
			pcall(function()
				ContentProvider:PreloadAsync(workspaceAssets)
			end)

		-- Milestone 3: Loading pets
		elseif i == 3 then
			setProgress(targetPercent, milestone.name)
			local petModels = ReplicatedStorage:FindFirstChild("PetModels")
			if petModels then
				pcall(function()
					ContentProvider:PreloadAsync(petModels:GetDescendants())
				end)
			end

		-- Milestone 4: Loading eggs
		elseif i == 4 then
			setProgress(targetPercent, milestone.name)
			local eggFolders = {
				ReplicatedStorage:FindFirstChild("Ovo Cosmico e seus Pets"),
				ReplicatedStorage:FindFirstChild("Ovo Lunar e seus Pets"),
				ReplicatedStorage:FindFirstChild("EggModels"),
			}
			for _, folder in ipairs(eggFolders) do
				if folder then
					pcall(function()
						ContentProvider:PreloadAsync(folder:GetDescendants())
					end)
				end
			end

		-- Milestone 5: Loading UI
		elseif i == 5 then
			setProgress(targetPercent, milestone.name)
			-- Wait for StardustUI ScreenGui
			playerGui:WaitForChild("StardustUI", 15)

		-- Milestone 6: Connecting to server
		elseif i == 6 then
			setProgress(targetPercent, milestone.name)
			-- Wait for critical RemoteEvents
			local function waitForRemote(name)
				return ReplicatedStorage:WaitForChild(name, 10)
			end
			waitForRemote("GameAction")
			waitForRemote("StardustSync")
			waitForRemote("CrystalBossSync")

		-- Milestone 7: Almost ready
		elseif i == 7 then
			setProgress(targetPercent, milestone.name)
			task.wait(0.3)
		end

		accumulated = accumulated + milestone.weight
	end

	-- Ensure we hit 100%
	setProgress(100, "Ready!")
	loadingComplete = true
	skipBtn.Visible = true

	-- Auto-fade after 1 second if player doesn't skip
	task.wait(1)
	if screenGui and screenGui.Parent then
		fadeOutAndDestroy()
	end
end)