local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local Config = require(ReplicatedStorage:WaitForChild("StardustConfig"))
local PanelManager = require(ReplicatedStorage:WaitForChild("StardustUI"):WaitForChild("PanelManager"))

local tradeAction = ReplicatedStorage:WaitForChild("TradeAction")
local tradeSync = ReplicatedStorage:WaitForChild("TradeSync")

local screenGui = playerGui:WaitForChild("StardustUI")

-- ============================================
-- STATE
-- ============================================
local OWNED_PETS = {}
local tradePanel = nil
local isInTrade = false
local tradePartner = nil
local myOfferedPets = {} -- list of pet data tables
local theirOfferedPets = {} -- list of pet data tables
local myAccepted = false
local theirAccepted = false
local inConfirmWindow = false
local confirmTimer = 0
local pendingRequestFrom = nil -- player who sent us a request
local requestNotif = nil

-- ============================================
-- HELPERS
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

local function getDisplayEmoji(pet)
    if not pet then return "?" end
    return pet.emoji or "?"
end

local function createCorner(parent, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius or 8)
    corner.Parent = parent
    return corner
end

local function createStroke(parent, color, thickness)
    local stroke = Instance.new("UIStroke")
    stroke.Color = color or Color3.fromRGB(80, 80, 80)
    stroke.Thickness = thickness or 1
    stroke.Parent = parent
    return stroke
end

local function setupButtonEffects(btn)
    local originalBg = btn.BackgroundColor3
    btn.MouseEnter:Connect(function()
        btn.BackgroundColor3 = Color3.fromRGB(
            math.min(255, math.floor(originalBg.R * 255 * 1.3)),
            math.min(255, math.floor(originalBg.G * 255 * 1.3)),
            math.min(255, math.floor(originalBg.B * 255 * 1.3))
        )
    end)
    btn.MouseLeave:Connect(function()
        btn.BackgroundColor3 = originalBg
    end)
end

-- ============================================
-- UPDATE OWNED PETS FROM SYNC
-- ============================================
local function updateOwnedPets()
    -- Listen to the main sync to keep OWNED_PETS updated
    local stardustSync = ReplicatedStorage:FindFirstChild("StardustSync")
    if stardustSync then
        stardustSync.OnClientEvent:Connect(function(stardust, starcoins, level, xp, xpNeeded, ownedPets, equippedPets)
            OWNED_PETS = ownedPets or {}
        end)
    end
end
updateOwnedPets()

-- ============================================
-- GET TRADEABLE PETS
-- ============================================
local function getTradeablePets()
    local tradeable = {}
    for _, pet in ipairs(OWNED_PETS) do
        if pet and pet.name and not pet.equipped and not pet.locked then
            -- Check not already offered
            local alreadyOffered = false
            for _, offered in ipairs(myOfferedPets) do
                if offered.id == pet.id then
                    alreadyOffered = true
                    break
                end
            end
            if not alreadyOffered then
                table.insert(tradeable, pet)
            end
        end
    end
    return tradeable
end

-- ============================================
-- SHOW NOTIFICATION
-- ============================================
local function showNotification(title, message, borderColor, duration)
    if not screenGui then return end

    local existing = screenGui:FindFirstChild("TradeNotif")
    if existing then existing:Destroy() end

    local notif = Instance.new("Frame")
    notif.Name = "TradeNotif"
    notif.Size = UDim2.new(0, 280, 0, 60)
    notif.Position = UDim2.new(0.5, -140, 0.85, 0)
    notif.BackgroundColor3 = Color3.fromRGB(16, 16, 16)
    notif.BorderSizePixel = 0
    notif.ZIndex = 500
    notif.Parent = screenGui
    createCorner(notif, 12)
    createStroke(notif, borderColor or Color3.fromRGB(255, 255, 255), 2)

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, -16, 0, 24)
    titleLabel.Position = UDim2.new(0, 8, 0, 4)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = title
    titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleLabel.TextSize = 14
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Parent = notif

    local msgLabel = Instance.new("TextLabel")
    msgLabel.Size = UDim2.new(1, -16, 0, 24)
    msgLabel.Position = UDim2.new(0, 8, 0, 30)
    msgLabel.BackgroundTransparency = 1
    msgLabel.Text = message
    msgLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
    msgLabel.TextSize = 12
    msgLabel.Font = Enum.Font.GothamSemibold
    msgLabel.TextXAlignment = Enum.TextXAlignment.Left
    msgLabel.TextWrapped = true
    msgLabel.Parent = notif

    notif.Size = UDim2.new(0, 0, 0, 60)
    local tweenIn = TweenService:Create(notif, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = UDim2.new(0, 280, 0, 60)})
    tweenIn:Play()

    task.delay(duration or 3, function()
        if not notif or not notif.Parent then return end
        local tweenOut = TweenService:Create(notif, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Size = UDim2.new(0, 0, 0, 60), BackgroundTransparency = 1})
        tweenOut:Play()
        tweenOut.Completed:Connect(function()
            notif:Destroy()
        end)
    end)
end

