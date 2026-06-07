local EggsPanel = {}

local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContentProvider = game:GetService("ContentProvider")

local Config = require(ReplicatedStorage:WaitForChild("StardustConfig"))
local PanelManager = require(ReplicatedStorage:WaitForChild("StardustUI"):WaitForChild("PanelManager"))
local NetworkClient = require(ReplicatedStorage:WaitForChild("StardustUI"):WaitForChild("NetworkClient"))
local SettingsPanel = require(ReplicatedStorage:WaitForChild("StardustUI"):WaitForChild("Panels"):WaitForChild("SettingsPanel"))

-- ===== MÓDULOS DO SISTEMA DE ABERTURA DE OVOS (4 PARTES) =====
local EggOverlay = require(ReplicatedStorage:WaitForChild("StardustUI"):WaitForChild("Panels"):WaitForChild("EggOverlay"))
local EggExplosion = require(ReplicatedStorage:WaitForChild("StardustUI"):WaitForChild("Panels"):WaitForChild("EggExplosion"))
local EggPetReveal = require(ReplicatedStorage:WaitForChild("StardustUI"):WaitForChild("Panels"):WaitForChild("EggPetReveal"))
local EggClose = require(ReplicatedStorage:WaitForChild("StardustUI"):WaitForChild("Panels"):WaitForChild("EggClose"))

local panel = nil
local eggOpeningPopup = nil

-- ============================================
-- ANIMATION THREAD SAFETY
-- Tracks the current popup's animation state so that
-- when a new popup replaces an old one, the old
-- animation thread exits gracefully
-- ============================================
local currentAnimToken = nil   -- { cancelled: boolean }
local currentAnimConn = nil    -- RenderStepped connection for shake animation

-- ============================================
-- EGG MODEL NAME MAPPING
-- Maps Config.EGGS names to workspace model names
-- ============================================
local EGG_MODEL_NAMES = {
    ["Ovo da Luz"]  = "Ovo da Luz",
    ["Ovo Sombrio"] = "Ovo Sombrio",
    ["EggCosmic"]   = "Ovo Cosmico",
    ["EggLunar"]    = "Ovo Lunar"
}

-- ============================================
-- EGG FOLDER MAPPING
-- Maps egg names to their combined egg+pet folders in ReplicatedStorage
-- ============================================
local EGG_FOLDERS = {
    ["EggCosmic"] = "Ovo Cosmico e seus Pets",
    ["EggLunar"]  = "Ovo Lunar e seus Pets"
}

