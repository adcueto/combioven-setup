-- components/oven_status_enums.lua

local Oven = {
    PowerState = {
        OFF = "off",
        ON = "on"
    },
    DoorState = {
        OPEN = "open",
        CLOSED = "closed"
    },
    CookingMode = {
        NONE = nil,
        MANUAL = "manual",
        SMART = "smart",
        MULTILEVEL = "multilevel",
    },
    ManualMode = {
        NONE = nil,
        CONVECTION = "convection",    -- Modo Convección
        COMBINED = "combined",        -- Modo Combinado
        STEAM = "steam",              -- Modo Vapor
    },
    ManualSubMode = {
        NONE = nil,
        PROBE = "probe",             -- Submodo Sonda
        TIME = "time",               -- Submodo Tiempo
        PREHEAT = "preheat",         -- Submodo Precalentar
        LOOP = "looptime",           -- Submodo Bucle
        SPRAY = "spray",
    },
    WashingMode = {
        NONE = nil,
        QUICK = 1,
        DESCALCIFICATION = 2,
        ECO = 3,
        REGULAR = 5,
        INTERMEDIATE = 4,
        INTENSE = 6
    },
    OvenMode = {
        NONE = nil,
        PREHEATING = "preheating",
        COOKING = "cooking",
        WASHING = "washing",
        COOLING = "cooling",
        TESTING = "testing",
    },
    OvenState = {
        STOP = "stop",
        PAUSED = "paused",
        RUNNING = "running",
        FINISHED = "finished",
        START = "start"
    },
    UserAction = {
        NONE = nil,
        START_COOKING = "start_cooking",
        START_WASHING = "start_washing",
        START_PREHEATING = "start_preheating",
        START_LOOPING = "start_looping",
        START_COOLING = "start_cooling",
        START_PROBING = "start_probing",
        PAUSE = "pause",
        RESUME = "resume",
        STOP = "stop",
        OPEN_DOOR = "open_door",
        CLOSE_DOOR = "close_door"
    }
}

return Oven
