-- =====================================================
-- PARTE 4 - BOTÃO FECHAR / CLOSE BUTTON
-- Gerencia o fechamento do popup, limpeza de efeitos
-- e restauração da UI
-- Manages popup closing, effect cleanup
-- and UI restoration
-- =====================================================

local CloseSystem = {}

local TweenService = game:GetService("TweenService")

-- Função para criar o botão de fechar e configurar o fechamento
-- popup: Frame do popup
-- popupShadow: Frame da sombra
-- Config: referência ao StardustConfig
-- PanelManager: referência ao PanelManager
-- cleanupCallbacks: tabela com funções de limpeza dos outros módulos
--   - overlayClose: função para fechar o overlay
--   - explosionCleanup: função para limpar explosão
--   - petCleanup: função para limpar pet
--   - animDisconnect: função para desconectar animação do ovo
-- Retorna: o botão de fechar (X) e o botão OK
function CloseSystem.setup(popup, popupShadow, Config, PanelManager, cleanupCallbacks)
	local isClosing = false

	local function closePopup()
		if isClosing then return end
		isClosing = true

		-- Desconecta animações do ovo
		if cleanupCallbacks.animDisconnect then
			cleanupCallbacks.animDisconnect()
		end

		-- Cancela a thread de animação principal (se ainda estiver rodando)
		if cleanupCallbacks.cancelAnimToken then
			cleanupCallbacks.cancelAnimToken()
		end

		-- Limpa efeitos da explosão
		if cleanupCallbacks.explosionCleanup then
			cleanupCallbacks.explosionCleanup()
		end

		-- Limpa efeitos do pet
		if cleanupCallbacks.petCleanup then
			cleanupCallbacks.petCleanup()
		end

		-- Fecha o overlay
		if cleanupCallbacks.overlayClose then
			cleanupCallbacks.overlayClose()
		end

		-- Fade out do popup
		local popupStroke = popup:FindFirstChildOfClass("UIStroke")
		if popupShadow and popupShadow.Parent then
			TweenService:Create(popupShadow, Config.TWEEN_INFO_FAST, {BackgroundTransparency = 1}):Play()
		end
		if popupStroke then
			TweenService:Create(popupStroke, Config.TWEEN_INFO_FAST, {Transparency = 1}):Play()
		end
		local tween = TweenService:Create(popup, Config.TWEEN_INFO_FAST, {BackgroundTransparency = 1})
		tween:Play()
		tween.Completed:Connect(function()
			if popupShadow and popupShadow.Parent then popupShadow:Destroy() end
			if popup and popup.Parent then popup:Destroy() end
		end)
	end

	-- Safety: ensure overlay is closed when popup is destroyed
	popup.Destroying:Connect(function()
		if cleanupCallbacks.overlayClose then
			cleanupCallbacks.overlayClose()
		end
	end)

	-- ===== BOTÃO X (canto superior direito) =====
	local closeBtn = PanelManager.createCloseButton(popup)
	closeBtn.Visible = false -- Só aparece após o pet ser revelado
	closeBtn.MouseButton1Click:Connect(closePopup)

	-- ===== BOTÃO OK (parte inferior) =====
	local okBtn = Instance.new("TextButton")
	okBtn.Name = "OkButton"
	okBtn.Size = UDim2.new(1, -32, 0, 44)
	okBtn.Position = UDim2.new(0, 16, 1, -56)
	okBtn.BackgroundColor3 = Config.COLORS.BUTTON_BG
	okBtn.BorderSizePixel = 0
	okBtn.Text = "Incrível!"
	okBtn.TextColor3 = Config.COLORS.TITLE_TEXT
	okBtn.TextSize = 16
	okBtn.Font = Enum.Font.GothamBold
	okBtn.ZIndex = 10
	okBtn.BackgroundTransparency = 1
	okBtn.Parent = popup
	PanelManager.createCorner(okBtn, 0.2)
	PanelManager.setupButtonEffects(okBtn)
	okBtn.MouseButton1Click:Connect(closePopup)

	return {
		closeBtn = closeBtn,
		okBtn = okBtn,
		closePopup = closePopup,
	}
end

-- Função para mostrar os botões (após revelação do pet)
function CloseSystem.showButtons(refs)
	if not refs then return end

	-- Mostra o botão X com scale bounce
	refs.closeBtn.Visible = true
	refs.closeBtn.Size = UDim2.new(0, 0, 0, 0)
	TweenService:Create(refs.closeBtn, TweenInfo.new(0.4, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out), {
		Size = UDim2.new(0, 28, 0, 28)
	}):Play()

	-- Bounce-in do botão OK
	refs.okBtn.Size = UDim2.new(1, -32, 0, 0)
	TweenService:Create(refs.okBtn, TweenInfo.new(0.5, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out), {
		Size = UDim2.new(1, -32, 0, 44),
		BackgroundTransparency = 0
	}):Play()

	-- Som de confirmação
	local confirmSound = Instance.new("Sound")
	confirmSound.Name = "ConfirmSound"
	confirmSound.SoundId = "rbxassetid://6895079853"
	confirmSound.Volume = 0.3
	confirmSound.PlaybackSpeed = 1.3
	confirmSound.Parent = refs.okBtn
	confirmSound:Play()
	confirmSound.Ended:Connect(function()
		confirmSound.Parent = nil
	end)
end

return CloseSystem