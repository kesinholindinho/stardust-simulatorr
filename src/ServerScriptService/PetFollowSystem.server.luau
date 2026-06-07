-- Pet Follow System Server
-- Gerencia os pets equipados que seguem o jogador no mundo 3D

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

print("🐾 Pet Follow System Server Started!")

-- ============================================
-- CONFIGURAÇÃO
-- ============================================
local PET_MODELS = ReplicatedStorage:WaitForChild("PetModels")
local MAX_PETS = 3
local FOLLOW_DISTANCE = 4   -- Distância base ATRÁS do jogador
local PET_HEIGHT = 2        -- Altura dos pets
local PET_SPACING = 3       -- Espaçamento horizontal entre pets
-- PET_SCALE removed: pets now use their original model size from PetModels

-- ============================================
-- CONFIGURAÇÃO DE PARTÍCULAS POR ESTRELA
-- ============================================
local STAR_PARTICLES = {
	[1] = nil, -- No effect at 1 star (default)
	[2] = {
		color = ColorSequence.new(Color3.fromRGB(200, 200, 255)), -- soft white/blue
		rate = 5,
		size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.2),
			NumberSequenceKeypoint.new(0.5, 0.3),
			NumberSequenceKeypoint.new(1, 0)
		}),
		speed = NumberRange.new(0.5, 1.5),
		lifetime = NumberRange.new(0.8, 1.5),
		lightEmission = 0.5,
		spread = Vector2.new(180, 180),
	},
	[3] = {
		color = ColorSequence.new(Color3.fromRGB(100, 200, 255), Color3.fromRGB(255, 255, 255)), -- cyan to white
		rate = 10,
		size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.3),
			NumberSequenceKeypoint.new(0.5, 0.5),
			NumberSequenceKeypoint.new(1, 0)
		}),
		speed = NumberRange.new(1, 2.5),
		lifetime = NumberRange.new(1, 2),
		lightEmission = 0.8,
		spread = Vector2.new(180, 180),
	},
	[4] = {
		color = ColorSequence.new(Color3.fromRGB(255, 200, 50), Color3.fromRGB(255, 150, 0)), -- gold to orange
		rate = 18,
		size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.4),
			NumberSequenceKeypoint.new(0.3, 0.6),
			NumberSequenceKeypoint.new(1, 0)
		}),
		speed = NumberRange.new(1.5, 3),
		lifetime = NumberRange.new(1, 2.5),
		lightEmission = 1,
		spread = Vector2.new(180, 180),
	},
	[5] = {
		color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 50, 200)),   -- pink/magenta
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(150, 50, 255)), -- purple
			ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 200, 50))    -- gold
		}),
		rate = 30,
		size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.5),
			NumberSequenceKeypoint.new(0.3, 0.8),
			NumberSequenceKeypoint.new(1, 0)
		}),
		speed = NumberRange.new(2, 5),
		lifetime = NumberRange.new(1.5, 3),
		lightEmission = 1,
		spread = Vector2.new(180, 180),
		-- Extra: also add a PointLight for ★5 pets
		pointLight = true,
		lightColor = Color3.fromRGB(200, 100, 255),
		lightBrightness = 2,
		lightRange = 12,
	},
}

-- Mapeamento de nomes de pets para nomes dos modelo
local PET_MODEL_NAMES = {
    -- Ovo da Luz pets
    ["Gato"] = "Pet Gato Commun",
    ["Galinha"] = "Pet Galinha Commun",
    ["Raposa"] = "Pet Raposa Raro",
    ["Morcego"] = "Pet Morcego Raro",
    ["Lobo"] = "Pet Lobo Epico",
    ["Coruja"] = "Pet Coruja Epico",
    ["Dragao"] = "Pet Dragao Lendario",
    -- Ovo Sombrio pets
    ["Fenix"] = "Pet Fenix Lendario",
    -- Boss reward pet
    ["PetMiniAstroKing"] = "Pet MiniAstroKing Lendario",
    -- EggCosmic pets
    ["PetBabyStar"] = "Pet BabyStar Commun",
    ["PetGalacticOctopus"] = "Pet GalacticOctopus Raro",
    ["PetNebulaCreature"] = "Pet NebulaCreature Epico",
    ["PetGalacticDragon"] = "Pet GalacticDragon Lendario",
    -- EggLunar pets
    ["PetLunarGhost"] = "Pet LunarGhost Commun",
    ["PetLunarComet"] = "Pet LunarComet Epico",
    ["PetCrystalBear"] = "Pet CrystalBear Raro",
    ["PetLunarPhoenix"] = "Pet LunarPhoenix Lendario",
}

-- ============================================
-- ARMAZENAMENTO DE PETS ATIVOS
-- ============================================
local playerPets = {} -- [player] = { [petId] = petModel }

