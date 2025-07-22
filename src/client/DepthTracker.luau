--[[
    DepthTracker.luau
    
    Модуль для отслеживания и отображения глубины игрока
    в системе горизонтальных слоев биомов
    
    Автор: Rus_ik000
    Дата: 2025
--]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- Зависимости
local DigConfig = require(game.ReplicatedStorage.Shared.DigConfig)

-- Модуль
local DepthTracker = {}

-- Локальные переменные
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Создание GUI элементов
local screenGui = nil
local depthLabel = nil
local biomeLabel = nil

-- Настройки отображения
local UPDATE_FREQUENCY = 10 -- Обновления в секунду

--[[
    Создает GUI элементы для отображения глубины
--]]
local function createDepthGui()
    -- Создаем главный контейнер
    screenGui = Instance.new("ScreenGui")
    screenGui.Name = "DepthTracker"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = playerGui
    
    -- Создаем фрейм для информации
    local infoFrame = Instance.new("Frame")
    infoFrame.Name = "InfoFrame"
    infoFrame.Size = UDim2.new(0, 250, 0, 80)
    infoFrame.Position = UDim2.new(0, 10, 0, 10)
    infoFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    infoFrame.BackgroundTransparency = 0.3
    infoFrame.BorderSizePixel = 2
    infoFrame.BorderColor3 = Color3.fromRGB(255, 255, 255)
    infoFrame.Parent = screenGui
    
    -- Создаем заголовок
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "TitleLabel"
    titleLabel.Size = UDim2.new(1, 0, 0.3, 0)
    titleLabel.Position = UDim2.new(0, 0, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "🏃‍♂️ ГЛУБИНА"
    titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleLabel.TextScaled = true
    titleLabel.Font = Enum.Font.SourceSansBold
    titleLabel.Parent = infoFrame
    
    -- Создаем лейбл для глубины
    depthLabel = Instance.new("TextLabel")
    depthLabel.Name = "DepthLabel"
    depthLabel.Size = UDim2.new(1, 0, 0.35, 0)
    depthLabel.Position = UDim2.new(0, 0, 0.3, 0)
    depthLabel.BackgroundTransparency = 1
    depthLabel.Text = "Y: 0 (Поверхность)"
    depthLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
    depthLabel.TextScaled = true
    depthLabel.Font = Enum.Font.SourceSans
    depthLabel.Parent = infoFrame
    
    -- Создаем лейбл для биома
    biomeLabel = Instance.new("TextLabel")
    biomeLabel.Name = "BiomeLabel"
    biomeLabel.Size = UDim2.new(1, 0, 0.35, 0)
    biomeLabel.Position = UDim2.new(0, 0, 0.65, 0)
    biomeLabel.BackgroundTransparency = 1
    biomeLabel.Text = "🌍 Биом: Поверхность"
    biomeLabel.TextColor3 = Color3.fromRGB(255, 255, 0)
    biomeLabel.TextScaled = true
    biomeLabel.Font = Enum.Font.SourceSans
    biomeLabel.Parent = infoFrame
    
    print("✅ DepthTracker GUI создан")
end

--[[
    Обновляет отображение глубины и биома
--]]
local function updateDepthDisplay()
    if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
        return
    end
    
    local character = player.Character
    local humanoidRootPart = character.HumanoidRootPart
    local currentY = humanoidRootPart.Position.Y
    
    -- Определяем текст глубины
    local depthText = ""
    local depthColor = Color3.fromRGB(0, 255, 0) -- Зеленый по умолчанию
    
    if currentY > 0 then
        depthText = string.format("Y: %.1f (Поверхность)", currentY)
        depthColor = Color3.fromRGB(0, 255, 0) -- Зеленый для поверхности
    else
        local depth = math.abs(currentY)
        depthText = string.format("Y: %.1f (Глубина %.1f)", currentY, depth)
        
        -- Цвет зависит от глубины
        if depth < 30 then
            depthColor = Color3.fromRGB(255, 255, 0) -- Желтый для малой глубины
        elseif depth < 100 then
            depthColor = Color3.fromRGB(255, 165, 0) -- Оранжевый для средней глубины
        else
            depthColor = Color3.fromRGB(255, 0, 0) -- Красный для большой глубины
        end
    end
    
    -- Определяем биом
    local biomeText = "🌍 Биом: "
    local layerIndex = DigConfig.getLayerIndex(currentY)
    
    if currentY > 0 then
        biomeText = biomeText .. "Поверхность"
    else
        biomeText = biomeText .. "Слой " .. layerIndex
    end
    
    -- Обновляем GUI
    if depthLabel then
        depthLabel.Text = depthText
        depthLabel.TextColor3 = depthColor
    end
    
    if biomeLabel then
        biomeLabel.Text = biomeText
    end
end

--[[
    Инициализирует систему отслеживания глубины
--]]
function DepthTracker.initialize()
    print("DepthTracker: Инициализация...")
    
    -- Создаем GUI
    createDepthGui()
    
    -- Запускаем цикл обновления
    local connection = nil
    connection = RunService.Heartbeat:Connect(function()
        local dt = RunService.Heartbeat:Wait()
        
        -- Ограничиваем частоту обновлений
        if tick() % (1/UPDATE_FREQUENCY) < dt then
            updateDepthDisplay()
        end
    end)
    
    -- Очистка при выходе игрока
    Players.PlayerRemoving:Connect(function(leavingPlayer)
        if leavingPlayer == player and connection then
            connection:Disconnect()
        end
    end)
    
    print("✅ DepthTracker инициализирован")
end

--[[
    Уничтожает GUI элементы
--]]
function DepthTracker.cleanup()
    if screenGui then
        screenGui:Destroy()
        screenGui = nil
        depthLabel = nil
        biomeLabel = nil
    end
    
    print("DepthTracker: GUI очищен")
end

-- Возвращаем модуль
return DepthTracker
