local PetsPanel = {}

local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")

local Config = require(ReplicatedStorage:WaitForChild("StardustConfig"))
local PanelManager = require(ReplicatedStorage:WaitForChild("StardustUI"):WaitForChild("PanelManager"))
local NetworkClient = require(ReplicatedStorage:WaitForChild("StardustUI"):WaitForChild("NetworkClient"))

-- Gamepass ID for More Pets
local GAMEPASS_MORE_PETS = 1816119729

local panel = nil
local petsContent = nil
local equippedRow = nil
local filterButtons = {}
local currentPetFilter = 1
local OWNED_PETS = {}

-- Selection mode state
local selectionMode = false
local selectedPets = {} -- Set of pet IDs
local selectButton = nil
local selectionBar = nil
local screenGuiRef = nil

-- ============================================
-- PET EMOJI OVERRIDE
-- ============================================
local PET_EMOJI_OVERRIDE = {
    ["PetCrystalTree"] = "TREE",
    ["PetMiniAstroKing"] = "KING",
}

local function getDisplayEmoji(pet)
    if not pet then return "?" end
    local override = PET_EMOJI_OVERRIDE[pet.name]
    if override then
        return override
    end
    return pet.emoji or "?"
end

-- ============================================
-- STAR DISPLAY HELPER
-- ============================================
local function getStarString(stars)
    stars = stars or 1
    local s = ""
    for i = 1, 5 do
        if i <= stars then
            s = s .. "\xe2\x98\x85"
        else
            s = s .. "\xe2\x98\x86"
        end
    end
    return s
end

-- Check if player has More Pets gamepass
local function hasMorePetsGamepass()
    local player = Players.LocalPlayer
    if not player then return false end
    local success, hasGamepass = pcall(function()
        return MarketplaceService:UserOwnsGamePassAsync(player.UserId, GAMEPASS_MORE_PETS)
    end)
    return success and hasGamepass
end

-- Get max pets player can equip
local function getMaxPets()
    if hasMorePetsGamepass() then
        return 6
    end
    return 3
end

-- Check if rarity is rare or higher
local function isRareOrHigher(rarity)
    return rarity == "Raro" or rarity == "Epico" or rarity == "Lendario" or rarity == "Supernova" or rarity == "Premium" or rarity == "Especial"
end

-- ============================================
-- MERGE VALIDATION
-- ============================================
local function getMergeStatus()
    local count = 0
    local selectedList = {}
    for id, _ in pairs(selectedPets) do
        count = count + 1
        for _, pet in ipairs(OWNED_PETS) do
            if pet.id == id then
                table.insert(selectedList, pet)
                break
            end
        end
    end

    if count == 0 then
        return false, "Select pets to delete or merge", nil
    end

    if #selectedList >= 3 then
        local firstName = selectedList[1].name
        local firstStars = selectedList[1].stars or 1

        local allSame = true
        for _, pet in ipairs(selectedList) do
            if pet.name ~= firstName or (pet.stars or 1) ~= firstStars then
                allSame = false
                break
            end
        end

        if allSame and #selectedList == 3 then
            if firstStars >= 5 then
                return false, "Max star level reached (5" .. string.char(226,152,133) .. ")", nil
            end
            return true, "3x " .. firstName .. " " .. getStarString(firstStars) .. " -> " .. getStarString(firstStars + 1), selectedList
        elseif allSame and #selectedList > 3 then
            return false, "Select exactly 3 same pets to merge", nil
        elseif allSame then
            return false, "Need " .. (3 - #selectedList) .. " more " .. firstName .. " to merge", nil
        else
            return false, "Pets must be same name & star level", nil
        end
    end

    return false, count .. " pet(s) selected", nil
end

-- Create warning popup for rare+ pets
local function createWarningPopup(title, message, petName, isBulk, onConfirm)
    if not screenGuiRef then return end

    local existing = screenGuiRef:FindFirstChild("DeleteWarningPopup")
    if existing then existing:Destroy() end

    local popup = Instance.new("Frame")
    popup.Name = "DeleteWarningPopup"
    popup.Size = UDim2.new(0, 320, 0, 180)
    popup.Position = UDim2.new(0.5, -160, 0.5, -90)
    popup.BackgroundColor3 = Color3.fromRGB(16, 16, 16)
    popup.BorderSizePixel = 0
    popup.ZIndex = 600
    popup.Parent = screenGuiRef

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = popup

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(180, 30, 30)
    stroke.Thickness = 2
    stroke.Parent = popup

    local warningIcon = Instance.new("TextLabel")
    warningIcon.Size = UDim2.new(1, 0, 0, 40)
    warningIcon.Position = UDim2.new(0, 0, 0, 10)
    warningIcon.BackgroundTransparency = 1
    warningIcon.Text = "WARNING"
    warningIcon.TextColor3 = Color3.fromRGB(255, 100, 100)
    warningIcon.TextSize = 20
    warningIcon.Font = Enum.Font.GothamBold
    warningIcon.Parent = popup

    local msgLabel = Instance.new("TextLabel")
    msgLabel.Size = UDim2.new(1, -20, 0, 60)
    msgLabel.Position = UDim2.new(0, 10, 0, 55)
    msgLabel.BackgroundTransparency = 1
    msgLabel.Text = message
    msgLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    msgLabel.TextSize = 14
    msgLabel.Font = Enum.Font.GothamBold
    msgLabel.TextWrapped = true
    msgLabel.Parent = popup

    if petName and not isBulk then
        local petNameLabel = Instance.new("TextLabel")
        petNameLabel.Size = UDim2.new(1, 0, 0, 24)
        petNameLabel.Position = UDim2.new(0, 0, 0, 95)
        petNameLabel.BackgroundTransparency = 1
        petNameLabel.Text = petName
        petNameLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
        petNameLabel.TextSize = 16
        petNameLabel.Font = Enum.Font.GothamBold
        petNameLabel.Parent = popup
    end

    local undoText = Instance.new("TextLabel")
    undoText.Size = UDim2.new(1, 0, 0, 20)
    undoText.Position = UDim2.new(0, 0, 0, isBulk and 105 or 115)
    undoText.BackgroundTransparency = 1
    undoText.Text = "This action cannot be undone."
    undoText.TextColor3 = Color3.fromRGB(150, 150, 150)
    undoText.TextSize = 12
    undoText.Font = Enum.Font.GothamSemibold
    undoText.Parent = popup

    local btnContainer = Instance.new("Frame")
    btnContainer.Size = UDim2.new(1, -20, 0, 36)
    btnContainer.Position = UDim2.new(0, 10, 1, -46)
    btnContainer.BackgroundTransparency = 1
    btnContainer.Parent = popup

    local btnLayout = Instance.new("UIListLayout")
    btnLayout.FillDirection = Enum.FillDirection.Horizontal
    btnLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    btnLayout.Padding = UDim.new(0, 10)
    btnLayout.Parent = btnContainer

    local cancelBtn = Instance.new("TextButton")
    cancelBtn.Size = UDim2.new(0, 120, 0, 36)
    cancelBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    cancelBtn.BorderSizePixel = 0
    cancelBtn.Text = "CANCEL"
    cancelBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    cancelBtn.TextSize = 14
    cancelBtn.Font = Enum.Font.GothamBold
    cancelBtn.Parent = btnContainer
    PanelManager.createCorner(cancelBtn, 0.2)
    PanelManager.setupButtonEffects(cancelBtn)

    cancelBtn.MouseButton1Click:Connect(function()
        popup:Destroy()
    end)

    local deleteBtn = Instance.new("TextButton")
    deleteBtn.Size = UDim2.new(0, 120, 0, 36)
    deleteBtn.BackgroundColor3 = Color3.fromRGB(180, 30, 30)
    deleteBtn.BorderSizePixel = 0
    deleteBtn.Text = isBulk and "DELETE ALL" or "DELETE ANYWAY"
    deleteBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    deleteBtn.TextSize = 14
    deleteBtn.Font = Enum.Font.GothamBold
    deleteBtn.Parent = btnContainer
    PanelManager.createCorner(deleteBtn, 0.2)
    PanelManager.setupButtonEffects(deleteBtn)

    deleteBtn.MouseButton1Click:Connect(function()
        popup:Destroy()
        if onConfirm then onConfirm() end
    end)
end

-- Create simple confirmation popup for common pets
local function createConfirmPopup(petName, isBulk, count, onConfirm)
    if not screenGuiRef then return end

    local existing = screenGuiRef:FindFirstChild("DeleteWarningPopup")
    if existing then existing:Destroy() end

    local popup = Instance.new("Frame")
    popup.Name = "DeleteWarningPopup"
    popup.Size = UDim2.new(0, 280, 0, 140)
    popup.Position = UDim2.new(0.5, -140, 0.5, -70)
    popup.BackgroundColor3 = Color3.fromRGB(16, 16, 16)
    popup.BorderSizePixel = 0
    popup.ZIndex = 600
    popup.Parent = screenGuiRef

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = popup

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(255, 255, 255)
    stroke.Thickness = 1
    stroke.Parent = popup

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, 0, 0, 30)
    titleLabel.Position = UDim2.new(0, 0, 0, 15)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = isBulk and ("Delete " .. count .. " pets?") or ("Delete " .. petName .. "?")
    titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleLabel.TextSize = 18
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.Parent = popup

    local msgLabel = Instance.new("TextLabel")
    msgLabel.Size = UDim2.new(1, 0, 0, 24)
    msgLabel.Position = UDim2.new(0, 0, 0, 50)
    msgLabel.BackgroundTransparency = 1
    msgLabel.Text = "This cannot be undone."
    msgLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
    msgLabel.TextSize = 14
    msgLabel.Font = Enum.Font.GothamSemibold
    msgLabel.Parent = popup

    local btnContainer = Instance.new("Frame")
    btnContainer.Size = UDim2.new(1, -20, 0, 36)
    btnContainer.Position = UDim2.new(0, 10, 1, -46)
    btnContainer.BackgroundTransparency = 1
    btnContainer.Parent = popup

    local btnLayout = Instance.new("UIListLayout")
    btnLayout.FillDirection = Enum.FillDirection.Horizontal
    btnLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    btnLayout.Padding = UDim.new(0, 10)
    btnLayout.Parent = btnContainer

    local cancelBtn = Instance.new("TextButton")
    cancelBtn.Size = UDim2.new(0, 100, 0, 36)
    cancelBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    cancelBtn.BorderSizePixel = 0
    cancelBtn.Text = "CANCEL"
    cancelBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    cancelBtn.TextSize = 14
    cancelBtn.Font = Enum.Font.GothamBold
    cancelBtn.Parent = btnContainer
    PanelManager.createCorner(cancelBtn, 0.2)
    PanelManager.setupButtonEffects(cancelBtn)

    cancelBtn.MouseButton1Click:Connect(function()
        popup:Destroy()
    end)

    local confirmBtn = Instance.new("TextButton")
    confirmBtn.Size = UDim2.new(0, 100, 0, 36)
    confirmBtn.BackgroundColor3 = Color3.fromRGB(180, 30, 30)
    confirmBtn.BorderSizePixel = 0
    confirmBtn.Text = "CONFIRM"
    confirmBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    confirmBtn.TextSize = 14
    confirmBtn.Font = Enum.Font.GothamBold
    confirmBtn.Parent = btnContainer
    PanelManager.createCorner(confirmBtn, 0.2)
    PanelManager.setupButtonEffects(confirmBtn)

    confirmBtn.MouseButton1Click:Connect(function()
        popup:Destroy()
        if onConfirm then onConfirm() end
    end)
