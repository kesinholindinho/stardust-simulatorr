local ShopPanel = {}

local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")

local Config = require(ReplicatedStorage:WaitForChild("StardustConfig"))
local PanelManager = require(ReplicatedStorage:WaitForChild("StardustUI"):WaitForChild("PanelManager"))

local panel = nil
local currentTab = 1
local tabButtons = {}
local contentFrame = nil
local gamepassOwnedCache = {}

-- Remote for game actions
local gameAction = ReplicatedStorage:WaitForChild("GameAction")

-- ============================================
-- CREATE PANEL
-- ============================================
function ShopPanel.create(screenGui)
    panel = screenGui:FindFirstChild("ShopPanel")
    if not panel then return end
    
    local shopClose = panel:FindFirstChild("CloseButton")
    
    -- Tabs
    local tabs = Instance.new("Frame")
    tabs.Name = "Tabs"
    tabs.Size = UDim2.new(1, -32, 0, 40)
    tabs.Position = UDim2.new(0, 16, 0, 52)
    tabs.BackgroundTransparency = 1
    tabs.Parent = panel
    
    local tabLayout = Instance.new("UIListLayout")
    tabLayout.FillDirection = Enum.FillDirection.Horizontal
    tabLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    tabLayout.Padding = UDim.new(0, 6)
    tabLayout.Parent = tabs
    
    local tabNames = {"🧪 Boosts", "📦 Items", "🐾 Pets", "🎫 Passes"}
    
    -- Content container (Frame, not ScrollingFrame - scrolling is per-tab)
    contentFrame = Instance.new("Frame")
    contentFrame.Name = "Content"
    contentFrame.Size = UDim2.new(1, -32, 1, -120)
    contentFrame.Position = UDim2.new(0, 16, 0, 100)
    contentFrame.BackgroundColor3 = Config.COLORS.MAIN_BG
    contentFrame.BorderSizePixel = 0
    contentFrame.ClipsDescendants = true
    contentFrame.Parent = panel
    PanelManager.createCorner(contentFrame, 0.08)
    PanelManager.createStroke(contentFrame)
    
    -- Function to clear content
    local function clearContent()
        for _, child in ipairs(contentFrame:GetChildren()) do
            child.Parent = nil
        end
    end
    
    -- Function to show Boosts tab (Category 1: Temporary Consumables)
    local function showBoostsTab()
        clearContent()
        
        local scroll = Instance.new("ScrollingFrame")
        scroll.Name = "BoostsScroll"
        scroll.Size = UDim2.new(1, 0, 1, 0)
        scroll.BackgroundTransparency = 1
        scroll.ScrollBarThickness = 3
        scroll.ScrollBarImageColor3 = Color3.fromRGB(80, 80, 80)
        scroll.Parent = contentFrame
        
        local padding = Instance.new("UIPadding")
        padding.PaddingTop = UDim.new(0, 10)
        padding.PaddingBottom = UDim.new(0, 10)
        padding.PaddingLeft = UDim.new(0, 10)
        padding.PaddingRight = UDim.new(0, 10)
        padding.Parent = scroll
        
        local grid = Instance.new("UIGridLayout")
        grid.CellSize = UDim2.new(0, 140, 0, 180)
        grid.CellPadding = UDim2.new(0, 10, 0, 10)
        grid.Parent = scroll
        
        grid:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            scroll.CanvasSize = UDim2.new(0, 0, 0, grid.AbsoluteContentSize.Y + 20)
        end)
        
        -- Boost items from Config
        local BOOST_ITEMS = Config.BOOST_ITEMS or {}
        
        for _, item in ipairs(BOOST_ITEMS) do
            local card = Instance.new("Frame")
            card.Name = item.name
            card.BackgroundColor3 = Config.COLORS.SECONDARY_BG
            card.BorderSizePixel = 0
            card.Parent = scroll
            PanelManager.createCorner(card, 0.1)
            PanelManager.createStroke(card, Color3.fromRGB(100, 200, 255), 1.5)
            
            local itemEmoji = Instance.new("TextLabel")
            itemEmoji.Size = UDim2.new(1, 0, 0, 45)
            itemEmoji.Position = UDim2.new(0, 0, 0, 6)
            itemEmoji.BackgroundTransparency = 1
            itemEmoji.Text = item.emoji
            itemEmoji.TextSize = 32
            itemEmoji.Font = Enum.Font.GothamBold
            itemEmoji.Parent = card
            
            local itemName = Instance.new("TextLabel")
            itemName.Size = UDim2.new(1, -12, 0, 18)
            itemName.Position = UDim2.new(0, 6, 0, 50)
            itemName.BackgroundTransparency = 1
            itemName.Text = item.name
            itemName.TextColor3 = Config.COLORS.TITLE_TEXT
            itemName.TextSize = 13
            itemName.Font = Enum.Font.GothamBold
            itemName.TextTruncate = Enum.TextTruncate.AtEnd
            itemName.Parent = card
            
            local itemDesc = Instance.new("TextLabel")
            itemDesc.Size = UDim2.new(1, -12, 0, 32)
            itemDesc.Position = UDim2.new(0, 6, 0, 68)
            itemDesc.BackgroundTransparency = 1
            itemDesc.Text = item.desc
            itemDesc.TextColor3 = Config.COLORS.DESC_TEXT
            itemDesc.TextSize = 10
            itemDesc.Font = Enum.Font.GothamSemibold
            itemDesc.TextWrapped = true
            itemDesc.Parent = card
            
            local itemPrice = Instance.new("TextLabel")
            itemPrice.Size = UDim2.new(1, -12, 0, 18)
            itemPrice.Position = UDim2.new(0, 6, 0, 102)
            itemPrice.BackgroundTransparency = 1
            itemPrice.Text = "✨ " .. tostring(item.price)
            itemPrice.TextColor3 = Color3.fromRGB(100, 200, 255)
            itemPrice.TextSize = 12
            itemPrice.Font = Enum.Font.GothamBold
            itemPrice.Parent = card
            
            local buyBtn = Instance.new("TextButton")
            buyBtn.Size = UDim2.new(1, -12, 0, 28)
            buyBtn.Position = UDim2.new(0, 6, 0, 124)
            buyBtn.BackgroundColor3 = Color3.fromRGB(50, 120, 150)
            buyBtn.BorderSizePixel = 0
            buyBtn.Text = "Activate"
            buyBtn.TextColor3 = Config.COLORS.TITLE_TEXT
            buyBtn.TextSize = 12
            buyBtn.Font = Enum.Font.GothamBold
            buyBtn.Parent = card
            PanelManager.createCorner(buyBtn, 0.25)
            PanelManager.setupButtonEffects(buyBtn)
            
            -- Connect buy button
            buyBtn.MouseButton1Click:Connect(function()
                gameAction:FireServer("buyBoostItem", item.name)
            end)
        end
    end
    
    -- Function to show Items tab (Category 2: Mission/Collection Items)
    local function showItemsTab()
        clearContent()
        
        local scroll = Instance.new("ScrollingFrame")
        scroll.Name = "ItemsScroll"
        scroll.Size = UDim2.new(1, 0, 1, 0)
        scroll.BackgroundTransparency = 1
        scroll.ScrollBarThickness = 3
        scroll.ScrollBarImageColor3 = Color3.fromRGB(80, 80, 80)
        scroll.Parent = contentFrame
        
        local padding = Instance.new("UIPadding")
        padding.PaddingTop = UDim.new(0, 10)
        padding.PaddingBottom = UDim.new(0, 10)
        padding.PaddingLeft = UDim.new(0, 10)
        padding.PaddingRight = UDim.new(0, 10)
        padding.Parent = scroll
        
        local grid = Instance.new("UIGridLayout")
        grid.CellSize = UDim2.new(0, 140, 0, 160)
        grid.CellPadding = UDim2.new(0, 10, 0, 10)
        grid.Parent = scroll
        
        grid:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            scroll.CanvasSize = UDim2.new(0, 0, 0, grid.AbsoluteContentSize.Y + 20)
        end)
        
        for _, item in ipairs(Config.SHOP_ITEMS) do
            local card = Instance.new("Frame")
            card.Name = item.name
            card.BackgroundColor3 = Config.COLORS.SECONDARY_BG
            card.BorderSizePixel = 0
            card.Parent = scroll
            PanelManager.createCorner(card, 0.1)
            PanelManager.createStroke(card)
            
            local itemEmoji = Instance.new("TextLabel")
            itemEmoji.Size = UDim2.new(1, 0, 0, 50)
            itemEmoji.Position = UDim2.new(0, 0, 0, 8)
            itemEmoji.BackgroundTransparency = 1
            itemEmoji.Text = item.emoji
            itemEmoji.TextSize = 36
            itemEmoji.Font = Enum.Font.GothamBold
            itemEmoji.Parent = card
            
            local itemName = Instance.new("TextLabel")
            itemName.Size = UDim2.new(1, -12, 0, 20)
            itemName.Position = UDim2.new(0, 6, 0, 58)
            itemName.BackgroundTransparency = 1
            itemName.Text = item.name
            itemName.TextColor3 = Config.COLORS.TITLE_TEXT
            itemName.TextSize = 14
            itemName.Font = Enum.Font.GothamBold
            itemName.TextTruncate = Enum.TextTruncate.AtEnd
            itemName.Parent = card
            
            local itemDesc = Instance.new("TextLabel")
            itemDesc.Size = UDim2.new(1, -12, 0, 24)
            itemDesc.Position = UDim2.new(0, 6, 0, 78)
            itemDesc.BackgroundTransparency = 1
            itemDesc.Text = item.desc
            itemDesc.TextColor3 = Config.COLORS.DESC_TEXT
            itemDesc.TextSize = 11
            itemDesc.Font = Enum.Font.GothamSemibold
            itemDesc.TextWrapped = true
            itemDesc.Parent = card
            
            local itemPrice = Instance.new("TextLabel")
            itemPrice.Size = UDim2.new(1, -12, 0, 18)
            itemPrice.Position = UDim2.new(0, 6, 0, 104)
            itemPrice.BackgroundTransparency = 1
            itemPrice.Text = "✨ " .. tostring(item.price)
            itemPrice.TextColor3 = Config.COLORS.TITLE_TEXT
            itemPrice.TextSize = 13
            itemPrice.Font = Enum.Font.GothamBold
            itemPrice.Parent = card
            
            local buyBtn = Instance.new("TextButton")
            buyBtn.Size = UDim2.new(1, -12, 0, 28)
            buyBtn.Position = UDim2.new(0, 6, 0, 126)
            buyBtn.BackgroundColor3 = Config.COLORS.BUTTON_BG
            buyBtn.BorderSizePixel = 0
            buyBtn.Text = "Buy"
            buyBtn.TextColor3 = Config.COLORS.TITLE_TEXT
            buyBtn.TextSize = 12
            buyBtn.Font = Enum.Font.GothamBold
            buyBtn.Parent = card
            PanelManager.createCorner(buyBtn, 0.25)
            PanelManager.setupButtonEffects(buyBtn)
            
            -- Connect buy button
            buyBtn.MouseButton1Click:Connect(function()
                gameAction:FireServer("buyShopItem", item.name)
            end)
        end
    end
    
    -- Function to show Pets tab
    local function showPetsTab()
        clearContent()
        
        local scroll = Instance.new("ScrollingFrame")
        scroll.Name = "PetsScroll"
        scroll.Size = UDim2.new(1, 0, 1, 0)
        scroll.BackgroundTransparency = 1
        scroll.ScrollBarThickness = 3
        scroll.ScrollBarImageColor3 = Color3.fromRGB(80, 80, 80)
        scroll.Parent = contentFrame
        
        local padding = Instance.new("UIPadding")
        padding.PaddingTop = UDim.new(0, 10)
        padding.PaddingBottom = UDim.new(0, 10)
        padding.PaddingLeft = UDim.new(0, 10)
        padding.PaddingRight = UDim.new(0, 10)
        padding.Parent = scroll
        
        local comingSoon = Instance.new("TextLabel")
        comingSoon.Size = UDim2.new(1, 0, 1, 0)
        comingSoon.BackgroundTransparency = 1
        comingSoon.Text = "🐾 Pets em breve!"
        comingSoon.TextColor3 = Config.COLORS.DESC_TEXT
        comingSoon.TextSize = 18
        comingSoon.Font = Enum.Font.GothamBold
        comingSoon.Parent = scroll
    end
    

    
    -- Function to show Gamepasses tab
    local function showGamepassesTab()
        clearContent()
        
        local player = Players.LocalPlayer
        if not player then return end
        
        local scroll = Instance.new("ScrollingFrame")
        scroll.Name = "GamepassesScroll"
        scroll.Size = UDim2.new(1, 0, 1, 0)
        scroll.BackgroundTransparency = 1
        scroll.ScrollBarThickness = 3
        scroll.ScrollBarImageColor3 = Color3.fromRGB(80, 80, 80)
        scroll.Parent = contentFrame
        
        local padding = Instance.new("UIPadding")
        padding.PaddingTop = UDim.new(0, 10)
        padding.PaddingBottom = UDim.new(0, 10)
        padding.PaddingLeft = UDim.new(0, 10)
        padding.PaddingRight = UDim.new(0, 10)
        padding.Parent = scroll
        
        local grid = Instance.new("UIGridLayout")
        grid.CellSize = UDim2.new(0, 140, 0, 160)
        grid.CellPadding = UDim2.new(0, 10, 0, 10)
        grid.Parent = scroll
        
        grid:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            scroll.CanvasSize = UDim2.new(0, 0, 0, grid.AbsoluteContentSize.Y + 20)
        end)
        
        for _, gp in ipairs(Config.GAMEPASS_ITEMS) do
            local card = Instance.new("Frame")
            card.Name = gp.name
            card.BackgroundColor3 = Config.COLORS.SECONDARY_BG
            card.BorderSizePixel = 0
            card.Parent = scroll
            PanelManager.createCorner(card, 0.1)
            PanelManager.createStroke(card, Color3.fromRGB(255, 200, 50), 1.5)
            
            local gpEmoji = Instance.new("TextLabel")
            gpEmoji.Size = UDim2.new(1, 0, 0, 50)
            gpEmoji.Position = UDim2.new(0, 0, 0, 8)
            gpEmoji.BackgroundTransparency = 1
            gpEmoji.Text = gp.emoji
            gpEmoji.TextSize = 36
            gpEmoji.Font = Enum.Font.GothamBold
            gpEmoji.Parent = card
            
            local gpName = Instance.new("TextLabel")
            gpName.Size = UDim2.new(1, -12, 0, 20)
            gpName.Position = UDim2.new(0, 6, 0, 58)
            gpName.BackgroundTransparency = 1
            gpName.Text = gp.name
            gpName.TextColor3 = Config.COLORS.TITLE_TEXT
            gpName.TextSize = 14
            gpName.Font = Enum.Font.GothamBold
            gpName.TextTruncate = Enum.TextTruncate.AtEnd
            gpName.Parent = card
            
            local gpDesc = Instance.new("TextLabel")
            gpDesc.Size = UDim2.new(1, -12, 0, 24)
            gpDesc.Position = UDim2.new(0, 6, 0, 78)
            gpDesc.BackgroundTransparency = 1
            gpDesc.Text = gp.desc
            gpDesc.TextColor3 = Config.COLORS.DESC_TEXT
            gpDesc.TextSize = 11
            gpDesc.Font = Enum.Font.GothamSemibold
            gpDesc.TextWrapped = true
            gpDesc.Parent = card
            
            local gpPrice = Instance.new("TextLabel")
            gpPrice.Size = UDim2.new(1, -12, 0, 18)
            gpPrice.Position = UDim2.new(0, 6, 0, 104)
            gpPrice.BackgroundTransparency = 1
            gpPrice.Text = "💎 Gamepass"
            gpPrice.TextColor3 = Color3.fromRGB(255, 200, 50)
            gpPrice.TextSize = 13
            gpPrice.Font = Enum.Font.GothamBold
            gpPrice.Parent = card
            
            local buyBtn = Instance.new("TextButton")
            buyBtn.Size = UDim2.new(1, -12, 0, 28)
            buyBtn.Position = UDim2.new(0, 6, 0, 126)
            buyBtn.BackgroundColor3 = Config.COLORS.BUTTON_BG
            buyBtn.BorderSizePixel = 0
            buyBtn.Text = "Carregando..."
            buyBtn.TextColor3 = Config.COLORS.TITLE_TEXT
            buyBtn.TextSize = 12
            buyBtn.Font = Enum.Font.GothamBold
            buyBtn.Parent = card
            PanelManager.createCorner(buyBtn, 0.25)
            PanelManager.setupButtonEffects(buyBtn)
            
            -- Check ownership asynchronously
            task.spawn(function()
                local success, owned = pcall(function()
                    return MarketplaceService:UserOwnsGamePassAsync(player.UserId, gp.id)
                end)
                
                if success and owned then
                    gamepassOwnedCache[gp.id] = true
                    buyBtn.Text = "✅ Owned"
                    buyBtn.BackgroundColor3 = Color3.fromRGB(40, 80, 40)
                    buyBtn.AutoButtonColor = false
                else
                    gamepassOwnedCache[gp.id] = false
                    -- Get price info
                    local priceSuccess, info = pcall(function()
                        return MarketplaceService:GetProductInfo(gp.id, Enum.InfoType.GamePass)
                    end)
                    if priceSuccess and info then
                        gpPrice.Text = "R$ " .. tostring(info.PriceInRobux or "?")
                    end
                    buyBtn.Text = "Buy"
                    buyBtn.BackgroundColor3 = Color3.fromRGB(50, 120, 50)
                    
                    buyBtn.MouseButton1Click:Connect(function()
                        MarketplaceService:PromptGamePassPurchase(player, gp.id)
                    end)
                end
            end)
        end
    end
    
    -- Tab switching functions
    local tabFunctions = {showBoostsTab, showItemsTab, showPetsTab, showGamepassesTab}
    
    for i, tabName in ipairs(tabNames) do
        local tabBtn = Instance.new("TextButton")
        tabBtn.Name = "Tab" .. i
        tabBtn.Size = UDim2.new(0, 110, 0, 34)
        tabBtn.AnchorPoint = Vector2.new(0.5, 0.5)
        tabBtn.BackgroundColor3 = i == 1 and Config.COLORS.BUTTON_BG or Config.COLORS.SECONDARY_BG
        tabBtn.BorderSizePixel = 0
        tabBtn.Text = tabName
        tabBtn.TextColor3 = Config.COLORS.TITLE_TEXT
        tabBtn.TextSize = 14
        tabBtn.Font = Enum.Font.GothamBold
        tabBtn.Parent = tabs
        PanelManager.createCorner(tabBtn, 0.2)
        PanelManager.createStroke(tabBtn, i == 1 and Color3.fromRGB(150, 150, 150) or Color3.fromRGB(60, 60, 60), 1.5)
        PanelManager.setupButtonEffects(tabBtn)
        table.insert(tabButtons, tabBtn)
        
        tabBtn.MouseButton1Click:Connect(function()
            currentTab = i
            for j, btn in ipairs(tabButtons) do
                btn.BackgroundColor3 = j == i and Config.COLORS.BUTTON_BG or Config.COLORS.SECONDARY_BG
                local btnStroke = btn:FindFirstChildOfClass("UIStroke")
                if btnStroke then
                    btnStroke.Color = j == i and Color3.fromRGB(150, 150, 150) or Color3.fromRGB(60, 60, 60)
                end
            end
            -- Switch content
            if tabFunctions[i] then
                tabFunctions[i]()
            end
        end)
    end
    
    -- Show default tab (Boosts)
    showBoostsTab()
    

    
    -- Close button
    if shopClose then
        shopClose.MouseButton1Click:Connect(function()
            PanelManager.closeActivePanel()
        end)
    end
    
    -- Listen for gamepass purchases to update the UI
    MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(plr, gamePassId, purchased)
        if purchased and gamepassOwnedCache[gamePassId] == false then
            gamepassOwnedCache[gamePassId] = true
            -- Refresh gamepasses tab if it's active
            if currentTab == 4 then
                showGamepassesTab()
            end
        end
    end)
    
    PanelManager.registerPanel("ShopPanel", panel)
end

return ShopPanel