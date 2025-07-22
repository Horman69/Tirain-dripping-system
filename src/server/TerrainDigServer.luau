--[[
    ═══════════════════════════════════════════════════════════════
    СЕРВЕРНАЯ ЛОГИКА КОПАНИЯ ТЕРРЕЙНА
    ═══════════════════════════════════════════════════════════════
    
    Этот модуль содержит основную логику для:
    • Обработки кликов по террейну
    • Создания ям в terrain
    • Генерации новых слоев биомов
    • Управления terrain через Roblox API
    
    ВАЖНЫЕ ПРИНЦИПЫ:
    • Используем FillRegion с resolution=1 для качества
    • Генерируем 3 слоя под игроком для безопасности  
    • Случайные биомы из BiomeConfig
    • Обработка ошибок и валидация
    
    Автор: Rus_ik000
    Дата: 2025
--]]

local TerrainDigServer = {}

-- ═══════════════════════════════════════════════════════════════
-- ИМПОРТЫ И СЕРВИСЫ
-- ═══════════════════════════════════════════════════════════════

-- Основные сервисы Roblox
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- Импортируем наши конфиги
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MasterConfig = require(ReplicatedStorage.Shared.MasterConfig)
local RemoteEvents = require(ReplicatedStorage.Shared.RemoteEvents)

-- Ссылка на terrain объект
local terrain = Workspace.Terrain

-- ═══════════════════════════════════════════════════════════════
-- ЛОКАЛЬНЫЕ ПЕРЕМЕННЫЕ
-- ═══════════════════════════════════════════════════════════════

-- Кэш последних операций копания (предотвращает спам)
local lastDigTimes = {} -- [playerId] = tick()

-- Кэш сгенерированных горизонтальных слоев  
local generatedLayers = {} -- [layerIndex] = {biome, timestamp}

-- Отслеживание самого глубокого игрока
local deepestPlayerY = 1000 -- Начинаем с большого положительного числа
local lastDepthCheck = 0

-- Счетчик активных операций с terrain
local activeOperations = 0

-- ═══════════════════════════════════════════════════════════════
-- ОСНОВНЫЕ ФУНКЦИИ КОПАНИЯ
-- ═══════════════════════════════════════════════════════════════

--[[
    Обрабатывает клик игрока по террейну и создает яму
    
    @param player Player - игрок, который кликнул
    @param hitPosition Vector3 - позиция клика в мире
    @return boolean - успешность операции
--]]
function TerrainDigServer.processDigClick(player, hitPosition)
    -- Проверяем ограничения и валидность
    if not TerrainDigServer.validateDigRequest(player, hitPosition) then
        return false
    end
    
    -- Обновляем время последнего копания
    lastDigTimes[player.UserId] = tick()
    
    -- Создаем яму в указанной позиции
    local success = TerrainDigServer.createHole(hitPosition)
    
    if success then
        print("TerrainDigServer: Игрок " .. player.Name .. " успешно выкопал яму в позиции " .. tostring(hitPosition))
        
        -- Обеспечиваем генерацию горизонтальных слоев после копания
        ensureLayersExist()
        
        -- Получаем биом текущего слоя для отчета
        local currentLayerIndex = MasterConfig.getLayerIndex(hitPosition.Y)
        local currentBiome = "поверхность"
        
        if currentLayerIndex > 0 then
            currentBiome = generatedLayers[currentLayerIndex] and generatedLayers[currentLayerIndex].biome or "неизвестно"
        end
        
        print("🌍 Игрок в биоме:", currentBiome, "слой:", currentLayerIndex)
        
        return true
    else
        warn("TerrainDigServer: Не удалось создать яму для игрока " .. player.Name)
        return false
    end
end