end

-- ============================================
-- MERGE CONFIRMATION POPUP
-- ============================================
local function createMergeConfirmPopup(petName, currentStars, onConfirm)
    if not screenGuiRef then return end

    local existing = screenGuiRef:FindFirstChild("DeleteWarningPopup")
    if existing then existing:Destroy() end

    local popup = Instance.new("Frame")
    popup.Name = "DeleteWarningPopup"
    popup.Size = UDim2.new(0, 300, 0, 200)
    popup.Position = UDim2.new(0.5, -150, 0.5, -100)
    popup.BackgroundColor3 = Color3.fromRGB(16, 16, 16)
    popup.BorderSizePixel = 0
    popup.ZIndex = 600
    popup.Parent = screenGuiRef

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = popup

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(255, 200, 50)
    stroke.Thickness = 2
    stroke.Parent = popup

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, 0, 0, 36)
    titleLabel.Position = UDim2.new(0, 0, 0, 15)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "MERGE PETS"
    titleLabel.TextColor3 = Color3.fromRGB(255, 200, 50)
    titleLabel.TextSize = 22
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.Parent = popup

    local petNameLabel = Instance.new("TextLabel")
    petNameLabel.Size = UDim2.new(1, 0, 0, 24)
    petNameLabel.Position = UDim2.new(0, 0, 0, 55)
    petNameLabel.BackgroundTransparency = 1
    petNameLabel.Text = petName
    petNameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    petNameLabel.TextSize = 18
    petNameLabel.Font = Enum.Font.GothamBold
    petNameLabel.Parent = popup

    local starsLabel = Instance.new("TextLabel")
    starsLabel.Size = UDim2.new(1, 0, 0, 30)
    starsLabel.Position = UDim2.new(0, 0, 0, 82)
    starsLabel.BackgroundTransparency = 1
    starsLabel.Text = getStarString(currentStars) .. "  ->  " .. getStarString(currentStars + 1)
    starsLabel.TextColor3 = Color3.fromRGB(255, 200, 50)
    starsLabel.TextSize = 16
    starsLabel.Font = Enum.Font.GothamBold
    starsLabel.Parent = popup

    local infoLabel = Instance.new("TextLabel")
    infoLabel.Size = UDim2.new(1, 0, 0, 20)
    infoLabel.Position = UDim2.new(0, 0, 0, 112)
    infoLabel.BackgroundTransparency = 1
    infoLabel.Text = "3 pets will be consumed"
    infoLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
    infoLabel.TextSize = 12
    infoLabel.Font = Enum.Font.GothamSemibold
    infoLabel.Parent = popup

    local btnContainer = Instance.new("Frame")
    btnContainer.Size = UDim2.new(1, -20, 0, 40)
    btnContainer.Position = UDim2.new(0, 10, 1, -50)
    btnContainer.BackgroundTransparency = 1
    btnContainer.Parent = popup

    local btnLayout = Instance.new("UIListLayout")
    btnLayout.FillDirection = Enum.FillDirection.Horizontal
    btnLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    btnLayout.Padding = UDim.new(0, 10)
    btnLayout.Parent = btnContainer

    local cancelBtn = Instance.new("TextButton")
    cancelBtn.Size = UDim2.new(0, 120, 0, 40)
    cancelBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    cancelBtn.BorderSizePixel = 0
    cancelBtn.Text = "CANCEL"
    cancelBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    cancelBtn.TextSize = 14
    cancelBtn.Font = Enum.Font.GothamBold
    cancelBtn.Parent = btnContainer
    PanelManager.createCorner(cancelBtn, 0.2)
    PanelManager.setupButtonEffects(cancelBtn)

    cancelBtn.MouseButton1Click:Connect(function()
        popup:Destroy()
    end)

    local confirmBtn = Instance.new("TextButton")
    confirmBtn.Size = UDim2.new(0, 120, 0, 40)
    confirmBtn.BackgroundColor3 = Color3.fromRGB(255, 200, 50)
    confirmBtn.BorderSizePixel = 0
    confirmBtn.Text = "CONFIRM"
    confirmBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
    confirmBtn.TextSize = 14
    confirmBtn.Font = Enum.Font.GothamBold
    confirmBtn.Parent = btnContainer
    PanelManager.createCorner(confirmBtn, 0.2)
    PanelManager.setupButtonEffects(confirmBtn)

    confirmBtn.MouseButton1Click:Connect(function()
        popup:Destroy()
        if onConfirm then onConfirm() end
    end)
