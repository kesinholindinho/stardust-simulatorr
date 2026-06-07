print("[CrystalBossClient] Loaded!")

-- Wrap entire script in pcall to catch errors
local success, err = pcall(function()

-- ============================================
-- SERVICES
-- ============================================
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Wait for RemoteEvent
local crystalBossSync = ReplicatedStorage:WaitForChild("CrystalBossSync")

-- ============================================
-- STATE
-- ============================================
local bossState = {
    currentHP = 0,
    maxHP = 0,
    isAlive = false,
    isUnderground = false
}

local isInArea = false
local serverAreaKnown = false
local gachaShots = 0
local isGachaRolling = false
	local showGachaRewardPopup

-- ============================================
-- CREATE GUI
-- ============================================

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "CrystalBossGUI"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.Parent = playerGui

-- ============================================
-- SHOT BADGE (Top Right)
-- ============================================
local shotBadge = Instance.new("Frame")
shotBadge.Name = "ShotBadge"
shotBadge.Size = UDim2.new(0, 150, 0, 35)
shotBadge.Position = UDim2.new(1, -160, 0, 10)
shotBadge.AnchorPoint = Vector2.new(0, 0)
shotBadge.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
shotBadge.BorderSizePixel = 1
shotBadge.BorderColor3 = Color3.fromRGB(255, 255, 255)
shotBadge.Visible = false
shotBadge.Parent = screenGui

local shotBadgeCorner = Instance.new("UICorner")
shotBadgeCorner.CornerRadius = UDim.new(0, 8)
shotBadgeCorner.Parent = shotBadge

local shotBadgeLabel = Instance.new("TextLabel")
shotBadgeLabel.Name = "Label"
shotBadgeLabel.Size = UDim2.new(1, -10, 1, 0)
shotBadgeLabel.Position = UDim2.new(0, 10, 0, 0)
shotBadgeLabel.BackgroundTransparency = 1
shotBadgeLabel.Text = "GACHA: 0 shots"
shotBadgeLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
shotBadgeLabel.TextSize = 14
shotBadgeLabel.Font = Enum.Font.GothamBold
shotBadgeLabel.TextXAlignment = Enum.TextXAlignment.Left
shotBadgeLabel.Parent = shotBadge

-- ============================================
-- HP BAR (Top Center)
-- ============================================
local hpContainer = Instance.new("Frame")
hpContainer.Name = "HPContainer"
hpContainer.Size = UDim2.new(0.5, 0, 0, 60)
hpContainer.Position = UDim2.new(0.5, 0, 0, 160)
hpContainer.AnchorPoint = Vector2.new(0.5, 0)
hpContainer.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
hpContainer.BorderSizePixel = 1
hpContainer.BorderColor3 = Color3.fromRGB(255, 255, 255)
hpContainer.Visible = false
hpContainer.Parent = screenGui

local hpContainerCorner = Instance.new("UICorner")
hpContainerCorner.CornerRadius = UDim.new(0, 10)
hpContainerCorner.Parent = hpContainer

local bossNameLabel = Instance.new("TextLabel")
bossNameLabel.Name = "BossName"
bossNameLabel.Size = UDim2.new(1, 0, 0, 20)
bossNameLabel.Position = UDim2.new(0, 0, 0, 5)
bossNameLabel.BackgroundTransparency = 1
bossNameLabel.Text = "Crystal Tree Boss"
bossNameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
bossNameLabel.TextSize = 16
bossNameLabel.Font = Enum.Font.GothamBold
bossNameLabel.Parent = hpContainer

local hpBarBg = Instance.new("Frame")
hpBarBg.Name = "HPBarBg"
hpBarBg.Size = UDim2.new(1, -20, 0, 20)
hpBarBg.Position = UDim2.new(0, 10, 0, 30)
hpBarBg.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
hpBarBg.BorderSizePixel = 0
hpBarBg.Parent = hpContainer

local hpBarBgCorner = Instance.new("UICorner")
hpBarBgCorner.CornerRadius = UDim.new(0, 5)
hpBarBgCorner.Parent = hpBarBg

local hpBarFill = Instance.new("Frame")
hpBarFill.Name = "HPBarFill"
hpBarFill.Size = UDim2.new(1, 0, 1, 0)
hpBarFill.BackgroundColor3 = Color3.fromRGB(50, 205, 50)
hpBarFill.BorderSizePixel = 0
hpBarFill.Parent = hpBarBg

local hpBarFillCorner = Instance.new("UICorner")
hpBarFillCorner.CornerRadius = UDim.new(0, 5)
hpBarFillCorner.Parent = hpBarFill

local hpText = Instance.new("TextLabel")
hpText.Name = "HPText"
hpText.Size = UDim2.new(1, 0, 1, 0)
hpText.BackgroundTransparency = 1
hpText.Text = "1000 / 1000"
hpText.TextColor3 = Color3.fromRGB(255, 255, 255)
hpText.TextSize = 12
hpText.Font = Enum.Font.GothamBold
hpText.Parent = hpBarBg

-- ============================================
-- GACHA PANEL (Center)
-- ============================================
local gachaPanel = Instance.new("Frame")
gachaPanel.Name = "GachaPanel"
gachaPanel.Size = UDim2.new(0, 600, 0, 400)
gachaPanel.Position = UDim2.new(0.5, 0, 0.5, 0)
gachaPanel.AnchorPoint = Vector2.new(0.5, 0.5)
gachaPanel.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
gachaPanel.BorderSizePixel = 1
gachaPanel.BorderColor3 = Color3.fromRGB(255, 255, 255)
gachaPanel.Visible = false
gachaPanel.Parent = screenGui

local gachaPanelCorner = Instance.new("UICorner")
gachaPanelCorner.CornerRadius = UDim.new(0, 15)
gachaPanelCorner.Parent = gachaPanel

local gachaTitle = Instance.new("TextLabel")
gachaTitle.Name = "Title"
gachaTitle.Size = UDim2.new(1, 0, 0, 40)
gachaTitle.Position = UDim2.new(0, 0, 0, 10)
gachaTitle.BackgroundTransparency = 1
gachaTitle.Text = "GACHA REWARDS"
gachaTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
gachaTitle.TextSize = 24
gachaTitle.Font = Enum.Font.GothamBold
gachaTitle.Parent = gachaPanel

local gachaShotsLabel = Instance.new("TextLabel")
gachaShotsLabel.Name = "ShotsLabel"
gachaShotsLabel.Size = UDim2.new(0, 200, 0, 30)
gachaShotsLabel.Position = UDim2.new(0.5, -100, 0, 55)
gachaShotsLabel.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
gachaShotsLabel.BorderSizePixel = 1
gachaShotsLabel.BorderColor3 = Color3.fromRGB(255, 255, 255)
gachaShotsLabel.Text = "0 shots remaining"
gachaShotsLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
gachaShotsLabel.TextSize = 14
gachaShotsLabel.Font = Enum.Font.GothamBold
gachaShotsLabel.Parent = gachaPanel

local gachaShotsLabelCorner = Instance.new("UICorner")
gachaShotsLabelCorner.CornerRadius = UDim.new(0, 8)
gachaShotsLabelCorner.Parent = gachaShotsLabel

-- Cards container
local cardsContainer = Instance.new("Frame")
cardsContainer.Name = "CardsContainer"
cardsContainer.Size = UDim2.new(1, -40, 0, 220)
cardsContainer.Position = UDim2.new(0, 20, 0, 100)
cardsContainer.BackgroundTransparency = 1
cardsContainer.Parent = gachaPanel

local cardsLayout = Instance.new("UIListLayout")
cardsLayout.FillDirection = Enum.FillDirection.Horizontal
cardsLayout.SortOrder = Enum.SortOrder.LayoutOrder
cardsLayout.Padding = UDim.new(0, 10)
cardsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
cardsLayout.VerticalAlignment = Enum.VerticalAlignment.Center
cardsLayout.Parent = cardsContainer

-- Use Shot button
local useShotBtn = Instance.new("TextButton")
useShotBtn.Name = "UseShotBtn"
useShotBtn.Size = UDim2.new(0, 200, 0, 45)
useShotBtn.Position = UDim2.new(0.5, -100, 1, -60)
useShotBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
useShotBtn.BorderSizePixel = 1
useShotBtn.BorderColor3 = Color3.fromRGB(255, 255, 255)
useShotBtn.Text = "USE SHOT"
useShotBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
useShotBtn.TextSize = 18
useShotBtn.Font = Enum.Font.GothamBold
useShotBtn.Parent = gachaPanel

local useShotBtnCorner = Instance.new("UICorner")
useShotBtnCorner.CornerRadius = UDim.new(0, 10)
useShotBtnCorner.Parent = useShotBtn

-- Close button
local closeBtn = Instance.new("TextButton")
closeBtn.Name = "CloseBtn"
closeBtn.Size = UDim2.new(0, 35, 0, 35)
closeBtn.Position = UDim2.new(1, -45, 0, 10)
closeBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
closeBtn.BorderSizePixel = 0
closeBtn.Text = "X"
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.TextSize = 18
closeBtn.Font = Enum.Font.GothamBold
closeBtn.Parent = gachaPanel

local closeBtnCorner = Instance.new("UICorner")
closeBtnCorner.CornerRadius = UDim.new(0, 8)
closeBtnCorner.Parent = closeBtn

-- ============================================
-- BOSS DEFEATED POPUP
-- ============================================
local rewardPopup = Instance.new("Frame")
rewardPopup.Name = "RewardPopup"
rewardPopup.Size = UDim2.new(0, 350, 0, 180)
rewardPopup.Position = UDim2.new(0.5, 0, 0.5, 0)
rewardPopup.AnchorPoint = Vector2.new(0.5, 0.5)
rewardPopup.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
rewardPopup.BorderSizePixel = 1
rewardPopup.BorderColor3 = Color3.fromRGB(255, 255, 255)
rewardPopup.Visible = false
rewardPopup.Parent = screenGui

local rewardPopupCorner = Instance.new("UICorner")
rewardPopupCorner.CornerRadius = UDim.new(0, 15)
rewardPopupCorner.Parent = rewardPopup

local rewardTitle = Instance.new("TextLabel")
rewardTitle.Name = "Title"
rewardTitle.Size = UDim2.new(1, 0, 0, 40)
rewardTitle.Position = UDim2.new(0, 0, 0, 15)
rewardTitle.BackgroundTransparency = 1
rewardTitle.Text = "BOSS DEFEATED!"
rewardTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
rewardTitle.TextSize = 24
rewardTitle.Font = Enum.Font.GothamBold
rewardTitle.Parent = rewardPopup

local rewardText = Instance.new("TextLabel")
rewardText.Name = "RewardText"
rewardText.Size = UDim2.new(1, 0, 0, 30)
rewardText.Position = UDim2.new(0, 0, 0, 60)
rewardText.BackgroundTransparency = 1
rewardText.Text = "+5000 Stardust"
rewardText.TextColor3 = Color3.fromRGB(255, 255, 255)
rewardText.TextSize = 16
rewardText.Font = Enum.Font.Gotham
rewardText.Parent = rewardPopup

local rewardShots = Instance.new("TextLabel")
rewardShots.Name = "ShotsText"
rewardShots.Size = UDim2.new(1, 0, 0, 30)
rewardShots.Position = UDim2.new(0, 0, 0, 95)
rewardShots.BackgroundTransparency = 1
rewardShots.Text = "+5 GACHA Shots!"
rewardShots.TextColor3 = Color3.fromRGB(255, 255, 255)
rewardShots.TextSize = 18
rewardShots.Font = Enum.Font.GothamBold
rewardShots.Parent = rewardPopup

local openGachaBtn = Instance.new("TextButton")
openGachaBtn.Name = "OpenGachaBtn"
openGachaBtn.Size = UDim2.new(0, 180, 0, 35)
openGachaBtn.Position = UDim2.new(0.5, -90, 1, -50)
openGachaBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
openGachaBtn.BorderSizePixel = 1
openGachaBtn.BorderColor3 = Color3.fromRGB(255, 255, 255)
openGachaBtn.Text = "Open Gacha"
openGachaBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
openGachaBtn.TextSize = 14
openGachaBtn.Font = Enum.Font.GothamBold
openGachaBtn.Parent = rewardPopup

local openGachaBtnCorner = Instance.new("UICorner")
openGachaBtnCorner.CornerRadius = UDim.new(0, 8)
openGachaBtnCorner.Parent = openGachaBtn

-- ============================================
-- GACHA REWARD POPUP
-- ============================================
local gachaRewardPopup = Instance.new("Frame")
gachaRewardPopup.Name = "GachaRewardPopup"
gachaRewardPopup.Size = UDim2.new(0, 280, 0, 180)
gachaRewardPopup.Position = UDim2.new(0.5, 0, 0.5, 0)
gachaRewardPopup.AnchorPoint = Vector2.new(0.5, 0.5)
gachaRewardPopup.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
gachaRewardPopup.BorderSizePixel = 1
gachaRewardPopup.BorderColor3 = Color3.fromRGB(255, 255, 255)
gachaRewardPopup.Visible = false
gachaRewardPopup.ZIndex = 100
gachaRewardPopup.Parent = screenGui

local gachaRewardPopupCorner = Instance.new("UICorner")
gachaRewardPopupCorner.CornerRadius = UDim.new(0, 15)
gachaRewardPopupCorner.Parent = gachaRewardPopup

local gachaRewardName = Instance.new("TextLabel")
gachaRewardName.Name = "RewardName"
gachaRewardName.Size = UDim2.new(1, 0, 0, 60)
gachaRewardName.Position = UDim2.new(0, 0, 0, 60)
gachaRewardName.BackgroundTransparency = 1
gachaRewardName.Text = "500 Stardust"
gachaRewardName.TextColor3 = Color3.fromRGB(255, 255, 255)
gachaRewardName.TextSize = 22
gachaRewardName.Font = Enum.Font.GothamBold
gachaRewardName.ZIndex = 101
gachaRewardName.Parent = gachaRewardPopup

local gachaRewardRarity = Instance.new("TextLabel")
gachaRewardRarity.Name = "Rarity"
gachaRewardRarity.Size = UDim2.new(1, 0, 0, 30)
gachaRewardRarity.Position = UDim2.new(0, 0, 0, 120)
gachaRewardRarity.BackgroundTransparency = 1
gachaRewardRarity.Text = "Common"
gachaRewardRarity.TextColor3 = Color3.fromRGB(180, 180, 180)
gachaRewardRarity.TextSize = 16
gachaRewardRarity.Font = Enum.Font.GothamBold
gachaRewardRarity.ZIndex = 101
gachaRewardRarity.Parent = gachaRewardPopup

-- ============================================
-- FLOATING GACHA BUTTON
-- ============================================
local floatingBtn = Instance.new("TextButton")
floatingBtn.Name = "FloatingBtn"
floatingBtn.Size = UDim2.new(0, 60, 0, 60)
floatingBtn.Position = UDim2.new(1, -70, 0.5, -30)
floatingBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
floatingBtn.BorderSizePixel = 1
floatingBtn.BorderColor3 = Color3.fromRGB(255, 255, 255)
floatingBtn.Text = "GACHA"
floatingBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
floatingBtn.TextSize = 12
floatingBtn.Font = Enum.Font.GothamBold
floatingBtn.Visible = false
floatingBtn.Parent = screenGui

local floatingBtnCorner = Instance.new("UICorner")
floatingBtnCorner.CornerRadius = UDim.new(0, 30)
floatingBtnCorner.Parent = floatingBtn

-- ============================================
-- CARD FRAMES TABLE
-- ============================================
local cardFrames = {}
local CARD_WIDTH = 70
local CARD_HEIGHT = 200

-- Icon mapping for rewards
local REWARD_ICONS = {
    ["Stardust"] = "★",
    ["Starcoins"] = "◆",
    ["Crystal Shard"] = "◈",
    ["XP Boost"] = "▲",
    ["Mini Crystal"] = "✦",
    ["Crystal Tree"] = "✤",
}

-- Short display names for card text (server names → readable short names)
local DISPLAY_NAMES = {
    ["PetMiniCrystal"] = "Mini Crystal",
    ["PetCrystalTree"] = "Crystal Tree",
    ["Crystal Shard"] = "Shard",
    ["XP Boost"] = "XP Boost",
    ["Starcoins"] = "Coins",
    ["Stardust"] = "Stardust",
    ["MISS"] = "MISS",
}

-- Short emoji text for cards (server emoji → short text that fits)
local SHORT_EMOJIS = {
    ["★"] = "★",
    ["◆"] = "◆",
    ["◈"] = "◈",
    ["▲"] = "▲",
    ["✦"] = "✦",
    ["✤"] = "✤",
    ["✕"] = "✕",
}

-- ============================================
-- HELPER FUNCTIONS (ALL DEFINED FIRST)
-- ============================================

local function updateShotUI()
    shotBadgeLabel.Text = "GACHA: " .. gachaShots .. " shots"
    shotBadge.Visible = gachaShots > 0
    floatingBtn.Visible = gachaShots > 0
    gachaShotsLabel.Text = gachaShots .. " shots remaining"
    
    if not isGachaRolling then
        if gachaShots > 0 then
            useShotBtn.Text = "USE SHOT (" .. gachaShots .. ")"
            useShotBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        else
            useShotBtn.Text = "NO SHOTS"
            useShotBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
        end
    end
end

local function updateHPBar()
    if bossState.maxHP <= 0 then return end
    
    local percent = bossState.currentHP / bossState.maxHP
    hpBarFill.Size = UDim2.new(percent, 0, 1, 0)
    hpText.Text = bossState.currentHP .. " / " .. bossState.maxHP
    
    if percent > 0.6 then
        hpBarFill.BackgroundColor3 = Color3.fromRGB(50, 205, 50)
    elseif percent > 0.3 then
        hpBarFill.BackgroundColor3 = Color3.fromRGB(255, 200, 50)
    else
        hpBarFill.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
    end
end

local function updateVisibility()
		local shouldShow = isInArea and bossState.isAlive and not bossState.isUnderground
    hpContainer.Visible = shouldShow
    
    if shouldShow then
        updateHPBar()
    end
end

local function checkIfInArea()
    local character = player.Character
    if not character then return false end
    
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end
    
    local areaFolder = game.Workspace:FindFirstChild("Crstal Tree pasta")
    if not areaFolder then return false end
    
    local areaPart = areaFolder:FindFirstChild("Area Crystal")
    if not areaPart then return false end
    
    local relativePos = areaPart.CFrame:PointToObjectSpace(hrp.Position)
    return math.abs(relativePos.X) <= areaPart.Size.X / 2 and
           math.abs(relativePos.Y) <= areaPart.Size.Y / 2 and
           math.abs(relativePos.Z) <= areaPart.Size.Z / 2
end

local function createCards()
    -- Clear existing cards
    for _, card in ipairs(cardFrames) do
        card:Destroy()
    end
    cardFrames = {}
    
		for i = 1, 5 do
        local card = Instance.new("Frame")
        card.Name = "Card" .. i
        card.Size = UDim2.new(0, CARD_WIDTH, 0, CARD_HEIGHT)
        card.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
        card.BorderSizePixel = 1
        card.BorderColor3 = Color3.fromRGB(200, 200, 200)
        card.Parent = cardsContainer
        
        local cardCorner = Instance.new("UICorner")
        cardCorner.CornerRadius = UDim.new(0, 10)
        cardCorner.Parent = card
        
        -- Icon label (top section)
        local iconLabel = Instance.new("TextLabel")
        iconLabel.Name = "IconLabel"
        iconLabel.Size = UDim2.new(1, 0, 0, 70)
        iconLabel.Position = UDim2.new(0, 0, 0, 0)
        iconLabel.BackgroundTransparency = 1
        iconLabel.Text = "?"
        iconLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        iconLabel.TextSize = 22
        iconLabel.Font = Enum.Font.GothamBold
        iconLabel.TextStrokeTransparency = 0.3
        iconLabel.Parent = card
        
        -- Name label (middle section)
        local nameLabel = Instance.new("TextLabel")
        nameLabel.Name = "NameLabel"
        nameLabel.Size = UDim2.new(1, -4, 0, 50)
        nameLabel.Position = UDim2.new(0, 2, 0, 75)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Text = ""
        nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        nameLabel.TextTransparency = 0
        nameLabel.TextSize = 11
        nameLabel.TextWrapped = true
        nameLabel.Font = Enum.Font.Gotham
        nameLabel.TextStrokeTransparency = 0.5
        nameLabel.Parent = card
        
        -- Rarity label (bottom section)
        local rarityLabel = Instance.new("TextLabel")
        rarityLabel.Name = "RarityLabel"
        rarityLabel.Size = UDim2.new(1, 0, 0, 25)
        rarityLabel.Position = UDim2.new(0, 0, 1, -30)
        rarityLabel.BackgroundTransparency = 1
        rarityLabel.Text = ""
        rarityLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
        rarityLabel.TextTransparency = 0
        rarityLabel.TextSize = 11
        rarityLabel.Font = Enum.Font.GothamBold
        rarityLabel.Parent = card
        
        table.insert(cardFrames, card)
    end
end

local function flipCard(cardIndex, cardResult, isWinning, isMiss)
    local card = cardFrames[cardIndex]
    if not card then return end
    
    local iconLabel = card:FindFirstChild("IconLabel")
    local nameLabel = card:FindFirstChild("NameLabel")
    local rarityLabel = card:FindFirstChild("RarityLabel")
    
    -- Update card appearance based on result
    if iconLabel then
        if isMiss then
            iconLabel.Text = "X"
            iconLabel.TextSize = 36
        else
            local emojiText = cardResult.emoji or ""
            iconLabel.Text = SHORT_EMOJIS[emojiText] or emojiText
            iconLabel.TextSize = 22
        end
    end
    
    if nameLabel then
        if isMiss then
            nameLabel.Text = "MISS"
        elseif cardResult.amount then
            local displayName = DISPLAY_NAMES[cardResult.name] or cardResult.name or ""
            nameLabel.Text = cardResult.amount .. " " .. displayName
        else
            nameLabel.Text = DISPLAY_NAMES[cardResult.name] or cardResult.name or ""
        end
    end
    
    if rarityLabel and isWinning and cardResult.rarity then
        rarityLabel.Text = cardResult.rarity
    end
    
    -- Update card background color based on type (dark, distinct colors)
    if cardResult.type == "miss" then
        card.BackgroundColor3 = Color3.fromRGB(60, 15, 15)
    elseif cardResult.type == "pet" then
        card.BackgroundColor3 = Color3.fromRGB(40, 20, 60)
elseif cardResult.type == "item" then
        card.BackgroundColor3 = Color3.fromRGB(20, 50, 30)
    elseif cardResult.type == "stardust" then
        card.BackgroundColor3 = Color3.fromRGB(50, 45, 10)
    elseif cardResult.type == "starcoins" then
        card.BackgroundColor3 = Color3.fromRGB(50, 35, 10)
    end
    
    if isWinning then
        card.BorderColor3 = Color3.fromRGB(255, 255, 255)
    end
end

local function shuffleCards()
    -- Visual shuffle effect - briefly shake the cards
    for i = 1, 3 do
        for _, card in ipairs(cardFrames) do
            local originalPos = card.Position
            card.Position = UDim2.new(originalPos.X.Scale, originalPos.X.Offset + math.random(-5, 5), originalPos.Y.Scale, originalPos.Y.Offset + math.random(-3, 3))
        end
        task.wait(0.05)
    end
    -- Reset positions
    for i, card in ipairs(cardFrames) do
        card.Position = UDim2.new(0, 0, 0, 0)
    end
end

local function playGachaAnimation(results)
    isGachaRolling = true
    useShotBtn.Text = "Rolling..."
    useShotBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    
    -- Wrap everything in pcall so errors don't freeze the panel
    local ok, err = pcall(function()
        createCards()
        shuffleCards()
        shuffleCards()
        
			for i = 1, 5 do
            local cardResult = results[i]
            if cardResult then
                local isMiss = cardResult.type == "miss"
                task.wait(0.15)
                flipCard(i, cardResult, not isMiss, isMiss)
                task.wait(0.3)
            end
        end
        
        -- Count non-miss rewards
        local won = {}
        for _, r in ipairs(results) do
            if r.type ~= "miss" then
                table.insert(won, r)
            end
        end
        
        -- Show popup
        if #won > 0 then
            showGachaRewardPopup(won)
        else
            gachaRewardName.Text = "Better luck next time!"
            gachaRewardRarity.Text = ""
            gachaRewardPopup.Size = UDim2.new(0, 280, 0, 120)
            gachaRewardPopup.Visible = true
        end
    end)
    
    if not ok then
        warn("[CrystalBossClient] Gacha animation error: " .. tostring(err))
    end
    
    -- ALWAYS reset after animation, success or failure
    task.delay(3, function()
        isGachaRolling = false
        gachaRewardPopup.Visible = false
        updateShotUI()
    end)
end

local function openGachaPanel()
    if gachaPanel.Visible then return end
    
    gachaPanel.Visible = true
    gachaPanel.Size = UDim2.new(0, 600, 0, 0)
    
    local tween = TweenService:Create(gachaPanel, TweenInfo.new(0.3, Enum.EasingStyle.Back), {
        Size = UDim2.new(0, 600, 0, 400)
    })
    tween:Play()
    
    createCards()
    updateShotUI()
    crystalBossSync:FireServer("getGachaShots")
end

local function closeGachaPanel()
    if isGachaRolling then return end
    
    local tween = TweenService:Create(gachaPanel, TweenInfo.new(0.2), {
        Size = UDim2.new(0, 600, 0, 0)
    })
    tween:Play()
    tween.Completed:Wait()
    gachaPanel.Visible = false
end

local function showRewardPopup(stardust, starcoins, shots)
    rewardText.Text = "+" .. stardust .. " Stardust, +" .. starcoins .. " Starcoins"
    rewardShots.Text = "+" .. shots .. " GACHA Shots!"
    rewardPopup.Visible = true
    
    task.delay(5, function()
        rewardPopup.Visible = false
    end)
end

	showGachaRewardPopup = function(rewardsSummary)
    -- Show list of won rewards, or "Better luck next time!" if all MISS
    if #rewardsSummary == 0 then
        gachaRewardName.Text = "Better luck next time!"
        gachaRewardRarity.Text = ""
    else
        -- Build summary text
        local summaryText = ""
        for i, r in ipairs(rewardsSummary) do
            if r.amount then
                summaryText = summaryText .. r.amount .. " " .. r.name
            else
                summaryText = summaryText .. (r.name or "Reward")
            end
            if i < #rewardsSummary then
                summaryText = summaryText .. "\n"
            end
        end
        gachaRewardName.Text = summaryText
        
        -- Show rarity of best reward
        local bestReward = nil
        for _, r in ipairs(rewardsSummary) do
            if r.type == "pet" and r.rarity then
                if not bestReward or r.rarity == "Lendario" then
                    bestReward = r
                end
            end
        end
        gachaRewardRarity.Text = bestReward and bestReward.rarity or (#rewardsSummary .. " rewards won!")
    end
    
    gachaRewardPopup.Size = UDim2.new(0, 350, 0, 50 + #rewardsSummary * 25)
    gachaRewardPopup.Visible = true
end

-- ============================================
-- BUTTON HANDLERS (AFTER FUNCTIONS)
-- ============================================

closeBtn.MouseButton1Click:Connect(function()
    -- Force close even if rolling, but reset state
    isGachaRolling = false
    gachaRewardPopup.Visible = false
    closeGachaPanel()
end)

useShotBtn.MouseButton1Click:Connect(function()
    if isGachaRolling then return end
    if gachaShots <= 0 then return end
    
    crystalBossSync:FireServer("useGachaShot")
    isGachaRolling = true
    useShotBtn.Text = "Rolling..."
end)

floatingBtn.MouseButton1Click:Connect(function()
    if gachaPanel.Visible then
        closeGachaPanel()
    else
        openGachaPanel()
    end
end)

openGachaBtn.MouseButton1Click:Connect(function()
    rewardPopup.Visible = false
    task.wait(0.1)
    openGachaPanel()
end)

-- ============================================
-- REMOTEEVENT HANDLERS (AFTER FUNCTIONS)
-- ============================================

crystalBossSync.OnClientEvent:Connect(function(action, data, arg2, arg3)
    if action == "bossStateUpdate" then
        bossState.currentHP = data.currentHP or 0
        bossState.maxHP = data.maxHP or 0
        bossState.isAlive = data.isAlive or false
        bossState.isUnderground = data.isUnderground or false
        if data.isInArea ~= nil then
            isInArea = data.isInArea
            serverAreaKnown = true
        end
        updateVisibility()
        
    elseif action == "bossDefeated" then
        bossState.isAlive = false
        bossState.isUnderground = true
        updateVisibility()
        
        if data.gachaShots then
            gachaShots = data.gachaShots
            updateShotUI()
        end
        
        showRewardPopup(data.stardust or 0, data.starcoins or 0, data.gachaShots or 0)
        
        task.delay(3, function()
            if gachaShots > 0 then
                openGachaPanel()
            end
        end)
        
    elseif action == "damageDealt" or action == "bossDamageFromClick" then
        bossState.currentHP = arg2 or bossState.currentHP
        updateHPBar()
        
    elseif action == "gachaResults" then
        -- data = table of 7 card results, arg2 = remaining shots
        if data then
            gachaShots = arg2 or 0
            updateShotUI()
            task.spawn(function()
                playGachaAnimation(data) -- pass all 7 results
            end)
        end
        
    elseif action == "gachaShotsUpdate" then
        gachaShots = data or 0
        updateShotUI()
        
    elseif action == "gachaError" then
        isGachaRolling = false
        updateShotUI()
        
    elseif action == "teleportingToSpawn" then
        -- Show countdown message
        local msg = Instance.new("TextLabel")
        msg.Size = UDim2.new(0, 300, 0, 40)
        msg.Position = UDim2.new(0.5, -150, 0.7, 0)
        msg.BackgroundTransparency = 1
        msg.Text = "Returning to spawn in 5..."
        msg.TextColor3 = Color3.fromRGB(255, 255, 255)
        msg.TextSize = 20
        msg.Font = Enum.Font.GothamBold
        msg.TextStrokeTransparency = 0.3
        msg.Parent = screenGui
        
        for i = 4, 1, -1 do
            task.wait(1)
            msg.Text = "Returning to spawn in " .. i .. "..."
        end
        task.wait(1)
        msg:Destroy()
    end
end)

-- ============================================
-- AREA CHECK LOOP
-- ============================================

task.spawn(function()
    while true do
        task.wait(1)
        if not serverAreaKnown then
            isInArea = checkIfInArea()
            updateVisibility()
        end
        crystalBossSync:FireServer("requestState")
    end
end)

-- ============================================
-- INITIAL REQUESTS
-- ============================================

task.wait(1)
crystalBossSync:FireServer("requestState")
crystalBossSync:FireServer("getGachaShots")
print("[CrystalBossClient] Ready!")

end) -- End pcall

if not success then
    warn("[CrystalBossClient] ERROR: " .. tostring(err))
end