-- ============================================
-- STARDUST GUI - REFACTORED WITH MODULES
-- This script was refactored to use panel modules
-- instead of inline code for better maintainability
-- ============================================

-- ===== SERVICES AND CORE REFERENCES =====
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local screenGui = playerGui:WaitForChild("StardustUI", 15)
if not screenGui then
    warn("[StardustGUI] ScreenGui 'StardustUI' not found in PlayerGui after 15 seconds!")
    return
end

-- ===== MODULES =====
local Style = require(ReplicatedStorage:WaitForChild("StardustStyle"))
local PanelManager = require(ReplicatedStorage:WaitForChild("StardustUI"):WaitForChild("PanelManager"))

-- Panel Modules
local AutoClickPanel = require(ReplicatedStorage:WaitForChild("StardustUI"):WaitForChild("Panels"):WaitForChild("AutoClickPanel"))
local ShopPanel = require(ReplicatedStorage:WaitForChild("StardustUI"):WaitForChild("Panels"):WaitForChild("ShopPanel"))
local SellPanel = require(ReplicatedStorage:WaitForChild("StardustUI"):WaitForChild("Panels"):WaitForChild("SellPanel"))
local UpgradesPanel = require(ReplicatedStorage:WaitForChild("StardustUI"):WaitForChild("Panels"):WaitForChild("UpgradesPanel"))
local InventoryPanel = require(ReplicatedStorage:WaitForChild("StardustUI"):WaitForChild("Panels"):WaitForChild("InventoryPanel"))
local EggsPanel = require(ReplicatedStorage:WaitForChild("StardustUI"):WaitForChild("Panels"):WaitForChild("EggsPanel"))
local PetsPanel = require(ReplicatedStorage:WaitForChild("StardustUI"):WaitForChild("Panels"):WaitForChild("PetsPanel"))
local SupernovaPanel = require(ReplicatedStorage:WaitForChild("StardustUI"):WaitForChild("Panels"):WaitForChild("SupernovaPanel"))
local WorldsPanel = require(ReplicatedStorage:WaitForChild("StardustUI"):WaitForChild("Panels"):WaitForChild("WorldsPanel"))
local QuestsPanel = require(ReplicatedStorage:WaitForChild("StardustUI"):WaitForChild("Panels"):WaitForChild("QuestsPanel"))
local DailyRewardPanel = require(ReplicatedStorage:WaitForChild("StardustUI"):WaitForChild("Panels"):WaitForChild("DailyRewardPanel"))
local SettingsPanel = require(ReplicatedStorage:WaitForChild("StardustUI"):WaitForChild("Panels"):WaitForChild("SettingsPanel"))
local LeaderboardPanel = require(ReplicatedStorage:WaitForChild("StardustUI"):WaitForChild("Panels"):WaitForChild("LeaderboardPanel"))
-- TUTORIAL: Import TutorialPanel module
local TutorialPanel = require(ReplicatedStorage:WaitForChild("StardustUI"):WaitForChild("Panels"):WaitForChild("TutorialPanel"))

local COLORS = Style.COLORS

-- ===== HELPER FUNCTIONS =====
local createCorner = Style.createCorner
local createStroke = Style.createStroke
local createShadow = Style.createShadow
local setupButtonEffects = function(btn) Style.setupButtonEffects(btn, TweenService) end
local showPanel = function(panel) Style.showPanel(panel, TweenService) end
local hidePanel = function(panel) Style.hidePanel(panel, TweenService) end
local abbreviateNumber = Style.abbreviateNumber
local createCloseButton = function(parent) return Style.createCloseButton(parent, TweenService) end

-- ===== STATE =====
local state = {
    stardust = 0,
    starcoins = 0,
    level = 1,
    xp = 0,
    xpNeeded = 100,
    playerDailyRewardData = nil,
    supernovaData = nil,
    activePanel = nil,
    activeButton = nil,
    buttonInstances = {},
    has2xGamepass = false,
    has2xXPGamepass = false,
    hasAutoClickStarGamepass = false,
    autoClickEnabled = false,
    autoClickRate = 0.5,
    autoClickConnection = nil,
    totalAutoClicks = 0,
    ownedPets = {},
    inventoryItems = {},
    upgradeLevels = {},
    dailyRewardCards = {},
    -- Active boosts tracking
    activeBoosts = {} -- {name, endTime, multiplier}
}

-- ===== GAMEPASS IDs =====
local GAMEPASS_IDS = {
    TWO_X_STARDUST = 1817317562,
    MORE_PETS = 1816119729,
    TWO_X_XP = 1814337737,
    AUTO_CLICK_STAR = 1818211451
}

-- ===== BUTTONS CONFIGURATION =====
local BUTTONS = {
    {name = "Shop", panel = "ShopPanel", emoji = "🛒"},
    {name = "Sell", panel = "SellPanel", emoji = "💰"},
    {name = "Upgrades", panel = "UpgradesPanel", emoji = "⚡"},
    {name = "Inventory", panel = "InventoryPanel", emoji = "🎒"},
    {name = "Eggs", panel = "EggsPanel", emoji = "🥚"},
    {name = "Pets", panel = "PetsPanel", emoji = "🐾"},
    {name = "Supernova", panel = "SupernovaPanel", emoji = "💥"},
    {name = "Worlds", panel = "WorldsPanel", emoji = "🌍"},
    {name = "AutoClick", panel = "AutoClickPanel", emoji = "🔄"},
    {name = "Settings", panel = "SettingsPanel", emoji = "⚙️"},
    {name = "Leaderboard", panel = "LeaderboardPanel", emoji = "🏆"},
    {name = "Quests", panel = "QuestsPanel", emoji = "📋"},
    {name = "Trade", panel = "TradePanel", emoji = "🤝"}
}

-- ===== RARITY DATA =====
local RARITY_COLORS = {
    ["Common"] = Color3.fromRGB(150, 150, 150),
    ["Raro"] = Color3.fromRGB(100, 150, 255),
    ["Rare"] = Color3.fromRGB(100, 150, 255),
    ["Epico"] = Color3.fromRGB(180, 100, 255),
    ["Epic"] = Color3.fromRGB(180, 100, 255),
    ["Lendario"] = Color3.fromRGB(255, 200, 50),
    ["Legendary"] = Color3.fromRGB(255, 200, 50),
    ["Mythic"] = Color3.fromRGB(255, 100, 255),
    ["Especial"] = Color3.fromRGB(255, 150, 200),
    ["Premium"] = Color3.fromRGB(100, 200, 255)
}

local RARITY_ORDER = {
    ["Common"] = 1, ["Raro"] = 2, ["Rare"] = 2,
    ["Epico"] = 3, ["Epic"] = 3,
    ["Lendario"] = 4, ["Legendary"] = 4,
    ["Mythic"] = 5, ["Especial"] = 6
}

-- ===== GAME ACTION REMOTE =====
local gameActionRemote = ReplicatedStorage:WaitForChild("GameAction")

local function safeFireServer(action, ...)
    local args = {...}
    local success, err = pcall(function()
        gameActionRemote:FireServer(action, table.unpack(args))
    end)
    if not success then
        warn("[Client] Failed to send '" .. tostring(action) .. "' to server: " .. tostring(err))
    end
    return success
end

-- ===== AUTOCLICK SOUND =====
local autoClickSound = Instance.new("Sound")
autoClickSound.Name = "AutoClickSound"
autoClickSound.SoundId = "rbxassetid://156286438"
autoClickSound.Volume = 0.5
autoClickSound.Parent = screenGui

-- ===== SETTINGS HELPER =====
local function shouldShowNotifications()
    return SettingsPanel.notificationsEnabled()
end

local function shouldPlaySound()
    return SettingsPanel.soundEnabled()
end

-- ===== TUTORIAL SYNC =====
local tutorialSync = ReplicatedStorage:FindFirstChild("TutorialSync")
if tutorialSync then
    tutorialSync.OnClientEvent:Connect(function(tutorialCompleted)
        -- If tutorial not completed, show it
        if not tutorialCompleted then
            -- Wait a moment for UI to fully load
            task.wait(1)
            
            -- Get button container for highlighting
            local bottomBar = screenGui:FindFirstChild("BottomBar")
            local btnContainer = bottomBar and bottomBar:FindFirstChild("ButtonContainer")
            
            -- Find star element (central star button)
            local starElement = screenGui:FindFirstChild("StarButton") or screenGui:FindFirstChild("CentralStar")
            
            -- Start tutorial
            TutorialPanel.start(screenGui, btnContainer, starElement, function()
                -- Notify server that tutorial was completed
                tutorialSync:FireServer("completed")
                print("[Tutorial] Tutorial completed, notified server")
            end)
        else
            print("[Tutorial] Tutorial already completed for this player")
        end
    end)
end

-- ===== HUD ELEMENTS =====
local hudTopFrame = screenGui:FindFirstChild("HUD_Top")
local stardustLabel = hudTopFrame and hudTopFrame:FindFirstChild("StardustLabel")
local starcoinsLabel = hudTopFrame and hudTopFrame:FindFirstChild("StarcoinsLabel")
if stardustLabel then
    stardustLabel.Text = "✨ " .. tostring(state.stardust)
end
if starcoinsLabel then
    starcoinsLabel.Text = "🌙 " .. tostring(state.starcoins)
end
local levelBadge = screenGui:FindFirstChild("LevelBadge")
local levelLabel = levelBadge and levelBadge:FindFirstChildWhichIsA("TextLabel")
if levelLabel then
    levelLabel.Text = "⭐ Lv. " .. tostring(state.level)
