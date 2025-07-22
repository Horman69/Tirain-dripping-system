--[[
    ═══════════════════════════════════════════════════════════════
    ИНИЦИАЛИЗАЦИЯ СЕРВЕРНОЙ ЧАСТИ ИГРЫ-КОПАЛКИ
    ═══════════════════════════════════════════════════════════════
    
    Этот скрипт запускается на сервере и инициализирует все системы:
    • Систему копания террейна
    • Обработку кликов игроков
    • Генерацию биомов
    • Отладку и мониторинг
    
    Автор: Rus_ik000
    Дата: 2025
--]]

-- Основные сервисы Roblox
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

print("🚀 Запуск серверной части игры-копалки...")

-- ═══════════════════════════════════════════════════════════════
-- ИНИЦИАЛИЗАЦИЯ МОДУЛЕЙ
-- ═══════════════════════════════════════════════════════════════

-- Импортируем серверную логику копания
local TerrainDigServer = require(script.TerrainDigServer)
local StartupTerrain = require(script.StartupTerrain)

-- Создаем стартовый terrain
StartupTerrain.generateStartupTerrain()

-- Инициализируем систему копания
TerrainDigServer.initialize()

print("✅ Система копания террейна инициализирована!")

-- ═══════════════════════════════════════════════════════════════
-- ОБРАБОТКА ПОДКЛЮЧЕНИЯ ИГРОКОВ
-- ═══════════════════════════════════════════════════════════════

--[[
    Обрабатывает подключение нового игрока к игре
--]]
local function onPlayerAdded(player)
    print("👤 Игрок " .. player.Name .. " подключился к игре")
    
    -- Ждем появления персонажа игрока
    player.CharacterAdded:Connect(function(character)
        print("🏃 Персонаж игрока " .. player.Name .. " заспавнился")
        
        -- Позицию игрока оставляем стандартной (SpawnLocation)
        print("📍 Игрок " .. player.Name .. " заспавнился на стандартной позиции")
    end)
end

-- Подписываемся на подключение игроков
Players.PlayerAdded:Connect(onPlayerAdded)

-- Обрабатываем уже подключенных игроков (если скрипт перезапускается)
for _, player in pairs(Players:GetPlayers()) do
    onPlayerAdded(player)
end

-- ═══════════════════════════════════════════════════════════════
-- ОТЛАДКА И МОНИТОРИНГ
-- ═══════════════════════════════════════════════════════════════

-- Выводим статистику каждые 30 секунд (только в режиме отладки)
spawn(function()
    while true do
        wait(30)
        
        -- Импортируем MasterConfig для проверки DEBUG_MODE
        local MasterConfig = require(ReplicatedStorage.Shared.MasterConfig)
        
        if MasterConfig.TECHNICAL.DEBUG.ENABLE_DEBUG_MODE then
            TerrainDigServer.printStats()
        end
    end
end)

print("🎮 Сервер игры-копалки успешно запущен!")
print("📝 Игроки могут кликать по terrain для копания ям")
print("🔧 Режим отладки: включен (отладочные маркеры видимы)")
print("═══════════════════════════════════════════════════════")