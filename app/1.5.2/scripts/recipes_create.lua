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

createRecipe  = {}
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



function CBInitNewStep(mapargs)
  if(mapargs.context_control == 'Layer_Mode_Select.bkg_Heather_on')then 
    createRecipe[nowIndxRecipe].mode     = "convection"
    createRecipe[nowIndxRecipe].humidity = 0
    createRecipe[nowIndxRecipe].tempmax  = 30
  
  elseif(mapargs.context_control == 'Layer_Mode_Select.bkg_Combined_on')then
    createRecipe[nowIndxRecipe].mode     = "combined"
    createRecipe[nowIndxRecipe].humidity = 0
    createRecipe[nowIndxRecipe].tempmax  = 30
    
  elseif(mapargs.context_control == 'Layer_Mode_Select.bkg_Steam_on')then
    createRecipe[nowIndxRecipe].mode     = "steam"
    createRecipe[nowIndxRecipe].humidity = 100
    createRecipe[nowIndxRecipe].tempmax  = 98
    --MAX_TEMP = 138
  end 
  createRecipe[nowIndxRecipe].time  = 0
  createRecipe[nowIndxRecipe].speed = 25
end


function CBSelectRecipeStep()
  local dk_data = {}  
  local btn_data = {}
  dk_data = gre.get_table_attrs("NewRecipeSteps","active_row","active_col")
  --print("Active Cell: " ..tostring(dk_data["active_row"]) ..","..tostring(dk_data["active_col"]))
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
  local data = {}
  data["mode"]      = ""
  data["humidity"]  = 0
  data["tempmax"]   = 0
  table.insert(createRecipe,data)
  
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
  typeRecipe = gre.get_value(mapargs.context_control..".typeRecipe")  
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