--[[
    Создает яму (пустоту) в указанной позиции террейна
    
    @param position Vector3 - центральная позиция ямы
    @return boolean - успешность создания ямы
--]]
function TerrainDigServer.createHole(position)
    -- Проверяем лимит одновременных операций
    if activeOperations >= MasterConfig.PERFORMANCE.TERRAIN_OPERATIONS.MAX_CONCURRENT then
        warn("TerrainDigServer: Достигнут лимит одновременных операций с terrain")
        return false
    end
    
    activeOperations = activeOperations + 1
    
    local success = pcall(function()
        local holeConfig = MasterConfig.DIGGING.HOLE_DIMENSIONS
        
        if holeConfig.SHAPE == "sphere" then
            -- 🌑 СФЕРИЧЕСКАЯ ЯМА - используем FillBall для круглых ям
            local radius = holeConfig.RADIUS
            terrain:FillBall(
                position,
                radius,
                MasterConfig.WORLD.TERRAIN_API.AIR_MATERIAL
            )
            
            -- Отладочный маркер для сферы
            if MasterConfig.TECHNICAL.DEBUG.ENABLE_DEBUG_MODE then
                local sphereSize = Vector3.new(radius * 2, radius * 2, radius * 2)
                TerrainDigServer.createDebugMarker(
                    position, 
                    sphereSize, 
                    MasterConfig.TECHNICAL.DEBUG.VISUAL_MARKERS.COLORS.HOLE,
                    "SPHERE_HOLE"
                )
            end
            
        else
            -- 🟦 КУБИЧЕСКАЯ ЯМА - используем FillRegion для квадратных ям
            local holeSize = MasterConfig.getHoleSizeVector()
            local region = MasterConfig.createRegion(position, holeSize)
            
            terrain:FillRegion(
                region, 
                MasterConfig.WORLD.TERRAIN_API.RESOLUTION, 
                MasterConfig.WORLD.TERRAIN_API.AIR_MATERIAL
            )
            
            -- Отладочный маркер для куба
            if MasterConfig.TECHNICAL.DEBUG.ENABLE_DEBUG_MODE then
                TerrainDigServer.createDebugMarker(
                    position, 
                    holeSize, 
                    MasterConfig.TECHNICAL.DEBUG.VISUAL_MARKERS.COLORS.HOLE,
                    "CUBE_HOLE"
                )
            end
        end
    end)
    
    activeOperations = activeOperations - 1
    
    if not success then
        warn("TerrainDigServer: Ошибка при создании ямы в позиции " .. tostring(position))
    end
    
    return success
end

-- Функция отслеживания самого глубокого игрока
function updateDeepestPlayer()
    local currentTime = tick()
    if currentTime - lastDepthCheck < 2 then return end -- Проверяем раз в 2 секунды
    
    lastDepthCheck = currentTime
    local newDeepest = 1000 -- Начинаем с большого положительного числа
    
    -- Проходим по всем игрокам
    for _, player in pairs(Players:GetPlayers()) do
        if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local playerY = player.Character.HumanoidRootPart.Position.Y
            if playerY < newDeepest then
                newDeepest = playerY
            end
        end
    end
    
    -- Обновляем только если нашли игроков и позиция действительно глубже
    if newDeepest < 1000 and newDeepest < deepestPlayerY then
        deepestPlayerY = newDeepest
        print("🔄 Самый глубокий игрок на Y:", deepestPlayerY)
    end
end

-- Функция генерации горизонтального слоя
function generateHorizontalLayer(layerIndex)
    if generatedLayers[layerIndex] then
        return -- Слой уже сгенерирован
    end
    
    -- Получаем случайный биом
    local biome = MasterConfig.getRandomUndergroundBiome()
    local layerY = MasterConfig.getLayerY(layerIndex)
    
    -- Создаем регион для горизонтального слоя
    local region = MasterConfig.createHorizontalLayerRegion(layerIndex)
    
    -- Заполняем слой материалом биома
    workspace.Terrain:FillRegion(region, 4, biome.material)
    
    -- Сохраняем в кэш
    generatedLayers[layerIndex] = {
        biome = biome.name,
        timestamp = tick(),
        y = layerY
    }
    
    print("🏗️ Сгенерирован горизонтальный слой", layerIndex, "биом:", biome.name, "Y:", layerY)
end

-- Функция проверки и генерации нужных слоев
function ensureLayersExist()
    updateDeepestPlayer()
    
    -- Вычисляем какие слои должны существовать
    local bufferDepth = MasterConfig.WORLD.LAYER_SYSTEM.PREVIEW_DISTANCE
    local deepestLayerNeeded = MasterConfig.getLayerIndex(deepestPlayerY - bufferDepth)
    
    -- Генерируем все слои от 1 до нужного
    for layerIndex = 1, deepestLayerNeeded do
        generateHorizontalLayer(layerIndex)
    end
end

