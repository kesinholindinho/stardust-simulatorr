-- CrystalBossClick - Detects clicks on the Boss Crystal Tree model
-- Fires CrystalBossSync RemoteEvent when player clicks the boss

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer

-- Wait for RemoteEvent
local crystalBossSync = ReplicatedStorage:WaitForChild("CrystalBossSync")

print("[CrystalBossClick] Click Handler Started!")

-- ============================================
-- CONFIGURATION
-- ============================================
local BOSS_MODEL_NAME = "Boss Crystal Tree"
local BOSS_PARENT_FOLDER = "Crstal Tree pasta"
local CLICK_COOLDOWN = 0.1 -- Minimum time between clicks (seconds)

-- ============================================
-- STATE
-- ============================================
local lastClickTime = 0
local bossState = {
	isAlive = false,
	isUnderground = false
}

-- ============================================
-- HELPER FUNCTIONS
-- ============================================

-- Check if the clicked part belongs to the boss model
local function isBossPart(part)
	if not part then return false end
	
	-- Check if the part or its ancestors is the Boss Crystal Tree
	local current = part
	while current do
		if current.Name == BOSS_MODEL_NAME then
			-- Verify it's in the correct folder
			if current.Parent and current.Parent.Name == BOSS_PARENT_FOLDER then
				return true
			end
		end
		current = current.Parent
	end
	
	return false
end

-- Check if player is in Area Crystal
local function isInCrystalArea()
	local character = player.Character
	if not character then return false end
	
	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoidRootPart then return false end
	
	local areaPart = game.Workspace:FindFirstChild(BOSS_PARENT_FOLDER)
	if not areaPart then return false end
	areaPart = areaPart:FindFirstChild("Area Crystal")
	if not areaPart then return false end
	
	local playerPos = humanoidRootPart.Position
	local areaCFrame = areaPart.CFrame
	local areaSize = areaPart.Size
	
	local relativePos = areaCFrame:PointToObjectSpace(playerPos)
	return math.abs(relativePos.X) <= areaSize.X / 2 and
		   math.abs(relativePos.Y) <= areaSize.Y / 2 and
		   math.abs(relativePos.Z) <= areaSize.Z / 2
end

-- ============================================
-- REMOTEEVENT HANDLERS
-- ============================================

crystalBossSync.OnClientEvent:Connect(function(action, data)
	if action == "bossStateUpdate" then
		bossState.isAlive = data.isAlive or false
		bossState.isUnderground = data.isUnderground or false
	elseif action == "bossDefeated" then
		bossState.isAlive = false
		bossState.isUnderground = true
	end
end)

-- ============================================
-- CLICK DETECTION
-- ============================================

-- Listen for mouse clicks
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	-- Only handle left mouse button clicks
	if input.UserInputType ~= Enum.UserInputType.MouseButton1 then
		return
	end
	
	-- Don't process if game is handling UI
	if gameProcessed then
		return
	end
	
	-- Check cooldown
	local now = tick()
	if now - lastClickTime < CLICK_COOLDOWN then
		return
	end
	
	-- Check if boss is alive
	if not bossState.isAlive or bossState.isUnderground then
		return
	end
	
	-- Check if player is in the area
	if not isInCrystalArea() then
		return
	end
	
	-- Get what the player clicked on
	local mouse = player:GetMouse()
	if not mouse then return end
	
	local target = mouse.Target
	if not target then return end
	
	-- Check if clicked on boss
	if isBossPart(target) then
		lastClickTime = now
		
		-- Fire event to server
		crystalBossSync:FireServer("clickBoss")
		print("[CrystalBossClick] Clicked on boss!")
	end
end)

-- Request initial boss state
task.wait(1)
crystalBossSync:FireServer("requestState")

print("[CrystalBossClick] Fully Loaded!")