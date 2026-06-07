local SettingsPanel = {}

local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Config = require(ReplicatedStorage:WaitForChild("StardustConfig"))
local PanelManager = require(ReplicatedStorage:WaitForChild("StardustUI"):WaitForChild("PanelManager"))

local panel = nil
local toggleButtons = {}
local settingsLoaded = false

-- ============================================
-- SETTINGS STATE (defaults, overridden by server)
-- ============================================
local settings = {
    music = true,
    sound = true,
    particles = true,
    notifications = true
}

-- Store original values so we can restore them
local originalVolumes = {} -- [Sound] = originalVolume
local originalRates = {}   -- [ParticleEmitter] = originalRate

-- ============================================
-- SETTINGS SYNC WITH SERVER (forward declarations)
-- ============================================
local function syncSettingsToServer()
    local settingsSync = ReplicatedStorage:FindFirstChild("SettingsSync")
    if settingsSync and settingsSync:IsA("RemoteEvent") then
        settingsSync:FireServer(settings)
    end
end

-- loadSettingsFromServer is defined after apply functions (see below)

local SETTINGS_CONFIG = {
    {name = "music", emoji = "🎵", label = "Music"},
    {name = "sound", emoji = "🔊", label = "Sound Effects"},
    {name = "particles", emoji = "✨", label = "Particles"},
    {name = "notifications", emoji = "🔔", label = "Notifications"}
}

-- ============================================
-- APPLY MUSIC SETTING
-- ============================================
local function applyMusic(enabled)
    -- Background music in Workspace
    local bgMusic = workspace:FindFirstChild("BackgroundMusic")
    if bgMusic and bgMusic:IsA("Sound") then
        if enabled then
            bgMusic.Volume = originalVolumes[bgMusic] or 0.5
            if not bgMusic.IsPlaying then
                bgMusic:Resume()
            end
        else
            if not originalVolumes[bgMusic] then
                originalVolumes[bgMusic] = bgMusic.Volume
            end
            bgMusic:Pause()
        end
    end
    
    -- Rain ambient sound
    local rain = workspace:FindFirstChild("Rain")
    if rain then
        local rainSound = rain:FindFirstChild("Raining")
        if rainSound and rainSound:IsA("Sound") then
            if enabled then
                rainSound.Volume = originalVolumes[rainSound] or 1
                if not rainSound.IsPlaying then
                    rainSound:Resume()
                end
            else
                if not originalVolumes[rainSound] then
                    originalVolumes[rainSound] = rainSound.Volume
                end
                rainSound:Pause()
            end
        end
    end
end

-- ============================================
-- APPLY SOUND EFFECTS SETTING
-- ============================================
local function applySound(enabled)
    local function processSound(sound)
        -- Skip music sounds (handled by music toggle)
        if sound.Name == "BackgroundMusic" or sound.Name == "Raining" then
            return
        end
        if enabled then
            local origVol = originalVolumes[sound]
            if origVol then
                sound.Volume = origVol
            end
        else
            if not originalVolumes[sound] then
                originalVolumes[sound] = sound.Volume
            end
            sound.Volume = 0
        end
    end
    
    -- Process sounds in Workspace
    for _, desc in workspace:GetDescendants() do
        if desc:IsA("Sound") then
            processSound(desc)
        end
    end
    
    -- Process sounds in PlayerGui
    local player = Players.LocalPlayer
    if player then
        local playerGui = player:FindFirstChild("PlayerGui")
        if playerGui then
            for _, desc in playerGui:GetDescendants() do
                if desc:IsA("Sound") then
                    processSound(desc)
                end
            end
        end
    end
    
    -- Process sounds in SoundService
    for _, desc in SoundService:GetDescendants() do
        if desc:IsA("Sound") then
            processSound(desc)
        end
    end
end

-- ============================================
-- APPLY PARTICLES SETTING
-- ============================================
local function applyParticles(enabled)
    local function processEmitter(emitter)
        if enabled then
            local origRate = originalRates[emitter]
            if origRate then
                emitter.Rate = origRate
            end
            emitter.Enabled = true
        else
            if not originalRates[emitter] then
                originalRates[emitter] = emitter.Rate
            end
            emitter.Rate = 0
            emitter.Enabled = false
        end
    end
    
    for _, desc in workspace:GetDescendants() do
        if desc:IsA("ParticleEmitter") then
            processEmitter(desc)
        end
    end
end

