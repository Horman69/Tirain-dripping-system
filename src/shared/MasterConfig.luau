--[[
    ═══════════════════════════════════════════════════════════════
    🎮 МАСТЕР-КОНФИГУРАЦИЯ ИГРЫ-КОПАЛКИ
    ═══════════════════════════════════════════════════════════════
    
    Единая централизованная система настроек для всей игры.
    Все параметры в одном месте для легкой настройки баланса.
    
    📋 ОСНОВНЫЕ ПРИНЦИПЫ:
    • Простота изменения настроек
    • Логическая группировка параметров
    • Подробные комментарии на русском
    • Валидация всех значений
    • Готовность к расширению
    
    🎯 СТРУКТУРА:
    ├── 🌍 WORLD         - Размеры мира, terrain, координаты
    ├── ⛏️  DIGGING       - Механика копания, размеры ям, лимиты  
    ├── 🌋 BIOMES        - Подземные биомы и их свойства
    ├── 🖥️  INTERFACE     - UI элементы, цвета, позиции
    ├── ⚡ PERFORMANCE   - Оптимизация, лимиты операций
    ├── 🎮 GAMEPLAY      - Игровые механики, баланс
    ├── 🔧 TECHNICAL     - API настройки, сеть, отладка
    └── 🎨 VISUAL        - Эффекты, анимации, визуализация
    
    👨‍💻 Автор: Rus_ik000
    📅 Версия: 3.0 - Master Edition
    📝 Дата: 2025-07-22
--]]

local MasterConfig = {}

-- ═══════════════════════════════════════════════════════════════
-- 🌍 НАСТРОЙКИ МИРА И TERRAIN
-- ═══════════════════════════════════════════════════════════════

MasterConfig.WORLD = {
    -- 📐 Базовые размеры игрового пространства
    DIMENSIONS = {
        WIDTH = 50,              -- ширина игровой зоны (studs)
        LENGTH = 50,             -- длина игровой зоны (studs)  
        MAX_DEPTH = 10000,       -- максимальная глубина (studs)
        WORLD_CENTER = Vector3.new(0, 0, 0) -- центр мира
    },
    
    -- 🏔️ Стартовая поверхность (верхний слой)
    SURFACE = {
        THICKNESS = 10,                    -- толщина верхнего слоя (studs)
        MATERIAL = Enum.Material.Sand,     -- материал поверхности
        COLOR = Color3.fromRGB(194, 178, 128), -- цвет песка
        HEIGHT_LEVEL = 0                   -- Y-координата поверхности
    },
    
    -- 📊 Система подземных слоев
    LAYER_SYSTEM = {
        THICKNESS = 15,           -- толщина каждого подземного слоя (studs)
        START_Y = 0,              -- Y-координата начала первого слоя  
        PREVIEW_DISTANCE = 45,    -- расстояние генерации под игроком (studs)
        AUTO_GENERATION = true,   -- автоматическая генерация новых слоев
        MAX_LAYERS = 666         -- максимальное количество слоев (666 * 15 = 9990 studs глубина)
    },
    
    -- ⚙️ Технические настройки Terrain API
    TERRAIN_API = {
        RESOLUTION = 4,                    -- качество FillRegion (1-4, выше = медленнее)
        GRID_ALIGNMENT = 4,                -- выравнивание по сетке ExpandToGrid  
        AIR_MATERIAL = Enum.Material.Air,  -- материал для создания пустоты
        DEFAULT_OCCUPANCY = 1.0            -- заполненность voxel (0.0-1.0)
    }
}

-- ═══════════════════════════════════════════════════════════════
-- ⛏️ МЕХАНИКА КОПАНИЯ
-- ═══════════════════════════════════════════════════════════════

MasterConfig.DIGGING = {
    -- 🕳️ Параметры создаваемых ям
    HOLE_DIMENSIONS = {
        WIDTH = 8,               -- ширина ямы (studs)
        HEIGHT = 8,              -- высота ямы (studs)  
        DEPTH = 8,               -- глубина ямы (studs)
        SHAPE = "sphere",        -- форма: "cube", "sphere" 🌑 ИЗМЕНЕНО: теперь сферические ямы!
        RADIUS = 4               -- радиус сферы (studs) - для более естественных ям
    },
    
    -- 🚫 Ограничения и валидация
    LIMITS = {
        COOLDOWN_TIME = 0.1,         -- задержка между кликами (секунды)
        MIN_DISTANCE = 3,            -- минимальное расстояние между ямами (studs)
        MAX_REACH = 10,              -- максимальная дальность копания от игрока (studs) 🧪 ЭКСПЕРИМЕНТ: было 100
        SAFETY_ZONE = 2,             -- защитная зона вокруг игрока (studs)
        PREVENT_SPAM = true,         -- защита от спам-кликов
        CHECK_OBSTACLES = true       -- проверять препятствия перед копанием
    },
    
    -- 🎯 Точность и проверки
    VALIDATION = {
        CHECK_PLAYER_DISTANCE = true,   -- проверять расстояние до игрока
        CHECK_TERRAIN_EXISTS = true,    -- проверять наличие terrain для копания
        CHECK_WORLD_BOUNDS = true,      -- проверять границы мира
        REQUIRE_SOLID_GROUND = false    -- требовать твердую поверхность
    }
}