end
local xpBarBg = screenGui:FindFirstChild("XPBar")
local xpBarFill = xpBarBg and xpBarBg:FindFirstChild("Fill")

-- Pet passive income rate label
local petIncomeLabel = nil
if hudTopFrame and stardustLabel then
	petIncomeLabel = Instance.new("TextLabel")
	petIncomeLabel.Name = "PetIncomeRate"
	petIncomeLabel.Size = UDim2.new(0, 120, 0, 18)
	petIncomeLabel.Position = stardustLabel.Position + UDim2.new(0, 0, 0, 20)
	petIncomeLabel.BackgroundTransparency = 1
	petIncomeLabel.Text = ""
	petIncomeLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
	petIncomeLabel.TextSize = 12
	petIncomeLabel.Font = Enum.Font.GothamBold
	petIncomeLabel.TextXAlignment = Enum.TextXAlignment.Left
	petIncomeLabel.ZIndex = stardustLabel.ZIndex
	petIncomeLabel.Parent = hudTopFrame
end

local currentPetRate = 0

local function updatePetIncomeLabel(totalMult)
	currentPetRate = totalMult or 0
	if petIncomeLabel then
		if currentPetRate > 0 then
			petIncomeLabel.Text = "+" .. tostring(currentPetRate) .. "/s 🐾"
		else
			petIncomeLabel.Text = ""
		end
	end
end

-- Show floating pet income notification every 5 seconds
task.spawn(function()
	while true do
		task.wait(5)
		if currentPetRate > 0 and screenGui and screenGui.Parent then
			local accumulated = currentPetRate * 5
			local notif = Instance.new("TextLabel")
			notif.Name = "PetIncomeNotif"
			notif.Size = UDim2.new(0, 200, 0, 50)
			notif.Position = UDim2.new(0.5, -100, 0.45, 0)
			notif.BackgroundTransparency = 1
			notif.Text = "+" .. tostring(accumulated) .. " ✨ 🐾"
			notif.TextColor3 = Color3.fromRGB(255, 200, 100)
			notif.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
			notif.TextStrokeTransparency = 0.5
			notif.TextSize = 26
			notif.Font = Enum.Font.GothamBold
			notif.ZIndex = 200
			notif.Parent = screenGui

			task.delay(0.3, function()
				if not notif or not notif.Parent then return end
				local tween = TweenService:Create(notif, TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
					Position = notif.Position + UDim2.new(0, 0, -0.08, 0),
					TextTransparency = 1,
					TextStrokeTransparency = 1
				})
				tween:Play()
				tween.Completed:Connect(function()
					notif:Destroy()
				end)
			end)
		end
	end
end)

-- ===== FORWARD DECLARATIONS FOR UPDATE FUNCTIONS =====
-- These are needed because the functions are defined in do blocks but called from other do blocks
-- Note: update2xGamepassIndicator is defined at script level below (not in a do block)

-- ===== FORWARD DECLARATIONS FOR CROSS-BLOCK VARIABLES =====
-- These variables are used across multiple do blocks
local OWNED_PETS = {}

-- Panel module references are now handled by the modules themselves

-- ===== UPDATE FUNCTIONS (DEFINED AT SCRIPT LEVEL) =====
-- These functions are called from multiple do blocks, so they must be at script level
local animateCounter
local gamepassIndicator = nil
local update2xGamepassIndicator

-- Define update2xGamepassIndicator at script level (called from CURRENCY SYNC do block)
local gamepassXPIndicator = nil
local gamepassAutoClickIndicator = nil

update2xGamepassIndicator = function()
    if state.has2xGamepass then
        if not gamepassIndicator then
            -- Create indicator if it doesn't exist
            gamepassIndicator = Instance.new("Frame")
            gamepassIndicator.Name = "2xGamepassIndicator"
            gamepassIndicator.Size = UDim2.new(0, 120, 0, 28)
            gamepassIndicator.Position = UDim2.new(0, 10, 0, 80)
            gamepassIndicator.BackgroundColor3 = Color3.fromRGB(255, 200, 50)
            gamepassIndicator.BorderSizePixel = 0
            gamepassIndicator.Parent = screenGui
            createCorner(gamepassIndicator, 0.3)
            
            local stroke = Instance.new("UIStroke")
            stroke.Color = Color3.fromRGB(255, 150, 0)
            stroke.Thickness = 2
            stroke.Parent = gamepassIndicator
            
            local label = Instance.new("TextLabel")
            label.Size = UDim2.new(1, 0, 1, 0)
            label.BackgroundTransparency = 1
            label.Text = "✨ 2x Stardust"
            label.TextColor3 = Color3.new(0.1, 0.1, 0.1)
            label.TextSize = 14
            label.Font = Enum.Font.GothamBold
            label.Parent = gamepassIndicator
            
            -- Pulsing animation
            local pulseTween = TweenService:Create(gamepassIndicator, TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
                BackgroundColor3 = Color3.fromRGB(255, 220, 100)
            })
            pulseTween:Play()
        end
        gamepassIndicator.Visible = true
    else
        if gamepassIndicator then
            gamepassIndicator.Visible = false
        end
    end
end

-- Update 2x XP indicator
local update2xXPGamepassIndicator
update2xXPGamepassIndicator = function()
    if state.has2xXPGamepass then
        if not gamepassXPIndicator then
            -- Create indicator if it doesn't exist
            gamepassXPIndicator = Instance.new("Frame")
            gamepassXPIndicator.Name = "2xXPGamepassIndicator"
            gamepassXPIndicator.Size = UDim2.new(0, 100, 0, 28)
            gamepassXPIndicator.Position = UDim2.new(0, 10, 0, 115)
            gamepassXPIndicator.BackgroundColor3 = Color3.fromRGB(100, 200, 255)
            gamepassXPIndicator.BorderSizePixel = 0
            gamepassXPIndicator.Parent = screenGui
            createCorner(gamepassXPIndicator, 0.3)
            
            local stroke = Instance.new("UIStroke")
            stroke.Color = Color3.fromRGB(50, 150, 255)
            stroke.Thickness = 2
            stroke.Parent = gamepassXPIndicator
            
            local label = Instance.new("TextLabel")
            label.Size = UDim2.new(1, 0, 1, 0)
            label.BackgroundTransparency = 1
            label.Text = "⭐ 2x XP"
            label.TextColor3 = Color3.new(0.1, 0.1, 0.1)
            label.TextSize = 14
            label.Font = Enum.Font.GothamBold
            label.Parent = gamepassXPIndicator
            
            -- Pulsing animation
            local pulseTween = TweenService:Create(gamepassXPIndicator, TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
                BackgroundColor3 = Color3.fromRGB(150, 220, 255)
            })
            pulseTween:Play()
        end
        gamepassXPIndicator.Visible = true
    else
        if gamepassXPIndicator then
            gamepassXPIndicator.Visible = false
        end
    end
end

-- ===== BOOST INDICATORS =====
-- Track boost indicator frames for cleanup
local boostIndicators = {}

-- Update boost indicators display
local function updateBoostIndicators()
    -- Remove old indicators
    for _, indicator in pairs(boostIndicators) do
        if indicator then
            indicator:Destroy()
        end
    end
    boostIndicators = {}
    
    -- Create indicators for active boosts
    local yOffset = 185 -- Start below gamepass indicators
    
    for i, boost in ipairs(state.activeBoosts) do
        if boost.endTime and os.time() < boost.endTime then
            local remaining = boost.endTime - os.time()
            local minutes = math.floor(remaining / 60)
            local seconds = remaining % 60
            local timeStr = string.format("%d:%02d", minutes, seconds)
            
            local indicator = Instance.new("Frame")
            indicator.Name = "BoostIndicator_" .. boost.name
            indicator.Size = UDim2.new(0, 140, 0, 28)
            indicator.Position = UDim2.new(0, 10, 0, yOffset)
            indicator.BackgroundColor3 = Color3.fromRGB(100, 150, 255)
            indicator.BorderSizePixel = 0
            indicator.Parent = screenGui
            createCorner(indicator, 0.3)
            
            local stroke = Instance.new("UIStroke")
            stroke.Color = Color3.fromRGB(50, 100, 200)
            stroke.Thickness = 2
            stroke.Parent = indicator
            
            local label = Instance.new("TextLabel")
            label.Size = UDim2.new(1, -8, 1, 0)
            label.Position = UDim2.new(0, 4, 0, 0)
            label.BackgroundTransparency = 1
            
            -- Set emoji and text based on boost type
            local boostEmoji = "🧪"
            local boostText = boost.name
            if boost.name == "stardustBoost" then
                boostEmoji = "✨"
                boostText = "x" .. tostring(boost.multiplier) .. " Stardust"
            elseif boost.name == "clickBoost" then
                boostEmoji = "⚡"
                boostText = "x" .. tostring(boost.multiplier) .. " Clicks"
            elseif boost.name == "luckyBoost" then
                boostEmoji = "🍀"
                boostText = "+" .. tostring(math.floor((boost.multiplier - 1) * 100)) .. "% Lucky"
            elseif boost.name == "xpBoost" then
                boostEmoji = "📚"
                boostText = "x" .. tostring(boost.multiplier) .. " XP"
            end
            
            label.Text = boostEmoji .. " " .. boostText .. " (" .. timeStr .. ")"
            label.TextColor3 = Color3.new(1, 1, 1)
            label.TextSize = 12
            label.Font = Enum.Font.GothamBold
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.Parent = indicator
            
            -- Pulsing animation
            local pulseTween = TweenService:Create(indicator, TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
                BackgroundColor3 = Color3.fromRGB(130, 180, 255)
            })
            pulseTween:Play()
            
            table.insert(boostIndicators, indicator)
            yOffset = yOffset + 35
        end
    end
