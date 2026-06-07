local BossSkyChanger = {}

-- ============================================
-- BOSS SKY CHANGER
-- Muda o céu quando o jogador entra na área do boss
-- ============================================

local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")

-- Céus
local skyGame = nil
local skyCrystal = nil
local originalLighting = {}

-- Buscar Sky Game no Lighting
for _, child in Lighting:GetChildren() do
    if child:IsA("Sky") and child.Name == "Sky Game" then
        skyGame = child
    end
end
-- Buscar Sky Crystal no ReplicatedStorage
skyCrystal = ReplicatedStorage:FindFirstChild("Sky Crystal")

-- Configuração das áreas de boss
local BOSS_AREAS = {
    {
        name = "Crystal Tree",
        areaPart = game.Workspace:FindFirstChild("Crstal Tree pasta") and game.Workspace["Crstal Tree pasta"]:FindFirstChild("Area Crystal"),
        ambient = Color3.fromRGB(100, 50, 150),
        fogColor = Color3.fromRGB(80, 40, 120),
        fogStart = 50,
        fogEnd = 200,
        outdoorAmbient = Color3.fromRGB(80, 40, 120),
    }
}

-- ============================================
-- ATIVAR CÉU DO BOSS
-- ============================================
local function activateBossSky(config)
    originalLighting = {
        Ambient = Lighting.Ambient,
        OutdoorAmbient = Lighting.OutdoorAmbient,
        FogColor = Lighting.FogColor,
        FogStart = Lighting.FogStart,
        FogEnd = Lighting.FogEnd,
        Brightness = Lighting.Brightness,
        EnvironmentDiffuseScale = Lighting.EnvironmentDiffuseScale,
        EnvironmentSpecularScale = Lighting.EnvironmentSpecularScale,
        ClockTime = Lighting.ClockTime,
    }

    if skyGame then skyGame.Parent = nil end
    if skyCrystal then skyCrystal.Parent = Lighting end

    Lighting.Ambient = config.ambient
    Lighting.OutdoorAmbient = config.outdoorAmbient or config.ambient
    Lighting.FogColor = config.fogColor
    Lighting.FogStart = config.fogStart or 0
    Lighting.FogEnd = config.fogEnd or 200
    Lighting.Brightness = 0.5
    Lighting.EnvironmentDiffuseScale = 0.3
    Lighting.EnvironmentSpecularScale = 0.3
    Lighting.ClockTime = 21
end

-- ============================================
-- RESTAURAR CÉU ORIGINAL
-- ============================================
local function restoreOriginalSky()
    if skyCrystal then skyCrystal.Parent = nil end
    if skyGame then skyGame.Parent = Lighting end

    if originalLighting.Ambient then
        Lighting.Ambient = originalLighting.Ambient
        Lighting.OutdoorAmbient = originalLighting.OutdoorAmbient
        Lighting.FogColor = originalLighting.FogColor
        Lighting.FogStart = originalLighting.FogStart
        Lighting.FogEnd = originalLighting.FogEnd
        Lighting.Brightness = originalLighting.Brightness
        Lighting.EnvironmentDiffuseScale = originalLighting.EnvironmentDiffuseScale
        Lighting.EnvironmentSpecularScale = originalLighting.EnvironmentSpecularScale
        Lighting.ClockTime = originalLighting.ClockTime
    end

    originalLighting = {}
end

-- ============================================
-- VERIFICAR SE JOGADOR ESTÁ NA ÁREA
-- ============================================
local function isPlayerInArea(areaPart)
    if not areaPart then return false end
    if not humanoidRootPart then return false end

    local areaCFrame = areaPart.CFrame
    local areaSize = areaPart.Size
    local point = areaCFrame:PointToObjectSpace(humanoidRootPart.Position)

    return math.abs(point.X) <= areaSize.X / 2
        and math.abs(point.Y) <= areaSize.Y / 2
        and math.abs(point.Z) <= areaSize.Z / 2
end

-- ============================================
-- LOOP DE VERIFICAÇÃO
-- ============================================
local currentBossArea = nil

RunService.Heartbeat:Connect(function()
    local inAnyBossArea = false
    local newArea = nil

    for _, area in ipairs(BOSS_AREAS) do
        if isPlayerInArea(area.areaPart) then
            inAnyBossArea = true
            newArea = area
            break
        end
    end

    if inAnyBossArea and currentBossArea ~= newArea then
        currentBossArea = newArea
        activateBossSky(newArea)
    elseif not inAnyBossArea and currentBossArea then
        currentBossArea = nil
        restoreOriginalSky()
    end
end)

-- ============================================
-- ATUALIZAR REFERÊNCIA DO PERSONAGEM
-- ============================================
player.CharacterAdded:Connect(function(newCharacter)
    character = newCharacter
    humanoidRootPart = character:WaitForChild("HumanoidRootPart")
end)

return BossSkyChanger