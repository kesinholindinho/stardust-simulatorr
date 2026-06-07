-- Gamepass Manager - Handles gamepass benefits
local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Gamepass IDs
local GAMEPASS_2X_STARDUST = 1817317562
local GAMEPASS_MORE_PETS = 1816119729
local GAMEPASS_2X_XP = 1814337737
local GAMEPASS_AUTO_CLICK_STAR = 1818211451

-- Store players who have the gamepasses
local playersWith2xStardust = {}
local playersWithMorePets = {}
local playersWith2xXP = {}
local playersWithAutoClickStar = {}

-- Function to check if player owns the gamepasses
local function checkGamepassOwnership(player)
	-- Check 2x Stardust gamepass
	local success1, hasGamepass1 = pcall(function()
		return MarketplaceService:UserOwnsGamePassAsync(player.UserId, GAMEPASS_2X_STARDUST)
	end)
	
	if success1 and hasGamepass1 then
		playersWith2xStardust[player.UserId] = true
		print("[GamepassManager] " .. player.Name .. " has 2x Stardust gamepass")
	else
		playersWith2xStardust[player.UserId] = false
	end
	
	-- Check More Pets gamepass
	local success2, hasGamepass2 = pcall(function()
		return MarketplaceService:UserOwnsGamePassAsync(player.UserId, GAMEPASS_MORE_PETS)
	end)
	
	if success2 and hasGamepass2 then
		playersWithMorePets[player.UserId] = true
		print("[GamepassManager] " .. player.Name .. " has More Pets gamepass")
	else
		playersWithMorePets[player.UserId] = false
	end
	
	-- Check 2x XP gamepass
	local success3, hasGamepass3 = pcall(function()
		return MarketplaceService:UserOwnsGamePassAsync(player.UserId, GAMEPASS_2X_XP)
	end)
	
	if success3 and hasGamepass3 then
		playersWith2xXP[player.UserId] = true
		print("[GamepassManager] " .. player.Name .. " has 2x XP gamepass")
	else
		playersWith2xXP[player.UserId] = false
	end
	
	-- Check Auto Click Star gamepass
	local success4, hasGamepass4 = pcall(function()
		return MarketplaceService:UserOwnsGamePassAsync(player.UserId, GAMEPASS_AUTO_CLICK_STAR)
	end)
	
	if success4 and hasGamepass4 then
		playersWithAutoClickStar[player.UserId] = true
		print("[GamepassManager] " .. player.Name .. " has Auto Click Star gamepass")
	else
		playersWithAutoClickStar[player.UserId] = false
	end
end

-- Function to check if player has 2x Stardust
local function has2xStardust(player)
	return playersWith2xStardust[player.UserId] == true
end

-- Function to check if player has More Pets
local function hasMorePets(player)
	return playersWithMorePets[player.UserId] == true
end

-- Function to check if player has 2x XP
local function has2xXP(player)
	return playersWith2xXP[player.UserId] == true
end

-- Function to check if player has Auto Click Star
local function hasAutoClickStar(player)
	return playersWithAutoClickStar[player.UserId] == true
end

-- Export functions for other scripts to use
_G.has2xStardustGamepass = has2xStardust
_G.hasMorePetsGamepass = hasMorePets
_G.has2xXPGamepass = has2xXP
_G.hasAutoClickStarGamepass = hasAutoClickStar

-- Handle player joining
local function onPlayerAdded(player)
	-- Check gamepass ownership when player joins
	checkGamepassOwnership(player)
end

-- Handle gamepass purchase
MarketplaceService.ProcessReceipt = function(receiptInfo)
	local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
	
	if receiptInfo.ProductId == GAMEPASS_2X_STARDUST then
		if player then
			playersWith2xStardust[player.UserId] = true
			print("[GamepassManager] " .. player.Name .. " purchased 2x Stardust gamepass")
			
			-- Notify player they have 2x Stardust
			local GameAction = ReplicatedStorage:FindFirstChild("GameAction")
			if GameAction then
				GameAction:FireClient(player, "gamepassPurchased", "2x Stardust")
			end
		end
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end
	
	if receiptInfo.ProductId == GAMEPASS_MORE_PETS then
		if player then
			playersWithMorePets[player.UserId] = true
			print("[GamepassManager] " .. player.Name .. " purchased More Pets gamepass")
			
			-- Notify player they have More Pets
			local GameAction = ReplicatedStorage:FindFirstChild("GameAction")
			if GameAction then
				GameAction:FireClient(player, "gamepassPurchased", "More Pets")
			end
		end
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end
	
	if receiptInfo.ProductId == GAMEPASS_2X_XP then
		if player then
			playersWith2xXP[player.UserId] = true
			print("[GamepassManager] " .. player.Name .. " purchased 2x XP gamepass")
			
			-- Notify player they have 2x XP
			local GameAction = ReplicatedStorage:FindFirstChild("GameAction")
			if GameAction then
				GameAction:FireClient(player, "gamepassPurchased", "2x XP")
			end
		end
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end
	
	if receiptInfo.ProductId == GAMEPASS_AUTO_CLICK_STAR then
		if player then
			playersWithAutoClickStar[player.UserId] = true
			print("[GamepassManager] " .. player.Name .. " purchased Auto Click Star gamepass")
			
			-- Notify player they have Auto Click Star
			local GameAction = ReplicatedStorage:FindFirstChild("GameAction")
			if GameAction then
				GameAction:FireClient(player, "gamepassPurchased", "Auto Click Star")
			end
		end
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end
	
	return Enum.ProductPurchaseDecision.NotProcessed
end

-- Connect player added event
Players.PlayerAdded:Connect(onPlayerAdded)

-- Also check players already in game
for _, player in ipairs(Players:GetPlayers()) do
	checkGamepassOwnership(player)
end

print("[GamepassManager] Loaded successfully")