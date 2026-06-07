-- TutorialPanel - Tutorial de Onboarding para novos jogadores
-- Mostra um tutorial passo-a-passo quando o jogador entra pela primeira vez
-- NÃO BLOQUEIA O JOGO - jogador pode jogar normalmente

local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local TutorialPanel = {}

-- ===== CONFIGURAÇÃO DO TUTORIAL (5 PASSOS) =====
local TUTORIAL_STEPS = {
    {
        id = "activate_autoclick",
        title = "Ative o AutoClick!",
        description = "Clique no botão AutoClick na barra inferior!",
        iconText = "AUTO",
        targetElement = "AutoClickBtn", -- Botão na barra inferior
        completionAction = "autoClickActivated",
        completionCount = 1,
        progressText = "Ative o AutoClick"
    },
    {
        id = "buy_shop",
        title = "Abra a Loja!",
        description = "Abra a loja e compre um item!",
        iconText = "SHOP",
        targetElement = "ShopBtn",
        completionAction = "buyItem",
        completionCount = 1,
        progressText = "Compre qualquer item"
    },
    {
        id = "buy_egg",
        title = "Compre um Ovo!",
        description = "Compre seu primeiro ovo na aba Eggs!",
        iconText = "EGG",
        targetElement = "EggsBtn",
        completionAction = "hatchEgg",
        completionCount = 1,
        progressText = "Choque um ovo"
    },
    {
        id = "equip_pet",
        title = "Equipe seu Pet!",
        description = "Equipe seu pet na aba Pets!",
        iconText = "PET",
        targetElement = "PetsBtn",
        completionAction = "equipPet",
        completionCount = 1,
        progressText = "Equipe um pet"
    },
    {
        id = "complete",
        title = "Você está pronto!",
        description = "O AutoClick está funcionando! Ganhe Stardust automaticamente!",
        iconText = "DONE",
        targetElement = nil,
        completionAction = "manual",
        completionCount = 1,
        progressText = "Clique para começar!"
    }
}

-- ===== ESTADO DO TUTORIAL =====
local tutorialState = {
    currentStep = 1,
    isActive = false,
    tutorialFrame = nil,
    arrowFrame = nil,
    progressCount = 0, -- Contador de progresso do passo atual
    onComplete = nil,
    completeTimer = nil, -- Timer para auto-completar etapa final
    isAdvancing = false -- Debounce para prevenir avanco multiplo
}

-- ===== REFERÊNCIAS =====
local screenGui = nil
local buttonContainer = nil
local starElement = nil

-- ===== FUNÇÕES AUXILIARES =====
local function createCorner(parent, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius or 12)
    corner.Parent = parent
    return corner
end

local function createStroke(parent, color, thickness)
    local stroke = Instance.new("UIStroke")
    stroke.Color = color or Color3.fromRGB(255, 200, 50)
    stroke.Thickness = thickness or 2
    stroke.Parent = parent
    return stroke
end

-- ===== CRIAR SETA ANIMADA =====
local function createArrow(targetPosition)
    -- Remover seta anterior
    if tutorialState.arrowFrame then
        tutorialState.arrowFrame:Destroy()
        tutorialState.arrowFrame = nil
    end
    
    if not targetPosition then return end
    
    local arrow = Instance.new("Frame")
    arrow.Name = "TutorialArrow"
    arrow.Size = UDim2.new(0, 30, 0, 50)
    arrow.BackgroundTransparency = 1
    arrow.ZIndex = 999
    arrow.Parent = screenGui
    
    -- Linha vertical da seta
    local arrowLine = Instance.new("Frame")
    arrowLine.Name = "ArrowLine"
    arrowLine.Size = UDim2.new(0, 3, 0, 30)
    arrowLine.Position = UDim2.new(0.5, -1.5, 0, 0)
    arrowLine.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    arrowLine.BorderSizePixel = 0
    arrowLine.Parent = arrow
    
    -- Ponta da seta (triângulo usando Frames)
    local arrowHead = Instance.new("Frame")
    arrowHead.Name = "ArrowHead"
    arrowHead.Size = UDim2.new(0, 12, 0, 12)
    arrowHead.Position = UDim2.new(0.5, -6, 0, 28)
    arrowHead.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    arrowHead.BorderSizePixel = 0
    arrowHead.Rotation = 45
    arrowHead.Parent = arrow
    
    -- Posicionar seta acima do alvo
    arrow.Position = UDim2.new(0, targetPosition.X - 15, 0, targetPosition.Y - 70)
    
    -- Animação de "bounce" (sobe e desce)
    local originalY = targetPosition.Y - 70
    local bounceTween = TweenService:Create(arrow, TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
        Position = UDim2.new(0, targetPosition.X - 15, 0, originalY - 15)
    })
    bounceTween:Play()
    
    tutorialState.arrowFrame = arrow
    return arrow
