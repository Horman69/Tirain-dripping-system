--[[
    ═══════════════════════════════════════════════════════════════
    СИСТЕМА REMOTEEVENTS ДЛЯ ИГРЫ-КОПАЛКИ
    ═══════════════════════════════════════════════════════════════
    
    Этот модуль создает и управляет всеми RemoteEvents для связи
    между клиентом и сервером:
    • Обработка кликов по terrain (клиент → сервер)
    • Обновление данных глубины (сервер → клиент)
    • Синхронизация информации о биомах
    
    ВАЖНЫЕ ПРИНЦИПЫ:
    • Безопасная передача данных
    • Валидация всех входящих данных
    • Готовность к расширению функциональности
    
    Автор: Rus_ik000
    Дата: 2025
--]]

local RemoteEvents = {}

-- ═══════════════════════════════════════════════════════════════
-- ИМПОРТЫ И СЕРВИСЫ
-- ═══════════════════════════════════════════════════════════════

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- ═══════════════════════════════════════════════════════════════
-- КОНСТАНТЫ REMOTEEVENTS
-- ═══════════════════════════════════════════════════════════════

-- Имена всех RemoteEvents (централизованно для избежания ошибок)
local REMOTE_EVENT_NAMES = {
    -- Основные события копания
    DIG_TERRAIN = "DigTerrain",           -- клиент → сервер: запрос на копание
    DIG_RESULT = "DigResult",             -- сервер → клиент: результат копания
    
    -- События для UI и глубины  
    DEPTH_UPDATE = "DepthUpdate",         -- сервер → клиент: обновление глубины
    BIOME_UPDATE = "BiomeUpdate",         -- сервер → клиент: смена биома
    
    -- Отладочные события
    DEBUG_INFO = "DebugInfo"              -- сервер → клиент: отладочная информация
}

-- ═══════════════════════════════════════════════════════════════
-- СОЗДАНИЕ REMOTEEVENTS
-- ═══════════════════════════════════════════════════════════════

-- Кэш созданных RemoteEvents
local createdEvents = {}

--[[
    Создает RemoteEvent с указанным именем
    
    @param eventName string - имя события
    @return RemoteEvent - созданное событие
--]]
local function createRemoteEvent(eventName)
    -- Проверяем, не создано ли уже это событие
    if createdEvents[eventName] then
        return createdEvents[eventName]
    end
    
    -- Создаем новое RemoteEvent
    local remoteEvent = Instance.new("RemoteEvent")
    remoteEvent.Name = eventName
    remoteEvent.Parent = ReplicatedStorage
    
    -- Сохраняем в кэш
    createdEvents[eventName] = remoteEvent
    
    print("RemoteEvents: Создано событие '" .. eventName .. "'")
    return remoteEvent
end

--[[
    Получает существующий RemoteEvent по имени
    
    @param eventName string - имя события
    @return RemoteEvent|nil - найденное событие или nil
--]]
local function getRemoteEvent(eventName)
    -- Сначала проверяем кэш
    if createdEvents[eventName] then
        return createdEvents[eventName]
    end
    
    -- Ищем в ReplicatedStorage
    local existingEvent = ReplicatedStorage:FindFirstChild(eventName)
    if existingEvent and existingEvent:IsA("RemoteEvent") then
        createdEvents[eventName] = existingEvent
        return existingEvent
    end
    
    return nil
end

-- ═══════════════════════════════════════════════════════════════
-- ОСНОВНЫЕ ФУНКЦИИ МОДУЛЯ
-- ═══════════════════════════════════════════════════════════════

--[[
    Инициализирует все RemoteEvents для системы копания
--]]
function RemoteEvents.initialize()
    print("RemoteEvents: Инициализация системы событий...")
    
    -- Создаем все необходимые RemoteEvents
    for eventKey, eventName in pairs(REMOTE_EVENT_NAMES) do
        createRemoteEvent(eventName)
    end
    
    print("RemoteEvents: Создано " .. table.getn(REMOTE_EVENT_NAMES) .. " событий")
    print("RemoteEvents: Система событий инициализирована!")
end

--[[
    Получает RemoteEvent для копания terrain
    
    @return RemoteEvent - событие для обработки кликов по terrain
--]]
function RemoteEvents.getDigTerrainEvent()
    return getRemoteEvent(REMOTE_EVENT_NAMES.DIG_TERRAIN) or createRemoteEvent(REMOTE_EVENT_NAMES.DIG_TERRAIN)
end

