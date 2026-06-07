local SellPanel = {}

local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("StardustConfig"))
local PanelManager = require(ReplicatedStorage:WaitForChild("StardustUI"):WaitForChild("PanelManager"))
local NetworkClient = require(ReplicatedStorage:WaitForChild("StardustUI"):WaitForChild("NetworkClient"))

local panel = nil
local stardustLabel = nil
local starcoinsLabel = nil
local gameState = {stardust = 0, starcoins = 0}

-- ============================================
-- CREATE PANEL
-- ============================================
function SellPanel.create(screenGui, state)
    panel = screenGui:FindFirstChild("SellPanel")
    if not panel then return end
    
    gameState = state or gameState
    local sellClose = panel:FindFirstChild("CloseButton")
    
    -- Stardust amount
    stardustLabel = Instance.new("TextLabel")
    stardustLabel.Name = "StardustAmount"
    stardustLabel.Size = UDim2.new(1, 0, 0, 50)
    stardustLabel.Position = UDim2.new(0, 0, 0, 80)
    stardustLabel.BackgroundTransparency = 1
    stardustLabel.Text = "✨ " .. tostring(gameState.stardust)
    stardustLabel.TextColor3 = Config.COLORS.TITLE_TEXT
    stardustLabel.TextSize = 32
    stardustLabel.Font = Enum.Font.GothamBold
    stardustLabel.Parent = panel
    
    -- Arrow
    local arrowLabel = Instance.new("TextLabel")
    arrowLabel.Size = UDim2.new(0, 40, 0, 40)
    arrowLabel.Position = UDim2.new(0.5, -20, 0, 135)
    arrowLabel.BackgroundTransparency = 1
    arrowLabel.Text = "⬇️"
    arrowLabel.TextSize = 28
    arrowLabel.Font = Enum.Font.GothamBold
    arrowLabel.Parent = panel
    
    -- Starcoins amount
    starcoinsLabel = Instance.new("TextLabel")
    starcoinsLabel.Name = "StarcoinsAmount"
    starcoinsLabel.Size = UDim2.new(1, 0, 0, 40)
    starcoinsLabel.Position = UDim2.new(0, 0, 0, 180)
    starcoinsLabel.BackgroundTransparency = 1
    starcoinsLabel.Text = "🌙 " .. tostring(math.floor(gameState.stardust / 100))
    starcoinsLabel.TextColor3 = Config.COLORS.TITLE_TEXT
    starcoinsLabel.TextSize = 24
    starcoinsLabel.Font = Enum.Font.GothamBold
    starcoinsLabel.Parent = panel
    
    -- Buttons frame
    local buttonsFrame = Instance.new("Frame")
    buttonsFrame.Name = "Buttons"
    buttonsFrame.Size = UDim2.new(1, -48, 0, 48)
    buttonsFrame.Position = UDim2.new(0, 24, 1, -72)
    buttonsFrame.BackgroundTransparency = 1
    buttonsFrame.Parent = panel
    
    -- Sell All button
    local sellAllBtn = Instance.new("TextButton")
    sellAllBtn.Size = UDim2.new(0.48, 0, 1, 0)
    sellAllBtn.BackgroundColor3 = Config.COLORS.BUTTON_BG
    sellAllBtn.BorderSizePixel = 0
    sellAllBtn.Text = "Sell All"
    sellAllBtn.TextColor3 = Config.COLORS.TITLE_TEXT
    sellAllBtn.TextSize = 16
    sellAllBtn.Font = Enum.Font.GothamBold
    sellAllBtn.Parent = buttonsFrame
    PanelManager.createCorner(sellAllBtn, 0.15)
    PanelManager.createStroke(sellAllBtn)
    PanelManager.setupButtonEffects(sellAllBtn)
    
    sellAllBtn.MouseButton1Click:Connect(function()
        NetworkClient.sellStardust(gameState.stardust)
        SellPanel.playCoinAnimation(screenGui)
    end)
    
    -- Sell Half button
    local sellHalfBtn = Instance.new("TextButton")
    sellHalfBtn.Size = UDim2.new(0.48, 0, 1, 0)
    sellHalfBtn.Position = UDim2.new(0.52, 0, 0, 0)
    sellHalfBtn.BackgroundColor3 = Config.COLORS.SECONDARY_BG
    sellHalfBtn.BorderSizePixel = 0
    sellHalfBtn.Text = "Sell Half"
    sellHalfBtn.TextColor3 = Config.COLORS.TITLE_TEXT
    sellHalfBtn.TextSize = 16
    sellHalfBtn.Font = Enum.Font.GothamBold
    sellHalfBtn.Parent = buttonsFrame
    PanelManager.createCorner(sellHalfBtn, 0.15)
    PanelManager.createStroke(sellHalfBtn)
    PanelManager.setupButtonEffects(sellHalfBtn)
    
    sellHalfBtn.MouseButton1Click:Connect(function()
        local halfAmount = math.floor(gameState.stardust / 2)
        if halfAmount > 0 then
            NetworkClient.sellStardust(halfAmount)
            SellPanel.playCoinAnimation(screenGui)
        end
    end)
    
    -- Close button
    if sellClose then
        sellClose.MouseButton1Click:Connect(function()
            PanelManager.closeActivePanel()
        end)
    end
    
    PanelManager.registerPanel("SellPanel", panel)
end

-- ============================================
-- PLAY COIN ANIMATION
-- ============================================
function SellPanel.playCoinAnimation(screenGui)
    local coin = Instance.new("TextLabel")
    coin.Size = UDim2.new(0, 40, 0, 40)
    coin.Position = UDim2.new(0.5, -20, 0.5, -20)
    coin.BackgroundTransparency = 1
    coin.Text = "✨"
    coin.TextSize = 32
    coin.Font = Enum.Font.GothamBold
    coin.ZIndex = 1000
    coin.Parent = screenGui
    
    local tween = TweenService:Create(coin, TweenInfo.new(0.6, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
        Position = UDim2.new(0.5, 0, 0, 40),
        TextTransparency = 1
    })
    tween:Play()
    tween.Completed:Connect(function()
        coin:Destroy()
    end)
end

-- ============================================
-- UPDATE
-- ============================================
function SellPanel.update(stardust)
    gameState.stardust = stardust
    if stardustLabel then
        stardustLabel.Text = "✨ " .. tostring(stardust)
    end
    if starcoinsLabel then
        starcoinsLabel.Text = "🌙 " .. tostring(math.floor(stardust / 100))
    end
end

return SellPanel