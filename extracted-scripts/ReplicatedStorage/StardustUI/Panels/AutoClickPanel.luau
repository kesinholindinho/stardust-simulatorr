local AutoClickPanel = {}

local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")

local Config = require(ReplicatedStorage:WaitForChild("StardustConfig"))
local PanelManager = require(ReplicatedStorage:WaitForChild("StardustUI"):WaitForChild("PanelManager"))
local TutorialPanel = require(ReplicatedStorage:WaitForChild("StardustUI"):WaitForChild("Panels"):WaitForChild("TutorialPanel"))

-- Gamepass ID
local AUTO_CLICK_STAR_GAMEPASS_ID = 1818211451

-- State
local autoClickEnabled = false
local autoClickRate = 0.5 -- Free version: 0.5s (2 clicks/sec)
local autoClickRateGamepass = 0.25 -- Gamepass version: 0.25s (4 clicks/sec)
local hasAutoClickGamepass = false
local useGamepassVersion = false -- Player's choice
local autoClickConnection = nil
local totalAutoClicks = 0
local panel = nil
local statusLabel = nil
local clickCounterLabel = nil
local toggleBtn = nil
local toggleStroke = nil
local screenGuiRef = nil
local gamepassIndicator = nil
local versionLabel = nil
local versionBtn = nil

-- GameAction remote for clicking
local gameActionRemote = ReplicatedStorage:WaitForChild("GameAction")

-- Check if player has gamepass
local function checkGamepass()
	local player = Players.LocalPlayer
	if not player then return false end
	
	local success, hasGamepass = pcall(function()
		return MarketplaceService:UserOwnsGamePassAsync(player.UserId, AUTO_CLICK_STAR_GAMEPASS_ID)
	end)
	return success and hasGamepass
end

