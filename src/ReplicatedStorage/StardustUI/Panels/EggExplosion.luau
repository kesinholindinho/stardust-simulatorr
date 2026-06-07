-- =====================================================
-- PARTE 2 - EXPLOSÃO OTIMIZADA
-- Shockwave simétrico, camera shake determinístico,
-- partículas em burst único, flash rápido
-- =====================================================

local ExplosionSystem = {}

local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

-- Cores de raridade para os efeitos
local RARITY_COLORS = {
	["Common"] = Color3.fromRGB(180, 180, 180),
	["Raro"] = Color3.fromRGB(100, 150, 255),
	["Rare"] = Color3.fromRGB(100, 150, 255),
	["Epico"] = Color3.fromRGB(180, 100, 255),
	["Epic"] = Color3.fromRGB(180, 100, 255),
	["Lendario"] = Color3.fromRGB(255, 200, 50),
	["Legendary"] = Color3.fromRGB(255, 200, 50),
}

-- Verifica se raridade é épica ou lendária
local function isEpicOrHigher(rarity)
	return rarity == "Epico" or rarity == "Epic" or rarity == "Lendario" or rarity == "Legendary"
end

-- Camera shake simétrico com sin/cos (determinístico, sem random)
local function playCameraShake(camera, duration, maxIntensity)
	local originalCFrame = camera.CFrame
	local startTime = tick()
	local conn
	conn = RunService.RenderStepped:Connect(function()
		local elapsed = tick() - startTime
		if elapsed >= duration then
			camera.CFrame = originalCFrame
			conn:Disconnect()
			return
		end
		local progress = elapsed / duration
		local decay = 1 - progress * progress -- ease-out quadrático
		local intensity = maxIntensity * decay
		-- Frequências primas entre si para movimento rico mas simétrico
		local offsetX = math.sin(elapsed * 42) * intensity
		local offsetY = math.cos(elapsed * 37) * intensity
		local offsetZ = math.sin(elapsed * 29) * intensity * 0.3
		camera.CFrame = originalCFrame * CFrame.new(offsetX, offsetY, offsetZ)
	end)
end

