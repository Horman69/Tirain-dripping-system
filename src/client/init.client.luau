--[[
    ═══════════════════════════════════════════════════════════════
    КЛИЕНТСКАЯ ЧАСТЬ ИГРЫ-КОПАЛКИ
    ═══════════════════════════════════════════════════════════════
    
    Этот скрипт обрабатывает:
    • Клики мыши по terrain
    • Отправку данных на сервер через RemoteEvents
    • Получение результатов копания
    • Базовый интерфейс (в будущем)
    
    Автор: Rus_ik000
    Дата: 2025
--]]

-- Основные сервисы Roblox
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

print("🖱️ Запуск клиентской части игры-копалки...")

-- Получаем локального игрока
local localPlayer = Players.LocalPlayer

-- ═══════════════════════════════════════════════════════════════
-- ИМПОРТ МОДУЛЕЙ
-- ═══════════════════════════════════════════════════════════════

-- Ждем загрузки модулей
local RemoteEvents = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("RemoteEvents"))
local MasterConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("MasterConfig"))

-- Встроенная система отслеживания глубины
local DepthTracker = {}
local screenGui = nil
local depthLabel = nil
local biomeLabel = nil

function DepthTracker.initialize()
    print("DepthTracker: Инициализация встроенной системы...")
    
    -- Создаем GUI
    screenGui = Instance.new("ScreenGui")
    screenGui.Name = "DepthTracker"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = localPlayer:WaitForChild("PlayerGui")
    
    -- Создаем фрейм
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 250, 0, 80)
    frame.Position = UDim2.new(0, 10, 0, 10)
    frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    frame.BackgroundTransparency = 0.3
    frame.BorderSizePixel = 2
    frame.BorderColor3 = Color3.fromRGB(255, 255, 255)
    frame.Parent = screenGui
    
    -- Заголовок
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0.3, 0)
    title.BackgroundTransparency = 1
    title.Text = "🏃‍♂️ ГЛУБИНА"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.TextScaled = true
    title.Font = Enum.Font.SourceSansBold
    title.Parent = frame
    
    -- Лейбл глубины
    depthLabel = Instance.new("TextLabel")
    depthLabel.Size = UDim2.new(1, 0, 0.35, 0)
    depthLabel.Position = UDim2.new(0, 0, 0.3, 0)
    depthLabel.BackgroundTransparency = 1
    depthLabel.Text = "Y: 0 (Поверхность)"
    depthLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
    depthLabel.TextScaled = true
    depthLabel.Font = Enum.Font.SourceSans
    depthLabel.Parent = frame
    
    -- Лейбл биома
    biomeLabel = Instance.new("TextLabel")
    biomeLabel.Size = UDim2.new(1, 0, 0.35, 0)
    biomeLabel.Position = UDim2.new(0, 0, 0.65, 0)
    biomeLabel.BackgroundTransparency = 1
    biomeLabel.Text = "🌍 Биом: Поверхность"
    biomeLabel.TextColor3 = Color3.fromRGB(255, 255, 0)
    biomeLabel.TextScaled = true
    biomeLabel.Font = Enum.Font.SourceSans
    biomeLabel.Parent = frame
    
    -- Запускаем обновление каждые 0.1 секунды
    game:GetService("RunService").Heartbeat:Connect(function()
        if localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart") then
            local y = localPlayer.Character.HumanoidRootPart.Position.Y
            
            -- Обновляем текст глубины и биома
            if y > 0 then
                depthLabel.Text = string.format("Y: %.1f (Поверхность)", y)
                depthLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
                biomeLabel.Text = "🌍 Биом: Поверхность"
            else
                local depth = math.abs(y)
                depthLabel.Text = string.format("Y: %.1f (Глубина %.1f)", y, depth)
                
                if depth < 30 then
                    depthLabel.TextColor3 = Color3.fromRGB(255, 255, 0)
                elseif depth < 100 then
                    depthLabel.TextColor3 = Color3.fromRGB(255, 165, 0)
                else
                    depthLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
                end
                
                local layerIndex = MasterConfig.getLayerIndex(y)
                if layerIndex > 0 then
                    biomeLabel.Text = "🌍 Биом: Подземный слой " .. layerIndex
                else
                    biomeLabel.Text = "🌍 Биом: Поверхность"
                end
            end
        end
    end)
    
    print("✅ DepthTracker инициализирован")
end

print("✅ Клиентские модули загружены")

-- ═══════════════════════════════════════════════════════════════
-- ОБРАБОТКА КЛИКОВ МЫШИ
-- ═══════════════════════════════════════════════════════════════

-- Получаем mouse игрока
local mouse = localPlayer:GetMouse()

-- Получаем события для копания
local digEvent = RemoteEvents.getDigTerrainEvent()
local resultEvent = RemoteEvents.getDigResultEvent()

--[[
    Обрабатывает клик мыши игрока
--]]
local function onMouseClick()
    -- Проверяем что у нас есть валидная цель
    if not mouse.Hit then
        return
    end
    
    local hitPosition = mouse.Hit.Position
    local target = mouse.Target
    
    -- Проверяем что клик был по terrain
    if target and target == Workspace.Terrain then
        print("🖱️ Клик по terrain в позиции: " .. tostring(hitPosition))
        
        -- Отправляем запрос на копание серверу
        digEvent:FireServer(hitPosition)
    else
        print("🖱️ Клик не по terrain")
    end
end

-- Подключаем обработчик клика
mouse.Button1Down:Connect(onMouseClick)

-- ═══════════════════════════════════════════════════════════════
-- ОБРАБОТКА РЕЗУЛЬТАТОВ КОПАНИЯ
-- ═══════════════════════════════════════════════════════════════

--[[
    Обрабатывает результат копания с сервера
--]]
resultEvent.OnClientEvent:Connect(function(resultData)
    if resultData and resultData.success then
        print("✅ Копание успешно! Позиция: " .. tostring(resultData.position))
    else
        print("❌ Копание не удалось")
    end
end)

-- ═══════════════════════════════════════════════════════════════
-- ДОПОЛНИТЕЛЬНЫЕ НАСТРОЙКИ
-- ═══════════════════════════════════════════════════════════════

-- Настраиваем курсор для лучшего UX
mouse.Icon = "rbxasset://textures/ArrowCursor.png"

-- Инициализируем систему отслеживания глубины
DepthTracker.initialize()

-- Сообщаем о готовности
print("🎮 Клиентская часть готова!")
print("📝 Кликайте по terrain для копания ям")
print("📊 Система отслеживания глубины активирована")