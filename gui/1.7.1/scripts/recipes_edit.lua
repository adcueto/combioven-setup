--[[
Copyright 2021, Pro-Servicios SA de CV.
All Rights Reserved.
Get user data to Add_New_Recipe/Programming mode
initialize dynamic tables, calls to store on database and clear after use
====================     ==============
||CBEditRecipeBtn|| -> ||CBRecipePress|| ->
====================     ==============
For more information email humberto.rodriguez@pro-servicios.com
** Author: Jose Adrian PErez Cueto **
]]--
local logger = require("components.logger")
local oven_state_service = require("services.oven_state_service")
local OvenEnums = require("components.oven_status_enums")

local SLIDER_MAX_CREATE = 505
local BAR_COLOR_MAXWIDTH = 510
local BALL_WIDTH = 40

isRecipeBook = false --If the user entered the recipe book
isIntelligentRecipe =false
isManualRecipe = false

--[[  +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ ]]--
--[[  +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ ]]--
--[[  ****************************   START PROGRAM        **************************]]--
--[[  +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ ]]--
--[[  +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ ]]--
--- Start Program 
--- Load Recipe from Modo_Automatico/Intelligent/Multilevel on Main-screen selected
-- 
-- 
function CBLoadEditRecipe(mapargs)
  
  logger.info("Recipe edition") 
  isEditRecipeBook = true
  
  recipe_id = gre.get_value(mapargs.context_control..".recipe_id")
  typeRecipe = gre.get_value(mapargs.context_control..".recipe_type")
  
  gre.set_value("Layer_AutoProcess.icon_gotoProcess.grd_hidden", 1)  --hidden goto process
  gre.set_value("Layer_AutoProcess.bkg_gotoProcess.grd_active", 0) --hidden goto process
  gre.set_control_attrs("Layer_SettingsBar.bkg_Back", hidden_off)
  gre.set_value("Layer_SettingsBar.icon_Back.pressed_key", 255) --the button back is hidden 
  gre.set_value("Layer_SettingsBar.bkg_Back.grd_active", 1) -- the button back is active
  gre.set_value("Layer_SettingsBar.bkg_Back.PreviousScreen", mapargs.context_screen)
  
  
  if(typeRecipe == "Intelligent") then
   SwitchRecipe(recipe_id, "recipes_auto")
   CBDisplayRecipeSteps_Intelligent()

   gre.set_value("screenName", "Ajustes_Modo_Auto")
   gre.send_event("ScreenTransition")
     
         
  elseif(typeRecipe == "Manual")then
  
    gre.set_value("Layer_TopBar.IconMainMenu_Status.mode_status", "Edicion de receta Manual")
    gre.set_value("Crear_Receta_Manual.Layer_Options_Edit.grd_hidden", false)
    gre.set_value("Crear_Receta_Manual.Layer_Sliders_Edit.grd_hidden", false)
    gre.set_value("Crear_Receta_Manual.Layer_Kind_Box.grd_hidden",true)
    gre.set_value("Layer_Mode_Select.bkg_Overlay.grd_hidden", true)
    
    CBInitNewRecipeTables(mapargs)
    ShowManualSliderPosition(mapargs)
    SwitchRecipe_Manual(recipe_id)
    CBDisplayRecipeSteps_Manual() 
    
    gre.set_value("screenName", "Crear_Receta_Manual")
    gre.send_event("ScreenTransition")
    gre.set_value("Layer_EditRecipeOptions.bkg_Add_RecipeML.push_addmanual", 0)
    
   
  elseif(typeRecipe == "Multilevel")then
    --grd_hidden
    gre.set_value("Crear_Receta_Manual.Layer_Kind_Box.grd_hidden",0)
    gre.set_value("Layer_TopBar.IconMainMenu_Status.mode_status", "Edicion de receta Multinivel")
    gre.set_value("Crear_Receta_Manual.Layer_Options_Edit.grd_hidden", 0)
    gre.set_value("Crear_Receta_Manual.Layer_Sliders_Edit.grd_hidden", 1)
    gre.set_value("Layer_Mode_Select.bkg_Overlay.grd_hidden", 0)
    gre.set_value("Layer_EditRecipeOptions.bkg_Add_RecipeML.push_addML", 255)
    
    CBInitNewRecipeTables(mapargs)
    ShowManualSliderPosition(mapargs)
      
    gre.set_value("screenName", "Crear_Receta_Manual")
    gre.send_event("ScreenTransition")
    gre.set_value("Layer_EditRecipeOptions.bkg_Add_RecipeML.push_addML", 0)
    
  end
  