-- Função para criar a explosão no viewport
function ExplosionSystem.play(viewport, camera, popup, rarity)
	local rarityColor = RARITY_COLORS[rarity] or Color3.fromRGB(255, 255, 255)
	local isEpic = isEpicOrHigher(rarity)

	-- ===== SOM DE EXPLOSÃO =====
	local explosionSound = Instance.new("Sound")
	explosionSound.Name = "ExplosionSound"
	explosionSound.SoundId = "rbxassetid://262562442"
	explosionSound.Volume = 0.7
	explosionSound.PlaybackSpeed = isEpic and 0.8 or 1.0
	explosionSound.Parent = popup
	explosionSound:Play()

	-- ===== FLASH COLORIDO =====
	local flashFrame = Instance.new("Frame")
	flashFrame.Name = "ExplosionFlash"
	flashFrame.Size = UDim2.new(1, 0, 1, 0)
	flashFrame.Position = UDim2.new(0, 0, 0, 0)
	flashFrame.BackgroundColor3 = isEpic and rarityColor or Color3.new(1, 1, 1)
	flashFrame.BackgroundTransparency = 1
	flashFrame.ZIndex = 10
	flashFrame.BorderSizePixel = 0
	flashFrame.Parent = popup

	-- Flash in rápido (0.05s)
	TweenService:Create(flashFrame, TweenInfo.new(0.05, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		BackgroundTransparency = 0
	}):Play()
	task.wait(0.05)

	-- ===== SHOCKWAVE RINGS (simétricos, criados juntos) =====
	for i, cfg in ipairs({{targetSize = 500, startTrans = 0.3}, {targetSize = 400, startTrans = 0.5}}) do
		local ring = Instance.new("Frame")
		ring.Name = "Shockwave" .. i
		ring.Size = UDim2.new(0, 20, 0, 20)
		ring.Position = UDim2.new(0.5, -10, 0.28, -10)
		ring.BackgroundColor3 = rarityColor
		ring.BackgroundTransparency = cfg.startTrans
		ring.ZIndex = 9
		ring.BorderSizePixel = 0
		ring.Parent = popup
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(1, 0)
		corner.Parent = ring

		local halfSize = cfg.targetSize / 2
		TweenService:Create(ring, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Size = UDim2.new(0, cfg.targetSize, 0, cfg.targetSize),
			Position = UDim2.new(0.5, -halfSize, 0.28, -halfSize),
			BackgroundTransparency = 1
		}):Play()

		task.delay(0.6, function()
			if ring and ring.Parent then ring.Parent = nil end
		end)
	end

	-- ===== LUZ COLORIDA (fade rápido, sem spawn) =====
	local explosionLight = Instance.new("PointLight")
	explosionLight.Name = "ExplosionLight"
	explosionLight.Brightness = 10
	explosionLight.Range = 50
	explosionLight.Color = rarityColor
	explosionLight.Parent = camera

	TweenService:Create(explosionLight, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Brightness = 0.5,
		Range = 15
	}):Play()

	-- ===== CAMERA SHAKE (simétrico, determinístico) =====
	playCameraShake(camera, 0.35, isEpic and 1.5 or 0.8)

	-- ===== PARTÍCULAS - CAMADA 1: BURST PRINCIPAL =====
	local particlePart = Instance.new("Part")
	particlePart.Name = "ParticleOrigin"
	particlePart.Size = Vector3.new(0.1, 0.1, 0.1)
	particlePart.Position = Vector3.new(0, 0, 0)
	particlePart.Transparency = 1
	particlePart.CanCollide = false
	particlePart.Anchored = true
	particlePart.Parent = viewport

	local mainEmitter = Instance.new("ParticleEmitter")
	mainEmitter.Rate = 0
	mainEmitter.Lifetime = NumberRange.new(0.4, 0.8)
	mainEmitter.Speed = NumberRange.new(4, 10)
	mainEmitter.SpreadAngle = Vector2.new(180, 180)
	mainEmitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 2.5),
		NumberSequenceKeypoint.new(0.4, 1.5),
		NumberSequenceKeypoint.new(1, 0)
	})
	mainEmitter.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(0.7, 0.3),
		NumberSequenceKeypoint.new(1, 1)
	})
	mainEmitter.Color = ColorSequence.new(rarityColor)
	mainEmitter.LightEmission = 1
	mainEmitter.LightInfluence = 0
	mainEmitter.EmissionDirection = Enum.NormalId.Top
	mainEmitter.Parent = particlePart
	mainEmitter:Emit(40)

	-- ===== PARTÍCULAS - CAMADA 2: SPARKS (rápidas, brilhantes) =====
	local sparkEmitter = Instance.new("ParticleEmitter")
	sparkEmitter.Rate = 0
	sparkEmitter.Lifetime = NumberRange.new(0.15, 0.35)
	sparkEmitter.Speed = NumberRange.new(12, 22)
	sparkEmitter.SpreadAngle = Vector2.new(180, 180)
	sparkEmitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.5),
		NumberSequenceKeypoint.new(1, 0)
	})
	sparkEmitter.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(1, 1)
	})
	sparkEmitter.Color = ColorSequence.new(Color3.new(1, 1, 1))
	sparkEmitter.LightEmission = 1
	sparkEmitter.LightInfluence = 0
	sparkEmitter.EmissionDirection = Enum.NormalId.Top
	sparkEmitter.Parent = particlePart
	sparkEmitter:Emit(25)

	-- ===== PARTÍCULAS - CAMADA 3: GLITTER (persistente, brilhante) =====
	local glitterEmitter = Instance.new("ParticleEmitter")
	glitterEmitter.Rate = 0
	glitterEmitter.Lifetime = NumberRange.new(0.6, 1.2)
	glitterEmitter.Speed = NumberRange.new(0.5, 1.5)
	glitterEmitter.SpreadAngle = Vector2.new(180, 180)
	glitterEmitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.2),
		NumberSequenceKeypoint.new(0.3, 0.6),
		NumberSequenceKeypoint.new(0.7, 0.4),
		NumberSequenceKeypoint.new(1, 0)
	})
	glitterEmitter.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(0.6, 0.2),
		NumberSequenceKeypoint.new(1, 1)
	})
	glitterEmitter.Color = ColorSequence.new(rarityColor, Color3.new(1, 1, 1))
	glitterEmitter.LightEmission = 1
	glitterEmitter.LightInfluence = 0
	glitterEmitter.EmissionDirection = Enum.NormalId.Top
	glitterEmitter.RotSpeed = NumberRange.new(-200, 200)
	glitterEmitter.Parent = particlePart
	glitterEmitter:Emit(15)

	-- ===== CONFETTI PARA ÉPICO/LENDÁRIO (burst único, sem delay) =====
	if isEpic then
		local confettiEmitter = Instance.new("ParticleEmitter")
		confettiEmitter.Rate = 0
		confettiEmitter.Lifetime = NumberRange.new(0.8, 1.5)
		confettiEmitter.Speed = NumberRange.new(2, 5)
		confettiEmitter.SpreadAngle = Vector2.new(180, 180)
		confettiEmitter.Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.8),
			NumberSequenceKeypoint.new(1, 0.3)
		})
		confettiEmitter.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0),
			NumberSequenceKeypoint.new(0.7, 0.3),
			NumberSequenceKeypoint.new(1, 1)
		})
		confettiEmitter.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 100, 100)),
			ColorSequenceKeypoint.new(0.25, Color3.fromRGB(100, 255, 100)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(100, 100, 255)),
			ColorSequenceKeypoint.new(0.75, Color3.fromRGB(255, 255, 100)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 100, 255)),
		})
		confettiEmitter.LightEmission = 0.5
		confettiEmitter.LightInfluence = 0
		confettiEmitter.EmissionDirection = Enum.NormalId.Top
		confettiEmitter.RotSpeed = NumberRange.new(-360, 360)
		confettiEmitter.Acceleration = Vector3.new(0, -3, 0)
		confettiEmitter.Parent = particlePart
		confettiEmitter:Emit(40)

		-- Som de sparkle (sem delay)
		local sparkleSound = Instance.new("Sound")
		sparkleSound.Name = "SparkleSound"
		sparkleSound.SoundId = "rbxassetid://6895079853"
		sparkleSound.Volume = 0.5
		sparkleSound.Parent = popup
		sparkleSound:Play()
		sparkleSound.Ended:Connect(function()
			sparkleSound.Parent = nil
		end)
	end

	-- ===== FLASH OUT (rápido) =====
	TweenService:Create(flashFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		BackgroundTransparency = 1
	}):Play()
	task.wait(0.25)
	if flashFrame and flashFrame.Parent then flashFrame.Parent = nil end

	-- Retorna referências para cleanup posterior
	return {
		particlePart = particlePart,
		mainEmitter = mainEmitter,
		sparkEmitter = sparkEmitter,
		glitterEmitter = glitterEmitter,
		explosionLight = explosionLight,
		explosionSound = explosionSound,
	}
end

-- Função para limpar efeitos da explosão
function ExplosionSystem.cleanup(fxRefs)
	if not fxRefs then return end
	for _, key in ipairs({"mainEmitter", "sparkEmitter", "glitterEmitter", "explosionLight", "explosionSound"}) do
		if fxRefs[key] and fxRefs[key].Parent then
			fxRefs[key].Parent = nil
		end
	end
	if fxRefs.particlePart and fxRefs.particlePart.Parent then
		fxRefs.particlePart.Parent = nil
	end
end

return ExplosionSystem