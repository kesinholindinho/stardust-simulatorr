-- CrystalTreeAttackSystem
-- Handles the Crystal Tree boss attack system with TWO separate models:
-- 1. Boss Crystal Tree = main boss statue (rises when player enters area)
-- 2. Attack Crystal Tree = crystal that rises during attacks

local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local crystalAttackSoundEvent = ReplicatedStorage:WaitForChild("CrystalAttackSoundEvent")

-- ============================================
-- REFERENCES
-- ============================================
local crystalTreeFolder = workspace:WaitForChild("Crstal Tree pasta")
local bossModel = crystalTreeFolder:WaitForChild("Boss Crystal Tree")
local attackModel = crystalTreeFolder:WaitForChild("Attack Crystal Tree")
local areaCrystal = crystalTreeFolder:WaitForChild("Area Crystal")

local ATTACK_SPIN_REVS = 3  -- Number of full revolutions during rise/sink

-- Base rotation for the Attack Crystal Tree (preserves its visual orientation)
-- This is the model's natural rotation so the crystal looks correct when positioned
local ATTACK_CRYSTAL_BASE_ROTATION = CFrame.fromEulerAnglesXYZ(math.rad(-0.108), math.rad(69.583), math.rad(1.315))

-- ============================================
-- CONFIGURATION
-- ============================================
local ENTRY_WAIT_DURATION = 4      -- Seconds to wait before boss rises after player enters
local BOSS_RISE_DURATION = 2      -- Seconds for boss to rise from underground
local POST_RISE_WAIT = 2         -- Seconds to wait after boss rises before attack loop starts
local ATTACK_LOOP_INTERVAL = 4   -- Seconds between attacks
local WARNING_DURATION = 1.5     -- Seconds for warning circle to shrink
local ATTACK_RISE_DURATION = 1.5 -- Seconds for attack crystal to rise
local ATTACK_STAY_DURATION = 2   -- Seconds attack crystal stays above ground
local ATTACK_SINK_DURATION = 2.0 -- Seconds for attack crystal to sink
local ATTACK_DAMAGE = 25         -- Damage dealt to players
local CIRCLE_START_SIZE = 30     -- Starting diameter of warning circle
local CIRCLE_END_SIZE = 2        -- Ending diameter of warning circle

-- ============================================
-- BOSS POSITIONS
-- ============================================
-- Only Y changes between underground and aboveground.
-- Rotation is captured from the model's Studio placement so it stays upright.
local BOSS_UNDERGROUND_Y = 3086.58
local BOSS_ABOVEGROUND_Y = 3216.255

-- ============================================
-- STATE
-- ============================================
local isBossAboveGround = false
local isAttacking = false
local attackLoopRunning = false

-- ============================================
-- HELPER FUNCTIONS
-- ============================================

-- Smoothly tween a model's pivot
local function tweenModelPivot(model, targetCFrame, duration, easingStyle, easingDirection)
	local startCFrame = model:GetPivot()
	local startTime = tick()

	while true do
		local elapsed = tick() - startTime
		local alpha = math.clamp(elapsed / duration, 0, 1)
		alpha = TweenService:GetValue(alpha, easingStyle, easingDirection)
		model:PivotTo(startCFrame:Lerp(targetCFrame, alpha))
		if alpha >= 1 then break end
		task.wait()
	end
end

-- Rise with spin animation using Heartbeat for smooth frame-by-frame movement
-- Spin starts fast underground and slows down as it reaches the surface
local RunService = game:GetService("RunService")

