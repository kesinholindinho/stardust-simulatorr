local SoundService = game:GetService("SoundService")
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Create the click sound
local clickSound = Instance.new("Sound")
clickSound.Name = "ButtonClickSound"
clickSound.SoundId = "rbxassetid://452267918"
clickSound.Volume = 0.5
clickSound.RollOffMaxDistance = 0
clickSound.Parent = SoundService

-- Function to play click sound
local function playClick()
    clickSound:Play()
end

-- Function to add sound to a single button
local function addSoundToButton(button)
    if button:IsA("TextButton") or button:IsA("ImageButton") then
        button.MouseButton1Click:Connect(playClick)
    end
end

-- Function to add sound to all buttons in a container
local function addSoundToContainer(container)
    for _, descendant in ipairs(container:GetDescendants()) do
        addSoundToButton(descendant)
    end
    -- Also catch buttons added later
    container.DescendantAdded:Connect(function(descendant)
        task.wait() -- wait one frame for it to fully load
        addSoundToButton(descendant)
    end)
end

-- Wait for all GUIs to load then apply to everything
task.wait(2)

-- Apply to all existing ScreenGuis
for _, gui in ipairs(playerGui:GetChildren()) do
    if gui:IsA("ScreenGui") then
        addSoundToContainer(gui)
    end
end

-- Also catch new ScreenGuis added after load
playerGui.ChildAdded:Connect(function(gui)
    task.wait(1)
    if gui:IsA("ScreenGui") then
        addSoundToContainer(gui)
    end
end)

print("[ButtonSoundManager] Click sounds added to all buttons!")