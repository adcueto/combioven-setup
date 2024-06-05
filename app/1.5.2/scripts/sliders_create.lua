--[[
Copyright 2021, Pro-Servicios SA de CV.
All Rights Reserved.
Control sliders for press and read data encoder on Add_New_Recipe/Programming mode
====================    ==========================================    ========================
|| Sliders_Create || -> ||Backend notification-PowerPCB feedback|| -> ||callbacks shows data|| 
====================    ==========================================    ========================
For more information email humberto.rodriguez@pro-servicios.com
** Author: Humberto Rodriguez **
]]--

local SLIDER_MAX_CREATE = 505
local BAR_COLOR_MAXWIDTH = 510
local BALL_WIDTH = 40
local gActiveSlider = nil
local gTarget_Probe = 0
encoder_options = {}


function SetBarCreateSlider(cur_value,slider_ID)
  local data = {}
  local width = math.ceil((cur_value * BAR_COLOR_MAXWIDTH)/MAX_TICKS)
  local name_str = string.format("Layer_Sliders_Edit.Slider_%d_Color.grd_width", slider_ID) 
  data[name_str] = width
  gre.set_data(data)
end


function UpdateCreateSlider(cur_value,slider_ID)
  local data={}
  local new_x
  local name_str_ball
  local name_str_color
  
  if    (slider_ID == 2) then
    new_x = math.ceil(((cur_value - 30) / MAX_TEMP) * (SLIDER_MAX_CREATE - SLIDER_MIN))
    data[string.format("Layer_Sliders_Edit.Slider_%d_Text.percent",slider_ID)] = string.format("%d°C", cur_value) 
     
  elseif(slider_ID == 3) then
    new_x = math.ceil((cur_value / MAX_TIME) * (SLIDER_MAX_CREATE - SLIDER_MIN))
    data[string.format("Layer_Sliders_Edit.Slider_%d_Text.percent",slider_ID)] = string.format("%.2d:%.2d m:s", cur_value/60, cur_value%60)
    
  else
    new_x = (cur_value * BAR_COLOR_MAXWIDTH)/MAX_TICKS
    data[string.format("Layer_Sliders_Edit.Slider_%d_Text.percent",slider_ID)] = string.format('%d%%', cur_value)
    
  end
  
  name_str_ball  = string.format("Layer_Sliders_Edit.Slider_%d_Ball.edit_slider_offset", slider_ID)
  name_str_color = string.format("Layer_Sliders_Edit.Slider_%d_Color.grd_width", slider_ID) 
  data[name_str_color] = new_x
  data[name_str_ball] = new_x
  gre.set_data(data)
end


