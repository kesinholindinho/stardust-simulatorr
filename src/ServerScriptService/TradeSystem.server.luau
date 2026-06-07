local TradeSystem = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local tradeAction = ReplicatedStorage:WaitForChild("TradeAction")
local tradeSync = ReplicatedStorage:WaitForChild("TradeSync")
local stardustSync = ReplicatedStorage:FindFirstChild("StardustSync")

-- ============================================
-- TRADE STATE
-- ============================================
local pendingTrades = {} -- pendingTrades[player] = {partner, offeredPets, accepted, confirming}
local activeTradeRequests = {} -- {from = player, to = player, timestamp = time}

-- ============================================
-- HELPERS
-- ============================================
local function getPlayerData(player)
    if _G.getPlayerData then
        return _G.getPlayerData(player)
    end
    -- Fallback: access playerDataCache directly
    for _, v in ipairs(game.ServerScriptService:GetChildren()) do
        if v.Name == "GameLogic" and v:IsA("Script") then
            -- Can't access locals, rely on _G
        end
    end
    return nil
end

local function syncToClient(player)
    if _G.syncToClient then
        _G.syncToClient(player)
    end
end

local function notifyPetSpawn(player)
    if _G.notifyPetSpawn then
        _G.notifyPetSpawn(player)
    end
end

-- ============================================
-- VALIDATE PETS
-- ============================================
local function validatePets(data, petIds)
    for _, id in ipairs(petIds) do
        local found = false
        for _, pet in ipairs(data.ownedPets) do
            if pet.id == id then
                if pet.equipped then return false, "A pet is equipped" end
                if pet.locked then return false, "A pet is locked" end
                found = true
                break
            end
        end
        if not found then return false, "Pet not found" end
    end
    return true
end

-- ============================================
-- EXECUTE TRADE
-- ============================================
local function executeTrade(player1, player2)
    local trade1 = pendingTrades[player1]
    local trade2 = pendingTrades[player2]
    if not trade1 or not trade2 then return end

    local data1 = getPlayerData(player1)
    local data2 = getPlayerData(player2)
    if not data1 or not data2 then
        tradeSync:FireClient(player1, "tradeFailed", "Player data not found")
        tradeSync:FireClient(player2, "tradeFailed", "Player data not found")
        pendingTrades[player1] = nil
        pendingTrades[player2] = nil
        return
    end

    -- Validate: all offered pets still exist, are unequipped and unlocked
    local ok1, err1 = validatePets(data1, trade1.offeredPets)
    local ok2, err2 = validatePets(data2, trade2.offeredPets)

    if not ok1 or not ok2 then
        tradeSync:FireClient(player1, "tradeFailed", err1 or err2)
        tradeSync:FireClient(player2, "tradeFailed", err1 or err2)
        pendingTrades[player1] = nil
        pendingTrades[player2] = nil
        return
    end

    -- Remove pets from each player and give to the other
    local function transferPets(fromData, toData, petIds)
        local transferredPets = {}
        local newPets = {}
        for _, pet in ipairs(fromData.ownedPets) do
            local isOffered = false
            for _, id in ipairs(petIds) do
                if pet.id == id then
                    isOffered = true
                    table.insert(transferredPets, pet)
                    break
                end
            end
            if not isOffered then
                table.insert(newPets, pet)
            end
        end
        fromData.ownedPets = newPets
        for _, pet in ipairs(transferredPets) do
            table.insert(toData.ownedPets, pet)
        end
        return transferredPets
    end

    local pets1to2 = transferPets(data1, data2, trade1.offeredPets)
    local pets2to1 = transferPets(data2, data1, trade2.offeredPets)

    -- Save both players
    if _G.savePlayerData then
        pcall(_G.savePlayerData, player1)
        pcall(_G.savePlayerData, player2)
    end

    -- Sync both players
    syncToClient(player1)
    syncToClient(player2)

    -- Notify pet follow system
    notifyPetSpawn(player1)
    notifyPetSpawn(player2)

    -- Notify both players trade succeeded
    tradeSync:FireClient(player1, "tradeSuccess", pets2to1)
    tradeSync:FireClient(player2, "tradeSuccess", pets1to2)

    pendingTrades[player1] = nil
    pendingTrades[player2] = nil

    print(string.format("[Trade] %s and %s completed a trade!", player1.Name, player2.Name))
