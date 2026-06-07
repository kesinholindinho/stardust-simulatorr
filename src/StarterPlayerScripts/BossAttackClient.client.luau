local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer

-- Wait for RemoteEvent
local bossAttackEvent = ReplicatedStorage:WaitForChild("BossAttackEvent")

-- Settings module reference
local SettingsPanel = require(ReplicatedStorage:WaitForChild("StardustUI"):WaitForChild("Panels"):WaitForChild("SettingsPanel"))

-- Sound IDs
local WARNING_SOUND_ID = "rbxassetid://6042053626" -- whoosh
local IMPACT_SOUND_ID = "rbxassetid://5801258398" -- impact

-- Play a sound and destroy it after playing
local function playSound(soundId, position)
	if not SettingsPanel.soundEnabled() then return end
	local sound = Instance.new("Sound")
	sound.SoundId = soundId
	sound.Volume = 1
	sound.Parent = workspace
	
	if position then
		sound.Position = position
		sound.EmitterSize = 10
	end
	
	sound:Play()
	
	sound.Ended:Connect(function()
		sound:Destroy()
	end)
	
	return sound
end

-- Create warning circle (Phase 1)
local function createWarningCircle(position)
	local circle = Instance.new("Part")
	circle.Name = "StakeWarning"
	circle.Shape = Enum.PartType.Cylinder
	circle.Size = Vector3.new(12, 0.2, 12)
	circle.CFrame = CFrame.new(position) * CFrame.Angles(0, 0, math.rad(90)) -- Rotate cylinder to be flat
	circle.Material = Enum.Material.Neon
	circle.Color = Color3.fromRGB(180, 0, 255) -- Corrupted purple
	circle.Transparency = 0.3
	circle.CanCollide = false
	circle.Anchored = true
	circle.Parent = workspace
	
	return circle
end

-- Animate warning circle shrinking (Phase 2)
local function animateWarningShrink(circle, warningDuration)
	local shrinkTween = TweenService:Create(
		circle,
		TweenInfo.new(
			warningDuration,
			Enum.EasingStyle.Quad,
			Enum.EasingDirection.In
		),
		{
			Size = Vector3.new(1, 0.2, 1),
			Transparency = 0.7
		}
	)
	shrinkTween:Play()
	return shrinkTween
end

-- Create stake part (Phase 3)
local function createStake(position)
	local stake = Instance.new("Part")
	stake.Name = "StakePart"
	stake.Size = Vector3.new(1.5, 8, 1.5)
	stake.Material = Enum.Material.Neon
	stake.Color = Color3.fromRGB(120, 0, 200) -- Dark corrupted purple
	stake.CanCollide = false
	stake.Anchored = true
	stake.Parent = workspace
	
	-- Position 4 studs below ground
	stake.CFrame = CFrame.new(position.X, position.Y - 4, position.Z)
	
	-- Add purple light effect
	local light = Instance.new("PointLight")
	light.Brightness = 3
	light.Color = Color3.fromRGB(150, 0, 255)
	light.Range = 12
	light.Parent = stake
	
	return stake
end

-- Animate stake rising (Phase 3)
local function animateStakeRise(stake, position)
	local riseTween = TweenService:Create(
		stake,
		TweenInfo.new(
			0.3,
			Enum.EasingStyle.Bounce,
			Enum.EasingDirection.Out
		),
		{
			CFrame = CFrame.new(position.X, position.Y + 5, position.Z)
		}
	)
	riseTween:Play()
	return riseTween
end

-- Animate stake descending (Phase 4)
local function animateStakeDescent(stake, position)
	local descentTween = TweenService:Create(
		stake,
		TweenInfo.new(
			0.4,
			Enum.EasingStyle.Quad,
			Enum.EasingDirection.In
		),
		{
			CFrame = CFrame.new(position.X, position.Y - 4, position.Z)
		}
	)
	descentTween:Play()
	return descentTween
end

-- Handle a single stake attack position
local function handleStakeAttack(attackPosition, warningDuration)
	-- PHASE 1: Create warning circle
	local warningCircle = createWarningCircle(attackPosition)
	
	-- Play warning sound
	playSound(WARNING_SOUND_ID, attackPosition)
	
	-- PHASE 2: Animate warning shrinking
	local shrinkTween = animateWarningShrink(warningCircle, warningDuration)
	shrinkTween.Completed:Wait()
	
	-- Destroy warning circle
	warningCircle:Destroy()
	
	-- PHASE 3: Create and animate stake
	local stake = createStake(attackPosition)
	
	-- Play impact sound
	playSound(IMPACT_SOUND_ID, attackPosition)
	
	-- Animate stake rising
	local riseTween = animateStakeRise(stake, attackPosition)
	riseTween.Completed:Wait()
	
	-- PHASE 4: Wait then animate descent
	task.wait(1.2)
	
	local descentTween = animateStakeDescent(stake, attackPosition)
	descentTween.Completed:Wait()
	
	-- Destroy stake
	stake:Destroy()
end

-- Listen for boss attack events
bossAttackEvent.OnClientEvent:Connect(function(data)
	if data.attackType == "stake" then
		local positions = data.positions
		local warningDuration = data.warningDuration or 2.5
		
		-- Handle each position simultaneously using task.spawn
		for _, position in ipairs(positions) do
			task.spawn(function()
				handleStakeAttack(position, warningDuration)
			end)
		end
	end
end)