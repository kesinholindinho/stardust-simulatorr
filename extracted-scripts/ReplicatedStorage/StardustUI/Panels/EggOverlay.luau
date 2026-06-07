-- =====================================================
-- OVERLAY FOSCO / DIMMED OVERLAY
-- Oculta as GUIs, escurece o fundo da tela inteira
-- Hides GUIs, dims the full screen background
-- =====================================================

local OverlaySystem = {}

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Guarda as GUIs ocultas para restaurar depois
-- Cada entrada: { instance = gui, bgTransparency = number }
local hiddenGuis = {}

-- Cria o frame de overlay (fundo fosco tela inteira)
local overlay = Instance.new("Frame")
overlay.Name = "EggDimOverlay"
overlay.Size = UDim2.new(1, 0, 1, 0)
overlay.Position = UDim2.new(0, 0, 0, 0)
overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
overlay.BackgroundTransparency = 1
overlay.ZIndex = 250
overlay.BorderSizePixel = 0

-- Função para ABRIR o overlay
function OverlaySystem.open(screenGui)
	-- If already open, close first to restore previous GUIs
	if overlay.Parent then
		OverlaySystem.close()
		task.wait(0.1)
	end
	table.clear(hiddenGuis)

	-- Oculta outras ScreenGuis
	for _, gui in ipairs(playerGui:GetChildren()) do
		if gui:IsA("ScreenGui") and gui ~= screenGui then
			if gui.Enabled then
				gui.Enabled = false
				table.insert(hiddenGuis, { instance = gui })
			end
		end
	end

	-- Oculta todos os painéis dentro da ScreenGui principal (HUD, barras, etc.)
	-- Salva BackgroundTransparency para restaurar depois (evita conflito com tweens do PanelManager)
	for _, child in ipairs(screenGui:GetChildren()) do
		if child:IsA("GuiObject") and child.Visible then
			table.insert(hiddenGuis, { instance = child, bgTransparency = child.BackgroundTransparency })
			child.Visible = false
		end
	end

	-- Coloca o overlay na ScreenGui (após esconder os painéis, então não será escondido)
	overlay.Parent = screenGui

	-- Fade-in suave do overlay (escurece a tela inteira)
	local tweenInfo = TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local tween = TweenService:Create(overlay, tweenInfo, {BackgroundTransparency = 0.55})
	tween:Play()
end

-- Função para FECHAR o overlay
function OverlaySystem.close()
	if not overlay.Parent then return end
	
	-- Fade out overlay
	local tweenInfo = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	local tween = TweenService:Create(overlay, tweenInfo, {BackgroundTransparency = 1})
	tween:Play()
	
	-- Restore saved GUIs
	for _, entry in ipairs(hiddenGuis) do
		if entry.instance and entry.instance.Parent then
			if entry.instance:IsA("ScreenGui") then
				entry.instance.Enabled = true
			elseif entry.instance:IsA("GuiObject") then
				entry.instance.Visible = true
				if entry.bgTransparency ~= nil then
					entry.instance.BackgroundTransparency = entry.bgTransparency
				end
			end
		end
	end
	
	-- ALSO restore any ScreenGui that is currently disabled (safety net)
	for _, gui in ipairs(playerGui:GetChildren()) do
		if gui:IsA("ScreenGui") and not gui.Enabled then
			gui.Enabled = true
		end
	end
	
	table.clear(hiddenGuis)
	
	tween.Completed:Connect(function()
		if overlay.Parent then overlay.Parent = nil end
	end)
	
	task.delay(0.35, function()
		if overlay.Parent then overlay.Parent = nil end
	end)
end

return OverlaySystem