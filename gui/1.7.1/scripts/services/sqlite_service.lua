-- services/sqlite_service.lua

local sqlite_manager = require("components.sqlite_manager")

local sqlite_service = {}

function sqlite_service.init(database_path)
    sqlite_manager.connect(database_path)
end

function sqlite_service.close()
    sqlite_manager.disconnect()
end

function sqlite_service.query(sql)
    return sqlite_manager.query(sql)
end

function sqlite_service.execute(sql)
    sqlite_manager.execute(sql)
end

return sqlite_service