--[[
    Генерирует новые слои биомов под указанной позицией
    УСТАРЕВШАЯ ФУНКЦИЯ - заменена на горизонтальные слои
    
    @param abovePosition Vector3 - позиция над которой генерировать слои
    @param playerId number - ID игрока для кэширования
--]]
function TerrainDigServer.generateLayersBelow(abovePosition, playerId)
    -- НОВАЯ СИСТЕМА: генерируем горизонтальные слои вместо точечной генерации
    ensureLayersExist()
    
    -- Возвращаем информацию о сгенерированных слоях в текущей области
    local layerIndex = MasterConfig.getLayerIndex(abovePosition.Y)
    return generatedLayers[layerIndex] and generatedLayers[layerIndex].biome or "неизвестно"
end

--[[
    Генерирует один слой конкретного биома
    
    @param centerPosition Vector3 - центральная позиция слоя
    @param biome table - конфигурация биома из BiomeConfig
    @param playerId number - ID игрока  
    @param layerIndex number - индекс слоя
--]]
function TerrainDigServer.generateLayer(centerPosition, biome, playerId, layerIndex)
    -- Проверяем лимит операций
    if activeOperations >= MasterConfig.PERFORMANCE.TERRAIN_OPERATIONS.MAX_CONCURRENT then
        warn("TerrainDigServer: Пропускаем генерацию слоя из-за лимита операций")
        return
    end
    
    activeOperations = activeOperations + 1
    
    local success = pcall(function()
        -- Создаем Region3 для слоя
        local layerSize = MasterConfig.getGenerationAreaVector()
        local region = MasterConfig.createRegion(centerPosition, layerSize)
        
        -- Заполняем регион материалом биома
        terrain:FillRegion(
            region,
            MasterConfig.WORLD.TERRAIN_API.RESOLUTION,
            biome.material
        )
        
        -- Сохраняем информацию о сгенерированном слое в новой системе (сейчас не используется)
        -- Информация хранится в generatedLayers
        
        -- Отладочный маркер
        if MasterConfig.TECHNICAL.DEBUG.ENABLE_DEBUG_MODE then
            TerrainDigServer.createDebugMarker(
                centerPosition,
                layerSize,
                MasterConfig.TECHNICAL.DEBUG.VISUAL_MARKERS.COLORS.LAYER,
                "LAYER_" .. biome.displayName
            )
        end
        
        print("TerrainDigServer: Сгенерирован слой " .. biome.displayName .. " в позиции " .. tostring(centerPosition))
    end)
    
    activeOperations = activeOperations - 1
    
    if not success then
        warn("TerrainDigServer: Ошибка при генерации слоя " .. biome.displayName)
    end
end

-- ═══════════════════════════════════════════════════════════════
-- ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ
-- ═══════════════════════════════════════════════════════════════

--[[
    Валидирует запрос на копание от игрока
    
    @param player Player - игрок
    @param position Vector3 - позиция копания
    @return boolean - валидность запроса
--]]
function TerrainDigServer.validateDigRequest(player, position)
    -- Проверяем что игрок существует
    if not player or not player.Character then
        warn("TerrainDigServer: Игрок не найден или не заспавнен")
        return false
    end
    
    -- Проверяем кулдаун копания
    local lastDigTime = lastDigTimes[player.UserId] or 0
    if tick() - lastDigTime < MasterConfig.DIGGING.LIMITS.COOLDOWN_TIME then
        warn("TerrainDigServer: Игрок " .. player.Name .. " копает слишком часто")
        return false
    end
    
    -- Получаем позицию игрока
    local playerPosition = player.Character.HumanoidRootPart.Position
    
    -- Проверяем валидность позиции для копания
    local isValid, reason = MasterConfig.isValidDigPosition(position, playerPosition)
    if not isValid then
        warn("TerrainDigServer: Недопустимая позиция для копания: " .. reason)
        return false
    end
    
    return true
end

