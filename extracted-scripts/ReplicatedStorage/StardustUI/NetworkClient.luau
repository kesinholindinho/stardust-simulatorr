local NetworkClient = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- RemoteEvents - Initialize immediately (auto-init pattern)
local gameActionRemote = ReplicatedStorage:WaitForChild("GameAction")
local stardustSync = ReplicatedStorage:FindFirstChild("StardustSync")

-- Callbacks for events
local callbacks = {}

-- ============================================
-- INITIALIZE (kept for backward compatibility, but auto-initializes)
-- ============================================
function NetworkClient.init()
    -- Already initialized at module load time
    -- This function exists for backward compatibility
    
    -- Connect to server events
    if stardustSync then
        stardustSync.OnClientEvent:Connect(function(stardust, starcoins, level, xp, xpNeeded, ownedPets, equippedPets, dailyRewardData)
            if callbacks.onSync then
                callbacks.onSync(stardust, starcoins, level, xp, xpNeeded, ownedPets, equippedPets, dailyRewardData)
            end
        end)
    end
    
    if gameActionRemote then
        gameActionRemote.OnClientEvent:Connect(function(action, ...)
            local args = {...}
            if callbacks.onAction then
                callbacks.onAction(action, args)
            end
        end)
    end
    
    print("[NetworkClient] Initialized")
end

-- ============================================
-- SET CALLBACKS
-- ============================================
function NetworkClient.setCallbacks(onSync, onAction)
    callbacks.onSync = onSync
    callbacks.onAction = onAction
end

-- ============================================
-- SAFE FIRE SERVER
-- ============================================
function NetworkClient.fire(action, ...)
    local args = {...}
    if not gameActionRemote then
        warn("[NetworkClient] gameActionRemote is nil, cannot send '" .. tostring(action) .. "'")
        return false
    end
    local success, err = pcall(function()
        gameActionRemote:FireServer(action, table.unpack(args))
    end)
    if not success then
        warn("[NetworkClient] Failed to send '" .. tostring(action) .. "': " .. tostring(err))
    end
    return success
end

-- ============================================
-- ACTION HELPERS
-- ============================================
function NetworkClient.click()
    return NetworkClient.fire("click")
end

function NetworkClient.sellStardust(amount)
    return NetworkClient.fire("sellStardust", amount)
end

function NetworkClient.buyUpgrade(upgradeName)
    return NetworkClient.fire("buyUpgrade", upgradeName)
end

function NetworkClient.buyEgg(eggName, quantity, useStarcoins)
    return NetworkClient.fire("buyEgg", eggName, quantity or 1, useStarcoins or false)
end

function NetworkClient.equipPet(petId, equip)
    return NetworkClient.fire("equipPet", petId, equip)
end

function NetworkClient.claimDailyReward(day)
    return NetworkClient.fire("claimDailyReward", day)
end

function NetworkClient.goSupernova()
    return NetworkClient.fire("supernova")
end

function NetworkClient.travelToWorld(worldName)
    return NetworkClient.fire("travelToWorld", worldName)
end

function NetworkClient.unlockWorld(worldName)
    return NetworkClient.fire("unlockWorld", worldName)
end

function NetworkClient.useItem(itemName)
    return NetworkClient.fire("useItem", itemName)
end

function NetworkClient.claimQuest(questName)
    return NetworkClient.fire("claimQuest", questName)
end

function NetworkClient.deletePets(petIds)
    return NetworkClient.fire("deletePet", petIds)
end

function NetworkClient.mergePets(petIds)
    return NetworkClient.fire("mergePets", petIds)
end

function NetworkClient.togglePetLock(petId)
    return NetworkClient.fire("petLockToggled", petId)
end

function NetworkClient.autoMergePets()
    return NetworkClient.fire("autoMerge")
end

return NetworkClient