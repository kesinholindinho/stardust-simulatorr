-- SupernovaPanel - Minimalist Black & White Design
-- Shows Supernova status, progress, confirmation, and token shop

local SupernovaPanel = {}

local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("StardustConfig"))
local PanelManager = require(ReplicatedStorage:WaitForChild("StardustUI"):WaitForChild("PanelManager"))
local NetworkClient = require(ReplicatedStorage:WaitForChild("StardustUI"):WaitForChild("NetworkClient"))

local panel = nil
local screenGui = nil
local currentSupernovaData = nil
local currentPermanentUpgrades = nil
local currentSelectedTitle = nil
local currentOwnedTitles = nil

-- SUPERNOVA REQUIREMENTS - Uses centralized ECONOMY config
local REQUIRED_TOTAL_STARDUST = Config.ECONOMY.SUPERNOVA_REQUIREMENT

-- ============================================
-- DESIGN CONSTANTS
-- ============================================
local BG_DARK = Color3.fromRGB(10, 10, 10)
local BG_PANEL = Color3.fromRGB(16, 16, 16)
local BG_CARD = Color3.fromRGB(22, 22, 22)
local BG_INPUT = Color3.fromRGB(30, 30, 30)
local BORDER_WHITE = Color3.fromRGB(255, 255, 255)
local BORDER_GRAY = Color3.fromRGB(80, 80, 80)
local TEXT_WHITE = Color3.fromRGB(255, 255, 255)
local TEXT_GRAY = Color3.fromRGB(120, 120, 120)
local TEXT_DIM = Color3.fromRGB(80, 80, 80)
local BTN_DARK = Color3.fromRGB(25, 25, 25)

-- ============================================
-- CREATE CORNER/STROKE HELPERS
-- ============================================
local function createCorner(parent, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius or 8)
    corner.Parent = parent
    return corner
end

local function createStroke(parent, color, thickness)
    local stroke = Instance.new("UIStroke")
    stroke.Color = color or BORDER_GRAY
    stroke.Thickness = thickness or 1
    stroke.Parent = parent
    return stroke
end

-- ============================================
-- CREATE TAB BUTTON
-- ============================================
local function createTabButton(parent, name, text, position, isActive)
    local btn = Instance.new("TextButton")
    btn.Name = name
    btn.Size = UDim2.new(0.5, -4, 0, 30)
    btn.Position = position
    btn.BackgroundColor3 = isActive and TEXT_WHITE or BTN_DARK
    btn.BorderSizePixel = 0
    btn.Text = text
    btn.TextColor3 = isActive and BG_DARK or TEXT_WHITE
    btn.TextSize = 11
    btn.Font = Enum.Font.GothamBold
    btn.Parent = parent
    createCorner(btn, 8)
    if not isActive then
        createStroke(btn, BORDER_GRAY, 1)
    end
    return btn
end

-- ============================================
-- CREATE PANEL
-- ============================================
function SupernovaPanel.create(gui)
    screenGui = gui
    panel = screenGui:FindFirstChild("SupernovaPanel")
    if not panel then return end
    
    local superClose = panel:FindFirstChild("CloseButton")
    
    -- Clear existing children (except CloseButton and TitleLabel)
    for _, child in ipairs(panel:GetChildren()) do
        if child.Name ~= "CloseButton" and child.Name ~= "TitleLabel" then
            child:Destroy()
        end
    end
    
    -- Style the panel itself
    panel.BackgroundColor3 = BG_PANEL
    createStroke(panel, BORDER_WHITE, 1)
    
    -- Style the title label if it exists
    local titleLabel = panel:FindFirstChild("TitleLabel")
    if titleLabel then
        titleLabel.TextColor3 = TEXT_WHITE
        titleLabel.Font = Enum.Font.GothamBold
    end
    
    -- Panel padding
    local padding = Instance.new("UIPadding")
    padding.PaddingTop = UDim.new(0, 20)
    padding.PaddingBottom = UDim.new(0, 20)
    padding.PaddingLeft = UDim.new(0, 24)
    padding.PaddingRight = UDim.new(0, 24)
    padding.Parent = panel

    -- Main container
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(1, -48, 1, -80)
    mainFrame.Position = UDim2.new(0, 24, 0, 60)
    mainFrame.BackgroundTransparency = 1
    mainFrame.Parent = panel
    
    -- === TAB BUTTONS ===
    local tabsFrame = Instance.new("Frame")
    tabsFrame.Name = "TabsFrame"
    tabsFrame.Size = UDim2.new(1, 0, 0, 34)
    tabsFrame.Position = UDim2.new(0, 0, 0, 0)
    tabsFrame.BackgroundTransparency = 1
    tabsFrame.Parent = mainFrame
    
    local supernovaTab = createTabButton(tabsFrame, "SupernovaTab", "SUPERNOVA", UDim2.new(0, 0, 0, 0), true)
    local shopTab = createTabButton(tabsFrame, "ShopTab", "TOKEN SHOP", UDim2.new(0.5, 4, 0, 0), false)
    
    -- === CONTENT FRAMES ===
    local supernovaContent = Instance.new("ScrollingFrame")
    supernovaContent.Name = "SupernovaContent"
    supernovaContent.Size = UDim2.new(1, 0, 1, -35)
    supernovaContent.Position = UDim2.new(0, 0, 0, 35)
    supernovaContent.BackgroundTransparency = 1
    supernovaContent.ScrollBarThickness = 4
    supernovaContent.ScrollBarImageColor3 = TEXT_GRAY
    supernovaContent.CanvasSize = UDim2.new(0, 0, 0, 350)
    supernovaContent.Parent = mainFrame
    
    local supernovaPadding = Instance.new("UIPadding")
    supernovaPadding.PaddingLeft = UDim.new(0, 4)
    supernovaPadding.PaddingRight = UDim.new(0, 4)
    supernovaPadding.Parent = supernovaContent
    
    local shopContent = Instance.new("ScrollingFrame")
    shopContent.Name = "ShopContent"
    shopContent.Size = UDim2.new(1, 0, 1, -35)
    shopContent.Position = UDim2.new(0, 0, 0, 35)
    shopContent.BackgroundTransparency = 1
    shopContent.ScrollBarThickness = 4
    shopContent.ScrollBarImageColor3 = TEXT_GRAY
    shopContent.CanvasSize = UDim2.new(0, 0, 0, 1200)
    shopContent.Visible = false
    shopContent.Parent = mainFrame
    
    local shopPadding = Instance.new("UIPadding")
    shopPadding.PaddingLeft = UDim.new(0, 4)
    shopPadding.PaddingRight = UDim.new(0, 4)
    shopPadding.Parent = shopContent
    
    -- Tab switching logic
    supernovaTab.MouseButton1Click:Connect(function()
        supernovaTab.BackgroundColor3 = TEXT_WHITE
        supernovaTab.TextColor3 = BG_DARK
        local s = supernovaTab:FindFirstChildOfClass("UIStroke")
        if s then s:Destroy() end
        
        shopTab.BackgroundColor3 = BTN_DARK
        shopTab.TextColor3 = TEXT_WHITE
        local ss = shopTab:FindFirstChildOfClass("UIStroke")
        if not ss then createStroke(shopTab, BORDER_GRAY, 1) end
        
        supernovaContent.Visible = true
        shopContent.Visible = false
    end)
    
    shopTab.MouseButton1Click:Connect(function()
        shopTab.BackgroundColor3 = TEXT_WHITE
        shopTab.TextColor3 = BG_DARK
        local s = shopTab:FindFirstChildOfClass("UIStroke")
        if s then s:Destroy() end
        
        supernovaTab.BackgroundColor3 = BTN_DARK
        supernovaTab.TextColor3 = TEXT_WHITE
        local ss = supernovaTab:FindFirstChildOfClass("UIStroke")
        if not ss then createStroke(supernovaTab, BORDER_GRAY, 1) end
        
        shopContent.Visible = true
        supernovaContent.Visible = false
    end)
    
    -- === SUPERNOVA CONTENT ===
    SupernovaPanel.createSupernovaContent(supernovaContent)
    
    -- === TOKEN SHOP CONTENT ===
    SupernovaPanel.createShopContent(shopContent)
    
    -- Close button
    if superClose then
        superClose.MouseButton1Click:Connect(function()
            PanelManager.closeActivePanel()
        end)
    end
    
    PanelManager.registerPanel("SupernovaPanel", panel)
