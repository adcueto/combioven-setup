--[[
Copyright 2021, Pro-Servicios SA de CV.
All Rights Reserved.
For more information email humberto.rodriguez@pro-servicios.com
** Author: Humberto Rodriguez **
]]--


local BALL_WIDTH = 40 --80
local gActiveSlider = nil
local gTarget_Probe = 0

local function TextBarRecipeSlider(cur_value,slider_ID,type)
  local data={}
  if(type == 'Time') then
    data[string.format("Layer_Recipe.Slider_%d.Slider_Data_Text.data",slider_ID)] = string.format("%.2d:%.2d",cur_value/60,cur_value%60)
  else
    data[string.format("Layer_Recipe.Slider_%d.Slider_Data_Text.data",slider_ID)] = string.format("%d°C",cur_value)
  end
  gre.set_data(data)
end

--ANALIZAR ESTA PARTE
function RecipeCalcSliderPosition(mapargs)
  local press_x = mapargs.context_event_data.x
  local control = gre.get_control_attrs(mapargs.context_control, "x")
  local new_x = press_x - control["x"] - (BALL_WIDTH/2)
  local bufferData
  
  if (new_x < SLIDER_MIN) then
    new_x = SLIDER_MIN
  elseif new_x > SLIDER_MAX then
    new_x = SLIDER_MAX
  end
 
  local percent_bar = math.ceil((new_x /(SLIDER_MAX - SLIDER_MIN)) * MAX_TICKS)
  local slider_num  = gre.get_value(mapargs.context_control..".slider_num")
  local nameSlider  = recipeSelPresets[slider_num].name
  
  print('nameSlider', nameSlider) --debug
  
  if(nameSlider == 'CookTime')then
    bufferData = (percent_bar * (recipeSelected[totalSteps+1].time_max - recipeSelected[totalSteps+1].time_min)/100) + recipeSelected[totalSteps+1].time_min
    recipeSelected[totalSteps+1].time_target = bufferData
    TextBarRecipeSlider(bufferData,slider_num,'Time')
   
  elseif(nameSlider == 'CoreProbe')then
    bufferData  = math.ceil((percent_bar * (69) / 100) + 30)
    recipeSelected[totalSteps+1].tcore_target = bufferData 
    TextBarRecipeSlider(bufferData,slider_num,'Temperature')
    
    print("tcore_target", recipeSelected[totalSteps+1].tcore_target) --Test
    
  elseif(nameSlider == 'Delta')then
    bufferData = math.ceil((percent_bar * (55) / 100) + 5)--put celcius degree on screen
    TextBarRecipeSlider(bufferData,slider_num,'Temperature')
    
  else
    if (  percent_bar >= 0  and  percent_bar <= 25  ) then
      percent_bar = 25
      new_x = 136
    elseif ( percent_bar > 25 and percent_bar <= 50 ) then
      percent_bar = 50
      new_x = 272
    elseif (percent_bar > 50 and percent_bar <= 75  ) then
      percent_bar = 75
      new_x = 408
    elseif (percent_bar > 75 and percent_bar <= 100 ) then
      percent_bar = 100
      new_x = 544
    end 
  end
  
  if(nameSlider == 'Browning' or nameSlider == 'TempOven')then
    tempKey.val = percent_bar
  elseif(nameSlider == 'FanSpeed' )then
    speedKey.val = percent_bar
  elseif(nameSlider == 'Thickness' )then
    local data={}
    if(percent_bar>50)then
      data[string.format("Layer_Recipe.Slider_%d.Slider_IconBtn.pimg",timeKey.id)]  = "images/icon_CoreProbe.png"
      data[string.format("Layer_Recipe.Slider_%d.Slider_Data_Text.data", timeKey.id)] = string.format("%d °C", recipeSelected[totalSteps+1].tcore_target) --tcore_target -> timeKey because coreKey doesnt exist
      data[string.format("Layer_Recipe.Slider_%d.Slider_Text.pname",timeKey.id)] = "Temperatura interna"
      data["Layer_AutoSteps.icon_CircleFunct.imgMode"] = "images/icon_coreStep.png"
      recipeSelPresets[timeKey.id].name = "CoreProbe"      --bug 1.5.1 se corrige la mayuscula
      recipeSelected[totalSteps+1].cookmode = "coreProbe"  --bug 1.5.1 se agrega esta linea
      
    else
      data[string.format("Layer_Recipe.Slider_%d.Slider_IconBtn.pimg",timeKey.id)]  = "images/icon_CookTime.png"
      data[string.format("Layer_Recipe.Slider_%d.Slider_Data_Text.data", timeKey.id)] = string.format("%.2d:%.2d",recipeSelected[totalSteps+1].time_target/60,recipeSelected[totalSteps+1].time_target%60)
      data["Layer_AutoSteps.icon_CircleFunct.imgMode"] = "images/icon_timeStep.png"
      data[string.format("Layer_Recipe.Slider_%d.Slider_Text.pname",timeKey.id)] = "Velocidad de cocción"
      recipeSelPresets[timeKey.id].name = "CookTime"
      recipeSelected[totalSteps+1].cookmode = "cookTime"  --bug 1.5.2 se corrgige el bug GUI003
    end
    gre.set_data(data)

    --CHANGE PARAMETER TO COOK WITH PROBE
  end
  recipeSelPresets[slider_num].value = percent_bar
  SetBarRecipeSlider(percent_bar,slider_num)
end


function CBRecipeSliderPress(mapargs)
	gActiveSlider = mapargs.context_control
	RecipeCalcSliderPosition(mapargs)
end


function CBRecipeSliderMotion(mapargs)
	if (gActiveSlider == nil) then
		return
	end
	
	if (gActiveSlider == mapargs.context_control) then
		RecipeCalcSliderPosition(mapargs)
	end
end


function CBRecipeSliderRelease(mapargs)
	gActiveSlider = nil	
end

--FUNCION AGREGADA
function CBRecipeEnableEncoder(mapargs)
 print("Funcion no existe")
end


function SetBarRecipeSlider(cur_value,slider_ID)
  local data = {}
  local width = math.ceil((cur_value * SLIDER_MAX) / 100)
  local name_str = string.format("Layer_Recipe.Slider_%d.Slider_Color.grd_width", slider_ID) 
  data[name_str] = width
  if(width<6)then
    width=6
  end
  data[string.format("Layer_Recipe.Slider_%d.Slider_Ball.slider_offset",slider_ID)] = width - 8
  gre.set_data(data)
end
