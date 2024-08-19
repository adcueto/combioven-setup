--[[
Copyright 2021, Pro-Servicios SA de CV.
All Rights Reserved.
For more information email humberto.rodriguez@pro-servicios.com
** Author: Humberto Rodriguez **
]]--
local logger = require("components.logger")

gToggleCreateState = {} -- table used to track state for all toggles
lastToggleControl = nil
getUserAction = nil
getUserSubType = nil

function CBToggleCreateControl(mapargs) 
  local alpha_value
  local control = mapargs.context_control
  local data = {}
  
  if (gToggleCreateState[control] == nil) then
    -- if it doesn't exisit yet create the toggle and set it to off
    gToggleCreateState[control] = 0
    alpha_value=0

  end
  
  if (gToggleCreateState[control] ~= nil and gToggleCreateState[control] == 1) then
    gToggleCreateState[control] = 0
    alpha_value=0
    data = {}  
    data["Layer_Options_Edit.bkg_OverlaySliders.grd_hidden"] = 1
    gre.set_data(data)
  
  elseif (gToggleCreateState[control] ~= nil and gToggleCreateState[control] == 0) then
    gToggleCreateState[control] = 1
    createRecipe[nowIndxRecipe].time = 0 
    alpha_value=150
  end
    
  if (mapargs.context_control == 'Layer_Options_Edit.bkg_Preheat_Btn') then
    gre.set_value("Layer_Options_Edit.bkg_Preheat_Btn.pressed_key", alpha_value)
    gre.set_value("Layer_Sliders_Edit.Slider_3_Ball.edit_slider_offset", 0)
    gre.set_value("Layer_Sliders_Edit.Slider_3_Text.percent","Precal.")
    SetBarCreateSlider(0,3)
    
    
  elseif (mapargs.context_control == 'Layer_PopUp_Action.bkg_Score') then 
    gre.set_value("Layer_PopUp_Action.bkg_Brush.press_btn", 0)
    gre.set_value("Layer_PopUp_Action.bkg_Load.press_btn", 0)
    gre.set_value("Layer_PopUp_Action.bkg_Add_Ingredient.press_btn", 0)
    gre.set_value("Layer_PopUp_Action.bkg_Add_Liquid.press_btn", 0)
    gre.set_value("Layer_PopUp_Action.bkg_Score.press_btn", alpha_value)
    getUserAction = "carve"
  
  elseif (mapargs.context_control == 'Layer_PopUp_Action.bkg_Brush') then
    gre.set_value("Layer_PopUp_Action.bkg_Score.press_btn", 0)
    gre.set_value("Layer_PopUp_Action.bkg_Load.press_btn", 0)
    gre.set_value("Layer_PopUp_Action.bkg_Add_Ingredient.press_btn", 0)
    gre.set_value("Layer_PopUp_Action.bkg_Add_Liquid.press_btn", 0)
    gre.set_value("Layer_PopUp_Action.bkg_Brush.press_btn", alpha_value)
    getUserAction = "brush"
    
  elseif (mapargs.context_control == 'Layer_PopUp_Action.bkg_Load') then
    gre.set_value("Layer_PopUp_Action.bkg_Score.press_btn", 0)
    gre.set_value("Layer_PopUp_Action.bkg_Brush.press_btn", 0)
    gre.set_value("Layer_PopUp_Action.bkg_Add_Ingredient.press_btn", 0)
    gre.set_value("Layer_PopUp_Action.bkg_Add_Liquid.press_btn", 0)
    gre.set_value("Layer_PopUp_Action.bkg_Load.press_btn", alpha_value)
    getUserAction = "load"
    
  elseif (mapargs.context_control == 'Layer_PopUp_Action.bkg_Add_Ingredient') then
    gre.set_value("Layer_PopUp_Action.bkg_Score.press_btn", 0)
    gre.set_value("Layer_PopUp_Action.bkg_Brush.press_btn", 0)
    gre.set_value("Layer_PopUp_Action.bkg_Load.press_btn", 0)
    gre.set_value("Layer_PopUp_Action.bkg_Add_Liquid.press_btn", 0)
    gre.set_value("Layer_PopUp_Action.bkg_Add_Ingredient.press_btn", alpha_value)
    getUserAction = "addingredient"
    
  elseif (mapargs.context_control == 'Layer_PopUp_Action.bkg_Add_Liquid') then
    gre.set_value("Layer_PopUp_Action.bkg_Score.press_btn", 0)
    gre.set_value("Layer_PopUp_Action.bkg_Brush.press_btn", 0)
    gre.set_value("Layer_PopUp_Action.bkg_Load.press_btn", 0)
    gre.set_value("Layer_PopUp_Action.bkg_Add_Ingredient.press_btn", 0)
    gre.set_value("Layer_PopUp_Action.bkg_Add_Liquid.press_btn", alpha_value)
    getUserAction = "addliquid"
    
  elseif (mapargs.context_control == 'Layer_PopUp_Action.bkg_Check') then
    gre.set_value("Layer_PopUp_Action.bkg_Check.press_btn", alpha_value)
    data["hidden"] = 1
    gre.set_layer_attrs("Layer_PopUp_Action",data)  
    gre.set_value("Layer_PopUp_Action.bkg_Check.press_btn",0)
    gre.set_value("Layer_Options_Edit.bkg_Action_Btn.pressed_key",255)
    data = {}  
    data["Layer_Options_Edit.bkg_OverlaySliders.grd_hidden"] = 0
    gre.set_data(data)
    createRecipe[nowIndxRecipe].mode = getUserAction
    createRecipe[nowIndxRecipe].tempmax = 0
    createRecipe[nowIndxRecipe].speed   = 0 
  else return  
  end
  
  if(lastToggleControl ~= nil and lastToggleControl ~= 'Layer_Options_Edit.bkg_Preheat_Btn') then
    gToggleCreateState[lastToggleControl] = 0
  end
  lastToggleControl = control