-- ============================================
-- FUNÇÕES AUXILIARES
-- ============================================
local function getPetModel(petName)
    local modelName = PET_MODEL_NAMES[petName]
    if not modelName then
        warn("[PetSystem] Modelo não encontrado para pet:", petName)
        return nil
    end
    
    local model = PET_MODELS:FindFirstChild(modelName)
    if not model then
        warn("[PetSystem] Modelo não existe:", modelName)
        return nil
    end
    
    return model
end

local function addStarParticles(petModel, stars)
	local config = STAR_PARTICLES[stars or 1]
	if not config then return end -- no effect for 1 star

	-- Find the primary part or largest part to attach particles to
	local attachPart = petModel.PrimaryPart
	if not attachPart then
		for _, part in ipairs(petModel:GetDescendants()) do
			if part:IsA("BasePart") then
				attachPart = part
				break
			end
		end
	end
	if not attachPart then return end

	-- Create attachment point
	local attachment = Instance.new("Attachment")
	attachment.Name = "StarParticleAttachment"
	attachment.Position = Vector3.new(0, 0.5, 0) -- slightly above center
	attachment.Parent = attachPart

	-- Create particle emitter
	local emitter = Instance.new("ParticleEmitter")
	emitter.Name = "StarParticles"
	emitter.Color = config.color
	emitter.Rate = config.rate
	emitter.Size = config.size
	emitter.Speed = config.speed
	emitter.Lifetime = config.lifetime
	emitter.LightEmission = config.lightEmission
	emitter.LightInfluence = 0
	emitter.SpreadAngle = config.spread
	emitter.RotSpeed = NumberRange.new(-45, 45)
	emitter.Rotation = NumberRange.new(0, 360)
	emitter.EmissionDirection = Enum.NormalId.Top
	emitter.Parent = attachment

	-- Add PointLight for ★5 pets
	if config.pointLight then
		local light = Instance.new("PointLight")
		light.Name = "StarLight"
		light.Color = config.lightColor
		light.Brightness = config.lightBrightness
		light.Range = config.lightRange
		light.Parent = attachPart
	end

	-- Add base aura emitter for ★5 pets
	if (stars or 1) >= 5 then
		local baseAttach = Instance.new("Attachment")
		baseAttach.Position = Vector3.new(0, -0.5, 0)
		baseAttach.Parent = attachPart

		local auraEmitter = Instance.new("ParticleEmitter")
		auraEmitter.Color = ColorSequence.new(Color3.fromRGB(200, 100, 255))
		auraEmitter.Rate = 15
		auraEmitter.Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.8),
			NumberSequenceKeypoint.new(1, 0)
		})
		auraEmitter.Speed = NumberRange.new(0.1, 0.5)
		auraEmitter.Lifetime = NumberRange.new(1, 2)
		auraEmitter.LightEmission = 1
		auraEmitter.SpreadAngle = Vector2.new(90, 90)
		auraEmitter.EmissionDirection = Enum.NormalId.Top
		auraEmitter.Parent = baseAttach
	end
end

local function resizePetModel(model, targetSize)
    local primaryPart = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart")
    if not primaryPart then return end
    
    -- Calculate current bounding box size
    local cf, size = model:GetBoundingBox()
    local scaleX = targetSize.X / size.X
    local scaleY = targetSize.Y / size.Y
    local scaleZ = targetSize.Z / size.Z
    local scale = math.min(scaleX, scaleY, scaleZ) -- uniform scale
    
    -- Apply scale to all parts
    for _, part in ipairs(model:GetDescendants()) do
        if part:IsA("BasePart") then
            part.Size = part.Size * scale
            if part ~= primaryPart then
                part.Position = primaryPart.Position + (part.Position - primaryPart.Position) * scale
            end
        end
    end
end

local function spawnPetForPlayer(player, petData)
    if not player.Character then return nil end
    
    local humanoidRootPart = player.Character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then return nil end
    
    local petModel = getPetModel(petData.name)
    if not petModel then return nil end
    
    -- Clonar o modelo do pet
    local petClone = petModel:Clone()
    petClone.Name = "Pet_" .. petData.id
    
    -- Resize pet to fixed size
    resizePetModel(petClone, Vector3.new(2, 2, 2))
    
    -- Configurar o pet
    for _, part in ipairs(petClone:GetDescendants()) do
        if part:IsA("BasePart") then
            part.Anchored = true
            part.CanCollide = false
            part.CastShadow = false
        end
    end
    
    -- Atributos do pet
    petClone:SetAttribute("PetId", petData.id)
    petClone:SetAttribute("PetName", petData.name)
    petClone:SetAttribute("PetRarity", petData.rarity)
    petClone:SetAttribute("FloatPhase", math.random() * math.pi * 2)
    
    petClone.Parent = workspace
    
    -- Add star particle effects
    addStarParticles(petClone, petData.stars or 1)
    
    return petClone
