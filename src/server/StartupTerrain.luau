--[[
    ═══════════════════════════════════════════════════════════════
    ГЕНЕРАЦИЯ СТАРТОВОГО ТЕРРЕЙНА
    ═══════════════════════════════════════════════════════════════
    
    Этот модуль создает начальный terrain для игры-копалки:
    • Плоская поверхность из песка
    • Размер 50x50 studs (совпадает с горизонтальными слоями)
    • Толщина 10 studs
    • Позиция по центру мира
    
    ВАЖНЫЕ ПРИНЦИПЫ:
    • Используем FillRegion с resolution=4 для совместимости
    • Материал Sand для поверхности
    • Размер совпадает с системой горизонтальных слоев
    • Готовность к копанию сразу после создания
    
    Автор: Rus_ik000
    Дата: 2025
--]]

local StartupTerrain = {}

-- ═══════════════════════════════════════════════════════════════
-- ИМПОРТЫ И СЕРВИСЫ
-- ═══════════════════════════════════════════════════════════════

local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Импортируем конфиги
local MasterConfig = require(ReplicatedStorage.Shared.MasterConfig)

-- Ссылка на terrain объект
local terrain = Workspace.Terrain

-- ═══════════════════════════════════════════════════════════════
-- НАСТРОЙКИ СТАРТОВОГО TERRAIN
-- ═══════════════════════════════════════════════════════════════

-- Размеры стартового terrain
local TERRAIN_CONFIG = {
    SIZE_X = 50,            -- ширина в studs (совпадает с размером горизонтальных слоев)
    SIZE_Z = 50,            -- глубина в studs (совпадает с размером горизонтальных слоев)
    THICKNESS = 10,         -- толщина в studs
    MATERIAL = Enum.Material.Sand,  -- материал поверхности
    POSITION = Vector3.new(0, 0, 0) -- центральная позиция
}

-- ═══════════════════════════════════════════════════════════════
-- ОСНОВНЫЕ ФУНКЦИИ
-- ═══════════════════════════════════════════════════════════════

--[[
    Создает стартовый terrain для игры
--]]
function StartupTerrain.generateStartupTerrain()
    print("StartupTerrain: Начинаю генерацию стартового terrain...")
    
    -- Очищаем существующий terrain в области
    StartupTerrain.clearExistingTerrain()
    
    -- Создаем новый terrain
    local success = StartupTerrain.createTerrainPlatform()
    
    if success then
        print("StartupTerrain: ✅ Стартовый terrain создан успешно!")
        print("StartupTerrain: 📏 Размер: " .. TERRAIN_CONFIG.SIZE_X .. "x" .. TERRAIN_CONFIG.SIZE_Z .. "x" .. TERRAIN_CONFIG.THICKNESS)
        print("StartupTerrain: 🏖️ Материал: " .. tostring(TERRAIN_CONFIG.MATERIAL))
        print("StartupTerrain: 📍 Позиция: " .. tostring(TERRAIN_CONFIG.POSITION))
    else
        warn("StartupTerrain: ❌ Ошибка при создании стартового terrain!")
    end
    
    return success
end

--[[
    Очищает существующий terrain в области генерации
--]]
function StartupTerrain.clearExistingTerrain()
    print("StartupTerrain: Очистка области для нового terrain...")
    
    local success = pcall(function()
        -- Создаем область для очистки (чуть больше чем нужно)
        local halfSizeX = (TERRAIN_CONFIG.SIZE_X + 20) / 2
        local halfSizeY = (TERRAIN_CONFIG.THICKNESS + 20) / 2
        local halfSizeZ = (TERRAIN_CONFIG.SIZE_Z + 20) / 2
        
        local minPoint = Vector3.new(
            TERRAIN_CONFIG.POSITION.X - halfSizeX,
            TERRAIN_CONFIG.POSITION.Y - halfSizeY,
            TERRAIN_CONFIG.POSITION.Z - halfSizeZ
        )
        
        local maxPoint = Vector3.new(
            TERRAIN_CONFIG.POSITION.X + halfSizeX,
            TERRAIN_CONFIG.POSITION.Y + halfSizeY,
            TERRAIN_CONFIG.POSITION.Z + halfSizeZ
        )
        
        local clearRegion = Region3.new(minPoint, maxPoint):ExpandToGrid(4)
        
        -- Заполняем область воздухом (очищаем) с правильным resolution
        terrain:FillRegion(clearRegion, 4, Enum.Material.Air)
    end)
    
    if success then
        print("StartupTerrain: ✅ Область очищена")
    else
        warn("StartupTerrain: ⚠️ Ошибка при очистке области")
    end
end

