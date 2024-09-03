-- components/logger.lua

local logger = {
    initialized = false,
    max_files = 2
}

-- Log levels
logger.levels = {ERROR = 1, WARN = 2, INFO = 3, DEBUG = 4}
logger.logLevel = logger.levels.INFO

-- Get the current date in a specific format for the log file name
local function get_log_filename()
    return os.date("%Y-%m-%d_%H-%M-%S") .. "_application.log"
end

-- List log files and keep only the most recent ones (cross-platform)
local function manage_old_logs(log_dir)
    local files = {}
    if package.config:sub(1,1) == "\\" then
        -- Windows command to list files by last modified time
        for file in io.popen('dir /B /O-D "' .. log_dir .. '\\*.log"'):lines() do
            table.insert(files, log_dir .. "\\" .. file)
        end
    else
        -- Unix-based command to list files by last modified time
        for file in io.popen('ls -t "' .. log_dir .. '"/*.log'):lines() do
            table.insert(files, file)
        end
    end

    while #files > logger.max_files do
        os.remove(files[#files])
        table.remove(files, #files)
    end
end

-- Method to initialize the logger and create the log file with a date
function logger.init()
    if not logger.initialized then
        -- Directory where log files are stored
        local osenv = gre.env({ "target_os", "target_cpu" })
        local log_dir ="/usr/crank/apps/interface/logs"
        if osenv.target_os == "win32" then
          log_dir ="./logs"
        end
        -- Create a new log file with the current date
        local log_filename = log_dir .. "/" .. get_log_filename()
        print("ruta: ",log_filename)
        logger.logFile = io.open(log_filename, "a")
        if not logger.logFile then
            error("Unable to open log file: " .. log_filename)
        end

        -- Manage old log files to ensure only the most recent are kept
        manage_old_logs(log_dir)

        logger.initialized = true
    end
end

-- Internal method to ensure initialization
function logger.ensureInitialized()
    if not logger.initialized then
        logger.init()
    end
end

-- Method to set the log level
function logger.setLevel(level)
    --logger.ensureInitialized()
    logger.logLevel = logger.levels[level]
end

-- Method to log a message
function logger.log(level, message)
    --logger.ensureInitialized()
    if logger.levels[level] <= logger.logLevel then
        -- Get debug info for the caller
        local info = debug.getinfo(3, "Sl")
        local src = info.short_src:match("^.+/(.+)$") or info.short_src
        local line = info.currentline

        --local logMessage = string.format("[%s] %s: %s (at %s:%d)", os.date("%Y-%m-%d %H:%M:%S"), level, message, src, line)
        local logMessage = string.format(" [%s][%s:%d]: %s", level, src, line, message)
        -- Write to the log file
        --[[
        if logger.logFile then
            logger.logFile:write(logMessage .. "\n")
            logger.logFile:flush()
        end
        --]]
        -- Print to the console
        print(logMessage)
    end
end

-- Convenience methods for each log level
function logger.error(message)
    logger.log("ERROR", message)
end

function logger.warn(message)
    logger.log("WARN", message)
end

function logger.info(message)
    logger.log("INFO", message)
end

function logger.debug(message)
    logger.log("DEBUG", message)
end

-- Method to close the log file when done
function logger.close()
    if logger.logFile then
        logger.logFile:close()
    end
end

return logger