end

-- ============================================
-- 5 SECOND CONFIRM WINDOW
-- ============================================
local function startConfirmWindow(player1, player2)
    local t1 = pendingTrades[player1]
    local t2 = pendingTrades[player2]
    if t1 then t1.confirming = true end
    if t2 then t2.confirming = true end

    tradeSync:FireClient(player1, "tradeConfirmWindow", 5)
    tradeSync:FireClient(player2, "tradeConfirmWindow", 5)

    task.delay(5, function()
        local t1 = pendingTrades[player1]
        local t2 = pendingTrades[player2]
        if t1 and t2 and t1.confirming and t2.confirming then
            executeTrade(player1, player2)
        end
    end)
end

-- ============================================
-- CLEANUP STALE REQUESTS
-- ============================================
local function cleanStaleRequests()
    local now = tick()
    for i = #activeTradeRequests, 1, -1 do
        local req = activeTradeRequests[i]
        if now - req.timestamp > 30 then
            -- Auto-decline stale request
            if req.to and req.to.Parent then
                tradeSync:FireClient(req.to, "tradeRequestExpired")
            end
            if req.from and req.from.Parent then
                tradeSync:FireClient(req.from, "tradeRequestExpired")
            end
            table.remove(activeTradeRequests, i)
        end
    end
end

-- ============================================
-- FIND REQUEST
-- ============================================
local function findRequestTo(player)
    for _, req in ipairs(activeTradeRequests) do
        if req.to == player then
            return req
        end
    end
    return nil
end

local function findRequestFrom(player)
    for _, req in ipairs(activeTradeRequests) do
        if req.from == player then
            return req
        end
    end
    return nil
end

local function removeRequestsInvolving(player)
    for i = #activeTradeRequests, 1, -1 do
        local req = activeTradeRequests[i]
        if req.from == player or req.to == player then
            table.remove(activeTradeRequests, i)
        end
    end
end

-- ============================================
-- CANCEL ACTIVE TRADE
-- ============================================
local function cancelTrade(player)
    local trade = pendingTrades[player]
    if not trade then return end
    local partner = trade.partner

    pendingTrades[player] = nil
    if partner and pendingTrades[partner] then
        pendingTrades[partner] = nil
        tradeSync:FireClient(partner, "tradeCancelled")
    end

    tradeSync:FireClient(player, "tradeCancelled")
    removeRequestsInvolving(player)
end