end

-- ============================================
-- CREATE SUPERNOVA CONTENT
-- ============================================
function SupernovaPanel.createSupernovaContent(container)
    -- Title
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "SupernovaTitle"
    titleLabel.Size = UDim2.new(1, 0, 0, 24)
    titleLabel.Position = UDim2.new(0, 0, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "SUPERNOVA"
    titleLabel.TextColor3 = TEXT_WHITE
    titleLabel.TextSize = 16
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Parent = container
    
    -- === PROGRESS SECTION ===
    local progressFrame = Instance.new("Frame")
    progressFrame.Name = "ProgressFrame"
    progressFrame.Size = UDim2.new(1, 0, 0, 70)
    progressFrame.Position = UDim2.new(0, 0, 0, 35)
    progressFrame.BackgroundColor3 = BG_CARD
    progressFrame.BorderSizePixel = 0
    progressFrame.Parent = container
    createCorner(progressFrame, 8)
    createStroke(progressFrame, BORDER_GRAY, 1)
    
    -- Progress bar background
    local progressBg = Instance.new("Frame")
    progressBg.Name = "ProgressBg"
    progressBg.Size = UDim2.new(1, -16, 0, 22)
    progressBg.Position = UDim2.new(0, 8, 0, 8)
    progressBg.BackgroundColor3 = BG_INPUT
    progressBg.BorderSizePixel = 0
    progressBg.Parent = progressFrame
    createCorner(progressBg, 6)
    
    -- Progress bar fill
    local progressFill = Instance.new("Frame")
    progressFill.Name = "ProgressFill"
    progressFill.Size = UDim2.new(0, 0, 1, 0)
    progressFill.Position = UDim2.new(0, 0, 0, 0)
    progressFill.BackgroundColor3 = TEXT_WHITE
    progressFill.BorderSizePixel = 0
    progressFill.Parent = progressBg
    createCorner(progressFill, 6)
    
    -- Progress text
    local progressText = Instance.new("TextLabel")
    progressText.Name = "ProgressText"
    progressText.Size = UDim2.new(1, -16, 0, 16)
    progressText.Position = UDim2.new(0, 8, 0, 34)
    progressText.BackgroundTransparency = 1
    progressText.Text = "0 / " .. Config.abbreviateNumber(Config.ECONOMY.SUPERNOVA_REQUIREMENT) .. " Total Stardust"
    progressText.TextColor3 = TEXT_GRAY
    progressText.TextSize = 10
    progressText.Font = Enum.Font.GothamBold
    progressText.TextXAlignment = Enum.TextXAlignment.Left
    progressText.ZIndex = 10
    progressText.Parent = progressFrame
    
    -- Percentage label
    local percentLabel = Instance.new("TextLabel")
    percentLabel.Name = "PercentLabel"
    percentLabel.Size = UDim2.new(0, 50, 0, 16)
    percentLabel.Position = UDim2.new(1, -58, 0, 52)
    percentLabel.BackgroundTransparency = 1
    percentLabel.Text = "0%"
    percentLabel.TextColor3 = TEXT_GRAY
    percentLabel.TextSize = 10
    percentLabel.Font = Enum.Font.GothamBold
    percentLabel.TextXAlignment = Enum.TextXAlignment.Right
    percentLabel.Parent = progressFrame
    
    -- === STATS SECTION ===
    local statsFrame = Instance.new("Frame")
    statsFrame.Name = "StatsFrame"
    statsFrame.Size = UDim2.new(1, 0, 0, 85)
    statsFrame.Position = UDim2.new(0, 0, 0, 110)
    statsFrame.BackgroundColor3 = BG_CARD
    statsFrame.BorderSizePixel = 0
    statsFrame.Parent = container
    createCorner(statsFrame, 8)
    createStroke(statsFrame, BORDER_GRAY, 1)
    
    -- Supernova count
    local countLabel = Instance.new("TextLabel")
    countLabel.Name = "CountLabel"
    countLabel.Size = UDim2.new(0.5, -5, 0, 22)
    countLabel.Position = UDim2.new(0, 10, 0, 8)
    countLabel.BackgroundTransparency = 1
    countLabel.Text = "Supernovas: 0"
    countLabel.TextColor3 = TEXT_GRAY
    countLabel.TextSize = 12
    countLabel.Font = Enum.Font.GothamBold
    countLabel.TextXAlignment = Enum.TextXAlignment.Left
    countLabel.Parent = statsFrame
    
    -- Tokens
    local tokensLabel = Instance.new("TextLabel")
    tokensLabel.Name = "TokensLabel"
    tokensLabel.Size = UDim2.new(0.5, 0, 0, 22)
    tokensLabel.Position = UDim2.new(0.5, 0, 0, 8)
    tokensLabel.BackgroundTransparency = 1
    tokensLabel.Text = "Tokens: 0"
    tokensLabel.TextColor3 = TEXT_GRAY
    tokensLabel.TextSize = 12
    tokensLabel.Font = Enum.Font.GothamBold
    tokensLabel.TextXAlignment = Enum.TextXAlignment.Left
    tokensLabel.Parent = statsFrame
    
    -- Current multiplier
    local multLabel = Instance.new("TextLabel")
    multLabel.Name = "MultiplierLabel"
    multLabel.Size = UDim2.new(1, -20, 0, 24)
    multLabel.Position = UDim2.new(0, 10, 0, 34)
    multLabel.BackgroundTransparency = 1
    multLabel.Text = "Current Multiplier: x1.0"
    multLabel.TextColor3 = TEXT_WHITE
    multLabel.TextSize = 15
    multLabel.Font = Enum.Font.GothamBold
    multLabel.TextXAlignment = Enum.TextXAlignment.Left
    multLabel.Parent = statsFrame
    
    -- Tokens to earn preview
    local tokensPreview = Instance.new("TextLabel")
    tokensPreview.Name = "TokensPreview"
    tokensPreview.Size = UDim2.new(1, -20, 0, 18)
    tokensPreview.Position = UDim2.new(0, 10, 0, 60)
    tokensPreview.BackgroundTransparency = 1
    tokensPreview.Text = "Tokens to earn: 0"
    tokensPreview.TextColor3 = TEXT_GRAY
    tokensPreview.TextSize = 11
    tokensPreview.Font = Enum.Font.GothamBold
    tokensPreview.TextXAlignment = Enum.TextXAlignment.Left
    tokensPreview.Parent = statsFrame
    
    -- === SEPARATOR ===
    local separator = Instance.new("Frame")
    separator.Name = "Separator"
    separator.Size = UDim2.new(1, 0, 0, 1)
    separator.Position = UDim2.new(0, 0, 1, -56)
    separator.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    separator.BorderSizePixel = 0
    separator.Parent = container

    -- === GO SUPERNOVA BUTTON ===
    local goBtn = Instance.new("TextButton")
    goBtn.Name = "GoSupernovaBtn"
    goBtn.Size = UDim2.new(1, 0, 0, 40)
    goBtn.Position = UDim2.new(0, 0, 1, -48)
    goBtn.BackgroundColor3 = TEXT_WHITE
    goBtn.BorderSizePixel = 0
    goBtn.Text = "GO SUPERNOVA"
    goBtn.TextColor3 = BG_DARK
    goBtn.TextSize = 14
    goBtn.Font = Enum.Font.GothamBold
    goBtn.Parent = container
    createCorner(goBtn, 8)
    
    -- Button hover effect
    goBtn.MouseEnter:Connect(function()
        TweenService:Create(goBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(230, 230, 230)}):Play()
    end)
    goBtn.MouseLeave:Connect(function()
        TweenService:Create(goBtn, TweenInfo.new(0.2), {BackgroundColor3 = TEXT_WHITE}):Play()
    end)
    
    goBtn.MouseButton1Click:Connect(function()
        SupernovaPanel.showConfirmation()
    end)
