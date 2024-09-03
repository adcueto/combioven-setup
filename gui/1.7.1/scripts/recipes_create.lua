--[[
Copyright 2021, Pro-Servicios SA de CV.
All Rights Reserved.
Get user data to Add_New_Recipe/Programming mode
initialize dynamic tables, calls to store on database and clear after use
====================     ==============
||InitNewStepRecipe|| -> ||AddNewStep|| 
====================     ==============
For more information email humberto.rodriguez@pro-servicios.com
** Author: Humberto Rodriguez **
]]--
local logger = require("components.logger")
local oven_state_service = require("services.oven_state_service")
local OvenEnums = require("components.oven_status_enums")

--createRecipe  = {}
createRecipe = createRecipe or {}
prevIndxRecipe = 1
nowIndxRecipe  = 1
typeRecipe = nil

function CBAddNewStep()
  local tab_data = {}
  local btn_data = {}
  encoder_options = {}
  
  nowIndxRecipe  = nowIndxRecipe  + 1 
  
  if(nowIndxRecipe <= 5) then
    tab_data["width"]  = 113 * nowIndxRecipe 
    tab_data["cols"]   = nowIndxRecipe 
    tab_data["x"]      = 343 - ((113 * (nowIndxRecipe -1))/2)
    gre.set_table_attrs("NewRecipeSteps",tab_data)
 
  
    btn_data["x"] = tab_data["x"] - 84
    gre.set_control_attrs("Layer_Actions_Phases.btn_Step_Less", btn_data)
    btn_data["x"] = (tab_data["width"]/2) + 56 + 343
    gre.set_control_attrs("Layer_Actions_Phases.btn_Step_Add", btn_data)
    btn_data["hidden"] = 1
    gre.set_control_attrs("Layer_Actions_Phases.btn_Step_Less.icon_Step_LessOff", btn_data)
  elseif(nowIndxRecipe >5 and nowIndxRecipe < 7)then
    tab_data["cols"]   = nowIndxRecipe
    tab_data["xoffset"]= -113
    gre.set_table_attrs("NewRecipeSteps",tab_data)
      
  elseif(nowIndxRecipe == 7)then
    tab_data["cols"]   = nowIndxRecipe
    tab_data["xoffset"]= -226
    gre.set_table_attrs("NewRecipeSteps",tab_data)
    --deshabilitar boton (+) 
    btn_data["x"] = 0
    btn_data["hidden"] = 0    
    gre.set_control_attrs("Layer_Actions_Phases.btn_Step_Add.icon_Step_AddOff", btn_data)
  end
  
  local dk_data = {}
  dk_data["Layer_Actions_Phases.NewRecipeSteps.txt.1."..nowIndxRecipe ] = string.format("%d",nowIndxRecipe )
  dk_data["Layer_Actions_Phases.NewRecipeSteps.bkstep.1."..nowIndxRecipe -1] = 0
  dk_data["Layer_Actions_Phases.NewRecipeSteps.bkstep.1."..nowIndxRecipe ] = 255
  dk_data["Layer_Options_Edit.bkg_OverlaySliders.grd_hidden"] = 1
  --dk_data["Layer_Actions_Phases.NewRecipeSteps.img." ..".1"..indxStep] = 'images/icon_num_step.png'
  gre.set_data(dk_data)
  gre.set_value("Layer_Options_Edit.bkg_Action_Btn.pressed_key",0)
  
  local data = {}
  data["mode"]      = ""
  data["humidity"]  = 0
  data["tempmax"]   = 0
  table.insert(createRecipe,data)
  prevIndxRecipe = nowIndxRecipe
end



function CBDeleteNewStep()
  local tab_data = {}
  local btn_data = {}
  table.remove(createRecipe,nowIndxRecipe)
  nowIndxRecipe  = nowIndxRecipe  - 1
  
  
  if(nowIndxRecipe == 6) then
    tab_data["xoffset"]= -113
    
  elseif(nowIndxRecipe >= 1 and nowIndxRecipe < 6) then 
    tab_data["width"]  = 113 * nowIndxRecipe  
    tab_data["x"]      = 343 - ((113 * (nowIndxRecipe -1))/2)
    btn_data["x"] = tab_data["x"] - 84
    gre.set_control_attrs("Layer_Actions_Phases.btn_Step_Less", btn_data)
    if(nowIndxRecipe == 1)then
      btn_data["x"] = 0
      btn_data["hidden"] = 0
      gre.set_control_attrs("Layer_Actions_Phases.btn_Step_Less.icon_Step_LessOff", btn_data)   
    elseif(nowIndxRecipe == 5)then
     tab_data["xoffset"]= 0
    end    
    btn_data["x"] = (tab_data["width"]/2) + 56 + 343
    gre.set_control_attrs("Layer_Actions_Phases.btn_Step_Add", btn_data)
  end
  
  tab_data["cols"]   = nowIndxRecipe
  gre.set_table_attrs("NewRecipeSteps",tab_data)
  btn_data["hidden"] = 1
  gre.set_control_attrs("Layer_Actions_Phases.btn_Step_Add.icon_Step_AddOff", btn_data)
  
  local dk_data = {}
  dk_data["Layer_Actions_Phases.NewRecipeSteps.bkstep.1."..nowIndxRecipe ] = 255
  dk_data["Layer_Actions_Phases.NewRecipeSteps.bkstep.1."..prevIndxRecipe] = 0
  gre.set_data(dk_data)
  ShowDataCreateSlider() 
