-- Pet Animation Client
-- Efeitos visuais nos pets (brilho baseado em raridade + animações)

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer

print("🐾 Pet Animation Client Started!")

-- ============================================
-- CONFIGURAÇÃO
-- ============================================

-- Cores baseadas na raridade
local RARITY_COLORS = {
    ["Common"] = Color3.fromRGB(200, 200, 200),
    ["Raro"] = Color3.fromRGB(100, 200, 255),
    ["Epico"] = Color3.fromRGB(200, 100, 255),
    ["Lendario"] = Color3.fromRGB(255, 200, 50)
}

-- Configurações de animação
local FLOAT_AMPLITUDE = 0.3 -- Altura da flutuação
local FLOAT_SPEED = 2 -- Velocidade da flutuação
local BOB_SPEED = 1.5 -- Velocidade do balanço
local GLOW_PULSE_SPEED = 3 -- Velocidade do pulso do brilho

-- ============================================
-- EFEITOS VISUAIS
-- ============================================
local function createPetGlow(petModel, rarity)
    -- Verificar se ja tem luz
    local existingLight = petModel:FindFirstChild("PetGlow", true)
    if existingLight then return existingLight end
    
    local color = RARITY_COLORS[rarity] or Color3.fromRGB(255, 255, 255)
    
    -- Encontrar a parte principal do pet
    local mainPart = petModel:FindFirstChildWhichIsA("BasePart")
    if not mainPart then return nil end
    
    -- Criar ponto de luz
    local light = Instance.new("PointLight")
    light.Name = "PetGlow"
    light.Color = color
    light.Brightness = 0.8
    light.Range = 6
    light.Parent = mainPart
    
    return light
end

-- ============================================
-- ENCONTRAR PETS DO JOGADOR
-- ============================================
local function findPlayerPets()
    local pets = {}
    
    for _, obj in ipairs(workspace:GetChildren()) do
        if obj.Name:sub(1, 4) == "Pet_" and obj:IsA("Model") then
            table.insert(pets, obj)
        end
    end
    
    return pets
end

-- ============================================
-- LOOP DE ANIMAÇÃO
-- ============================================
local startTime = tick()

RunService.RenderStepped:Connect(function()
    local currentTime = tick() - startTime
    local pets = findPlayerPets()
    
    for _, petModel in ipairs(pets) do
        local rarity = petModel:GetAttribute("PetRarity")
        local floatPhase = petModel:GetAttribute("FloatPhase") or 0
        
        -- Criar efeito de luz se nao existir
        if rarity then
            local light = createPetGlow(petModel, rarity)
            
            -- Animar o brilho (pulsar)
            if light then
                local pulse = math.sin(currentTime * GLOW_PULSE_SPEED + floatPhase) * 0.3 + 0.8
                light.Brightness = pulse
            end
        end
        
        -- Animar partes do pet (se tiver mais de uma parte)
        local parts = {}
        for _, child in ipairs(petModel:GetDescendants()) do
            if child:IsA("BasePart") and child.Name ~= "HumanoidRootPart" then
                table.insert(parts, child)
            end
        end
        
        -- Aplicar animação de flutuação nas partes
        for i, part in ipairs(parts) do
            -- Calcular offset de flutuação
            local floatOffset = math.sin(currentTime * FLOAT_SPEED + floatPhase + i * 0.5) * FLOAT_AMPLITUDE
            
            -- Aplicar rotação suave (balanço)
            local bobAngle = math.sin(currentTime * BOB_SPEED + floatPhase) * 0.1
            
            -- Salvar posição original se não existir
            if not part:GetAttribute("OriginalY") then
                part:SetAttribute("OriginalY", part.Position.Y)
            end
        end
    end
end)

print("🐾 Pet Animation Client Fully Loaded!")