-- ============================================
-- DESCENDANT ADDED LISTENERS
-- Auto-apply settings to new objects
-- ============================================
local function setupDescendantListeners()
    -- New sounds in workspace
    workspace.DescendantAdded:Connect(function(desc)
        if desc:IsA("Sound") then
            if desc.Name == "BackgroundMusic" or desc.Name == "Raining" then
                if not settings.music then
                    if not originalVolumes[desc] then
                        originalVolumes[desc] = desc.Volume
                    end
                    desc:Pause()
                end
            else
                if not settings.sound then
                    if not originalVolumes[desc] then
                        originalVolumes[desc] = desc.Volume
                    end
                    desc.Volume = 0
                end
            end
        elseif desc:IsA("ParticleEmitter") then
            if not settings.particles then
                if not originalRates[desc] then
                    originalRates[desc] = desc.Rate
                end
                desc.Rate = 0
                desc.Enabled = false
            end
        end
    end)
    
    -- New sounds in PlayerGui
    local player = Players.LocalPlayer
    if player then
        local playerGui = player:FindFirstChild("PlayerGui")
        if playerGui then
            playerGui.DescendantAdded:Connect(function(desc)
                if desc:IsA("Sound") then
                    if not settings.sound then
                        if not originalVolumes[desc] then
                            originalVolumes[desc] = desc.Volume
                        end
                        desc.Volume = 0
                    end
                end
            end)
        end
    end
end

-- ============================================
-- UPDATE TOGGLE BUTTON VISUAL
-- ============================================
function updateToggleVisual(settingName)
    local btn = toggleButtons[settingName]
    if not btn then return end
    local isOn = settings[settingName]
    
    -- Update container background
    btn.BackgroundColor3 = isOn and Color3.fromRGB(80, 200, 120) or Color3.fromRGB(80, 80, 80)
    
    -- Update knob position
    local knob = btn:FindFirstChild("Knob")
    if knob then
        knob.Position = isOn and UDim2.new(1, -24, 0.5, -11) or UDim2.new(0, 2, 0.5, -11)
    end
end

-- ============================================
-- LOAD SETTINGS FROM SERVER
-- (defined here so it can reference apply functions)
-- ============================================
local function loadSettingsFromServer()
    local settingsSync = ReplicatedStorage:FindFirstChild("SettingsSync")
    if not settingsSync or not settingsSync:IsA("RemoteEvent") then
        return
    end
    
    settingsSync.OnClientEvent:Connect(function(savedSettings)
        if type(savedSettings) ~= "table" then return end
        
        -- Apply saved settings
        for key, value in pairs(savedSettings) do
            if settings[key] ~= nil and type(value) == "boolean" then
                settings[key] = value
            end
        end
        
        settingsLoaded = true
        
        -- Apply all settings immediately
        applyMusic(settings.music)
        applySound(settings.sound)
        applyParticles(settings.particles)
        
        -- Update toggle visuals if panel is open
        for name, _ in pairs(settings) do
            updateToggleVisual(name)
        end
    end)
end

