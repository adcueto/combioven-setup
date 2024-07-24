--[[
Copyright 2021, Pro-Servicios SA de CV.
All Rights Reserved.
For more information email humberto.rodriguez@pro-servicios.com
** Author: Humberto Rodriguez **
]]--

BAR_COLOR_MAXWIDTH = 510

local BALL_WIDTH = 40 --80
local gActiveSlider = nil
local gTarget_Probe = 0

local function TextBarRecipeSlider(cur_value,slider_ID,type)
  local data={}
  if(type == 'Time') then
    data[string.format("Layer_Recipe.Slider_%d.Slider_Data_Text.data",slider_ID)] = string.format("%.2d:%.2d m:s",cur_value/60,cur_value%60)
  else
    data[string.format("Layer_Recipe.Slider_%d.Slider_Data_Text.data",slider_ID)] = string.format("%d °C",cur_value)
  end
  gre.set_data(data)
end

--ANALIZAR ESTA PARTE
function RecipeCalcSliderPosition(mapargs)
  gScreen = mapargs.context_screen 
  
  local press_x = mapargs.context_event_data.x
  local control = gre.get_control_attrs(mapargs.context_control, "x")
  local new_x = press_x - control["x"] - (BALL_WIDTH/2)
  local bufferData
  local type
  
  encoder_options["data"] = 0
  encoder_options["parameter"] = 0
  
  if (new_x < SLIDER_MIN) then
    new_x = SLIDER_MIN
  elseif new_x > SLIDER_MAX then
    new_x = SLIDER_MAX
  end
 
  local percent_bar = math.ceil((new_x /(SLIDER_MAX - SLIDER_MIN)) * MAX_TICKS)
  local slider_num  = gre.get_value(mapargs.context_control..".slider_num")
  local nameSlider  = recipeSelPresets[slider_num].name

  
  if(nameSlider == 'CookTime')then
    bufferData = (percent_bar * (recipeSelected[totalSteps+1].time_max - recipeSelected[totalSteps+1].time_min)/100) + recipeSelected[totalSteps+1].time_min
    recipeSelected[totalSteps+1].time_target = bufferData
    type = 'Time'
    TextBarRecipeSlider(bufferData,slider_num,'Time')
    print("bufferData",bufferData)
    encoder_options.data = bufferData
    encoder_options.parameter = slider_num
    --CBUpdateEncoderOptions(180,1200,encoder_options.data,1,6)
    SetBarRecipeSlider(bufferData,slider_num, nameSlider,recipeSelected[totalSteps+1].time_min, recipeSelected[totalSteps+1].time_max)
   
  elseif(nameSlider == 'CoreProbe')then
    bufferData  = math.ceil((percent_bar * (69) / 100) + 30)
    recipeSelected[totalSteps+1].tcore_target = bufferData 
    type = 'Temperature'
    TextBarRecipeSlider(bufferData,slider_num,'Temperature')
    
    encoder_options.data = bufferData
    encoder_options.parameter = slider_num
    --CBUpdateEncoderOptions(180,1200,encoder_options.data,1,6)
    SetBarRecipeSlider(bufferData,slider_num, nameSlider,30, 100)
    print("tcore_target", recipeSelected[totalSteps+1].tcore_target) --Test
    
  elseif(nameSlider == 'Delta')then
    bufferData = math.ceil((percent_bar * (94) / 100) + 5)--put celcius degree on screen
    TextBarRecipeSlider(bufferData,slider_num,'Temperature')
    
    encoder_options.data = bufferData
    encoder_options.parameter = slider_num
    SetBarRecipeSlider(bufferData,slider_num, nameSlider,5, 100)
    
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
    encoder_options.parameter = slider_num
    encoder_options.data = percent_bar
    SetBarRecipeSlider(percent_bar,slider_num, nameSlider,25, 100)
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
      
      SetBarRecipeSlider(recipeSelected[totalSteps+1].tcore_target,3, 'CoreProbe',30, 100)
      
    else
      data[string.format("Layer_Recipe.Slider_%d.Slider_IconBtn.pimg",timeKey.id)]  = "images/icon_CookTime.png"
      data[string.format("Layer_Recipe.Slider_%d.Slider_Data_Text.data", timeKey.id)] = string.format("%.2d:%.2d m:s",recipeSelected[totalSteps+1].time_target/60,recipeSelected[totalSteps+1].time_target%60)
      data["Layer_AutoSteps.icon_CircleFunct.imgMode"] = "images/icon_timeStep.png"
      data[string.format("Layer_Recipe.Slider_%d.Slider_Text.pname",timeKey.id)] = "Velocidad de cocción"
      recipeSelPresets[timeKey.id].name = "CookTime"
      recipeSelected[totalSteps+1].cookmode = "cookTime"  --bug 1.5.2 se corrgige el bug GUI003
      
      SetBarRecipeSlider(recipeSelected[totalSteps+1].time_target,3, 'CookTime',recipeSelected[totalSteps+1].time_min, recipeSelected[totalSteps+1].time_max )
    
    end
    gre.set_data(data)
    
    --CHANGE PARAMETER TO COOK WITH PROBE
  end
  
  recipeSelPresets[slider_num].value = percent_bar

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
 -- local  minvalueSlider, maxvalueSlider, nowvalueSlider, stepvalueSlider
  --local gScreen = mapargs.context_screen

  
  local percentData = {}
  local slider_num  = gre.get_value(mapargs.context_control..".slider_num")
  local slider_width  = gre.get_value(string.format("Layer_Recipe.Slider_%d.Slider_Color.grd_width", slider_num) )
  local slider_text = gre.get_value(string.format("Layer_Recipe.Slider_%d.Slider_Data_Text.data", slider_num) )
  local nameSlider  = recipeSelPresets[slider_num].name
  local selectedParam = slider_num
  
  percentData[133] = 25
  percentData[265] = 50
  percentData[398] = 75
  percentData[530] = 100
  
  print("text:",slider_text )
  print("nameSlider:",nameSlider )
  
  if(nameSlider == 'CoreProbe')then
   -- stepvalueSlider = 1
    --minvalueSlider = 30
    --maxvalueSlider = 99
    --nowvalueSlider = tonumber(string.sub(slider_text, 1, 2))                        --math.ceil(slider_width/degCen) + initTemp
      bufferData = recipeSelected[totalSteps+1].tcore_target
      encoder_options.data = bufferData
      encoder_options.parameter = slider_num
      print("encoder_options.data:", encoder_options.data)
      CBUpdateEncoderOptions(30,100,encoder_options.data,1,6)

   elseif(nameSlider == 'Delta' )then
   
      bufferData = tonumber(string.sub(slider_text, 1, 2))
      encoder_options.data = bufferData
      encoder_options.parameter = slider_num
      print("encoder_options.data:", encoder_options.data)
      CBUpdateEncoderOptions(5,100,encoder_options.data,1,6)
     
   
  elseif(nameSlider == 'CookTime' )then
    --stepvalueSlider = 10
    --minvalueSlider = 180
    --maxvalueSlider = 5940
    --nowvalueSlider = tonumber(string.sub(slider_text, 1, 2)) *60 + tonumber(string.sub(slider_text, 4, 5))
    --encoder_options.data = nowvalueSlider
      bufferData = recipeSelected[totalSteps+1].time_target
      --encoder_options.data = tonumber(string.sub(slider_text, 1, 2)) *60 + tonumber(string.sub(slider_text, 4, 5))
      encoder_options.data = bufferData
      encoder_options.parameter = slider_num
      CBUpdateEncoderOptions(recipeSelected[totalSteps+1].time_min,recipeSelected[totalSteps+1].time_max,encoder_options.data,1,6)
  else
      encoder_options.data = percentData[slider_width] 
      encoder_options.parameter = slider_num
      print("encoder_options.data:", encoder_options.data)
      CBUpdateEncoderOptions(25,100,encoder_options.data,25,6)
  
  end
