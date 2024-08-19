-- components/oven_status_manager.lua

local oven_status_manager = {}
local Oven = require("components.oven_status_enums")
local validator = require("utils.data_validator")

local initial_state = {
    PowerState = Oven.PowerState.ON,
    DoorState = Oven.DoorState.CLOSED,
    CookingMode = Oven.CookingMode.NONE,
    WashingMode = Oven.WashingMode.NONE,
    OvenState = Oven.OvenState.STOP,
    OvenMode = Oven.OvenMode.NONE,
    UserAction = Oven.UserAction.NONE,
    ManualMode = Oven.ManualMode.NONE,
    ManualSubMode = Oven.ManualSubMode.NONE
}

local oven_state = {
    PowerState = Oven.PowerState.OFF,
    DoorState = Oven.DoorState.CLOSED,
    CookingMode = Oven.CookingMode.NONE,
    WashingMode = Oven.WashingMode.NONE,
    OvenState = Oven.OvenState.STOP,
    OvenMode = Oven.OvenMode.NONE,
    UserAction = Oven.UserAction.NONE,
    ManualMode = Oven.ManualMode.NONE,
    ManualSubMode = Oven.ManualSubMode.NONE
}

local function is_valid_value(enum_table, value)
    if value == nil then
        return true  -- Consideramos nil como válido si es usado para resetear el estado
    end

    for _, v in pairs(enum_table) do
        if v == value then
            return true
        end
    end
    return false
end


-- Métodos para actualizar cada estado
function oven_status_manager.update_power_state(value)
    if is_valid_value(Oven.PowerState, value) then
        oven_state.PowerState = value
    else
        error("Invalid PowerState value: " .. tostring(value))
    end
end

function oven_status_manager.update_door_state(value)
    if is_valid_value(Oven.DoorState, value) then
        oven_state.DoorState = value
    else
        error("Invalid DoorState value: " .. tostring(value))
    end
end

function oven_status_manager.update_cooking_mode(value)
    if is_valid_value(Oven.CookingMode, value) then
        oven_state.CookingMode = value
    else
        error("Invalid CookingMode value: " .. tostring(value))
    end
end

function oven_status_manager.update_washing_mode(value)
    if is_valid_value(Oven.WashingMode, value) then
        oven_state.WashingMode = value
    else
        error("Invalid WashingMode value: " .. tostring(value))
    end
end

function oven_status_manager.update_oven_state(value)
    if is_valid_value(Oven.OvenState, value) then
        oven_state.OvenState = value
    else
        error("Invalid OvenState value: " .. tostring(value))
    end
end

function oven_status_manager.update_oven_mode(value)
    if is_valid_value(Oven.OvenMode, value) then
        oven_state.OvenMode = value
    else
        error("Invalid OvenState value: " .. tostring(value))
    end
end


function oven_status_manager.update_user_action(value)
    if is_valid_value(Oven.UserAction, value) then
        oven_state.UserAction = value
    else
        error("Invalid UserAction value: " .. tostring(value))
    end
end

function oven_status_manager.update_manual_mode(value)
    if is_valid_value(Oven.ManualMode, value) then
        oven_state.ManualMode = value
    else
        error("Invalid ManualMode value: " .. tostring(value))
    end
end

function oven_status_manager.update_manual_sub_mode(value)
    if is_valid_value(Oven.ManualSubMode, value) then
        oven_state.ManualSubMode = value
    else
        error("Invalid ManualMode value: " .. tostring(value))
    end
end

-- Función para obtener el estado actual del horno
function oven_status_manager.get_state()
    return oven_state
end

-- Función para obtener un valor específico del estado del horno
function oven_status_manager.get_state_value(key)
    return oven_state[key]
end

-- Función para reiniciar el estado del horno
function oven_status_manager.reset_state()
  oven_state.PowerState = initial_state.PowerState
  oven_state.DoorState = initial_state.DoorState
  oven_state.CookingMode = initial_state.CookingMode
  oven_state.WashingMode = initial_state.WashingMode
  oven_state.OvenState = initial_state.OvenState
  oven_state.OvenMode = initial_state.OvenMode
  oven_state.UserAction = initial_state.UserAction
  oven_state.ManualMode = initial_state.ManualMode
  oven_state.ManualSubMode = initial_state.ManualSubMode
end
-- Retornar las enumeraciones y el manejador de estado
oven_status_manager.Oven = Oven

return oven_status_manager
