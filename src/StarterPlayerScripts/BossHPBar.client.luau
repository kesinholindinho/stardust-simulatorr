return -- disabled, replaced by CrystalBossClient
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- References
local bossSyncEvent = ReplicatedStorage:WaitForChild("CrystalBossSync", 10)
if not bossSyncEvent then return end
local arenaPlatform = workspace:WaitForChild("ArenaBossStarPlatform")

-- State
local currentHP = 0
local maxHP = 0
local isBossAlive = true
local respawnEndTime = 0
local distanceCheckConnection = nil

-- Create ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "BossHPGui"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = playerGui

-- Create container Frame (centered at top)
local container = Instance.new("Frame")
container.Name = "Container"
container.Size = UDim2.new(0, 400, 0, 70)
container.Position = UDim2.new(0.5, -200, 0, 10)
container.BackgroundTransparency = 1
container.Parent = screenGui

-- Boss name Label
local bossNameLabel = Instance.new("TextLabel")
bossNameLabel.Name = "BossName"
bossNameLabel.Size = UDim2.new(1, 0, 0, 20)
bossNameLabel.Position = UDim2.new(0, 0, 0, 0)
bossNameLabel.BackgroundTransparency = 1
bossNameLabel.Text = "☆ AstroKing ☆"
bossNameLabel.Font = Enum.Font.GothamBold
bossNameLabel.TextColor3 = Color3.fromRGB(220, 150, 255) -- Bright lilac
bossNameLabel.TextSize = 14
bossNameLabel.Parent = container

-- Background bar (HP background)
local hpBackground = Instance.new("Frame")
hpBackground.Name = "HPBackground"
hpBackground.Size = UDim2.new(1, 0, 0, 18)
hpBackground.Position = UDim2.new(0, 0, 0, 24)
hpBackground.BackgroundColor3 = Color3.fromRGB(30, 0, 50) -- Dark purple
hpBackground.BorderSizePixel = 0
hpBackground.Parent = container

local hpBackgroundCorner = Instance.new("UICorner")
hpBackgroundCorner.Radius = UDim.new(0, 9)
hpBackgroundCorner.Parent = hpBackground

-- HP fill bar
local hpFill = Instance.new("Frame")
hpFill.Name = "HPFill"
hpFill.Size = UDim2.new(1, 0, 1, 0)
hpFill.Position = UDim2.new(0, 0, 0, 0)
hpFill.BackgroundColor3 = Color3.fromRGB(180, 0, 255)
hpFill.BorderSizePixel = 0
hpFill.Parent = hpBackground

local hpFillCorner = Instance.new("UICorner")
hpFillCorner.Radius = UDim.new(0, 9)
hpFillCorner.Parent = hpFill

-- Gradient for HP fill (purple to magenta)
local hpGradient = Instance.new("UIGradient")
hpGradient.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(180, 0, 255)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 150))
})
hpGradient.Parent = hpFill

-- HP text label
local hpText = Instance.new("TextLabel")
hpText.Name = "HPText"
hpText.Size = UDim2.new(1, 0, 1, 0)
hpText.Position = UDim2.new(0, 0, 0, 0)
hpText.BackgroundTransparency = 1
hpText.Text = "5000 / 5000"
hpText.Font = Enum.Font.Gotham
hpText.TextColor3 = Color3.fromRGB(255, 255, 255)
hpText.TextSize = 12
hpText.Parent = hpBackground

-- Respawn timer label (hidden by default)
local respawnLabel = Instance.new("TextLabel")
respawnLabel.Name = "RespawnTimer"
respawnLabel.Size = UDim2.new(1, 0, 0, 20)
respawnLabel.Position = UDim2.new(0, 0, 0, 46)
respawnLabel.BackgroundTransparency = 1
respawnLabel.Text = "Respawn in: 10:00"
respawnLabel.Font = Enum.Font.Gotham
respawnLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
respawnLabel.TextSize = 12
respawnLabel.Visible = false
respawnLabel.Parent = container