function CreateCalcSliderPosition(mapargs)
  local press_x = mapargs.context_event_data.x
  local control = gre.get_control_attrs(mapargs.context_control,"x")
  local new_x = press_x - control["x"] - (BALL_WIDTH/2)
  encoder_options["data"] = 0
  encoder_options["parameter"] = 0
   
  if (new_x < SLIDER_MIN) then
    new_x = SLIDER_MIN
  elseif new_x > SLIDER_MAX_CREATE then
    new_x = SLIDER_MAX_CREATE
  end

  local percent_num = math.ceil((new_x /(SLIDER_MAX_CREATE - SLIDER_MIN)) * MAX_TICKS)
  local slider_num  = gre.get_value(mapargs.context_control..".edit_slider_num")
  local name_str = string.format("Layer_Sliders_Edit.Slider_%d_Text.percent", slider_num)
  local data = {}
  
  if (slider_num == 1) then
    data[name_str] = string.format('%d%%', percent_num)
    createRecipe[nowIndxRecipe].humidity = percent_num
    encoder_options.data = percent_num
    encoder_options.parameter = slider_num
    CBUpdateEncoderOptions(0,100,encoder_options.data,1,6)

  elseif (slider_num == 2) then
    MAX_TEMP   = gre.get_value("Layer_Sliders_Edit.Slider_2_Text.max_temp")
    local temper_target = math.ceil(((new_x / (SLIDER_MAX_CREATE - SLIDER_MIN)) * MAX_TEMP)+30)
    data[name_str] = string.format('%d°C', temper_target)
    createRecipe[nowIndxRecipe].tempmax = temper_target
    encoder_options.data = temper_target
    encoder_options.parameter = slider_num
    CBUpdateEncoderOptions(30,MAX_TEMP+30,encoder_options.data,1,6)

  elseif (slider_num == 3) then 
    local get_time = math.ceil((new_x / (SLIDER_MAX_CREATE - SLIDER_MIN)) * MAX_TIME)
    data[name_str] = string.format('%.2d:%.2d m:s', get_time/60, get_time%60) -- min:sec
    createRecipe[nowIndxRecipe].time = get_time
    if(get_time>0)then --Active Save Button on Settings_Bar
      gre.set_value("Layer_SettingsBar.bkg_Save.grd_active",1)
      gre.set_value("Layer_SettingsBar.icon_Save.pressed_key",255)
    end
    encoder_options.data = get_time
    encoder_options.parameter = slider_num
    CBUpdateEncoderOptions(0,10800,encoder_options.data,1,6)
       
  elseif (slider_num == 4) then 
     if (  percent_num >= 0  and  percent_num <= 25 ) then
      percent_num = 25
      new_x = 136
    elseif ( percent_num > 25 and percent_num <= 50 ) then
      percent_num = 50
      new_x = 272
    elseif (percent_num > 50 and percent_num <= 75) then
      percent_num = 75
      new_x = 408
    elseif (percent_num > 75 and percent_num <= 100) then
      percent_num = 100
      new_x = 544
    end
    data[name_str] = string.format('%d%%', percent_num)
    createRecipe[nowIndxRecipe].speed = percent_num
    encoder_options.data = percent_num
    encoder_options.parameter = slider_num
    CBUpdateEncoderOptions(25,100,encoder_options.data,25,6)
    
  end
  gre.set_value(mapargs.context_control..".edit_slider_offset", new_x)
  gre.set_data(data)
  SetBarCreateSlider(percent_num,slider_num)
end

-- Esto ocurre cuando se presiona un slider de la ventana de ajustes
function CBCreateSliderPress(mapargs)
	gActiveSlider = mapargs.context_control
	CreateCalcSliderPosition(mapargs)
end


function CBCreateSliderMotion(mapargs)
	if (gActiveSlider == nil) then
		return
	end
	
	if (gActiveSlider == mapargs.context_control) then
		CreateCalcSliderPosition(mapargs)
	end
end


function CBCreateSliderRelease(mapargs)
	gActiveSlider = nil	
end



function CBDisplayDataEncoder(feedbackData)
  if(encoder_options.parameter == 1) then
    createRecipe[nowIndxRecipe].humidity = feedbackData
  elseif(encoder_options.parameter == 2) then
    createRecipe[nowIndxRecipe].tempmax = feedbackData 
  elseif(encoder_options.parameter == 3) then
    createRecipe[nowIndxRecipe].time = feedbackData
  elseif(encoder_options.parameter == 4) then
    createRecipe[nowIndxRecipe].speed = feedbackData
  else return
  end
  UpdateCreateSlider(feedbackData,encoder_options.parameter)
end



