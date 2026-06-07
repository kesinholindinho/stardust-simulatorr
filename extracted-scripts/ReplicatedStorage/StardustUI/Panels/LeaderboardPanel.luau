local LeaderboardPanel = {}

local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("StardustConfig"))
local PanelManager = require(ReplicatedStorage:WaitForChild("StardustUI"):WaitForChild("PanelManager"))

local panel = nil

-- ============================================
-- CREATE PANEL
-- ============================================
function LeaderboardPanel.create(screenGui)
    panel = screenGui:FindFirstChild("LeaderboardPanel")
    if not panel then return end
    
    local COLORS = Config.COLORS
    
    local leaderboardTitle = Instance.new("TextLabel")
    leaderboardTitle.Name = "TitleLabel"
    leaderboardTitle.Size = UDim2.new(1, 0, 0, 40)
    leaderboardTitle.AnchorPoint = Vector2.new(0.5, 0)
    leaderboardTitle.Position = UDim2.new(0.5, 0, 0, 16)
    leaderboardTitle.BackgroundTransparency = 1
    leaderboardTitle.Text = "🏆 Leaderboard"
    leaderboardTitle.TextColor3 = COLORS.TITLE_TEXT
    leaderboardTitle.TextSize = 18
    leaderboardTitle.Font = Enum.Font.GothamBold
    leaderboardTitle.TextXAlignment = Enum.TextXAlignment.Center
    leaderboardTitle.Parent = panel
    
    local leaderboardContent = Instance.new("ScrollingFrame")
    leaderboardContent.Name = "Content"
    leaderboardContent.Size = UDim2.new(1, -16, 1, -56)
    leaderboardContent.Position = UDim2.new(0, 8, 0, 52)
    leaderboardContent.BackgroundTransparency = 1
    leaderboardContent.ScrollBarThickness = 3
    leaderboardContent.ScrollBarImageColor3 = Color3.fromRGB(80, 80, 80)
    leaderboardContent.Parent = panel
    
    local leaderboardPadding = Instance.new("UIPadding")
    leaderboardPadding.PaddingTop = UDim.new(0, 10)
    leaderboardPadding.PaddingBottom = UDim.new(0, 10)
    leaderboardPadding.PaddingLeft = UDim.new(0, 10)
    leaderboardPadding.PaddingRight = UDim.new(0, 10)
    leaderboardPadding.Parent = leaderboardContent
    
    local leaderboardList = Instance.new("UIListLayout")
    leaderboardList.Padding = UDim.new(0, 10)
    leaderboardList.Parent = leaderboardContent
    
    leaderboardList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        leaderboardContent.CanvasSize = UDim2.new(0, 0, 0, leaderboardList.AbsoluteContentSize.Y + 20)
    end)
    
    PanelManager.registerPanel("LeaderboardPanel", panel)
end

-- ============================================
-- UPDATE LEADERBOARD
-- ============================================
function LeaderboardPanel.update(screenGui, players, localPlayer)
    local panel = screenGui:FindFirstChild("LeaderboardPanel")
    if not panel then return end
    
    local content = panel:FindFirstChild("Content")
    if not content then return end
    
    -- Clear existing rows
    for _, child in ipairs(content:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end
    
    local COLORS = Config.COLORS
    
    -- Sort players by stardust
    table.sort(players, function(a, b) return a.stardust > b.stardust end)
    
    for rank, playerData in ipairs(players) do
        local row = Instance.new("Frame")
        row.Name = "Player" .. rank
        row.Size = UDim2.new(1, 0, 0, 32)
        row.BackgroundColor3 = rank % 2 == 0 and Color3.fromRGB(32, 32, 32) or Color3.fromRGB(25, 25, 25)
        row.BorderSizePixel = 0
        row.Parent = content
        PanelManager.createCorner(row, 0.15)
        
        if playerData.isPlayer then
            local highlightStroke = Instance.new("UIStroke")
            highlightStroke.Color = Color3.fromRGB(120, 120, 120)
            highlightStroke.Thickness = 2
            highlightStroke.Parent = row
        end
        
        local rankLabel = Instance.new("TextLabel")
        rankLabel.Size = UDim2.new(0, 28, 1, 0)
        rankLabel.BackgroundTransparency = 1
        if rank == 1 then rankLabel.Text = "⭐"
        elseif rank == 2 then rankLabel.Text = "🌙"
        elseif rank == 3 then rankLabel.Text = "✨"
        else rankLabel.Text = tostring(rank) end
        rankLabel.TextColor3 = COLORS.TITLE_TEXT
        rankLabel.TextSize = rank <= 3 and 16 or 12
        rankLabel.Font = Enum.Font.GothamBold
        rankLabel.Parent = row
        
        local nameLabel = Instance.new("TextLabel")
        nameLabel.Size = UDim2.new(1, -80, 1, 0)
        nameLabel.Position = UDim2.new(0, 28, 0, 0)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Text = playerData.name
        nameLabel.TextColor3 = playerData.isPlayer and COLORS.TITLE_TEXT or COLORS.DESC_TEXT
        nameLabel.TextSize = 12
        nameLabel.Font = Enum.Font.GothamSemibold
        nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
        nameLabel.TextXAlignment = Enum.TextXAlignment.Left
        nameLabel.Parent = row
        
        local stardustLabel = Instance.new("TextLabel")
        stardustLabel.Size = UDim2.new(0, 60, 1, 0)
        stardustLabel.Position = UDim2.new(1, -65, 0, 0)
        stardustLabel.BackgroundTransparency = 1
        stardustLabel.Text = PanelManager.abbreviateNumber(playerData.stardust)
        stardustLabel.TextColor3 = COLORS.TITLE_TEXT
        stardustLabel.TextSize = 11
        stardustLabel.Font = Enum.Font.GothamBold
        stardustLabel.Parent = row
    end
end

return LeaderboardPanel