-- Update HP bar with animation
local function updateHPBar(newCurrentHP, newMaxHP)
	currentHP = newCurrentHP
	maxHP = newMaxHP
	
	-- Calculate percentage
	local percent = 0
	if maxHP > 0 then
		percent = math.clamp(currentHP / maxHP, 0, 1)
	end
	
	-- Animate the fill bar size
	local targetSize = UDim2.new(percent, 0, 1, 0)
	local tween = TweenService:Create(
		hpFill,
		TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{Size = targetSize}
	)
	tween:Play()
	
	-- Update text
	hpText.Text = string.format("%d / %d", currentHP, maxHP)
end

-- Show/hide HP bar elements
local function showHPBar()
	bossNameLabel.Visible = true
	hpBackground.Visible = true
	hpFill.Visible = true
	hpText.Visible = true
	respawnLabel.Visible = false
end

local function showRespawnTimer()
	bossNameLabel.Visible = true
	hpBackground.Visible = false
	hpFill.Visible = false
	hpText.Visible = false
	respawnLabel.Visible = true
end

-- Respawn timer countdown
local respawnTimerConnection = nil

local function startRespawnCountdown(respawnSeconds)
	respawnEndTime = tick() + respawnSeconds
	isBossAlive = false
	
	showRespawnTimer()
	
	-- Cancel existing timer if any
	if respawnTimerConnection then
		respawnTimerConnection:Disconnect()
	end
	
	-- Update timer every second
	respawnTimerConnection = RunService.Heartbeat:Connect(function()
		local remaining = respawnEndTime - tick()
		
		if remaining <= 0 then
			respawnLabel.Text = "Respawn in: 0:00"
			respawnTimerConnection:Disconnect()
			respawnTimerConnection = nil
			return
		end
		
		local minutes = math.floor(remaining / 60)
		local seconds = math.floor(remaining % 60)
		respawnLabel.Text = string.format("Respawn in: %d:%02d", minutes, seconds)
	end)
end

-- Distance check (hide if too far from arena)
local function checkDistance()
	local character = player.Character
	if not character then
		return true -- Hide if no character
	end
	
	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp then
		return true -- Hide if no HumanoidRootPart
	end
	
	local distance = (hrp.Position - arenaPlatform.Position).Magnitude
	return distance <= 100 -- Show if within 100 studs
end

-- Start distance check loop
local function startDistanceCheck()
	if distanceCheckConnection then
		distanceCheckConnection:Disconnect()
	end
	
	distanceCheckConnection = task.spawn(function()
		while true do
			local shouldShow = checkDistance()
			
			if shouldShow then
				if isBossAlive then
					showHPBar()
				end
				-- If boss is dead, respawn timer handles visibility
			else
				container.Visible = false
			end
			
			task.wait(2)
		end
	end)
end

-- Listen for BossSync events
bossSyncEvent.OnClientEvent:Connect(function(data)
	-- HP update
	if data.currentHP and data.maxHP then
		isBossAlive = true
		updateHPBar(data.currentHP, data.maxHP)
		
		-- Check distance before showing
		if checkDistance() then
			showHPBar()
			container.Visible = true
		end
	end
	
	-- Boss defeated
	if data.bossDefeated then
		local respawnIn = data.respawnIn or 600
		startRespawnCountdown(respawnIn)
		
		-- Check distance before showing
		if checkDistance() then
			container.Visible = true
		end
	end
	
	-- Boss respawned
	if data.bossSpawned then
		isBossAlive = true
		
		-- Cancel respawn timer
		if respawnTimerConnection then
			respawnTimerConnection:Disconnect()
			respawnTimerConnection = nil
		end
		
		-- Update HP bar to full
		if data.currentHP and data.maxHP then
			updateHPBar(data.currentHP, data.maxHP)
		end
		
		-- Check distance before showing
		if checkDistance() then
			showHPBar()
			container.Visible = true
		end
	end
end)

-- Start distance check
startDistanceCheck()

-- Initial hide until we receive data
container.Visible = false