local function riseWithSpin(model, startCFrame, endCFrame, duration)
	local startPos = startCFrame.Position
	local endPos = endCFrame.Position
	-- Preserve the boss's base rotation (from the end CFrame)
	local baseRotation = endCFrame - endPos

	local startTime = tick()
	local connection

	connection = RunService.Heartbeat:Connect(function()
		local elapsed = tick() - startTime
		local progress = math.min(elapsed / duration, 1)

		-- Ease out cubic for smooth stop
		local eased = 1 - math.pow(1 - progress, 3)

		-- Interpolate Y position from underground to surface
		local currentY = startPos.Y + (endPos.Y - startPos.Y) * eased

		-- Spin speed decreases as it reaches surface (starts fast, slows down)
		local spinAngle = elapsed * (8 - progress * 6)

		if model and model.PrimaryPart then
			model:PivotTo(
				CFrame.new(startPos.X, currentY, startPos.Z)
				* baseRotation
				* CFrame.Angles(0, spinAngle, 0)
			)
		end

		if progress >= 1 then
			connection:Disconnect()
			-- Final position with clean rotation (no leftover spin)
			if model and model.PrimaryPart then
				model:PivotTo(endCFrame)
			end
		end
	end)
end

-- Tween a model's pivot with spin around Y axis
-- Uses PivotTo to properly move the model while adding spin rotation
local function tweenModelPivotWithSpin(model, targetCFrame, duration, easingStyle, easingDirection, spinRevolutions)
	local startCFrame = model:GetPivot()
	local startPos = startCFrame.Position
	local targetPos = targetCFrame.Position
	local startTime = tick()
	local totalSpinRadians = spinRevolutions * math.pi * 2

	-- Capture the model's base rotation (the rotation without position)
	-- We want to preserve this orientation and add spin on top of it
	local baseRotation = startCFrame - startCFrame.Position

	-- Also capture the target rotation if different from start
	local targetRotation = targetCFrame - targetCFrame.Position
	local useTargetRotation = targetRotation ~= baseRotation

	while true do
		local elapsed = tick() - startTime
		local alpha = math.clamp(elapsed / duration, 0, 1)
		local easedAlpha = TweenService:GetValue(alpha, easingStyle, easingDirection)

		-- Interpolate position
		local currentPos = startPos + (targetPos - startPos) * easedAlpha

		-- Interpolate base rotation if target has different rotation
		local currentBaseRot = useTargetRotation and baseRotation:Lerp(targetRotation, easedAlpha) or baseRotation

		-- Current spin angle (added on top of base rotation)
		local angle = totalSpinRadians * easedAlpha
		local spinRot = CFrame.fromEulerAnglesXYZ(0, angle, 0)

		-- Apply: position + base rotation + spin
		-- The spin is applied AFTER the base rotation so it spins around the world Y axis
		-- which is the vertical axis the crystal should spin around
		local newPivot = CFrame.new(currentPos) * spinRot * currentBaseRot

		model:PivotTo(newPivot)

		if alpha >= 1 then break end
		task.wait()
	end

	-- Set final position to the target CFrame (without extra spin)
	-- The spin was visual-only during the rise; the crystal should end at its base orientation
	model:PivotTo(targetCFrame)
end



-- Check if a player is inside the Area Crystal bounding box
local function isPlayerInArea(player)
	local character = player.Character
	if not character then return false end
	
	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp then return false end
	
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then return false end
	
	local areaCFrame = areaCrystal.CFrame
	local areaSize = areaCrystal.Size
	local localPos = areaCFrame:PointToObjectSpace(hrp.Position)
	local halfSize = areaSize / 2
	
	return math.abs(localPos.X) <= halfSize.X
		and math.abs(localPos.Y) <= halfSize.Y
		and math.abs(localPos.Z) <= halfSize.Z
end

-- Get all players currently inside the area
local function getPlayersInArea()
	local playersInArea = {}
	for _, player in Players:GetPlayers() do
		if isPlayerInArea(player) then
			table.insert(playersInArea, player)
		end
	end
	return playersInArea
end

-- Make a model visible (and ensure all parts are non-collidable)
-- IMPORTANT: HitBOX must always stay invisible!
local function showModel(model)
	local hitbox = model:FindFirstChild("HitBOX")
	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") then
			part.Transparency = 0
			part.CanCollide = false
		end
	end
	-- Ensure HitBOX stays invisible
	if hitbox then
		hitbox.Transparency = 1
	end