end

-- ===== CRIAR FRAME DO TUTORIAL (CANTO INFERIOR) =====
local function createTutorialFrame()
    -- Frame principal no canto inferior esquerdo
    local frame = Instance.new("Frame")
    frame.Name = "TutorialFrame"
    frame.Size = UDim2.new(0, 340, 0, 170)
    frame.Position = UDim2.new(0, 20, 1, -280) -- Canto inferior esquerdo, mais alto para nao sobrepor botoes
    frame.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
    frame.BorderSizePixel = 0
    frame.ZIndex = 998
    frame.Parent = screenGui
    
    createCorner(frame, 12)
    createStroke(frame, Color3.fromRGB(255, 255, 255), 1)
    
    -- Step counter (top right)
    local stepCounter = Instance.new("TextLabel")
    stepCounter.Name = "StepCounter"
    stepCounter.Size = UDim2.new(0, 70, 0, 16)
    stepCounter.Position = UDim2.new(1, -80, 0, 8)
    stepCounter.BackgroundTransparency = 1
    stepCounter.Text = "STEP 1 / 5"
    stepCounter.TextColor3 = Color3.fromRGB(120, 120, 120)
    stepCounter.TextSize = 11
    stepCounter.Font = Enum.Font.GothamBold
    stepCounter.Parent = frame
    
    -- Icon square (white square instead of emoji)
    local iconSquare = Instance.new("Frame")
    iconSquare.Name = "IconSquare"
    iconSquare.Size = UDim2.new(0, 40, 0, 40)
    iconSquare.Position = UDim2.new(0, 15, 0, 15)
    iconSquare.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    iconSquare.BorderSizePixel = 0
    iconSquare.Parent = frame
    createCorner(iconSquare, 4)
    
    -- Icon text label (AUTO, SHOP, EGG, PET, DONE)
    local iconLabel = Instance.new("TextLabel")
    iconLabel.Name = "IconLabel"
    iconLabel.Size = UDim2.new(0, 40, 0, 40)
    iconLabel.Position = UDim2.new(0, 15, 0, 15)
    iconLabel.BackgroundTransparency = 1
    iconLabel.Text = "AUTO"
    iconLabel.TextColor3 = Color3.fromRGB(10, 10, 10)
    iconLabel.TextSize = 10
    iconLabel.Font = Enum.Font.GothamBold
    iconLabel.Parent = frame
    
    -- Título
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "Title"
    titleLabel.Size = UDim2.new(1, -100, 0, 28)
    titleLabel.Position = UDim2.new(0, 70, 0, 15)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "Clique na Estrela!"
    titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleLabel.TextSize = 18
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Parent = frame
    
    -- Descrição
    local descLabel = Instance.new("TextLabel")
    descLabel.Name = "Description"
    descLabel.Size = UDim2.new(1, -30, 0, 45)
    descLabel.Position = UDim2.new(0, 15, 0, 60)
    descLabel.BackgroundTransparency = 1
    descLabel.Text = "Clique na estrela para ganhar Stardust!"
    descLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    descLabel.TextSize = 14
    descLabel.Font = Enum.Font.GothamSemibold
    descLabel.TextWrapped = true
    descLabel.TextXAlignment = Enum.TextXAlignment.Left
    descLabel.TextYAlignment = Enum.TextYAlignment.Top
    descLabel.Parent = frame
    
    -- Progresso
    local progressLabel = Instance.new("TextLabel")
    progressLabel.Name = "Progress"
    progressLabel.Size = UDim2.new(1, -30, 0, 20)
    progressLabel.Position = UDim2.new(0, 15, 0, 115)
    progressLabel.BackgroundTransparency = 1
    progressLabel.Text = "Cliques: 0/5"
    progressLabel.TextColor3 = Color3.fromRGB(150, 200, 150)
    progressLabel.TextSize = 14
    progressLabel.Font = Enum.Font.GothamSemibold
    progressLabel.TextXAlignment = Enum.TextXAlignment.Left
    progressLabel.Parent = frame
    
    -- Botão Pular Tutorial
    local skipBtn = Instance.new("TextButton")
    skipBtn.Name = "SkipButton"
    skipBtn.Size = UDim2.new(0, 120, 0, 32)
    skipBtn.Position = UDim2.new(1, -130, 0, 130)
    skipBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    skipBtn.BorderSizePixel = 0
    skipBtn.Text = "Pular"
    skipBtn.TextColor3 = Color3.fromRGB(180, 180, 180)
    skipBtn.TextSize = 14
    skipBtn.Font = Enum.Font.GothamBold
    skipBtn.ZIndex = 999
    skipBtn.Parent = frame
    createCorner(skipBtn, 8)
    createStroke(skipBtn, Color3.fromRGB(100, 100, 100), 1)
    
    skipBtn.MouseButton1Click:Connect(function()
        TutorialPanel.skip()
    end)
    
    return frame