end

-- Handle single pet deletion
local function handleDeletePet(pet)
    if not pet then return end

    local function doDelete()
        NetworkClient.deletePets({pet.id})
    end

    if isRareOrHigher(pet.rarity) then
        createWarningPopup(
            "WARNING",
            "You are about to delete a " .. string.upper(pet.rarity) .. " pet!",
            pet.name,
            false,
            doDelete
        )
    else
        createConfirmPopup(pet.name, false, 1, doDelete)
    end
end

-- Handle bulk deletion
local function handleBulkDelete()
    local petIds = {}
    local hasRare = false
    local rareCount = 0

    for id, _ in pairs(selectedPets) do
        table.insert(petIds, id)
        for _, pet in ipairs(OWNED_PETS) do
            if pet.id == id then
                if isRareOrHigher(pet.rarity) then
                    hasRare = true
                    rareCount = rareCount + 1
                end
                break
            end
        end
    end

    local function doDelete()
        NetworkClient.deletePets(petIds)
        selectionMode = false
        selectedPets = {}
        PetsPanel.refresh()
        PetsPanel.updateSelectionBar()
    end

    if hasRare then
        createWarningPopup(
            "WARNING",
            "You are about to delete " .. rareCount .. " rare/epic/legendary pet(s)!",
            nil,
            true,
            doDelete
        )
    else
        createConfirmPopup(nil, true, #petIds, doDelete)
    end
end

-- ============================================
-- HANDLE BULK MERGE
-- ============================================
local function handleBulkMerge()
    local canMerge, _, mergePets = getMergeStatus()
    if not canMerge or not mergePets then return end

    local petName = mergePets[1].name
    local currentStars = mergePets[1].stars or 1
    local petIds = {}
    for _, pet in ipairs(mergePets) do
        table.insert(petIds, pet.id)
    end

    createMergeConfirmPopup(petName, currentStars, function()
        NetworkClient.mergePets(petIds)
        -- Exit selection mode after sending merge request
        selectionMode = false
        selectedPets = {}
        if selectButton then
            selectButton.Text = "SELECT"
            selectButton.BackgroundColor3 = Config.COLORS.BUTTON_BG
        end
        PetsPanel.refresh()
        PetsPanel.updateSelectionBar()
    end)
end

-- Toggle selection mode
function PetsPanel.toggleSelectionMode()
    selectionMode = not selectionMode
    selectedPets = {}

    if selectButton then
        selectButton.Text = selectionMode and "CANCEL" or "SELECT"
        selectButton.BackgroundColor3 = selectionMode and Color3.fromRGB(180, 30, 30) or Config.COLORS.BUTTON_BG
    end

    PetsPanel.refresh()
    PetsPanel.updateSelectionBar()
end

-- ============================================
-- UPDATE SELECTION BAR (with MERGE + DELETE)
-- ============================================
function PetsPanel.updateSelectionBar()
    if not panel then return end

    if selectionBar then
        selectionBar:Destroy()
        selectionBar = nil
    end

    if not selectionMode then return end

    local canMerge, statusMessage = getMergeStatus()
    local selectedCount = 0
    for _ in pairs(selectedPets) do
        selectedCount = selectedCount + 1
    end

    -- Create selection bar (taller to fit status + buttons)
    selectionBar = Instance.new("Frame")
    selectionBar.Name = "SelectionBar"
    selectionBar.Size = UDim2.new(1, 0, 0, 64)
    selectionBar.Position = UDim2.new(0, 0, 1, -64)
    selectionBar.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    selectionBar.BorderSizePixel = 0
    selectionBar.ZIndex = 100
    selectionBar.Parent = panel
    PanelManager.createCorner(selectionBar, 0.08)

    -- Status label
    local statusLabel = Instance.new("TextLabel")
    statusLabel.Name = "StatusLabel"
    statusLabel.Size = UDim2.new(1, -16, 0, 20)
    statusLabel.Position = UDim2.new(0, 8, 0, 4)
    statusLabel.BackgroundTransparency = 1
    statusLabel.Text = statusMessage
    statusLabel.TextColor3 = canMerge and Color3.fromRGB(255, 200, 50) or Color3.fromRGB(180, 180, 180)
    statusLabel.TextSize = 11
    statusLabel.Font = Enum.Font.GothamBold
    statusLabel.TextXAlignment = Enum.TextXAlignment.Left
    statusLabel.TextTruncate = Enum.TextTruncate.AtEnd
    statusLabel.Parent = selectionBar

    -- Buttons row
    local btnRow = Instance.new("Frame")
    btnRow.Size = UDim2.new(1, -16, 0, 36)
    btnRow.Position = UDim2.new(0, 8, 0, 26)
    btnRow.BackgroundTransparency = 1
    btnRow.Parent = selectionBar

    local btnLayout = Instance.new("UIListLayout")
    btnLayout.FillDirection = Enum.FillDirection.Horizontal
    btnLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
    btnLayout.Padding = UDim.new(0, 8)
    btnLayout.Parent = btnRow

    -- MERGE SELECTED button (gold)
    local mergeBtn = Instance.new("TextButton")
    mergeBtn.Size = UDim2.new(0, 130, 0, 36)
    mergeBtn.BackgroundColor3 = canMerge and Color3.fromRGB(255, 200, 50) or Color3.fromRGB(60, 60, 60)
    mergeBtn.BorderSizePixel = 0
    mergeBtn.Text = "MERGE"
    mergeBtn.TextColor3 = canMerge and Color3.fromRGB(0, 0, 0) or Color3.fromRGB(100, 100, 100)
    mergeBtn.TextSize = 12
    mergeBtn.Font = Enum.Font.GothamBold
    mergeBtn.Parent = btnRow
    PanelManager.createCorner(mergeBtn, 0.2)

    if canMerge then
        PanelManager.setupButtonEffects(mergeBtn)
        mergeBtn.MouseButton1Click:Connect(handleBulkMerge)
    end

    -- DELETE SELECTED button (red)
    local deleteBtn = Instance.new("TextButton")
    deleteBtn.Size = UDim2.new(0, 130, 0, 36)
    deleteBtn.BackgroundColor3 = selectedCount > 0 and Color3.fromRGB(180, 30, 30) or Color3.fromRGB(60, 60, 60)
    deleteBtn.BorderSizePixel = 0
    deleteBtn.Text = "DELETE"
    deleteBtn.TextColor3 = selectedCount > 0 and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(100, 100, 100)
    deleteBtn.TextSize = 12
    deleteBtn.Font = Enum.Font.GothamBold
    deleteBtn.Parent = btnRow
    PanelManager.createCorner(deleteBtn, 0.2)

    if selectedCount > 0 then
        PanelManager.setupButtonEffects(deleteBtn)
        deleteBtn.MouseButton1Click:Connect(handleBulkDelete)
    end
end

-- Toggle pet selection
local function togglePetSelection(petId)
    -- Check if pet is locked - cannot select locked pets
    for _, pet in ipairs(OWNED_PETS) do
        if pet.id == petId and pet.locked then
            PetsPanel.showLockError()
            return
        end
    end

    if selectedPets[petId] then
        selectedPets[petId] = nil
    else
        selectedPets[petId] = true
    end
    PetsPanel.refresh()
    PetsPanel.updateSelectionBar()
end

-- ============================================
-- LOCK ERROR NOTIFICATION
-- ============================================
function PetsPanel.showLockError()
    if not screenGuiRef then return end

    local existing = screenGuiRef:FindFirstChild("LockErrorNotif")
    if existing then existing:Destroy() end

    local notif = Instance.new("Frame")
    notif.Name = "LockErrorNotif"
    notif.Size = UDim2.new(0, 280, 0, 60)
    notif.Position = UDim2.new(0.5, -140, 0.85, 0)
    notif.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    notif.BorderSizePixel = 0
    notif.ZIndex = 500
    notif.Parent = screenGuiRef

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = notif

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(255, 255, 255)
    stroke.Thickness = 2
    stroke.Parent = notif

    local icon = Instance.new("TextLabel")
    icon.Size = UDim2.new(0, 40, 0, 40)
    icon.Position = UDim2.new(0, 10, 0.5, -20)
    icon.BackgroundTransparency = 1
    icon.Text = "\xe2\x97\x8f"
    icon.TextColor3 = Color3.fromRGB(255, 255, 255)
    icon.TextSize = 20
    icon.Font = Enum.Font.GothamBold
    icon.Parent = notif

    local text = Instance.new("TextLabel")
    text.Size = UDim2.new(1, -60, 1, 0)
    text.Position = UDim2.new(0, 50, 0, 0)
    text.BackgroundTransparency = 1
    text.Text = "Unlock pet first"
    text.TextColor3 = Color3.fromRGB(255, 255, 255)
    text.TextSize = 16
    text.Font = Enum.Font.GothamBold
    text.TextWrapped = true
    text.TextXAlignment = Enum.TextXAlignment.Left
    text.Parent = notif

    -- Animate in
    notif.Size = UDim2.new(0, 0, 0, 60)
    local tweenIn = TweenService:Create(notif, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = UDim2.new(0, 280, 0, 60)})
    tweenIn:Play()

    task.delay(2, function()
        if not notif or not notif.Parent then return end
        local tweenOut = TweenService:Create(notif, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Size = UDim2.new(0, 0, 0, 60), BackgroundTransparency = 1})
        tweenOut:Play()
        tweenOut.Completed:Connect(function()
            notif:Destroy()
        end)
    end)