-- ============================================
-- CREATE PANEL CONTENT
-- ============================================
function AutoClickPanel.create(screenGui)
    panel = screenGui:FindFirstChild("AutoClickPanel")
    if not panel then return end
    screenGuiRef = screenGui
    
    -- Check if player has gamepass
    hasAutoClickGamepass = checkGamepass()
    
    local autoClickClose = panel:FindFirstChild("CloseButton")
    
    -- Content frame
    local content = Instance.new("Frame")
    content.Name = "Content"
    content.Size = UDim2.new(1, -32, 1, -60)
    content.Position = UDim2.new(0, 16, 0, 52)
    content.BackgroundTransparency = 1
    content.Parent = panel
    
    -- Gamepass indicator (shows if player has the gamepass)
    if hasAutoClickGamepass then
        gamepassIndicator = Instance.new("Frame")
        gamepassIndicator.Name = "GamepassIndicator"
        gamepassIndicator.Size = UDim2.new(1, 0, 0, 35)
        gamepassIndicator.Position = UDim2.new(0, 0, 0, 0)
        gamepassIndicator.BackgroundColor3 = Color3.fromRGB(255, 200, 50)
        gamepassIndicator.BorderSizePixel = 0
        gamepassIndicator.Parent = content
        PanelManager.createCorner(gamepassIndicator, 0.2)
        
        local indicatorStroke = Instance.new("UIStroke")
        indicatorStroke.Color = Color3.fromRGB(255, 150, 0)
        indicatorStroke.Thickness = 2
        indicatorStroke.Parent = gamepassIndicator
        
        local indicatorLabel = Instance.new("TextLabel")
        indicatorLabel.Size = UDim2.new(1, 0, 1, 0)
        indicatorLabel.BackgroundTransparency = 1
        indicatorLabel.Text = "🔄 Auto Click Star ATIVO!"
        indicatorLabel.TextColor3 = Color3.fromRGB(30, 30, 30)
        indicatorLabel.TextSize = 16
        indicatorLabel.Font = Enum.Font.GothamBold
        indicatorLabel.Parent = gamepassIndicator
    end
    
    -- Version label (shows current speed)
    versionLabel = Instance.new("TextLabel")
    versionLabel.Name = "VersionLabel"
    versionLabel.Size = UDim2.new(1, 0, 0, 30)
    versionLabel.Position = UDim2.new(0, 0, 0, hasAutoClickGamepass and 45 or 10)
    versionLabel.BackgroundTransparency = 1
    versionLabel.Text = hasAutoClickGamepass and "Velocidade: 4 cliques/seg (Gamepass)" or "Velocidade: 2 cliques/seg (Grátis)"
    versionLabel.TextColor3 = hasAutoClickGamepass and Color3.fromRGB(100, 200, 100) or Config.COLORS.DESC_TEXT
    versionLabel.TextSize = 14
    versionLabel.Font = Enum.Font.GothamSemibold
    versionLabel.Parent = content
    
    -- Version toggle button (only if player has gamepass)
    if hasAutoClickGamepass then
        versionBtn = Instance.new("TextButton")
        versionBtn.Name = "VersionBtn"
        versionBtn.Size = UDim2.new(1, 0, 0, 35)
        versionBtn.Position = UDim2.new(0, 0, 0, 80)
        versionBtn.BackgroundColor3 = Color3.fromRGB(60, 100, 60)
        versionBtn.BorderSizePixel = 0
        versionBtn.Text = "🔄 Usar Gamepass (2x rápido)"
        versionBtn.TextColor3 = Config.COLORS.TITLE_TEXT
        versionBtn.TextSize = 14
        versionBtn.Font = Enum.Font.GothamBold
        versionBtn.Parent = content
        PanelManager.createCorner(versionBtn, 0.15)
        local versionStroke = PanelManager.createStroke(versionBtn, Color3.fromRGB(100, 200, 100))
        PanelManager.setupButtonEffects(versionBtn)
        
        versionBtn.MouseButton1Click:Connect(AutoClickPanel.toggleVersion)
    end
    
    -- Status label
    statusLabel = Instance.new("TextLabel")
    statusLabel.Name = "StatusLabel"
    statusLabel.Size = UDim2.new(1, 0, 0, 40)
    statusLabel.Position = UDim2.new(0, 0, 0, hasAutoClickGamepass and 125 or 50)
    statusLabel.BackgroundTransparency = 1
    statusLabel.Text = "Status: DESATIVADO"
    statusLabel.TextColor3 = Config.COLORS.DESC_TEXT
    statusLabel.TextSize = 20
    statusLabel.Font = Enum.Font.GothamBold
    statusLabel.Parent = content
    
    -- Click counter
    clickCounterLabel = Instance.new("TextLabel")
    clickCounterLabel.Name = "ClickCounter"
    clickCounterLabel.Size = UDim2.new(1, 0, 0, 30)
    clickCounterLabel.Position = UDim2.new(0, 0, 0, hasAutoClickGamepass and 175 or 100)
    clickCounterLabel.BackgroundTransparency = 1
    clickCounterLabel.Text = "Cliques automáticos: 0"
    clickCounterLabel.TextColor3 = Config.COLORS.TITLE_TEXT
    clickCounterLabel.TextSize = 16
    clickCounterLabel.Font = Enum.Font.GothamSemibold
    clickCounterLabel.Parent = content
    
    -- Toggle button
    toggleBtn = Instance.new("TextButton")
    toggleBtn.Name = "ToggleBtn"
    toggleBtn.Size = UDim2.new(1, -32, 0, 50)
    toggleBtn.Position = UDim2.new(0, 16, 0, hasAutoClickGamepass and 220 or 145)
    toggleBtn.BackgroundColor3 = Config.COLORS.BUTTON_BG
    toggleBtn.BorderSizePixel = 0
    toggleBtn.Text = "▶️ Ativar AutoClick"
    toggleBtn.TextColor3 = Config.COLORS.TITLE_TEXT
    toggleBtn.TextSize = 18
    toggleBtn.Font = Enum.Font.GothamBold
    toggleBtn.Parent = content
    PanelManager.createCorner(toggleBtn, 0.15)
    toggleStroke = PanelManager.createStroke(toggleBtn)
    PanelManager.setupButtonEffects(toggleBtn)
    
    toggleBtn.MouseButton1Click:Connect(AutoClickPanel.toggle)
    
    -- Close button - use PanelManager to close
    if autoClickClose then
        autoClickClose.MouseButton1Click:Connect(function()
            PanelManager.closeActivePanel()
        end)
    end
    
    PanelManager.registerPanel("AutoClickPanel", panel)
    
    -- Auto-select gamepass version if available
    if hasAutoClickGamepass then
        useGamepassVersion = true
        AutoClickPanel.updateVersionUI()
    end
