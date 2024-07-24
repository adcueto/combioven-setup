--- Oven Level Alert System
-- This script manages the alert system for a multi-level oven.
-- Each level has a specific cooking time, and alerts are generated
-- when the cooking time is up. Alerts are cleared when the door is opened.
-- @module OvenLevelAlertSystem
-- @license MIT
-- @author Adrian Cueto
-- @contact adrianjpca@gmail.com
-- 

MLevels = {}

--- Send an alert message for a specific level.
-- This function displays an alert message for the specified level.
-- @param level The level to send an alert for.
function sendAlert(level)
  local data = { hidden = 0 }
  local strname = string.format("Layer_Pop_ups.icon_level_ready_%d",level)
  
  gre.set_group_attrs(strname,data)  --Set Window discharge level msg
  data[string.format("Layer_MultiLevel.bkg_Level_%d.alpha%d",level,level)] = 255
  gre.set_data(data) 
end

--- Clear the alert message for a specific level.
-- This function clears the alert message for the specified level.
-- @param level The level to clear the alert for.
function clearAlert(level)
    local data = { hidden = 1 } -- Assuming hidden = 1 clears the alert
    local strname = string.format("Layer_Pop_ups.icon_level_ready_%d", level)

    gre.set_group_attrs(strname, data) -- Clear window discharge level message
    data[string.format("Layer_MultiLevel.bkg_Level_%d.alpha%d",level,level)] = 0
    gre.set_data(data)
end


--- Update the cooking time of a level.
-- This function updates the cooking time of the specified level and triggers an alert if the time is less than or equal to zero.
-- @param level The level to update the cooking time for.
-- @param time The new cooking time for the level.
function alert_updateLevelTime(i, time)
   local index = MLevels[i]
   if index.time > 0 then
        index.time = time
        index.alert = (time == 0) and true or false
        print("Level " .. index.level .. " time updated to " .. time .. " seconds. Alert status: " .. (index.alert and "ON" or "OFF"))
        if index.alert then
            sendAlert(index.level)
        end
        return
    end
end


--- Clear alerts when the door is opened.
-- This function clears the alerts for all levels when the oven door is opened
function alert_clearLevelAlert(table)
    print("Funcion alert_clearLevelAlert()")
    for i, v in ipairs(table) do
        if v.alert then
            --v.alert = false
            print("Alert for level " .. v.level .. " cleared.")
            clearAlert(v.level)
        end
    end
end


--- Add new food to a level and reset the alert.
-- This function resets the alert status and sets a new cooking time for the specified level.
-- @param level The level to add new food to.
-- @param cookingTime The cooking time for the new food.
function alert_addFoodToLevel(level, cookingTime)
    table.insert(MLevels, {level = level, time = cookingTime, alert = false})
    print("tamaño de tabla:", #MLevels)
    print("New food added to level " .. level .. ". Cooking time set to " .. cookingTime .. " seconds. Alert reset.")
end

--- Reset all levels to their initial state.
-- This function resets the time and alert status for all levels in the oven
function alert_resetAllLevels()
    for i in ipairs(MLevels) do
            MLevels[i] = nil            
    end
    for i=1, 7 do
       clearAlert(i)
    end
    print("All levels cleared.")
end