end

-- Timer update loop for boost indicators
task.spawn(function()
    while true do
        task.wait(1)
        -- Update boost indicators every second
        if #state.activeBoosts > 0 then
            -- Clean up expired boosts
            local now = os.time()
            local hasActiveBoosts = false
            for i = #state.activeBoosts, 1, -1 do
                local boost = state.activeBoosts[i]
                if boost.endTime and now >= boost.endTime then
                    table.remove(state.activeBoosts, i)
                else
                    hasActiveBoosts = true
                end
            end
            if hasActiveBoosts then
                updateBoostIndicators()
            else
                -- All boosts expired, clear indicators
                for _, indicator in pairs(boostIndicators) do
                    if indicator then indicator:Destroy() end
                end
                boostIndicators = {}
            end
        end
    end
end)

-- Update AutoClick gamepass indicator
local updateAutoClickGamepassIndicator
updateAutoClickGamepassIndicator = function()
    if state.hasAutoClickStarGamepass then
        if not gamepassAutoClickIndicator then
            -- Create indicator if it doesn't exist
            gamepassAutoClickIndicator = Instance.new("Frame")
            gamepassAutoClickIndicator.Name = "AutoClickGamepassIndicator"
            gamepassAutoClickIndicator.Size = UDim2.new(0, 130, 0, 28)
            gamepassAutoClickIndicator.Position = UDim2.new(0, 10, 0, 150)
            gamepassAutoClickIndicator.BackgroundColor3 = Color3.fromRGB(100, 200, 100)
            gamepassAutoClickIndicator.BorderSizePixel = 0
            gamepassAutoClickIndicator.Parent = screenGui
            createCorner(gamepassAutoClickIndicator, 0.3)
            
            local stroke = Instance.new("UIStroke")
            stroke.Color = Color3.fromRGB(50, 150, 50)
            stroke.Thickness = 2
            stroke.Parent = gamepassAutoClickIndicator
            
            local label = Instance.new("TextLabel")
            label.Size = UDim2.new(1, 0, 1, 0)
            label.BackgroundTransparency = 1
            label.Text = "🔄 AutoClick 2x"
            label.TextColor3 = Color3.new(0.1, 0.1, 0.1)
            label.TextSize = 14
            label.Font = Enum.Font.GothamBold
            label.Parent = gamepassAutoClickIndicator
            
            -- Pulsing animation
            local pulseTween = TweenService:Create(gamepassAutoClickIndicator, TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
                BackgroundColor3 = Color3.fromRGB(150, 230, 150)
            })
            pulseTween:Play()
        end
        gamepassAutoClickIndicator.Visible = true
        
        -- Notify AutoClickPanel module
        AutoClickPanel.setGamepassStatus(true)
    else
        if gamepassAutoClickIndicator then
            gamepassAutoClickIndicator.Visible = false
        end
    end
end

updateStardust = function(amount)
    local oldValue = state.stardust or 0
    state.stardust = amount
    
    -- Animar se aumentou
    if amount > oldValue and stardustLabel then
        animateCounter(stardustLabel, oldValue, amount, "✨", 0.5)
    else
        stardustLabel.Text = "✨ " .. Style.abbreviateNumber(amount)
    end
    
    -- Update SellPanel
    SellPanel.update(amount)
end

updateStarcoins = function(amount)
    local oldValue = state.starcoins or 0
    state.starcoins = amount
    
    -- Animar se aumentou
    if amount > oldValue and starcoinsLabel then
        animateCounter(starcoinsLabel, oldValue, amount, "🌙", 0.5)
    else
        starcoinsLabel.Text = "🌙 " .. Style.abbreviateNumber(amount)
    end
end

local activeXPTween = nil

updateLevel = function(level, xp, xpNeeded)
    local oldLevel = state.level or 1
    local oldXp = state.xp or 0
    local oldXpNeeded = state.xpNeeded or 100
    
    state.level = level
    state.xp = xp
    state.xpNeeded = xpNeeded
    
    -- Animar barra de XP
    if xpBarFill then
        local newSize = math.clamp(xp / xpNeeded, 0, 1)
        
        -- Cancelar tween anterior se existir
        if activeXPTween then
            activeXPTween:Cancel()
            activeXPTween = nil
        end
        
        -- Se subiu de nível, fazer animação especial
        if level > oldLevel then
            -- Animar até 100%, depois resetar
            local tween1 = TweenService:Create(xpBarFill, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Size = UDim2.new(1, 0, 1, 0)
            })
            activeXPTween = tween1
            tween1:Play()
            
            tween1.Completed:Connect(function()
                if activeXPTween == tween1 then
                    activeXPTween = nil
                end
                
                -- Flash no level
                if levelLabel then
                    levelLabel.Text = "⭐ Lv. " .. tostring(level)
                    -- Efeito de "pop"
                    local originalSize = levelLabel.TextSize
                    levelLabel.TextSize = originalSize + 8
                    local shrinkTween = TweenService:Create(levelLabel, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                        TextSize = originalSize
                    })
                    shrinkTween:Play()
                end
                
                -- Resetar barra para novo nível
                xpBarFill.Size = UDim2.new(0, 0, 1, 0)
                
                local tween2 = TweenService:Create(xpBarFill, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                    Size = UDim2.new(newSize, 0, 1, 0)
                })
                activeXPTween = tween2
                tween2:Play()
                
                tween2.Completed:Connect(function()
                    if activeXPTween == tween2 then
                        activeXPTween = nil
                    end
                end)
            end)
        else
            -- Animação normal de XP
            local tween = TweenService:Create(xpBarFill, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Size = UDim2.new(newSize, 0, 1, 0)
            })
            activeXPTween = tween
            tween:Play()
            
            tween.Completed:Connect(function()
                if activeXPTween == tween then
                    activeXPTween = nil
                end
            end)
        end
    end
    
    -- Atualizar label do level
    if levelLabel then
        levelLabel.Text = "⭐ Lv. " .. tostring(level)
    end
end

-- Animated counter function
animateCounter = function(label, startValue, endValue, prefix, duration)
    -- Se os valores são iguais, só atualiza
    if startValue == endValue then
        label.Text = prefix .. " " .. Style.abbreviateNumber(endValue)
        return
    end
    
    duration = duration or 0.4
    local startTime = tick()
    local difference = endValue - startValue
    
    -- Usar task.spawn para não travar
    task.spawn(function()
        while tick() - startTime < duration do
            local progress = (tick() - startTime) / duration
            -- Easing suave (ease-out)
            progress = 1 - (1 - progress) * (1 - progress)
            
            local currentValue = math.floor(startValue + difference * progress)
            label.Text = prefix .. " " .. Style.abbreviateNumber(currentValue)
            
            task.wait(0.03)
        end
        
        -- Garantir valor final
        label.Text = prefix .. " " .. Style.abbreviateNumber(endValue)
    end)
end

-- ===== CENTRAL STAR BUTTON =====
-- Handle clicks on the central star button
local starButton = screenGui:FindFirstChild("StarButton")
if starButton then
    -- Click debounce to prevent spam
    local lastStarClick = 0
    local starClickCooldown = 0.1 -- 100ms between clicks
    
    starButton.MouseButton1Click:Connect(function()
        local now = tick()
        if now - lastStarClick < starClickCooldown then
            return -- Debounce: too soon
        end
        lastStarClick = now
        
        -- Send click to server
        safeFireServer("click")
        
        -- Visual feedback: scale down and up
        local originalSize = starButton.Size
        starButton.Size = UDim2.new(0, 100, 0, 100)
        local tween = TweenService:Create(starButton, TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = originalSize})
        tween:Play()
        
        -- TUTORIAL: Track click progress
        TutorialPanel.updateProgress("click", 1)
    end)
    
    print("[StardustGUI] StarButton click handler connected")
end

-- ===== AUTOCLICK PANEL =====
-- AutoClick panel is now handled by AutoClickPanel module
AutoClickPanel.create(screenGui)

-- ===== BOTTOM BUTTONS =====
do
local buttonContainer = screenGui:FindFirstChild("BottomBar") and screenGui:FindFirstChild("BottomBar"):FindFirstChild("ButtonContainer")
if buttonContainer then
    for _, btnData in ipairs(BUTTONS) do
        local btnFrame = buttonContainer:FindFirstChild(btnData.name .. "Btn")
        if btnFrame then
            local stroke = btnFrame:FindFirstChildOfClass("UIStroke")
            local clickDetector = btnFrame:FindFirstChild("ClickDetector")
            
            if clickDetector then
                setupButtonEffects(clickDetector)
                
                clickDetector.MouseButton1Click:Connect(function()
                    local panel = screenGui:FindFirstChild(btnData.panel)
                    if panel then
                        -- Use PanelManager to toggle panel (this syncs state)
                        PanelManager.togglePanel(panel, stroke)
                    end
                end)
            end
            
            if not state.buttonInstances then
                state.buttonInstances = {}
            end
            state.buttonInstances[btnData.name] = {frame = btnFrame, stroke = stroke}
        end
    end
