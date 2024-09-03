--[[
Copyright 2016, Crank Software Inc.
All Rights Reserved.
For more information email info@cranksoftware.com
** FOR DEMO PURPOSES ONLY **
]]--

local logger = require("components.logger")
local oven_state_service = require("services.oven_state_service")
local OvenEnums = require("components.oven_status_enums")

-- Global variables for managing drag and drop functionality
local gLastPressedControl = nil
local gActiveCellPressed = nil
local gFront = 100
local gLevelSelected = 0      --if drag and drop is inside of ML are this will be 1 to 7 if it is outside will be 0
local gStartYposition = nil
local gStartXposition = nil
local uncopiedFlag = 0

--- Clones the pressed cell and sets the necessary attributes
local function CloneCellPressed()
  local dk_data = {}
  gFront = gFront + 1
  dk_data["hidden"] = 0 
  dk_data["Layer_MLOptions.drag_recipe.grd_zindex"] = gFront
  gre.clone_object("icon_recipe","drag_recipe","Layer_MLOptions", dk_data) 
  gre.set_data(dk_data)
  gre.set_value("Layer_MLOptions.drag_recipe.alpha",255)
  uncopiedFlag = 1
end

--- Highlights the appropriate level based on the position
---@param posY number The y-coordinate of the current position
local function HighlightLevel(posY)
    local data = {}
    gLevelSelected = 0
    local levels = {
        {380, 490, "Layer_MultiLevel.bkg_Level_1.alpha1", 1},
        {490, 600, "Layer_MultiLevel.bkg_Level_2.alpha2", 2},
        {600, 710, "Layer_MultiLevel.bkg_Level_3.alpha3", 3},
        {710, 820, "Layer_MultiLevel.bkg_Level_4.alpha4", 4},
        {820, 930, "Layer_MultiLevel.bkg_Level_5.alpha5", 5},
        {930, 1040, "Layer_MultiLevel.bkg_Level_6.alpha6", 6},
        {1040, 1140, "Layer_MultiLevel.bkg_Level_7.alpha7", 7},
    }
    
    for _, level in ipairs(levels) do
        local minY, maxY, alphaKey, levelIndex = unpack(level)
        if posY >= minY and posY <= maxY then
            data[alphaKey] = 255
            gLevelSelected = levelIndex
        else
            data[alphaKey] = 0
        end
    end
    gre.set_data(data)
end


--- Callback function to handle drag motion events
--- This function manages the dragging logic, including cloning the cell and highlighting levels
---@param mapargs table The event arguments containing context and event data
function CBDragML(mapargs)
	-- if no control is selected just return
  if not gLastPressedControl or recipe_id==0 then  return end
	--set postion to touch co-ord, center the control on the screen location
	local ev_data = mapargs.context_event_data;
	local size = gre.get_control_attrs(gLastPressedControl, "width", "height")
  local pos = {
      x = math.abs(ev_data.x) - 105 , --- (size.width / 2)),
      y = math.abs(ev_data.y) - 40 -- - (size.height / 2))
  }
  
   -- Save initial touch position
  if not gStartXposition or not gStartYposition then
      gStartXposition = ev_data.x
      gStartYposition = ev_data.y
  end
 

  local dk_data = {}
  dk_data = gre.get_table_attrs("Layer_MLOptions.RecipesMLTable", "rows", "cols")
  
  -- Calculate movement deltas
  local deltaX = math.abs(ev_data.x - gStartXposition)
  local deltaY = math.abs(ev_data.y - gStartYposition)
  
 
	if(gLastPressedControl == "Layer_MLOptions.RecipesMLTable")then
    -- If horizontal movement is greater than vertical, enable horizontal scroll
    if deltaX > deltaY then
        -- Enable scrolling if there are more than 6 elements
        if max_elements >= 8 then
            gre.set_table_attrs("RecipesMLTable", {scroll_horizontal = true })
            logger.info("Scrolling Enable")
       
        else
            gre.set_table_attrs("RecipesMLTable", {scroll_horizontal = false })
            logger.info("Scrolling Disable")
            if(uncopiedFlag == 0) then
               CloneCellPressed()
               gActiveCellPressed = gLastPressedControl
               gLastPressedControl = "Layer_MLOptions.drag_recipe"
               logger.info("Cell Copy")
            end
        end
    else
        gre.set_table_attrs("RecipesMLTable", { scroll_horizontal = false })
        if(uncopiedFlag == 0) then
           CloneCellPressed()
           gActiveCellPressed = gLastPressedControl
           gLastPressedControl = "Layer_MLOptions.drag_recipe"
        end
    end
	end
    
  -- Ensure the cloned cell stays within the defined area
  if gLastPressedControl == "Layer_MLOptions.drag_recipe" then
     if  pos.y > 80 and pos.y < 1200  then
        gre.set_control_attrs(gLastPressedControl, pos)
        HighlightLevel(pos.y)
     end
  end
end