end


--- When the user selects a recipe from the list it prepare recipe options
function CBRecipePress(mapargs) 
    local data = {}
    isRecipeBook = true
    if (mapargs.context_screen == "Modo_Programacion") then
       -- the row that was pressed in the table
        gIndex = mapargs.context_row
        --print(gIndex)
        --gre.send_event("CONTACT_SCREEN")
        data["Layer_ListTable.RecipesListTable.img."..gPreviousIndex..".1"] = 'images/bar_list_recipes.png'
        data["Layer_ListTable.RecipesListTable.img."..gIndex..".1"] = 'images/bar_list_highlight.png'
        data["Layer_EditRecipeOptions.icon_Edit.recipe_id"]   = recipes_auto[gIndex].id
        data["Layer_EditRecipeOptions.icon_Edit.recipe_type"] = recipes_auto[gIndex].type
        data["Layer_EditRecipeOptions.icon_Play.recipe_id"]   = recipes_auto[gIndex].id
        data["Layer_EditRecipeOptions.icon_Play.recipe_type"] = recipes_auto[gIndex].type
        recipe_id = recipes_auto[gIndex].id
        gre.set_data(data)
        gPreviousIndex = gIndex
    end  
end

local function AddNewStep(nowIndxRecipe)
  local tab_data = {}
  local btn_data = {}
  encoder_options = {}
  
 
  if(nowIndxRecipe <= 5) then
    tab_data["width"]  = 113 * nowIndxRecipe 
    tab_data["cols"]   = nowIndxRecipe 
    tab_data["x"]      = 343 - ((113 * (nowIndxRecipe -1))/2)
    gre.set_table_attrs("Layer_Actions_Phases.NewRecipeSteps",tab_data)
 
  
    btn_data["x"] = tab_data["x"] - 84
    gre.set_control_attrs("Layer_Actions_Phases.btn_Step_Less", btn_data)
    btn_data["x"] = (tab_data["width"]/2) + 56 + 343
    gre.set_control_attrs("Layer_Actions_Phases.btn_Step_Add", btn_data)
    btn_data["hidden"] = 1
    gre.set_control_attrs("Layer_Actions_Phases.btn_Step_Less.icon_Step_LessOff", btn_data)
  elseif(nowIndxRecipe >5 and nowIndxRecipe < 7)then
    tab_data["cols"]   = nowIndxRecipe
    tab_data["xoffset"]= -113
    gre.set_table_attrs("Layer_Actions_Phases.NewRecipeSteps",tab_data)
      
  elseif(nowIndxRecipe == 7)then
    tab_data["cols"]   = nowIndxRecipe
    tab_data["xoffset"]= -226
    gre.set_table_attrs("Layer_Actions_Phases.NewRecipeSteps",tab_data)
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
  
  prevIndxRecipe = nowIndxRecipe
end


local function ShowToggleMLSubtype(subtype)
  local alpha_value = 250
  local buttons = {
    Carne = "Layer_Kind_Box.Bkg_kind_meat.press_btn",
    Aves = "Layer_Kind_Box.Bkg_kind_birds.press_btn",
    Huevo = "Layer_Kind_Box.Bkg_kind_eggs.press_btn",
    Guarniciones = "Layer_Kind_Box.Bkg_kind_vegetables.press_btn",
    Grill = "Layer_Kind_Box.Bkg_kind_grill.press_btn",
    Reheat = "Layer_Kind_Box.Bkg_kind_reheat.press_btn",
    Panaderia = "Layer_Kind_Box.Bkg_kind_bakery.press_btn",
    Pescado = "Layer_Kind_Box.Bkg_kind_fish.press_btn"
  }

  for buttonType, buttonID in pairs(buttons) do
    if subtype == buttonType then
      gre.set_value(buttonID, alpha_value)
      getUserSubType = subtype
      
    else
      gre.set_value(buttonID, 0)
    end
  end