--[[
    Создает визуальный отладочный маркер (только в DEBUG_MODE)
    
    @param position Vector3 - позиция маркера
    @param size Vector3 - размер маркера  
    @param color Color3 - цвет маркера
    @param label string - текстовая метка
--]]
function TerrainDigServer.createDebugMarker(position, size, color, label)
    if not MasterConfig.TECHNICAL.DEBUG.ENABLE_DEBUG_MODE then
        return
    end
    
    -- Создаем полупрозрачную часть для визуализации
    local marker = Instance.new("Part")
    marker.Name = "DebugMarker_" .. label
    marker.Size = size
    marker.Position = position
    marker.Material = Enum.Material.ForceField
    marker.Color = color
    marker.Transparency = 0.7
    marker.Anchored = true
    marker.CanCollide = false
    marker.Parent = Workspace
    
    -- Добавляем текстовую метку
    local gui = Instance.new("BillboardGui")
    gui.Size = UDim2.new(0, 100, 0, 50)
    gui.Parent = marker
    
    local textLabel = Instance.new("TextLabel")
    textLabel.Size = UDim2.new(1, 0, 1, 0)
    textLabel.Text = label
    textLabel.TextColor3 = Color3.new(1, 1, 1)
    textLabel.BackgroundTransparency = 1
    textLabel.Font = Enum.Font.SourceSansBold
    textLabel.TextScaled = true
    textLabel.Parent = gui
    
    -- Удаляем маркер через заданное время
    game:GetService("Debris"):AddItem(marker, MasterConfig.TECHNICAL.DEBUG.VISUAL_MARKERS.MARKER_LIFETIME)
end

--[[
    Очищает кэш данных для отключившегося игрока
    
    @param player Player - игрок который покинул игру
--]]
function TerrainDigServer.cleanupPlayerData(player)
    lastDigTimes[player.UserId] = nil
    -- Кэш горизонтальных слоев общий для всех игроков, поэтому не чистим
    print("TerrainDigServer: Очищены данные для игрока " .. player.Name)
end

-- ═══════════════════════════════════════════════════════════════
-- ИНИЦИАЛИЗАЦИЯ И ОТЛАДКА
-- ═══════════════════════════════════════════════════════════════

--[[
    Инициализирует систему копания террейна
--]]
function TerrainDigServer.initialize()
    print("TerrainDigServer: Инициализация системы копания...")
    
    -- Проверяем доступность terrain
    if not terrain then
        error("TerrainDigServer: Не удалось получить доступ к Workspace.Terrain!")
    end
    
    -- Инициализируем RemoteEvents
    RemoteEvents.initialize()
    
    -- Подключаем обработчик события копания
    local digEvent = RemoteEvents.getDigTerrainEvent()
    digEvent.OnServerEvent:Connect(function(player, hitPosition)
        -- Валидируем данные
        if not RemoteEvents.validateDigData(player, hitPosition) then
            return
        end
        
        -- Обрабатываем копание
        local success = TerrainDigServer.processDigClick(player, hitPosition)
        
        -- Отправляем результат клиенту
        local resultEvent = RemoteEvents.getDigResultEvent()
        RemoteEvents.safeFireClient(resultEvent, player, {
            success = success,
            position = hitPosition,
            timestamp = tick()
        })
    end)
    
    -- Выводим отладочную информацию о конфигах
    if MasterConfig.TECHNICAL.DEBUG.ENABLE_DEBUG_MODE then
        MasterConfig.printFullConfiguration()
        RemoteEvents.printDebugInfo()
    end
    
    -- Подписываемся на отключение игроков для очистки данных
    Players.PlayerRemoving:Connect(function(player)
        TerrainDigServer.cleanupPlayerData(player)
    end)
    
    -- Инициализация завершена, запускаем генерацию начальных слоев
    print("TerrainDigServer: Система копания успешно инициализирована!")
    
    -- Генерируем первые несколько слоев при старте
    wait(1) -- Даем время на загрузку
    ensureLayersExist()
    print("TerrainDigServer: Начальные слои сгенерированы!")
end

--[[
    Выводит статистику системы копания
--]]
function TerrainDigServer.printStats()
    print("═══ СТАТИСТИКА КОПАНИЯ ═══")
    print("Активных операций с terrain:", activeOperations)
    print("Игроков в кэше:", table.getn(lastDigTimes or {}))
    print("🔧 Горизонтальных слоев сгенерировано:", #generatedLayers)
    print("⏰ Самый глубокий игрок на Y:", deepestPlayerY)
    
    for layerIndex, layerData in pairs(generatedLayers) do
        print("  Слой", layerIndex, ":", layerData.biome, "на Y:", layerData.y)
    end
    print("═════════════════════════")
end

-- Возвращаем модуль для использования в других скриптах
return TerrainDigServer