end



function RecipeCalcSliderPositionEncoder(value,slider_ID)
 
  local slider_num  = slider_ID
  local nameSlider  = recipeSelPresets[slider_num].name
  
    
  if(nameSlider == 'CookTime')then
    recipeSelected[totalSteps+1].time_target = math.ceil(value)
    TextBarRecipeSlider(value,slider_num,'Time')
    SetBarRecipeSlider(value,slider_num, nameSlider,recipeSelected[totalSteps+1].time_min,  recipeSelected[totalSteps+1].time_max)
   
  elseif(nameSlider == 'CoreProbe')then
    recipeSelected[totalSteps+1].tcore_target = math.ceil(value)
    type = 'Temperature'
    TextBarRecipeSlider(value,slider_num,'Temperature')
    SetBarRecipeSlider(value,slider_num, nameSlider,30,100)

    
  elseif(nameSlider == 'Delta')then
  
    TextBarRecipeSlider(value,slider_num,'Temperature')
    SetBarRecipeSlider(value,slider_num, nameSlider,5,100)
    
  else
    SetBarRecipeSlider(value,slider_num, nameSlider,25,100)  
  end
  
  if(nameSlider == 'Browning' or nameSlider == 'TempOven')then
    tempKey.val = math.ceil(value)

    
  elseif(nameSlider == 'FanSpeed' )then
    speedKey.val = math.ceil(value)
    
  elseif(nameSlider == 'Thickness' )then
    local data={}
    if(value>50)then
      data[string.format("Layer_Recipe.Slider_%d.Slider_IconBtn.pimg",timeKey.id)]  = "images/icon_CoreProbe.png"
      data[string.format("Layer_Recipe.Slider_%d.Slider_Data_Text.data", timeKey.id)] = string.format("%d °C", recipeSelected[totalSteps+1].tcore_target) --tcore_target -> timeKey because coreKey doesnt exist
      data[string.format("Layer_Recipe.Slider_%d.Slider_Text.pname",timeKey.id)] = "Temperatura interna"
      data["Layer_AutoSteps.icon_CircleFunct.imgMode"] = "images/icon_coreStep.png"
      recipeSelPresets[timeKey.id].name = "CoreProbe"      --bug 1.5.1 se corrige la mayuscula
      recipeSelected[totalSteps+1].cookmode = "coreProbe"  --bug 1.5.1 se agrega esta linea
      SetBarRecipeSlider(recipeSelected[totalSteps+1].tcore_target, 3, 'CoreProbe',30, 100)
      
    else
      data[string.format("Layer_Recipe.Slider_%d.Slider_IconBtn.pimg",timeKey.id)]  = "images/icon_CookTime.png"
      data[string.format("Layer_Recipe.Slider_%d.Slider_Data_Text.data", timeKey.id)] = string.format("%.2d:%.2d m:s",recipeSelected[totalSteps+1].time_target/60,recipeSelected[totalSteps+1].time_target%60)
      data["Layer_AutoSteps.icon_CircleFunct.imgMode"] = "images/icon_timeStep.png"
      data[string.format("Layer_Recipe.Slider_%d.Slider_Text.pname",timeKey.id)] = "Velocidad de cocción"
      recipeSelPresets[timeKey.id].name = "CookTime"
      recipeSelected[totalSteps+1].cookmode = "cookTime"  --bug 1.5.2 se corrgige el bug GUI003
      SetBarRecipeSlider(recipeSelected[totalSteps+1].time_target, 3, 'CookTime',recipeSelected[totalSteps+1].time_min,  recipeSelected[totalSteps+1].time_max)
    end
    gre.set_data(data)

    --CHANGE PARAMETER TO COOK WITH PROBE
  end

  recipeSelPresets[slider_num].value = value
  