-- ============================================
-- FIND EGG MODEL IN WORKSPACE
-- Searches by exact name, then by partial match
-- MUST be defined BEFORE shakeEggModel which uses it
-- ============================================
local function findEggModel(eggName)
    local modelName = EGG_MODEL_NAMES[eggName]
    if not modelName then return nil end

    -- First pass: check EGG_FOLDERS for combined egg+pet folders
    local eggFolderName = EGG_FOLDERS[eggName]
    if eggFolderName then
        local eggFolder = game.ReplicatedStorage:FindFirstChild(eggFolderName)
        if eggFolder then
            for _, descendant in ipairs(eggFolder:GetDescendants()) do
                if descendant:IsA("Model") and descendant.Name == modelName then
                    return descendant
                end
            end
        end
    end

    -- Second pass: check ReplicatedStorage.EggModels
    local eggModelsFolder = game.ReplicatedStorage:FindFirstChild("EggModels")
    if eggModelsFolder then
        for _, descendant in ipairs(eggModelsFolder:GetDescendants()) do
            if descendant:IsA("Model") and descendant.Name == modelName then
                return descendant
            end
        end
    end

    -- Third pass: exact name match on Models in Workspace
    for _, descendant in ipairs(game.Workspace:GetDescendants()) do
        if descendant:IsA("Model") and descendant.Name == modelName then
            return descendant
        end
    end

    -- Fourth pass: exact name match on BaseParts (in case it's not wrapped in a Model)
    for _, descendant in ipairs(game.Workspace:GetDescendants()) do
        if descendant:IsA("BasePart") and descendant.Name == modelName then
            -- Wrap in a model for cloning
            local wrapper = Instance.new("Model")
            wrapper.Name = modelName
            descendant:Clone().Parent = wrapper
            return wrapper
        end
    end

    -- Fifth pass: case-insensitive partial match on Models
    local lowerName = string.lower(modelName)
    for _, descendant in ipairs(game.Workspace:GetDescendants()) do
        if descendant:IsA("Model") and string.find(string.lower(descendant.Name), lowerName, 1, true) then
            return descendant
        end
    end

    return nil
end

-- ============================================
-- SHAKE 3D EGG MODEL IN WORKSPACE
-- ============================================
function EggsPanel.shakeEggModel(eggName)
    local modelName = EGG_MODEL_NAMES[eggName]
    if not modelName then return end

    local eggModel = findEggModel(eggName)
    if not eggModel then return end

    -- Ensure PrimaryPart is set
    if not eggModel.PrimaryPart then
        local firstPart = eggModel:FindFirstChildWhichIsA("BasePart")
        if not firstPart then return end
        eggModel.PrimaryPart = firstPart
    end

    local originalCFrame = eggModel:GetPivot()

    task.spawn(function()
        -- TweenService cannot tween a Model's CFrame directly
        -- Use PivotTo with timed steps instead
        for i = 1, 6 do
            local intensity = math.min(i, 3)
            local shakeAngle = (i % 2 == 1) and (8 * intensity) or -(8 * intensity)
            local shakeCFrame = originalCFrame * CFrame.Angles(0, math.rad(shakeAngle), 0)
            eggModel:PivotTo(shakeCFrame)
            task.wait(0.08)
        end

        -- Smooth reset to original position
        local steps = 8
        for i = 1, steps do
            local progress = i / steps
            local eased = 1 - math.pow(1 - progress, 3) -- ease out cubic
            local currentCFrame = eggModel:GetPivot()
            local resetCFrame = currentCFrame:Lerp(originalCFrame, eased)
            eggModel:PivotTo(resetCFrame)
            task.wait(0.02)
        end
        eggModel:PivotTo(originalCFrame)
    end)
end

-- ============================================
-- PRELOAD MESH ASSETS FOR VIEWPORTFRAME
-- Ensures MeshParts render correctly when cloned
-- ============================================
local function preloadModelAssets(model)
    local assets = {}
    for _, desc in ipairs(model:GetDescendants()) do
        if desc:IsA("MeshPart") then
            if desc.MeshId ~= "" then
                table.insert(assets, desc.MeshId)
            end
            if desc.TextureID ~= "" then
                table.insert(assets, desc.TextureID)
            end
        elseif desc:IsA("Decal") or desc:IsA("Texture") then
            if desc.Texture ~= "" then
                table.insert(assets, desc.Texture)
            end
        end
    end
    if #assets > 0 then
        pcall(function()
            ContentProvider:PreloadAsync(assets)
        end)
    end
end

-- ============================================
-- SETUP VIEWPORT CAMERA
-- Properly creates and configures camera for ViewportFrame
-- ============================================
local function setupViewportCamera(viewport)
    local camera = Instance.new("Camera")
    camera.FieldOfView = 40
    -- IMPORTANT: Parent camera to viewport FIRST, then set as CurrentCamera
    camera.Parent = viewport
    viewport.CurrentCamera = camera

    -- Point light for better visibility
    local pointLight = Instance.new("PointLight")
    pointLight.Brightness = 2
    pointLight.Range = 20
    pointLight.Color = Color3.fromRGB(255, 255, 255)
    pointLight.Parent = camera

    return camera
end

-- ============================================
-- POSITION MODEL IN VIEWPORT
-- Centers model at origin and positions camera to frame it
-- ============================================
local function positionModelInView(model, camera)
    -- Unanchor all parts so PivotTo works reliably in ViewportFrame
    for _, desc in ipairs(model:GetDescendants()) do
        if desc:IsA("BasePart") then
            desc.Anchored = true
            desc.CanCollide = false
        end
    end

    -- Calculate base orientation from PrimaryPart's PivotOffset
    -- Meshes imported with non-standard up directions have a PivotOffset rotation.
    -- PivotTo(CFrame.new(0,0,0)) would compensate for this, flipping the mesh.
    -- By including the PivotOffset rotation in the target, the mesh stays upright.
    local baseOrientation = CFrame.new()
    if model.PrimaryPart then
        baseOrientation = model.PrimaryPart.PivotOffset.Rotation
    end

    -- Move model to origin (with baseOrientation to keep mesh upright)
    model:PivotTo(CFrame.new(0, 0, 0) * baseOrientation)

    -- Get bounding box AFTER repositioning
    local _, size = model:GetBoundingBox()
    local maxDim = math.max(size.X, size.Y, size.Z)
    if maxDim < 0.1 then maxDim = 5 end -- safety fallback
    local distance = maxDim * 2.5

    -- Position camera looking at center
    camera.CFrame = CFrame.new(Vector3.new(0, size.Y * 0.15, distance), Vector3.new(0, 0, 0))

    return size, distance, baseOrientation
end

-- ============================================
-- CREATE EGG OPENING POPUP (4-PHASE SYSTEM)
-- Usa os 4 módulos separados: EggOverlay, EggExplosion, EggPetReveal, EggClose
-- ============================================
local function createEggOpeningPopup(screenGui, egg, hatchedPets)
    -- ===== CANCEL ANY RUNNING ANIMATION =====
    if currentAnimToken then
        currentAnimToken.cancelled = true
    end
    if currentAnimConn then
        currentAnimConn:Disconnect()
        currentAnimConn = nil
    end

    -- Clean up any existing popup
    if eggOpeningPopup then
        eggOpeningPopup:Destroy()
        eggOpeningPopup = nil
    end

    -- Close any existing overlay (in case it was left open)
    EggOverlay.close()

    -- Create new cancellation token for this popup
    local animToken = { cancelled = false }
    currentAnimToken = animToken

    -- Garantir que hatchedPets é uma lista
    if hatchedPets and type(hatchedPets) ~= "table" then
        hatchedPets = {hatchedPets}
    end
    local petCount = hatchedPets and #hatchedPets or 1
    local isMultiHatch = petCount > 1

    -- ===== PARTE 1: OVERLAY FOSCO =====
    EggOverlay.open(screenGui)

    -- ===== TAMANHO DO POPUP BASEADO NO NÚMERO DE PETS =====
    local popupWidth = isMultiHatch and (200 + petCount * 180) or 360
    local popupHeight = 480
    local popupX = -popupWidth / 2
    local popupY = -popupHeight / 2

    -- ===== MAIN POPUP FRAME =====
    local popup = Instance.new("Frame")
    popup.Name = "EggOpeningPopup"
    popup.Size = UDim2.new(0, popupWidth, 0, popupHeight)
    popup.Position = UDim2.new(0.5, popupX, 0.5, popupY)
    popup.BackgroundColor3 = Config.COLORS.MAIN_BG
    popup.BorderSizePixel = 0
    popup.ZIndex = 300
    popup.BackgroundTransparency = 1
    popup.Parent = screenGui
    PanelManager.createCorner(popup)
    PanelManager.createStroke(popup)

    -- Shadow
    local popupShadow = Instance.new("Frame")
    popupShadow.Size = popup.Size
    popupShadow.Position = popup.Position + UDim2.new(0, 4, 0, 4)
    popupShadow.BackgroundColor3 = Config.COLORS.SHADOW
    popupShadow.BackgroundTransparency = 1
    popupShadow.BorderSizePixel = 0
    popupShadow.ZIndex = 299
    popupShadow.Parent = screenGui
    PanelManager.createCorner(popupShadow)

    -- Store shadow reference
    local shadowRef = Instance.new("ObjectValue")
    shadowRef.Name = "ShadowRef"
    shadowRef.Value = popupShadow
    shadowRef.Parent = popup

    -- Animate popup appearing
    TweenService:Create(popup, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        BackgroundTransparency = 0
    }):Play()
    TweenService:Create(popupShadow, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        BackgroundTransparency = 0.5
    }):Play()

    -- ===== VIEWPORT FOR 3D MODELS =====
    local viewport = Instance.new("ViewportFrame")
    viewport.Name = "EggViewport"
    viewport.Size = UDim2.new(1, 0, 0, 260)
    viewport.Position = UDim2.new(0, 0, 0, 10)
    viewport.BackgroundTransparency = 1
    viewport.Ambient = Color3.fromRGB(200, 200, 220)
    viewport.LightDirection = Vector3.new(-1, -1, -1)
    viewport.ZIndex = 5
    viewport.Parent = popup

    -- Setup camera properly
    local camera = setupViewportCamera(viewport)

    -- ===== OPENING TEXT =====
    local openingText = Instance.new("TextLabel")
    openingText.Size = UDim2.new(1, 0, 0, 30)
    openingText.Position = UDim2.new(0, 0, 0, 270)
    openingText.BackgroundTransparency = 1
    openingText.Text = "Abrindo " .. egg.name .. "..."
    openingText.TextColor3 = Config.COLORS.TITLE_TEXT
    openingText.TextSize = isMultiHatch and 16 or 18
    openingText.Font = Enum.Font.GothamBold
    openingText.ZIndex = 10
    openingText.Parent = popup

    -- ===== PARTE 4: SETUP DO CLOSE SYSTEM =====
    local animConnection = nil
    local fxRefs = nil
    local allPetRefs = {} -- Lista de refs para múltiplos pets

    local closeRefs = EggClose.setup(popup, popupShadow, Config, PanelManager, {
        animDisconnect = function()
            if animConnection then animConnection:Disconnect(); animConnection = nil end
        end,
        cancelAnimToken = function()
            animToken.cancelled = true
        end,
        explosionCleanup = function()
            EggExplosion.cleanup(fxRefs)
        end,
        petCleanup = function()
            for _, refs in ipairs(allPetRefs) do
                EggPetReveal.cleanup(refs)
            end
        end,
        overlayClose = function()
            EggOverlay.close()
        end,
        popupClosed = function()
            -- Reset module-level state so future popups work cleanly
            if eggOpeningPopup == popup then
                eggOpeningPopup = nil
            end
            if currentAnimToken == animToken then
                currentAnimToken = nil
            end
            if currentAnimConn then
                currentAnimConn:Disconnect()
                currentAnimConn = nil
            end
        end,
    })

    -- ===== MAIN ANIMATION SEQUENCE =====
    task.spawn(function()
        local ok, err = pcall(function()
        local RunService = game:GetService("RunService")

        -- Resolve pet data for ALL hatched pets
        local petsData = {}
        for i = 1, petCount do
            local pet = hatchedPets[i]
            local randomIndex = math.random(1, #egg.pets)
            local petEmoji = pet and pet.emoji or egg.pets[randomIndex]
            local petName = pet and pet.name or (egg.petNames and egg.petNames[randomIndex] or "Pet")
            local petRarity = pet and pet.rarity or (egg.petRarities and egg.petRarities[randomIndex] or "Common")
            local petMult = pet and pet.multiplier or 1.5

            -- Find pet model template from egg's combined folder
            local petModelTemplate = nil
            local eggFolderName = EGG_FOLDERS[egg.name]
            if eggFolderName then
                local eggFolder = ReplicatedStorage:FindFirstChild(eggFolderName)
                if eggFolder then
                    local displayName = petName
                    if displayName:sub(1, 3) == "Pet" and #displayName > 3 then
                        displayName = displayName:sub(4)
                    end

                    -- Find the model key from egg.pets by matching petName against egg.petNames
                    -- egg.pets has model names (no spaces), egg.petNames has display names (with spaces)
                    local modelKey = nil
                    if egg.petNames and egg.pets then
                        for j, pn in ipairs(egg.petNames) do
                            if pn == petName or pn == displayName then
                                modelKey = egg.pets[j]
                                break
                            end
                        end
                    end

                    -- Try model key first (matches folder model names), then display name, then without spaces
                    petModelTemplate = (modelKey and eggFolder:FindFirstChild(modelKey))
                        or eggFolder:FindFirstChild(displayName)
                        or eggFolder:FindFirstChild(petName)
                        or eggFolder:FindFirstChild(displayName:gsub(" ", ""))
                        or eggFolder:FindFirstChild(petName:gsub(" ", ""))
                end
            end

            table.insert(petsData, {
                name = petName,
                emoji = petEmoji,
                rarity = petRarity,
                multiplier = petMult,
                modelTemplate = petModelTemplate,
            })
        end

        -- Use first pet's rarity for egg animation effects
        local petRarity = petsData[1] and petsData[1].rarity or "Common"

        -- Find and clone the 3D egg model(s)
        local eggClones = {}
        local originalEggModel = nil
        local eggBaseOrientation = CFrame.new()
        local modelSize = Vector3.new(5, 5, 5)
        local eggSpacing = 0
        local eggStartX = 0

        -- Find egg model using the same findEggModel function for all eggs
        originalEggModel = findEggModel(egg.name)

        if originalEggModel then
            -- Preload mesh assets so they render in the ViewportFrame
            preloadModelAssets(originalEggModel)

            local numEggs = isMultiHatch and petCount or 1

            for eggIdx = 1, numEggs do
                local clone = originalEggModel:Clone()

                -- Ensure the clone has a PrimaryPart
                if not clone.PrimaryPart then
                    local firstPart = clone:FindFirstChildWhichIsA("BasePart")
                    if firstPart then
                        clone.PrimaryPart = firstPart
                    end
                end

                -- Parent to viewport first
                clone.Parent = viewport
                table.insert(eggClones, clone)
            end

            -- Position models and camera
            if #eggClones == 1 then
                modelSize, _, eggBaseOrientation = positionModelInView(eggClones[1], camera)
            else
                -- Position multiple eggs side by side
                local firstClone = eggClones[1]
                if firstClone.PrimaryPart then
                    eggBaseOrientation = firstClone.PrimaryPart.PivotOffset.Rotation
                end

                -- Unanchor and center all clones
                for _, clone in ipairs(eggClones) do
                    for _, desc in ipairs(clone:GetDescendants()) do
                        if desc:IsA("BasePart") then
                            desc.Anchored = true
                            desc.CanCollide = false
                        end
                    end
                    clone:PivotTo(CFrame.new(0, 0, 0) * eggBaseOrientation)
                end

                local _, firstSize = firstClone:GetBoundingBox()
                modelSize = firstSize
                local maxDim = math.max(firstSize.X, firstSize.Y, firstSize.Z)
                if maxDim < 0.1 then maxDim = 5 end

                eggSpacing = maxDim * 1.4
                local totalWidth = eggSpacing * (#eggClones - 1)
                eggStartX = -totalWidth / 2

                for i, clone in ipairs(eggClones) do
                    local offsetX = eggStartX + (i - 1) * eggSpacing
                    clone:PivotTo(CFrame.new(offsetX, 0, 0) * eggBaseOrientation)
                end

                -- Position camera to see all eggs
                local camDistance = maxDim * 2.5 + totalWidth * 0.6
                camera.CFrame = CFrame.new(Vector3.new(0, firstSize.Y * 0.15, camDistance), Vector3.new(0, 0, 0))
            end

            -- SetPrimaryPartCFrame removed: positionModelInView already centers
            -- the model correctly with baseOrientation accounting for PivotOffset

            -- ===== LUZ PULSANTE NO OVO =====
            local eggLight = Instance.new("PointLight")
            eggLight.Name = "EggPulseLight"
            eggLight.Brightness = 1
            eggLight.Range = 10
            eggLight.Color = Config.RARITY_COLORS[petRarity] or Color3.fromRGB(255, 255, 255)
            eggLight.Parent = camera

            -- Usar a raridade do primeiro pet para os efeitos do ovo
            petRarity = petsData[1] and petsData[1].rarity or "Common"

            -- ===== PARTÍCULAS VAZANDO DO OVO =====
            local leakPart = Instance.new("Part")
            leakPart.Name = "LeakOrigin"
            leakPart.Size = Vector3.new(0.1, 0.1, 0.1)
            leakPart.Position = Vector3.new(0, modelSize.Y * 0.3, 0)
            leakPart.Transparency = 1
            leakPart.CanCollide = false
            leakPart.Anchored = true
            leakPart.Parent = viewport

            local leakEmitter = Instance.new("ParticleEmitter")
            leakEmitter.Rate = 0
            leakEmitter.Lifetime = NumberRange.new(0.5, 1.0)
            leakEmitter.Speed = NumberRange.new(0.5, 2)
            leakEmitter.SpreadAngle = Vector2.new(60, 60)
            leakEmitter.Size = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 0.4),
                NumberSequenceKeypoint.new(1, 0)
            })
            leakEmitter.Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 0),
                NumberSequenceKeypoint.new(1, 1)
            })
            leakEmitter.Color = ColorSequence.new(Config.RARITY_COLORS[petRarity] or Color3.fromRGB(255, 255, 255))
            leakEmitter.LightEmission = 1
            leakEmitter.LightInfluence = 0
            leakEmitter.EmissionDirection = Enum.NormalId.Top
            leakEmitter.Parent = leakPart

            -- ===== SOM DE RUMBLE DURANTE SHAKE =====
            local rumbleSound = Instance.new("Sound")
            rumbleSound.Name = "EggRumble"
            rumbleSound.SoundId = "rbxassetid://138080600"
            rumbleSound.Volume = SettingsPanel.soundEnabled() and 0.3 or 0
            rumbleSound.Looped = true
            rumbleSound.Parent = popup
            if SettingsPanel.soundEnabled() then
                rumbleSound:Play()
            end

            -- ===== EGG SHAKE + SPIN ANIMATION (INTENSIFICADO) =====
            local startTime = tick()
            local animDuration = 3.0

            animConnection = RunService.RenderStepped:Connect(function()
                if animToken.cancelled then return end

                local elapsed = tick() - startTime
                if elapsed > animDuration then return end

                local progress = elapsed / animDuration

                -- Rotação que acelera progressivamente
                local rotSpeed = 3 + progress * 14
                local angle = elapsed * rotSpeed

                -- Shake que intensifica com progressão quadrática
                local shakeIntensity = progress * progress * 1.5
                local shakeX = math.sin(elapsed * 18) * shakeIntensity
                local shakeY = math.abs(math.sin(elapsed * 15)) * shakeIntensity * 0.4
                local shakeZ = math.cos(elapsed * 22) * shakeIntensity * 0.6

                -- Animate all egg clones
                for idx, clone in ipairs(eggClones) do
                    if clone and clone.Parent then
                        local phaseOffset = (idx - 1) * 1.5
                        local eggShakeX = math.sin((elapsed + phaseOffset) * 18) * shakeIntensity
                        local eggShakeY = math.abs(math.sin((elapsed + phaseOffset) * 15)) * shakeIntensity * 0.4
                        local eggShakeZ = math.cos((elapsed + phaseOffset) * 22) * shakeIntensity * 0.6
                        local eggAngle = (elapsed + phaseOffset * 0.3) * rotSpeed

                        local offsetX = 0
                        if #eggClones > 1 then
                            offsetX = eggStartX + (idx - 1) * eggSpacing
                        end

                        clone:PivotTo(CFrame.new(offsetX + eggShakeX, eggShakeY, eggShakeZ) * CFrame.Angles(0, eggAngle, 0) * eggBaseOrientation)
                    end
                end

                -- Vazamento de partículas aumenta com progresso
                if progress > 0.3 and math.random() < progress * 0.4 then
                    leakEmitter:Emit(1)
                end

                -- Volume e velocidade do rumble aumentam
                if rumbleSound and rumbleSound.Parent then
                    rumbleSound.Volume = SettingsPanel.soundEnabled() and (0.3 + progress * 0.5) or 0
                    rumbleSound.PlaybackSpeed = 0.8 + progress * 0.6
                end

                -- Luz pulsa mais forte perto do fim
                if eggLight and eggLight.Parent then
                    local pulseBrightness = 1 + progress * 8 + math.sin(elapsed * 10) * progress * 3
                    eggLight.Brightness = pulseBrightness
                    eggLight.Range = 10 + progress * 25
                end
            end)
            currentAnimConn = animConnection

            task.wait(animDuration)
            if animConnection then
                animConnection:Disconnect()
                animConnection = nil
                if currentAnimConn == animConnection then
                    currentAnimConn = nil
                end
            end

            -- Exit if popup was replaced
            if animToken.cancelled then return end

            -- ===== FLASH BRANCO RÁPIDO ANTES DA EXPLOSÃO =====
            local preFlash = Instance.new("Frame")
            preFlash.Name = "PreExplosionFlash"
            preFlash.Size = UDim2.new(1, 0, 1, 0)
            preFlash.BackgroundColor3 = Color3.new(1, 1, 1)
            preFlash.BackgroundTransparency = 1
            preFlash.ZIndex = 8
            preFlash.BorderSizePixel = 0
            preFlash.Parent = popup
            TweenService:Create(preFlash, TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                BackgroundTransparency = 0.2
            }):Play()
            task.wait(0.08)

            -- Exit if popup was replaced
            if animToken.cancelled then return end

            -- Para o rumble e limpa efeitos do ovo
            if rumbleSound and rumbleSound.Parent then
                rumbleSound:Stop()
                rumbleSound.Parent = nil
            end
            if eggLight and eggLight.Parent then eggLight.Parent = nil end
            if leakPart and leakPart.Parent then leakPart.Parent = nil end
            if preFlash and preFlash.Parent then preFlash.Parent = nil end

            -- Exit if popup was replaced
            if animToken.cancelled then return end

            -- ===== PARTE 2: EXPLOSÃO =====
            -- Remove todos os ovos antes da explosão
            for _, clone in ipairs(eggClones) do
                if clone and clone.Parent then
                    clone:Destroy()
                end
            end
            eggClones = {}

            fxRefs = EggExplosion.play(viewport, camera, popup, petRarity)

            task.wait(0.5)

            -- Exit if popup was replaced
            if animToken.cancelled then return end
        else
            -- Fallback: show emoji egg while waiting
            local fallbackEgg = Instance.new("TextLabel")
            fallbackEgg.Name = "FallbackEgg"
            fallbackEgg.Size = UDim2.new(1, 0, 0, 260)
            fallbackEgg.Position = UDim2.new(0, 0, 0, 10)
            fallbackEgg.BackgroundTransparency = 1
            fallbackEgg.Text = egg.emoji or "🥚"
            fallbackEgg.TextSize = 0
            fallbackEgg.Font = Enum.Font.GothamBold
            fallbackEgg.ZIndex = 5
            fallbackEgg.Parent = popup

            -- Bounce in
            TweenService:Create(fallbackEgg, TweenInfo.new(0.5, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out), {
                TextSize = 100
            }):Play()

            -- Shake the emoji
            local shakeStart = tick()
            local shakeDur = 1.5
            local shakeConn = RunService.RenderStepped:Connect(function()
                if animToken.cancelled then
                    shakeConn:Disconnect()
                    return
                end
                local el = tick() - shakeStart
                if el > shakeDur then return end
                local prog = el / shakeDur
                local sx = math.sin(el * 20) * prog * 8
                if fallbackEgg and fallbackEgg.Parent then
                    fallbackEgg.Position = UDim2.new(0, sx, 0, 10)
                end
            end)

            task.wait(shakeDur)
            if shakeConn then shakeConn:Disconnect() end
            if fallbackEgg and fallbackEgg.Parent then
                fallbackEgg:Destroy()
            end

            -- Exit if popup was replaced
            if animToken.cancelled then return end

            fxRefs = EggExplosion.play(viewport, camera, popup, petRarity)
            task.wait(0.5)

            -- Exit if popup was replaced
            if animToken.cancelled then return end
        end

        -- ===== PARTE 3: PET REVEAL (MÚLTIPLOS PETS) =====
        -- Exit if popup was replaced
        if animToken.cancelled then return end

        if openingText and openingText.Parent then
            openingText.Text = isMultiHatch and ("Você conseguiu " .. petCount .. " novos pets!") or "Você conseguiu um novo pet!"
        end

        if isMultiHatch then
            -- Múltiplos pets: criar viewports e info cards separados
            local spacing = 12
            local cardWidth = (popupWidth - spacing * (petCount + 1)) / petCount
            local viewportHeight = 180

            -- Remover viewport original (vamos criar um por pet)
            if viewport and viewport.Parent then
                viewport.Parent = nil
            end

            for i, petData in ipairs(petsData) do
                local xOffset = spacing + (i - 1) * (cardWidth + spacing)

                -- Viewport individual para cada pet
                local petViewport = Instance.new("ViewportFrame")
                petViewport.Name = "PetViewport" .. i
                petViewport.Size = UDim2.new(0, cardWidth, 0, viewportHeight)
                petViewport.Position = UDim2.new(0, xOffset, 0, 10)
                petViewport.BackgroundTransparency = 1
                petViewport.Ambient = Color3.fromRGB(200, 200, 220)
                petViewport.LightDirection = Vector3.new(-1, -1, -1)
                petViewport.ZIndex = 5
                petViewport.Parent = popup

                local petCamera = setupViewportCamera(petViewport)

                -- Info card individual
                local infoCard = Instance.new("Frame")
                infoCard.Name = "PetInfoCard" .. i
                infoCard.Size = UDim2.new(0, cardWidth, 0, 140)
                infoCard.Position = UDim2.new(0, xOffset, 0, 200)
                infoCard.BackgroundColor3 = Config.COLORS.SECONDARY_BG
                infoCard.BorderSizePixel = 0
                infoCard.BackgroundTransparency = 1
                infoCard.ZIndex = 10
                infoCard.ClipsDescendants = true
                infoCard.Parent = popup
                PanelManager.createCorner(infoCard, 0.08)

                local rarityColor = Config.RARITY_COLORS[petData.rarity] or Color3.fromRGB(255, 255, 255)
                PanelManager.createStroke(infoCard, rarityColor, 1.5)

                -- Slide-in do info card
                TweenService:Create(infoCard, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                    Position = UDim2.new(0, xOffset, 0, 200),
                    BackgroundTransparency = 0
                }):Play()

                -- Nome do pet
                local petNameLabel = Instance.new("TextLabel")
                petNameLabel.Size = UDim2.new(1, -8, 0, 24)
                petNameLabel.Position = UDim2.new(0, 4, 0, 6)
                petNameLabel.BackgroundTransparency = 1
                petNameLabel.Text = petData.emoji .. " " .. petData.name
                petNameLabel.TextColor3 = rarityColor
                petNameLabel.TextSize = 13
                petNameLabel.Font = Enum.Font.GothamBold
                petNameLabel.ZIndex = 11
                petNameLabel.TextTruncate = Enum.TextTruncate.AtEnd
                petNameLabel.Parent = infoCard

                -- Badge de raridade
                local rarityBadge = Instance.new("Frame")
                rarityBadge.Size = UDim2.new(0, 60, 0, 18)
                rarityBadge.Position = UDim2.new(0, 4, 0, 32)
                rarityBadge.BackgroundColor3 = rarityColor
                rarityBadge.BorderSizePixel = 0
                rarityBadge.ZIndex = 11
                rarityBadge.Parent = infoCard
                PanelManager.createCorner(rarityBadge, 0.5)

                local rarityBadgeText = Instance.new("TextLabel")
                rarityBadgeText.Size = UDim2.new(1, 0, 1, 0)
                rarityBadgeText.BackgroundTransparency = 1
                rarityBadgeText.Text = petData.rarity
                rarityBadgeText.TextColor3 = Color3.fromRGB(20, 20, 20)
                rarityBadgeText.TextSize = 9
                rarityBadgeText.Font = Enum.Font.GothamBold
                rarityBadgeText.ZIndex = 12
                rarityBadgeText.Parent = rarityBadge

                -- Multiplicador
                local multLabel = Instance.new("TextLabel")
                multLabel.Size = UDim2.new(1, -8, 0, 18)
                multLabel.Position = UDim2.new(0, 4, 0, 54)
                multLabel.BackgroundTransparency = 1
                multLabel.Text = "x" .. tostring(petData.multiplier) .. " ✨"
                multLabel.TextColor3 = Config.COLORS.DESC_TEXT
                multLabel.TextSize = 11
                multLabel.Font = Enum.Font.GothamSemibold
                multLabel.ZIndex = 11
                multLabel.Parent = infoCard

                -- Badge NOVO!
                local novoBadge = Instance.new("Frame")
                novoBadge.Name = "NovoBadge" .. i
                novoBadge.Size = UDim2.new(0, 0, 0, 0)
                novoBadge.Position = UDim2.new(0, xOffset + 4, 0, 12)
                novoBadge.BackgroundColor3 = rarityColor
                novoBadge.BorderSizePixel = 0
                novoBadge.ZIndex = 15
                novoBadge.Parent = popup
                PanelManager.createCorner(novoBadge, 0.3)

                local novoText = Instance.new("TextLabel")
                novoText.Size = UDim2.new(1, 0, 1, 0)
                novoText.BackgroundTransparency = 1
                novoText.Text = "NOVO!"
                novoText.TextColor3 = Color3.fromRGB(20, 20, 20)
                novoText.TextSize = 8
                novoText.Font = Enum.Font.GothamBold
                novoText.ZIndex = 16
                novoText.Parent = novoBadge

                -- Bounce-in do badge
                TweenService:Create(novoBadge, TweenInfo.new(0.4, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out), {
                    Size = UDim2.new(0, 38, 0, 16),
                }):Play()

                -- Revelar o pet no viewport
                local refs = EggPetReveal.show(petViewport, petCamera, popup, petData, Config, PanelManager, petData.modelTemplate, true)
                table.insert(allPetRefs, refs)

                -- Pequeno delay entre cada pet para efeito cascata
                if i < petCount then
                    task.wait(0.15)
                    if animToken.cancelled then return end
                end
            end
        else
            -- Pet único: comportamento original
            local petData = petsData[1]
            local refs = EggPetReveal.show(viewport, camera, popup, petData, Config, PanelManager, petData.modelTemplate)
            table.insert(allPetRefs, refs)
        end

        -- ===== PARTE 4: MOSTRAR BOTÕES DE FECHAR =====
        -- Final check before showing buttons
        if animToken.cancelled then return end

        EggClose.showButtons(closeRefs)
        end)

        -- ALWAYS close overlay regardless of success or error
        EggOverlay.close()

        if not ok then
            warn("[EggPanel] Animation error: " .. tostring(err))
        end
    end)

    eggOpeningPopup = popup