-- ═══════════════════════════════════════════════════════════════
-- 🌋 ПОДЗЕМНЫЕ БИОМЫ И МАТЕРИАЛЫ
-- ═══════════════════════════════════════════════════════════════

MasterConfig.BIOMES = {
    -- 🎲 Система генерации биомов
    GENERATION = {
        ALGORITHM = "weighted_random",  -- алгоритм: "weighted_random", "sequential", "depth_based"
        SEED = nil,                     -- фиксированный seed (nil = случайный каждый раз)
        RARITY_MULTIPLIER = 1.0,        -- общий множитель редкости (балансировка)
        USE_DEPTH_SCALING = false       -- учитывать глубину при выборе биома
    },
    
    -- 📋 Список всех подземных биомов
    UNDERGROUND_LIST = {
        -- 🏖️ Песок - самый распространенный
        {
            id = "sand",
            name = "Sand",
            displayName = "Песок", 
            material = Enum.Material.Sand,
            color = Color3.fromRGB(194, 178, 128),
            rarity = 1.0,           -- базовая вероятность (100%)
            minDepth = 0,           -- появляется с любой глубины
            maxDepth = 9999,        -- нет ограничений по глубине
            hardness = 1,           -- легкость копания (1=легко, 10=очень тяжело)
            value = 1,              -- ценность материала (для будущих механик)
            description = "Мягкий желтый песок"
        },
        
        -- 🧂 Соль - довольно частый
        {
            id = "salt",
            name = "Salt",
            displayName = "Соль",
            material = Enum.Material.Salt, 
            color = Color3.fromRGB(240, 240, 240),
            rarity = 0.8,
            minDepth = 15,
            maxDepth = 9999,
            hardness = 1.5,
            value = 4,
            description = "Белые соляные кристаллы"
        },
        
        -- 🪨 Известняк - средняя редкость
        {
            id = "limestone", 
            name = "Limestone",
            displayName = "Известняк",
            material = Enum.Material.Limestone,
            color = Color3.fromRGB(230, 230, 200),
            rarity = 0.6,
            minDepth = 30,
            maxDepth = 9999,
            hardness = 2.5,
            value = 6,
            description = "Светлая осадочная порода"
        },
        
        -- ⚫ Сланец - менее частый
        {
            id = "slate",
            name = "Slate", 
            displayName = "Сланец",
            material = Enum.Material.Slate,
            color = Color3.fromRGB(70, 70, 80),
            rarity = 0.4,
            minDepth = 60,
            maxDepth = 9999,
            hardness = 3,
            value = 10, 
            description = "Темная слоистая порода"
        },
        
        -- 🌋 Базальт - редкий, на большой глубине
        {
            id = "basalt",
            name = "Basalt",
            displayName = "Базальт", 
            material = Enum.Material.Basalt,
            color = Color3.fromRGB(50, 50, 50),
            rarity = 0.2,
            minDepth = 100,
            maxDepth = 9999,
            hardness = 4,
            value = 15,
            description = "Твердая вулканическая порода"
        },
        
        -- 🖤 Коренная порода - очень редкий, глубоко
        {
            id = "bedrock",
            name = "Bedrock", 
            displayName = "Коренная порода",
            material = Enum.Material.Concrete,
            color = Color3.fromRGB(0, 0, 0),
            rarity = 0.05,
            minDepth = 200,
            maxDepth = 9999,
            hardness = 10,
            value = 50,
            description = "Практически неразрушимый камень",
            isDestructible = false  -- специальное свойство
        }
    }
}

-- ═══════════════════════════════════════════════════════════════
-- 🖥️ ПОЛЬЗОВАТЕЛЬСКИЙ ИНТЕРФЕЙС
-- ═══════════════════════════════════════════════════════════════

MasterConfig.INTERFACE = {
    -- 📊 Трекер глубины (показывает Y-координату игрока)
    DEPTH_TRACKER = {
        ENABLED = true,                           -- включить/выключить трекер
        UPDATE_RATE = 10,                        -- обновлений в секунду
        POSITION = UDim2.new(0, 10, 0, 10),     -- позиция на экране (левый верх)
        SIZE = UDim2.new(0, 250, 0, 80),        -- размер GUI элемента
        FONT = Enum.Font.SourceSansBold,         -- шрифт текста
        TEXT_SIZE = 14,                          -- размер шрифта
        BACKGROUND_TRANSPARENCY = 0.3,           -- прозрачность фона
        TEXT_COLORS = {
            SURFACE = Color3.fromRGB(0, 255, 0),     -- зеленый для поверхности
            SHALLOW = Color3.fromRGB(255, 255, 0),   -- желтый для малой глубины (0-30)
            MEDIUM = Color3.fromRGB(255, 165, 0),    -- оранжевый для средней (30-100) 
            DEEP = Color3.fromRGB(255, 0, 0)         -- красный для большой (100+)
        },
        DEPTH_RANGES = {
            SHALLOW_LIMIT = 30,   -- до этой глубины = малая
            MEDIUM_LIMIT = 100    -- от shallow до этой = средняя, далее = большая
        }
    },
    
    -- 🎨 Цветовая схема интерфейса  
    THEME = {
        PRIMARY_COLOR = Color3.fromRGB(52, 152, 219),    -- основной синий
        SECONDARY_COLOR = Color3.fromRGB(46, 204, 113),  -- зеленый для успеха
        WARNING_COLOR = Color3.fromRGB(241, 196, 15),    -- желтый для предупреждений
        ERROR_COLOR = Color3.fromRGB(231, 76, 60),       -- красный для ошибок
        TEXT_COLOR = Color3.fromRGB(255, 255, 255),      -- белый текст
        BACKGROUND_COLOR = Color3.fromRGB(44, 62, 80)    -- темный фон
    },
    
    -- 🎭 Визуальные эффекты (на будущее)
    EFFECTS = {
        ENABLE_PARTICLES = false,      -- частицы при копании
        ENABLE_SCREEN_SHAKE = false,   -- тряска камеры
        ENABLE_SOUND_EFFECTS = false,  -- звуковые эффекты
        ENABLE_SMOOTH_CAMERA = false   -- плавная камера
    }
}

