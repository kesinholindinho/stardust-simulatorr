local StyleModule = {}

-- ============================================
-- GLOBAL STYLE CONSTANTS
-- ============================================
StyleModule.COLORS = {
    MAIN_BG = Color3.fromRGB(20, 20, 20),
    SECONDARY_BG = Color3.fromRGB(35, 35, 35),
    BUTTON_BG = Color3.fromRGB(50, 50, 50),
    TITLE_TEXT = Color3.fromRGB(220, 220, 220),
    DESC_TEXT = Color3.fromRGB(170, 170, 170),
    BORDER = Color3.fromRGB(80, 80, 80),
    DIVIDER = Color3.fromRGB(60, 60, 60),
    CLOSE_BTN = Color3.fromRGB(60, 60, 60),
    CLOSE_HOVER = Color3.fromRGB(90, 90, 90),
    BUTTON_HOVER = Color3.fromRGB(65, 65, 65),
    BUTTON_CLICK = Color3.fromRGB(80, 80, 80),
    SHADOW = Color3.fromRGB(5, 5, 5),
    ACTIVE_BORDER = Color3.fromRGB(160, 160, 160),
    XP_FILL = Color3.fromRGB(180, 180, 180),
    TOGGLE_OFF = Color3.fromRGB(60, 60, 60),
    TOGGLE_ON = Color3.fromRGB(150, 150, 150),
    SUCCESS = Color3.fromRGB(100, 200, 100),
    RARITY = {
        Common = Color3.fromRGB(150, 150, 150),
        Rare = Color3.fromRGB(100, 150, 255),
        Epic = Color3.fromRGB(180, 100, 255),
        Legendary = Color3.fromRGB(255, 200, 50)
    }
}