-- ============================================
-- SHOW INCOMING TRADE REQUEST
-- ============================================
local function showTradeRequest(fromPlayer)
    pendingRequestFrom = fromPlayer

    -- Remove existing
    local existing = screenGui:FindFirstChild("TradeRequestNotif")
    if existing then existing:Destroy() end

    local notif = Instance.new("Frame")
    notif.Name = "TradeRequestNotif"
    notif.Size = UDim2.new(0, 300, 0, 120)
    notif.Position = UDim2.new(1, -320, 0.5, -60)
    notif.BackgroundColor3 = Color3.fromRGB(16, 16, 16)
    notif.BorderSizePixel = 0
    notif.ZIndex = 600
    notif.Parent = screenGui
    createCorner(notif, 12)
    createStroke(notif, Color3.fromRGB(255, 255, 255), 1)

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, -16, 0, 24)
    titleLabel.Position = UDim2.new(0, 8, 0, 8)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "TRADE REQUEST"
    titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleLabel.TextSize = 16
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Parent = notif

    -- Avatar
    local avatarLabel = Instance.new("ImageLabel")
    avatarLabel.Name = "Avatar"
    avatarLabel.Size = UDim2.new(0, 40, 0, 40)
    avatarLabel.Position = UDim2.new(0, 8, 0, 36)
    avatarLabel.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    avatarLabel.BorderSizePixel = 0
    avatarLabel.Parent = notif
    createCorner(avatarLabel, 6)

    pcall(function()
        local thumb = Players:GetUserThumbnailAsync(fromPlayer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48)
        avatarLabel.Image = thumb
    end)

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, -64, 0, 20)
    nameLabel.Position = UDim2.new(0, 56, 0, 38)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = fromPlayer.Name
    nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    nameLabel.TextSize = 14
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.Parent = notif

    local descLabel = Instance.new("TextLabel")
    descLabel.Size = UDim2.new(1, -64, 0, 16)
    descLabel.Position = UDim2.new(0, 56, 0, 58)
    descLabel.BackgroundTransparency = 1
    descLabel.Text = "wants to trade with you!"
    descLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
    descLabel.TextSize = 11
    descLabel.Font = Enum.Font.GothamSemibold
    descLabel.TextXAlignment = Enum.TextXAlignment.Left
    descLabel.Parent = notif

    -- Buttons
    local acceptBtn = Instance.new("TextButton")
    acceptBtn.Size = UDim2.new(0, 120, 0, 28)
    acceptBtn.Position = UDim2.new(0, 8, 0, 84)
    acceptBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    acceptBtn.BorderSizePixel = 0
    acceptBtn.Text = "ACCEPT"
    acceptBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
    acceptBtn.TextSize = 12
    acceptBtn.Font = Enum.Font.GothamBold
    acceptBtn.Parent = notif
    createCorner(acceptBtn, 6)
    setupButtonEffects(acceptBtn)

    local declineBtn = Instance.new("TextButton")
    declineBtn.Size = UDim2.new(0, 120, 0, 28)
    declineBtn.Position = UDim2.new(0, 140, 0, 84)
    declineBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    declineBtn.BorderSizePixel = 0
    declineBtn.Text = "DECLINE"
    declineBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    declineBtn.TextSize = 12
    declineBtn.Font = Enum.Font.GothamBold
    declineBtn.Parent = notif
    createCorner(declineBtn, 6)
    createStroke(declineBtn, Color3.fromRGB(255, 255, 255), 1)
    setupButtonEffects(declineBtn)

    -- Slide in from right
    notif.Position = UDim2.new(1, 0, 0.5, -60)
    local tweenIn = TweenService:Create(notif, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Position = UDim2.new(1, -320, 0.5, -60)})
    tweenIn:Play()

    requestNotif = notif

    acceptBtn.MouseButton1Click:Connect(function()
        tradeAction:FireServer("acceptRequest", fromPlayer)
        notif:Destroy()
        requestNotif = nil
        pendingRequestFrom = nil
    end)

    declineBtn.MouseButton1Click:Connect(function()
        tradeAction:FireServer("declineRequest", fromPlayer)
        notif:Destroy()
        requestNotif = nil
        pendingRequestFrom = nil
    end)

    -- Auto-decline after 30 seconds
    task.delay(30, function()
        if notif and notif.Parent then
            tradeAction:FireServer("declineRequest", fromPlayer)
            notif:Destroy()
            requestNotif = nil
            pendingRequestFrom = nil
        end
    end)
end