-- ═══════════════════════════════════════════════════════════════
-- ⚡ ПРОИЗВОДИТЕЛЬНОСТЬ И ОПТИМИЗАЦИЯ
-- ═══════════════════════════════════════════════════════════════

MasterConfig.PERFORMANCE = {
    -- 🔄 Лимиты операций с Terrain API
    TERRAIN_OPERATIONS = {
        MAX_CONCURRENT = 5,         -- максимум одновременных FillRegion операций
        TIMEOUT_SECONDS = 10,       -- таймаут операции перед отменой
        BATCH_SIZE = 3,             -- количество операций в пакете
        RETRY_ATTEMPTS = 2          -- попытки повтора при ошибке
    },
    
    -- ⏰ Интервалы обновлений (в секундах)
    UPDATE_INTERVALS = {
        DEPTH_TRACKING = 2,         -- как часто проверять глубину игроков
        LAYER_GENERATION = 1,       -- как часто генерировать новые слои
        CACHE_CLEANUP = 30,         -- как часто очищать кэш
        STATS_OUTPUT = 30,          -- как часто выводить статистику в консоль
        UI_REFRESH = 0.1           -- как часто обновлять UI
    },
    
    -- 💾 Управление памятью и кэшированием
    CACHE_SETTINGS = {
        MAX_GENERATED_LAYERS = 100,    -- максимум слоев в памяти
        MAX_PLAYER_DATA = 50,          -- максимум данных об игроках
        CLEANUP_THRESHOLD = 0.8,       -- порог очистки (80% заполнения)
        SAVE_LAYER_HISTORY = true      -- сохранять историю сгенерированных слоев
    },
    
    -- 📊 Мониторинг производительности
    MONITORING = {
        TRACK_PERFORMANCE = true,       -- отслеживать время выполнения операций
        LOG_SLOW_OPERATIONS = true,     -- логировать медленные операции  
        BENCHMARK_TERRAIN = false,      -- детальное измерение Terrain API
        MEMORY_USAGE_ALERTS = true      -- предупреждения о высоком потреблении памяти
    }
}

-- ═══════════════════════════════════════════════════════════════
-- 🎮 ИГРОВЫЕ МЕХАНИКИ И БАЛАНС
-- ═══════════════════════════════════════════════════════════════

MasterConfig.GAMEPLAY = {
    -- 🏃 Поведение и настройки игрока
    PLAYER = {
        SPAWN_HEIGHT = 20,              -- высота спавна над поверхностью (studs)
        FALL_DAMAGE = false,            -- получать урон от падения
        RESPAWN_ON_VOID_FALL = true,    -- респавн при падении в пустоту
        INFINITE_HEALTH = true,         -- бесконечное здоровье (для копалки)
        WALKSPEED_NORMAL = 16,          -- обычная скорость ходьбы
        WALKSPEED_UNDERGROUND = 16      -- скорость под землей
    },
    
    -- 🎯 Система достижений (на будущее)
    ACHIEVEMENTS = {
        ENABLE_ACHIEVEMENTS = false,
        TRACK_DEPTH_RECORDS = true,     -- отслеживать рекорды глубины
        TRACK_BLOCKS_MINED = true,      -- считать количество выкопанных блоков
        TRACK_BIOMES_FOUND = true       -- считать найденные биомы
    },
    
    -- 💎 Система ресурсов (на будущее)
    RESOURCES = {
        ENABLE_RESOURCE_SYSTEM = false,
        DROP_MATERIALS = false,         -- выпадают ли материалы при копании
        INVENTORY_SIZE = 50             -- размер инвентаря
    }
}

-- ═══════════════════════════════════════════════════════════════
-- 🔧 ТЕХНИЧЕСКИЕ НАСТРОЙКИ
-- ═══════════════════════════════════════════════════════════════