end
    
-- ============================================
-- CREATE SHOP CONTENT
-- ============================================
function SupernovaPanel.createShopContent(container)
    local yPos = 0
    
    -- === TOKEN BALANCE ===
    local balanceFrame = Instance.new("Frame")
    balanceFrame.Name = "BalanceFrame"
    balanceFrame.Size = UDim2.new(1, 0, 0, 40)
    balanceFrame.Position = UDim2.new(0, 0, 0, yPos)
    balanceFrame.BackgroundColor3 = BG_CARD
    balanceFrame.BorderSizePixel = 0
    balanceFrame.Parent = container
    createCorner(balanceFrame, 8)
    createStroke(balanceFrame, BORDER_GRAY, 1)
    
    local balanceLabel = Instance.new("TextLabel")
    balanceLabel.Name = "BalanceLabel"
    balanceLabel.Size = UDim2.new(1, -20, 1, 0)
    balanceLabel.Position = UDim2.new(0, 12, 0, 0)
    balanceLabel.BackgroundTransparency = 1
    balanceLabel.Text = "Your Tokens: 0"
    balanceLabel.TextColor3 = TEXT_WHITE
    balanceLabel.TextSize = 14
    balanceLabel.Font = Enum.Font.GothamBold
    balanceLabel.TextXAlignment = Enum.TextXAlignment.Left
    balanceLabel.Parent = balanceFrame
    
    yPos = yPos + 48
    
    -- === EXCLUSIVE PETS SECTION ===
    local petsTitle = Instance.new("TextLabel")
    petsTitle.Name = "PetsTitle"
    petsTitle.Size = UDim2.new(1, 0, 0, 24)
    petsTitle.Position = UDim2.new(0, 0, 0, yPos)
    petsTitle.BackgroundTransparency = 1
    petsTitle.Text = "EXCLUSIVE SUPERNOVA PETS"
    petsTitle.TextColor3 = TEXT_WHITE
    petsTitle.TextSize = 13
    petsTitle.Font = Enum.Font.GothamBold
    petsTitle.TextXAlignment = Enum.TextXAlignment.Left
    petsTitle.Parent = container
    yPos = yPos + 28
    
    -- Pet items
    for _, pet in ipairs(Config.SUPERNOVA_PETS) do
        local petFrame = Instance.new("Frame")
        petFrame.Name = "Pet_" .. pet.id
        petFrame.Size = UDim2.new(1, 0, 0, 55)
        petFrame.Position = UDim2.new(0, 0, 0, yPos)
        petFrame.BackgroundColor3 = BG_CARD
        petFrame.BorderSizePixel = 0
        petFrame.Parent = container
        createCorner(petFrame, 8)
        createStroke(petFrame, BORDER_WHITE, 1)
        
        -- Pet info
        local petInfo = Instance.new("TextLabel")
        petInfo.Size = UDim2.new(0.6, 0, 1, 0)
        petInfo.Position = UDim2.new(0, 12, 0, 0)
        petInfo.BackgroundTransparency = 1
        petInfo.Text = pet.name .. "\n" .. pet.desc .. "\nx" .. pet.multiplier .. " multiplier"
        petInfo.TextColor3 = TEXT_WHITE
        petInfo.TextSize = 11
        petInfo.Font = Enum.Font.GothamBold
        petInfo.TextXAlignment = Enum.TextXAlignment.Left
        petInfo.TextYAlignment = Enum.TextYAlignment.Center
        petInfo.Parent = petFrame
        
        -- Buy button
        local buyBtn = Instance.new("TextButton")
        buyBtn.Name = "BuyBtn"
        buyBtn.Size = UDim2.new(0, 70, 0, 30)
        buyBtn.Position = UDim2.new(1, -80, 0.5, -15)
        buyBtn.BackgroundColor3 = TEXT_WHITE
        buyBtn.BorderSizePixel = 0
        buyBtn.Text = tostring(pet.price)
        buyBtn.TextColor3 = BG_DARK
        buyBtn.TextSize = 13
        buyBtn.Font = Enum.Font.GothamBold
        buyBtn.Parent = petFrame
        createCorner(buyBtn, 6)
        
        buyBtn.MouseButton1Click:Connect(function()
            NetworkClient.fire("buySupernovaPet", pet.id)
        end)
        
        yPos = yPos + 54
    end
    
    yPos = yPos + 10
    
    -- === PERMANENT UPGRADES SECTION ===
    local upgradesTitle = Instance.new("TextLabel")
    upgradesTitle.Name = "UpgradesTitle"
    upgradesTitle.Size = UDim2.new(1, 0, 0, 24)
    upgradesTitle.Position = UDim2.new(0, 0, 0, yPos)
    upgradesTitle.BackgroundTransparency = 1
    upgradesTitle.Text = "PERMANENT UPGRADES"
    upgradesTitle.TextColor3 = TEXT_WHITE
    upgradesTitle.TextSize = 13
    upgradesTitle.Font = Enum.Font.GothamBold
    upgradesTitle.TextXAlignment = Enum.TextXAlignment.Left
    upgradesTitle.Parent = container
    yPos = yPos + 28
    
    -- Upgrade items
    for _, upgrade in ipairs(Config.PERMANENT_UPGRADES) do
        local upgradeFrame = Instance.new("Frame")
        upgradeFrame.Name = "Upgrade_" .. upgrade.id
        upgradeFrame.Size = UDim2.new(1, 0, 0, 48)
        upgradeFrame.Position = UDim2.new(0, 0, 0, yPos)
        upgradeFrame.BackgroundColor3 = BG_CARD
        upgradeFrame.BorderSizePixel = 0
        upgradeFrame.Parent = container
        createCorner(upgradeFrame, 8)
        createStroke(upgradeFrame, BORDER_WHITE, 1)
        
        -- Upgrade info
        local upgradeInfo = Instance.new("TextLabel")
        upgradeInfo.Size = UDim2.new(0.6, 0, 1, 0)
        upgradeInfo.Position = UDim2.new(0, 12, 0, 0)
        upgradeInfo.BackgroundTransparency = 1
        upgradeInfo.Text = upgrade.name .. "\n" .. upgrade.desc
        upgradeInfo.TextColor3 = TEXT_WHITE
        upgradeInfo.TextSize = 11
        upgradeInfo.Font = Enum.Font.GothamBold
        upgradeInfo.TextXAlignment = Enum.TextXAlignment.Left
        upgradeInfo.TextYAlignment = Enum.TextYAlignment.Center
        upgradeInfo.Parent = upgradeFrame
        
        -- Buy button
        local buyBtn = Instance.new("TextButton")
        buyBtn.Name = "BuyBtn"
        buyBtn.Size = UDim2.new(0, 70, 0, 26)
        buyBtn.Position = UDim2.new(1, -80, 0.5, -13)
        buyBtn.BackgroundColor3 = TEXT_WHITE
        buyBtn.BorderSizePixel = 0
        buyBtn.Text = tostring(upgrade.price)
        buyBtn.TextColor3 = BG_DARK
        buyBtn.TextSize = 13
        buyBtn.Font = Enum.Font.GothamBold
        buyBtn.Parent = upgradeFrame
        createCorner(buyBtn, 6)
        
        buyBtn.MouseButton1Click:Connect(function()
            NetworkClient.fire("buyPermanentUpgrade", upgrade.id)
        end)
        
        yPos = yPos + 60
    end
    
    yPos = yPos + 10
    
    -- === COSMETIC TITLES SECTION ===
    local titlesTitle = Instance.new("TextLabel")
    titlesTitle.Name = "TitlesTitle"
    titlesTitle.Size = UDim2.new(1, 0, 0, 24)
    titlesTitle.Position = UDim2.new(0, 0, 0, yPos)
    titlesTitle.BackgroundTransparency = 1
    titlesTitle.Text = "COSMETIC TITLES"
    titlesTitle.TextColor3 = TEXT_WHITE
    titlesTitle.TextSize = 13
    titlesTitle.Font = Enum.Font.GothamBold
    titlesTitle.TextXAlignment = Enum.TextXAlignment.Left
    titlesTitle.Parent = container
    yPos = yPos + 28
    
    -- Title items
    for _, title in ipairs(Config.SUPERNOVA_TITLES) do
        local titleFrame = Instance.new("Frame")
        titleFrame.Name = "Title_" .. title.id
        titleFrame.Size = UDim2.new(1, 0, 0, 40)
        titleFrame.Position = UDim2.new(0, 0, 0, yPos)
        titleFrame.BackgroundColor3 = BG_CARD
        titleFrame.BorderSizePixel = 0
        titleFrame.Parent = container
        createCorner(titleFrame, 8)
        createStroke(titleFrame, BORDER_WHITE, 1)
        
        -- Title info
        local titleInfo = Instance.new("TextLabel")
        titleInfo.Size = UDim2.new(0.6, 0, 1, 0)
        titleInfo.Position = UDim2.new(0, 12, 0, 0)
        titleInfo.BackgroundTransparency = 1
        titleInfo.Text = title.name .. " - " .. title.desc
        titleInfo.TextColor3 = TEXT_WHITE
        titleInfo.TextSize = 11
        titleInfo.Font = Enum.Font.GothamBold
        titleInfo.TextXAlignment = Enum.TextXAlignment.Left
        titleInfo.TextYAlignment = Enum.TextYAlignment.Center
        titleInfo.Parent = titleFrame
        
        -- Buy button
        local buyBtn = Instance.new("TextButton")
        buyBtn.Name = "BuyBtn"
        buyBtn.Size = UDim2.new(0, 70, 0, 24)
        buyBtn.Position = UDim2.new(1, -80, 0.5, -12)
        buyBtn.BackgroundColor3 = TEXT_WHITE
        buyBtn.BorderSizePixel = 0
        buyBtn.Text = tostring(title.price)
        buyBtn.TextColor3 = BG_DARK
        buyBtn.TextSize = 13
        buyBtn.Font = Enum.Font.GothamBold
        buyBtn.Parent = titleFrame
        createCorner(buyBtn, 6)
        
        buyBtn.MouseButton1Click:Connect(function()
            NetworkClient.fire("buyTitle", title.id)
        end)
        
        yPos = yPos + 46
    end
    
    -- Update canvas size
    container.CanvasSize = UDim2.new(0, 0, 0, yPos + 20)