end

local function removePet(petModel)
    if petModel and petModel.Parent then
        petModel:Destroy()
    end
end

local function removeAllPlayerPets(player)
    local pets = playerPets[player]
    if not pets then return end
    
    for petId, petModel in pairs(pets) do
        removePet(petModel)
    end
    
    playerPets[player] = nil
end

-- ============================================
-- SISTEMA DE MOVIMENTO DOS PETS
-- ============================================
local function updatePetPositions()
    for player, pets in pairs(playerPets) do
        -- Verificar se o jogador ainda está no jogo
        if not player or not player.Parent then
            removeAllPlayerPets(player)
            continue
        end
        
        local character = player.Character
        if not character then continue end
        
        local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
        if not humanoidRootPart then continue end
        
        -- Contar pets
        local petCount = 0
        for _ in pairs(pets) do petCount = petCount + 1 end
        
        local petIndex = 0
        for petId, petModel in pairs(pets) do
            if not petModel or not petModel.Parent then continue end
            
            petIndex = petIndex + 1
            
            -- Calcular posição em arco ATRÁS do jogador
            -- Z negativo = ATRÁS no espaço local do Roblox
            local angle = 0
            if petCount > 1 then
                -- Distribui os pets em um arco atrás do jogador
                angle = ((petIndex - 1) / (petCount - 1) - 0.5) * math.pi * 0.5
            end
            
            -- Offset horizontal (para os lados)
            local offsetX = math.sin(angle) * PET_SPACING
            
            -- Offset Z POSITIVO = ATRÁS do jogador
            local offsetZ = FOLLOW_DISTANCE + math.abs(math.cos(angle)) * 1.5
            
            -- Posição alvo (relativa ao CFrame do jogador)
            local playerCFrame = humanoidRootPart.CFrame
            local targetPosition = playerCFrame * CFrame.new(offsetX, PET_HEIGHT, offsetZ)
            
            -- Suavizar movimento (interpolação)
            local currentCFrame = petModel:GetPivot()
            local newCFrame = currentCFrame:Lerp(targetPosition, 0.12)
            
            -- Fazer o pet olhar para o jogador
            local lookDirection = (humanoidRootPart.Position - newCFrame.Position).Unit
            if lookDirection.Magnitude > 0 then
                local targetRotation = CFrame.lookAt(newCFrame.Position, humanoidRootPart.Position)
                newCFrame = newCFrame:Lerp(targetRotation, 0.08)
            end
            
            petModel:PivotTo(newCFrame)
        end
    end
end

-- Atualizar posição dos pets a cada frame
RunService.Heartbeat:Connect(updatePetPositions)

-- ============================================
-- EVENTOS DE EQUIPAR/DESEQUIPAR PETS
-- ============================================
task.spawn(function()
    -- Esperar o PetSpawnEvent ser criado pelo GameLogic
    local petSpawnEvent = nil
    local timeout = 10
    local startTime = tick()
    
    while not petSpawnEvent and (tick() - startTime) < timeout do
        petSpawnEvent = ReplicatedStorage:FindFirstChild("PetSpawnEvent")
        if not petSpawnEvent then
            task.wait(0.5)
        end
    end
    
    if petSpawnEvent then
        print("[PetSystem] PetSpawnEvent found, connecting...")
        
        petSpawnEvent.Event:Connect(function(player, equippedPetIds, ownedPets)
            print("[PetSystem] Received pet spawn event for", player.Name, "with", equippedPetIds and #equippedPetIds or 0, "pets")
            
            if not equippedPetIds or not ownedPets then return end
            
            -- Remover pets antigos deste jogador
            removeAllPlayerPets(player)
            
            -- Spawnar novos pets equipados
            playerPets[player] = {}
            
            for _, petId in ipairs(equippedPetIds) do
                -- Encontrar dados do pet
                local petData = nil
                for _, pet in ipairs(ownedPets) do
                    if pet.id == petId then
                        petData = pet
                        break
                    end
                end
                
                if petData then
                    local petModel = spawnPetForPlayer(player, petData)
                    if petModel then
                        playerPets[player][petId] = petModel
                        print("[PetSystem] Spawned pet", petData.name, "for", player.Name)
                    end
                end
            end
        end)
    else
        warn("[PetSystem] PetSpawnEvent not found after waiting!")
    end
end)

-- ============================================
-- LIMPEZA QUANDO JOGADOR SAI
-- ============================================
Players.PlayerRemoving:Connect(function(player)
    removeAllPlayerPets(player)
end)

print("🐾 Pet Follow System Server Fully Loaded!")