end



function ShowManualSliderPosition(mapargs)
  
  local query, cur, row
  local data = {}
  local name,steps, type, subtype
    
  recipe_id = gre.get_value(mapargs.context_control..".recipe_id")
  typeRecipe = gre.get_value(mapargs.context_control..".recipe_type")
  createRecipe = {}
  
    
  if typeRecipe == "Manual" then
    query = string.format("SELECT * from recipes_manual WHERE id=%s",recipe_id)
    cur = db:execute(query)
    row = cur:fetch({}, "a")
    steps = tonumber(row.steps)
    name = row.name
    type = row.type
    data["name"]  = name
    data["type"]  = type
    data["steps"] = steps
    
  else
    query = string.format("SELECT * from recipes_multilevel WHERE id=%s",recipe_id)
    cur = db:execute(query)
    steps = 1
    row = cur:fetch({}, "a")
    name = row.name
    type = row.type
    subtype = row.subtype
    data["name"]  = name
    data["type"]  = type
    data["subtype"] = subtype
    getUserSubType = subtype
  end
  

  nowIndxRecipe = steps
  
  for i=1, steps do
    createRecipe[i] = {
      mode = row[string.format("s%d_mode", i)],
      humidity = tonumber(row[string.format("s%d_humidity", i)]),
      tempmax = tonumber(row[string.format("s%d_tempmax", i)]),
      time = tonumber(row[string.format("s%d_time", i)]),
      speed = tonumber(row[string.format("s%d_speed", i)])
    }
    if typeRecipe == "Manual" then
      AddNewStep(i)
    else 
      ShowToggleMLSubtype(subtype)
    end
  end
  
  table.insert(createRecipe,data)
  
  
  -- Actualizar sliders
  UpdateCreateSlider(createRecipe[nowIndxRecipe].humidity, 1)
  UpdateCreateSlider(createRecipe[nowIndxRecipe].tempmax, 2)
  UpdateCreateSlider(createRecipe[nowIndxRecipe].time, 3)
  UpdateCreateSlider(createRecipe[nowIndxRecipe].speed, 4)
   
  data = {}
  
  data["Layer_TopBar.IconMainMenu_Status.mode_status"] = type.."-"..name
  
  data["Crear_Receta_Manual.Layer_Options_Edit.grd_hidden"] = false 
  data["Crear_Receta_Manual.Layer_Sliders_Edit.grd_hidden"] = false 
  

  -- Configurar el modo de cocción
  local mode = createRecipe[nowIndxRecipe].mode
  local modes = {
    convection = {255, 0, 0, 0, 1},
    combined = {0, 255, 0, 0, 1},
    steam = {0, 0, 255, 0, 1},
  }

  if modes[mode] then
    gre.set_value("Layer_Mode_Select.bkg_Heather_on.pressed_key", modes[mode][1])
    gre.set_value("Layer_Mode_Select.bkg_Combined_on.pressed_key", modes[mode][2])
    gre.set_value("Layer_Mode_Select.bkg_Steam_on.pressed_key", modes[mode][3])
    gre.set_value("Layer_Options_Edit.bkg_Action_Btn.pressed_key", modes[mode][4])
    data["Layer_Options_Edit.bkg_OverlaySliders.grd_hidden"] = modes[mode][5]
  else
    gre.set_value("Layer_Mode_Select.bkg_Heather_on.pressed_key", 0)
    gre.set_value("Layer_Mode_Select.bkg_Combined_on.pressed_key", 0)
    gre.set_value("Layer_Mode_Select.bkg_Steam_on.pressed_key", 0)
    gre.set_value("Layer_Options_Edit.bkg_Action_Btn.pressed_key", 255)
    data["Layer_Options_Edit.bkg_OverlaySliders.grd_hidden"] = 0
  end

  data["Layer_Mode_Select.bkg_Overlay.grd_hidden"] = true
  gre.set_data(data)
  
end