end

-- Make a model invisible (and ensure all parts are non-collidable)
local function hideModel(model)
	local hitbox = model:FindFirstChild("HitBOX")
	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") then
			part.Transparency = 1
			part.CanCollide = false
		end
	end
	-- Ensure HitBOX stays invisible
	if hitbox then
		hitbox.Transparency = 1
	end
end

-- Setup Attack Crystal Tree properties before each attack
local function setupAttackModel()
	-- Ensure all parts are non-collidable
	for _, part in attackModel:GetDescendants() do
		if part:IsA("BasePart") then
			part.CanCollide = false
		end
	end
	
	-- Setup HitBOX specifically
	local hitbox = attackModel:FindFirstChild("HitBOX")
	if hitbox then
		hitbox.Transparency = 1
		hitbox.CanCollide = false
		hitbox.CanQuery = false
	end
	
	-- Setup Mesh_0 specifically
	local mesh = attackModel:FindFirstChild("Mesh_0")
	if mesh then
		mesh.CanCollide = false
		mesh.Transparency = 0  -- Visible during attack
	end
end

-- Create a red warning circle on the ground (flat disc using SpecialMesh)
local function createWarningCircle(position)
	local circle = Instance.new("Part")
	circle.Name = "WarningCircle"
	circle.Size = Vector3.new(1, 1, 1)
	circle.CFrame = CFrame.new(position.X, position.Y + 0.1, position.Z)
	circle.Color = Color3.fromRGB(255, 50, 50)
	circle.Transparency = 0.5
	circle.Anchored = true
	circle.CanCollide = false
	circle.CanQuery = false
	circle.CastShadow = false
	circle.Material = Enum.Material.Neon
	circle.Parent = workspace

	local circleMesh = Instance.new("SpecialMesh")
	circleMesh.MeshType = Enum.MeshType.Sphere
	circleMesh.Scale = Vector3.new(CIRCLE_START_SIZE, 0.1, CIRCLE_START_SIZE)
	circleMesh.Parent = circle

	return circle
end

-- Deal damage to players within radius
local function dealDamageInArea(centerPos, radius)
	for _, player in Players:GetPlayers() do
		local character = player.Character
		if character then
			local hrp = character:FindFirstChild("HumanoidRootPart")
			local humanoid = character:FindFirstChildOfClass("Humanoid")

			if hrp and humanoid and humanoid.Health > 0 then
				local distance = (hrp.Position - centerPos).Magnitude
				if distance <= radius then
					humanoid:TakeDamage(ATTACK_DAMAGE)
				end
			end
		end
	end
end

-- ============================================
-- BOSS ANIMATION FUNCTIONS
-- ============================================

-- Helper: build a CFrame that only changes the Y position, keeping X/Z/rotation intact
local function bossCFrameAtY(yPosition)
	local pivot = bossModel:GetPivot()
	local rot = pivot - pivot.Position
	return CFrame.new(pivot.X, yPosition, pivot.Z) * rot
end

-- Animate Boss Crystal Tree rising from underground with a spin to face backwards
local function animateBossRise()
	if isBossAboveGround then return end

	print("[CrystalTreeAttack] Boss rising...")

	local pivot = bossModel:GetPivot()
	local rot = pivot - pivot.Position

	-- Start underground with original rotation
	local undergroundCFrame = CFrame.new(pivot.X, BOSS_UNDERGROUND_Y, pivot.Z) * rot

	-- End aboveground facing backwards (180° Y rotation in world space)
	local backwardsRot = CFrame.Angles(0, math.rad(180), 0) * rot
	local abovegroundCFrame = CFrame.new(pivot.X, BOSS_ABOVEGROUND_Y, pivot.Z) * backwardsRot

	bossModel:PivotTo(undergroundCFrame)
	showModel(bossModel)

	-- Rise with spin, ending facing backwards
	tweenModelPivotWithSpin(bossModel, abovegroundCFrame, BOSS_RISE_DURATION, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out, 1)

	task.wait(BOSS_RISE_DURATION + 0.1)
	isBossAboveGround = true

	print("[CrystalTreeAttack] Boss risen and visible")