end



function CBToggleMLSubtype(mapargs)
  local alpha_value
  local control = mapargs.context_control
  local data = {}
  local timeValue = createRecipe[nowIndxRecipe].time
  
  if (gToggleCreateState[control] == nil) then
    -- if it doesn't exisit yet create the toggle and set it to off
    gToggleCreateState[control] = 0
    alpha_value=0

  end
  
  if (gToggleCreateState[control] ~= nil and gToggleCreateState[control] == 1) then
    gToggleCreateState[control] = 0
    alpha_value=0
    
  elseif (gToggleCreateState[control] ~= nil and gToggleCreateState[control] == 0) then
    gToggleCreateState[control] = 1
    alpha_value=250

  end
  
  if(mapargs.context_control == 'Layer_Kind_Box.Bkg_kind_meat') then
    gre.set_value("Layer_Kind_Box.Bkg_kind_meat.press_btn", alpha_value)
    gre.set_value("Layer_Kind_Box.Bkg_kind_birds.press_btn", 0)
    gre.set_value("Layer_Kind_Box.Bkg_kind_eggs.press_btn", 0)
    gre.set_value("Layer_Kind_Box.Bkg_kind_grill.press_btn", 0)
    gre.set_value("Layer_Kind_Box.Bkg_kind_reheat.press_btn", 0)
    gre.set_value("Layer_Kind_Box.Bkg_kind_bakery.press_btn", 0)
    gre.set_value("Layer_Kind_Box.Bkg_kind_fish.press_btn", 0)
    gre.set_value("Layer_Kind_Box.Bkg_kind_vegetables.press_btn", 0)
    getUserSubType = 'Carne'
  
  elseif (mapargs.context_control == 'Layer_Kind_Box.Bkg_kind_birds') then
    gre.set_value("Layer_Kind_Box.Bkg_kind_birds.press_btn", alpha_value)
    gre.set_value("Layer_Kind_Box.Bkg_kind_meat.press_btn", 0)
    gre.set_value("Layer_Kind_Box.Bkg_kind_eggs.press_btn", 0)
    gre.set_value("Layer_Kind_Box.Bkg_kind_grill.press_btn", 0)
    gre.set_value("Layer_Kind_Box.Bkg_kind_reheat.press_btn", 0)
    gre.set_value("Layer_Kind_Box.Bkg_kind_bakery.press_btn", 0)
    gre.set_value("Layer_Kind_Box.Bkg_kind_fish.press_btn", 0)
    gre.set_value("Layer_Kind_Box.Bkg_kind_vegetables.press_btn", 0)
    getUserSubType = 'Aves'
        
  elseif (mapargs.context_control == 'Layer_Kind_Box.Bkg_kind_eggs') then
    gre.set_value("Layer_Kind_Box.Bkg_kind_birds.press_btn", 0)
    gre.set_value("Layer_Kind_Box.Bkg_kind_meat.press_btn", 0)
    gre.set_value("Layer_Kind_Box.Bkg_kind_eggs.press_btn", alpha_value)
    gre.set_value("Layer_Kind_Box.Bkg_kind_grill.press_btn", 0)
    gre.set_value("Layer_Kind_Box.Bkg_kind_reheat.press_btn", 0)
    gre.set_value("Layer_Kind_Box.Bkg_kind_bakery.press_btn", 0)
    gre.set_value("Layer_Kind_Box.Bkg_kind_fish.press_btn", 0)
    gre.set_value("Layer_Kind_Box.Bkg_kind_vegetables.press_btn", 0)
    getUserSubType = 'Huevo'
        
  elseif (mapargs.context_control == 'Layer_Kind_Box.Bkg_kind_vegetables') then
    gre.set_value("Layer_Kind_Box.Bkg_kind_birds.press_btn", 0)
    gre.set_value("Layer_Kind_Box.Bkg_kind_meat.press_btn", 0)
    gre.set_value("Layer_Kind_Box.Bkg_kind_eggs.press_btn", 0)
    gre.set_value("Layer_Kind_Box.Bkg_kind_grill.press_btn", 0)
    gre.set_value("Layer_Kind_Box.Bkg_kind_reheat.press_btn", 0)
    gre.set_value("Layer_Kind_Box.Bkg_kind_bakery.press_btn", 0)
    gre.set_value("Layer_Kind_Box.Bkg_kind_fish.press_btn", 0)
    gre.set_value("Layer_Kind_Box.Bkg_kind_vegetables.press_btn", alpha_value)
    getUserSubType = 'Guarniciones'
    
  elseif (mapargs.context_control == 'Layer_Kind_Box.Bkg_kind_grill') then
    gre.set_value("Layer_Kind_Box.Bkg_kind_birds.press_btn", 0)
    gre.set_value("Layer_Kind_Box.Bkg_kind_meat.press_btn", 0)
    gre.set_value("Layer_Kind_Box.Bkg_kind_eggs.press_btn", 0)
    gre.set_value("Layer_Kind_Box.Bkg_kind_grill.press_btn", alpha_value)
    gre.set_value("Layer_Kind_Box.Bkg_kind_reheat.press_btn", 0)
    gre.set_value("Layer_Kind_Box.Bkg_kind_bakery.press_btn", 0)
    gre.set_value("Layer_Kind_Box.Bkg_kind_fish.press_btn", 0)
    gre.set_value("Layer_Kind_Box.Bkg_kind_vegetables.press_btn", 0)
    getUserSubType = 'Grill'
    
  elseif (mapargs.context_control == 'Layer_Kind_Box.Bkg_kind_reheat') then
    gre.set_value("Layer_Kind_Box.Bkg_kind_birds.press_btn", 0)
    gre.set_value("Layer_Kind_Box.Bkg_kind_meat.press_btn", 0)
    gre.set_value("Layer_Kind_Box.Bkg_kind_eggs.press_btn", 0)
    gre.set_value("Layer_Kind_Box.Bkg_kind_grill.press_btn", 0)
    gre.set_value("Layer_Kind_Box.Bkg_kind_reheat.press_btn", alpha_value)
    gre.set_value("Layer_Kind_Box.Bkg_kind_bakery.press_btn", 0)
    gre.set_value("Layer_Kind_Box.Bkg_kind_fish.press_btn", 0)
    gre.set_value("Layer_Kind_Box.Bkg_kind_vegetables.press_btn", 0)
    getUserSubType = 'Reheat'
  
  elseif (mapargs.context_control == 'Layer_Kind_Box.Bkg_kind_bakery') then
    gre.set_value("Layer_Kind_Box.Bkg_kind_birds.press_btn", 0)
    gre.set_value("Layer_Kind_Box.Bkg_kind_meat.press_btn", 0)
    gre.set_value("Layer_Kind_Box.Bkg_kind_eggs.press_btn", 0)
    gre.set_value("Layer_Kind_Box.Bkg_kind_grill.press_btn", 0)
    gre.set_value("Layer_Kind_Box.Bkg_kind_reheat.press_btn", 0)
    gre.set_value("Layer_Kind_Box.Bkg_kind_bakery.press_btn", alpha_value)
    gre.set_value("Layer_Kind_Box.Bkg_kind_fish.press_btn", 0)
    gre.set_value("Layer_Kind_Box.Bkg_kind_vegetables.press_btn", 0)
    getUserSubType = 'Panaderia'
    
  elseif (mapargs.context_control == 'Layer_Kind_Box.Bkg_kind_fish') then
    gre.set_value("Layer_Kind_Box.Bkg_kind_birds.press_btn", 0)
    gre.set_value("Layer_Kind_Box.Bkg_kind_meat.press_btn", 0)
    gre.set_value("Layer_Kind_Box.Bkg_kind_eggs.press_btn", 0)
    gre.set_value("Layer_Kind_Box.Bkg_kind_grill.press_btn", 0)
    gre.set_value("Layer_Kind_Box.Bkg_kind_reheat.press_btn", 0)
    gre.set_value("Layer_Kind_Box.Bkg_kind_bakery.press_btn", 0)
    gre.set_value("Layer_Kind_Box.Bkg_kind_fish.press_btn", alpha_value)
    gre.set_value("Layer_Kind_Box.Bkg_kind_vegetables.press_btn", 0)
    getUserSubType = 'Pescado'
    
  end
  
  if timeValue > 0 then 
    ShowSaveButton()
  end
  
  if(gToggleCreateState[lastToggleControl] ~= nil) then
    gToggleCreateState[lastToggleControl] = 0 
  end
  lastToggleControl = control
end