end

function CBSteNewStepHeater(mapargs)
  
  --if (isEditRecipeBook == false) then 
    local data_attributes = {}
    data_attributes["Layer_Sliders_Edit.Slider_1_Ball.edit_slider_offset"] = 0
    data_attributes["Layer_Sliders_Edit.Slider_1_Text.percent"] = "0%"
    data_attributes["Layer_Sliders_Edit.Slider_1_Color.grd_width"] = 12
    
    data_attributes["Layer_Sliders_Edit.Slider_2_Ball.edit_slider_offset"] = 0
    data_attributes["Layer_Sliders_Edit.Slider_2_Text.percent"] = "30°C"
    data_attributes["Layer_Sliders_Edit.Slider_2_Color.grd_width"] = 12
    data_attributes["Layer_Sliders_Edit.Slider_2_Text.max_temp"] = 270
     
    data_attributes["Layer_Sliders_Edit.Slider_3_Ball.edit_slider_offset"] = 0
    data_attributes["Layer_Sliders_Edit.Slider_3_Text.percent"] = "00:00 m:s"
    data_attributes["Layer_Sliders_Edit.Slider_3_Color.grd_width"] = 12
    
    data_attributes["Layer_Sliders_Edit.Slider_4_Ball.edit_slider_offset"] = 0
    data_attributes["Layer_Sliders_Edit.Slider_4_Text.percent"] = "25%"
    data_attributes["Layer_Sliders_Edit.Slider_4_Color.grd_width"] = 128
    --[[
    data_attributes["Layer_TopBar.IconMainMenu_Status.mode_status"] = "Convección"
    data_attributes["Crear_Receta_Manual.Layer_Options_Edit.grd_hidden"] = false 
    data_attributes["Crear_Receta_Manual.Layer_Sliders_Edit.grd_hidden"] = false 
    data_attributes["Layer_Mode_Select.bkg_Heather_on.pressed_key"] = 255
    data_attributes["Layer_Mode_Select.bkg_Steam.on.pressed_key"] = 0
    data_attributes["Layer_Mode_Select.bkg_Combined.on.pressed_key"] = 0
    data_attributes["Layer_Mode_Select.bkg_Overlay.grd_hidden"] = true
    ]]--
     gre.set_data(data_attributes)
  --end
 
end

function CBSteNewStepCombi(mapargs)

  --if (isEditRecipeBook == false) then 
    local data_attributes = {}
    data_attributes["Layer_Sliders_Edit.Slider_1_Ball.edit_slider_offset"] = 0
    data_attributes["Layer_Sliders_Edit.Slider_1_Text.percent"] = "0%"
    data_attributes["Layer_Sliders_Edit.Slider_1_Color.grd_width"] = 12
    
    data_attributes["Layer_Sliders_Edit.Slider_2_Ball.edit_slider_offset"] = 0
    data_attributes["Layer_Sliders_Edit.Slider_2_Text.percent"] = "30°C"
    data_attributes["Layer_Sliders_Edit.Slider_2_Color.grd_width"] = 12
    data_attributes["Layer_Sliders_Edit.Slider_2_Text.max_temp"] = 270
     
    data_attributes["Layer_Sliders_Edit.Slider_3_Ball.edit_slider_offset"] = 0
    data_attributes["Layer_Sliders_Edit.Slider_3_Text.percent"] = "00:00 m:s"
    data_attributes["Layer_Sliders_Edit.Slider_3_Color.grd_width"] = 12
    
    data_attributes["Layer_Sliders_Edit.Slider_4_Ball.edit_slider_offset"] = 0
    data_attributes["Layer_Sliders_Edit.Slider_4_Text.percent"] = "25%"
    data_attributes["Layer_Sliders_Edit.Slider_4_Color.grd_width"] = 128
    --[[
    data_attributes["Layer_TopBar.IconMainMenu_Status.mode_status"] = "Combinado"
    data_attributes["Crear_Receta_Manual.Layer_Options_Edit.grd_hidden"] = false 
    data_attributes["Crear_Receta_Manual.Layer_Sliders_Edit.grd_hidden"] = false 
    data_attributes["Layer_Mode_Select.bkg_Heather_on.pressed_key"] = 0
    data_attributes["Layer_Mode_Select.bkg_Steam.on.pressed_key"] = 0
    data_attributes["Layer_Mode_Select.bkg_Combined.on.pressed_key"] = 255
    data_attributes["Layer_Mode_Select.bkg_Overlay.grd_hidden"] = true
     ]]--
    gre.set_data(data_attributes)
  --end