end

-- Animate Boss Crystal Tree sinking back underground with a spin back to original facing
local function animateBossSink()
	if not isBossAboveGround then return end
	
	print("[CrystalTreeAttack] Boss sinking...")

	local pivot = bossModel:GetPivot()
	local rot = pivot - pivot.Position

	-- End underground facing original direction (undo the 180° in world space)
	local originalRot = CFrame.Angles(0, math.rad(-180), 0) * rot
	local undergroundCFrame = CFrame.new(pivot.X, BOSS_UNDERGROUND_Y, pivot.Z) * originalRot

	-- Sink with spin back to original facing
	tweenModelPivotWithSpin(bossModel, undergroundCFrame, BOSS_RISE_DURATION, Enum.EasingStyle.Cubic, Enum.EasingDirection.In, 1)
	isBossAboveGround = false
	
	-- Hide boss
	hideModel(bossModel)
	
	print("[CrystalTreeAttack] Boss sunk and hidden")
end

-- ============================================
-- ATTACK FUNCTION
-- ============================================
local function performAttack(targetPlayer)
	if isAttacking then return end
	isAttacking = true

	-- Get target position
	local character = targetPlayer.Character
	if not character then
		isAttacking = false
		return
	end

	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp then
		isAttacking = false
		return
	end

	local targetPos = hrp.Position
	local groundY = targetPos.Y - 1  -- Closer to player level

	print("[CrystalTreeAttack] Attacking player at: " .. tostring(targetPos))

	-- Step 1: Create and shrink warning circle
	local circle = createWarningCircle(Vector3.new(targetPos.X, groundY, targetPos.Z))

	local shrinkTween = TweenService:Create(circle.Mesh, TweenInfo.new(WARNING_DURATION, Enum.EasingStyle.Linear), {
		Scale = Vector3.new(CIRCLE_END_SIZE, 0.1, CIRCLE_END_SIZE)
	})
	shrinkTween:Play()
	shrinkTween.Completed:Wait()
	circle:Destroy()

	-- Step 2: Position Attack Crystal Tree underground at target position
	local UNDERGROUND_DEPTH = 250
	local surfacePos = Vector3.new(targetPos.X, groundY - 19, targetPos.Z)
	local undergroundPos = Vector3.new(targetPos.X, groundY - 19 - UNDERGROUND_DEPTH, targetPos.Z)

	local surfaceCFrame = CFrame.new(surfacePos) * ATTACK_CRYSTAL_BASE_ROTATION
	local undergroundCFrame = CFrame.new(undergroundPos) * ATTACK_CRYSTAL_BASE_ROTATION

	attackModel:PivotTo(undergroundCFrame)
	setupAttackModel()  -- Setup HitBOX and Mesh_0 properties
	showModel(attackModel)
	
	-- Ensure HitBOX stays invisible after showModel
	local hitbox = attackModel:FindFirstChild("HitBOX")
	if hitbox then
		hitbox.Transparency = 1
	end

	-- Step 3: Rise from ground with spin
	-- Play attack sound only for players in the area
	local areaPlayers = getPlayersInArea()
	for _, p in ipairs(areaPlayers) do
		crystalAttackSoundEvent:FireClient(p)
	end

	tweenModelPivotWithSpin(attackModel, surfaceCFrame, ATTACK_RISE_DURATION, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out, ATTACK_SPIN_REVS)

	-- Step 4: Deal damage
	dealDamageInArea(targetPos, 10)

	-- Step 5: Stay above ground
	task.wait(ATTACK_STAY_DURATION)

	-- Step 6: Sink back underground WITH spin (reverse direction)
	tweenModelPivotWithSpin(attackModel, undergroundCFrame, ATTACK_SINK_DURATION, Enum.EasingStyle.Quad, Enum.EasingDirection.In, ATTACK_SPIN_REVS)

	-- Step 7: Hide Attack Crystal Tree (IMPORTANT!)
	hideModel(attackModel)
	
	-- Ensure Mesh_0 is hidden after attack
	local mesh = attackModel:FindFirstChild("Mesh_0")
	if mesh then
		mesh.Transparency = 1
	end
	
	-- Ensure HitBOX stays invisible after hideModel
	local hitbox = attackModel:FindFirstChild("HitBOX")
	if hitbox then
		hitbox.Transparency = 1
	end
	
	print("[CrystalTreeAttack] Attack complete, Attack Crystal Tree hidden")

	isAttacking = false
