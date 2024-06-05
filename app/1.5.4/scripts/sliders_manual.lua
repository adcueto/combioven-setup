--[[
Copyright 2021, Pro-Servicios SA de CV.
All Rights Reserved.
Control sliders for press and read data encoder on Manual mode operation
====================    ==========================================    ========================
|| Sliders_manual || -> ||Backend notification-PowerPCB feedback|| -> ||callbacks shows data|| 
====================    ==========================================    ========================
For more information email humberto.rodriguez@pro-servicios.com
** Author: Humberto Rodriguez **
]]--


local BALL_WIDTH = 40
local gActiveSlider = nil
local gTarget_Probe = 0


function SetBarSlider(cur_value, slider_number)
  local data = {}
  local width = math.ceil( (cur_value * SLIDER_MAX) / MAX_TICKS)
  local name_str = string.format("Layer_Combi_Levels.Combi_ColorSlider%d.grd_width",slider_number)
  data[name_str] = width
  gre.set_data(data)
end


function CalcSliderPosition(mapargs)
	local press_x = mapargs.context_event_data.x
	local control = gre.get_control_attrs(mapargs.context_control, "x")
	local new_x = press_x - control["x"] - (BALL_WIDTH/2)
	
	if (new_x < SLIDER_MIN) then
		new_x = SLIDER_MIN
	elseif new_x > SLIDER_MAX then
		new_x = SLIDER_MAX
	end	
	
  gre.set_value(mapargs.context_control..".slider_offset", new_x)
  
	local percent_num   = math.ceil((new_x / (SLIDER_MAX - SLIDER_MIN)) * MAX_TICKS)
	local slider_num    = gre.get_value(mapargs.context_control..".slider_num")
	local data = {}
	local name_str = string.format("Layer_Combi_Levels.Combi_TextSlider%d.percent", slider_num)
	
	--[[Slider Humedad]]--
	if (slider_num == 1) then
	  data[name_str] = string.format('%d%%', percent_num)
	  CBUpdateSteam(percent_num)
	  
  --[[Slider Temperatura]]--
  elseif (slider_num == 2) then
    MAX_TEMP   = gre.get_value("Layer_Combi_Levels.Combi_TextSlider2.max_temp")
    local temper_target = math.ceil(((new_x / (SLIDER_MAX - SLIDER_MIN)) * MAX_TEMP)+30)
    data[name_str] = string.format('%d°C', temper_target)
    gInitTemperature = 0                -- Variable to calc DeltaTemp for bar progress
    CBUpdateTemperature(temper_target)  -- se envia el evento al backend
  
  elseif (slider_num == 3) then 
    gTimeCooking = math.ceil((new_x / (SLIDER_MAX - SLIDER_MIN)) * MAX_TIME)
    local units = 0;  -- 0-> m:s   1->h:m
    hours_target =  gTimeCooking / 60
    mins_target  =  gTimeCooking % 60
    data[name_str] = string.format('%.2d:%.2d m:s', hours_target, mins_target) -- min:sec
    CBUpdateTime(gTimeCooking, units)
    
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
    gre.set_value(mapargs.context_control..".slider_offset", new_x)
    CBUpdateFanSpeed(percent_num)
  
  elseif ( slider_num == 5 ) then
    MAX_TEMP   = gre.get_value("Layer_Combi_Levels.Combi_TextSlider5.max_temp")
    gTarget_Probe = math.ceil(((new_x / (SLIDER_MAX - SLIDER_MIN)) * MAX_TEMP)+10)
    data[name_str] = string.format('%d°C', gTarget_Probe)
    CBUpdateTemperProbe(gTarget_Probe)
  end
  
  gre.set_value(mapargs.context_control..".slider_offset", new_x)
  gre.set_data(data)
  SetBarSlider(percent_num, slider_num)
end


function CBSliderPress(mapargs)
	gActiveSlider = mapargs.context_control
	CalcSliderPosition(mapargs)
end

function CBSliderMotion(mapargs)
	if (gActiveSlider == nil) then
		return
	end
	
	if (gActiveSlider == mapargs.context_control) then
		CalcSliderPosition(mapargs)
	end
end

function CBSliderRelease(mapargs)
	gActiveSlider = nil	
end


--[[
Funcion para obtener que icono se selecciono para informar al backend
---]]

function CBEnableEncoder(mapargs)
   local selectedParam
   
   if    (mapargs.context_control == 'Layer_Combi_Menu.bkg_SelSteam' or mapargs.context_control == 'Layer_Combi_Levels.Combi_BallSlider1' ) then
    selectedParam = 1
  elseif (mapargs.context_control == 'Layer_Combi_Menu.bkg_SelTemp' or mapargs.context_control == 'Layer_Combi_Levels.Combi_BallSlider2' ) then
    selectedParam = 2
  elseif (mapargs.context_control == 'Layer_Combi_Menu.bkg_SelTime' or mapargs.context_control == 'Layer_Combi_Levels.Combi_BallSlider3' ) then
    selectedParam = 3
  elseif (mapargs.context_control == 'Layer_Combi_Menu.bkg_SelFan' or mapargs.context_control == 'Layer_Combi_Levels.Combi_BallSlider4' ) then
    selectedParam = 4
  elseif (mapargs.context_control == 'Layer_Combi_Levels.Combi_BallSlider5' ) then
    selectedParam = 5  --target_probe
  end
  
   gre.send_event_data(
   "enable_encoder", 
   "1u1 parameter",
   {parameter = selectedParam }, 
   gBackendChannel)
end




