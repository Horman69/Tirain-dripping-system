-- Быстрый тест конфигурации
local MasterConfig = require(script.Parent.src.shared.MasterConfig)
local isValid, message = MasterConfig.validateConfiguration()
print('Результат валидации:', message)
MasterConfig.printFullConfiguration()