MasterConfig.TECHNICAL = {
    -- 📡 Настройки сети (Client-Server)
    NETWORKING = {
        REMOTE_EVENT_NAMES = {
            DIG_TERRAIN = "DigTerrain",       -- клиент → сервер: клик по terrain
            DIG_RESULT = "DigResult",         -- сервер → клиент: результат копания  
            DEPTH_UPDATE = "DepthUpdate",     -- сервер → клиент: обновление глубины
            BIOME_UPDATE = "BiomeUpdate",     -- сервер → клиент: смена биома
            DEBUG_INFO = "DebugInfo"          -- отладочная информация
        },
        VALIDATE_ALL_INPUTS = true,           -- валидировать данные от клиентов
        MAX_REQUESTS_PER_SECOND = 10,         -- лимит запросов от одного клиента
        TIMEOUT_REMOTE_CALLS = 5              -- таймаут RemoteFunction вызовов
    },
    
    -- 🔍 Отладка и разработка
    DEBUG = {
        ENABLE_DEBUG_MODE = false,            -- общий режим отладки
        PRINT_TERRAIN_OPERATIONS = false,     -- логировать операции с Terrain
        PRINT_LAYER_GENERATION = false,       -- логировать генерацию слоев
        PRINT_PLAYER_ACTIONS = false,         -- логировать действия игроков
        
        -- 🎨 Визуальные маркеры отладки
        VISUAL_MARKERS = {
            SHOW_HOLES = true,               -- показывать маркеры ям
            SHOW_LAYERS = true,              -- показывать маркеры слоев
            SHOW_PLAYER_ZONES = true,        -- показывать зоны игроков 🧪 включаем для эксперимента  
            MARKER_LIFETIME = 5,             -- время жизни маркеров (секунды)
            
            COLORS = {
                HOLE = Color3.fromRGB(255, 0, 0),        -- красный для ям
                LAYER = Color3.fromRGB(0, 255, 0),       -- зеленый для слоев
                SAFETY = Color3.fromRGB(255, 255, 0),    -- желтый для безопасных зон
                ERROR = Color3.fromRGB(255, 0, 255),     -- пурпурный для ошибок
                INFO = Color3.fromRGB(0, 255, 255)       -- голубой для информации
            }
        }
    },
    
    -- 🛡️ Защита от читерства
    ANTI_CHEAT = {
        ENABLE_BASIC_PROTECTION = true,       -- базовая защита
        CHECK_DISTANCE_EXPLOITS = true,       -- проверка дистанции копания
        CHECK_SPEED_EXPLOITS = true,          -- проверка скорости копания  
        RATE_LIMIT_DIGGING = true,            -- лимит частоты копания
        LOG_SUSPICIOUS_ACTIVITY = true        -- логировать подозрительные действия
    }
}

-- ═══════════════════════════════════════════════════════════════
-- 🎨 ВИЗУАЛЬНЫЕ НАСТРОЙКИ
-- ═══════════════════════════════════════════════════════════════

MasterConfig.VISUAL = {
    -- 🌈 Цвета и материалы
    COLORS = {
        SUCCESS = Color3.fromRGB(46, 204, 113),      -- зеленый для успеха
        WARNING = Color3.fromRGB(241, 196, 15),      -- желтый для предупреждений
        ERROR = Color3.fromRGB(231, 76, 60),         -- красный для ошибок
        INFO = Color3.fromRGB(52, 152, 219),         -- синий для информации
        NEUTRAL = Color3.fromRGB(149, 165, 166)      -- серый для нейтрального
    },
    
    -- ✨ Эффекты частиц (на будущее)
    PARTICLE_EFFECTS = {
        ENABLE_PARTICLES = false,
        DIG_PARTICLES = {
            COUNT = 20,                              -- количество частиц
            LIFETIME = 1.0,                          -- время жизни (секунды)  
            SPREAD_ANGLE = 45,                       -- угол разлета (градусы)
            SPEED = 10                               -- скорость частиц
        }
    },
    
    -- 🎬 Анимации и переходы (на будущее) 
    ANIMATIONS = {
        ENABLE_SMOOTH_TRANSITIONS = false,
        DIG_ANIMATION_SPEED = 1.0,                   -- скорость анимации копания
        UI_TRANSITION_TIME = 0.3,                    -- время переходов UI
        CAMERA_SMOOTH_FACTOR = 0.1                   -- фактор сглаживания камеры
    }
}

-- ═══════════════════════════════════════════════════════════════
-- 🔨 ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ
-- ═══════════════════════════════════════════════════════════════

--[[
    🏗️ Получает размеры ямы в формате Vector3
    Удобно для создания Region3 объектов
    
    @return Vector3 - размеры ямы (width, height, depth)
--]]
function MasterConfig.getHoleSize()
    local hole = MasterConfig.DIGGING.HOLE_DIMENSIONS
    if hole.SHAPE == "sphere" then
        -- Для сферы используем диаметр как размер
        local diameter = hole.RADIUS * 2
        return Vector3.new(diameter, diameter, diameter)
    else
        -- Для куба используем заданные размеры
        return Vector3.new(hole.WIDTH, hole.HEIGHT, hole.DEPTH)
    end
end