end

-- ============================================
-- SHOW DETAILED CONFIRMATION DIALOG
-- ============================================
function SupernovaPanel.showConfirmation()
    if not screenGui then return end
    
    -- Remove existing confirmation if any
    local existing = screenGui:FindFirstChild("SupernovaConfirmation")
    if existing then existing:Destroy() end
    
    -- Calculate values for display
    local totalEarned = currentSupernovaData and currentSupernovaData.totalStardustEarned or 0
    local tokensToEarn = math.floor(totalEarned / REQUIRED_TOTAL_STARDUST)
    local currentMult = currentSupernovaData and currentSupernovaData.multiplier or 1.0
    local newMult = currentMult + 0.5
    
    -- Apply permanent upgrades to calculations
    if currentPermanentUpgrades then
        if currentPermanentUpgrades["TokenBonus"] then
            tokensToEarn = tokensToEarn + 1
        end
        if currentPermanentUpgrades["MultiplierBoost"] then
            newMult = newMult + 0.2
        end
    end
    
    -- Dark overlay
    local overlay = Instance.new("Frame")
    overlay.Name = "SupernovaConfirmation"
    overlay.Size = UDim2.new(1, 0, 1, 0)
    overlay.Position = UDim2.new(0, 0, 0, 0)
    overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    overlay.BackgroundTransparency = 0.5
    overlay.ZIndex = 500
    overlay.Parent = screenGui
    
    -- Dialog frame
    local dialog = Instance.new("Frame")
    dialog.Name = "Dialog"
    dialog.Size = UDim2.new(0, 380, 0, 460)
    dialog.Position = UDim2.new(0.5, -190, 0.5, -230)
    dialog.BackgroundColor3 = BG_PANEL
    dialog.BorderSizePixel = 0
    dialog.ZIndex = 501
    dialog.ClipsDescendants = true
    dialog.Parent = overlay
    createCorner(dialog, 12)
    createStroke(dialog, BORDER_WHITE, 1)
    
    -- Title
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 40)
    title.Position = UDim2.new(0, 0, 0, 15)
    title.BackgroundTransparency = 1
    title.Text = "CONFIRM SUPERNOVA"
    title.TextColor3 = TEXT_WHITE
    title.TextSize = 22
    title.Font = Enum.Font.GothamBold
    title.ZIndex = 502
    title.Parent = dialog
    
    -- Thin separator line
    local separator1 = Instance.new("Frame")
    separator1.Size = UDim2.new(1, -24, 0, 1)
    separator1.Position = UDim2.new(0, 12, 0, 55)
    separator1.BackgroundColor3 = BORDER_GRAY
    separator1.BorderSizePixel = 0
    separator1.ZIndex = 502
    separator1.Parent = dialog
    
    -- === GAIN SECTION ===
    local gainSection = Instance.new("Frame")
    gainSection.Name = "GainFrame"
    gainSection.Size = UDim2.new(1, -24, 0, 95)
    gainSection.Position = UDim2.new(0, 12, 0, 62)
    gainSection.BackgroundColor3 = BG_PANEL
    gainSection.BorderSizePixel = 0
    gainSection.ZIndex = 502
    gainSection.Parent = dialog
    
    -- Left accent bar (white)
    local gainAccent = Instance.new("Frame")
    gainAccent.Size = UDim2.new(0, 2, 1, 0)
    gainAccent.Position = UDim2.new(0, 0, 0, 0)
    gainAccent.BackgroundColor3 = TEXT_WHITE
    gainAccent.BorderSizePixel = 0
    gainAccent.ZIndex = 503
    gainAccent.Parent = gainSection
    
    -- GAIN label
    local gainLabel = Instance.new("TextLabel")
    gainLabel.Size = UDim2.new(1, -12, 0, 16)
    gainLabel.Position = UDim2.new(0, 10, 0, 4)
    gainLabel.BackgroundTransparency = 1
    gainLabel.Text = "GAIN"
    gainLabel.TextColor3 = TEXT_GRAY
    gainLabel.TextSize = 11
    gainLabel.Font = Enum.Font.GothamBold
    gainLabel.TextXAlignment = Enum.TextXAlignment.Left
    gainLabel.ZIndex = 503
    gainLabel.Parent = gainSection
    
    -- GAIN content
    local gainText = Instance.new("TextLabel")
    gainText.Size = UDim2.new(1, -12, 0, 70)
    gainText.Position = UDim2.new(0, 10, 0, 22)
    gainText.BackgroundTransparency = 1
    gainText.Text = tokensToEarn .. " Supernova Tokens\nMultiplier: x" .. string.format("%.1f", currentMult) .. " \226\134\146 x" .. string.format("%.1f", newMult) .. "\nSupernova Count: " .. (currentSupernovaData and currentSupernovaData.count or 0) .. " \226\134\146 " .. ((currentSupernovaData and currentSupernovaData.count or 0) + 1)
    gainText.TextColor3 = TEXT_WHITE
    gainText.TextSize = 13
    gainText.Font = Enum.Font.GothamBold
    gainText.TextXAlignment = Enum.TextXAlignment.Left
    gainText.TextYAlignment = Enum.TextYAlignment.Top
    gainText.TextWrapped = true
    gainText.ZIndex = 503
    gainText.Parent = gainSection
    
    -- Separator
    local separator2 = Instance.new("Frame")
    separator2.Size = UDim2.new(1, -24, 0, 1)
    separator2.Position = UDim2.new(0, 12, 0, 160)
    separator2.BackgroundColor3 = BORDER_GRAY
    separator2.BorderSizePixel = 0
    separator2.ZIndex = 502
    separator2.Parent = dialog
    
    -- === LOSE SECTION ===
    local loseSection = Instance.new("Frame")
    loseSection.Name = "LoseFrame"
    loseSection.Size = UDim2.new(1, -24, 0, 95)
    loseSection.Position = UDim2.new(0, 12, 0, 167)
    loseSection.BackgroundColor3 = BG_PANEL
    loseSection.BorderSizePixel = 0
    loseSection.ZIndex = 502
    loseSection.Parent = dialog
    
    -- Left accent bar (gray)
    local loseAccent = Instance.new("Frame")
    loseAccent.Size = UDim2.new(0, 2, 1, 0)
    loseAccent.Position = UDim2.new(0, 0, 0, 0)
    loseAccent.BackgroundColor3 = TEXT_GRAY
    loseAccent.BorderSizePixel = 0
    loseAccent.ZIndex = 503
    loseAccent.Parent = loseSection
    
    -- LOSE label
    local loseLabel = Instance.new("TextLabel")
    loseLabel.Size = UDim2.new(1, -12, 0, 16)
    loseLabel.Position = UDim2.new(0, 10, 0, 4)
    loseLabel.BackgroundTransparency = 1
    loseLabel.Text = "LOSE"
    loseLabel.TextColor3 = TEXT_GRAY
    loseLabel.TextSize = 11
    loseLabel.Font = Enum.Font.GothamBold
    loseLabel.TextXAlignment = Enum.TextXAlignment.Left
    loseLabel.ZIndex = 503
    loseLabel.Parent = loseSection
    
    -- LOSE content (gray to de-emphasize)
    local loseText = Instance.new("TextLabel")
    loseText.Size = UDim2.new(1, -12, 0, 70)
    loseText.Position = UDim2.new(0, 10, 0, 22)
    loseText.BackgroundTransparency = 1
    loseText.Text = "All Stardust & Starcoins reset\nLevel & XP reset to 1\nClick Power resets\nTotal Stardust resets"
    loseText.TextColor3 = TEXT_GRAY
    loseText.TextSize = 12
    loseText.Font = Enum.Font.GothamBold
    loseText.TextXAlignment = Enum.TextXAlignment.Left
    loseText.TextYAlignment = Enum.TextYAlignment.Top
    loseText.TextWrapped = true
    loseText.ZIndex = 503
    loseText.Parent = loseSection
    
    -- Separator
    local separator3 = Instance.new("Frame")
    separator3.Size = UDim2.new(1, -24, 0, 1)
    separator3.Position = UDim2.new(0, 12, 0, 265)
    separator3.BackgroundColor3 = BORDER_GRAY
    separator3.BorderSizePixel = 0
    separator3.ZIndex = 502
    separator3.Parent = dialog
    
    -- === KEEP SECTION ===
    local keepSection = Instance.new("Frame")
    keepSection.Name = "KeepFrame"
    keepSection.Size = UDim2.new(1, -24, 0, 85)
    keepSection.Position = UDim2.new(0, 12, 0, 272)
    keepSection.BackgroundColor3 = BG_PANEL
    keepSection.BorderSizePixel = 0
    keepSection.ZIndex = 502
    keepSection.Parent = dialog
    
    -- Left accent bar (white)
    local keepAccent = Instance.new("Frame")
    keepAccent.Size = UDim2.new(0, 2, 1, 0)
    keepAccent.Position = UDim2.new(0, 0, 0, 0)
    keepAccent.BackgroundColor3 = TEXT_WHITE
    keepAccent.BorderSizePixel = 0
    keepAccent.ZIndex = 503
    keepAccent.Parent = keepSection
    
    -- KEEP label
    local keepLabel = Instance.new("TextLabel")
    keepLabel.Size = UDim2.new(1, -12, 0, 16)
    keepLabel.Position = UDim2.new(0, 10, 0, 4)
    keepLabel.BackgroundTransparency = 1
    keepLabel.Text = "KEEP"
    keepLabel.TextColor3 = TEXT_GRAY
    keepLabel.TextSize = 11
    keepLabel.Font = Enum.Font.GothamBold
    keepLabel.TextXAlignment = Enum.TextXAlignment.Left
    keepLabel.ZIndex = 503
    keepLabel.Parent = keepSection
    
    -- KEEP content
    local keepText = Instance.new("TextLabel")
    keepText.Size = UDim2.new(1, -12, 0, 60)
    keepText.Position = UDim2.new(0, 10, 0, 22)
    keepText.BackgroundTransparency = 1
    keepText.Text = "All Pets\nAll Gamepasses\nAccumulated Tokens\nPermanent Multiplier"
    keepText.TextColor3 = TEXT_WHITE
    keepText.TextSize = 12
    keepText.Font = Enum.Font.GothamBold
    keepText.TextXAlignment = Enum.TextXAlignment.Left
    keepText.TextYAlignment = Enum.TextYAlignment.Top
    keepText.TextWrapped = true
    keepText.ZIndex = 503
    keepText.Parent = keepSection
    
    -- === BUTTONS ===
    local cancelBtn = Instance.new("TextButton")
    cancelBtn.Name = "CancelButton"
    cancelBtn.Size = UDim2.new(0.5, -12, 0, 44)
    cancelBtn.Position = UDim2.new(0, 12, 1, -56)
    cancelBtn.BackgroundColor3 = BTN_DARK
    cancelBtn.BorderSizePixel = 0
    cancelBtn.Text = "CANCEL"
    cancelBtn.TextColor3 = TEXT_WHITE
    cancelBtn.TextSize = 14
    cancelBtn.Font = Enum.Font.GothamBold
    cancelBtn.ZIndex = 502
    cancelBtn.Parent = dialog
    createCorner(cancelBtn, 8)
    createStroke(cancelBtn, BORDER_GRAY, 1)
    
    cancelBtn.MouseButton1Click:Connect(function()
        -- Animate out then destroy
        local tween = TweenService:Create(dialog, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            Size = UDim2.new(0, 0, 0, 0),
            Position = UDim2.new(0.5, 0, 0.5, 0)
        })
        tween:Play()
        TweenService:Create(overlay, TweenInfo.new(0.2), {BackgroundTransparency = 1}):Play()
        tween.Completed:Connect(function()
            overlay:Destroy()
        end)
    end)
    
    local confirmBtn = Instance.new("TextButton")
    confirmBtn.Name = "ConfirmButton"
    confirmBtn.Size = UDim2.new(0.5, -12, 0, 44)
    confirmBtn.Position = UDim2.new(0.5, 0, 1, -56)
    confirmBtn.BackgroundColor3 = TEXT_WHITE
    confirmBtn.BorderSizePixel = 0
    confirmBtn.Text = "CONFIRM"
    confirmBtn.TextColor3 = BG_DARK
    confirmBtn.TextSize = 14
    confirmBtn.Font = Enum.Font.GothamBold
    confirmBtn.ZIndex = 502
    confirmBtn.Parent = dialog
    createCorner(confirmBtn, 8)
    
    confirmBtn.MouseButton1Click:Connect(function()
        -- Animate out then destroy
        local tween = TweenService:Create(dialog, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            Size = UDim2.new(0, 0, 0, 0),
            Position = UDim2.new(0.5, 0, 0.5, 0)
        })
        tween:Play()
        TweenService:Create(overlay, TweenInfo.new(0.2), {BackgroundTransparency = 1}):Play()
        tween.Completed:Connect(function()
            overlay:Destroy()
        end)
        NetworkClient.goSupernova()
    end)
    
    -- Open animation
    dialog.Size = UDim2.new(0, 0, 0, 0)
    dialog.Position = UDim2.new(0.5, 0, 0.5, 0)
    overlay.BackgroundTransparency = 1
    
    local tweenIn = TweenService:Create(dialog, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, 380, 0, 460),
        Position = UDim2.new(0.5, -190, 0.5, -230)
    })
    tweenIn:Play()
    TweenService:Create(overlay, TweenInfo.new(0.3), {BackgroundTransparency = 0.5}):Play()