end

-- ============================================
-- REFRESH PETS PANEL
-- ============================================
function PetsPanel.refresh()
    if not petsContent then return end

    for _, child in ipairs(petsContent:GetChildren()) do
        if child.Name ~= "UIGridLayout" and child.Name ~= "UIPadding" then
            child:Destroy()
        end
    end

    local filteredPets = {}
    for _, pet in ipairs(OWNED_PETS) do
        if pet and pet.name then
            local includePet = false

            if currentPetFilter == 1 then
                includePet = true
            elseif currentPetFilter == 2 then
                includePet = pet.equipped == true
            elseif currentPetFilter == 3 then
                local petRarityLevel = Config.RARITY_ORDER[pet.rarity] or 1
                includePet = petRarityLevel >= 2
            end

            if includePet then
                table.insert(filteredPets, pet)
            end
        end
    end

    if #filteredPets == 0 then
        local emptyLabel = Instance.new("TextLabel")
        emptyLabel.Name = "EmptyState"
        emptyLabel.Size = UDim2.new(1, 0, 1, 0)
        emptyLabel.BackgroundTransparency = 1
        if currentPetFilter == 2 then
            emptyLabel.Text = "Nenhum pet equipado"
        elseif currentPetFilter == 3 then
            emptyLabel.Text = "Nenhum pet Raro+ encontrado"
        else
            emptyLabel.Text = "Nenhum pet ainda"
        end
        emptyLabel.TextColor3 = Config.COLORS.DESC_TEXT
        emptyLabel.TextSize = 18
        emptyLabel.Font = Enum.Font.GothamSemibold
        emptyLabel.TextWrapped = true
        emptyLabel.TextXAlignment = Enum.TextXAlignment.Center
        emptyLabel.TextYAlignment = Enum.TextYAlignment.Center
        emptyLabel.Parent = petsContent
        return
    end

    for _, pet in ipairs(filteredPets) do
        local card = Instance.new("Frame")
        card.Name = pet.name .. "_" .. tostring(pet.id)
        card.BackgroundColor3 = Config.COLORS.SECONDARY_BG
        card.BorderSizePixel = 0
        card.Parent = petsContent
        PanelManager.createCorner(card, 0.1)
        PanelManager.createStroke(card)

        -- White border for locked pets
        if pet.locked then
            local lockStroke = Instance.new("UIStroke")
            lockStroke.Color = Color3.fromRGB(255, 255, 255)
            lockStroke.Thickness = 1.5
            lockStroke.Parent = card
        end

        -- Lock button (top right corner)
        local lockBtn = Instance.new("TextButton")
        lockBtn.Name = "LockBtn"
        lockBtn.Size = UDim2.new(0, 20, 0, 20)
        lockBtn.Position = UDim2.new(1, -24, 0, 4)
        lockBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        lockBtn.BorderSizePixel = 0
        lockBtn.Text = pet.locked and "\xe2\x97\x8f" or "\xe2\x97\x8b"
        lockBtn.TextColor3 = pet.locked and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(100, 100, 100)
        lockBtn.TextSize = 14
        lockBtn.Font = Enum.Font.GothamBold
        lockBtn.ZIndex = 10
        lockBtn.Parent = card
        PanelManager.createCorner(lockBtn, 0.3)

        -- Tooltip for lock state
        local lockTooltip = Instance.new("TextLabel")
        lockTooltip.Name = "LockTooltip"
        lockTooltip.Size = UDim2.new(0, 70, 0, 20)
        lockTooltip.Position = UDim2.new(1, -74, 0, 26)
        lockTooltip.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        lockTooltip.BorderSizePixel = 0
        lockTooltip.Text = pet.locked and "LOCKED" or "UNLOCKED"
        lockTooltip.TextColor3 = Color3.fromRGB(255, 255, 255)
        lockTooltip.TextSize = 9
        lockTooltip.Font = Enum.Font.GothamBold
        lockTooltip.ZIndex = 11
        lockTooltip.Visible = false
        lockTooltip.Parent = card
        PanelManager.createCorner(lockTooltip, 0.2)

        lockBtn.MouseEnter:Connect(function()
            lockTooltip.Visible = true
        end)
        lockBtn.MouseLeave:Connect(function()
            lockTooltip.Visible = false
        end)

        lockBtn.MouseButton1Click:Connect(function()
            NetworkClient.togglePetLock(pet.id)
        end)

        -- Selection checkbox (only in selection mode for unequipped, unlocked pets)
        if selectionMode and not pet.equipped and not pet.locked then
            local checkbox = Instance.new("TextButton")
            checkbox.Name = "Checkbox"
            checkbox.Size = UDim2.new(0, 20, 0, 20)
            checkbox.Position = UDim2.new(0, 4, 0, 4)
            checkbox.BackgroundColor3 = selectedPets[pet.id] and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(50, 50, 50)
            checkbox.BorderSizePixel = 0
            checkbox.Text = selectedPets[pet.id] and "X" or ""
            checkbox.TextColor3 = Color3.fromRGB(0, 0, 0)
            checkbox.TextSize = 14
            checkbox.Font = Enum.Font.GothamBold
            checkbox.ZIndex = 10
            checkbox.Parent = card
            PanelManager.createCorner(checkbox, 0.2)

            checkbox.MouseButton1Click:Connect(function()
                togglePetSelection(pet.id)
            end)
        end

        local petEmoji = Instance.new("TextLabel")
        petEmoji.Size = UDim2.new(1, 0, 0, 36)
        petEmoji.Position = UDim2.new(0, 0, 0, 6)
        petEmoji.BackgroundTransparency = 1
        petEmoji.Text = getDisplayEmoji(pet)
        local isOverride = PET_EMOJI_OVERRIDE[pet.name] ~= nil
        petEmoji.TextSize = isOverride and 14 or 32
        petEmoji.Font = Enum.Font.GothamBold
        petEmoji.Parent = card

        local petName = Instance.new("TextLabel")
        petName.Size = UDim2.new(1, -8, 0, 24)
        petName.Position = UDim2.new(0, 4, 0, 42)
        petName.BackgroundTransparency = 1
        petName.Text = pet.name
        petName.TextColor3 = Config.COLORS.TITLE_TEXT
        petName.TextSize = 10
        petName.Font = Enum.Font.GothamBold
        petName.TextWrapped = true
        petName.TextTruncate = Enum.TextTruncate.AtEnd
        petName.Parent = card

        -- Rarity pill
        local rarityPill = Instance.new("Frame")
        rarityPill.Size = UDim2.new(0, 55, 0, 14)
        rarityPill.Position = UDim2.new(0.5, -27.5, 0, 66)
        rarityPill.BackgroundColor3 = Config.COLORS.MAIN_BG
        rarityPill.BorderSizePixel = 0
        rarityPill.Parent = card
        PanelManager.createCorner(rarityPill, 0.5)

        local rarityText = Instance.new("TextLabel")
        rarityText.Size = UDim2.new(1, 0, 1, 0)
        rarityText.BackgroundTransparency = 1
        rarityText.Text = pet.rarity
        rarityText.TextColor3 = Config.RARITY_COLORS[pet.rarity] or Config.COLORS.DESC_TEXT
        rarityText.TextSize = 8
        rarityText.Font = Enum.Font.GothamBold
        rarityText.Parent = rarityPill

        -- Star display
        local starLabel = Instance.new("TextLabel")
        starLabel.Size = UDim2.new(1, 0, 0, 14)
        starLabel.Position = UDim2.new(0, 0, 0, 82)
        starLabel.BackgroundTransparency = 1
        starLabel.Text = getStarString(pet.stars or 1)
        starLabel.TextColor3 = Color3.fromRGB(255, 200, 50)
        starLabel.TextSize = 10
        starLabel.Font = Enum.Font.GothamBold
        starLabel.Parent = card

        local multLabel = Instance.new("TextLabel")
        multLabel.Size = UDim2.new(1, 0, 0, 14)
        multLabel.Position = UDim2.new(0, 0, 0, 96)
        multLabel.BackgroundTransparency = 1
        multLabel.Text = "x" .. tostring(pet.multiplier) .. " stardust"
        multLabel.TextColor3 = Config.COLORS.DESC_TEXT
        multLabel.TextSize = 10
        multLabel.Font = Enum.Font.GothamSemibold
        multLabel.Parent = card

        -- Delete button (bottom left, only for unequipped AND unlocked pets, only outside selection mode)
        if not selectionMode then
            if not pet.equipped and not pet.locked then
                local deleteBtn = Instance.new("TextButton")
                deleteBtn.Name = "DeleteBtn"
                deleteBtn.Size = UDim2.new(0, 50, 0, 20)
                deleteBtn.Position = UDim2.new(0, 4, 1, -52)
                deleteBtn.BackgroundColor3 = Color3.fromRGB(180, 30, 30)
                deleteBtn.BorderSizePixel = 0
                deleteBtn.Text = "DELETE"
                deleteBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
                deleteBtn.TextSize = 10
                deleteBtn.Font = Enum.Font.GothamBold
                deleteBtn.Parent = card
                PanelManager.createCorner(deleteBtn, 0.2)
                PanelManager.setupButtonEffects(deleteBtn)

                deleteBtn.MouseButton1Click:Connect(function()
                    handleDeletePet(pet)
                end)
            elseif not pet.equipped and pet.locked then
                local lockedLabel = Instance.new("TextLabel")
                lockedLabel.Size = UDim2.new(0, 50, 0, 20)
                lockedLabel.Position = UDim2.new(0, 4, 1, -52)
                lockedLabel.BackgroundTransparency = 1
                lockedLabel.Text = "LOCKED"
                lockedLabel.TextColor3 = Color3.fromRGB(100, 100, 100)
                lockedLabel.TextSize = 8
                lockedLabel.Font = Enum.Font.GothamBold
                lockedLabel.Parent = card
            elseif pet.equipped then
                local equipFirstLabel = Instance.new("TextLabel")
                equipFirstLabel.Size = UDim2.new(0, 70, 0, 20)
                equipFirstLabel.Position = UDim2.new(0, 4, 1, -52)
                equipFirstLabel.BackgroundTransparency = 1
                equipFirstLabel.Text = "EQUIP FIRST"
                equipFirstLabel.TextColor3 = Color3.fromRGB(80, 80, 80)
                equipFirstLabel.TextSize = 8
                equipFirstLabel.Font = Enum.Font.GothamBold
                equipFirstLabel.Parent = card
            end
        end

        local equipBtn = Instance.new("TextButton")
        equipBtn.Size = UDim2.new(1, -8, 0, 24)
        equipBtn.Position = UDim2.new(0, 4, 1, -28)
        equipBtn.BackgroundColor3 = pet.equipped and Config.COLORS.MAIN_BG or Config.COLORS.BUTTON_BG
        equipBtn.BorderSizePixel = 0
        equipBtn.Text = pet.equipped and "Unequip" or "Equip"
        equipBtn.TextColor3 = Config.COLORS.TITLE_TEXT
        equipBtn.TextSize = 11
        equipBtn.Font = Enum.Font.GothamBold
        equipBtn.Parent = card
        PanelManager.createCorner(equipBtn, 0.2)
        if not pet.equipped then
            PanelManager.createStroke(equipBtn)
        end
        PanelManager.setupButtonEffects(equipBtn)

        local equipDebounce = false

        equipBtn.MouseButton1Click:Connect(function()
            if equipDebounce then return end
            equipDebounce = true

            print("[PetsPanel] Equip button clicked - pet.id:", pet.id, "pet.equipped:", pet.equipped, "will send:", not pet.equipped)
            NetworkClient.equipPet(pet.id, not pet.equipped)

            task.wait(0.5)
            equipDebounce = false
        end)
    end