end
end -- End of BOTTOM BUTTONS do block

-- ===== SHOP PANEL =====
-- Shop panel is now handled by ShopPanel module
ShopPanel.create(screenGui)

-- ===== SELL PANEL =====
-- Sell panel is now handled by SellPanel module
SellPanel.create(screenGui, state)

-- ===== UPGRADES PANEL =====
-- Upgrades panel is now handled by UpgradesPanel module
UpgradesPanel.create(screenGui)

-- ===== INVENTORY PANEL =====
-- Inventory panel is now handled by InventoryPanel module
InventoryPanel.create(screenGui)

-- ===== EGGS PANEL =====
-- Eggs panel is now handled by EggsPanel module
EggsPanel.create(screenGui)

-- ===== PETS PANEL =====
-- Pets panel is now handled by PetsPanel module
PetsPanel.create(screenGui)

-- ===== SUPERNOVA PANEL =====
-- Supernova panel is now handled by SupernovaPanel module
SupernovaPanel.create(screenGui)

-- ===== WORLDS PANEL =====
-- Worlds panel is now handled by WorldsPanel module
WorldsPanel.create(screenGui)

-- ===== QUESTS PANEL =====
-- Quests panel is now handled by QuestsPanel module
QuestsPanel.create(screenGui)

-- ===== DAILY REWARD PANEL =====
-- Daily Reward panel is now handled by DailyRewardPanel module
DailyRewardPanel.create(screenGui)

-- ===== SETTINGS PANEL =====
-- Settings panel is now handled by SettingsPanel module
SettingsPanel.create(screenGui)