-- ============================================
-- SHOW CONFIRM WINDOW (5s countdown)
-- ============================================
local function showConfirmWindow()
    if not screenGui then return end

    local existing = screenGui:FindFirstChild("TradeConfirmPopup")
    if existing then existing:Destroy() end

    inConfirmWindow = true
    confirmTimer = 5

    local popup = Instance.new("Frame")
    popup.Name = "TradeConfirmPopup"
    popup.Size = UDim2.new(0, 260, 0, 120)
    popup.Position = UDim2.new(0.5, -130, 0.5, -60)
    popup.BackgroundColor3 = Color3.fromRGB(16, 16, 16)
    popup.BorderSizePixel = 0
    popup.ZIndex = 700
    popup.Parent = screenGui
    createCorner(popup, 12)
    createStroke(popup, Color3.fromRGB(255, 255, 255), 2)

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, 0, 0, 30)
    titleLabel.Position = UDim2.new(0, 0, 0, 10)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "TRADE LOCKED IN!"
    titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleLabel.TextSize = 18
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.Parent = popup

    local timerLabel = Instance.new("TextLabel")
    timerLabel.Name = "TimerLabel"
    timerLabel.Size = UDim2.new(1, 0, 0, 30)
    timerLabel.Position = UDim2.new(0, 0, 0, 40)
    timerLabel.BackgroundTransparency = 1
    timerLabel.Text = "Completing in 5..."
    timerLabel.TextColor3 = Color3.fromRGB(255, 200, 50)
    timerLabel.TextSize = 16
    timerLabel.Font = Enum.Font.GothamBold
    timerLabel.Parent = popup

    local cancelBtn = Instance.new("TextButton")
    cancelBtn.Name = "CancelBtn"
    cancelBtn.Size = UDim2.new(0, 200, 0, 32)
    cancelBtn.Position = UDim2.new(0.5, -100, 0, 78)
    cancelBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    cancelBtn.BorderSizePixel = 0
    cancelBtn.Text = "CANCEL -- 5s"
    cancelBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    cancelBtn.TextSize = 12
    cancelBtn.Font = Enum.Font.GothamBold
    cancelBtn.Parent = popup
    createCorner(cancelBtn, 6)
    createStroke(cancelBtn, Color3.fromRGB(255, 255, 255), 1)
    setupButtonEffects(cancelBtn)

    cancelBtn.MouseButton1Click:Connect(function()
        tradeAction:FireServer("cancelTrade")
        inConfirmWindow = false
        popup:Destroy()
    end)

    -- Countdown
    task.spawn(function()
        for i = 4, 1, -1 do
            task.wait(1)
            if not popup or not popup.Parent then return end
            timerLabel.Text = "Completing in " .. i .. "..."
            cancelBtn.Text = "CANCEL -- " .. i .. "s"
        end
        task.wait(1)
        if popup and popup.Parent then
            popup:Destroy()
        end
        inConfirmWindow = false
    end)
end

-- ============================================
-- CREATE PET SLOT
-- ============================================
local function createPetSlot(parent, position, petData, isMySide, isFilled)
    local slot = Instance.new("Frame")
    slot.Size = UDim2.new(0, 80, 0, 80)
    slot.Position = position
    slot.BackgroundColor3 = Color3.fromRGB(22, 22, 22)
    slot.BorderSizePixel = 0
    slot.Parent = parent

    if isFilled and petData then
        local rarityColor = Config.RARITY_COLORS[petData.rarity] or Color3.fromRGB(80, 80, 80)
        createStroke(slot, rarityColor, 1.5)
        createCorner(slot, 6)

        local emojiLabel = Instance.new("TextLabel")
        emojiLabel.Size = UDim2.new(1, 0, 0, 30)
        emojiLabel.Position = UDim2.new(0, 0, 0, 2)
        emojiLabel.BackgroundTransparency = 1
        emojiLabel.Text = getDisplayEmoji(petData)
        emojiLabel.TextSize = 22
        emojiLabel.Font = Enum.Font.GothamBold
        emojiLabel.Parent = slot

        local nameLabel = Instance.new("TextLabel")
        nameLabel.Size = UDim2.new(1, -4, 0, 16)
        nameLabel.Position = UDim2.new(0, 2, 0, 32)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Text = petData.name
        nameLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
        nameLabel.TextSize = 9
        nameLabel.Font = Enum.Font.GothamBold
        nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
        nameLabel.Parent = slot

        local starLabel = Instance.new("TextLabel")
        starLabel.Size = UDim2.new(1, 0, 0, 14)
        starLabel.Position = UDim2.new(0, 0, 0, 48)
        starLabel.BackgroundTransparency = 1
        starLabel.Text = getStarString(petData.stars or 1)
        starLabel.TextColor3 = Color3.fromRGB(255, 200, 50)
        starLabel.TextSize = 9
        starLabel.Font = Enum.Font.GothamBold
        starLabel.Parent = slot

        local rarityLabel = Instance.new("TextLabel")
        rarityLabel.Size = UDim2.new(1, 0, 0, 14)
        rarityLabel.Position = UDim2.new(0, 0, 0, 62)
        rarityLabel.BackgroundTransparency = 1
        rarityLabel.Text = petData.rarity or ""
        rarityLabel.TextColor3 = rarityColor
        rarityLabel.TextSize = 8
        rarityLabel.Font = Enum.Font.GothamBold
        rarityLabel.Parent = slot

        -- Click to remove from offer (only on my side)
        if isMySide then
            local clickBtn = Instance.new("TextButton")
            clickBtn.Size = UDim2.new(1, 0, 1, 0)
            clickBtn.BackgroundTransparency = 1
            clickBtn.Text = ""
            clickBtn.ZIndex = 10
            clickBtn.Parent = slot

            clickBtn.MouseButton1Click:Connect(function()
                tradeAction:FireServer("removeOffer", petData.id)
            end)
        end
    else
        -- Empty slot with dashed border
        createCorner(slot, 6)
        local dashStroke = Instance.new("UIStroke")
        dashStroke.Color = Color3.fromRGB(80, 80, 80)
        dashStroke.Thickness = 1
        dashStroke.LineJoinMode = Enum.LineJoinMode.Round
        dashStroke.Parent = slot

        local plusLabel = Instance.new("TextLabel")
        plusLabel.Size = UDim2.new(1, 0, 1, 0)
        plusLabel.BackgroundTransparency = 1
        plusLabel.Text = "+"
        plusLabel.TextColor3 = Color3.fromRGB(100, 100, 100)
        plusLabel.TextSize = 24
        plusLabel.Font = Enum.Font.GothamBold
        plusLabel.Parent = slot

        -- Click empty slot on my side to open pet picker
        if isMySide then
            local clickBtn = Instance.new("TextButton")
            clickBtn.Size = UDim2.new(1, 0, 1, 0)
            clickBtn.BackgroundTransparency = 1
            clickBtn.Text = ""
            clickBtn.ZIndex = 10
            clickBtn.Parent = slot

            clickBtn.MouseButton1Click:Connect(function()
                openPetPicker()
            end)
        end
    end

    return slot