function ShowDataCreateSlider()
    local mode
    local percent_num
    local name_str
    local data = {}
    
    mode = createRecipe[nowIndxRecipe].mode
    if(mode == 'convection')then
      gre.set_value("Layer_Mode_Select.bkg_Heather_on.pressed_key",255)
      gre.set_value("Layer_Mode_Select.bkg_Combined_on.pressed_key",0)
      gre.set_value("Layer_Mode_Select.bkg_Steam_on.pressed_key",0)
      gre.set_value("Layer_Options_Edit.bkg_Action_Btn.pressed_key",0)
      data["Layer_Options_Edit.bkg_OverlaySliders.grd_hidden"] = 1
      
    elseif(mode == 'combined')then
      gre.set_value("Layer_Mode_Select.bkg_Heather_on.pressed_key",0)
      gre.set_value("Layer_Mode_Select.bkg_Combined_on.pressed_key",255)
      gre.set_value("Layer_Mode_Select.bkg_Steam_on.pressed_key",0)
      gre.set_value("Layer_Options_Edit.bkg_Action_Btn.pressed_key",0)
      data["Layer_Options_Edit.bkg_OverlaySliders.grd_hidden"] = 1
      
    elseif(mode == 'steam')then
      gre.set_value("Layer_Mode_Select.bkg_Heather_on.pressed_key",0)
      gre.set_value("Layer_Mode_Select.bkg_Combined_on.pressed_key",0)
      gre.set_value("Layer_Mode_Select.bkg_Steam_on.pressed_key",255)
      gre.set_value("Layer_Options_Edit.bkg_Action_Btn.pressed_key",0)  
      data["Layer_Options_Edit.bkg_OverlaySliders.grd_hidden"] = 1
    
    else
      gre.set_value("Layer_Mode_Select.bkg_Heather_on.pressed_key",0)
      gre.set_value("Layer_Mode_Select.bkg_Combined_on.pressed_key",0)
      gre.set_value("Layer_Mode_Select.bkg_Steam_on.pressed_key",0)
      gre.set_value("Layer_Options_Edit.bkg_Action_Btn.pressed_key",255)
      data["Layer_Options_Edit.bkg_OverlaySliders.grd_hidden"] = 0
    end
    
    ---Print Color and Ball Slider HUMIDITY
    percent_num = createRecipe[nowIndxRecipe].humidity
    UpdateCreateSlider(percent_num,1)
    
    ---Print Color and Ball Slider TEMPERATURE
    percent_num = createRecipe[nowIndxRecipe].tempmax
    UpdateCreateSlider(percent_num,2)
    
    ---Print Color and Ball Slider TIME
    percent_num = createRecipe[nowIndxRecipe].time
    UpdateCreateSlider(percent_num,3)
    
    ---Print Color and Ball Slider SPEED
    percent_num = createRecipe[nowIndxRecipe].speed
    UpdateCreateSlider(percent_num,4)
    
    gre.set_data(data) 
end


--- @param gre#context mapargs
function CBCreateEnableEncoder(mapargs)
   local selectedParam
   local min_value
   local max_value
   local step_value = 0
   
   if    (mapargs.context_control == 'Layer_Options_Edit.bkg_SelSteam' ) then
    selectedParam = 1
    min_value = 0
    max_value = 100
    step_value = 1
    encoder_options.data = createRecipe[nowIndxRecipe].humidity
    
  elseif (mapargs.context_control == 'Layer_Options_Edit.bkg_SelTemp' ) then
    selectedParam = 2
    min_value = 30
    max_value = MAX_TEMP+30
    step_value = 1
    encoder_options.data = createRecipe[nowIndxRecipe].tempmax
    
  elseif (mapargs.context_control == 'Layer_Options_Edit.bkg_SelTime' ) then
    selectedParam = 3
    min_value = 0
    max_value = 10800
    step_value = 1
    encoder_options.data = createRecipe[nowIndxRecipe].time
    
  elseif (mapargs.context_control == 'Layer_Options_Edit.bkg_SelFan' ) then
    selectedParam = 4
    min_value = 25
    max_value = 100
    step_value = 25
    encoder_options.data = createRecipe[nowIndxRecipe].speed
    
  end
  
  if(encoder_options.data ~= nil) then
    encoder_options.parameter = selectedParam
    CBUpdateEncoderOptions(min_value,max_value,encoder_options.data,step_value,6)
  else 
    encoder_options["data"] = min_value
    encoder_options["parameter"] = selectedParam
    CBUpdateEncoderOptions(min_value,max_value,encoder_options.data,step_value,6)
  end
end