end




function CBSteNewStepSteam(mapargs)
 
 -- if (isEditRecipeBook == false) then 
    local data_attributes = {}
    data_attributes["Layer_Sliders_Edit.Slider_1_Ball.edit_slider_offset"] = 495
    data_attributes["Layer_Sliders_Edit.Slider_1_Text.percent"] = "100%"
    data_attributes["Layer_Sliders_Edit.Slider_1_Color.grd_width"] = 495
    
    data_attributes["Layer_Sliders_Edit.Slider_2_Ball.edit_slider_offset"] = 270
    data_attributes["Layer_Sliders_Edit.Slider_2_Text.percent"] = "98°C"
    data_attributes["Layer_Sliders_Edit.Slider_2_Color.grd_width"] = 280
    data_attributes["Layer_Sliders_Edit.Slider_2_Text.max_temp"] = 105
    
    data_attributes["Layer_Sliders_Edit.Slider_3_Ball.edit_slider_offset"] = 0
    data_attributes["Layer_Sliders_Edit.Slider_3_Text.percent"] = "00:00 m:s"
    data_attributes["Layer_Sliders_Edit.Slider_3_Color.grd_width"] = 12
    
    data_attributes["Layer_Sliders_Edit.Slider_4_Ball.edit_slider_offset"] = 0
    data_attributes["Layer_Sliders_Edit.Slider_4_Text.percent"] = "25%"
    data_attributes["Layer_Sliders_Edit.Slider_4_Color.grd_width"] = 128
    --[[
    data_attributes["Layer_TopBar.IconMainMenu_Status.mode_status"] = "Vapor"
    data_attributes["Crear_Receta_Manual.Layer_Options_Edit.grd_hidden"] = false 
    data_attributes["Crear_Receta_Manual.Layer_Sliders_Edit.grd_hidden"] = false 
    data_attributes["Layer_Mode_Select.bkg_Heather_on.pressed_key"] = 0
    data_attributes["Layer_Mode_Select.bkg_Steam.on.pressed_key"] = 255
    data_attributes["Layer_Mode_Select.bkg_Combined.on.pressed_key"] = 0
    data_attributes["Layer_Mode_Select.bkg_Overlay.grd_hidden"] = true
    ]]--
    gre.set_data(data_attributes)
  --end
end

function CBInitNewStep(mapargs)

  if(mapargs.context_control == 'Layer_Mode_Select.bkg_Heather_on')then 
    MAX_TEMP   = gre.get_value("Layer_Sliders_Edit.Slider_2_Text.max_temp")
    createRecipe[nowIndxRecipe].mode     = "convection"
    createRecipe[nowIndxRecipe].humidity = 0
    createRecipe[nowIndxRecipe].tempmax  = 30
    logger.debug("TEMP MAX: ",MAX_TEMP )
  
  elseif(mapargs.context_control == 'Layer_Mode_Select.bkg_Combined_on')then
    MAX_TEMP   = gre.get_value("Layer_Sliders_Edit.Slider_2_Text.max_temp")
    createRecipe[nowIndxRecipe].mode     = "combined"
    createRecipe[nowIndxRecipe].humidity = 0
    createRecipe[nowIndxRecipe].tempmax  = 30
    logger.debug("TEMP MAX: ",MAX_TEMP )
    
  elseif(mapargs.context_control == 'Layer_Mode_Select.bkg_Steam_on')then
    MAX_TEMP   = gre.get_value("Layer_Sliders_Edit.Slider_2_Text.max_temp")
    createRecipe[nowIndxRecipe].mode     = "steam"
    createRecipe[nowIndxRecipe].humidity = 100
    createRecipe[nowIndxRecipe].tempmax  = 98
    logger.debug("TEMP MAX: ",MAX_TEMP)

  end 
  createRecipe[nowIndxRecipe].time  = 0
  createRecipe[nowIndxRecipe].speed = 25
  
  gre.send_event ("mode_recipe_"..createRecipe[nowIndxRecipe].mode, "combioven_backend")