-- ===== CURRENCY SYNC =====
local lastPetSyncTime = 0
do
local stardustSync = ReplicatedStorage:FindFirstChild("StardustSync")
if stardustSync then
    stardustSync.OnClientEvent:Connect(function(stardust, starcoins, level, xp, xpNeeded, ownedPets, equippedPets, dailyRewardData, supernovaInfo, upgradesData)
        if stardust then
            updateStardust(stardust)
        end
        if starcoins then
            updateStarcoins(starcoins)
        end
        if level and xp and xpNeeded then
            updateLevel(level, xp, xpNeeded)
        end
        
        -- Only update pets from StardustSync if enough time has passed (throttle to avoid race with petEquipped)
        -- and only if we have valid data
        local now = tick()
        if ownedPets and #ownedPets > 0 and equippedPets and (now - lastPetSyncTime) > 2 then
            lastPetSyncTime = now
            
            -- Filter out nil values from the pet list
            OWNED_PETS = {}
            for _, pet in ipairs(ownedPets) do
                if pet and pet.name then
                    table.insert(OWNED_PETS, pet)
                end
            end
            -- Mark equipped status based on equippedPets
            for _, pet in ipairs(OWNED_PETS) do
                if pet then
                    pet.equipped = false
                    for _, equippedId in ipairs(equippedPets) do
                        if pet.id == equippedId then
                            pet.equipped = true
                            break
                        end
                    end
                end
            end
            
            -- Update pets panel via module
            PetsPanel.setPets(OWNED_PETS, equippedPets)
            print("[Client] Received " .. #OWNED_PETS .. " pets from server")
            
            -- Calculate and update pet income rate
            local PET_MULTIPLIERS = {
                ["Common"] = 1,
                ["Raro"] = 2,
                ["Epico"] = 5,
                ["Lendario"] = 10,
                ["Especial"] = 15,
                ["Supernova"] = 25
            }
            local syncTotalMult = 0
            for _, equippedId in ipairs(equippedPets or {}) do
                for _, pet in ipairs(OWNED_PETS) do
                    if pet.id == equippedId then
                        syncTotalMult = syncTotalMult + (PET_MULTIPLIERS[pet.rarity] or 1)
                    end
                end
            end
            updatePetIncomeLabel(syncTotalMult)
        end
        
        if upgradesData then
            UpgradesPanel.updateLevels(upgradesData)
        end
        
        if dailyRewardData then
            playerDailyRewardData = dailyRewardData
            DailyRewardPanel.update(dailyRewardData)
            print("[Client] Received daily reward data: Day " .. tostring(dailyRewardData.currentDay))
        end
        
        if supernovaInfo then
            supernovaData = supernovaInfo
            SupernovaPanel.update(supernovaInfo)
            print("[Client] Received supernova data: Count " .. tostring(supernovaInfo.count) .. ", Multiplier " .. tostring(supernovaInfo.multiplier) .. "x")
        end
    end)
end
-- ===== GAME ACTION RESPONSES =====
gameActionRemote.OnClientEvent:Connect(function(action, ...)
    local args = {...}
    
    if action == "petEquipped" then
        local equippedPets = args[1]
        local totalMult = args[2]
        local serverOwnedPets = args[3]
        
        print("[StardustGUI] petEquipped received - equippedPets:", equippedPets and #equippedPets or 0, "serverOwnedPets:", serverOwnedPets and #serverOwnedPets or 0)
        
        -- Update pet income label
        updatePetIncomeLabel(totalMult)
        
        -- Always rebuild OWNED_PETS from server data to avoid duplication
        if serverOwnedPets and #serverOwnedPets > 0 then
            OWNED_PETS = {}
            for _, pet in ipairs(serverOwnedPets) do
                if pet and pet.name then
                    table.insert(OWNED_PETS, pet)
                end
            end
        end
        
        -- Sync equipped status from equippedPets list
        for _, pet in ipairs(OWNED_PETS) do
            if pet then
                pet.equipped = false
                for _, equippedId in ipairs(equippedPets or {}) do
                    if pet.id == equippedId then
                        pet.equipped = true
                        break
                    end
                end
            end
        end
        
        -- Update pets panel via module
        PetsPanel.setPets(OWNED_PETS, equippedPets)
        print("[Pets] Updated equipped pets:", table.concat(equippedPets or {}, ", "))
        
        -- Mark last pet sync time so StardustSync doesn't overwrite this immediately
        lastPetSyncTime = tick()
        
        -- TUTORIAL: Track pet equip progress
        TutorialPanel.updateProgress("equipPet", 1)
        
    elseif action == "eggPurchased" then
        local eggName = args[1]
        local quantity = args[2]
        local hatchedPets = args[3] -- Agora é uma lista de pets
        
        if hatchedPets and type(hatchedPets) ~= "table" then
            hatchedPets = {hatchedPets}
        end
        
        print("[Eggs] Purchased:", eggName, "x" .. tostring(quantity), "Pets:", hatchedPets and #hatchedPets or 0)
        
        if hatchedPets then
            -- Don't manually add pets here - the server's syncToClient will send the updated ownedPets
            -- Just update the UI with the hatched pets info for display purposes
            
            -- Update pets panel - keep current equipped state
            local currentEquippedIds = {}
            for _, pet in ipairs(OWNED_PETS) do
                if pet and pet.equipped and pet.id then
                    table.insert(currentEquippedIds, pet.id)
                end
            end
            PetsPanel.setPets(OWNED_PETS, currentEquippedIds)
        end
        
        -- Shake the 3D egg model in workspace
        EggsPanel.shakeEggModel(eggName)
        
        -- Show egg opening popup via module (EggOverlay handles hiding/showing panels)
        if hatchedPets and #hatchedPets > 0 then
            EggsPanel.showPopup(screenGui, eggName, hatchedPets)
        end
        
        -- TUTORIAL: Track egg hatching progress
        TutorialPanel.updateProgress("hatchEgg", 1)
        
    elseif action == "upgradePurchased" then
        local upgradeName = args[1]
        local newLevel = args[2]
        print("[Upgrades] Purchased:", upgradeName, "Level:", newLevel)
        
        -- Update the upgrade level via module
        UpgradesPanel.updateLevels({[upgradeName] = newLevel})
        
    elseif action == "nightStatus" then
        local isNight = args[1]
        print("[Night] Night status:", isNight and "Night" or "Day")
        
    elseif action == "dailyRewardClaimed" then
        local dayClaimed = args[1]
        local rewardAmount = args[2]
        local multiplier = args[3]
        
        print("[Client] dailyRewardClaimed event received! Day: " .. tostring(dayClaimed) .. ", Reward: " .. tostring(rewardAmount) .. ", Multiplier: x" .. tostring(multiplier))
        
        -- Validate arguments
        if not dayClaimed then
            warn("[Client] dailyRewardClaimed received nil dayClaimed")
            return
        end
        
        -- Notify the DailyRewardPanel module that claim succeeded
        DailyRewardPanel.notifyClaimSuccess(dayClaimed, rewardAmount, multiplier)
        print("[DailyReward] Claimed day " .. tostring(dayClaimed) .. ": " .. tostring(rewardAmount) .. " Stardust (x" .. tostring(multiplier) .. ")")
        
    elseif action == "dailyRewardAlreadyClaimed" then
        -- Player already claimed today
        DailyRewardPanel.notifyAlreadyClaimed()
        print("[DailyReward] Already claimed today")
        
    elseif action == "clickEarned" then
        -- Server sent back the actual amount earned
        local amount = args[1] or 1
        local inBonusZone = args[2] or false
        local has2xGamepassNow = args[3] or false
        local has2xXPGamepassNow = args[4] or false
        local hasAutoClickStarGamepassNow = args[5] or false
        
        -- Update 2x Stardust gamepass indicator
        if has2xGamepassNow ~= state.has2xGamepass then
            state.has2xGamepass = has2xGamepassNow
            update2xGamepassIndicator()
        end
        
        -- Update 2x XP gamepass indicator
        if has2xXPGamepassNow ~= state.has2xXPGamepass then
            state.has2xXPGamepass = has2xXPGamepassNow
            update2xXPGamepassIndicator()
        end
        
        -- Update AutoClick gamepass indicator
        if hasAutoClickStarGamepassNow ~= state.hasAutoClickStarGamepass then
            state.hasAutoClickStarGamepass = hasAutoClickStarGamepassNow
            updateAutoClickGamepassIndicator()
        end
        
        -- Show click earned notification (inline for now)
        if shouldShowNotifications() then
            local clickNotif = Instance.new("TextLabel")
            clickNotif.Name = "ClickEarned"
            clickNotif.Size = UDim2.new(0, 200, 0, 50)
            local randomX = math.random(-60, 60)
            clickNotif.Position = UDim2.new(0.5, -100 + randomX, 0.4, 0)
            clickNotif.BackgroundTransparency = 1
            clickNotif.Text = "+" .. tostring(amount) .. " ✨"
            clickNotif.TextColor3 = inBonusZone and Color3.fromRGB(100, 255, 100) or Color3.new(1, 1, 1)
            clickNotif.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
            clickNotif.TextStrokeTransparency = 0.5
            clickNotif.TextSize = 28
            clickNotif.Font = Enum.Font.GothamBold
            clickNotif.ZIndex = 200
            clickNotif.Parent = screenGui
            
            -- Animação: flutuar pra cima e sumir
            local tween = TweenService:Create(clickNotif, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Position = clickNotif.Position + UDim2.new(0, 0, -0.08, 0),
                TextTransparency = 1,
                TextStrokeTransparency = 1
            })
            tween:Play()
            tween.Completed:Connect(function()
                clickNotif:Destroy()
            end)
        end
        
        -- TUTORIAL: Track click progress
        TutorialPanel.updateProgress("click", 1)
    
    elseif action == "gamepassPurchased" then
        -- Player purchased a gamepass
        local gamepassName = args[1]
        if gamepassName == "2x Stardust" then
            state.has2xGamepass = true
            update2xGamepassIndicator()
            
            -- Show notification
            if shouldShowNotifications() then
                local notif = Instance.new("Frame")
                notif.Name = "GamepassNotif"
                notif.Size = UDim2.new(0, 300, 0, 80)
                notif.Position = UDim2.new(0.5, -150, 0.3, 0)
                notif.BackgroundColor3 = Color3.fromRGB(40, 50, 40)
                notif.BorderSizePixel = 0
                notif.ZIndex = 500
                notif.Parent = screenGui
                createCorner(notif, 0.15)
                createStroke(notif, Color3.fromRGB(100, 200, 100), 2)
                
                local icon = Instance.new("TextLabel")
                icon.Size = UDim2.new(0, 50, 0, 50)
                icon.Position = UDim2.new(0, 15, 0.5, -25)
                icon.BackgroundTransparency = 1
                icon.Text = "✨"
                icon.TextSize = 36
                icon.Font = Enum.Font.GothamBold
                icon.Parent = notif
                
                local title = Instance.new("TextLabel")
                title.Size = UDim2.new(1, -80, 0, 30)
                title.Position = UDim2.new(0, 70, 0, 10)
                title.BackgroundTransparency = 1
                title.Text = "2x Stardust Ativado!"
                title.TextColor3 = Color3.fromRGB(100, 255, 100)
                title.TextSize = 16
                title.Font = Enum.Font.GothamBold
                title.TextXAlignment = Enum.TextXAlignment.Left
                title.Parent = notif
                
                local desc = Instance.new("TextLabel")
                desc.Size = UDim2.new(1, -80, 0, 30)
                desc.Position = UDim2.new(0, 70, 0, 40)
                desc.BackgroundTransparency = 1
                desc.Text = "Dobre todo Stardust ganho!"
                desc.TextColor3 = Color3.fromRGB(200, 200, 200)
                desc.TextSize = 12
                desc.Font = Enum.Font.GothamSemibold
                desc.TextXAlignment = Enum.TextXAlignment.Left
                desc.Parent = notif
                
                task.delay(3, function()
                    local tweenOut = TweenService:Create(notif, TweenInfo.new(0.3), {BackgroundTransparency = 1})
                    tweenOut:Play()
                    tweenOut.Completed:Connect(function()
                        notif:Destroy()
                    end)
                end)
            end
            
        elseif gamepassName == "3+ Pets" then
            -- Show notification
            if shouldShowNotifications() then
                local notif = Instance.new("Frame")
                notif.Name = "GamepassNotif"
                notif.Size = UDim2.new(0, 300, 0, 80)
                notif.Position = UDim2.new(0.5, -150, 0.3, 0)
                notif.BackgroundColor3 = Color3.fromRGB(40, 50, 40)
                notif.BorderSizePixel = 0
                notif.ZIndex = 500
                notif.Parent = screenGui
                createCorner(notif, 0.15)
                createStroke(notif, Color3.fromRGB(100, 200, 100), 2)
                
                local icon = Instance.new("TextLabel")
                icon.Size = UDim2.new(0, 50, 0, 50)
                icon.Position = UDim2.new(0, 15, 0.5, -25)
                icon.BackgroundTransparency = 1
                icon.Text = "🐾"
                icon.TextSize = 36
                icon.Font = Enum.Font.GothamBold
                icon.Parent = notif
                
                local title = Instance.new("TextLabel")
                title.Size = UDim2.new(1, -80, 0, 30)
                title.Position = UDim2.new(0, 70, 0, 10)
                title.BackgroundTransparency = 1
                title.Text = "3+ Pets Ativado!"
                title.TextColor3 = Color3.fromRGB(100, 255, 100)
                title.TextSize = 16
                title.Font = Enum.Font.GothamBold
                title.TextXAlignment = Enum.TextXAlignment.Left
                title.Parent = notif
                
                local desc = Instance.new("TextLabel")
                desc.Size = UDim2.new(1, -80, 0, 30)
                desc.Position = UDim2.new(0, 70, 0, 40)
                desc.BackgroundTransparency = 1
                desc.Text = "Equipe até 6 pets de uma vez!"
                desc.TextColor3 = Color3.fromRGB(200, 200, 200)
                desc.TextSize = 12
                desc.Font = Enum.Font.GothamSemibold
                desc.TextXAlignment = Enum.TextXAlignment.Left
                desc.Parent = notif
                
                task.delay(3, function()
                    local tweenOut = TweenService:Create(notif, TweenInfo.new(0.3), {BackgroundTransparency = 1})
                    tweenOut:Play()
                    tweenOut.Completed:Connect(function()
                        notif:Destroy()
                    end)
                end)
            end
        
        elseif gamepassName == "2x XP" then
            state.has2xXPGamepass = true
            update2xXPGamepassIndicator()
            
            -- Show notification
            if shouldShowNotifications() then
                local notif = Instance.new("Frame")
                notif.Name = "GamepassNotif"
                notif.Size = UDim2.new(0, 300, 0, 80)
                notif.Position = UDim2.new(0.5, -150, 0.3, 0)
                notif.BackgroundColor3 = Color3.fromRGB(40, 50, 40)
                notif.BorderSizePixel = 0
                notif.ZIndex = 500
                notif.Parent = screenGui
                createCorner(notif, 0.15)
                createStroke(notif, Color3.fromRGB(100, 200, 100), 2)
                
                local icon = Instance.new("TextLabel")
                icon.Size = UDim2.new(0, 50, 0, 50)
                icon.Position = UDim2.new(0, 15, 0.5, -25)
                icon.BackgroundTransparency = 1
                icon.Text = "⭐"
                icon.TextSize = 36
                icon.Font = Enum.Font.GothamBold
                icon.Parent = notif
                
                local title = Instance.new("TextLabel")
                title.Size = UDim2.new(1, -80, 0, 30)
                title.Position = UDim2.new(0, 70, 0, 10)
                title.BackgroundTransparency = 1
                title.Text = "2x XP Ativado!"
                title.TextColor3 = Color3.fromRGB(100, 255, 100)
                title.TextSize = 16
                title.Font = Enum.Font.GothamBold
                title.TextXAlignment = Enum.TextXAlignment.Left
                title.Parent = notif
                
                local desc = Instance.new("TextLabel")
                desc.Size = UDim2.new(1, -80, 0, 30)
                desc.Position = UDim2.new(0, 70, 0, 40)
                desc.BackgroundTransparency = 1
                desc.Text = "Dobre todo XP ganho!"
                desc.TextColor3 = Color3.fromRGB(200, 200, 200)
                desc.TextSize = 12
                desc.Font = Enum.Font.GothamSemibold
                desc.TextXAlignment = Enum.TextXAlignment.Left
                desc.Parent = notif
                
                task.delay(3, function()
                    local tweenOut = TweenService:Create(notif, TweenInfo.new(0.3), {BackgroundTransparency = 1})
                    tweenOut:Play()
                    tweenOut.Completed:Connect(function()
                        notif:Destroy()
                    end)
                end)
            end
        
        elseif gamepassName == "Auto Click Star" then
            state.hasAutoClickStarGamepass = true
            updateAutoClickGamepassIndicator()
            
            -- Show notification
            if shouldShowNotifications() then
                local notif = Instance.new("Frame")
                notif.Name = "GamepassNotif"
                notif.Size = UDim2.new(0, 300, 0, 80)
                notif.Position = UDim2.new(0.5, -150, 0.3, 0)
                notif.BackgroundColor3 = Color3.fromRGB(40, 50, 40)
                notif.BorderSizePixel = 0
                notif.ZIndex = 500
                notif.Parent = screenGui
                createCorner(notif, 0.15)
                createStroke(notif, Color3.fromRGB(100, 200, 100), 2)
                
                local icon = Instance.new("TextLabel")
                icon.Size = UDim2.new(0, 50, 0, 50)
                icon.Position = UDim2.new(0, 15, 0.5, -25)
                icon.BackgroundTransparency = 1
                icon.Text = "🔄"
                icon.TextSize = 36
                icon.Font = Enum.Font.GothamBold
                icon.Parent = notif
                
                local title = Instance.new("TextLabel")
                title.Size = UDim2.new(1, -80, 0, 30)
                title.Position = UDim2.new(0, 70, 0, 10)
                title.BackgroundTransparency = 1
                title.Text = "Auto Click Star Ativado!"
                title.TextColor3 = Color3.fromRGB(100, 255, 100)
                title.TextSize = 16
                title.Font = Enum.Font.GothamBold
                title.TextXAlignment = Enum.TextXAlignment.Left
                title.Parent = notif
                
                local desc = Instance.new("TextLabel")
                desc.Size = UDim2.new(1, -80, 0, 30)
                desc.Position = UDim2.new(0, 70, 0, 40)
                desc.BackgroundTransparency = 1
                desc.Text = "AutoClick 2x mais rápido!"
                desc.TextColor3 = Color3.fromRGB(200, 200, 200)
                desc.TextSize = 12
                desc.Font = Enum.Font.GothamSemibold
                desc.TextXAlignment = Enum.TextXAlignment.Left
                desc.Parent = notif
                
                task.delay(3, function()
                    local tweenOut = TweenService:Create(notif, TweenInfo.new(0.3), {BackgroundTransparency = 1})
                    tweenOut:Play()
                    tweenOut.Completed:Connect(function()
                        notif:Destroy()
                    end)
                end)
            end
        end
        
    elseif action == "insufficientFunds" then
        -- Player doesn't have enough currency
        local currencyType = args[1] or "Stardust"
        local required = args[2] or 0
        local current = args[3] or 0
        
        -- Create beautiful notification
        if shouldShowNotifications() then
        local notifBg = Instance.new("Frame")
        notifBg.Name = "InsufficientFundsNotif"
        notifBg.Size = UDim2.new(0, 320, 0, 100)
        notifBg.Position = UDim2.new(0.5, -160, 0.35, 0)
        notifBg.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
        notifBg.BorderSizePixel = 0
        notifBg.Parent = screenGui
        
        local notifCorner = Instance.new("UICorner")
        notifCorner.CornerRadius = UDim.new(0, 16)
        notifCorner.Parent = notifBg
        
        -- Red accent border
        local notifStroke = Instance.new("UIStroke")
        notifStroke.Color = Color3.fromRGB(220, 60, 60)
        notifStroke.Thickness = 3
        notifStroke.Parent = notifBg
        
        -- Icon
        local icon = Instance.new("TextLabel")
        icon.Size = UDim2.new(0, 50, 0, 50)
        icon.Position = UDim2.new(0, 15, 0.5, -25)
        icon.BackgroundTransparency = 1
        icon.Text = "⚠️"
        icon.TextSize = 36
        icon.Font = Enum.Font.GothamBold
        icon.Parent = notifBg
        
        -- Title
        local title = Instance.new("TextLabel")
        title.Size = UDim2.new(1, -80, 0, 30)
        title.Position = UDim2.new(0, 70, 0, 15)
        title.BackgroundTransparency = 1
        title.Text = currencyType .. " Insuficiente"
        title.TextColor3 = Color3.fromRGB(255, 100, 100)
        title.TextSize = 18
        title.Font = Enum.Font.GothamBold
        title.TextXAlignment = Enum.TextXAlignment.Left
        title.Parent = notifBg
        
        -- Details
        local details = Instance.new("TextLabel")
        details.Size = UDim2.new(1, -80, 0, 40)
        details.Position = UDim2.new(0, 70, 0, 45)
        details.BackgroundTransparency = 1
        details.Text = "Precisa: " .. required .. "\nVocê tem: " .. current
        details.TextColor3 = Color3.fromRGB(200, 200, 200)
        details.TextSize = 14
        details.Font = Enum.Font.GothamSemibold
        details.TextXAlignment = Enum.TextXAlignment.Left
        details.TextYAlignment = Enum.TextYAlignment.Top
        details.Parent = notifBg
        
        -- Animate in
        notifBg.Size = UDim2.new(0, 0, 0, 100)
        local tweenService = game:GetService("TweenService")
        local tweenIn = tweenService:Create(notifBg, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = UDim2.new(0, 320, 0, 100)})
        tweenIn:Play()
        
        -- Fade out and remove after 3 seconds
        task.delay(3, function()
            local tweenOut = tweenService:Create(notifBg, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Size = UDim2.new(0, 0, 0, 100), BackgroundTransparency = 1})
            tweenOut:Play()
            tweenOut.Completed:Wait()
            notifBg:Destroy()
        end)
        
        end -- end notifications check
        print("[Client] Insufficient funds: needs " .. required .. " " .. currencyType .. ", has " .. current)
    
    elseif action == "supernovaSuccess" then
        -- Supernova was successful!
        local count = args[1] or 0
        local tokensEarned = args[2] or 0
        local newMultiplier = args[3] or 1.0
        
        -- Create celebration popup
        local celebrationBg = Instance.new("Frame")
        celebrationBg.Name = "SupernovaCelebration"
        celebrationBg.Size = UDim2.new(1, 0, 1, 0)
        celebrationBg.Position = UDim2.new(0, 0, 0, 0)
        celebrationBg.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        celebrationBg.BackgroundTransparency = 0.3
        celebrationBg.ZIndex = 500
        celebrationBg.Parent = screenGui
        
        local celebrationContainer = Instance.new("Frame")
        celebrationContainer.Size = UDim2.new(0, 350, 0, 280)
        celebrationContainer.Position = UDim2.new(0.5, -175, 0.5, -140)
        celebrationContainer.BackgroundColor3 = COLORS.MAIN_BG
        celebrationContainer.BorderSizePixel = 0
        celebrationContainer.Parent = celebrationBg
        createCorner(celebrationContainer, 0.1)
        createStroke(celebrationContainer, Color3.fromRGB(255, 200, 50), 3)
        
        local celebEmoji = Instance.new("TextLabel")
        celebEmoji.Size = UDim2.new(1, 0, 0, 80)
        celebEmoji.Position = UDim2.new(0, 0, 0, 20)
        celebEmoji.BackgroundTransparency = 1
        celebEmoji.Text = "💥✨💥"
        celebEmoji.TextSize = 60
        celebEmoji.Font = Enum.Font.GothamBold
        celebEmoji.Parent = celebrationContainer
        
        local celebTitle = Instance.new("TextLabel")
        celebTitle.Size = UDim2.new(1, 0, 0, 40)
        celebTitle.Position = UDim2.new(0, 0, 0, 100)
        celebTitle.BackgroundTransparency = 1
        celebTitle.Text = "SUPERNOVA!"
        celebTitle.TextColor3 = Color3.fromRGB(255, 200, 50)
        celebTitle.TextSize = 32
        celebTitle.Font = Enum.Font.GothamBold
        celebTitle.Parent = celebrationContainer
        
        local celebStats = Instance.new("TextLabel")
        celebStats.Size = UDim2.new(1, -32, 0, 80)
        celebStats.Position = UDim2.new(0, 16, 0, 145)
        celebStats.BackgroundTransparency = 1
        celebStats.Text = "Supernova #" .. tostring(count) .. "\n+" .. tostring(tokensEarned) .. " Tokens\nNew Multiplier: " .. string.format("%.1fx", newMultiplier)
        celebStats.TextColor3 = COLORS.TITLE_TEXT
        celebStats.TextSize = 18
        celebStats.Font = Enum.Font.GothamSemibold
        celebStats.TextWrapped = true
        celebStats.Parent = celebrationContainer
        
        local celebCloseBtn = Instance.new("TextButton")
        celebCloseBtn.Size = UDim2.new(1, -32, 0, 44)
        celebCloseBtn.Position = UDim2.new(0, 16, 1, -56)
        celebCloseBtn.BackgroundColor3 = COLORS.BUTTON_BG
        celebCloseBtn.BorderSizePixel = 0
        celebCloseBtn.Text = "🎉 Awesome!"
        celebCloseBtn.TextColor3 = COLORS.TITLE_TEXT
        celebCloseBtn.TextSize = 18
        celebCloseBtn.Font = Enum.Font.GothamBold
        celebCloseBtn.Parent = celebrationContainer
        createCorner(celebCloseBtn, 0.15)
        setupButtonEffects(celebCloseBtn)
        
        celebCloseBtn.MouseButton1Click:Connect(function()
            celebrationBg:Destroy()
        end)
        
        -- Animate in
        celebrationContainer.Size = UDim2.new(0, 0, 0, 0)
        local tweenIn = TweenService:Create(celebrationContainer, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = UDim2.new(0, 350, 0, 280)})
        tweenIn:Play()
        
        print("[Supernova] Success! Count: " .. tostring(count) .. ", Tokens: " .. tostring(tokensEarned) .. ", Multiplier: " .. tostring(newMultiplier))
        
    elseif action == "supernovaFailed" then
        -- Supernova failed (not enough total earned)
        local message = args[1] or "Cannot go Supernova yet!"
        
        -- Show error notification
        if shouldShowNotifications() then
        local errorNotif = Instance.new("Frame")
        errorNotif.Name = "SupernovaError"
        errorNotif.Size = UDim2.new(0, 300, 0, 80)
        errorNotif.Position = UDim2.new(0.5, -150, 0.4, 0)
        errorNotif.BackgroundColor3 = Color3.fromRGB(60, 40, 40)
        errorNotif.BorderSizePixel = 0
        errorNotif.ZIndex = 500
        errorNotif.Parent = screenGui
        createCorner(errorNotif, 0.15)
        createStroke(errorNotif, Color3.fromRGB(200, 80, 80), 2)
        
        local errorIcon = Instance.new("TextLabel")
        errorIcon.Size = UDim2.new(0, 50, 0, 50)
        errorIcon.Position = UDim2.new(0, 15, 0.5, -25)
        errorIcon.BackgroundTransparency = 1
        errorIcon.Text = "⚠️"
        errorIcon.TextSize = 36
        errorIcon.Font = Enum.Font.GothamBold
        errorIcon.Parent = errorNotif
        
        local errorText = Instance.new("TextLabel")
        errorText.Size = UDim2.new(1, -80, 1, 0)
        errorText.Position = UDim2.new(0, 70, 0, 0)
        errorText.BackgroundTransparency = 1
        errorText.Text = message
        errorText.TextColor3 = Color3.fromRGB(255, 150, 150)
        errorText.TextSize = 14
        errorText.Font = Enum.Font.GothamSemibold
        errorText.TextWrapped = true
        errorText.TextXAlignment = Enum.TextXAlignment.Left
        errorText.Parent = errorNotif
        
        -- Animate and remove
        task.delay(3, function()
            local tweenOut = TweenService:Create(errorNotif, TweenInfo.new(0.3), {BackgroundTransparency = 1})
            tweenOut:Play()
            tweenOut.Completed:Connect(function()
                errorNotif:Destroy()
            end)
        end)
        
        end -- end notifications check
        -- Note: Button text will be reset by the SupernovaPanel module
        
        print("[Supernova] Failed: " .. message)
    
    elseif action == "travelSuccess" then
        -- Player successfully teleported
        local worldName = args[1] or "Unknown"
        
        -- Show success notification
        if shouldShowNotifications() then
        local travelNotif = Instance.new("Frame")
        travelNotif.Name = "TravelSuccessNotif"
        travelNotif.Size = UDim2.new(0, 280, 0, 70)
        travelNotif.Position = UDim2.new(0.5, -140, 0.35, 0)
        travelNotif.BackgroundColor3 = Color3.fromRGB(40, 60, 50)
        travelNotif.BorderSizePixel = 0
        travelNotif.ZIndex = 500
        travelNotif.Parent = screenGui
        createCorner(travelNotif, 0.15)
        createStroke(travelNotif, Color3.fromRGB(80, 200, 120), 2)
        
        local travelIcon = Instance.new("TextLabel")
        travelIcon.Size = UDim2.new(0, 50, 0, 50)
        travelIcon.Position = UDim2.new(0, 10, 0.5, -25)
        travelIcon.BackgroundTransparency = 1
        travelIcon.Text = "🌍"
        travelIcon.TextSize = 32
        travelIcon.Font = Enum.Font.GothamBold
        travelIcon.Parent = travelNotif
        
        local travelText = Instance.new("TextLabel")
        travelText.Size = UDim2.new(1, -70, 1, 0)
        travelText.Position = UDim2.new(0, 60, 0, 0)
        travelText.BackgroundTransparency = 1
        travelText.Text = "Teleportado para\n" .. worldName
        travelText.TextColor3 = Color3.fromRGB(150, 255, 150)
        travelText.TextSize = 16
        travelText.Font = Enum.Font.GothamBold
        travelText.TextWrapped = true
        travelText.TextXAlignment = Enum.TextXAlignment.Left
        travelText.Parent = travelNotif
        
        -- Animate and remove
        task.delay(2, function()
            local tweenOut = TweenService:Create(travelNotif, TweenInfo.new(0.3), {BackgroundTransparency = 1})
            tweenOut:Play()
            tweenOut.Completed:Connect(function()
                travelNotif:Destroy()
            end)
        end)
        
        end -- end notifications check
        -- Close worlds panel
        PanelManager.closeActivePanel()
        
        print("[Worlds] Traveled to: " .. worldName)
    
    elseif action == "travelFailed" then
        -- Travel failed
        local message = args[1] or "Unknown world"
        
        if shouldShowNotifications() then
        local failNotif = Instance.new("Frame")
        failNotif.Name = "TravelFailedNotif"
        failNotif.Size = UDim2.new(0, 280, 0, 60)
        failNotif.Position = UDim2.new(0.5, -140, 0.4, 0)
        failNotif.BackgroundColor3 = Color3.fromRGB(60, 40, 40)
        failNotif.BorderSizePixel = 0
        failNotif.ZIndex = 500
        failNotif.Parent = screenGui
        createCorner(failNotif, 0.15)
        createStroke(failNotif, Color3.fromRGB(200, 80, 80), 2)
        
        local failIcon = Instance.new("TextLabel")
        failIcon.Size = UDim2.new(0, 40, 0, 40)
        failIcon.Position = UDim2.new(0, 10, 0.5, -20)
        failIcon.BackgroundTransparency = 1
        failIcon.Text = "⚠️"
        failIcon.TextSize = 28
        failIcon.Font = Enum.Font.GothamBold
        failIcon.Parent = failNotif
        
        local failText = Instance.new("TextLabel")
        failText.Size = UDim2.new(1, -60, 1, 0)
        failText.Position = UDim2.new(0, 50, 0, 0)
        failText.BackgroundTransparency = 1
        failText.Text = message
        failText.TextColor3 = Color3.fromRGB(255, 150, 150)
        failText.TextSize = 14
        failText.Font = Enum.Font.GothamSemibold
        failText.TextWrapped = true
        failText.TextXAlignment = Enum.TextXAlignment.Left
        failText.Parent = failNotif
        
        task.delay(2, function()
            local tweenOut = TweenService:Create(failNotif, TweenInfo.new(0.3), {BackgroundTransparency = 1})
            tweenOut:Play()
            tweenOut.Completed:Connect(function()
                failNotif:Destroy()
            end)
        end)
        
        end -- end notifications check
        print("[Worlds] Travel failed: " .. message)
    
    elseif action == "worldUnlocked" then
        -- World unlocked (free unlock)
        local worldName = args[1] or "Unknown"
        print("[Worlds] World unlocked: " .. worldName)
    
    elseif action == "boostActivated" then
        -- Boost item was purchased and activated
        local itemName = args[1]
        local boostData = args[2]
        local activeBoosts = args[3]
        
        print("[Boost] Activated: " .. tostring(itemName))
        
        -- Update state with active boosts from server
        if activeBoosts and #activeBoosts > 0 then
            state.activeBoosts = activeBoosts
        end
        
        -- Update boost indicators
        updateBoostIndicators()
        
        -- Show activation notification
        if shouldShowNotifications() then
            local notif = Instance.new("Frame")
            notif.Name = "BoostActivationNotif"
            notif.Size = UDim2.new(0, 300, 0, 80)
            notif.Position = UDim2.new(0.5, -150, 0.3, 0)
            notif.BackgroundColor3 = Color3.fromRGB(40, 60, 80)
            notif.BorderSizePixel = 0
            notif.ZIndex = 500
            notif.Parent = screenGui
            createCorner(notif, 0.15)
            createStroke(notif, Color3.fromRGB(100, 150, 255), 2)
            
            local icon = Instance.new("TextLabel")
            icon.Size = UDim2.new(0, 50, 0, 50)
            icon.Position = UDim2.new(0, 15, 0.5, -25)
            icon.BackgroundTransparency = 1
            icon.Text = "🧪"
            icon.TextSize = 36
            icon.Font = Enum.Font.GothamBold
            icon.Parent = notif
            
            local title = Instance.new("TextLabel")
            title.Size = UDim2.new(1, -80, 0, 30)
            title.Position = UDim2.new(0, 70, 0, 10)
            title.BackgroundTransparency = 1
            title.Text = itemName .. " Activated!"
            title.TextColor3 = Color3.fromRGB(100, 200, 255)
            title.TextSize = 16
            title.Font = Enum.Font.GothamBold
            title.TextXAlignment = Enum.TextXAlignment.Left
            title.Parent = notif
            
            local desc = Instance.new("TextLabel")
            desc.Size = UDim2.new(1, -80, 0, 30)
            desc.Position = UDim2.new(0, 70, 0, 40)
            desc.BackgroundTransparency = 1
            
            -- Format duration
            local durationMin = math.floor((boostData.duration or 180) / 60)
            local durationSec = (boostData.duration or 180) % 60
            local durationStr = ""
            if durationMin > 0 then
                durationStr = durationMin .. " min"
                if durationSec > 0 then
                    durationStr = durationStr .. " " .. durationSec .. "s"
                end
            else
                durationStr = durationSec .. " seconds"
            end
            
            desc.Text = "x" .. tostring(boostData.multiplier) .. " for " .. durationStr
            desc.TextColor3 = Color3.fromRGB(200, 200, 200)
            desc.TextSize = 12
            desc.Font = Enum.Font.GothamSemibold
            desc.TextXAlignment = Enum.TextXAlignment.Left
            desc.Parent = notif
            
            task.delay(3, function()
                local tweenOut = TweenService:Create(notif, TweenInfo.new(0.3), {BackgroundTransparency = 1})
                tweenOut:Play()
                tweenOut.Completed:Connect(function()
                    notif:Destroy()
                end)
            end)
        end
    
    elseif action == "shopItemPurchased" then
        -- Collection item was purchased
        local itemName = args[1]
        local stardustGain = args[2]
        
        print("[Shop] Purchased: " .. tostring(itemName) .. " (gain: " .. tostring(stardustGain) .. ")")
        
        -- Show purchase notification
        if shouldShowNotifications() then
            local notif = Instance.new("Frame")
            notif.Name = "ShopItemNotif"
            notif.Size = UDim2.new(0, 280, 0, 70)
            notif.Position = UDim2.new(0.5, -140, 0.35, 0)
            notif.BackgroundColor3 = Color3.fromRGB(40, 60, 40)
            notif.BorderSizePixel = 0
            notif.ZIndex = 500
            notif.Parent = screenGui
            createCorner(notif, 0.15)
            createStroke(notif, Color3.fromRGB(100, 200, 100), 2)
            
            local icon = Instance.new("TextLabel")
            icon.Size = UDim2.new(0, 40, 0, 40)
            icon.Position = UDim2.new(0, 10, 0.5, -20)
            icon.BackgroundTransparency = 1
            icon.Text = "📦"
            icon.TextSize = 28
            icon.Font = Enum.Font.GothamBold
            icon.Parent = notif
            
            local text = Instance.new("TextLabel")
            text.Size = UDim2.new(1, -60, 1, 0)
            text.Position = UDim2.new(0, 50, 0, 0)
            text.BackgroundTransparency = 1
            text.Text = itemName .. " added to inventory!\nUse it for " .. tostring(stardustGain) .. " Stardust"
            text.TextColor3 = Color3.fromRGB(150, 255, 150)
            text.TextSize = 14
            text.Font = Enum.Font.GothamBold
            text.TextWrapped = true
            text.TextXAlignment = Enum.TextXAlignment.Left
            text.Parent = notif
            
            task.delay(2.5, function()
                local tweenOut = TweenService:Create(notif, TweenInfo.new(0.3), {BackgroundTransparency = 1})
                tweenOut:Play()
                tweenOut.Completed:Connect(function()
                    notif:Destroy()
                end)
            end)
        end
        
        -- TUTORIAL: Track shop purchase progress
        TutorialPanel.updateProgress("buyItem", 1)
    
    elseif action == "petsDeleted" then
        -- Pets were deleted from server
        local deletedCount = args[1] or 0
        local newOwnedPets = args[2]
        local equippedPets = args[3]
        
        print("[Pets] Deleted " .. tostring(deletedCount) .. " pet(s)")
        
        -- Update OWNED_PETS
        OWNED_PETS = {}
        for _, pet in ipairs(newOwnedPets or {}) do
            if pet and pet.name then
                table.insert(OWNED_PETS, pet)
            end
        end
        
        -- Mark equipped status
        for _, pet in ipairs(OWNED_PETS) do
            if pet then
                pet.equipped = false
                for _, equippedId in ipairs(equippedPets or {}) do
                    if pet.id == equippedId then
                        pet.equipped = true
                        break
                    end
                end
            end
        end
        
        -- Update pets panel
        PetsPanel.setPets(OWNED_PETS, equippedPets)
        
        -- Show success notification
        if shouldShowNotifications() then
            local notif = Instance.new("Frame")
            notif.Name = "PetsDeletedNotif"
            notif.Size = UDim2.new(0, 250, 0, 60)
            notif.Position = UDim2.new(0.5, -125, 0.85, 0)
            notif.BackgroundColor3 = Color3.fromRGB(40, 50, 40)
            notif.BorderSizePixel = 0
            notif.ZIndex = 500
            notif.Parent = screenGui
            createCorner(notif, 0.15)
            createStroke(notif, Color3.fromRGB(100, 200, 100), 2)
            
            local icon = Instance.new("TextLabel")
            icon.Size = UDim2.new(0, 40, 0, 40)
            icon.Position = UDim2.new(0, 10, 0.5, -20)
            icon.BackgroundTransparency = 1
            icon.Text = "🗑️"
            icon.TextSize = 24
            icon.Font = Enum.Font.GothamBold
            icon.Parent = notif
            
            local text = Instance.new("TextLabel")
            text.Size = UDim2.new(1, -60, 1, 0)
            text.Position = UDim2.new(0, 50, 0, 0)
            text.BackgroundTransparency = 1
            text.Text = deletedCount .. " pet(s) deleted"
            text.TextColor3 = Color3.fromRGB(150, 255, 150)
            text.TextSize = 16
            text.Font = Enum.Font.GothamBold
            text.TextXAlignment = Enum.TextXAlignment.Left
            text.Parent = notif
            
            task.delay(2, function()
                local tweenOut = TweenService:Create(notif, TweenInfo.new(0.3), {BackgroundTransparency = 1})
                tweenOut:Play()
                tweenOut.Completed:Connect(function()
                    notif:Destroy()
                end)
            end)
        end
    
    elseif action == "mergeSuccess" then
        -- Pet merge was successful
        local mergedPet = args[1]
        local newOwnedPets = args[2]
        local equippedPets = args[3]
        
        print("[Pets] Merge successful! Merged pet:", mergedPet and mergedPet.name or "unknown", "stars:", mergedPet and (mergedPet.stars or 1) or "?")
        
        -- Update OWNED_PETS
        OWNED_PETS = {}
        for _, pet in ipairs(newOwnedPets or {}) do
            if pet and pet.name then
                table.insert(OWNED_PETS, pet)
            end
        end
        
        -- Mark equipped status
        for _, pet in ipairs(OWNED_PETS) do
            if pet then
                pet.equipped = false
                for _, equippedId in ipairs(equippedPets or {}) do
                    if pet.id == equippedId then
                        pet.equipped = true
                        break
                    end
                end
            end
        end
        
        -- Update pets panel
        PetsPanel.setPets(OWNED_PETS, equippedPets)
        
        -- Show merge success notification
        PetsPanel.showMergeSuccess(mergedPet)
        
        -- Mark last pet sync time
        lastPetSyncTime = tick()
    
    elseif action == "mergeError" then
        -- Pet merge failed
        local message = args[1] or "Merge failed"
        
        print("[Pets] Merge failed:", message)
        
        -- Show merge error notification
        PetsPanel.showMergeError(message)
    
    elseif action == "autoMergeSuccess" then
        -- Auto-merge was successful
        local totalMerges = args[1]
        local mergedPetsList = args[2]
        local newOwnedPets = args[3]
        local equippedPets = args[4]
        
        print("[Pets] Auto-merge successful! Merges:", totalMerges)
        
        -- Update OWNED_PETS
        OWNED_PETS = {}
        for _, pet in ipairs(newOwnedPets or {}) do
            if pet and pet.name then
                table.insert(OWNED_PETS, pet)
            end
        end
        
        -- Mark equipped status
        for _, pet in ipairs(OWNED_PETS) do
            if pet then
                pet.equipped = false
                for _, equippedId in ipairs(equippedPets or {}) do
                    if pet.id == equippedId then
                        pet.equipped = true
                        break
                    end
                end
            end
        end
        
        -- Update pets panel
        PetsPanel.setPets(OWNED_PETS, equippedPets)
        
        -- Show auto-merge success notification
        PetsPanel.showAutoMergeSuccess(totalMerges, mergedPetsList)
        
        -- Mark last pet sync time
        lastPetSyncTime = tick()
    
    elseif action == "petLockUpdated" then
        -- Pet lock state was toggled on server
        local petId = args[1]
        local isLocked = args[2]
        local newOwnedPets = args[3]
        local equippedPets = args[4]
        
        print("[Pets] Lock updated for pet:", petId, "locked:", isLocked)
        
        -- Update OWNED_PETS
        OWNED_PETS = {}
        for _, pet in ipairs(newOwnedPets or {}) do
            if pet and pet.name then
                table.insert(OWNED_PETS, pet)
            end
        end
        
        -- Mark equipped status
        for _, pet in ipairs(OWNED_PETS) do
            if pet then
                pet.equipped = false
                for _, equippedId in ipairs(equippedPets or {}) do
                    if pet.id == equippedId then
                        pet.equipped = true
                        break
                    end
                end
            end
        end
        
        -- Update pets panel
        PetsPanel.setPets(OWNED_PETS, equippedPets)
        
        -- Mark last pet sync time
        lastPetSyncTime = tick()
    
    elseif action == "petsLockedError" then
        -- Tried to delete locked pets
        local lockedCount = args[1] or 1
        
        print("[Pets] Cannot delete " .. tostring(lockedCount) .. " locked pet(s)")
        
        -- Show lock error notification
        PetsPanel.showLockError()
    
    end
end)
end -- End of CURRENCY SYNC do block

-- ===== LEADERBOARD PANEL =====
-- Leaderboard panel is now handled by LeaderboardPanel module
LeaderboardPanel.create(screenGui)

print("✨ Stardust Simulator GUI System Loaded!")