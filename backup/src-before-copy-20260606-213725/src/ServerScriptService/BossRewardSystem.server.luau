-- Boss Reward System
-- Detects when player interacts with the boss and triggers the boss defeat event
-- The actual reward is handled by GameLogic

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

print("👑 Boss Reward System Started!")

-- Get or create RemoteEvents
local function getOrCreateRemote(name)
    local remote = ReplicatedStorage:FindFirstChild(name)
    if not remote then
        remote = Instance.new("RemoteEvent")
        remote.Name = name
        remote.Parent = ReplicatedStorage
    end
    return remote
end

local gameAction = getOrCreateRemote("GameAction")

-- ============================================
-- BOSS TOUCH DETECTION
-- ============================================
-- Detect when player touches the boss area
local bossModel = game.Workspace:FindFirstChild("Pet Boss")

if bossModel then
    -- Find or create a hitbox for the boss
    local hitbox = bossModel:FindFirstChild("BossHitbox")
    if not hitbox then
        hitbox = Instance.new("Part")
        hitbox.Name = "BossHitbox"
        hitbox.Size = Vector3.new(15, 15, 15)
        hitbox.Transparency = 1
        hitbox.Anchored = true
        hitbox.CanCollide = false
        hitbox.Parent = bossModel
    end
    
    -- Position hitbox at boss location
    local bossPivot = bossModel:GetPivot()
    hitbox.CFrame = bossPivot
    
    -- Track players who have touched the boss recently (debounce)
    local touchDebounce = {}
    
    hitbox.Touched:Connect(function(otherPart)
        local character = otherPart.Parent
        local player = Players:GetPlayerFromCharacter(character)
        
        if player and not touchDebounce[player] then
            touchDebounce[player] = true
            
            -- Fire boss defeated event to GameLogic
            gameAction:FireServer("bossDefeated")
            
            print("[BossReward] " .. player.Name .. " touched the boss area!")
            
            -- Clear debounce after 5 seconds
            task.delay(5, function()
                touchDebounce[player] = nil
            end)
        end
    end)
    
    print("[BossReward] Boss hitbox created at", bossPivot.Position)
else
    warn("[BossReward] Boss model not found in Workspace!")
end

-- ============================================
-- BOSS ARENA TELEPORT DETECTION
-- ============================================
-- Also detect when player enters the boss arena
local bossArena = game.Workspace:FindFirstChild("ArenaBossStarPlatform ")
if bossArena then
    -- Find the arena part
    local arenaPart = nil
    for _, child in ipairs(bossArena:GetChildren()) do
        if child:IsA("BasePart") then
            arenaPart = child
            break
        end
    end
    
    if arenaPart then
        local arenaDebounce = {}
        
        arenaPart.Touched:Connect(function(otherPart)
            local character = otherPart.Parent
            local player = Players:GetPlayerFromCharacter(character)
            
            if player and not arenaDebounce[player] then
                arenaDebounce[player] = true
                
                -- Fire boss defeated event to GameLogic
                gameAction:FireServer("bossDefeated")
                
                print("[BossReward] " .. player.Name .. " entered the boss arena!")
                
                -- Clear debounce after 5 seconds
                task.delay(5, function()
                    arenaDebounce[player] = nil
                end)
            end
        end)
        
        print("[BossReward] Boss arena detection active")
    end
end

print("👑 Boss Reward System Fully Loaded!")