--[[
    🌑 Создает регион для сферической ямы
    Использует FillBall для более естественного вида
    
    @param centerPosition Vector3 - центр ямы
    @return Region3, number - регион и радиус для FillBall
--]]
function MasterConfig.createSphereHoleRegion(centerPosition)
    local hole = MasterConfig.DIGGING.HOLE_DIMENSIONS
    local radius = hole.RADIUS
    
    -- Создаем регион немного больше радиуса для FillRegion
    local size = Vector3.new(radius * 2.2, radius * 2.2, radius * 2.2)
    local halfSize = size / 2
    
    local minPoint = centerPosition - halfSize
    local maxPoint = centerPosition + halfSize
    
    local region = Region3.new(minPoint, maxPoint)
    local expandedRegion = region:ExpandToGrid(MasterConfig.WORLD.TERRAIN_API.GRID_ALIGNMENT)
    
    return expandedRegion, radius
end

--[[
    🌍 Получает размеры игрового мира в формате Vector3  
    
    @return Vector3 - размеры мира (width, max_depth, length)
--]]
function MasterConfig.getWorldSize()
    local world = MasterConfig.WORLD.DIMENSIONS
    return Vector3.new(world.WIDTH, world.MAX_DEPTH, world.LENGTH)
end

--[[
    📊 Вычисляет Y-координату центра слоя по его индексу
    
    @param layerIndex number - номер слоя (1, 2, 3...)
    @return number - Y-координата центра слоя
--]]
function MasterConfig.getLayerCenterY(layerIndex)
    local system = MasterConfig.WORLD.LAYER_SYSTEM
    local topY = system.START_Y - (layerIndex - 1) * system.THICKNESS
    return topY - system.THICKNESS / 2
end

--[[
    📏 Определяет индекс слоя по Y-координате
    
    @param yPosition number - Y-координата в мире
    @return number - индекс слоя (0 для поверхности, 1+ для подземных)
--]]
function MasterConfig.getLayerIndex(yPosition)
    local system = MasterConfig.WORLD.LAYER_SYSTEM
    
    if yPosition > system.START_Y then
        return 0  -- поверхность
    end
    
    local depth = math.abs(yPosition - system.START_Y)  
    return math.ceil(depth / system.THICKNESS)
end

--[[
    🌋 Создает Region3 для слоя по его индексу
    
    @param layerIndex number - номер слоя
    @return Region3 - готовая область для FillRegion операций
--]]
function MasterConfig.createLayerRegion(layerIndex)
    local world = MasterConfig.WORLD.DIMENSIONS
    local system = MasterConfig.WORLD.LAYER_SYSTEM
    local center = MasterConfig.WORLD.DIMENSIONS.WORLD_CENTER
    
    -- Вычисляем границы слоя
    local topY = system.START_Y - (layerIndex - 1) * system.THICKNESS
    local bottomY = topY - system.THICKNESS
    
    -- Создаем точки региона
    local minPoint = Vector3.new(
        center.X - world.WIDTH / 2,
        bottomY,
        center.Z - world.LENGTH / 2
    )
    
    local maxPoint = Vector3.new(
        center.X + world.WIDTH / 2,
        topY,
        center.Z + world.LENGTH / 2
    )
    
    local region = Region3.new(minPoint, maxPoint)
    return region:ExpandToGrid(MasterConfig.WORLD.TERRAIN_API.GRID_ALIGNMENT)
end