StyleModule.TWEEN_INFO = TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
StyleModule.TWEEN_INFO_FAST = TweenInfo.new(0.15, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
StyleModule.CORNER_RADIUS = 0.12

-- ============================================
-- HELPER FUNCTIONS
-- ============================================
function StyleModule.createCorner(parent, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(radius or StyleModule.CORNER_RADIUS, 0)
    corner.Parent = parent
    return corner
end

function StyleModule.createStroke(parent, color, thickness)
    local stroke = Instance.new("UIStroke")
    stroke.Color = color or StyleModule.COLORS.BORDER
    stroke.Thickness = thickness or 1.5
    stroke.Parent = parent
    return stroke
end

function StyleModule.createShadow(frame)
    local shadow = Instance.new("Frame")
    shadow.Name = frame.Name .. "Shadow"
    shadow.Size = frame.Size
    shadow.Position = frame.Position + UDim2.new(0, 4, 0, 4)
    shadow.BackgroundColor3 = StyleModule.COLORS.SHADOW
    shadow.BorderSizePixel = 0
    shadow.ZIndex = frame.ZIndex - 1
    shadow.Parent = frame.Parent
    StyleModule.createCorner(shadow, StyleModule.CORNER_RADIUS)
    return shadow
end

function StyleModule.createCloseButton(parent, TweenService)
    local closeBtn = Instance.new("TextButton")
    closeBtn.Name = "CloseButton"
    closeBtn.Size = UDim2.new(0, 28, 0, 28)
    closeBtn.Position = UDim2.new(1, -36, 0, 8)
    closeBtn.AnchorPoint = Vector2.new(1, 0)
    closeBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    closeBtn.BorderSizePixel = 0
    closeBtn.Text = "X"
    closeBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
    closeBtn.TextSize = 18
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.Parent = parent
    
    -- Perfect circle
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1, 0)
    corner.Parent = closeBtn
    
    -- Border stroke
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(80, 80, 80)
    stroke.Thickness = 1.5
    stroke.Parent = closeBtn
    
    -- Cancel previous tween before starting new one to prevent visual glitches
    local activeTween = nil
    local function playTween(props, duration)
        if activeTween then
            activeTween:Cancel()
        end
        local info = duration and TweenInfo.new(duration, Enum.EasingStyle.Quint, Enum.EasingDirection.Out) or StyleModule.TWEEN_INFO_FAST
        activeTween = TweenService:Create(closeBtn, info, props)
        activeTween:Play()
    end
    
    closeBtn.MouseEnter:Connect(function()
        playTween({BackgroundColor3 = Color3.fromRGB(65, 65, 65)}, 0.12)
    end)
    closeBtn.MouseLeave:Connect(function()
        playTween({BackgroundColor3 = Color3.fromRGB(45, 45, 45)}, 0.12)
    end)
    closeBtn.MouseButton1Down:Connect(function()
        playTween({BackgroundColor3 = Color3.fromRGB(80, 80, 80)}, 0.08)
    end)
    closeBtn.MouseButton1Up:Connect(function()
        playTween({BackgroundColor3 = Color3.fromRGB(65, 65, 65)}, 0.08)
    end)
    
    return closeBtn
end

function StyleModule.setupButtonEffects(btn, TweenService)
    local originalColor = btn.BackgroundColor3
    local originalSize = btn.Size
    
    -- Cancel previous tween before starting new one to prevent visual glitches
    local activeTween = nil
    local function playTween(props)
        if activeTween then
            activeTween:Cancel()
        end
        activeTween = TweenService:Create(btn, StyleModule.TWEEN_INFO_FAST, props)
        activeTween:Play()
    end
    
    btn.MouseEnter:Connect(function()
        playTween({BackgroundColor3 = StyleModule.COLORS.BUTTON_HOVER})
    end)
    btn.MouseLeave:Connect(function()
        playTween({BackgroundColor3 = originalColor})
    end)
    btn.MouseButton1Down:Connect(function()
        playTween({BackgroundColor3 = StyleModule.COLORS.BUTTON_CLICK})
    end)
    btn.MouseButton1Up:Connect(function()
        playTween({BackgroundColor3 = originalColor})
    end)
end

function StyleModule.createPanel(name, size, title, TweenService)
    local panel = Instance.new("Frame")
    panel.Name = name
    panel.Size = size
    panel.AnchorPoint = Vector2.new(0.5, 0.5)
    panel.Position = UDim2.new(0.5, 0, 0.5, 0)
    panel.BackgroundColor3 = StyleModule.COLORS.MAIN_BG
    panel.BorderSizePixel = 0
    panel.Visible = false
    panel.ZIndex = 100
    
    StyleModule.createCorner(panel)
    local panelStroke = StyleModule.createStroke(panel)
    StyleModule.createShadow(panel)
    
    -- Store reference to stroke for animation
    panel:SetAttribute("HasStroke", "true")
    
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "TitleLabel"
    titleLabel.Size = UDim2.new(1, -50, 0, 40)
    titleLabel.AnchorPoint = Vector2.new(0.5, 0)
    titleLabel.Position = UDim2.new(0.5, 0, 0, 16)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = title
    titleLabel.TextColor3 = StyleModule.COLORS.TITLE_TEXT
    titleLabel.TextSize = 22
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextXAlignment = Enum.TextXAlignment.Center
    titleLabel.Parent = panel
    
    local closeBtn = StyleModule.createCloseButton(panel, TweenService)
    
    return panel, closeBtn
end

function StyleModule.showPanel(panel, TweenService)
    -- Store original size for reset
    local originalSize = panel.Size
    
    panel.Visible = true
    panel.AnchorPoint = Vector2.new(0.5, 0.5)
    panel.Position = UDim2.new(0.5, 0, 0.5, 0)
    panel.BackgroundTransparency = 1
    panel.Size = UDim2.new(originalSize.X.Scale, originalSize.X.Offset * 0.88, originalSize.Y.Scale, originalSize.Y.Offset * 0.88)
    
    -- Find shadow and stroke
    local shadow = panel.Parent and panel.Parent:FindFirstChild(panel.Name .. "Shadow")
    local stroke = panel:FindFirstChildOfClass("UIStroke")
    
    -- Set initial states
    if shadow then
        shadow.Position = panel.Position + UDim2.new(0, 4, 0, 4)
        shadow.BackgroundTransparency = 1
        shadow.Size = panel.Size
    end
    
    if stroke then
        stroke.Transparency = 1
    end
    
    -- Create tween info for elastic open
    local openTweenInfo = TweenInfo.new(0.35, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out)
    
    -- Tween shadow transparency
    if shadow then
        TweenService:Create(shadow, openTweenInfo, {BackgroundTransparency = 0, Size = originalSize}):Play()
    end
    
    -- Tween stroke transparency
    if stroke then
        TweenService:Create(stroke, openTweenInfo, {Transparency = 0}):Play()
    end
    
    -- Tween panel size and transparency
    local tween = TweenService:Create(panel, openTweenInfo, {
        Size = originalSize,
        BackgroundTransparency = 0
    })
    tween:Play()
end

function StyleModule.hidePanel(panel, TweenService)
    -- Store original size for reset
    local originalSize = panel.Size
    local targetSize = UDim2.new(originalSize.X.Scale, originalSize.X.Offset * 0.92, originalSize.Y.Scale, originalSize.Y.Offset * 0.92)
    
    -- Find shadow and stroke
    local shadow = panel.Parent and panel.Parent:FindFirstChild(panel.Name .. "Shadow")
    local stroke = panel:FindFirstChildOfClass("UIStroke")
    
    -- Create tween info for close (Quint In for snappy close)
    local closeTweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
    
    -- Tween all elements simultaneously
    if shadow then
        TweenService:Create(shadow, closeTweenInfo, {BackgroundTransparency = 1, Size = targetSize}):Play()
    end
    
    if stroke then
        TweenService:Create(stroke, closeTweenInfo, {Transparency = 1}):Play()
    end
    
    -- Tween panel size and transparency
    local tween = TweenService:Create(panel, closeTweenInfo, {
        Size = targetSize,
        BackgroundTransparency = 1
    })
    tween:Play()
    
    -- Only set Visible = false AFTER tween completes, then reset size
    tween.Completed:Connect(function()
        panel.Visible = false
        panel.Size = originalSize -- Reset to original size for next open
        if shadow then
            shadow.Visible = false
            shadow.Size = originalSize
        end
    end)
end

function StyleModule.abbreviateNumber(num)
    if num >= 1e12 then return string.format("%.1fT", num / 1e12)
    elseif num >= 1e9 then return string.format("%.1fB", num / 1e9)
    elseif num >= 1e6 then return string.format("%.1fM", num / 1e6)
    elseif num >= 1e3 then return string.format("%.1fK", num / 1e3)
    else
        -- Mostrar decimais para números pequenos
        local intPart = math.floor(num)
        local decPart = num - intPart
        if decPart > 0.001 then
            return string.format("%.1f", num)
        else
            return tostring(intPart)
        end
    end
end

return StyleModule