end

-- ============================================
-- PET PICKER POPUP
-- ============================================
function openPetPicker()
    if not screenGui then return end
    if inConfirmWindow then return end

    local existing = screenGui:FindFirstChild("PetPickerPopup")
    if existing then existing:Destroy() return end -- toggle

    local tradeable = getTradeablePets()
    if #tradeable == 0 then
        showNotification("NO PETS", "No tradeable pets available", Color3.fromRGB(200, 80, 80), 2)
        return
    end

    local popup = Instance.new("Frame")
    popup.Name = "PetPickerPopup"
    popup.Size = UDim2.new(0, 300, 0, 400)
    popup.Position = UDim2.new(0.5, -150, 0.5, -200)
    popup.BackgroundColor3 = Color3.fromRGB(16, 16, 16)
    popup.BorderSizePixel = 0
    popup.ZIndex = 800
    popup.Parent = screenGui
    createCorner(popup, 12)
    createStroke(popup, Color3.fromRGB(255, 255, 255), 1)

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, 0, 0, 30)
    titleLabel.Position = UDim2.new(0, 0, 0, 8)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "SELECT PET TO OFFER"
    titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleLabel.TextSize = 14
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.Parent = popup

    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 24, 0, 24)
    closeBtn.Position = UDim2.new(1, -30, 0, 6)
    closeBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    closeBtn.BorderSizePixel = 0
    closeBtn.Text = "X"
    closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeBtn.TextSize = 12
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.ZIndex = 801
    closeBtn.Parent = popup
    createCorner(closeBtn, 4)

    closeBtn.MouseButton1Click:Connect(function()
        popup:Destroy()
    end)

    local scrollFrame = Instance.new("ScrollingFrame")
    scrollFrame.Size = UDim2.new(1, -16, 1, -50)
    scrollFrame.Position = UDim2.new(0, 8, 0, 42)
    scrollFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
    scrollFrame.BorderSizePixel = 0
    scrollFrame.ScrollBarThickness = 3
    scrollFrame.ScrollBarImageColor3 = Color3.fromRGB(80, 80, 80)
    scrollFrame.Parent = popup
    createCorner(scrollFrame, 8)

    local gridLayout = Instance.new("UIGridLayout")
    gridLayout.CellSize = UDim2.new(0, 85, 0, 85)
    gridLayout.CellPadding = UDim2.new(0, 6, 0, 6)
    gridLayout.Parent = scrollFrame

    local padding = Instance.new("UIPadding")
    padding.PaddingTop = UDim.new(0, 6)
    padding.PaddingLeft = UDim.new(0, 6)
    padding.Parent = scrollFrame

    for _, pet in ipairs(tradeable) do
        local petCard = Instance.new("TextButton")
        petCard.Name = pet.name
        petCard.Size = UDim2.new(0, 85, 0, 85)
        petCard.BackgroundColor3 = Color3.fromRGB(22, 22, 22)
        petCard.BorderSizePixel = 0
        petCard.Text = ""
        petCard.Parent = scrollFrame
        createCorner(petCard, 6)
        local rarityColor = Config.RARITY_COLORS[pet.rarity] or Color3.fromRGB(80, 80, 80)
        createStroke(petCard, rarityColor, 1)
        setupButtonEffects(petCard)

        local emoji = Instance.new("TextLabel")
        emoji.Size = UDim2.new(1, 0, 0, 28)
        emoji.Position = UDim2.new(0, 0, 0, 2)
        emoji.BackgroundTransparency = 1
        emoji.Text = getDisplayEmoji(pet)
        emoji.TextSize = 20
        emoji.Font = Enum.Font.GothamBold
        emoji.Parent = petCard

        local name = Instance.new("TextLabel")
        name.Size = UDim2.new(1, -4, 0, 14)
        name.Position = UDim2.new(0, 2, 0, 30)
        name.BackgroundTransparency = 1
        name.Text = pet.name
        name.TextColor3 = Color3.fromRGB(220, 220, 220)
        name.TextSize = 8
        name.Font = Enum.Font.GothamBold
        name.TextTruncate = Enum.TextTruncate.AtEnd
        name.Parent = petCard

        local stars = Instance.new("TextLabel")
        stars.Size = UDim2.new(1, 0, 0, 12)
        stars.Position = UDim2.new(0, 0, 0, 44)
        stars.BackgroundTransparency = 1
        stars.Text = getStarString(pet.stars or 1)
        stars.TextColor3 = Color3.fromRGB(255, 200, 50)
        stars.TextSize = 8
        stars.Font = Enum.Font.GothamBold
        stars.Parent = petCard

        local rarity = Instance.new("TextLabel")
        rarity.Size = UDim2.new(1, 0, 0, 12)
        rarity.Position = UDim2.new(0, 0, 0, 58)
        rarity.BackgroundTransparency = 1
        rarity.Text = pet.rarity or ""
        rarity.TextColor3 = rarityColor
        rarity.TextSize = 8
        rarity.Font = Enum.Font.GothamBold
        rarity.Parent = petCard

        petCard.MouseButton1Click:Connect(function()
            tradeAction:FireServer("offerPet", pet.id)
            popup:Destroy()
        end)
    end

    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, gridLayout.AbsoluteContentSize.Y + 20)
    gridLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        scrollFrame.CanvasSize = UDim2.new(0, 0, 0, gridLayout.AbsoluteContentSize.Y + 20)
    end)