end

-- ============================================
-- UPDATE EQUIPPED PETS DISPLAY
-- ============================================
function PetsPanel.updateEquipped(equippedPets)
    if not equippedRow then return end

    for _, child in ipairs(equippedRow:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end

    local maxPets = getMaxPets()
    local slotSize = 75

    for i = 1, maxPets do
        local slot = Instance.new("Frame")
        slot.Name = "Slot" .. i
        slot.Size = UDim2.new(0, slotSize, 0, slotSize)
        slot.BackgroundColor3 = Config.COLORS.SECONDARY_BG
        slot.BorderSizePixel = 0
        slot.Parent = equippedRow
        PanelManager.createCorner(slot, 0.1)
        PanelManager.createStroke(slot)

        local petId = equippedPets and equippedPets[i]
        local petData = nil

        if petId then
            for _, pet in ipairs(OWNED_PETS) do
                if pet and pet.id == petId then
                    petData = pet
                    break
                end
            end
        end

        if petData then
            local isOverride = PET_EMOJI_OVERRIDE[petData.name] ~= nil
            local petEmoji = Instance.new("TextLabel")
            petEmoji.Size = UDim2.new(1, 0, 0, 28)
            petEmoji.Position = UDim2.new(0, 0, 0, 2)
            petEmoji.BackgroundTransparency = 1
            petEmoji.Text = getDisplayEmoji(petData)
            petEmoji.TextSize = isOverride and 10 or 24
            petEmoji.Font = Enum.Font.GothamBold
            petEmoji.Parent = slot

            local petNameLabel = Instance.new("TextLabel")
            petNameLabel.Size = UDim2.new(1, -4, 0, 14)
            petNameLabel.Position = UDim2.new(0, 2, 0, 30)
            petNameLabel.BackgroundTransparency = 1
            petNameLabel.Text = petData.name
            petNameLabel.TextColor3 = Config.COLORS.TITLE_TEXT
            petNameLabel.TextSize = 8
            petNameLabel.Font = Enum.Font.GothamBold
            petNameLabel.TextWrapped = true
            petNameLabel.Parent = slot

            -- Star display in equipped slot
            local starLabel = Instance.new("TextLabel")
            starLabel.Size = UDim2.new(1, 0, 0, 12)
            starLabel.Position = UDim2.new(0, 0, 0, 44)
            starLabel.BackgroundTransparency = 1
            starLabel.Text = getStarString(petData.stars or 1)
            starLabel.TextColor3 = Color3.fromRGB(255, 200, 50)
            starLabel.TextSize = 8
            starLabel.Font = Enum.Font.GothamBold
            starLabel.Parent = slot

            local petMult = Instance.new("TextLabel")
            petMult.Size = UDim2.new(1, 0, 0, 14)
            petMult.Position = UDim2.new(0, 0, 0, 56)
            petMult.BackgroundTransparency = 1
            petMult.Text = "x" .. tostring(petData.multiplier)
            petMult.TextColor3 = Config.COLORS.DESC_TEXT
            petMult.TextSize = 8
            petMult.Font = Enum.Font.GothamSemibold
            petMult.Parent = slot
        else
            local emptyText = Instance.new("TextLabel")
            emptyText.Size = UDim2.new(1, 0, 1, 0)
            emptyText.BackgroundTransparency = 1
            emptyText.Text = "+\nEmpty"
            emptyText.TextColor3 = Config.COLORS.DESC_TEXT
            emptyText.TextSize = 14
            emptyText.Font = Enum.Font.GothamSemibold
            emptyText.TextWrapped = true
            emptyText.Parent = slot
        end
    end
end

-- ============================================
-- CREATE PANEL
-- ============================================
function PetsPanel.create(screenGui)
    panel = screenGui:FindFirstChild("PetsPanel")
    if not panel then return end

    screenGuiRef = screenGui

    local petsClose = panel:FindFirstChild("CloseButton")

    local maxPets = getMaxPets()
    local equippedLabel = Instance.new("TextLabel")
    equippedLabel.Name = "EquippedLabel"
    equippedLabel.Size = UDim2.new(1, -32, 0, 24)
    equippedLabel.Position = UDim2.new(0, 16, 0, 52)
    equippedLabel.BackgroundTransparency = 1
    equippedLabel.Text = "Equipped Pets (" .. maxPets .. " max)"
    equippedLabel.TextColor3 = Config.COLORS.TITLE_TEXT
    equippedLabel.TextSize = 14
    equippedLabel.Font = Enum.Font.GothamBold
    equippedLabel.TextXAlignment = Enum.TextXAlignment.Left
    equippedLabel.Parent = panel

    local rowHeight = maxPets > 3 and 80 or 100
    equippedRow = Instance.new("Frame")
    equippedRow.Name = "EquippedRow"
    equippedRow.Size = UDim2.new(1, -16, 0, rowHeight)
    equippedRow.Position = UDim2.new(0, 8, 0, 80)
    equippedRow.BackgroundTransparency = 1
    equippedRow.ClipsDescendants = false
    equippedRow.Parent = panel

    local equippedPadding = Instance.new("UIPadding")
    equippedPadding.PaddingTop = UDim.new(0, 4)
    equippedPadding.PaddingLeft = UDim.new(0, 4)
    equippedPadding.Parent = equippedRow

    local equippedLayout = Instance.new("UIGridLayout")
    equippedLayout.CellSize = UDim2.new(0, 75, 0, 75)
    equippedLayout.CellPadding = UDim2.new(0, 6, 0, 6)
    equippedLayout.FillDirection = Enum.FillDirection.Horizontal
    equippedLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
    equippedLayout.Parent = equippedRow

    local filterTabsPos = maxPets > 3 and 170 or 190
    local filterTabs = Instance.new("Frame")
    filterTabs.Name = "FilterTabs"
    filterTabs.Size = UDim2.new(1, -32, 0, 32)
    filterTabs.Position = UDim2.new(0, 16, 0, filterTabsPos)
    filterTabs.BackgroundTransparency = 1
    filterTabs.Parent = panel

    local filterLayout = Instance.new("UIListLayout")
    filterLayout.FillDirection = Enum.FillDirection.Horizontal
    filterLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    filterLayout.Padding = UDim.new(0, 6)
    filterLayout.Parent = filterTabs

    local FILTERS = {"All", "Equipped", "Rare+"}

    for i, filterName in ipairs(FILTERS) do
        local filterBtn = Instance.new("TextButton")
        filterBtn.Size = UDim2.new(0, 80, 0, 28)
        filterBtn.AnchorPoint = Vector2.new(0.5, 0.5)
        filterBtn.BackgroundColor3 = i == 1 and Config.COLORS.BUTTON_BG or Config.COLORS.SECONDARY_BG
        filterBtn.BorderSizePixel = 0
        filterBtn.Text = filterName
        filterBtn.TextColor3 = Config.COLORS.TITLE_TEXT
        filterBtn.TextSize = 12
        filterBtn.Font = Enum.Font.GothamBold
        filterBtn.Parent = filterTabs
        PanelManager.createCorner(filterBtn, 0.2)
        PanelManager.createStroke(filterBtn, i == 1 and Color3.fromRGB(150, 150, 150) or Color3.fromRGB(60, 60, 60), 1.5)
        PanelManager.setupButtonEffects(filterBtn)
        table.insert(filterButtons, filterBtn)

        filterBtn.MouseButton1Click:Connect(function()
            currentPetFilter = i
            for j, btn in ipairs(filterButtons) do
                btn.BackgroundColor3 = j == i and Config.COLORS.BUTTON_BG or Config.COLORS.SECONDARY_BG
                local btnStroke = btn:FindFirstChildOfClass("UIStroke")
                if btnStroke then
                    btnStroke.Color = j == i and Color3.fromRGB(150, 150, 150) or Color3.fromRGB(60, 60, 60)
                end
            end
            PetsPanel.refresh()
        end)
    end

    -- SELECT button for selection mode
    selectButton = Instance.new("TextButton")
    selectButton.Name = "SelectButton"
    selectButton.Size = UDim2.new(0, 60, 0, 28)
    selectButton.BackgroundColor3 = Config.COLORS.BUTTON_BG
    selectButton.BorderSizePixel = 0
    selectButton.Text = "SELECT"
    selectButton.TextColor3 = Config.COLORS.TITLE_TEXT
    selectButton.TextSize = 12
    selectButton.Font = Enum.Font.GothamBold
    selectButton.Parent = filterTabs
    PanelManager.createCorner(selectButton, 0.2)
    PanelManager.createStroke(selectButton)
    PanelManager.setupButtonEffects(selectButton)

    selectButton.MouseButton1Click:Connect(function()
        PetsPanel.toggleSelectionMode()
    end)

    -- AUTO MERGE button
    local autoMergeBtn = Instance.new("TextButton")
    autoMergeBtn.Name = "AutoMergeButton"
    autoMergeBtn.Size = UDim2.new(0, 90, 0, 28)
    autoMergeBtn.BackgroundColor3 = Config.COLORS.BUTTON_BG
    autoMergeBtn.BorderSizePixel = 0
    autoMergeBtn.Text = "AUTO MERGE"
    autoMergeBtn.TextColor3 = Config.COLORS.TITLE_TEXT
    autoMergeBtn.TextSize = 10
    autoMergeBtn.Font = Enum.Font.GothamBold
    autoMergeBtn.ZIndex = 10
    autoMergeBtn.Parent = filterTabs
    PanelManager.createCorner(autoMergeBtn, 0.2)
    PanelManager.createStroke(autoMergeBtn)
    PanelManager.setupButtonEffects(autoMergeBtn)

    autoMergeBtn.MouseButton1Click:Connect(function()
        -- Count how many merges are possible
        local groups = {}
        for _, pet in ipairs(OWNED_PETS) do
            if not pet.equipped and not pet.locked and (pet.stars or 1) < 5 then
                local key = pet.name .. "_" .. tostring(pet.stars or 1)
                if not groups[key] then
                    groups[key] = { name = pet.name, stars = pet.stars or 1, count = 0 }
                end
                groups[key].count = groups[key].count + 1
            end
        end

        local totalMerges = 0
        for _, group in pairs(groups) do
            totalMerges = totalMerges + math.floor(group.count / 3)
        end

        if totalMerges == 0 then
            PetsPanel.showMergeError("No pets available for auto-merge")
            return
        end

        -- Show confirmation popup inline
        local existing = screenGui:FindFirstChild("DeleteWarningPopup")
        if existing then existing:Destroy() end

        local popup = Instance.new("Frame")
        popup.Name = "DeleteWarningPopup"
        popup.Size = UDim2.new(0, 320, 0, 220)
        popup.Position = UDim2.new(0.5, -160, 0.5, -110)
        popup.BackgroundColor3 = Config.COLORS.MAIN_BG
        popup.BorderSizePixel = 0
        popup.ZIndex = 600
        popup.Parent = screenGui

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 12)
        corner.Parent = popup

        local stroke = Instance.new("UIStroke")
        stroke.Color = Config.COLORS.TITLE_TEXT
        stroke.Thickness = 1.5
        stroke.Parent = popup

        local titleLabel = Instance.new("TextLabel")
        titleLabel.Size = UDim2.new(1, 0, 0, 36)
        titleLabel.Position = UDim2.new(0, 0, 0, 15)
        titleLabel.BackgroundTransparency = 1
        titleLabel.Text = "AUTO MERGE"
        titleLabel.TextColor3 = Config.COLORS.TITLE_TEXT
        titleLabel.TextSize = 22
        titleLabel.Font = Enum.Font.GothamBold
        titleLabel.ZIndex = 601
        titleLabel.Parent = popup

        local infoLabel = Instance.new("TextLabel")
        infoLabel.Size = UDim2.new(1, -20, 0, 50)
        infoLabel.Position = UDim2.new(0, 10, 0, 55)
        infoLabel.BackgroundTransparency = 1
        infoLabel.Text = totalMerges .. " merge(s) available\nStarts from lowest stars\nLocked pets excluded"
        infoLabel.TextColor3 = Config.COLORS.DESC_TEXT
        infoLabel.TextSize = 14
        infoLabel.Font = Enum.Font.GothamBold
        infoLabel.TextWrapped = true
        infoLabel.ZIndex = 601
        infoLabel.Parent = popup

        local warnLabel = Instance.new("TextLabel")
        warnLabel.Size = UDim2.new(1, 0, 0, 20)
        warnLabel.Position = UDim2.new(0, 0, 0, 110)
        warnLabel.BackgroundTransparency = 1
        warnLabel.Text = "This action cannot be undone."
        warnLabel.TextColor3 = Config.COLORS.DESC_TEXT
        warnLabel.TextSize = 12
        warnLabel.Font = Enum.Font.GothamSemibold
        warnLabel.ZIndex = 601
        warnLabel.Parent = popup

        local btnContainer = Instance.new("Frame")
        btnContainer.Size = UDim2.new(1, -20, 0, 40)
        btnContainer.Position = UDim2.new(0, 10, 1, -50)
        btnContainer.BackgroundTransparency = 1
        btnContainer.ZIndex = 601
        btnContainer.Parent = popup

        local btnLayout = Instance.new("UIListLayout")
        btnLayout.FillDirection = Enum.FillDirection.Horizontal
        btnLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
        btnLayout.Padding = UDim.new(0, 10)
        btnLayout.Parent = btnContainer

        local cancelBtn = Instance.new("TextButton")
        cancelBtn.Size = UDim2.new(0, 120, 0, 40)
        cancelBtn.BackgroundColor3 = Config.COLORS.BUTTON_BG
        cancelBtn.BorderSizePixel = 0
        cancelBtn.Text = "CANCEL"
        cancelBtn.TextColor3 = Config.COLORS.TITLE_TEXT
        cancelBtn.TextSize = 14
        cancelBtn.Font = Enum.Font.GothamBold
        cancelBtn.ZIndex = 602
        cancelBtn.Parent = btnContainer
        PanelManager.createCorner(cancelBtn, 0.2)
        PanelManager.setupButtonEffects(cancelBtn)

        cancelBtn.MouseButton1Click:Connect(function()
            popup:Destroy()
        end)

        local confirmBtn = Instance.new("TextButton")
        confirmBtn.Size = UDim2.new(0, 120, 0, 40)
        confirmBtn.BackgroundColor3 = Config.COLORS.BUTTON_BG
        confirmBtn.BorderSizePixel = 0
        confirmBtn.Text = "MERGE ALL"
        confirmBtn.TextColor3 = Config.COLORS.TITLE_TEXT
        confirmBtn.TextSize = 14
        confirmBtn.Font = Enum.Font.GothamBold
        confirmBtn.ZIndex = 602
        confirmBtn.Parent = btnContainer
        PanelManager.createCorner(confirmBtn, 0.2)
        PanelManager.setupButtonEffects(confirmBtn)

        confirmBtn.MouseButton1Click:Connect(function()
            popup:Destroy()
            NetworkClient.autoMergePets()
        end)
    end)

    local contentPos = maxPets > 3 and 210 or 230
    petsContent = Instance.new("ScrollingFrame")
    petsContent.Name = "Content"
    petsContent.Size = UDim2.new(1, -32, 1, -240)
    petsContent.Position = UDim2.new(0, 16, 0, contentPos)
    petsContent.BackgroundColor3 = Config.COLORS.MAIN_BG
    petsContent.BorderSizePixel = 0
    petsContent.ScrollBarThickness = 3
    petsContent.ScrollBarImageColor3 = Color3.fromRGB(80, 80, 80)
    petsContent.Parent = panel
    PanelManager.createCorner(petsContent, 0.08)
    PanelManager.createStroke(petsContent)

    local petsPadding = Instance.new("UIPadding")
    petsPadding.PaddingTop = UDim.new(0, 10)
    petsPadding.PaddingBottom = UDim.new(0, 10)
    petsPadding.PaddingLeft = UDim.new(0, 10)
    petsPadding.PaddingRight = UDim.new(0, 10)
    petsPadding.Parent = petsContent

    local petsGrid = Instance.new("UIGridLayout")
    petsGrid.CellSize = UDim2.new(0, 100, 0, 150)
    petsGrid.CellPadding = UDim2.new(0, 10, 0, 10)
    petsGrid.Parent = petsContent

    petsGrid:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        petsContent.CanvasSize = UDim2.new(0, 0, 0, petsGrid.AbsoluteContentSize.Y + 20)
    end)

    if petsClose then
        petsClose.MouseButton1Click:Connect(function()
            PanelManager.closeActivePanel()
        end)
    end

    PanelManager.registerPanel("PetsPanel", panel)
