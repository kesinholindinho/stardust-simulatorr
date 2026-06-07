-- =====================================================
-- PARTE 3 - PET REVEAL OTIMIZADO
-- Bounce com TweenService, sparkle controlado,
-- plataforma com tween único, info card sincronizado
-- =====================================================

local PetRevealSystem = {}

local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

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

-- Aliases de raridade para busca de modelos
local RARITY_ALIASES = {
	["Common"] = {"Common", "Commun"},
	["Raro"] = {"Raro", "Rare"},
	["Epico"] = {"Epico", "Epic"},
	["Lendario"] = {"Lendario", "Legendary"},
}

-- Verifica se raridade é épica ou lendária
local function isEpicOrHigher(rarity)
	return rarity == "Epico" or rarity == "Epic" or rarity == "Lendario" or rarity == "Legendary"
end

-- Função para encontrar modelo do pet no ReplicatedStorage
-- Map pet names to their combined egg+pet folders
-- Includes both model keys (no spaces) and display names (with spaces)
local PET_FOLDERS = {
    -- Model keys (no spaces) - from egg.pets
    ["PetBabyStar"]        = "Ovo Cosmico e seus Pets",
    ["PetGalacticDragon"]  = "Ovo Cosmico e seus Pets",
    ["PetGalacticOctopus"] = "Ovo Cosmico e seus Pets",
    ["PetNebulaCreature"]  = "Ovo Cosmico e seus Pets",
    ["PetLunarGhost"]      = "Ovo Lunar e seus Pets",
    ["PetCrystalBear"]     = "Ovo Lunar e seus Pets",
    ["PetLunarComet"]      = "Ovo Lunar e seus Pets",
    ["PetLunarPhoenix"]    = "Ovo Lunar e seus Pets",
    -- Display names (with spaces) - from egg.petNames / server pet.name
    ["Baby Star"]          = "Ovo Cosmico e seus Pets",
    ["Galactic Dragon"]    = "Ovo Cosmico e seus Pets",
    ["Galactic Octopus"]   = "Ovo Cosmico e seus Pets",
    ["Nebula Creature"]    = "Ovo Cosmico e seus Pets",
    ["Crystal Bear"]       = "Ovo Lunar e seus Pets",
    ["Lunar Ghost"]        = "Ovo Lunar e seus Pets",
    ["Lunar Comet"]        = "Ovo Lunar e seus Pets",
    ["Lunar Phoenix"]      = "Ovo Lunar e seus Pets",
}