end

-- ============================================
-- UPDATE PANEL
-- ============================================
function SupernovaPanel.update(supernovaData, permanentUpgrades, selectedTitle, ownedTitles)
    if not panel then return end
    
    currentSupernovaData = supernovaData
    currentPermanentUpgrades = permanentUpgrades
    currentSelectedTitle = selectedTitle
    currentOwnedTitles = ownedTitles
    
    local mainFrame = panel:FindFirstChild("MainFrame")
    if not mainFrame then return end
    
    local supernovaContent = mainFrame:FindFirstChild("SupernovaContent")
    local shopContent = mainFrame:FindFirstChild("ShopContent")
    
    -- Update Supernova content
    if supernovaContent then
        local progressFrame = supernovaContent:FindFirstChild("ProgressFrame")
        local statsFrame = supernovaContent:FindFirstChild("StatsFrame")
        
        -- Update progress
        if progressFrame then
            local totalEarned = supernovaData and supernovaData.totalStardustEarned or 0
            local progress = math.min(totalEarned / REQUIRED_TOTAL_STARDUST, 1)
            
            local progressFill = progressFrame:FindFirstChild("ProgressBg") and progressFrame.ProgressBg:FindFirstChild("ProgressFill")
            if progressFill then
                TweenService:Create(progressFill, TweenInfo.new(0.3), {Size = UDim2.new(progress, 0, 1, 0)}):Play()
            end
            
            local progressText = progressFrame:FindFirstChild("ProgressText")
            if progressText then
                progressText.Text = Config.abbreviateNumber(totalEarned) .. " / " .. Config.abbreviateNumber(REQUIRED_TOTAL_STARDUST) .. " Total Stardust"
            end
            
            local percentLabel = progressFrame:FindFirstChild("PercentLabel")
            if percentLabel then
                percentLabel.Text = string.format("%.0f%%", progress * 100)
            end
        end
        
        -- Update stats
        if statsFrame then
            local countLabel = statsFrame:FindFirstChild("CountLabel")
            local tokensLabel = statsFrame:FindFirstChild("TokensLabel")
            local multLabel = statsFrame:FindFirstChild("MultiplierLabel")
            local tokensPreview = statsFrame:FindFirstChild("TokensPreview")
            
            if countLabel then
                countLabel.Text = "Supernovas: " .. tostring(supernovaData and supernovaData.count or 0)
            end
            
            if tokensLabel then
                tokensLabel.Text = "Tokens: " .. tostring(supernovaData and supernovaData.tokens or 0)
            end
            
            if multLabel then
                multLabel.Text = "Current Multiplier: x" .. string.format("%.1f", supernovaData and supernovaData.multiplier or 1.0)
            end
            
            if tokensPreview then
                local totalEarned = supernovaData and supernovaData.totalStardustEarned or 0
                local tokensToEarn = math.floor(totalEarned / REQUIRED_TOTAL_STARDUST)
                tokensPreview.Text = "Tokens to earn: " .. tostring(tokensToEarn)
            end
        end
    end
    
    -- Update Shop content (token balance)
    if shopContent then
        local balanceFrame = shopContent:FindFirstChild("BalanceFrame")
        if balanceFrame then
            local balanceLabel = balanceFrame:FindFirstChild("BalanceLabel")
            if balanceLabel then
                balanceLabel.Text = "Your Tokens: " .. tostring(supernovaData and supernovaData.tokens or 0)
            end
        end
        
        -- Update permanent upgrade buttons (show "OWNED" if already purchased)
        if permanentUpgrades then
            for _, upgrade in ipairs(Config.PERMANENT_UPGRADES) do
                local upgradeFrame = shopContent:FindFirstChild("Upgrade_" .. upgrade.id)
                if upgradeFrame then
                    local buyBtn = upgradeFrame:FindFirstChild("BuyBtn")
                    if buyBtn then
                        if permanentUpgrades[upgrade.id] then
                            buyBtn.Text = "OWNED"
                            buyBtn.BackgroundColor3 = BORDER_GRAY
                            buyBtn.TextColor3 = TEXT_GRAY
                            buyBtn.Active = false
                        end
                    end
                end
            end
        end
        
        -- Update title buttons (show "OWNED" if already purchased)
        if ownedTitles then
            for _, title in ipairs(Config.SUPERNOVA_TITLES) do
                local titleFrame = shopContent:FindFirstChild("Title_" .. title.id)
                if titleFrame then
                    local buyBtn = titleFrame:FindFirstChild("BuyBtn")
                    if buyBtn then
                        local isOwned = false
                        for _, ownedId in ipairs(ownedTitles) do
                            if ownedId == title.id then
                                isOwned = true
                                break
                            end
                        end
                        if isOwned then
                            if selectedTitle == title.id then
                                buyBtn.Text = "EQUIPPED"
                                buyBtn.BackgroundColor3 = TEXT_WHITE
                                buyBtn.TextColor3 = BG_DARK
                            else
                                buyBtn.Text = "SELECT"
                                buyBtn.BackgroundColor3 = BORDER_GRAY
                                buyBtn.TextColor3 = TEXT_WHITE
                            end
                        end
                    end
                end
            end
        end
    end
end

return SupernovaPanel
