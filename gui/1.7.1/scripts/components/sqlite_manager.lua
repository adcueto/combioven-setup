-- components/sqlite_manager.lua

local logger = require("components.logger")
local env_loader = require("utils.env_loader")
local luasql = env_loader.load_library("luasql_sqlite3")
local env = assert(luasql.sqlite3(), "Failed to load SQLite3 environment")

local sqlite_manager = {}
local db = nil

-- Conectar a la base de datos
function sqlite_manager.connect(database_path)
    local connection, err = env:connect(database_path)
    if not connection then
        logger.error("Failed to connect to database: " .. err)
        error("Failed to connect to database: " .. err)
    else
        logger.info("Connected to database at " .. database_path)
        db = connection
    end
end

-- Desconectar de la base de datos
function sqlite_manager.disconnect()
    if db then
        local status, err = db:close()
        if not status then
            logger.warn("Failed to close database connection: " .. err)
        else
            logger.info("Disconnected from database")
            db = nil
        end
    else
        logger.warn("Database is not connected")
    end
end

-- Ejecutar una consulta SQL y devolver una fila
function sqlite_manager.query(sql)
    assert(db, "Database is not connected")
    local cur, err = db:execute(sql)
    if not cur then
        logger.error("SQL execution failed: " .. err)
        error("SQL execution failed: " .. err)
    end

    local row = cur:fetch({}, "a")
    local close_status, close_err = pcall(function() return cur:close() end)
    if not close_status then
        logger.warn("Failed to close cursor: " .. (close_err or "unknown error"))
    end

    return row
end

-- Ejecutar una consulta SQL que no devuelva resultados (INSERT, UPDATE, DELETE)
function sqlite_manager.execute(sql)
    assert(db, "Database is not connected")
    local res, err = db:execute(sql)
    if not res then
        logger.error("SQL execution failed: " .. err)
        error("SQL execution failed: " .. err)
    end
end

return sqlite_manager