end

-- ============================================
-- SET OWNED PETS
-- ============================================
function PetsPanel.setPets(ownedPets, equippedPets)
    print("[PetsPanel] setPets called - ownedPets:", ownedPets and #ownedPets or 0, "equippedPets:", equippedPets and #equippedPets or 0)

    OWNED_PETS = {}
    for _, pet in ipairs(ownedPets or {}) do
        if pet and pet.name then
            table.insert(OWNED_PETS, pet)
            print("[PetsPanel] Added pet:", pet.name, "id:", pet.id, "equipped:", pet.equipped, "stars:", pet.stars or 1)
        end
    end

    for _, pet in ipairs(OWNED_PETS) do
        if pet then
            pet.equipped = false
            for _, equippedId in ipairs(equippedPets or {}) do
                if pet.id == equippedId then
                    pet.equipped = true
                    break
                end
            end
        end
    end

    PetsPanel.refresh()
    PetsPanel.updateEquipped(equippedPets)
end

-- ============================================
-- ADD PET
-- ============================================
function PetsPanel.addPet(pet)
    if not pet or not pet.name then return end

    if pet.id then
        for _, existingPet in ipairs(OWNED_PETS) do
            if existingPet and existingPet.id == pet.id then
                return
            end
        end
    end

    table.insert(OWNED_PETS, {
        id = pet.id,
        name = pet.name,
        emoji = pet.emoji,
        rarity = pet.rarity,
        multiplier = pet.multiplier,
        stars = pet.stars or 1,
        equipped = false,
        locked = pet.locked or false
    })

    PetsPanel.refresh()
end

-- ============================================
-- MERGE SUCCESS NOTIFICATION
-- ============================================
function PetsPanel.showMergeSuccess(mergedPet)
    if not screenGuiRef then return end

    local petName = mergedPet and mergedPet.name or "Pet"
    local newStars = mergedPet and (mergedPet.stars or 1) or 1

    local notif = Instance.new("Frame")
    notif.Name = "MergeSuccessNotif"
    notif.Size = UDim2.new(0, 280, 0, 70)
    notif.Position = UDim2.new(0.5, -140, 0.85, 0)
    notif.BackgroundColor3 = Color3.fromRGB(30, 30, 16)
    notif.BorderSizePixel = 0
    notif.ZIndex = 500
    notif.Parent = screenGuiRef

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = notif

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(255, 200, 50)
    stroke.Thickness = 2
    stroke.Parent = notif

    local icon = Instance.new("TextLabel")
    icon.Size = UDim2.new(0, 40, 0, 40)
    icon.Position = UDim2.new(0, 10, 0.5, -20)
    icon.BackgroundTransparency = 1
    icon.Text = getStarString(newStars)
    icon.TextColor3 = Color3.fromRGB(255, 200, 50)
    icon.TextSize = 14
    icon.Font = Enum.Font.GothamBold
    icon.Parent = notif

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -60, 0, 30)
    title.Position = UDim2.new(0, 50, 0, 8)
    title.BackgroundTransparency = 1
    title.Text = petName .. " upgraded!"
    title.TextColor3 = Color3.fromRGB(255, 200, 50)
    title.TextSize = 16
    title.Font = Enum.Font.GothamBold
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = notif

    local desc = Instance.new("TextLabel")
    desc.Size = UDim2.new(1, -60, 0, 24)
    desc.Position = UDim2.new(0, 50, 0, 38)
    desc.BackgroundTransparency = 1
    desc.Text = "Now " .. getStarString(newStars) .. " (x" .. tostring(mergedPet and mergedPet.multiplier or "?") .. ")"
    desc.TextColor3 = Color3.fromRGB(200, 200, 200)
    desc.TextSize = 12
    desc.Font = Enum.Font.GothamSemibold
    desc.TextXAlignment = Enum.TextXAlignment.Left
    desc.Parent = notif

    -- Animate in
    notif.Size = UDim2.new(0, 0, 0, 70)
    local tweenIn = TweenService:Create(notif, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = UDim2.new(0, 280, 0, 70)})
    tweenIn:Play()

    task.delay(3, function()
        if not notif or not notif.Parent then return end
        local tweenOut = TweenService:Create(notif, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Size = UDim2.new(0, 0, 0, 70), BackgroundTransparency = 1})
        tweenOut:Play()
        tweenOut.Completed:Connect(function()
            notif:Destroy()
        end)
    end)