end

-- ============================================
-- BUILD ACTIVE TRADE UI
-- ============================================
local function buildActiveTradeUI()
    if not tradePanel then return end

    -- Clear existing content
    for _, child in ipairs(tradePanel:GetChildren()) do
        if child.Name ~= "CloseButton" and child.Name ~= "UICorner" and child.Name ~= "UIStroke" and child.Name ~= "TitleLabel" then
            child:Destroy()
        end
    end

    -- Update existing TitleLabel
    local titleLabel = tradePanel:FindFirstChild("TitleLabel")
    if titleLabel then
        titleLabel.Text = "TRADING WITH: " .. (tradePartner and tradePartner.Name or "?")
        titleLabel.TextSize = 14
    end

    -- Divider
    local divider = Instance.new("Frame")
    divider.Size = UDim2.new(0, 1, 1, -100)
    divider.Position = UDim2.new(0.5, 0, 0, 50)
    divider.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    divider.BorderSizePixel = 0
    divider.Parent = tradePanel

    -- YOUR OFFER label
    local yourLabel = Instance.new("TextLabel")
    yourLabel.Size = UDim2.new(0.5, -10, 0, 20)
    yourLabel.Position = UDim2.new(0, 8, 0, 50)
    yourLabel.BackgroundTransparency = 1
    yourLabel.Text = "YOUR OFFER"
    yourLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
    yourLabel.TextSize = 11
    yourLabel.Font = Enum.Font.GothamBold
    yourLabel.Parent = tradePanel

    -- THEIR OFFER label
    local theirLabel = Instance.new("TextLabel")
    theirLabel.Size = UDim2.new(0.5, -10, 0, 20)
    theirLabel.Position = UDim2.new(0.5, 8, 0, 50)
    theirLabel.BackgroundTransparency = 1
    theirLabel.Text = "THEIR OFFER"
    theirLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
    theirLabel.TextSize = 11
    theirLabel.Font = Enum.Font.GothamBold
    theirLabel.Parent = tradePanel

    -- Pet slots - 3x3 grid on each side
    local slotSize = 80
    local slotPadding = 6
    local startX = 8
    local startY = 74

    -- My offer slots
    for row = 0, 2 do
        for col = 0, 2 do
            local idx = row * 3 + col + 1
            local petData = myOfferedPets[idx]
            local pos = UDim2.new(0, startX + col * (slotSize + slotPadding), 0, startY + row * (slotSize + slotPadding))
            createPetSlot(tradePanel, pos, petData, true, petData ~= nil)
        end
    end

    -- Their offer slots
    local theirStartX = 210
    for row = 0, 2 do
        for col = 0, 2 do
            local idx = row * 3 + col + 1
            local petData = theirOfferedPets[idx]
            local pos = UDim2.new(0, theirStartX + col * (slotSize + slotPadding), 0, startY + row * (slotSize + slotPadding))
            createPetSlot(tradePanel, pos, petData, false, petData ~= nil)
        end
    end

    -- Status label
    local statusLabel = Instance.new("TextLabel")
    statusLabel.Name = "StatusLabel"
    statusLabel.Size = UDim2.new(1, -16, 0, 20)
    statusLabel.Position = UDim2.new(0, 8, 1, -80)
    statusLabel.BackgroundTransparency = 1
    if myAccepted and theirAccepted then
        statusLabel.Text = "Both accepted -- confirming..."
        statusLabel.TextColor3 = Color3.fromRGB(255, 200, 50)
    elseif myAccepted then
        statusLabel.Text = "You accepted -- waiting for partner..."
        statusLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
    elseif theirAccepted then
        statusLabel.Text = "Partner accepted -- your turn?"
        statusLabel.TextColor3 = Color3.fromRGB(255, 200, 50)
    else
        statusLabel.Text = "Add pets and accept when ready"
        statusLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
    end
    statusLabel.TextSize = 11
    statusLabel.Font = Enum.Font.GothamBold
    statusLabel.Parent = tradePanel

    -- ACCEPT button
    local acceptBtn = Instance.new("TextButton")
    acceptBtn.Size = UDim2.new(0.5, -14, 0, 32)
    acceptBtn.Position = UDim2.new(0, 8, 1, -52)
    acceptBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    acceptBtn.BorderSizePixel = 0
    acceptBtn.Text = myAccepted and "ACCEPTED" or "ACCEPT TRADE"
    acceptBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
    acceptBtn.TextSize = 12
    acceptBtn.Font = Enum.Font.GothamBold
    acceptBtn.Parent = tradePanel
    createCorner(acceptBtn, 6)
    if not myAccepted and not inConfirmWindow then
        setupButtonEffects(acceptBtn)
        acceptBtn.MouseButton1Click:Connect(function()
            tradeAction:FireServer("acceptTrade")
        end)
    end

    -- CANCEL button
    local cancelBtn = Instance.new("TextButton")
    cancelBtn.Size = UDim2.new(0.5, -14, 0, 32)
    cancelBtn.Position = UDim2.new(0.5, 6, 1, -52)
    cancelBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    cancelBtn.BorderSizePixel = 0
    cancelBtn.Text = "CANCEL TRADE"
    cancelBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    cancelBtn.TextSize = 12
    cancelBtn.Font = Enum.Font.GothamBold
    cancelBtn.Parent = tradePanel
    createCorner(cancelBtn, 6)
    createStroke(cancelBtn, Color3.fromRGB(255, 255, 255), 1)
    setupButtonEffects(cancelBtn)

    cancelBtn.MouseButton1Click:Connect(function()
        tradeAction:FireServer("cancelTrade")
    end)
