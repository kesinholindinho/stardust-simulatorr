local WorldsPanel = {}

local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("StardustConfig"))
local PanelManager = require(ReplicatedStorage:WaitForChild("StardustUI"):WaitForChild("PanelManager"))
local NetworkClient = require(ReplicatedStorage:WaitForChild("StardustUI"):WaitForChild("NetworkClient"))

local panel = nil

-- Mundos reais do jogo (todos gratuitos e desbloqueados)
local WORLDS = {
    {name = "Ilha Inicial", emoji = "🏠", unlocked = true, multiplier = "x1", price = 0},
    {name = "Ilha do Cogumelo", emoji = "🍄", unlocked = true, multiplier = "x1", price = 0},
    {name = "Ilha Star", emoji = "⭐", unlocked = true, multiplier = "x1.5", price = 0},
    {name = "Ilha Cometa", emoji = "☄️", unlocked = true, multiplier = "x2", price = 0},
    {name = "Terra Morta", emoji = "💀", unlocked = true, multiplier = "x2.5", price = 0},
    {name = "Crystal Tree", emoji = "💎", unlocked = true, multiplier = "x3", price = 0}
}

-- ============================================
-- CREATE PANEL
-- ============================================
function WorldsPanel.create(screenGui)
    panel = screenGui:FindFirstChild("WorldsPanel")
    if not panel then return end
    
    local COLORS = Config.COLORS
    local worldsClose = panel:FindFirstChild("CloseButton")
    
    local content = Instance.new("ScrollingFrame")
    content.Name = "Content"
    content.Size = UDim2.new(1, -32, 1, -60)
    content.Position = UDim2.new(0, 16, 0, 52)
    content.BackgroundTransparency = 1
    content.ScrollBarThickness = 3
    content.ScrollBarImageColor3 = Color3.fromRGB(80, 80, 80)
    content.Parent = panel
    
    local padding = Instance.new("UIPadding")
    padding.PaddingTop = UDim.new(0, 10)
    padding.PaddingBottom = UDim.new(0, 10)
    padding.PaddingLeft = UDim.new(0, 10)
    padding.PaddingRight = UDim.new(0, 10)
    padding.Parent = content
    
    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 10)
    layout.Parent = content
    
    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        content.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 20)
    end)
    
    -- Create world cards
    for _, world in ipairs(WORLDS) do
        local card = Instance.new("Frame")
        card.Name = world.name
        card.Size = UDim2.new(1, 0, 0, 80)
        card.BackgroundColor3 = COLORS.SECONDARY_BG
        card.BorderSizePixel = 0
        card.Parent = content
        PanelManager.createCorner(card, 0.1)
        PanelManager.createStroke(card)
        
        local worldEmoji = Instance.new("TextLabel")
        worldEmoji.Size = UDim2.new(0, 60, 1, 0)
        worldEmoji.BackgroundTransparency = 1
        worldEmoji.Text = world.emoji
        worldEmoji.TextSize = 36
        worldEmoji.Font = Enum.Font.GothamBold
        worldEmoji.Parent = card
        
        local worldName = Instance.new("TextLabel")
        worldName.Size = UDim2.new(0, 150, 0, 24)
        worldName.Position = UDim2.new(0, 60, 0, 10)
        worldName.BackgroundTransparency = 1
        worldName.Text = world.name
        worldName.TextColor3 = COLORS.TITLE_TEXT
        worldName.TextSize = 16
        worldName.Font = Enum.Font.GothamBold
        worldName.TextXAlignment = Enum.TextXAlignment.Left
        worldName.Parent = card
        
        local multLabel = Instance.new("TextLabel")
        multLabel.Size = UDim2.new(0, 80, 0, 20)
        multLabel.Position = UDim2.new(0, 60, 0, 35)
        multLabel.BackgroundTransparency = 1
        multLabel.Text = world.multiplier .. " Stardust"
        multLabel.TextColor3 = COLORS.DESC_TEXT
        multLabel.TextSize = 12
        multLabel.Font = Enum.Font.GothamSemibold
        multLabel.TextXAlignment = Enum.TextXAlignment.Left
        multLabel.Parent = card
        
        local actionBtn = Instance.new("TextButton")
        actionBtn.Name = "ActionBtn"
        actionBtn.Size = UDim2.new(0, 100, 0, 36)
        actionBtn.Position = UDim2.new(1, -110, 0, 22)
        actionBtn.BackgroundColor3 = world.unlocked and Color3.fromRGB(80, 200, 120) or COLORS.BUTTON_BG
        actionBtn.BorderSizePixel = 0
        actionBtn.Text = world.unlocked and "Travel" or ("✨ " .. tostring(world.price))
        actionBtn.TextColor3 = COLORS.TITLE_TEXT
        actionBtn.TextSize = 13
        actionBtn.Font = Enum.Font.GothamBold
        actionBtn.Parent = card
        PanelManager.createCorner(actionBtn, 0.2)
        PanelManager.setupButtonEffects(actionBtn)
        
        actionBtn.MouseButton1Click:Connect(function()
            if world.unlocked then
                NetworkClient.travelToWorld(world.name)
            else
                NetworkClient.unlockWorld(world.name)
            end
        end)
    end
    
    -- Close button
    if worldsClose then
        worldsClose.MouseButton1Click:Connect(function()
            PanelManager.closeActivePanel()
        end)
    end
    
    PanelManager.registerPanel("WorldsPanel", panel)
end

-- ============================================
-- UPDATE UNLOCKED WORLDS
-- ============================================
function WorldsPanel.updateUnlocked(unlockedWorlds)
    if not panel or not unlockedWorlds then return end
    
    local content = panel:FindFirstChild("Content")
    if not content then return end
    
    for _, world in ipairs(WORLDS) do
        local card = content:FindFirstChild(world.name)
        if card then
            local isUnlocked = table.find(unlockedWorlds, world.name) ~= nil or world.unlocked
            local actionBtn = card:FindFirstChild("ActionBtn")
            
            if actionBtn then
                actionBtn.Text = isUnlocked and "Travel" or ("✨ " .. tostring(world.price))
                actionBtn.BackgroundColor3 = isUnlocked and Color3.fromRGB(80, 200, 120) or Config.COLORS.BUTTON_BG
            end
        end
    end
end

return WorldsPanel