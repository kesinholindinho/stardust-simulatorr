local InventoryPanel = {}

local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("StardustConfig"))
local PanelManager = require(ReplicatedStorage:WaitForChild("StardustUI"):WaitForChild("PanelManager"))
local NetworkClient = require(ReplicatedStorage:WaitForChild("StardustUI"):WaitForChild("NetworkClient"))

local panel = nil
local inventoryItems = {}

-- ============================================
-- CREATE PANEL
-- ============================================
function InventoryPanel.create(screenGui)
    panel = screenGui:FindFirstChild("InventoryPanel")
    if not panel then return end
    
    local COLORS = Config.COLORS
    local invClose = panel:FindFirstChild("CloseButton")
    
    local content = Instance.new("ScrollingFrame")
    content.Name = "Content"
    content.Size = UDim2.new(1, -32, 1, -60)
    content.Position = UDim2.new(0, 16, 0, 52)
    content.BackgroundColor3 = COLORS.MAIN_BG
    content.BorderSizePixel = 0
    content.ScrollBarThickness = 3
    content.ScrollBarImageColor3 = Color3.fromRGB(80, 80, 80)
    content.ClipsDescendants = true
    content.Parent = panel
    PanelManager.createCorner(content, 0.08)
    PanelManager.createStroke(content)
    
    local padding = Instance.new("UIPadding")
    padding.PaddingTop = UDim.new(0, 10)
    padding.PaddingBottom = UDim.new(0, 10)
    padding.PaddingLeft = UDim.new(0, 10)
    padding.PaddingRight = UDim.new(0, 10)
    padding.Parent = content
    
    local layout = Instance.new("UIGridLayout")
    layout.CellSize = UDim2.new(0, 100, 0, 120)
    layout.CellPadding = UDim2.new(0, 10, 0, 10)
    layout.FillDirection = Enum.FillDirection.Horizontal
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    layout.Parent = content
    
    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        content.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 20)
    end)
    
    -- Close button
    if invClose then
        invClose.MouseButton1Click:Connect(function()
            PanelManager.closeActivePanel()
        end)
    end
    
    PanelManager.registerPanel("InventoryPanel", panel)
end

-- ============================================
-- UPDATE INVENTORY
-- ============================================
function InventoryPanel.update(items)
    if not panel then return end
    
    inventoryItems = items or {}
    
    local content = panel:FindFirstChild("Content")
    if not content then return end
    
    -- Clear existing items
    for _, child in ipairs(content:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end
    
    local COLORS = Config.COLORS
    
    -- Create item cards
    for _, item in ipairs(inventoryItems) do
        local card = Instance.new("Frame")
        card.Name = item.name or "Item"
        card.BackgroundColor3 = COLORS.SECONDARY_BG
        card.BorderSizePixel = 0
        card.Parent = content
        PanelManager.createCorner(card, 0.1)
        PanelManager.createStroke(card)
        
        local itemEmoji = Instance.new("TextLabel")
        itemEmoji.Size = UDim2.new(1, 0, 0, 50)
        itemEmoji.Position = UDim2.new(0, 0, 0, 5)
        itemEmoji.BackgroundTransparency = 1
        itemEmoji.Text = item.emoji or "📦"
        itemEmoji.TextSize = 36
        itemEmoji.Font = Enum.Font.GothamBold
        itemEmoji.Parent = card
        
        local itemName = Instance.new("TextLabel")
        itemName.Size = UDim2.new(1, -8, 0, 20)
        itemName.Position = UDim2.new(0, 4, 0, 55)
        itemName.BackgroundTransparency = 1
        itemName.Text = item.name or "Item"
        itemName.TextColor3 = COLORS.TITLE_TEXT
        itemName.TextSize = 11
        itemName.Font = Enum.Font.GothamBold
        itemName.TextTruncate = Enum.TextTruncate.AtEnd
        itemName.Parent = card
        
        local itemValue = Instance.new("TextLabel")
        itemValue.Size = UDim2.new(1, -8, 0, 16)
        itemValue.Position = UDim2.new(0, 4, 0, 75)
        itemValue.BackgroundTransparency = 1
        itemValue.Text = "✨ " .. tostring(item.value or 0)
        itemValue.TextColor3 = COLORS.DESC_TEXT
        itemValue.TextSize = 10
        itemValue.Font = Enum.Font.GothamSemibold
        itemValue.Parent = card
        
        local useBtn = Instance.new("TextButton")
        useBtn.Size = UDim2.new(1, -8, 0, 24)
        useBtn.Position = UDim2.new(0, 4, 1, -28)
        useBtn.BackgroundColor3 = COLORS.BUTTON_BG
        useBtn.BorderSizePixel = 0
        useBtn.Text = "Use"
        useBtn.TextColor3 = COLORS.TITLE_TEXT
        useBtn.TextSize = 11
        useBtn.Font = Enum.Font.GothamBold
        useBtn.Parent = card
        PanelManager.createCorner(useBtn, 0.2)
        PanelManager.setupButtonEffects(useBtn)
        
        useBtn.MouseButton1Click:Connect(function()
            NetworkClient.useItem(item.name)
        end)
    end
end

return InventoryPanel