end

-- ===== OBTER POSIÇÃO DO ELEMENTO ALVO =====
local function getTargetPosition(targetElement)
    if not targetElement then return nil end
    
    -- Se for um botão, encontrar no container
    if buttonContainer then
        local btn = buttonContainer:FindFirstChild(targetElement)
        if btn then
            local btnPos = btn.AbsolutePosition
            local btnSize = btn.AbsoluteSize
            return Vector2.new(btnPos.X + btnSize.X/2, btnPos.Y + btnSize.Y/2)
        end
    end
    
    -- Posição padrão (centro inferior da tela)
    if screenGui then
        return Vector2.new(screenGui.AbsoluteSize.X/2, screenGui.AbsoluteSize.Y - 100)
    end
    
    return nil
end

-- ===== ATUALIZAR PASSO DO TUTORIAL =====
local function updateStep(stepIndex)
    if stepIndex < 1 or stepIndex > #TUTORIAL_STEPS then return end
    
    -- Cancelar timer anterior se existir
    if tutorialState.completeTimer then
        task.cancel(tutorialState.completeTimer)
        tutorialState.completeTimer = nil
    end
    
    tutorialState.currentStep = stepIndex
    tutorialState.progressCount = 0 -- Resetar contador de progresso
    local step = TUTORIAL_STEPS[stepIndex]
    
    if not tutorialState.tutorialFrame then return end
    
    -- Atualizar conteúdo
    local iconLabel = tutorialState.tutorialFrame:FindFirstChild("IconLabel")
    local title = tutorialState.tutorialFrame:FindFirstChild("Title")
    local desc = tutorialState.tutorialFrame:FindFirstChild("Description")
    local progress = tutorialState.tutorialFrame:FindFirstChild("Progress")
    local stepCounter = tutorialState.tutorialFrame:FindFirstChild("StepCounter")
    
    if iconLabel then iconLabel.Text = step.iconText end
    if title then title.Text = step.title end
    if desc then desc.Text = step.description end
    if stepCounter then stepCounter.Text = "STEP " .. stepIndex .. " / " .. #TUTORIAL_STEPS end
    
    -- Atualizar texto de progresso
    if progress then
        if step.id == "complete" then
            progress.Text = "Clique para começar!"
        else
            progress.Text = step.progressText:gsub("{current}", "0"):gsub("{target}", tostring(step.completionCount))
        end
    end
    
    -- Criar seta apontando para o elemento
    local targetPos = getTargetPosition(step.targetElement)
    createArrow(targetPos)
    
    -- Animação de entrada
    tutorialState.tutorialFrame.Position = UDim2.new(0, 20, 1, -220) -- Começa mais baixo
    local tweenIn = TweenService:Create(tutorialState.tutorialFrame, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Position = UDim2.new(0, 20, 1, -280)
    })
    tweenIn:Play()
    
    -- Auto-completar após 4 segundos na etapa final
    if step.id == "complete" then
        tutorialState.completeTimer = task.delay(4, function()
            if tutorialState.isActive and tutorialState.currentStep == stepIndex then
                TutorialPanel.complete()
            end
        end)
    end
end

