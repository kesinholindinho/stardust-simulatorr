local PanelManager = {}

local TweenService = game:GetService("TweenService")

local Config = require(game.ReplicatedStorage:WaitForChild("StardustConfig"))

-- State
local activePanel = nil
local activeButton = nil
local panels = {}

-- ============================================
-- TWEEN INFO
-- ============================================
local TWEEN_INFO = Config.TWEEN_INFO
local TWEEN_INFO_FAST = Config.TWEEN_INFO_FAST

-- ============================================
-- CREATE CORNER
-- ============================================
function PanelManager.createCorner(parent, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(radius or Config.CORNER_RADIUS, 0)
    corner.Parent = parent
    return corner
end

-- ============================================
-- CREATE STROKE
-- ============================================
function PanelManager.createStroke(parent, color, thickness)
    local stroke = Instance.new("UIStroke")
    stroke.Color = color or Config.COLORS.BORDER
    stroke.Thickness = thickness or 1.5
    stroke.Parent = parent
    return stroke
end

-- ============================================
-- CREATE CLOSE BUTTON
-- ============================================
function PanelManager.createCloseButton(parent)
    local closeBtn = Instance.new("TextButton")
    closeBtn.Name = "CloseButton"
    closeBtn.Size = UDim2.new(0, 28, 0, 28)
    closeBtn.Position = UDim2.new(1, -36, 0, 8)
    closeBtn.AnchorPoint = Vector2.new(1, 0)
    closeBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    closeBtn.BorderSizePixel = 0
    closeBtn.Text = "X"
    closeBtn.TextColor3 = Color3.fromRGB(180, 180, 180)
    closeBtn.TextSize = 14
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.Parent = parent
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1, 0)
    corner.Parent = closeBtn
    
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(80, 80, 80)
    stroke.Thickness = 1.5
    stroke.Parent = closeBtn
    
    local activeTween = nil
    local function playTween(props, duration)
        if activeTween then activeTween:Cancel() end
        activeTween = TweenService:Create(closeBtn, duration or TWEEN_INFO_FAST, props)
        activeTween:Play()
    end
    
    closeBtn.MouseEnter:Connect(function() playTween({BackgroundColor3 = Color3.fromRGB(65, 65, 65)}) end)
    closeBtn.MouseLeave:Connect(function() playTween({BackgroundColor3 = Color3.fromRGB(45, 45, 45)}) end)
    closeBtn.MouseButton1Down:Connect(function() playTween({BackgroundColor3 = Color3.fromRGB(80, 80, 80)}) end)
    closeBtn.MouseButton1Up:Connect(function() playTween({BackgroundColor3 = Color3.fromRGB(65, 65, 65)}) end)
    
    return closeBtn
end

-- ============================================
-- SETUP BUTTON EFFECTS
-- ============================================
function PanelManager.setupButtonEffects(btn)
    local originalColor = btn.BackgroundColor3
    local activeTween = nil
    
    local function playTween(props)
        if activeTween then activeTween:Cancel() end
        activeTween = TweenService:Create(btn, TWEEN_INFO_FAST, props)
        activeTween:Play()
    end
    
    btn.MouseEnter:Connect(function() playTween({BackgroundColor3 = Config.COLORS.BUTTON_HOVER}) end)
    btn.MouseLeave:Connect(function() playTween({BackgroundColor3 = originalColor}) end)
    btn.MouseButton1Down:Connect(function() playTween({BackgroundColor3 = Config.COLORS.BUTTON_CLICK}) end)
    btn.MouseButton1Up:Connect(function() playTween({BackgroundColor3 = originalColor}) end)
end