--[[
    Получает RemoteEvent для результатов копания
    
    @return RemoteEvent - событие для отправки результатов копания
--]]
function RemoteEvents.getDigResultEvent()
    return getRemoteEvent(REMOTE_EVENT_NAMES.DIG_RESULT) or createRemoteEvent(REMOTE_EVENT_NAMES.DIG_RESULT)
end

--[[
    Получает RemoteEvent для обновления глубины
    
    @return RemoteEvent - событие для обновления UI глубины
--]]
function RemoteEvents.getDepthUpdateEvent()
    return getRemoteEvent(REMOTE_EVENT_NAMES.DEPTH_UPDATE) or createRemoteEvent(REMOTE_EVENT_NAMES.DEPTH_UPDATE)
end

--[[
    Получает RemoteEvent для обновления биома
    
    @return RemoteEvent - событие для смены текущего биома
--]]
function RemoteEvents.getBiomeUpdateEvent()
    return getRemoteEvent(REMOTE_EVENT_NAMES.BIOME_UPDATE) or createRemoteEvent(REMOTE_EVENT_NAMES.BIOME_UPDATE)
end

--[[
    Получает RemoteEvent для отладочной информации
    
    @return RemoteEvent - событие для отправки отладочных данных
--]]
function RemoteEvents.getDebugInfoEvent()
    return getRemoteEvent(REMOTE_EVENT_NAMES.DEBUG_INFO) or createRemoteEvent(REMOTE_EVENT_NAMES.DEBUG_INFO)
end

-- ═══════════════════════════════════════════════════════════════
-- ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ
-- ═══════════════════════════════════════════════════════════════

--[[
    Валидирует данные для события копания
    
    @param player Player - игрок, отправивший запрос
    @param position Vector3 - позиция клика
    @return boolean - валидность данных
--]]
function RemoteEvents.validateDigData(player, position)
    -- Проверяем игрока
    if not player or not player:IsA("Player") then
        warn("RemoteEvents: Недопустимый игрок в запросе копания")
        return false
    end
    
    -- Проверяем позицию
    if not position or typeof(position) ~= "Vector3" then
        warn("RemoteEvents: Недопустимая позиция в запросе копания")
        return false
    end
    
    -- Проверяем, что позиция не содержит NaN или бесконечные значения
    if position.X ~= position.X or position.Y ~= position.Y or position.Z ~= position.Z then
        warn("RemoteEvents: Позиция содержит NaN значения")
        return false
    end
    
    if math.abs(position.X) == math.huge or math.abs(position.Y) == math.huge or math.abs(position.Z) == math.huge then
        warn("RemoteEvents: Позиция содержит бесконечные значения")
        return false
    end
    
    return true
end

--[[
    Безопасно вызывает RemoteEvent для клиента
    
    @param event RemoteEvent - событие для вызова
    @param player Player - целевой игрок
    @param data table - данные для передачи
--]]
function RemoteEvents.safeFireClient(event, player, data)
    if not event or not event:IsA("RemoteEvent") then
        warn("RemoteEvents: Попытка вызвать недопустимое событие")
        return
    end
    
    if not player or not player:IsA("Player") then
        warn("RemoteEvents: Попытка отправить событие недопустимому игроку")
        return
    end
    
    -- Проверяем, что игрок все еще в игре
    if not player.Parent then
        warn("RemoteEvents: Игрок " .. tostring(player.Name) .. " покинул игру")
        return
    end
    
    local success, errorMessage = pcall(function()
        if data then
            event:FireClient(player, data)
        else
            event:FireClient(player)
        end
    end)
    
    if not success then
        warn("RemoteEvents: Ошибка при отправке события клиенту: " .. tostring(errorMessage))
    end
end

-- ═══════════════════════════════════════════════════════════════
-- ОТЛАДОЧНАЯ ИНФОРМАЦИЯ
-- ═══════════════════════════════════════════════════════════════

--[[
    Выводит отладочную информацию о всех созданных событиях
--]]
function RemoteEvents.printDebugInfo()
    print("═══ ОТЛАДКА REMOTEEVENTS ═══")
    print("Всего событий создано:", table.getn(createdEvents))
    
    for eventName, event in pairs(createdEvents) do
        print("• " .. eventName .. " - " .. (event.Parent and "✅ Активно" or "❌ Не активно"))
    end
    
    print("════════════════════════════")
end

--[[
    Очищает все созданные события (для тестирования)
--]]
function RemoteEvents.cleanup()
    for eventName, event in pairs(createdEvents) do
        if event and event.Parent then
            event:Destroy()
        end
    end
    
    createdEvents = {}
    print("RemoteEvents: Все события очищены")
end

-- Возвращаем модуль для использования в других скриптах
return RemoteEvents