end

-- ============================================
-- TOGGLE VERSION (Free vs Gamepass)
-- ============================================
function AutoClickPanel.toggleVersion()
    if not hasAutoClickGamepass then return end
    
    useGamepassVersion = not useGamepassVersion
    AutoClickPanel.updateVersionUI()
    
    -- If autoclick is running, restart it with new rate
    if autoClickEnabled then
        AutoClickPanel.toggle() -- Stop
        task.wait(0.1)
        AutoClickPanel.toggle() -- Start with new rate
    end
end

-- ============================================
-- UPDATE VERSION UI
-- ============================================
function AutoClickPanel.updateVersionUI()
    if not versionLabel or not versionBtn then return end
    
    if useGamepassVersion then
        versionLabel.Text = "Velocidade: 4 cliques/seg (Gamepass)"
        versionLabel.TextColor3 = Color3.fromRGB(100, 200, 100)
        versionBtn.Text = "🔄 Usar Gamepass (2x rápido)"
        versionBtn.BackgroundColor3 = Color3.fromRGB(60, 100, 60)
    else
        versionLabel.Text = "Velocidade: 2 cliques/seg (Grátis)"
        versionLabel.TextColor3 = Config.COLORS.DESC_TEXT
        versionBtn.Text = "⭐ Usar Versão Grátis"
        versionBtn.BackgroundColor3 = Config.COLORS.BUTTON_BG
    end
end

-- ============================================
-- PERFORM AUTO CLICK
-- ============================================
function AutoClickPanel.performClick()
    if not autoClickEnabled then return end
    
    -- Send click to server
    local success, err = pcall(function()
        gameActionRemote:FireServer("click")
    end)
    if not success then
        warn("[AutoClick] Failed to send click: " .. tostring(err))
    end
    
    totalAutoClicks = totalAutoClicks + 1
    if clickCounterLabel then
        clickCounterLabel.Text = "Cliques automáticos: " .. tostring(totalAutoClicks)
    end
end

-- ============================================
-- TOGGLE AUTO CLICK
-- ============================================
function AutoClickPanel.toggle()
    autoClickEnabled = not autoClickEnabled
    
    -- Determine the click rate based on gamepass and player choice
    local currentRate = autoClickRate
    if hasAutoClickGamepass and useGamepassVersion then
        currentRate = autoClickRateGamepass
    end
    
    if autoClickEnabled then
        statusLabel.Text = "Status: ATIVADO ✓"
        statusLabel.TextColor3 = Config.COLORS.SUCCESS
        toggleBtn.Text = "⏸️ Desativar AutoClick"
        toggleBtn.BackgroundColor3 = Color3.fromRGB(60, 100, 60)
        toggleStroke.Color = Config.COLORS.SUCCESS
        
        autoClickConnection = task.spawn(function()
            while autoClickEnabled do
                AutoClickPanel.performClick()
                task.wait(currentRate)
            end
        end)
        
        local speedText = hasAutoClickGamepass and useGamepassVersion and "(4 cliques/seg)" or "(2 cliques/seg)"
        print("[AutoClick] Ativado " .. speedText)
        
        -- Notify tutorial that AutoClick was activated
        TutorialPanel.updateProgress("autoClickActivated", 1)
    else
        statusLabel.Text = "Status: DESATIVADO"
        statusLabel.TextColor3 = Config.COLORS.DESC_TEXT
        toggleBtn.Text = "▶️ Ativar AutoClick"
        toggleBtn.BackgroundColor3 = Config.COLORS.BUTTON_BG
        toggleStroke.Color = Config.COLORS.BORDER
        
        print("[AutoClick] Desativado")
    end
end

-- ============================================
-- SET GAMEPASS STATUS (called from StardustGUI)
-- ============================================
function AutoClickPanel.setGamepassStatus(hasGamepass)
    hasAutoClickGamepass = hasGamepass
    if hasGamepass and not useGamepassVersion then
        useGamepassVersion = true
        AutoClickPanel.updateVersionUI()
    end
end

-- ============================================
-- GET GAMEPASS STATUS
-- ============================================
function AutoClickPanel.hasGamepass()
    return hasAutoClickGamepass
end

return AutoClickPanel