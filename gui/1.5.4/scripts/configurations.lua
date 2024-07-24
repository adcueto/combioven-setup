--[[
Copyright 2021, Pro-Servicios SA de CV.
All Rights Reserved.
Setup main configuration like as Background, Time/Date, CpuTemp,
and get Clean Status from database. 
For more information email humberto.rodriguez@pro-servicios.com
** Author: Humberto Rodriguez **
]]--


local myenv = gre.env({ "target_os", "target_cpu" })
local timerDate       = 2
local timerDateID     = nil
local MAX_CLEAN_BAR   = 690   --pixels
local MAX_TIME_DIRTY  = 7200  --minutes
local MAX_TIME_CALOUT = 6000  --minutes
local MAX_TEMP_FILTER = 80    --°C degree
local MAX_TEMP_CPU    = 81    --°C degree


--[[ When application starts it calls SetDateTimer() then CBGetTime each minute ]]--
--[[***********  TIMER FOR DATE AND TIME SYSTEM ****************]]--
function SetDateTimer()
  local data = {}
  data["Layer_HomeSettingsBar.text_Date.date"] = os.date("%d/%m/%Y")
  data["Layer_HomeSettingsBar.text_Time.time"] = os.date("%H:%M")
  gre.set_data(data)
  timerDate = 2  
  timerDateID = gre.timer_set_interval(UpdateDisplayDate,29000)
end


--[[Esta funcion se ejecuta cada 29 segundos]]--
function UpdateDisplayDate()
  if (timerDate>0) then
    timerDate = timerDate - 1
  else
    CBGetTime()
    UseTimeCounter()
    ProcessorTemp()
  end
end


--[[Actualiza Fecha y hora cada 29 segundos]]--
function CBGetTime()
  local data = {}
  data["Layer_HomeSettingsBar.text_Date.date"] = os.date("%d/%m/%Y")
  data["Layer_HomeSettingsBar.text_Time.time"] = os.date("%H:%M")
  gre.set_data(data)
end
--[[******************** END SET DATE TIMER **************************]]--


function SaveBackgroundTheme() --Storage the theme selected on DB
  local bkgname = gre.get_value("Layer_UserTheme.bkgUserTheme.bkg_imageUserSelected")
  local stateUpdate = string.format("UPDATE system_configuration SET ThemeBkg='%s' WHERE id=1;",bkgname)
  local update = db:execute(stateUpdate)
end

function CBSetBackgroundTheme() --Set background on initial startup
  local statement = string.format("SELECT NoSerie,ThemeBkg FROM system_Configuration")
  local cur = db:execute(statement)
  local row = cur:fetch({}, "a")
  local data = {}
  data["Layer_UserTheme.bkgUserTheme.bkg_imageUserSelected"] = string.format("%s",row.ThemeBkg)
  gre.set_data(data)
end


local function GetCleanRecommends(usedTimeCamera, usedTimeBoiler)
  local data = {}
  if(usedTimeCamera <= 138)then
    if(usedTimeBoiler>=276)then
      data["Layer_DialogBoxSuggest.text_InputField.text"] = 'Descalcificado     24 min'
    else
      data["Layer_DialogBoxSuggest.text_InputField.text"] = 'Enjuague rapido    12 min'
    end
  
  elseif(usedTimeCamera > 138 and usedTimeCamera <= 276)then
    data["Layer_DialogBoxSuggest.text_InputField.text"] = 'Lavado Eco   41 min'
  
  elseif(usedTimeCamera > 276 and usedTimeCamera <= 414)then
    data["Layer_DialogBoxSuggest.text_InputField.text"] = 'Lavado Intermedio   60 min'
  
  elseif(usedTimeCamera > 414 and usedTimeCamera <= 552)then
    data["Layer_DialogBoxSuggest.text_InputField.text"] = 'Lavado Regular   95 min'
    
  else
    data["Layer_DialogBoxSuggest.text_InputField.text"] = 'Lavado Intenso   150 min'  
  end
  gre.set_data(data)
end 


--- Show the boiler and camera bar status for wash cycles   
function CBGetCleanStatus()
  local statement = string.format("SELECT HrsSteam,HrsConv FROM system_Configuration WHERE id=1;")
  local cur = db:execute(statement)
  local row = cur:fetch({}, "a")
  local percentBoiler = math.ceil((row.HrsSteam * MAX_CLEAN_BAR) / (MAX_TIME_CALOUT) )
  local percentCamera = math.ceil((row.HrsConv * MAX_CLEAN_BAR) / (MAX_TIME_DIRTY) ) 
  local data = {}
  if(percentCamera>552)then
    percentCamera=552
  elseif(percentBoiler>552)then
    percentBoiler=552
  end
  data["Layer_ModeWashing.Slider1.Slider_Color.percent"] = percentCamera
  data["Layer_ModeWashing.Slider2.Slider_Color.percent"] = percentBoiler
  gre.set_data(data)
  GetCleanRecommends(percentCamera,percentBoiler)
end


function CBBrightness(mapargs)
  local percent_bar = math.ceil()
  local statement = string.format("echo %d /sys/class/backlight/backlight\@0/brightness",percent_bar)
  print(statement)
end


---Get Temperature measurement from CPU each 29 seconds
function ProcessorTemp()
  local cpu_tStr = 0

  if myenv["target_os"] == "linux" then 
      local f = assert( io.popen("cat /sys/class/thermal/thermal_zone0/temp"))
      local data = {} 

      for line in f:lines() do
        --prueba
        print("line:",line)
        if line:match("%d%d") ~= nil then
          cpu_tStr = line:match("%d%d")
        end
      end     
      f:close();
      
      --[[Enable Temperature CPU on display]]--
      --if (gToggleState["Layer_RelayState.17_text_Opt17"] == 1) then
        data["Layer_TopBar.IconMainMenu_Status.mode_status"] = string.format("cpu:%s°C",cpu_tStr)
        gre.set_data(data)  --80°C is the limit
      --end
      
      local cpu_temp = tonumber(cpu_tStr)  
      if(cpu_temp == MAX_TEMP_FILTER and gCombiOvenState ~= DIRTY_FILTER_STATE and gCombiOvenState ~= OVERHEAT_STATE) then
        data["Layer_TopBar.IconMainMenu_Status.mode_status"] = string.format("cpu:%s°C ¡Precaución!",cpu_tStr)
        gre.set_data(data)
        SetWarningState(DIRTY_FILTER_STATE)
        
      elseif(cpu_temp >= MAX_TEMP_CPU and gCombiOvenState ~= OVERHEAT_STATE) then
        data["Layer_TopBar.IconMainMenu_Status.mode_status"] = string.format("cpu:%s°C ¡Equipo desactivado!",cpu_tStr)
        gre.set_data(data)
        SetWarningState(OVERHEAT_STATE)
      end
   end
end