end

-- ============================================
-- CREATE PANEL
-- ============================================
function EggsPanel.create(screenGui)
    panel = screenGui:FindFirstChild("EggsPanel")
    if not panel then return end
    
    local eggsClose = panel:FindFirstChild("CloseButton")
    
    -- Scroll frame
    local scroll = Instance.new("ScrollingFrame")
    scroll.Name = "EggsScroll"
    scroll.Size = UDim2.new(1, -32, 1, -60)
    scroll.Position = UDim2.new(0, 16, 0, 52)
    scroll.BackgroundTransparency = 1
    scroll.ScrollBarThickness = 3
    scroll.ScrollBarImageColor3 = Color3.fromRGB(80, 80, 80)
    scroll.ScrollingDirection = Enum.ScrollingDirection.Y
    scroll.ClipsDescendants = true
    scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    scroll.Parent = panel
    
    local padding = Instance.new("UIPadding")
    padding.PaddingTop = UDim.new(0, 10)
    padding.PaddingBottom = UDim.new(0, 10)
    padding.PaddingLeft = UDim.new(0, 10)
    padding.PaddingRight = UDim.new(0, 10)
    padding.Parent = scroll
    
    local layout = Instance.new("UIGridLayout")
    layout.CellSize = UDim2.new(0.48, 0, 0, 340)
    layout.CellPadding = UDim2.new(0.02, 0, 0, 10)
    layout.FillDirection = Enum.FillDirection.Horizontal
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = scroll
    
    -- Egg cards
    for _, egg in ipairs(Config.EGGS) do
        local card = Instance.new("Frame")
        card.Name = egg.name
        card.Size = UDim2.new(0, 160, 0, 220)
        card.BackgroundColor3 = Config.COLORS.SECONDARY_BG
        card.BorderSizePixel = 0
        card.Parent = scroll
        PanelManager.createCorner(card, 0.1)
        PanelManager.createStroke(card)
        
        local eggEmoji = Instance.new("TextLabel")
        eggEmoji.Size = UDim2.new(1, 0, 0, 60)
        eggEmoji.Position = UDim2.new(0, 0, 0, 8)
        eggEmoji.BackgroundTransparency = 1
        eggEmoji.Text = egg.emoji
        eggEmoji.TextSize = 48
        eggEmoji.Font = Enum.Font.GothamBold
        eggEmoji.Parent = card
        
        local eggName = Instance.new("TextLabel")
        eggName.Size = UDim2.new(1, -8, 0, 20)
        eggName.Position = UDim2.new(0, 4, 0, 75)
        eggName.BackgroundTransparency = 1
        eggName.Text = egg.name
        eggName.TextColor3 = Config.COLORS.TITLE_TEXT
        eggName.TextSize = 16
        eggName.Font = Enum.Font.GothamBold
        eggName.TextWrapped = true
        eggName.Parent = card
        
        -- Rarity pill
        local rarityPill = Instance.new("Frame")
        rarityPill.Size = UDim2.new(0, 60, 0, 18)
        rarityPill.Position = UDim2.new(0.5, -30, 0, 98)
        rarityPill.BackgroundColor3 = Config.COLORS.MAIN_BG
        rarityPill.BorderSizePixel = 0
        rarityPill.Parent = card
        PanelManager.createCorner(rarityPill, 0.5)
        
        local rarityText = Instance.new("TextLabel")
        rarityText.Size = UDim2.new(1, 0, 1, 0)
        rarityText.BackgroundTransparency = 1
        rarityText.Text = egg.rarity
        rarityText.TextColor3 = Config.RARITY_COLORS[egg.rarity]
        rarityText.TextSize = 13
        rarityText.Font = Enum.Font.GothamBold
        rarityText.Parent = rarityPill
        
        -- Pets list (simplified)
        local petsLabel = Instance.new("TextLabel")
        petsLabel.Size = UDim2.new(1, -8, 0, 14)
        petsLabel.Position = UDim2.new(0, 4, 0, 125)
        petsLabel.BackgroundTransparency = 1
        petsLabel.Text = "Pets:"
        petsLabel.TextColor3 = Config.COLORS.DESC_TEXT
        petsLabel.TextSize = 14
        petsLabel.Font = Enum.Font.GothamSemibold
        petsLabel.TextXAlignment = Enum.TextXAlignment.Left
        petsLabel.TextWrapped = true
        petsLabel.Parent = card
        
        for i, petEmoji in ipairs(egg.pets) do
            if i <= 4 then
                local petRow = Instance.new("TextLabel")
                petRow.Size = UDim2.new(1, -8, 0, 14)
                petRow.Position = UDim2.new(0, 4, 0, 143 + (i-1)*18)
                petRow.BackgroundTransparency = 1
                petRow.Text = (egg.petNames and egg.petNames[i] or "Pet")
                petRow.TextColor3 = Config.RARITY_COLORS[egg.petRarities and egg.petRarities[i] or "Common"] or Config.COLORS.DESC_TEXT
                petRow.TextSize = 11
                petRow.Font = Enum.Font.GothamSemibold
                petRow.TextXAlignment = Enum.TextXAlignment.Left
                petRow.TextWrapped = true
                petRow.ClipsDescendants = false
                petRow.Parent = card
            end
        end
        
        -- Premium egg indicator
        if egg.starcoinsOnly then
            local premiumBadge = Instance.new("TextLabel")
            premiumBadge.Size = UDim2.new(0, 70, 0, 16)
            premiumBadge.Position = UDim2.new(0.5, -35, 0, 0)
            premiumBadge.BackgroundTransparency = 1
            premiumBadge.Text = "⭐ PREMIUM"
            premiumBadge.TextColor3 = Color3.fromRGB(255, 200, 50)
            premiumBadge.TextSize = 9
            premiumBadge.Font = Enum.Font.GothamBold
            premiumBadge.Parent = card
        end
        
        -- Purchase buttons
        if egg.starcoinsOnly then
            -- Premium eggs: Starcoins only (1x and 3x)
            local open1Btn = Instance.new("TextButton")
            open1Btn.Size = UDim2.new(1, -16, 0, 26)
            open1Btn.Position = UDim2.new(0, 8, 1, -62)
            open1Btn.BackgroundColor3 = Config.COLORS.BUTTON_BG
            open1Btn.BorderSizePixel = 0
            open1Btn.Text = "🌙 " .. tostring(egg.price1Starcoins) .. " (1x)"
            open1Btn.TextColor3 = Config.COLORS.TITLE_TEXT
            open1Btn.TextSize = 11
            open1Btn.Font = Enum.Font.GothamBold
            open1Btn.Parent = card
            PanelManager.createCorner(open1Btn, 0.2)
            PanelManager.setupButtonEffects(open1Btn)
            
            open1Btn.MouseButton1Click:Connect(function()
                NetworkClient.buyEgg(egg.name, 1, true)
            end)
            
            local open3Btn = Instance.new("TextButton")
            open3Btn.Size = UDim2.new(1, -16, 0, 26)
            open3Btn.Position = UDim2.new(0, 8, 1, -32)
            open3Btn.BackgroundColor3 = Config.COLORS.MAIN_BG
            open3Btn.BorderSizePixel = 0
            open3Btn.Text = "🌙 " .. tostring(egg.price3Starcoins) .. " (3x)"
            open3Btn.TextColor3 = Config.COLORS.TITLE_TEXT
            open3Btn.TextSize = 11
            open3Btn.Font = Enum.Font.GothamBold
            open3Btn.Parent = card
            PanelManager.createCorner(open3Btn, 0.2)
            PanelManager.createStroke(open3Btn)
            PanelManager.setupButtonEffects(open3Btn)
            
            open3Btn.MouseButton1Click:Connect(function()
                NetworkClient.buyEgg(egg.name, 3, true)
            end)
        else
            -- Regular eggs: Stardust only (1x and 3x)
            local open1Btn = Instance.new("TextButton")
            open1Btn.Size = UDim2.new(1, -16, 0, 26)
            open1Btn.Position = UDim2.new(0, 8, 1, -62)
            open1Btn.BackgroundColor3 = Config.COLORS.BUTTON_BG
            open1Btn.BorderSizePixel = 0
            open1Btn.Text = "✨" .. tostring(egg.price1) .. " (1x)"
            open1Btn.TextColor3 = Config.COLORS.TITLE_TEXT
            open1Btn.TextSize = 11
            open1Btn.Font = Enum.Font.GothamBold
            open1Btn.Parent = card
            PanelManager.createCorner(open1Btn, 0.2)
            PanelManager.setupButtonEffects(open1Btn)
            
            open1Btn.MouseButton1Click:Connect(function()
                NetworkClient.buyEgg(egg.name, 1, false)
            end)
            
            local open3Btn = Instance.new("TextButton")
            open3Btn.Size = UDim2.new(1, -16, 0, 26)
            open3Btn.Position = UDim2.new(0, 8, 1, -32)
            open3Btn.BackgroundColor3 = Config.COLORS.MAIN_BG
            open3Btn.BorderSizePixel = 0
            open3Btn.Text = "✨" .. tostring(egg.price3) .. " (3x)"
            open3Btn.TextColor3 = Config.COLORS.TITLE_TEXT
            open3Btn.TextSize = 11
            open3Btn.Font = Enum.Font.GothamBold
            open3Btn.Parent = card
            PanelManager.createCorner(open3Btn, 0.2)
            PanelManager.createStroke(open3Btn)
            PanelManager.setupButtonEffects(open3Btn)
            
            open3Btn.MouseButton1Click:Connect(function()
                NetworkClient.buyEgg(egg.name, 3, false)
            end)
        end
    end
    
    -- Close button
    if eggsClose then
        eggsClose.MouseButton1Click:Connect(function()
            PanelManager.closeActivePanel()
        end)
    end
    
    PanelManager.registerPanel("EggsPanel", panel)
end

-- ============================================
-- SHOW EGG POPUP (called when server confirms)
-- ============================================
function EggsPanel.showPopup(screenGui, eggName, hatchedPets)
    -- Garantir que hatchedPets é uma lista
    if hatchedPets and type(hatchedPets) ~= "table" then
        hatchedPets = {hatchedPets}
    end
    for _, egg in ipairs(Config.EGGS) do
        if egg.name == eggName then
            createEggOpeningPopup(screenGui, egg, hatchedPets)
            break
        end
    end
end

return EggsPanel