-- ============================================
-- HANDLE TRADE ACTIONS
-- ============================================
tradeAction.OnServerEvent:Connect(function(player, action, ...)
    local args = {...}

    if action == "sendRequest" then
        -- player wants to trade with targetPlayer
        local targetPlayer = args[1]
        if not targetPlayer or not targetPlayer:IsA("Player") then return end
        if targetPlayer == player then return end

        -- Check if either player is already in a trade
        if pendingTrades[player] or pendingTrades[targetPlayer] then
            tradeSync:FireClient(player, "tradeFailed", "Already in a trade")
            return
        end

        -- Check if there's already a pending request to this player
        for _, req in ipairs(activeTradeRequests) do
            if req.from == player and req.to == targetPlayer then
                tradeSync:FireClient(player, "tradeFailed", "Request already sent")
                return
            end
        end

        -- Add request
        table.insert(activeTradeRequests, {
            from = player,
            to = targetPlayer,
            timestamp = tick()
        })

        -- Notify target player
        tradeSync:FireClient(targetPlayer, "tradeRequest", player)

        -- Notify sender
        tradeSync:FireClient(player, "tradeRequestSent", targetPlayer)

        print(string.format("[Trade] %s sent trade request to %s", player.Name, targetPlayer.Name))

    elseif action == "cancelRequest" then
        -- Cancel pending request
        for i = #activeTradeRequests, 1, -1 do
            local req = activeTradeRequests[i]
            if req.from == player then
                if req.to and req.to.Parent then
                    tradeSync:FireClient(req.to, "tradeRequestExpired")
                end
                table.remove(activeTradeRequests, i)
                break
            end
        end
        tradeSync:FireClient(player, "tradeRequestCancelled")

    elseif action == "acceptRequest" then
        -- Accept incoming trade request
        local fromPlayer = args[1]
        if not fromPlayer then return end

        -- Find the request
        local foundReq = nil
        for i, req in ipairs(activeTradeRequests) do
            if req.from == fromPlayer and req.to == player then
                foundReq = req
                table.remove(activeTradeRequests, i)
                break
            end
        end

        if not foundReq then
            tradeSync:FireClient(player, "tradeFailed", "Request no longer available")
            return
        end

        -- Check if either is already in a trade
        if pendingTrades[player] or pendingTrades[fromPlayer] then
            tradeSync:FireClient(player, "tradeFailed", "Already in a trade")
            return
        end

        -- Create trade for both players
        pendingTrades[player] = {
            partner = fromPlayer,
            offeredPets = {},
            accepted = false,
            confirming = false
        }
        pendingTrades[fromPlayer] = {
            partner = player,
            offeredPets = {},
            accepted = false,
            confirming = false
        }

        -- Notify both players
        tradeSync:FireClient(player, "tradeStarted", fromPlayer)
        tradeSync:FireClient(fromPlayer, "tradeStarted", player)

        print(string.format("[Trade] %s and %s started a trade", player.Name, fromPlayer.Name))

    elseif action == "declineRequest" then
        -- Decline incoming trade request
        local fromPlayer = args[1]
        for i, req in ipairs(activeTradeRequests) do
            if req.from == fromPlayer and req.to == player then
                table.remove(activeTradeRequests, i)
                break
            end
        end
        tradeSync:FireClient(player, "tradeRequestDeclined")
        if fromPlayer and fromPlayer.Parent then
            tradeSync:FireClient(fromPlayer, "tradeRequestDeclined")
        end

    elseif action == "offerPet" then
        -- Add pet to trade offer
        local petId = args[1]
        local trade = pendingTrades[player]
        if not trade then return end

        -- Max 9 pets
        if #trade.offeredPets >= 9 then
            tradeSync:FireClient(player, "tradeFailed", "Maximum 9 pets per trade")
            return
        end

        -- Check pet isn't already offered
        for _, id in ipairs(trade.offeredPets) do
            if id == petId then return end
        end

        -- Validate pet exists, is unequipped and unlocked
        local data = getPlayerData(player)
        if not data then return end

        local valid = false
        for _, pet in ipairs(data.ownedPets) do
            if pet.id == petId then
                if pet.equipped then
                    tradeSync:FireClient(player, "tradeFailed", "Unequip pet first")
                    return
                end
                if pet.locked then
                    tradeSync:FireClient(player, "tradeFailed", "Unlock pet first")
                    return
                end
                valid = true
                break
            end
        end

        if not valid then
            tradeSync:FireClient(player, "tradeFailed", "Pet not found")
            return
        end

        table.insert(trade.offeredPets, petId)
        trade.accepted = false
        trade.confirming = false

        -- Reset partner's accepted state too
        local partner = trade.partner
        if partner and pendingTrades[partner] then
            pendingTrades[partner].accepted = false
            pendingTrades[partner].confirming = false
        end

        -- Notify both players of updated offers
        local partnerData = getPlayerData(partner)
        local myData = data

        -- Send full offer info to both
        local function getPetInfo(data, petIds)
            local pets = {}
            for _, id in ipairs(petIds) do
                for _, pet in ipairs(data.ownedPets) do
                    if pet.id == id then
                        table.insert(pets, pet)
                        break
                    end
                end
            end
            return pets
        end

        local myOfferedInfo = getPetInfo(myData, trade.offeredPets)
        local partnerTrade = pendingTrades[partner]
        local partnerOfferedInfo = partnerTrade and getPetInfo(partnerData, partnerTrade.offeredPets) or {}

        tradeSync:FireClient(player, "tradeUpdated", myOfferedInfo, partnerOfferedInfo, false, false)
        tradeSync:FireClient(partner, "tradeUpdated", partnerOfferedInfo, myOfferedInfo, false, false)

    elseif action == "removeOffer" then
        -- Remove pet from trade offer
        local petId = args[1]
        local trade = pendingTrades[player]
        if not trade then return end

        for i, id in ipairs(trade.offeredPets) do
            if id == petId then
                table.remove(trade.offeredPets, i)
                break
            end
        end

        trade.accepted = false
        trade.confirming = false

        local partner = trade.partner
        if partner and pendingTrades[partner] then
            pendingTrades[partner].accepted = false
            pendingTrades[partner].confirming = false
        end

        -- Notify both
        local myData = getPlayerData(player)
        local partnerData = getPlayerData(partner)

        local function getPetInfo(data, petIds)
            local pets = {}
            for _, id in ipairs(petIds) do
                for _, pet in ipairs(data.ownedPets) do
                    if pet.id == id then
                        table.insert(pets, pet)
                        break
                    end
                end
            end
            return pets
        end

        local myOfferedInfo = getPetInfo(myData, trade.offeredPets)
        local partnerTrade = pendingTrades[partner]
        local partnerOfferedInfo = partnerTrade and getPetInfo(partnerData, partnerTrade.offeredPets) or {}

        tradeSync:FireClient(player, "tradeUpdated", myOfferedInfo, partnerOfferedInfo, false, false)
        tradeSync:FireClient(partner, "tradeUpdated", partnerOfferedInfo, myOfferedInfo, false, false)

    elseif action == "acceptTrade" then
        -- Player accepts the trade (ready to confirm)
        local trade = pendingTrades[player]
        if not trade then return end

        trade.accepted = true
        trade.confirming = false

        local partner = trade.partner
        local partnerTrade = pendingTrades[partner]

        -- Check if both accepted
        if partnerTrade and partnerTrade.accepted then
            -- Both accepted, start 5s confirm window
            startConfirmWindow(player, partner)
        else
            -- Notify partner that this player accepted
            local myData = getPlayerData(player)
            local partnerData = getPlayerData(partner)

            local function getPetInfo(data, petIds)
                local pets = {}
                for _, id in ipairs(petIds) do
                    for _, pet in ipairs(data.ownedPets) do
                        if pet.id == id then
                            table.insert(pets, pet)
                            break
                        end
                    end
                end
                return pets
            end

            local myOfferedInfo = getPetInfo(myData, trade.offeredPets)
            local partnerOfferedInfo = partnerTrade and getPetInfo(partnerData, partnerTrade.offeredPets) or {}

            tradeSync:FireClient(player, "tradeUpdated", myOfferedInfo, partnerOfferedInfo, true, false)
            tradeSync:FireClient(partner, "tradeUpdated", partnerOfferedInfo, myOfferedInfo, false, true)
        end

    elseif action == "cancelTrade" then
        cancelTrade(player)

    elseif action == "confirmTrade" then
        -- Player confirms during 5s window (no-op, trade auto-executes after 5s)
        -- This is just for the client to acknowledge
        local trade = pendingTrades[player]
        if trade then
            trade.confirming = true
        end
    end
end)

-- ============================================
-- CLEANUP ON PLAYER LEAVE
-- ============================================
Players.PlayerRemoving:Connect(function(player)
    -- Cancel any active trade
    cancelTrade(player)
    removeRequestsInvolving(player)
    pendingTrades[player] = nil
end)

-- ============================================
-- PERIODIC CLEANUP
-- ============================================
task.spawn(function()
    while task.wait(10) do
        cleanStaleRequests()
    end
end)

print("[TradeSystem] Loaded")