end

-- ============================================
-- BUILD PLAYER LIST UI (main trade panel)
-- ============================================
local function buildPlayerListUI()
    if not tradePanel then return end

    -- Clear existing content
    for _, child in ipairs(tradePanel:GetChildren()) do
        if child.Name ~= "CloseButton" and child.Name ~= "UICorner" and child.Name ~= "UIStroke" and child.Name ~= "TitleLabel" then
            child:Destroy()
        end
    end

    -- Update existing TitleLabel
    local titleLabel = tradePanel:FindFirstChild("TitleLabel")
    if titleLabel then
        titleLabel.Text = "TRADE"
    end

    -- Search bar
    local searchBox = Instance.new("TextBox")
    searchBox.Name = "SearchBox"
    searchBox.Size = UDim2.new(1, -90, 0, 32)
    searchBox.Position = UDim2.new(0, 12, 0, 46)
    searchBox.BackgroundColor3 = Color3.fromRGB(22, 22, 22)
    searchBox.BorderSizePixel = 0
    searchBox.PlaceholderText = "Search player..."
    searchBox.Text = ""
    searchBox.TextColor3 = Color3.fromRGB(220, 220, 220)
    searchBox.PlaceholderColor3 = Color3.fromRGB(100, 100, 100)
    searchBox.TextSize = 13
    searchBox.Font = Enum.Font.GothamBold
    searchBox.ClearTextOnFocus = false
    searchBox.Parent = tradePanel
    createCorner(searchBox, 6)
    createStroke(searchBox, Color3.fromRGB(80, 80, 80), 1)

    local findBtn = Instance.new("TextButton")
    findBtn.Size = UDim2.new(0, 60, 0, 32)
    findBtn.Position = UDim2.new(1, -74, 0, 46)
    findBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    findBtn.BorderSizePixel = 0
    findBtn.Text = "FIND"
    findBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
    findBtn.TextSize = 11
    findBtn.Font = Enum.Font.GothamBold
    findBtn.Parent = tradePanel
    createCorner(findBtn, 6)
    setupButtonEffects(findBtn)

    -- Online players label
    local onlineLabel = Instance.new("TextLabel")
    onlineLabel.Size = UDim2.new(1, -24, 0, 20)
    onlineLabel.Position = UDim2.new(0, 12, 0, 86)
    onlineLabel.BackgroundTransparency = 1
    onlineLabel.Text = "ONLINE PLAYERS:"
    onlineLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
    onlineLabel.TextSize = 11
    onlineLabel.Font = Enum.Font.GothamBold
    onlineLabel.TextXAlignment = Enum.TextXAlignment.Left
    onlineLabel.Parent = tradePanel

    -- Player list scroll frame
    local scrollFrame = Instance.new("ScrollingFrame")
    scrollFrame.Name = "PlayerList"
    scrollFrame.Size = UDim2.new(1, -24, 1, -130)
    scrollFrame.Position = UDim2.new(0, 12, 0, 110)
    scrollFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
    scrollFrame.BorderSizePixel = 0
    scrollFrame.ScrollBarThickness = 3
    scrollFrame.ScrollBarImageColor3 = Color3.fromRGB(80, 80, 80)
    scrollFrame.Parent = tradePanel
    createCorner(scrollFrame, 8)

    local listLayout = Instance.new("UIListLayout")
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Padding = UDim.new(0, 4)
    listLayout.Parent = scrollFrame

    local listPadding = Instance.new("UIPadding")
    listPadding.PaddingTop = UDim.new(0, 4)
    listPadding.PaddingLeft = UDim.new(0, 4)
    listPadding.PaddingRight = UDim.new(0, 4)
    listPadding.Parent = scrollFrame

    -- Populate player list
    local function populatePlayers(filter)
        for _, child in ipairs(scrollFrame:GetChildren()) do
            if child:IsA("Frame") then
                child:Destroy()
            end
        end

        local allPlayers = Players:GetPlayers()
        local count = 0

        for i, otherPlayer in ipairs(allPlayers) do
            if otherPlayer == player then continue end

            if filter and filter ~= "" then
                if not string.find(string.lower(otherPlayer.Name), string.lower(filter)) then
                    continue
                end
            end

            count = count + 1

            local row = Instance.new("Frame")
            row.Name = otherPlayer.Name
            row.Size = UDim2.new(1, 0, 0, 50)
            row.BackgroundColor3 = Color3.fromRGB(22, 22, 22)
            row.BorderSizePixel = 0
            row.LayoutOrder = i
            row.Parent = scrollFrame
            createCorner(row, 6)
            createStroke(row, Color3.fromRGB(60, 60, 60), 1)

            -- Avatar
            local avatar = Instance.new("ImageLabel")
            avatar.Size = UDim2.new(0, 36, 0, 36)
            avatar.Position = UDim2.new(0, 6, 0.5, -18)
            avatar.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
            avatar.BorderSizePixel = 0
            avatar.Parent = row
            createCorner(avatar, 4)

            pcall(function()
                local thumb = Players:GetUserThumbnailAsync(otherPlayer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48)
                avatar.Image = thumb
            end)

            -- Name
            local nameLabel = Instance.new("TextLabel")
            nameLabel.Size = UDim2.new(1, -120, 0, 20)
            nameLabel.Position = UDim2.new(0, 50, 0.5, -10)
            nameLabel.BackgroundTransparency = 1
            nameLabel.Text = otherPlayer.Name
            nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
            nameLabel.TextSize = 13
            nameLabel.Font = Enum.Font.GothamBold
            nameLabel.TextXAlignment = Enum.TextXAlignment.Left
            nameLabel.Parent = row

            -- Trade button
            local tradeBtn = Instance.new("TextButton")
            tradeBtn.Size = UDim2.new(0, 60, 0, 28)
            tradeBtn.Position = UDim2.new(1, -70, 0.5, -14)
            tradeBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            tradeBtn.BorderSizePixel = 0
            tradeBtn.Text = "TRADE"
            tradeBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
            tradeBtn.TextSize = 11
            tradeBtn.Font = Enum.Font.GothamBold
            tradeBtn.Parent = row
            createCorner(tradeBtn, 4)
            setupButtonEffects(tradeBtn)

            tradeBtn.MouseButton1Click:Connect(function()
                tradeAction:FireServer("sendRequest", otherPlayer)
                showNotification("REQUEST SENT", "Trade request sent to " .. otherPlayer.Name, Color3.fromRGB(255, 255, 255), 3)
            end)
        end

        if count == 0 then
            local emptyLabel = Instance.new("TextLabel")
            emptyLabel.Size = UDim2.new(1, 0, 0, 40)
            emptyLabel.BackgroundTransparency = 1
            emptyLabel.Text = filter and "No players found" or "No other players online"
            emptyLabel.TextColor3 = Color3.fromRGB(100, 100, 100)
            emptyLabel.TextSize = 13
            emptyLabel.Font = Enum.Font.GothamSemibold
            emptyLabel.Parent = scrollFrame
        end

        scrollFrame.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 20)
    end

    populatePlayers("")

    -- Search functionality
    findBtn.MouseButton1Click:Connect(function()
        populatePlayers(searchBox.Text)
    end)

    searchBox.FocusLost:Connect(function(enterPressed)
        if enterPressed then
            populatePlayers(searchBox.Text)
        end
    end)

    -- Refresh when players join/leave
    Players.PlayerAdded:Connect(function()
        task.wait(1)
        if not isInTrade then
            populatePlayers(searchBox.Text)
        end
    end)
    Players.PlayerRemoving:Connect(function()
        task.wait(1)
        if not isInTrade then
            populatePlayers(searchBox.Text)
        end
    end)