-- ===== INICIAR TUTORIAL =====
function TutorialPanel.start(gui, btnContainer, starRef, onCompleteCallback)
    print("[TutorialPanel] start() called")
    
    -- Destruir qualquer frame existente antes de criar um novo (evita duplicatas)
    if tutorialState.tutorialFrame then
        tutorialState.tutorialFrame:Destroy()
        tutorialState.tutorialFrame = nil
    end
    if tutorialState.arrowFrame then
        tutorialState.arrowFrame:Destroy()
        tutorialState.arrowFrame = nil
    end
    
    -- Cancelar timer anterior se existir
    if tutorialState.completeTimer then
        task.cancel(tutorialState.completeTimer)
        tutorialState.completeTimer = nil
    end
    
    screenGui = gui
    buttonContainer = btnContainer
    starElement = starRef
    tutorialState.onComplete = onCompleteCallback
    tutorialState.isActive = true
    tutorialState.currentStep = 1
    tutorialState.progressCount = 0
    tutorialState.isAdvancing = false -- Resetar debounce
    
    -- Criar frame do tutorial (sem overlay - não bloqueia o jogo)
    tutorialState.tutorialFrame = createTutorialFrame()
    
    -- Mostrar primeiro passo
    updateStep(1)
    
    print("[Tutorial] Started tutorial for new player")
end

-- ===== ATUALIZAR PROGRESSO DO PASSO ATUAL =====
function TutorialPanel.updateProgress(actionType, count)
    print("[TutorialPanel] updateProgress called - actionType:", actionType, "count:", count, "isActive:", tutorialState.isActive, "currentStep:", tutorialState.currentStep)
    
    -- DEBOUNCE: Ignorar chamadas enquanto está avançando
    if tutorialState.isAdvancing then
        print("[TutorialPanel] Ignoring call - already advancing")
        return
    end
    
    if not tutorialState.isActive then return end
    
    local step = TUTORIAL_STEPS[tutorialState.currentStep]
    if not step then return end
    
    print("[TutorialPanel] Current step completionAction:", step.completionAction, "matches:", step.completionAction == actionType)
    
    -- Verificar se a ação corresponde ao passo atual
    if step.completionAction == actionType then
        tutorialState.progressCount = tutorialState.progressCount + (count or 1)
        
        -- Atualizar texto de progresso
        local progress = tutorialState.tutorialFrame and tutorialState.tutorialFrame:FindFirstChild("Progress")
        if progress then
            progress.Text = step.progressText:gsub("{current}", tostring(tutorialState.progressCount)):gsub("{target}", tostring(step.completionCount))
        end
        
        -- Verificar se completou o passo
        if tutorialState.progressCount >= step.completionCount then
            if tutorialState.currentStep < #TUTORIAL_STEPS then
                -- DEBOUNCE: Bloquear novas chamadas enquanto avança
                tutorialState.isAdvancing = true
                
                -- Avançar para próximo passo
                task.wait(0.5) -- Pequena pausa para feedback visual
                updateStep(tutorialState.currentStep + 1)
                
                -- DEBOUNCE: Liberar após avançar
                task.wait(0.3) -- Tempo extra para garantir que a UI atualizou
                tutorialState.isAdvancing = false
            else
                -- Tutorial completo
                TutorialPanel.complete()
            end
        end
    end
end

-- ===== COMPLETAR TUTORIAL =====
function TutorialPanel.complete()
    tutorialState.isActive = false
    
    -- Cancelar timer se existir
    if tutorialState.completeTimer then
        task.cancel(tutorialState.completeTimer)
        tutorialState.completeTimer = nil
    end
    
    -- Remover seta
    if tutorialState.arrowFrame then
        tutorialState.arrowFrame:Destroy()
        tutorialState.arrowFrame = nil
    end
    
    -- Remover TODOS os frames de tutorial (incluindo órfãos)
    if screenGui then
        for _, child in ipairs(screenGui:GetChildren()) do
            if child.Name == "TutorialFrame" or child.Name == "TutorialArrow" then
                child:Destroy()
            end
        end
    end
    
    -- Limpar referência
    tutorialState.tutorialFrame = nil
    
    -- Callback de conclusão
    if tutorialState.onComplete then
        tutorialState.onComplete()
    end
    
    print("[Tutorial] Tutorial completed!")
end

-- ===== VERIFICAR SE TUTORIAL ESTÁ ATIVO =====
function TutorialPanel.isActive()
    return tutorialState.isActive
end

-- ===== PULAR TUTORIAL =====
function TutorialPanel.skip()
    print("[Tutorial] Tutorial skipped by player")
    TutorialPanel.complete()
end

-- ===== OBTER PASSO ATUAL =====
function TutorialPanel.getCurrentStep()
    return tutorialState.currentStep
end

return TutorialPanel