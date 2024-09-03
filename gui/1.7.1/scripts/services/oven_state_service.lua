-- services/oven_state_service.lua

local logger = require("components.logger")
local oven_status_manager = require("components.oven_status_manager")

local oven_state_service = {}

-- Log a composite message
function oven_state_service.logOvenState()
    local oven_state = oven_status_manager.get_state()
    logger.info("OvenState: " .. tostring(oven_state.OvenState))
    logger.info("OvenMode: " .. tostring(oven_state.OvenMode))
    logger.info("ManualMode: " .. tostring(oven_state.ManualMode))
    logger.info("ManualSubMode: " .. tostring(oven_state.ManualSubMode))
    logger.info("WashingMode: " .. tostring(oven_state.WashingMode))
    
end

-- Update and log power state
function oven_state_service.updatePowerState(value)
    oven_status_manager.update_power_state(value)
    --oven_state_service.logOvenState()
end

-- Update and log door state
function oven_state_service.updateDoorState(value)
    oven_status_manager.update_door_state(value)
    --oven_state_service.logOvenState()
end
  
-- Update and log cooking mode
function oven_state_service.updateCookingMode(value)
    oven_status_manager.update_cooking_mode(value)
    --oven_state_service.logOvenState()
end

-- Update and log washing mode
function oven_state_service.updateWashingMode(value)
    oven_status_manager.update_washing_mode(value)
    --oven_state_service.logOvenState()
end

-- Update and log oven state
function oven_state_service.updateOvenState(value)
    oven_status_manager.update_oven_state(value)
    --oven_state_service.logOvenState()
end

function oven_state_service.updateOvenMode(value)
    oven_status_manager.update_oven_mode(value)
    --oven_state_service.logOvenState()
end

-- Update and log user action
function oven_state_service.updateUserAction(value)
    oven_status_manager.update_user_action(value)
    --oven_state_service.logOvenState()
end

-- Update and log manual mode
function oven_state_service.updateManualMode(value)
    oven_status_manager.update_manual_mode(value)
    --oven_state_service.logOvenState()
end

-- Update and log sub  manual mode
function oven_state_service.updateManualSubMode(value)
    oven_status_manager.update_manual_sub_mode(value)
    --oven_state_service.logOvenState()
end

-- Reset oven state and log
function oven_state_service.resetOvenState()
    oven_status_manager.reset_state()
    --oven_state_service.logOvenState()
end

-- Get specific state values
function oven_state_service.getPowerState()
    return oven_status_manager.get_state_value("PowerState")
end

function oven_state_service.getDoorState()
    return oven_status_manager.get_state_value("DoorState")
end

function oven_state_service.getCookingMode()
    return oven_status_manager.get_state_value("CookingMode")
end

function oven_state_service.getWashingMode()
    return oven_status_manager.get_state_value("WashingMode")
end

function oven_state_service.getOvenState()
    return oven_status_manager.get_state_value("OvenState")
end

function oven_state_service.getOvenMode()
    return oven_status_manager.get_state_value("OvenMode")
end

function oven_state_service.getUserAction()
    return oven_status_manager.get_state_value("UserAction")
end

function oven_state_service.getManualMode()
    return oven_status_manager.get_state_value("ManualMode")
end

function oven_state_service.getManualSubMode()
    return oven_status_manager.get_state_value("ManualSubMode")
end

return oven_state_service