end

-- ============================================
-- INITIALIZE TRADE PANEL
-- ============================================
local function initTradePanel()
    tradePanel = screenGui:FindFirstChild("TradePanel")
    if not tradePanel then
        warn("[TradeClient] TradePanel not found in ScreenGui")
        return
    end

    -- Close button handler
    local closeBtn = tradePanel:FindFirstChild("CloseButton")
    if closeBtn then
        closeBtn.MouseButton1Click:Connect(function()
            if isInTrade then
                tradeAction:FireServer("cancelTrade")
            end
            if pendingRequestFrom then
                tradeAction:FireServer("declineRequest", pendingRequestFrom)
                pendingRequestFrom = nil
            end
            -- Remove request notification
            local reqNotif = screenGui:FindFirstChild("TradeRequestNotif")
            if reqNotif then reqNotif:Destroy() end
            PanelManager.closeActivePanel()
        end)
    end

    -- Register with PanelManager
    PanelManager.registerPanel("TradePanel", tradePanel)

    -- Build initial player list
    buildPlayerListUI()
end

-- ============================================
-- HANDLE TRADE SYNC EVENTS
-- ============================================
tradeSync.OnClientEvent:Connect(function(action, ...)
    local args = {...}

    if action == "tradeRequest" then
        -- Incoming trade request
        local fromPlayer = args[1]
        if fromPlayer then
            showTradeRequest(fromPlayer)
        end

    elseif action == "tradeRequestSent" then
        -- Our request was sent (acknowledged)
        local targetPlayer = args[1]

    elseif action == "tradeRequestCancelled" then
        -- Our request was cancelled

    elseif action == "tradeRequestDeclined" then
        -- Request was declined
        showNotification("TRADE DECLINED", "Your trade request was declined", Color3.fromRGB(200, 80, 80), 3)

    elseif action == "tradeRequestExpired" then
        -- Request expired
        showNotification("TRADE EXPIRED", "Trade request expired", Color3.fromRGB(150, 150, 150), 2)

    elseif action == "tradeStarted" then
        -- Trade was accepted, open active trade UI
        tradePartner = args[1]
        isInTrade = true
        myOfferedPets = {}
        theirOfferedPets = {}
        myAccepted = false
        theirAccepted = false
        inConfirmWindow = false

        -- Remove request notification if present
        local reqNotif = screenGui:FindFirstChild("TradeRequestNotif")
        if reqNotif then reqNotif:Destroy() end

        buildActiveTradeUI()

    elseif action == "tradeUpdated" then
        -- Trade offers updated
        local myOffer = args[1] or {}
        local theirOffer = args[2] or {}
        local iAccepted = args[3] or false
        local partnerAccepted = args[4] or false

        myOfferedPets = myOffer
        theirOfferedPets = theirOffer
        myAccepted = iAccepted
        theirAccepted = partnerAccepted

        if isInTrade then
            buildActiveTradeUI()
        end

    elseif action == "tradeConfirmWindow" then
        -- 5 second confirm window started
        showConfirmWindow()

    elseif action == "tradeSuccess" then
        -- Trade completed successfully
        local receivedPets = args[1] or {}
        isInTrade = false
        tradePartner = nil
        myOfferedPets = {}
        theirOfferedPets = {}
        myAccepted = false
        theirAccepted = false
        inConfirmWindow = false

        -- Remove confirm popup
        local confirmPopup = screenGui:FindFirstChild("TradeConfirmPopup")
        if confirmPopup then confirmPopup:Destroy() end

        -- Show success
        local petNames = {}
        for _, pet in ipairs(receivedPets) do
            table.insert(petNames, pet.name)
        end
        local msg = #petNames > 0 and table.concat(petNames, ", ") or "Trade complete!"
        showNotification("TRADE SUCCESS!", "Received: " .. msg, Color3.fromRGB(100, 200, 100), 4)

        -- Rebuild player list
        buildPlayerListUI()

    elseif action == "tradeFailed" then
        -- Trade failed
        local errorMsg = args[1] or "Trade failed"
        isInTrade = false
        tradePartner = nil
        myOfferedPets = {}
        theirOfferedPets = {}
        myAccepted = false
        theirAccepted = false
        inConfirmWindow = false

        local confirmPopup = screenGui:FindFirstChild("TradeConfirmPopup")
        if confirmPopup then confirmPopup:Destroy() end

        showNotification("TRADE FAILED", errorMsg, Color3.fromRGB(200, 80, 80), 3)
        buildPlayerListUI()

    elseif action == "tradeCancelled" then
        -- Trade was cancelled
        isInTrade = false
        tradePartner = nil
        myOfferedPets = {}
        theirOfferedPets = {}
        myAccepted = false
        theirAccepted = false
        inConfirmWindow = false

        local confirmPopup = screenGui:FindFirstChild("TradeConfirmPopup")
        if confirmPopup then confirmPopup:Destroy() end

        showNotification("TRADE CANCELLED", "The trade was cancelled", Color3.fromRGB(150, 150, 150), 2)
        buildPlayerListUI()
    end
end)

-- ============================================
-- INIT
-- ============================================
task.spawn(function()
    task.wait(2)
    initTradePanel()
    print("[TradeClient] Loaded")
end)