end


function SetBarRecipeSlider(cur_value,slider_ID, type, min, max)
  local data = {}
  local width = 0
  
  print("cur_value: "..cur_value)  
  print("time_max:", min)
  print("time_min:", max)
  
  if type =='CookTime' then
      --width = math.ceil((cur_value * SLIDER_MAX) / 5760)
      width =  math.ceil(((cur_value - min )/ (max-min)) * (SLIDER_MAX - SLIDER_MIN))
  elseif type =='CoreProbe' then
      --width = math.ceil((cur_value * SLIDER_MAX) / 100)
      width =  math.ceil(((cur_value - min) / (max-min)) * (SLIDER_MAX - SLIDER_MIN))
  elseif type =='Delta' then
      --width = math.ceil((cur_value * SLIDER_MAX) / 100)
      width =  math.ceil(((cur_value - min) / (max-min)) * (SLIDER_MAX - SLIDER_MIN))
  else
      --width = math.ceil((cur_value * SLIDER_MAX) / 100)
      width = (cur_value * SLIDER_MAX)/MAX_TICKS
  end
  print("width: "..width)  

  local name_str = string.format("Layer_Recipe.Slider_%d.Slider_Color.grd_width", slider_ID) 
  data[name_str] = width
  if(width<6)then
    width=6
  end
  data[string.format("Layer_Recipe.Slider_%d.Slider_Ball.slider_offset",slider_ID)] = width - 8
  gre.set_data(data)
end