--- Copies the cell data from the source table to the drag object
--- This function is used to copy the recipe name and other relevant information
---@param mapargs table The event arguments containing context and event data
function CBCopyCellData(mapargs)
  recipe_id = gre.get_value(string.format("Layer_MLOptions.RecipesMLTable.recipe_id.%d.%d",mapargs.context_row,mapargs.context_col))
  if recipe_id=="" then recipe_id=0 end
  local dk_data = {
        ["Layer_MLOptions.icon_recipe.txt.1.1"] = gre.get_value(string.format("Layer_MLOptions.RecipesMLTable.name.%d.%d", mapargs.context_row, mapargs.context_col))
    }
  logger.info("Copy Cell Data")
  gre.set_data(dk_data)
end

function ClearCopyCellData()
  recipe_id= 0
  local dk_data = {
        ["Layer_MLOptions.icon_recipe.txt.1.1"] = ""
    }
  logger.info("Clear Copy Cell")
  gre.set_data(dk_data)
end



--- Handles the release event, clearing the dragged control and finalizing the drop
--- This function manages the end of the drag and drop interaction
---@param mapargs table The event arguments containing context and event data
function CBReleaseML(mapargs)
  gLastPressedControl = nil
  uncopiedFlag = 0
  local dk_data = {}
  logger.info("Release Copy Cell")
  
  if(gLevelSelected ~= 0) then
    CheckPresetsML(recipe_id, gLevelSelected)   --recipe_id recipe selected
    dk_data["Layer_MultiLevel.bkg_PlayML.pressed"] = 0

    oven_state_service.updateOvenState(OvenEnums.OvenState.RUNNING)
    oven_state_service.updateOvenMode(OvenEnums.OvenMode.COOKING)
    oven_state_service.updateManualMode(OvenEnums.ManualMode.NONE)
    oven_state_service.updateCookingMode(OvenEnums.CookingMode.MULTILEVEL)
    oven_state_service.logOvenState()
    logger.info("Oven running in multilevel mode")
  else
    gLevelSelected = 0
  end
  
  gFront = gFront + 1
  dk_data["hidden"] = 0 
  dk_data["Layer_MLOptions.drag_recipe.grd_zindex"] = 0
  dk_data["Layer_MLOptions.drag_recipe.alpha"] = 0  
  dk_data["Layer_MLOptions.RecipesMLTable.grd_zindex"] = gFront
  dk_data[string.format("Layer_MultiLevel.bkg_Level_%d.alpha%d",gLevelSelected,gLevelSelected)] = 0
  
  ClearCopyCellData()
  gre.set_data(dk_data) 
  gre.delete_object("Layer_MLOptions.drag_recipe")
end


--- Initializes the drag operation by saving the start position and control name
--- This function is called at the start of a drag interaction
---@param mapargs table The event arguments containing context and event data
function CBCheckDragStartML(mapargs)
  local data = { hidden = 0 } 
  
  for i=1, 7 do
    data[string.format("Layer_MultiLevel.bkg_Level_%d.alpha%d",i,i)] = 0
  end
  
  gre.set_data(data)
  gLastPressedControl = mapargs.context_control
  local ev_data = mapargs.context_event_data;
  gStartYposition = ev_data.y
  gStartXposition = ev_data.x
end

--- Stops the table scrolling by resetting the control attributes
--- This function ensures the table scroll is disabled when not needed
---@param mapargs table The event arguments containing context and event data
function CBStopScrollTable(mapargs)
  gLastPressedControl = nil
  uncopiedFlag = 0
end

function CBReleaseTableML(mapargs)
  gLastPressedControl = nil
  uncopiedFlag = 0
  ClearCopyCellData()
  HighlightLevel(0)
  
end

--- Clear the alert message for a specific level.
-- This function clears the alert message for the specified level.
-- @param level The level to clear the alert for.
function CBClearAlert(level)
    local data = { hidden = 1 } -- Assuming hidden = 1 clears the alert
    local strname = string.format("Layer_Pop_ups.icon_level_ready_%d", level)

    gre.set_group_attrs(strname, data) -- Clear window discharge level message
    data[string.format("Layer_MultiLevel.bkg_Level_%d.alpha%d",level,level)] = 0
    gre.set_data(data)
end

--- Reset all levels to their initial state.
-- This function resets the time and alert status for all levels in the oven
function CBResetAllLevels()
    for i=1, 7 do
       CBClearAlert(i)
    end
    logger.info("All levels cleared.")
end


--- Clear all MultiLevel cart data
function CBClearMLCart()
  local data = {}
  for i=1, 7 do
    --data[string.format("Layer_MultiLevel.Data_Level_%d.icon.img",i)] = nil 
    data[string.format("Layer_MultiLevel.Data_Level_%d.text_name.data",i)] = " "
    data[string.format("Layer_MultiLevel.Data_Level_%d.text_time.data",i)] = " "  
    data[string.format("Layer_MultiLevel.Data_Level_%d.bar_progress.percent",i)] = -405
  end

  data["Layer_MultiLevel.icon_PlayML.alpha"] = 0
  gre.set_group_attrs("Layer_Pop_ups.icon_preheat_ML",hidden_on)  --Set Window discharge level msg    
  gre.set_data(data)
  ClearCopyCellData()
  CBResetAllLevels()
  HighlightLevel(0)
  uncopiedFlag = 0
  gindexStep = 1
  ClearStepTable()
end