end

-- ============================================
-- AUTO MERGE CONFIRMATION POPUP
-- ============================================
-- (createAutoMergeConfirmPopup moved inline into button handler)


-- ============================================
-- MERGE ERROR NOTIFICATION
-- ============================================
function PetsPanel.showMergeError(message)
    if not screenGuiRef then return end

    local notif = Instance.new("Frame")
    notif.Name = "MergeErrorNotif"
    notif.Size = UDim2.new(0, 280, 0, 60)
    notif.Position = UDim2.new(0.5, -140, 0.85, 0)
    notif.BackgroundColor3 = Color3.fromRGB(40, 20, 20)
    notif.BorderSizePixel = 0
    notif.ZIndex = 500
    notif.Parent = screenGuiRef

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = notif

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(200, 80, 80)
    stroke.Thickness = 2
    stroke.Parent = notif

    local icon = Instance.new("TextLabel")
    icon.Size = UDim2.new(0, 40, 0, 40)
    icon.Position = UDim2.new(0, 10, 0.5, -20)
    icon.BackgroundTransparency = 1
    icon.Text = "X"
    icon.TextColor3 = Color3.fromRGB(255, 100, 100)
    icon.TextSize = 20
    icon.Font = Enum.Font.GothamBold
    icon.Parent = notif

    local text = Instance.new("TextLabel")
    text.Size = UDim2.new(1, -60, 1, 0)
    text.Position = UDim2.new(0, 50, 0, 0)
    text.BackgroundTransparency = 1
    text.Text = message or "Merge failed"
    text.TextColor3 = Color3.fromRGB(255, 150, 150)
    text.TextSize = 14
    text.Font = Enum.Font.GothamBold
    text.TextWrapped = true
    text.TextXAlignment = Enum.TextXAlignment.Left
    text.Parent = notif

    -- Animate in
    notif.Size = UDim2.new(0, 0, 0, 60)
    local tweenIn = TweenService:Create(notif, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = UDim2.new(0, 280, 0, 60)})
    tweenIn:Play()

    task.delay(3, function()
        if not notif or not notif.Parent then return end
        local tweenOut = TweenService:Create(notif, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Size = UDim2.new(0, 0, 0, 60), BackgroundTransparency = 1})
        tweenOut:Play()
        tweenOut.Completed:Connect(function()
            notif:Destroy()
        end)
    end)