local function findPetModel(petName, petRarity)
	-- First pass: check combined egg+pet folders
	local folderName = PET_FOLDERS[petName]
	if folderName then
		local folder = ReplicatedStorage:FindFirstChild(folderName)
		if folder then
			-- Strip "Pet" prefix for folder lookup (models are named without prefix)
			local displayName = petName
			if displayName:sub(1, 3) == "Pet" and #displayName > 3 then
				displayName = displayName:sub(4)
			end
			local model = folder:FindFirstChild(displayName)
			if model then return model end
			-- Also try original petName
			model = folder:FindFirstChild(petName)
			if model then return model end
			-- Try name without spaces (display names have spaces, model names don't)
			local noSpaceName = displayName:gsub(" ", "")
			model = folder:FindFirstChild(noSpaceName)
			if model then return model end
			noSpaceName = petName:gsub(" ", "")
			model = folder:FindFirstChild(noSpaceName)
			if model then return model end
		end
	end

	local petModelsFolder = ReplicatedStorage:FindFirstChild("PetModels")
	if not petModelsFolder then return nil end

	-- Strip "Pet" prefix if present
	local displayName = petName
	if displayName:sub(1, 3) == "Pet" and #displayName > 3 then
		displayName = displayName:sub(4)
	end

	-- Build rarity options
	local rarityOptions = {}
	if petRarity then
		local aliases = RARITY_ALIASES[petRarity]
		if aliases then
			for _, alias in ipairs(aliases) do
				table.insert(rarityOptions, alias)
			end
		else
			table.insert(rarityOptions, petRarity)
		end
	end

	-- Try exact match: "Pet [DisplayName] [Rarity]"
	for _, rarity in ipairs(rarityOptions) do
		local exactName = "Pet " .. displayName .. " " .. rarity
		local model = petModelsFolder:FindFirstChild(exactName)
		if model then return model end
		-- Also try without spaces in display name
		local noSpaceExact = "Pet " .. displayName:gsub(" ", "") .. " " .. rarity
		model = petModelsFolder:FindFirstChild(noSpaceExact)
		if model then return model end
	end

	-- Fallback: search by display name
	for _, child in ipairs(petModelsFolder:GetChildren()) do
		if child.Name:find(displayName, 1, true) then
			return child
		end
	end

	-- Fallback: search by display name without spaces
	local noSpaceDisplayName = displayName:gsub(" ", "")
	if noSpaceDisplayName ~= displayName then
		for _, child in ipairs(petModelsFolder:GetChildren()) do
			if child.Name:find(noSpaceDisplayName, 1, true) then
				return child
			end
		end
	end

	-- Last fallback: search by original petName
	for _, child in ipairs(petModelsFolder:GetChildren()) do
		if child.Name:find(petName, 1, true) then
			return child
		end
	end

	-- Last fallback: search by petName without spaces
	local noSpacePetName = petName:gsub(" ", "")
	if noSpacePetName ~= petName then
		for _, child in ipairs(petModelsFolder:GetChildren()) do
			if child.Name:find(noSpacePetName, 1, true) then
				return child
			end
		end
	end

	return nil
end

-- Preload removido — já é feito no EggsPanel antes do popup

-- Ensure a model has a PrimaryPart set for ScaleTo/PivotTo
local function ensurePrimaryPart(model)
	if model.PrimaryPart then return end
	-- Try to find a part named "HumanoidRootPart" or "RootPart" first
	local hrp = model:FindFirstChild("HumanoidRootPart")
	if hrp and hrp:IsA("BasePart") then
		model.PrimaryPart = hrp
		return
	end
	-- Fall back to the largest part (most likely the main body)
	local largestPart = nil
	local largestVolume = 0
	for _, desc in ipairs(model:GetDescendants()) do
		if desc:IsA("BasePart") then
			local vol = desc.Size.X * desc.Size.Y * desc.Size.Z
			if vol > largestVolume then
				largestVolume = vol
				largestPart = desc
			end
		end
	end
	if largestPart then
		model.PrimaryPart = largestPart
	end
end

-- Resize model to target size using bounding box (scales parts + offsets correctly)
local function resizeModel(model, targetSize)
	ensurePrimaryPart(model)
	if not model.PrimaryPart then return end

	local _, size = model:GetBoundingBox()
	local maxDim = math.max(size.X, size.Y, size.Z)
	if maxDim < 0.1 then return end -- safety fallback
	local scale = targetSize / maxDim

	local primaryPos = model.PrimaryPart.Position
	for _, part in ipairs(model:GetDescendants()) do
		if part:IsA("BasePart") then
			local offset = part.Position - primaryPos
			part.Size = part.Size * scale
			part.Position = primaryPos + offset * scale
		end
	end
end

-- Resize pet model specifically for the reveal animation (3 studs max)
-- Uses ScaleTo so the bounce animation's ScaleTo calls stay consistent.
-- Returns the target scale factor (or 1 as fallback).
local function resizePetForReveal(model)
	if not model.PrimaryPart then
		-- Set PrimaryPart if missing
		for _, part in ipairs(model:GetDescendants()) do
			if part:IsA("BasePart") then
				model.PrimaryPart = part
				break
			end
		end
	end
	if not model.PrimaryPart then return 1 end

	-- Normalize scale factor first (bake in any existing scale so ScaleTo works correctly)
	-- Models imported with a non-1 scale factor would break the bounce animation
	-- if we only resize parts manually, because ScaleTo(1) would restore the
	-- original (pre-resize) size.
	pcall(function() model:ScaleTo(1) end)

	-- Get bounding box at scale 1
	local _, currentSize = model:GetBoundingBox()
	local largestSide = math.max(currentSize.X, currentSize.Y, currentSize.Z)
	if largestSide <= 0 then return 1 end

	-- Target: 3 studs max (sized for reveal UI)
	local targetScale = 3 / largestSide
	pcall(function() model:ScaleTo(targetScale) end)

	return targetScale
end

-- Função principal: mostra o pet com bounce + sparkles + info card
function PetRevealSystem.show(viewport, camera, popup, petData, Config, PanelManager, prebuiltPetModel, skipInfoUI)
	local petName = petData.name or "Pet"
	local petEmoji = petData.emoji or "🐾"
	local petRarity = petData.rarity or "Common"
	local petMult = petData.multiplier or 1.0
	local rarityColor = RARITY_COLORS[petRarity] or Config.RARITY_COLORS[petRarity] or Color3.fromRGB(255, 255, 255)
	local isEpic = isEpicOrHigher(petRarity)

	local petModelClone = nil
	local petRotConnection = nil
	local sparklePart = nil
	local platformPart = nil

	-- ===== SOM DE REVELAÇÃO =====
	local revealSound = Instance.new("Sound")
	revealSound.Name = "PetRevealSound"
	revealSound.SoundId = "rbxassetid://6895079853"
	revealSound.Volume = 0.6
	revealSound.PlaybackSpeed = isEpic and 0.9 or 1.1
	revealSound.Parent = popup
	revealSound:Play()
	revealSound.Ended:Connect(function()
		revealSound.Parent = nil
	end)

	-- ===== PLATAFORMA BRILHANTE REMOVIDA =====
	-- (removida a pedido - não aparece mais sob o pet)

	-- ===== SPARKLE PARTICLES AO REDOR DO PET =====
	sparklePart = Instance.new("Part")
	sparklePart.Name = "SparkleOrigin"
	sparklePart.Size = Vector3.new(0.1, 0.1, 0.1)
	sparklePart.Position = Vector3.new(0, 0, 0)
	sparklePart.Transparency = 1
	sparklePart.CanCollide = false
	sparklePart.Anchored = true
	sparklePart.Parent = viewport

	local sparkleEmitter = Instance.new("ParticleEmitter")
	sparkleEmitter.Rate = isEpic and 12 or 6
	sparkleEmitter.Lifetime = NumberRange.new(0.8, 1.5)
	sparkleEmitter.Speed = NumberRange.new(0.5, 2)
	sparkleEmitter.SpreadAngle = Vector2.new(180, 180)
	sparkleEmitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(0.3, 0.5),
		NumberSequenceKeypoint.new(0.7, 0.3),
		NumberSequenceKeypoint.new(1, 0)
	})
	sparkleEmitter.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.2, 0),
		NumberSequenceKeypoint.new(0.8, 0.2),
		NumberSequenceKeypoint.new(1, 1)
	})
	sparkleEmitter.Color = ColorSequence.new(rarityColor, Color3.new(1, 1, 1))
	sparkleEmitter.LightEmission = 1
	sparkleEmitter.LightInfluence = 0
	sparkleEmitter.EmissionDirection = Enum.NormalId.Top
	sparkleEmitter.RotSpeed = NumberRange.new(-180, 180)
	sparkleEmitter.Parent = sparklePart

	-- ===== TENTAR MOSTRAR MODELO 3D DO PET =====
	-- Bug 3: Use prebuilt pet model from combined folder if available, otherwise find it
	local petModelTemplate = prebuiltPetModel or findPetModel(petName, petRarity)

	if petModelTemplate then
		petModelClone = petModelTemplate:Clone()

		-- Ensure PrimaryPart is set for ScaleTo/PivotTo
		ensurePrimaryPart(petModelClone)

		-- Resize pet model for reveal animation (3 studs max)
		local targetScale = resizePetForReveal(petModelClone)

		-- Calculate base orientation from PrimaryPart's PivotOffset
		-- Meshes imported with non-standard up directions have a PivotOffset rotation.
		-- PivotTo(CFrame.new(0,0,0)) would compensate for this, flipping the mesh.
		-- By including the PivotOffset rotation in the target, the mesh stays upright.
		local baseOrientation = CFrame.new()
		if petModelClone.PrimaryPart then
			baseOrientation = petModelClone.PrimaryPart.PivotOffset.Rotation
		end

		-- Anchor all parts for ViewportFrame
		for _, desc in ipairs(petModelClone:GetDescendants()) do
			if desc:IsA("BasePart") then
				desc.Anchored = true
				desc.CanCollide = false
			end
		end

		petModelClone.Parent = viewport

		petModelClone:PivotTo(CFrame.new(0, 0, 0) * baseOrientation)
		camera.CFrame = CFrame.new(Vector3.new(0, 0, 5), Vector3.new(0, 0, 0))

		-- Posição da plataforma não precisa mais ser ajustada

		-- Começa minúsculo para pop-in
		local startScale = targetScale * 0.01
		pcall(function() petModelClone:ScaleTo(startScale) end)

		-- ===== BOUNCE-IN COM TWEEN (sem loop while) =====
		local bounceInfo = TweenInfo.new(0.6, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out)
		-- ScaleTo não é tweenável diretamente, usamos RenderStepped com duração controlada
		local bounceStart = tick()
		local bounceDuration = 0.6
		local bounceConn
		bounceConn = RunService.RenderStepped:Connect(function()
			if not petModelClone or not petModelClone.Parent then
				bounceConn:Disconnect()
				return
			end
			local elapsed = tick() - bounceStart
			if elapsed >= bounceDuration then
				pcall(function() petModelClone:ScaleTo(targetScale) end)
				bounceConn:Disconnect()
				return
			end
			local progress = elapsed / bounceDuration
			-- Elastic out: 1 - 2^(-10t) * cos((t*10 - 0.75) * 2π/3)
			local elastic = 1 - math.pow(2, -10 * progress) * math.cos((progress * 10 - 0.75) * (2 * math.pi) / 3)
			local currentScale = startScale + (targetScale - startScale) * math.min(elastic, 1)
			pcall(function() petModelClone:ScaleTo(currentScale) end)
		end)

		-- ===== ROTAÇÃO SUAVE + BOUNCE (conectado junto, 1 conexão só) =====
		local animStartTime = tick()
		petRotConnection = RunService.RenderStepped:Connect(function()
			if not petModelClone or not petModelClone.Parent then
				if petRotConnection then petRotConnection:Disconnect() end
				return
			end
			local elapsed = tick() - animStartTime
			local rotAngle = elapsed * 1.2
			local bounceY = math.sin(elapsed * 2.5) * 0.3
			pcall(function() petModelClone:PivotTo(CFrame.new(0, bounceY, 0) * CFrame.Angles(0, rotAngle, 0) * baseOrientation) end)
		end)
	else
		-- Fallback: mostrar emoji
		local petEmojiLabel = Instance.new("TextLabel")
		petEmojiLabel.Name = "PetEmojiFallback"
		petEmojiLabel.Size = UDim2.new(1, 0, 0, 260)
		petEmojiLabel.Position = UDim2.new(0, 0, 0, 10)
		petEmojiLabel.BackgroundTransparency = 1
		petEmojiLabel.Text = petEmoji
		petEmojiLabel.TextSize = 0
		petEmojiLabel.Font = Enum.Font.GothamBold
		petEmojiLabel.ZIndex = 5
		petEmojiLabel.Parent = popup

		-- Bounce-in para emoji
		TweenService:Create(petEmojiLabel, TweenInfo.new(0.6, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out), {
			TextSize = 100
		}):Play()
	end

	-- ===== BADGE "NOVO!" COM BOUNCE =====
	if not skipInfoUI then
		local novoBadge = Instance.new("Frame")
		novoBadge.Name = "NovoBadge"
		novoBadge.Size = UDim2.new(0, 50, 0, 22)
		novoBadge.Position = UDim2.new(0, 10, 0, 38)
		novoBadge.BackgroundColor3 = rarityColor
		novoBadge.BorderSizePixel = 0
		novoBadge.ZIndex = 15
		novoBadge.Parent = popup
		local novoCorner = Instance.new("UICorner")
		novoCorner.CornerRadius = UDim.new(0, 6)
		novoCorner.Parent = novoBadge

		local novoText = Instance.new("TextLabel")
		novoText.Size = UDim2.new(1, 0, 1, 0)
		novoText.BackgroundTransparency = 1
		novoText.Text = "NOVO!"
		novoText.TextColor3 = Color3.fromRGB(20, 20, 20)
		novoText.TextSize = 10
		novoText.Font = Enum.Font.GothamBold
		novoText.ZIndex = 16
		novoText.Parent = novoBadge

		-- Bounce-in do badge (sem delay, junto com o reveal)
		novoBadge.Size = UDim2.new(0, 0, 0, 0)
		novoBadge.Position = UDim2.new(0, 10, 0, 44)
		TweenService:Create(novoBadge, TweenInfo.new(0.4, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out), {
			Size = UDim2.new(0, 50, 0, 22),
			Position = UDim2.new(0, 10, 0, 38)
		}):Play()
	end

	-- ===== INFO CARD COM SLIDE-IN =====
	if not skipInfoUI then
		local infoCard = Instance.new("Frame")
		infoCard.Name = "PetInfoCard"
		infoCard.Size = UDim2.new(1, -32, 0, 100)
		infoCard.Position = UDim2.new(0, 16, 0, 420) -- Começa abaixo (fora da tela)
		infoCard.BackgroundColor3 = Config.COLORS.SECONDARY_BG
		infoCard.BorderSizePixel = 0
		infoCard.BackgroundTransparency = 1
		infoCard.ZIndex = 10
		infoCard.ClipsDescendants = true
		infoCard.Parent = popup
		PanelManager.createCorner(infoCard, 0.08)
		PanelManager.createStroke(infoCard, rarityColor, 1.5)

		-- Slide-in + fade do info card (sem delay, sincronizado)
		TweenService:Create(infoCard, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Position = UDim2.new(0, 16, 0, 305),
			BackgroundTransparency = 0
		}):Play()

		-- Nome do pet com glow
		local petNameLabel = Instance.new("TextLabel")
		petNameLabel.Size = UDim2.new(1, -16, 0, 28)
		petNameLabel.Position = UDim2.new(0, 8, 0, 8)
		petNameLabel.BackgroundTransparency = 1
		petNameLabel.Text = petEmoji .. " " .. petName
		petNameLabel.TextColor3 = rarityColor
		petNameLabel.TextSize = 20
		petNameLabel.Font = Enum.Font.GothamBold
		petNameLabel.ZIndex = 11
		petNameLabel.Parent = infoCard

		-- Glow no nome do pet para épico/lendário (tween ping-pong, sem loop)
		if isEpic then
			local nameGlow = Instance.new("UIStroke")
			nameGlow.Color = rarityColor
			nameGlow.Thickness = 1.5
			nameGlow.Transparency = 0.5
			nameGlow.Parent = petNameLabel

			local glowUp = TweenService:Create(nameGlow, TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
				Transparency = 0.2
			})
			local glowDown = TweenService:Create(nameGlow, TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
				Transparency = 0.7
			})
			glowUp.Completed:Connect(function()
				if nameGlow and nameGlow.Parent then glowDown:Play() end
			end)
			glowDown.Completed:Connect(function()
				if nameGlow and nameGlow.Parent then glowUp:Play() end
			end)
			glowUp:Play()
		end

		-- Badge de raridade
		local rarityBadge = Instance.new("Frame")
		rarityBadge.Size = UDim2.new(0, 80, 0, 20)
		rarityBadge.Position = UDim2.new(0, 8, 0, 38)
		rarityBadge.BackgroundColor3 = rarityColor
		rarityBadge.BorderSizePixel = 0
		rarityBadge.ZIndex = 11
		rarityBadge.Parent = infoCard
		PanelManager.createCorner(rarityBadge, 0.5)

		local rarityBadgeText = Instance.new("TextLabel")
		rarityBadgeText.Size = UDim2.new(1, 0, 1, 0)
		rarityBadgeText.BackgroundTransparency = 1
		rarityBadgeText.Text = petRarity
		rarityBadgeText.TextColor3 = Color3.fromRGB(20, 20, 20)
		rarityBadgeText.TextSize = 10
		rarityBadgeText.Font = Enum.Font.GothamBold
		rarityBadgeText.ZIndex = 12
		rarityBadgeText.Parent = rarityBadge

		-- Multiplicador
		local multLabel = Instance.new("TextLabel")
		multLabel.Size = UDim2.new(1, -16, 0, 20)
		multLabel.Position = UDim2.new(0, 8, 0, 62)
		multLabel.BackgroundTransparency = 1
		multLabel.Text = "Multiplicador: x" .. tostring(petMult) .. " ✨"
		multLabel.TextColor3 = Config.COLORS.DESC_TEXT
		multLabel.TextSize = 13
		multLabel.Font = Enum.Font.GothamSemibold
		multLabel.ZIndex = 11
		multLabel.Parent = infoCard
	end

	-- ===== RARITY RAY BURST (raios simétricos, sem stagger) =====
	if not skipInfoUI and isEpic then
		local rayCount = 8
		for i = 1, rayCount do
			local angle = (i / rayCount) * math.pi * 2
			local ray = Instance.new("Frame")
			ray.Name = "RarityRay" .. i
			ray.Size = UDim2.new(0, 3, 0, 0)
			ray.Position = UDim2.new(0.5, -1.5, 0.28, 0)
			ray.BackgroundColor3 = rarityColor
			ray.BackgroundTransparency = 0.3
			ray.BorderSizePixel = 0
			ray.ZIndex = 4
			ray.Rotation = math.deg(angle)
			ray.Parent = popup

			-- Todos os raios ao mesmo tempo (simétrico)
			TweenService:Create(ray, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Size = UDim2.new(0, 3, 0, 200),
				Position = UDim2.new(0.5, -1.5, 0.28, -100),
				BackgroundTransparency = 1
			}):Play()

			task.delay(0.6, function()
				if ray and ray.Parent then ray.Parent = nil end
			end)
		end
	end

	-- Retorna referências para cleanup
	return {
		petModelClone = petModelClone,
		petRotConnection = petRotConnection,
		infoCard = skipInfoUI and nil or infoCard,
		sparklePart = sparklePart,
		sparkleEmitter = sparkleEmitter,
		platformPart = platformPart,
		revealSound = revealSound,
	}
end

-- Função para limpar efeitos do pet
function PetRevealSystem.cleanup(petRefs)
	if not petRefs then return end
	if petRefs.petRotConnection then
		petRefs.petRotConnection:Disconnect()
	end
	if petRefs.petModelClone and petRefs.petModelClone.Parent then
		petRefs.petModelClone.Parent = nil
	end
	if petRefs.sparklePart and petRefs.sparklePart.Parent then
		petRefs.sparklePart.Parent = nil
	end
	if petRefs.platformPart and petRefs.platformPart.Parent then
		petRefs.platformPart.Parent = nil
	end
	if petRefs.revealSound and petRefs.revealSound.Parent then
		petRefs.revealSound.Parent = nil
	end
end

return PetRevealSystem