--[[
    🎲 Получает случайный биом для указанной глубины
    Учитывает минимальную/максимальную глубину биомов
    
    @param depth number - глубина (положительное число)
    @return table|nil - конфигурация биома или nil если не найден
--]]
function MasterConfig.getRandomBiomeForDepth(depth)
    local availableBiomes = {}
    local biomes = MasterConfig.BIOMES.UNDERGROUND_LIST
    local generation = MasterConfig.BIOMES.GENERATION
    
    -- Фильтруем биомы подходящие для данной глубины
    for _, biome in ipairs(biomes) do
        if depth >= biome.minDepth and depth <= biome.maxDepth then
            table.insert(availableBiomes, biome)
        end
    end
    
    if #availableBiomes == 0 then
        warn("MasterConfig: Нет доступных биомов для глубины " .. depth)
        return nil
    end
    
    -- Взвешенный случайный выбор
    local totalWeight = 0
    for _, biome in ipairs(availableBiomes) do
        totalWeight = totalWeight + (biome.rarity * generation.RARITY_MULTIPLIER)
    end
    
    local randomValue = math.random() * totalWeight
    local currentWeight = 0
    
    for _, biome in ipairs(availableBiomes) do
        currentWeight = currentWeight + (biome.rarity * generation.RARITY_MULTIPLIER)
        if randomValue <= currentWeight then
            return biome
        end
    end
    
    -- Fallback - возвращаем последний биом из списка
    return availableBiomes[#availableBiomes]
end

--[[
    ✅ Валидирует всю конфигурацию на корректность
    Проверяет диапазоны значений и логическую целостность
    
    @return boolean, string - результат валидации и сообщение
--]]
function MasterConfig.validateConfiguration()
    local errors = {}
    
    -- Проверяем размеры мира
    local world = MasterConfig.WORLD.DIMENSIONS
    if world.WIDTH <= 0 or world.LENGTH <= 0 or world.MAX_DEPTH <= 0 then
        table.insert(errors, "Размеры мира должны быть положительными")
    end
    
    -- Проверяем толщину слоев
    if MasterConfig.WORLD.LAYER_SYSTEM.THICKNESS <= 0 then
        table.insert(errors, "Толщина слоев должна быть положительной")
    end
    
    -- Проверяем размеры ямы
    local hole = MasterConfig.DIGGING.HOLE_DIMENSIONS
    if hole.WIDTH <= 0 or hole.HEIGHT <= 0 or hole.DEPTH <= 0 then
        table.insert(errors, "Размеры ямы должны быть положительными")
    end
    
    -- Проверяем кулдаун
    if MasterConfig.DIGGING.LIMITS.COOLDOWN_TIME < 0 then
        table.insert(errors, "Время кулдауна не может быть отрицательным")
    end
    
    -- Проверяем биомы
    if #MasterConfig.BIOMES.UNDERGROUND_LIST == 0 then
        table.insert(errors, "Должен быть хотя бы один подземный биом")
    end
    
    -- Проверяем производительность
    if MasterConfig.PERFORMANCE.TERRAIN_OPERATIONS.MAX_CONCURRENT <= 0 then
        table.insert(errors, "Количество одновременных операций должно быть положительным")
    end
    
    -- Проверяем UI настройки
    if MasterConfig.INTERFACE.DEPTH_TRACKER.UPDATE_RATE <= 0 then
        table.insert(errors, "Частота обновления UI должна быть положительной")
    end
    
    if #errors > 0 then
        return false, "Ошибки конфигурации: " .. table.concat(errors, "; ")
    end
    
    return true, "Конфигурация валидна ✅"
end

--[[
    📊 Выводит подробную информацию обо всей конфигурации
    Удобно для отладки и настройки баланса игры
--]]
function MasterConfig.printFullConfiguration()
    print("═══════════════════════════════════════════════")
    print("🎮 МАСТЕР-КОНФИГУРАЦИЯ ИГРЫ-КОПАЛКИ v3.0")
    print("═══════════════════════════════════════════════")
    
    -- Мир и размеры
    local world = MasterConfig.WORLD.DIMENSIONS
    local surface = MasterConfig.WORLD.SURFACE
    local layers = MasterConfig.WORLD.LAYER_SYSTEM
    
    print("🌍 Мир:")
    print("  Размер области:", world.WIDTH .. "x" .. world.LENGTH .. " studs")
    print("  Максимальная глубина:", world.MAX_DEPTH .. " studs")
    print("  Толщина слоя:", layers.THICKNESS .. " studs")
    print("  Максимум слоев:", layers.MAX_LAYERS)
    print("  Материал поверхности:", tostring(surface.MATERIAL))
    
    -- Копание
    local hole = MasterConfig.DIGGING.HOLE_DIMENSIONS
    local limits = MasterConfig.DIGGING.LIMITS
    
    print("⛏️ Копание:")
    print("  Размер ямы:", hole.WIDTH .. "x" .. hole.HEIGHT .. "x" .. hole.DEPTH .. " studs")
    print("  Кулдаун:", limits.COOLDOWN_TIME .. " сек")
    print("  Максимальная дальность:", limits.MAX_REACH .. " studs")
    print("  Защитная зона:", limits.SAFETY_ZONE .. " studs")
    
    -- Биомы
    local biomes = MasterConfig.BIOMES.UNDERGROUND_LIST
    print("🌋 Биомы:")
    print("  Количество биомов:", #biomes)
    for i, biome in ipairs(biomes) do
        print(string.format("  %d. %s (редкость: %.2f, твердость: %d)", 
            i, biome.displayName, biome.rarity, biome.hardness))
    end
    
    -- Производительность
    local perf = MasterConfig.PERFORMANCE
    print("⚡ Производительность:")
    print("  Макс. операций Terrain:", perf.TERRAIN_OPERATIONS.MAX_CONCURRENT)
    print("  Макс. слоев в кэше:", perf.CACHE_SETTINGS.MAX_GENERATED_LAYERS)
    print("  Интервал генерации:", perf.UPDATE_INTERVALS.LAYER_GENERATION .. " сек")
    
    -- Интерфейс  
    local ui = MasterConfig.INTERFACE.DEPTH_TRACKER
    print("🖥️ Интерфейс:")
    print("  Трекер глубины:", ui.ENABLED and "включен" or "выключен")
    print("  Частота обновления UI:", ui.UPDATE_RATE .. " FPS")
    
    -- Отладка
    local debug = MasterConfig.TECHNICAL.DEBUG
    print("🔧 Отладка:")
    print("  Режим отладки:", debug.ENABLE_DEBUG_MODE and "включен" or "выключен")
    print("  Визуальные маркеры ям:", debug.VISUAL_MARKERS.SHOW_HOLES and "включены" or "выключены")
    print("  Время жизни маркеров:", debug.VISUAL_MARKERS.MARKER_LIFETIME .. " сек")
    
    print("═══════════════════════════════════════════════")
    
    -- Валидация конфигурации
    local isValid, message = MasterConfig.validateConfiguration()
    print("📋 Статус конфигурации:", message)
    print("═══════════════════════════════════════════════")
end

--[[
    🎛️ Быстрые пресеты для разных режимов игры
    Позволяет быстро переключаться между настройками
--]]
MasterConfig.PRESETS = {
    -- 🚀 Режим разработки - быстро и с отладкой
    DEVELOPMENT = function()
        MasterConfig.TECHNICAL.DEBUG.ENABLE_DEBUG_MODE = true
        MasterConfig.TECHNICAL.DEBUG.VISUAL_MARKERS.SHOW_HOLES = true
        MasterConfig.TECHNICAL.DEBUG.VISUAL_MARKERS.SHOW_LAYERS = true
        MasterConfig.DIGGING.LIMITS.COOLDOWN_TIME = 0.05  -- быстрое копание
        MasterConfig.PERFORMANCE.UPDATE_INTERVALS.LAYER_GENERATION = 0.5
        print("🚀 Применен пресет: РАЗРАБОТКА")
    end,
    
    -- 🎮 Режим игры - сбалансированные настройки
    PRODUCTION = function()
        MasterConfig.TECHNICAL.DEBUG.ENABLE_DEBUG_MODE = false
        MasterConfig.TECHNICAL.DEBUG.VISUAL_MARKERS.SHOW_HOLES = false
        MasterConfig.TECHNICAL.DEBUG.VISUAL_MARKERS.SHOW_LAYERS = false
        MasterConfig.DIGGING.LIMITS.COOLDOWN_TIME = 0.1
        MasterConfig.PERFORMANCE.UPDATE_INTERVALS.LAYER_GENERATION = 1.0
        print("🎮 Применен пресет: ИГРА")
    end,
    
    -- 🧪 Режим тестирования - экстремальные настройки
    TESTING = function()
        MasterConfig.WORLD.LAYER_SYSTEM.THICKNESS = 5  -- тонкие слои для быстрого тестирования
        MasterConfig.DIGGING.LIMITS.COOLDOWN_TIME = 0.01  -- очень быстрое копание
        MasterConfig.PERFORMANCE.TERRAIN_OPERATIONS.MAX_CONCURRENT = 10
        MasterConfig.TECHNICAL.DEBUG.ENABLE_DEBUG_MODE = true
        print("🧪 Применен пресет: ТЕСТИРОВАНИЕ")
    end
}

--[[
    🔄 ДОПОЛНИТЕЛЬНЫЕ ФУНКЦИИ ДЛЯ СОВМЕСТИМОСТИ С УСТАРЕВШИМИ МОДУЛЯМИ
    Эти функции обеспечивают работу существующего кода без изменений
--]]

-- Получить Y-координату слоя
function MasterConfig.getLayerY(layerIndex)
    return MasterConfig.getLayerCenterY(layerIndex)
end

-- Получить случайный биом для глубины (старый API)
function MasterConfig.getRandomUndergroundBiome()
    -- По умолчанию берем глубину 30 (второй слой)
    return MasterConfig.getRandomBiomeForDepth(30) or MasterConfig.BIOMES.UNDERGROUND_LIST[1]
end

-- Создать регион для ямы
function MasterConfig.createRegion(centerPosition, size)
    local hole = MasterConfig.DIGGING.HOLE_DIMENSIONS
    
    if hole.SHAPE == "sphere" then
        -- Для сферы используем специальную функцию
        return MasterConfig.createSphereHoleRegion(centerPosition)
    else
        -- Для куба используем стандартный метод
        local halfSize = Vector3.new(size.X / 2, size.Y / 2, size.Z / 2)
        local minPoint = centerPosition - halfSize
        local maxPoint = centerPosition + halfSize
        
        local region = Region3.new(minPoint, maxPoint)
        return region:ExpandToGrid(MasterConfig.WORLD.TERRAIN_API.GRID_ALIGNMENT)
    end
end

-- Создать регион ямы с текущими настройками
function MasterConfig.createHoleRegion(centerPosition)
    local hole = MasterConfig.DIGGING.HOLE_DIMENSIONS
    
    if hole.SHAPE == "sphere" then
        return MasterConfig.createSphereHoleRegion(centerPosition)
    else
        local size = MasterConfig.getHoleSize()
        return MasterConfig.createRegion(centerPosition, size)
    end
end

-- Получить вектор размера ямы
function MasterConfig.getHoleSizeVector()
    return MasterConfig.getHoleSize()
end

-- Получить вектор размера области генерации
function MasterConfig.getGenerationAreaVector()
    local world = MasterConfig.WORLD.DIMENSIONS
    local layer = MasterConfig.WORLD.LAYER_SYSTEM
    return Vector3.new(world.WIDTH, layer.THICKNESS, world.LENGTH)
end

-- Создать горизонтальный слой
function MasterConfig.createHorizontalLayerRegion(layerIndex)
    return MasterConfig.createLayerRegion(layerIndex)
end

-- Проверить валидность позиции для копания
function MasterConfig.isValidDigPosition(digPosition, playerPosition)
    local distance = (digPosition - playerPosition).Magnitude
    local limits = MasterConfig.DIGGING.LIMITS
    
    if distance > limits.MAX_REACH then
        return false, "Слишком далеко от игрока (макс. " .. limits.MAX_REACH .. " studs)"
    end
    
    if distance < limits.SAFETY_ZONE then
        return false, "Слишком близко к игроку (мин. " .. limits.SAFETY_ZONE .. " studs)"
    end
    
    return true, "OK"
end

--[[
    🧪 ФУНКЦИИ ДЛЯ ЭКСПЕРИМЕНТА С РАДИУСОМ КОПАНИЯ
    Быстрая настройка без перезапуска игры
--]]

-- Изменить радиус копания на лету
function MasterConfig.setDiggingRadius(newRadius)
    local oldRadius = MasterConfig.DIGGING.LIMITS.MAX_REACH
    MasterConfig.DIGGING.LIMITS.MAX_REACH = newRadius
    print("🧪 Радиус копания изменен: " .. oldRadius .. " → " .. newRadius .. " studs")
    return oldRadius
end

-- Быстрые пресеты радиуса для эксперимента  
MasterConfig.RADIUS_PRESETS = {
    VERY_CLOSE = 5,   -- очень близко
    CLOSE = 10,       -- близко (текущий)
    MEDIUM = 15,      -- средне
    FAR = 20,         -- далеко
    OLD_VALUE = 100   -- старое значение
}

-- Применить пресет радиуса
function MasterConfig.applyRadiusPreset(presetName)
    local radius = MasterConfig.RADIUS_PRESETS[presetName]
    if radius then
        MasterConfig.setDiggingRadius(radius)
        print("🎯 Применен пресет '" .. presetName .. "': " .. radius .. " studs")
    else
        warn("⚠️ Неизвестный пресет: " .. tostring(presetName))
    end
end

--[[
    🌑 ФУНКЦИИ ДЛЯ НАСТРОЙКИ ФОРМЫ ЯМ
--]]

-- Изменить форму ямы (куб или сфера)
function MasterConfig.setHoleShape(newShape)
    local validShapes = {"cube", "sphere"}
    local oldShape = MasterConfig.DIGGING.HOLE_DIMENSIONS.SHAPE
    
    if table.find(validShapes, newShape) then
        MasterConfig.DIGGING.HOLE_DIMENSIONS.SHAPE = newShape
        print("🕳️ Форма ямы изменена: " .. oldShape .. " → " .. newShape)
        
        -- Автоматически настраиваем размеры для новой формы
        if newShape == "sphere" and not MasterConfig.DIGGING.HOLE_DIMENSIONS.RADIUS then
            -- Конвертируем кубические размеры в радиус сферы
            local avgSize = (MasterConfig.DIGGING.HOLE_DIMENSIONS.WIDTH + 
                           MasterConfig.DIGGING.HOLE_DIMENSIONS.HEIGHT + 
                           MasterConfig.DIGGING.HOLE_DIMENSIONS.DEPTH) / 6
            MasterConfig.DIGGING.HOLE_DIMENSIONS.RADIUS = avgSize
            print("🌑 Радиус сферы установлен: " .. avgSize .. " studs")
        end
        
        return oldShape
    else
        warn("⚠️ Неизвестная форма ямы: " .. tostring(newShape) .. ". Доступны: cube, sphere")
        return nil
    end
end

-- Изменить размер ямы
function MasterConfig.setHoleSize(newSize)
    local hole = MasterConfig.DIGGING.HOLE_DIMENSIONS
    local oldSize
    
    if hole.SHAPE == "sphere" then
        oldSize = hole.RADIUS
        hole.RADIUS = newSize
        print("🌑 Радиус сферической ямы: " .. oldSize .. " → " .. newSize .. " studs")
    else
        oldSize = hole.WIDTH
        hole.WIDTH = newSize
        hole.HEIGHT = newSize  
        hole.DEPTH = newSize
        print("🟦 Размер кубической ямы: " .. oldSize .. " → " .. newSize .. " studs")
    end
    
    return oldSize
end

-- Пресеты форм ям
MasterConfig.HOLE_PRESETS = {
    SMALL_SPHERE = function()
        MasterConfig.setHoleShape("sphere")
        MasterConfig.setHoleSize(3)
        print("🌑 Применен пресет: Маленькая сфера (3 studs)")
    end,
    
    MEDIUM_SPHERE = function()
        MasterConfig.setHoleShape("sphere")
        MasterConfig.setHoleSize(4)
        print("🌑 Применен пресет: Средняя сфера (4 studs)")
    end,
    
    LARGE_SPHERE = function()
        MasterConfig.setHoleShape("sphere")
        MasterConfig.setHoleSize(6)
        print("🌑 Применен пресет: Большая сфера (6 studs)")
    end,
    
    SMALL_CUBE = function()
        MasterConfig.setHoleShape("cube")
        MasterConfig.setHoleSize(6)
        print("🟦 Применен пресет: Маленький куб (6x6x6)")
    end,
    
    MEDIUM_CUBE = function()
        MasterConfig.setHoleShape("cube")
        MasterConfig.setHoleSize(8)
        print("🟦 Применен пресет: Средний куб (8x8x8)")
    end
}

-- Возвращаем модуль
return MasterConfig
