local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local skyBoss = ReplicatedStorage:WaitForChild("123")
local skyGame = Lighting:WaitForChild("Sky Game")
local atmosphere = Lighting:WaitForChild("Atmosphere")
local bloom = Lighting:WaitForChild("Bloom")

local isActive = false

-- ============================================
-- ORIGINAL LIGHTING VALUES (captured at startup)
-- ============================================
local ORIGINAL = {
	ClockTime = Lighting.ClockTime,
	Brightness = Lighting.Brightness,
	Ambient = Lighting.Ambient,
	OutdoorAmbient = Lighting.OutdoorAmbient,
	FogColor = Lighting.FogColor,
	FogEnd = Lighting.FogEnd,
	FogStart = Lighting.FogStart,
	ExposureCompensation = Lighting.ExposureCompensation,
	AtmosphereDensity = atmosphere.Density,
	AtmosphereOffset = atmosphere.Offset,
	AtmosphereColor = atmosphere.Color,
	AtmosphereDecay = atmosphere.Decay,
	AtmosphereGlare = atmosphere.Glare,
	AtmosphereHaze = atmosphere.Haze,
	BloomIntensity = bloom.Intensity,
	BloomThreshold = bloom.Threshold,
	BloomSize = bloom.Size,
}

-- ============================================
-- BOSS AREA LIGHTING VALUES (dramatic dark cosmic)
-- ============================================
local BOSS = {
	ClockTime = 14.5,           -- Afternoon (daytime, keeps sky bright)
	Brightness = 1.8,           -- Bright, not dark
	Ambient = Color3.fromRGB(120, 80, 160),      -- Soft purple ambient
	OutdoorAmbient = Color3.fromRGB(100, 70, 150), -- Soft purple outdoor
	ExposureCompensation = 0.1,  -- Slightly brighter exposure
	AtmosphereDensity = 0.15,   -- Light atmosphere (won't hide skybox)
	AtmosphereOffset = 0.0,     -- Normal offset
	AtmosphereColor = Color3.fromRGB(0.5, 0.35, 0.7), -- Purple tint (lighter)
	AtmosphereDecay = Color3.fromRGB(0.45, 0.3, 0.65), -- Purple decay (lighter)
	AtmosphereGlare = 0.2,      -- Subtle glare
	AtmosphereHaze = 0.05,      -- Very light haze (keeps skybox visible)
	BloomIntensity = 1.5,       -- Moderate bloom for crystal glow
	BloomThreshold = 1.0,       -- Higher threshold = less bloom
	BloomSize = 30,             -- Moderate bloom size
}

-- Transition duration for smooth changes
local TRANSITION_DURATION = 2.5

-- ============================================
-- SMOOTH TRANSITION FUNCTIONS
-- ============================================
local function tweenValue(obj, property, targetValue, duration)
	local info = TweenInfo.new(duration, Enum.EasingStyle.Cubic, Enum.EasingDirection.InOut)
	local tween = TweenService:Create(obj, info, {[property] = targetValue})
	tween:Play()
	return tween
end

local function tweenMultiple(obj, properties, duration)
	local info = TweenInfo.new(duration, Enum.EasingStyle.Cubic, Enum.EasingDirection.InOut)
	local tween = TweenService:Create(obj, info, properties)
	tween:Play()
	return tween
end

-- Track active tweens so we can cancel them if needed
local activeTweens = {}

local function cancelActiveTweens()
	for _, tween in ipairs(activeTweens) do
		if tween.PlayState == Enum.PlayState.Playing then
			tween:Cancel()
		end
	end
	activeTweens = {}
end

local function applyBossAtmosphere()
	if isActive then return end
	isActive = true
	cancelActiveTweens()

	-- Swap Sky objects directly (move Sky Game to ReplicatedStorage, move boss sky to Lighting)
	skyGame.Parent = ReplicatedStorage
	skyBoss.Parent = Lighting

	-- Tween Lighting properties (NO fog changes - fog breaks skybox bottom)
	table.insert(activeTweens, tweenMultiple(Lighting, {
		ClockTime = BOSS.ClockTime,
		Brightness = BOSS.Brightness,
		Ambient = BOSS.Ambient,
		OutdoorAmbient = BOSS.OutdoorAmbient,
		ExposureCompensation = BOSS.ExposureCompensation,
	}, TRANSITION_DURATION))

	-- NÃO mudar Atmosphere para evitar cortar o skybox
	-- table.insert(activeTweens, tweenMultiple(atmosphere, {
	-- 	Density = BOSS.AtmosphereDensity,
	-- 	Offset = BOSS.AtmosphereOffset,
	-- 	Color = BOSS.AtmosphereColor,
	-- 	Decay = BOSS.AtmosphereDecay,
	-- 	Glare = BOSS.AtmosphereGlare,
	-- 	Haze = BOSS.AtmosphereHaze,
	-- }, TRANSITION_DURATION))

	-- Tween Bloom
	table.insert(activeTweens, tweenMultiple(bloom, {
		Intensity = BOSS.BloomIntensity,
		Threshold = BOSS.BloomThreshold,
		Size = BOSS.BloomSize,
	}, TRANSITION_DURATION))
end

local function restoreOriginalAtmosphere()
	if not isActive then return end
	isActive = false
	cancelActiveTweens()

	-- Swap Sky objects back (move boss sky to ReplicatedStorage, move Sky Game to Lighting)
	skyBoss.Parent = ReplicatedStorage
	skyGame.Parent = Lighting

	-- Tween Lighting back (no fog changes)
	table.insert(activeTweens, tweenMultiple(Lighting, {
		ClockTime = ORIGINAL.ClockTime,
		Brightness = ORIGINAL.Brightness,
		Ambient = ORIGINAL.Ambient,
		OutdoorAmbient = ORIGINAL.OutdoorAmbient,
		ExposureCompensation = ORIGINAL.ExposureCompensation,
	}, TRANSITION_DURATION))

	-- NÃO mudar Atmosphere para evitar cortar o skybox
	-- table.insert(activeTweens, tweenMultiple(atmosphere, {
	-- 	Density = ORIGINAL.AtmosphereDensity,
	-- 	Offset = ORIGINAL.AtmosphereOffset,
	-- 	Color = ORIGINAL.AtmosphereColor,
	-- 	Decay = ORIGINAL.AtmosphereDecay,
	-- 	Glare = ORIGINAL.AtmosphereGlare,
	-- 	Haze = ORIGINAL.AtmosphereHaze,
	-- }, TRANSITION_DURATION))

	-- Tween Bloom back
	table.insert(activeTweens, tweenMultiple(bloom, {
		Intensity = ORIGINAL.BloomIntensity,
		Threshold = ORIGINAL.BloomThreshold,
		Size = ORIGINAL.BloomSize,
	}, TRANSITION_DURATION))
end

-- ============================================
-- AREA DETECTION
-- ============================================
local function isInsideArea(rootPart, areaPart)
	local point = areaPart.CFrame:PointToObjectSpace(rootPart.Position)
	return math.abs(point.X) <= areaPart.Size.X / 2
		and math.abs(point.Y) <= areaPart.Size.Y / 2
		and math.abs(point.Z) <= areaPart.Size.Z / 2
end

RunService.Heartbeat:Connect(function()
	local character = player.Character
	if not character then return end
	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not rootPart then return end

	local pasta = workspace:FindFirstChild("Crstal Tree pasta")
	if not pasta then return end
	local areaPart = pasta:FindFirstChild("Area Crystal")
	if not areaPart then return end

	if isInsideArea(rootPart, areaPart) then
		applyBossAtmosphere()
	else
		restoreOriginalAtmosphere()
	end
end)