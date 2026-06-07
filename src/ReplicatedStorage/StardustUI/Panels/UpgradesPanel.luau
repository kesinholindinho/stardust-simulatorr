local UpgradesPanel = {}

local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("StardustConfig"))
local PanelManager = require(ReplicatedStorage:WaitForChild("StardustUI"):WaitForChild("PanelManager"))
local NetworkClient = require(ReplicatedStorage:WaitForChild("StardustUI"):WaitForChild("NetworkClient"))

local panel = nil
local upgradeLevels = {}

local UPGRADES = {
    {emoji = "👆", name = "Click Power", maxLevel = 5, desc = "+5% Stardust per click", price = 1200},
    {emoji = "⚡", name = "Super Click", maxLevel = 3, desc = "+10% chance for double stardust", price = 2500},
    {emoji = "💫", name = "Star Burst", maxLevel = 1, desc = "+15% Stardust from stars", price = 5000},
    {emoji = "🌟", name = "Constellation Bonus", maxLevel = 0, desc = "+20% XP from all sources", price = 8000},
    {emoji = "🌙", name = "Moon Power", maxLevel = 2, desc = "+8% Stardust at night", price = 3500}
}

-- ============================================
-- CREATE PANEL
-- ============================================
function UpgradesPanel.create(screenGui)
    panel = screenGui:FindFirstChild("UpgradesPanel")
    if not panel then return end
    
    local COLORS = Config.COLORS
    
    local upgradesClose = panel:FindFirstChild("CloseButton")
    
    -- Tabs
    local upgradesTabs = Instance.new("Frame")
    upgradesTabs.Name = "Tabs"
    upgradesTabs.Size = UDim2.new(1, -32, 0, 40)
    upgradesTabs.Position = UDim2.new(0, 16, 0, 52)
    upgradesTabs.BackgroundTransparency = 1
    upgradesTabs.Parent = panel
    
    local upgradesTabLayout = Instance.new("UIListLayout")
    upgradesTabLayout.FillDirection = Enum.FillDirection.Horizontal
    upgradesTabLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    upgradesTabLayout.Padding = UDim.new(0, 6)
    upgradesTabLayout.Parent = upgradesTabs
    
    local upgradesTabNames = {"⚡ Click", "🌀 Auto", "✨ Multiplier"}
    local currentUpgradesTab = 1
    local upgradesTabButtons = {}
    
    for i, tabName in ipairs(upgradesTabNames) do
        local tabBtn = Instance.new("TextButton")
        tabBtn.Name = "Tab" .. i
        tabBtn.Size = UDim2.new(0, 110, 0, 34)
        tabBtn.AnchorPoint = Vector2.new(0.5, 0.5)
        tabBtn.BackgroundColor3 = i == 1 and COLORS.BUTTON_BG or COLORS.SECONDARY_BG
        tabBtn.BorderSizePixel = 0
        tabBtn.Text = tabName
        tabBtn.TextColor3 = COLORS.TITLE_TEXT
        tabBtn.TextSize = 14
        tabBtn.Font = Enum.Font.GothamBold
        tabBtn.Parent = upgradesTabs
        PanelManager.createCorner(tabBtn, 0.2)
        PanelManager.createStroke(tabBtn, i == 1 and Color3.fromRGB(150, 150, 150) or Color3.fromRGB(60, 60, 60), 1.5)
        PanelManager.setupButtonEffects(tabBtn)
        table.insert(upgradesTabButtons, tabBtn)
        
        tabBtn.MouseButton1Click:Connect(function()
            currentUpgradesTab = i
            for j, btn in ipairs(upgradesTabButtons) do
                btn.BackgroundColor3 = j == i and COLORS.BUTTON_BG or COLORS.SECONDARY_BG
                local btnStroke = btn:FindFirstChildOfClass("UIStroke")
                if btnStroke then
                    btnStroke.Color = j == i and Color3.fromRGB(150, 150, 150) or Color3.fromRGB(60, 60, 60)
                end
            end
        end)
    end
    
    -- Content
    local upgradesContent = Instance.new("ScrollingFrame")
    upgradesContent.Name = "Content"
    upgradesContent.Size = UDim2.new(1, -32, 1, -120)
    upgradesContent.Position = UDim2.new(0, 16, 0, 100)
    upgradesContent.BackgroundColor3 = COLORS.MAIN_BG
    upgradesContent.BorderSizePixel = 0
    upgradesContent.ScrollBarThickness = 3
    upgradesContent.ScrollBarImageColor3 = Color3.fromRGB(80, 80, 80)
    upgradesContent.ClipsDescendants = true
    upgradesContent.Parent = panel
    PanelManager.createCorner(upgradesContent, 0.08)
    PanelManager.createStroke(upgradesContent)
    
    local upgradesPadding = Instance.new("UIPadding")
    upgradesPadding.PaddingTop = UDim.new(0, 10)
    upgradesPadding.PaddingBottom = UDim.new(0, 10)
    upgradesPadding.PaddingLeft = UDim.new(0, 10)
    upgradesPadding.PaddingRight = UDim.new(0, 10)
    upgradesPadding.Parent = upgradesContent
    
    local upgradesList = Instance.new("UIListLayout")
    upgradesList.Padding = UDim.new(0, 10)
    upgradesList.Parent = upgradesContent
    
    upgradesList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        upgradesContent.CanvasSize = UDim2.new(0, 0, 0, upgradesList.AbsoluteContentSize.Y + 20)
    end)
    
    -- Create upgrade rows
    for _, upgrade in ipairs(UPGRADES) do
        local row = Instance.new("Frame")
        row.Name = upgrade.name
        row.Size = UDim2.new(1, 0, 0, 70)
        row.BackgroundColor3 = COLORS.SECONDARY_BG
        row.BorderSizePixel = 0
        row.Parent = upgradesContent
        PanelManager.createCorner(row, 0.1)
        PanelManager.createStroke(row)
        
        local upgradeEmoji = Instance.new("TextLabel")
        upgradeEmoji.Size = UDim2.new(0, 50, 1, 0)
        upgradeEmoji.BackgroundTransparency = 1
        upgradeEmoji.Text = upgrade.emoji
        upgradeEmoji.TextSize = 28
        upgradeEmoji.Font = Enum.Font.GothamBold
        upgradeEmoji.Parent = row
        
        local upgradeName = Instance.new("TextLabel")
        upgradeName.Size = UDim2.new(0, 150, 0, 24)
        upgradeName.Position = UDim2.new(0, 50, 0, 8)
        upgradeName.BackgroundTransparency = 1
        upgradeName.Text = upgrade.name
        upgradeName.TextColor3 = COLORS.TITLE_TEXT
        upgradeName.TextSize = 16
        upgradeName.Font = Enum.Font.GothamBold
        upgradeName.TextXAlignment = Enum.TextXAlignment.Left
        upgradeName.Parent = row
        
        local levelPill = Instance.new("Frame")
        levelPill.Size = UDim2.new(0, 50, 0, 20)
        levelPill.Position = UDim2.new(0, 50, 0, 32)
        levelPill.BackgroundColor3 = COLORS.MAIN_BG
        levelPill.BorderSizePixel = 0
        levelPill.Parent = row
        PanelManager.createCorner(levelPill, 0.5)
        PanelManager.createStroke(levelPill)
        
        local levelText = Instance.new("TextLabel")
        levelText.Name = "LevelText"
        levelText.Size = UDim2.new(1, 0, 1, 0)
        levelText.BackgroundTransparency = 1
        levelText.Text = "Lv. 0"
        levelText.TextColor3 = COLORS.DESC_TEXT
        levelText.TextSize = 11
        levelText.Font = Enum.Font.GothamSemibold
        levelText.Parent = levelPill
        
        local upgradeDesc = Instance.new("TextLabel")
        upgradeDesc.Size = UDim2.new(0, 200, 0, 18)
        upgradeDesc.Position = UDim2.new(0, 105, 0, 34)
        upgradeDesc.BackgroundTransparency = 1
        upgradeDesc.Text = upgrade.desc
        upgradeDesc.TextColor3 = COLORS.DESC_TEXT
        upgradeDesc.TextSize = 12
        upgradeDesc.Font = Enum.Font.GothamSemibold
        upgradeDesc.TextXAlignment = Enum.TextXAlignment.Left
        upgradeDesc.Parent = row
        
        local priceLabel = Instance.new("TextLabel")
        priceLabel.Size = UDim2.new(0, 80, 0, 24)
        priceLabel.Position = UDim2.new(1, -180, 0, 23)
        priceLabel.BackgroundTransparency = 1
        priceLabel.Text = "✨ " .. tostring(upgrade.price)
        priceLabel.TextColor3 = COLORS.TITLE_TEXT
        priceLabel.TextSize = 14
        priceLabel.Font = Enum.Font.GothamBold
        priceLabel.Parent = row
        
        local upgradeBtn = Instance.new("TextButton")
        upgradeBtn.Size = UDim2.new(0, 90, 0, 36)
        upgradeBtn.Position = UDim2.new(1, -100, 0, 17)
        upgradeBtn.BackgroundColor3 = COLORS.BUTTON_BG
        upgradeBtn.BorderSizePixel = 0
        upgradeBtn.Text = "Upgrade"
        upgradeBtn.TextColor3 = COLORS.TITLE_TEXT
        upgradeBtn.TextSize = 13
        upgradeBtn.Font = Enum.Font.GothamBold
        upgradeBtn.Parent = row
        PanelManager.createCorner(upgradeBtn, 0.2)
        PanelManager.setupButtonEffects(upgradeBtn)
        
        upgradeBtn.MouseButton1Click:Connect(function()
            NetworkClient.buyUpgrade(upgrade.name)
        end)
    end
    
    -- Close button
    if upgradesClose then
        upgradesClose.MouseButton1Click:Connect(function()
            PanelManager.closeActivePanel()
        end)
    end
    
    PanelManager.registerPanel("UpgradesPanel", panel)
end

-- ============================================
-- UPDATE LEVELS
-- ============================================
function UpgradesPanel.updateLevels(upgradeData)
    if not upgradeData then return end
    
    for name, level in pairs(upgradeData) do
        upgradeLevels[name] = level
    end
    
    if not panel then return end
    
    local content = panel:FindFirstChild("Content")
    if not content then return end
    
    for _, upgrade in ipairs(UPGRADES) do
        local row = content:FindFirstChild(upgrade.name)
        if row then
            local levelPill = row:FindFirstChildWhichIsA("Frame", true)
            if levelPill then
                local levelText = levelPill:FindFirstChild("LevelText")
                if levelText then
                    levelText.Text = "Lv. " .. tostring(upgradeLevels[upgrade.name] or 0)
                end
            end
        end
    end
end

return UpgradesPanel