--[[
    Создает платформу из terrain
    
    @return boolean - успешность создания
--]]
function StartupTerrain.createTerrainPlatform()
    local success = pcall(function()
        -- Вычисляем позицию платформы (чуть выше центра)
        local platformY = TERRAIN_CONFIG.POSITION.Y + TERRAIN_CONFIG.THICKNESS/2
        
        -- Создаем границы региона
        local minPoint = Vector3.new(
            TERRAIN_CONFIG.POSITION.X - TERRAIN_CONFIG.SIZE_X/2,
            TERRAIN_CONFIG.POSITION.Y,
            TERRAIN_CONFIG.POSITION.Z - TERRAIN_CONFIG.SIZE_Z/2
        )
        
        local maxPoint = Vector3.new(
            TERRAIN_CONFIG.POSITION.X + TERRAIN_CONFIG.SIZE_X/2,
            TERRAIN_CONFIG.POSITION.Y + TERRAIN_CONFIG.THICKNESS,
            TERRAIN_CONFIG.POSITION.Z + TERRAIN_CONFIG.SIZE_Z/2
        )
        
        -- Создаем Region3 для платформы
        local region = Region3.new(minPoint, maxPoint):ExpandToGrid(4)
        
        -- Заполняем регион песком с правильным resolution
        terrain:FillRegion(region, 4, TERRAIN_CONFIG.MATERIAL)
        
        -- Создаем отладочный маркер если включена отладка
        if MasterConfig.TECHNICAL.DEBUG.ENABLE_DEBUG_MODE then
            local platformPosition = Vector3.new(
                TERRAIN_CONFIG.POSITION.X,
                platformY,
                TERRAIN_CONFIG.POSITION.Z
            )
            local platformSize = Vector3.new(
                TERRAIN_CONFIG.SIZE_X,
                TERRAIN_CONFIG.THICKNESS,
                TERRAIN_CONFIG.SIZE_Z
            )
            StartupTerrain.createDebugMarker(platformPosition, platformSize)
        end
        
        print("StartupTerrain: Платформа создана в позиции " .. tostring(minPoint) .. " - " .. tostring(maxPoint))
    end)
    
    return success
end

--[[
    Создает отладочный маркер для визуализации созданного terrain
    
    @param position Vector3 - позиция маркера
    @param size Vector3 - размер маркера
--]]
function StartupTerrain.createDebugMarker(position, size)
    -- Создаем полупрозрачную часть для визуализации границ
    local marker = Instance.new("Part")
    marker.Name = "StartupTerrain_DebugMarker"
    marker.Size = size
    marker.Position = position
    marker.Material = Enum.Material.ForceField
    marker.Color = Color3.fromRGB(255, 255, 0) -- желтый цвет
    marker.Transparency = 0.8
    marker.Anchored = true
    marker.CanCollide = false
    marker.Parent = Workspace
    
    -- Добавляем текстовую метку
    local gui = Instance.new("BillboardGui")
    gui.Size = UDim2.new(0, 150, 0, 50)
    gui.Parent = marker
    
    local textLabel = Instance.new("TextLabel")
    textLabel.Size = UDim2.new(1, 0, 1, 0)
    textLabel.Text = "СТАРТОВЫЙ TERRAIN"
    textLabel.TextColor3 = Color3.new(1, 1, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.Font = Enum.Font.SourceSansBold
    textLabel.TextScaled = true
    textLabel.Parent = gui
    
    -- Удаляем маркер через 10 секунд
    game:GetService("Debris"):AddItem(marker, 10)
    
    print("StartupTerrain: Отладочный маркер создан")
end

--[[
    Проверяет, создан ли уже стартовый terrain
    
    @return boolean - true если terrain уже создан
--]]
function StartupTerrain.isStartupTerrainExists()
    -- Проверяем наличие terrain в центральной области
    local checkPosition = TERRAIN_CONFIG.POSITION + Vector3.new(0, TERRAIN_CONFIG.THICKNESS/2, 0)
    local checkSize = Vector3.new(10, 5, 10) -- небольшая область для проверки
    
    local region = Region3.new(
        checkPosition - checkSize/2,
        checkPosition + checkSize/2
    ):ExpandToGrid(4)
    
    -- Читаем данные terrain в области
    local materials, occupancies = terrain:ReadVoxels(region, MasterConfig.WORLD.TERRAIN_API.RESOLUTION)
    
    -- Проверяем, есть ли материал в области (не воздух)
    for x = 1, materials.Size.X do
        for y = 1, materials.Size.Y do
            for z = 1, materials.Size.Z do
                if materials[x][y][z] ~= Enum.Material.Air and occupancies[x][y][z] > 0 then
                    return true
                end
            end
        end
    end
    
    return false
end

--[[
    Получает информацию о стартовом terrain
    
    @return table - информация о конфигурации terrain
--]]
function StartupTerrain.getTerrainInfo()
    return {
        sizeX = TERRAIN_CONFIG.SIZE_X,
        sizeZ = TERRAIN_CONFIG.SIZE_Z,
        thickness = TERRAIN_CONFIG.THICKNESS,
        material = TERRAIN_CONFIG.MATERIAL,
        position = TERRAIN_CONFIG.POSITION,
        exists = StartupTerrain.isStartupTerrainExists()
    }
end

-- ═══════════════════════════════════════════════════════════════
-- ОТЛАДОЧНАЯ ИНФОРМАЦИЯ
-- ═══════════════════════════════════════════════════════════════

--[[
    Выводит отладочную информацию о стартовом terrain
--]]
function StartupTerrain.printDebugInfo()
    print("═══ ОТЛАДКА СТАРТОВОГО TERRAIN ═══")
    print("Размер X:", TERRAIN_CONFIG.SIZE_X)
    print("Размер Z:", TERRAIN_CONFIG.SIZE_Z) 
    print("Толщина:", TERRAIN_CONFIG.THICKNESS)
    print("Материал:", tostring(TERRAIN_CONFIG.MATERIAL))
    print("Позиция:", tostring(TERRAIN_CONFIG.POSITION))
    print("Terrain существует:", StartupTerrain.isStartupTerrainExists())
    print("═══════════════════════════════")
end

-- Возвращаем модуль для использования в других скриптах
return StartupTerrain