end


function CBSelectRecipeStep()
  local dk_data = {}  
  local btn_data = {}
  dk_data = gre.get_table_attrs("NewRecipeSteps","active_row","active_col")
  logger.debug("Active Cell: " ..tostring(dk_data["active_row"]) ..","..tostring(dk_data["active_col"]))
  nowIndxRecipe  = dk_data["active_col"]
  if(nowIndxRecipe ~= prevIndxRecipe) then
    dk_data["Layer_Actions_Phases.NewRecipeSteps.bkstep.1."..nowIndxRecipe ] = 255
    dk_data["Layer_Actions_Phases.NewRecipeSteps.bkstep.1."..prevIndxRecipe] = 0
    gre.set_data(dk_data)
    ShowDataCreateSlider() 
    prevIndxRecipe = nowIndxRecipe
    if(nowIndxRecipe==1)then
      btn_data["x"] = 0
      btn_data["hidden"] = 0
      gre.set_control_attrs("Layer_Actions_Phases.btn_Step_Less.icon_Step_LessOff", btn_data)
    else      
      btn_data["x"] = 0
      btn_data["hidden"] = 1
      gre.set_control_attrs("Layer_Actions_Phases.btn_Step_Less.icon_Step_LessOff", btn_data)
    end 
  else
    return
  end
end


---
function CBInitNewRecipeTables(mapargs)
  
  typeRecipe = gre.get_value(mapargs.context_control..".typeRecipe") 
  createRecipe = {}
  if not isEditRecipeBook then
  
    if type(createRecipe) ~= "table" then
      logger.error("createRecipe no es una tabla")
    else
      local data = {}
      data["mode"]      = ""
      data["humidity"]  = 0
      data["tempmax"]   = 0
      table.insert(createRecipe,data)
    end
  end
  
  local tab_data = {}
  local btn_data = {}
  gToggleCreateState = {}
  tab_data["width"]  = 113 * nowIndxRecipe 
  tab_data["cols"]   = nowIndxRecipe 
  tab_data["x"]      = 343 - ((113 * (nowIndxRecipe -1))/2)
  gre.set_table_attrs("NewRecipeSteps",tab_data)
  
  btn_data["x"] = tab_data["x"] - 84
  gre.set_control_attrs("Layer_Actions_Phases.btn_Step_Less", btn_data)
  btn_data["x"] = (tab_data["width"]/2) + 56 + 343
  gre.set_control_attrs("Layer_Actions_Phases.btn_Step_Add", btn_data)
  btn_data["x"] = 0
  btn_data["hidden"] = 0
   
  if(typeRecipe == 'Manual')then
    gre.set_control_attrs("Layer_Actions_Phases.btn_Step_Less.icon_Step_LessOff", btn_data)
    gre.set_value("Layer_Options_Edit.bkg_Action_Btn.pressed_key",0)
    gre.set_value("Layer_Options_Edit.bkg_Preheat_Btn.pressed_key",0)
    gre.set_value("Layer_Mode_Select.bkg_Heather_on.pressed_key",0)
    gre.set_value("Layer_Mode_Select.bkg_Combined_on.pressed_key",0)
    gre.set_value("Layer_Mode_Select.bkg_Steam_on.pressed_key",0)
    gre.set_value("Layer_PopUp_Action.bkg_Score.press_btn",0)
    gre.set_value("Layer_PopUp_Action.bkg_Load.press_btn",0)
    gre.set_value("Layer_PopUp_Action.bkg_Add_Ingredient.press_btn",0)
    gre.set_value("Layer_PopUp_Action.bkg_Add_Liquid.press_btn",0)
    gre.set_value("Layer_PopUp_Action.bkg_Brush.press_btn",0)
  else
    gre.set_value("Layer_Kind_Box.Bkg_kind_birds.press_btn", 0)
    gre.set_value("Layer_Kind_Box.Bkg_kind_meat.press_btn", 0)
    gre.set_value("Layer_Kind_Box.Bkg_kind_eggs.press_btn", 0)
    gre.set_value("Layer_Kind_Box.Bkg_kind_grill.press_btn", 0)
    gre.set_value("Layer_Kind_Box.Bkg_kind_reheat.press_btn", 0)
    gre.set_value("Layer_Kind_Box.Bkg_kind_bakery.press_btn", 0)
    gre.set_value("Layer_Kind_Box.Bkg_kind_fish.press_btn", 0)
    gre.set_value("Layer_Kind_Box.Bkg_kind_vegetables.press_btn", 0)
  end
end