end

-- ============================================
-- AUTO MERGE SUCCESS NOTIFICATION
-- ============================================
function PetsPanel.showAutoMergeSuccess(totalMerges, mergedPetsList)
    if not screenGuiRef then return end

    local notif = Instance.new("Frame")
    notif.Name = "AutoMergeSuccessNotif"
    notif.Size = UDim2.new(0, 300, 0, 70)
    notif.Position = UDim2.new(0.5, -150, 0.85, 0)
    notif.BackgroundColor3 = Config.COLORS.MAIN_BG
    notif.BorderSizePixel = 0
    notif.ZIndex = 500
    notif.Parent = screenGuiRef

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = notif

    local stroke = Instance.new("UIStroke")
    stroke.Color = Config.COLORS.TITLE_TEXT
    stroke.Thickness = 1.5
    stroke.Parent = notif

    local icon = Instance.new("TextLabel")
    icon.Size = UDim2.new(0, 40, 0, 40)
    icon.Position = UDim2.new(0, 10, 0.5, -20)
    icon.BackgroundTransparency = 1
    icon.Text = "\xe2\x9c\x85"
    icon.TextColor3 = Config.COLORS.TITLE_TEXT
    icon.TextSize = 24
    icon.Font = Enum.Font.GothamBold
    icon.Parent = notif

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -60, 0, 30)
    title.Position = UDim2.new(0, 50, 0, 8)
    title.BackgroundTransparency = 1
    title.Text = "Auto Merge Complete!"
    title.TextColor3 = Config.COLORS.TITLE_TEXT
    title.TextSize = 16
    title.Font = Enum.Font.GothamBold
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = notif

    local desc = Instance.new("TextLabel")
    desc.Size = UDim2.new(1, -60, 0, 24)
    desc.Position = UDim2.new(0, 50, 0, 38)
    desc.BackgroundTransparency = 1
    desc.Text = totalMerges .. " merge(s) completed"
    desc.TextColor3 = Config.COLORS.DESC_TEXT
    desc.TextSize = 12
    desc.Font = Enum.Font.GothamSemibold
    desc.TextXAlignment = Enum.TextXAlignment.Left
    desc.Parent = notif

    -- Animate in
    notif.Size = UDim2.new(0, 0, 0, 70)
    local tweenIn = TweenService:Create(notif, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = UDim2.new(0, 300, 0, 70)})
    tweenIn:Play()

    task.delay(3, function()
        if not notif or not notif.Parent then return end
        local tweenOut = TweenService:Create(notif, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Size = UDim2.new(0, 0, 0, 70), BackgroundTransparency = 1})
        tweenOut:Play()
        tweenOut.Completed:Connect(function()
            notif:Destroy()
        end)
    end)
end

return PetsPanel