-- ============================================
-- SHOW PANEL
-- ============================================
function PanelManager.showPanel(panel)
    if not panel then return end
    
    local originalSize = panel.Size
    panel.Visible = true
    panel.AnchorPoint = Vector2.new(0.5, 0.5)
    panel.Position = UDim2.new(0.5, 0, 0.5, 0)
    panel.BackgroundTransparency = 1
    panel.Size = UDim2.new(originalSize.X.Scale, originalSize.X.Offset * 0.88, originalSize.Y.Scale, originalSize.Y.Offset * 0.88)
    
    local shadow = panel.Parent and panel.Parent:FindFirstChild(panel.Name .. "Shadow")
    local stroke = panel:FindFirstChildOfClass("UIStroke")
    
    if shadow then
        shadow.Position = panel.Position + UDim2.new(0, 4, 0, 4)
        shadow.BackgroundTransparency = 1
        shadow.Size = panel.Size
    end
    
    if stroke then stroke.Transparency = 1 end
    
    local openTweenInfo = TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
    
    if shadow then
        TweenService:Create(shadow, openTweenInfo, {BackgroundTransparency = 0, Size = originalSize}):Play()
    end
    if stroke then
        TweenService:Create(stroke, openTweenInfo, {Transparency = 0}):Play()
    end
    
    TweenService:Create(panel, openTweenInfo, {Size = originalSize, BackgroundTransparency = 0}):Play()
end

-- ============================================
-- HIDE PANEL
-- ============================================
function PanelManager.hidePanel(panel)
    if not panel then return end
    
    local originalSize = panel.Size
    local targetSize = UDim2.new(originalSize.X.Scale, originalSize.X.Offset * 0.92, originalSize.Y.Scale, originalSize.Y.Offset * 0.92)
    
    local shadow = panel.Parent and panel.Parent:FindFirstChild(panel.Name .. "Shadow")
    local stroke = panel:FindFirstChildOfClass("UIStroke")
    
    local closeTweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
    
    if shadow then
        TweenService:Create(shadow, closeTweenInfo, {BackgroundTransparency = 1, Size = targetSize}):Play()
    end
    if stroke then
        TweenService:Create(stroke, closeTweenInfo, {Transparency = 1}):Play()
    end
    
    local tween = TweenService:Create(panel, closeTweenInfo, {Size = targetSize, BackgroundTransparency = 1})
    tween:Play()
    
    tween.Completed:Connect(function()
        panel.Visible = false
        panel.Size = originalSize
        if shadow then
            shadow.Visible = false
            shadow.Size = originalSize
        end
    end)
end

-- ============================================
-- TOGGLE PANEL
-- ============================================
function PanelManager.togglePanel(panel, buttonStroke)
    if activePanel == panel then
        PanelManager.hidePanel(panel)
        if buttonStroke then buttonStroke.Color = Config.COLORS.BORDER end
        activePanel = nil
        activeButton = nil
        return false
    else
        if activePanel then
            PanelManager.hidePanel(activePanel)
            if activeButton and activeButton.stroke then
                activeButton.stroke.Color = Config.COLORS.BORDER
            end
        end
        PanelManager.showPanel(panel)
        if buttonStroke then buttonStroke.Color = Config.COLORS.ACTIVE_BORDER end
        activePanel = panel
        activeButton = {frame = buttonStroke and buttonStroke.Parent, stroke = buttonStroke}
        return true
    end
end

-- ============================================
-- CLOSE ACTIVE PANEL
-- ============================================
function PanelManager.closeActivePanel()
    if activePanel then
        PanelManager.hidePanel(activePanel)
        if activeButton and activeButton.stroke then
            activeButton.stroke.Color = Config.COLORS.BORDER
        end
        activePanel = nil
        activeButton = nil
    end
end

-- ============================================
-- GET ACTIVE PANEL
-- ============================================
function PanelManager.getActivePanel()
    return activePanel, activeButton
end

-- ============================================
-- REGISTER PANEL
-- ============================================
function PanelManager.registerPanel(name, panel)
    panels[name] = panel
end

function PanelManager.getPanel(name)
    return panels[name]
end

return PanelManager