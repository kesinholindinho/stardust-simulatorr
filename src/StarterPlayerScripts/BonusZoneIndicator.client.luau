local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Esperar pelo ScreenGui existente do StarterGui
local screenGui = playerGui:WaitForChild("StardustUI", 10)
if not screenGui then
    warn("[BonusZoneIndicator] StardustUI ScreenGui not found!")
    return
end

-- Container do indicador
local indicator = Instance.new("Frame")
indicator.Name = "BonusZoneIndicator"
indicator.Size = UDim2.new(0, 200, 0, 50)
indicator.Position = UDim2.new(0.5, -100, 0, 100)
indicator.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
indicator.BackgroundTransparency = 0.5
indicator.BorderSizePixel = 0
indicator.Visible = false
indicator.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 12)
corner.Parent = indicator

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(0, 255, 150)
stroke.Thickness = 2
stroke.Parent = indicator

-- Texto do indicador
local textLabel = Instance.new("TextLabel")
textLabel.Size = UDim2.new(1, 0, 1, 0)
textLabel.BackgroundTransparency = 1
textLabel.Text = "🌟 2x STARDUST"
textLabel.TextColor3 = Color3.fromRGB(0, 255, 150)
textLabel.TextSize = 20
textLabel.Font = Enum.Font.GothamBold
textLabel.Parent = indicator

-- Animação de pulso
local pulseInfo = TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
local pulseTween = TweenService:Create(stroke, pulseInfo, {Color = Color3.fromRGB(100, 255, 200)})

-- Verificar se está na zona de bônus
local function checkBonusZone()
    local character = player.Character
    if not character then return false end
    
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then return false end
    
    local zonasFolder = game.Workspace:FindFirstChild("ZonasBonus")
    if not zonasFolder then return false end
    
    for _, zone in ipairs(zonasFolder:GetChildren()) do
        if zone:IsA("BasePart") then
            local zoneCFrame = zone.CFrame
            local zoneSize = zone.Size
            local playerPos = humanoidRootPart.Position
            
            local relativePos = zoneCFrame:PointToObjectSpace(playerPos)
            if math.abs(relativePos.X) <= zoneSize.X / 2 and
               math.abs(relativePos.Y) <= zoneSize.Y / 2 and
               math.abs(relativePos.Z) <= zoneSize.Z / 2 then
                return true
            end
        end
    end
    
    return false
end

-- Loop para verificar posição
local wasInZone = false

task.spawn(function()
    while true do
        task.wait(0.3)
        
        local inZone = checkBonusZone()
        
        if inZone and not wasInZone then
            -- Entrou na zona
            indicator.Visible = true
            pulseTween:Play()
            
            -- Animação de entrada
            indicator.Size = UDim2.new(0, 0, 0, 50)
            local tweenIn = TweenService:Create(indicator, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                Size = UDim2.new(0, 200, 0, 50)
            })
            tweenIn:Play()
            
        elseif not inZone and wasInZone then
            -- Saiu da zona
            pulseTween:Cancel()
            
            -- Animação de saída
            local tweenOut = TweenService:Create(indicator, TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
                Size = UDim2.new(0, 0, 0, 50)
            })
            tweenOut:Play()
            tweenOut.Completed:Connect(function()
                indicator.Visible = false
            end)
        end
        
        wasInZone = inZone
    end
end)

print("[BonusZone] Indicator loaded!")