-- ============================================
-- CREATE PANEL
-- ============================================
function SettingsPanel.create(screenGui)
    panel = screenGui:FindFirstChild("SettingsPanel")
    if not panel then return end
    
    local COLORS = Config.COLORS
    local settingsClose = panel:FindFirstChild("CloseButton")
    
    -- Remove old Content if it exists (for re-creation safety)
    local oldContent = panel:FindFirstChild("Content")
    if oldContent then oldContent:Destroy() end
    
    local settingsContent = Instance.new("ScrollingFrame")
    settingsContent.Name = "Content"
    settingsContent.Size = UDim2.new(1, -32, 1, -60)
    settingsContent.Position = UDim2.new(0, 16, 0, 52)
    settingsContent.BackgroundTransparency = 1
    settingsContent.ScrollBarThickness = 3
    settingsContent.ScrollBarImageColor3 = Color3.fromRGB(80, 80, 80)
    settingsContent.AutomaticCanvasSize = Enum.AutomaticSize.Y
    settingsContent.Parent = panel
    
    local settingsPadding = Instance.new("UIPadding")
    settingsPadding.PaddingTop = UDim.new(0, 10)
    settingsPadding.PaddingBottom = UDim.new(0, 10)
    settingsPadding.PaddingLeft = UDim.new(0, 10)
    settingsPadding.PaddingRight = UDim.new(0, 10)
    settingsPadding.Parent = settingsContent
    
    local settingsList = Instance.new("UIListLayout")
    settingsList.Padding = UDim.new(0, 10)
    settingsList.Parent = settingsContent
    
    -- Create setting rows
    for _, setting in ipairs(SETTINGS_CONFIG) do
        local row = Instance.new("Frame")
        row.Name = setting.name
        row.Size = UDim2.new(1, 0, 0, 50)
        row.BackgroundColor3 = COLORS.SECONDARY_BG
        row.BorderSizePixel = 0
        row.Parent = settingsContent
        PanelManager.createCorner(row, 0.1)
        PanelManager.createStroke(row)
        
        local settingEmoji = Instance.new("TextLabel")
        settingEmoji.Size = UDim2.new(0, 40, 1, 0)
        settingEmoji.BackgroundTransparency = 1
        settingEmoji.Text = setting.emoji
        settingEmoji.TextSize = 24
        settingEmoji.Font = Enum.Font.GothamBold
        settingEmoji.Parent = row
        
        local settingLabel = Instance.new("TextLabel")
        settingLabel.Size = UDim2.new(0, 150, 1, 0)
        settingLabel.Position = UDim2.new(0, 45, 0, 0)
        settingLabel.BackgroundTransparency = 1
        settingLabel.Text = setting.label
        settingLabel.TextColor3 = COLORS.TITLE_TEXT
        settingLabel.TextSize = 14
        settingLabel.Font = Enum.Font.GothamSemibold
        settingLabel.TextXAlignment = Enum.TextXAlignment.Left
        settingLabel.Parent = row
        
        -- Toggle switch container
        local toggleContainer = Instance.new("Frame")
        toggleContainer.Name = "ToggleSwitch"
        toggleContainer.Size = UDim2.new(0, 50, 0, 26)
        toggleContainer.Position = UDim2.new(1, -60, 0.5, -13)
        toggleContainer.BackgroundColor3 = settings[setting.name] and Color3.fromRGB(80, 200, 120) or Color3.fromRGB(80, 80, 80)
        toggleContainer.BorderSizePixel = 0
        toggleContainer.Parent = row
        PanelManager.createCorner(toggleContainer, 0.5)
        
        -- Toggle knob
        local toggleKnob = Instance.new("Frame")
        toggleKnob.Name = "Knob"
        toggleKnob.Size = UDim2.new(0, 22, 0, 22)
        toggleKnob.Position = settings[setting.name] and UDim2.new(1, -24, 0.5, -11) or UDim2.new(0, 2, 0.5, -11)
        toggleKnob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        toggleKnob.BorderSizePixel = 0
        toggleKnob.Parent = toggleContainer
        PanelManager.createCorner(toggleKnob, 0.5)
        
        -- Invisible click button over the whole toggle
        local toggleBtn = Instance.new("TextButton")
        toggleBtn.Name = "Toggle"
        toggleBtn.Size = UDim2.new(1, 0, 1, 0)
        toggleBtn.BackgroundTransparency = 1
        toggleBtn.Text = ""
        toggleBtn.Parent = toggleContainer
        
        -- Store reference for visual updates
        toggleButtons[setting.name] = toggleContainer
        
        toggleBtn.MouseButton1Click:Connect(function()
            settings[setting.name] = not settings[setting.name]
            local isOn = settings[setting.name]
            
            -- Animate toggle
            local targetKnobPos = isOn and UDim2.new(1, -24, 0.5, -11) or UDim2.new(0, 2, 0.5, -11)
            local targetBgColor = isOn and Color3.fromRGB(80, 200, 120) or Color3.fromRGB(80, 80, 80)
            
            TweenService:Create(toggleKnob, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Position = targetKnobPos
            }):Play()
            TweenService:Create(toggleContainer, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                BackgroundColor3 = targetBgColor
            }):Play()
            
            -- Apply setting immediately
            if setting.name == "music" then
                applyMusic(settings.music)
            elseif setting.name == "sound" then
                applySound(settings.sound)
            elseif setting.name == "particles" then
                applyParticles(settings.particles)
            end
            -- notifications is checked by other code via getSettings()
            
            -- Sync to server for persistence
            syncSettingsToServer()
        end)
    end
    
    -- Close button
    if settingsClose then
        settingsClose.MouseButton1Click:Connect(function()
            PanelManager.closeActivePanel()
        end)
    end
    
    PanelManager.registerPanel("SettingsPanel", panel)
    
    -- Setup listeners for new sounds/particles
    setupDescendantListeners()
end

-- ============================================
-- GET SETTINGS
-- ============================================
function SettingsPanel.getSettings()
    return settings
end

-- ============================================
-- CHECK IF NOTIFICATIONS ENABLED
-- ============================================
function SettingsPanel.notificationsEnabled()
    return settings.notifications
end

-- ============================================
-- CHECK IF SOUND ENABLED
-- ============================================
function SettingsPanel.soundEnabled()
    return settings.sound
end

-- ============================================
-- CHECK IF MUSIC ENABLED
-- ============================================
function SettingsPanel.musicEnabled()
    return settings.music
end

-- ============================================
-- INITIALIZE: Load settings from server ASAP
-- This runs when the module is first required,
-- before the panel UI is even created.
-- ============================================
loadSettingsFromServer()

return SettingsPanel