end

-- ============================================
-- INITIALIZATION
-- ============================================
-- Set PrimaryPart for Boss Crystal Tree so PivotTo works correctly
local bossMesh = bossModel:FindFirstChild("Mesh1.0")
if bossMesh then
	bossModel.PrimaryPart = bossMesh
end

-- Ensure all parts in Attack Crystal Tree are non-collidable
for _, part in attackModel:GetDescendants() do
	if part:IsA("BasePart") then
		part.CanCollide = false
	end
end

-- Setup HitBOX specifically
local hitbox = attackModel:FindFirstChild("HitBOX")
if hitbox then
	hitbox.Transparency = 1
	hitbox.CanCollide = false
	hitbox.CanQuery = false
end

-- Setup Mesh_0 specifically
local mesh = attackModel:FindFirstChild("Mesh_0")
if mesh then
	mesh.CanCollide = false
	mesh.Transparency = 1  -- Hidden at start
end

-- Hide both models at start
hideModel(bossModel)
hideModel(attackModel)
bossModel:PivotTo(bossCFrameAtY(BOSS_UNDERGROUND_Y))

print("[CrystalTreeAttack] Both models initialized as hidden")

-- ============================================
-- MAIN LOOP - AREA DETECTION
-- ============================================
task.spawn(function()
	local wasPlayerInArea = false
	local pendingRise = false
	
	while true do
		task.wait(0.5)
		
		local playersInArea = getPlayersInArea()
		local hasPlayersInArea = #playersInArea > 0
		
		-- Player entered the area
		if hasPlayersInArea and not wasPlayerInArea and not isBossAboveGround and not pendingRise then
			pendingRise = true
			print("[CrystalTreeAttack] Player detected, waiting " .. ENTRY_WAIT_DURATION .. " seconds...")
			
			task.spawn(function()
				task.wait(ENTRY_WAIT_DURATION)
				
				local currentPlayers = getPlayersInArea()
				if #currentPlayers > 0 and not isBossAboveGround then
					-- Animate Boss Crystal Tree rising
					animateBossRise()
					
					-- Wait after rise
					task.wait(POST_RISE_WAIT)
					
					-- Start attack loop
					attackLoopRunning = true
					print("[CrystalTreeAttack] Attack loop started")
					
					while attackLoopRunning and #getPlayersInArea() > 0 do
						task.wait(ATTACK_LOOP_INTERVAL)
						
						if not attackLoopRunning then break end
						
						-- Stop attacking if boss is defeated
						if not _G.GetCrystalBossHP or not _G.GetCrystalBossHP().isAlive then
							break -- stop attacking
						end
						
						local attackTargets = getPlayersInArea()
						if #attackTargets > 0 then
							local randomPlayer = attackTargets[math.random(1, #attackTargets)]
							performAttack(randomPlayer)
						end
					end
					
					print("[CrystalTreeAttack] Attack loop stopped")
				end
				
				pendingRise = false
			end)
		end
		
		-- Players left the area
		if not hasPlayersInArea and wasPlayerInArea then
			attackLoopRunning = false
			pendingRise = false
			
			if isBossAboveGround then
				animateBossSink()
			end
		end
		
		wasPlayerInArea = hasPlayersInArea
	end
end)

print("[CrystalTreeAttack] System initialized!")