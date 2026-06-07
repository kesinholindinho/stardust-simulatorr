-- Inventory Server Script
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

-- QUEST SYSTEM INTEGRATION: Cache QuestEvents reference
local QuestEvents = ServerStorage:WaitForChild("QuestEvents")

local inventoryEvent = ReplicatedStorage:WaitForChild("InventoryAction")
local itemStardustEvent = ReplicatedStorage:WaitForChild("ItemStardustEvent")

-- Listen for quest item rewards (from QuestManager)
-- Use WaitForChild to ensure QuestManager has created the event first
local questItemRewardEvent = ServerStorage:WaitForChild("QuestItemReward")
questItemRewardEvent.Event:Connect(function(player, itemName, quantity)
	addItem(player, itemName, quantity or 1)
	print("[Inventory] Added quest reward item to " .. player.Name .. ": " .. itemName .. " x" .. tostring(quantity or 1))
end)
print("[Inventory] Connected to QuestItemReward event")

local ITEM_DATA = {
	["Star Fragment"] = {stardustReward = 50},
	["Shooting Star"] = {stardustReward = 200},
	["Moon Stone"] = {stardustReward = 100},
	["Magic Dust"] = {stardustReward = 25},
	["Bright Star"] = {stardustReward = 150},
	["Crystal Star"] = {stardustReward = 500},
	["Comet Core"] = {stardustReward = 1000},
	["Nebula Dust"] = {stardustReward = 300},
	-- Gacha consumables
	["Crystal Shard"] = {effect = "stardustBoost", duration = 300, multiplier = 2}, -- 2x Stardust for 5 min
	["XP Boost"] = {effect = "xpBoost", duration = 600, multiplier = 2}, -- 2x XP for 10 min

}

local playerInventories = {}

local function getInventory(player)
	if not playerInventories[player] then
		playerInventories[player] = {}
	end
	return playerInventories[player]
end

local function addItem(player, itemName, quantity)
	local inventory = getInventory(player)
	inventory[itemName] = (inventory[itemName] or 0) + quantity
	inventoryEvent:FireClient(player, "InventoryUpdate", inventory)
end

local function useItem(player, itemName)
	local itemData = ITEM_DATA[itemName]
	if not itemData then return false, "Item not found" end
	
	local inventory = getInventory(player)
	if not inventory[itemName] or inventory[itemName] <= 0 then
		return false, "You don't have this item"
	end
	
	inventory[itemName] = inventory[itemName] - 1
	if inventory[itemName] <= 0 then
		inventory[itemName] = nil
	end
	
	-- Handle consumable effects
	if itemData.effect == "stardustBoost" then
		-- Crystal Shard: 2x Stardust for 5 minutes
		local playerData = _G.playerData
		if playerData and playerData[player] then
			local data = playerData[player]
			data.stardustBoostEndTime = os.time() + itemData.duration
			data.stardustBoostMultiplier = itemData.multiplier
			print("[Inventory] " .. player.Name .. " used Crystal Shard - 2x Stardust for 5 min!")
			
			-- Auto-remove boost after duration
			task.delay(itemData.duration, function()
				if playerData[player] then
					playerData[player].stardustBoostEndTime = nil
					playerData[player].stardustBoostMultiplier = nil
					print("[Inventory] " .. player.Name .. " Stardust boost expired")
				end
			end)
		end
		inventoryEvent:FireClient(player, "InventoryUpdate", inventory)
		inventoryEvent:FireClient(player, "ItemUsed", itemName, "2x Stardust for 5 min")
		QuestEvents.OnItemUsed:Fire(player)
		return true
		
	elseif itemData.effect == "xpBoost" then
		-- XP Boost: 2x XP for 10 minutes
		local playerData = _G.playerData
		if playerData and playerData[player] then
			local data = playerData[player]
			data.xpBoostEndTime = os.time() + itemData.duration
			data.xpBoostMultiplier = itemData.multiplier
			print("[Inventory] " .. player.Name .. " used XP Boost - 2x XP for 10 min!")
			
			-- Auto-remove boost after duration
			task.delay(itemData.duration, function()
				if playerData[player] then
					playerData[player].xpBoostEndTime = nil
					playerData[player].xpBoostMultiplier = nil
					print("[Inventory] " .. player.Name .. " XP boost expired")
				end
			end)
		end
		inventoryEvent:FireClient(player, "InventoryUpdate", inventory)
		inventoryEvent:FireClient(player, "ItemUsed", itemName, "2x XP for 10 min")
		QuestEvents.OnItemUsed:Fire(player)
		return true
		
	else
		-- Standard stardust-reward items
		itemStardustEvent:Fire(player, itemData.stardustReward)
		print("[Inventory] Fired ItemStardustEvent for", player.Name, "amount:", itemData.stardustReward)
		QuestEvents.OnItemUsed:Fire(player)
		inventoryEvent:FireClient(player, "InventoryUpdate", inventory)
		inventoryEvent:FireClient(player, "ItemUsed", itemName, itemData.stardustReward)
		print("[Inventory] " .. player.Name .. " used " .. itemName .. " gained " .. itemData.stardustReward)
		return true
	end
end

inventoryEvent.OnServerEvent:Connect(function(player, action, ...)
	local args = {...}
	
	if action == "UseItem" then
		local success, msg = useItem(player, args[1])
		if not success then
			inventoryEvent:FireClient(player, "Error", msg)
		end
	elseif action == "GetInventory" then
		inventoryEvent:FireClient(player, "InventoryUpdate", getInventory(player))
	elseif action == "AddItem" then
		addItem(player, args[1], args[2] or 1)
	end
end)

local function initPlayer(player)
	-- Evitar inicialização duplicada
	if playerInventories[player] then
		return
	end
	
	playerInventories[player] = {}
	
	addItem(player, "Star Fragment", 15)
	addItem(player, "Shooting Star", 3)
	addItem(player, "Moon Stone", 7)
	addItem(player, "Magic Dust", 25)
	addItem(player, "Bright Star", 5)
	addItem(player, "Crystal Star", 2)
	addItem(player, "Comet Core", 1)
	addItem(player, "Nebula Dust", 4)
	
	print("[Inventory] Initialized for " .. player.Name)
end

Players.PlayerAdded:Connect(initPlayer)
for _, p in ipairs(Players:GetPlayers()) do initPlayer(p) end
Players.PlayerRemoving:Connect(function(p) playerInventories[p] = nil end)

print("[Inventory] Server Script initialized!")

-- PART 5 COMPLETE
