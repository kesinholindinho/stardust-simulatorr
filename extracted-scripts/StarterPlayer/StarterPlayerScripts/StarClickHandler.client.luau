-- ============================================
-- STAR CLICK HANDLER
-- Handles clicks on Golden Star parts in the 3D world
-- ============================================

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local gameAction = ReplicatedStorage:WaitForChild("GameAction")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local screenGui = playerGui:WaitForChild("StardustUI", 15)

-- Track last click time for debounce
local lastClickTime = 0
local clickCooldown = 0.1 -- 100ms between clicks

-- Function to send click to server
local function sendClickToServer()
    local now = tick()
    if now - lastClickTime < clickCooldown then
        return -- Debounce
    end
    lastClickTime = now
    
    -- Send click action to server
    local success, err = pcall(function()
        gameAction:FireServer("click")
    end)
    if not success then
        warn("[StarClickHandler] Failed to send click: " .. tostring(err))
    end
end

-- Function to create click feedback effect
local function createClickEffect(starPart)
    if not starPart then return end
    
    -- Quick scale animation
    local originalSize = starPart.Size
    local shrinkTween = TweenService:Create(starPart, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Size = originalSize * 0.8
    })
    shrinkTween:Play()
    
    shrinkTween.Completed:Connect(function()
        local growTween = TweenService:Create(starPart, TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Size = originalSize
        })
        growTween:Play()
    end)
end

-- Function to setup click handler on a star part
local function setupStarClickHandler(starPart)
    local clickDetector = starPart:FindFirstChild("StarClickDetector")
    if not clickDetector then
        -- Try to find any ClickDetector
        clickDetector = starPart:FindFirstChildOfClass("ClickDetector")
    end
    
    if clickDetector then
        clickDetector.MouseClick:Connect(function()
            sendClickToServer()
            createClickEffect(starPart)
        end)
        print("[StarClickHandler] Connected to " .. starPart:GetFullName())
    end
end

-- Setup existing star parts
local function setupExistingStars()
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Part") and obj.Name == "StarPart" then
            setupStarClickHandler(obj)
        end
    end
end

-- Watch for new star parts being added
workspace.DescendantAdded:Connect(function(descendant)
    if descendant:IsA("Part") and descendant.Name == "StarPart" then
        task.wait(0.1) -- Small delay to ensure ClickDetector is ready
        setupStarClickHandler(descendant)
    end
end)

-- Setup existing stars on load
setupExistingStars()

print("[StarClickHandler] Loaded and watching for Golden Star clicks!")