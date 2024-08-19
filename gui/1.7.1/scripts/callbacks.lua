--[[
Copyright 2021, Pro-Servicios SA de CV.
All Rights Reserved.
Main update events between user interaction and backend control for serial PowerPCB.
For more information email humberto.rodriguez@pro-servicios.com
** Author: Humberto Rodriguez **
]]--

local logger = require("components.logger")
local oven_state_service = require("services.oven_state_service")
local OvenEnums = require("components.oven_status_enums")

---Global variables
SLIDER_MIN      = 0      --Min width pixels for Manual Sliders
SLIDER_MAX      = 530    --524 Max width pixels for Manual Sliders 
WIDE_SMALL_BAR  = 240    --Max width pixels for Precal./Enfriar bars
MAX_TICKS       = 100    --% Percent (humidity/speed)
MAX_TEMP        = 270    --30°C offset
MAX_TIME        = 10820  --to get 180:00 m:s
TIME_WASHING    = 360    --backup time on each wash-cycle selected
MAXTIME_RECIPEML= 0      --backup maximun time on each recipe-ML mode
MAX_LEVEL_RACK  = 7      --Max levels in oven
gCombiOvenState = 0      --Main state-machine indicator
previousState   = 0      --Last state-machine indicator
gCombiOvenMode  = ""     --Mode operation running
gBackendChannel = "combioven_backend" --Channel name with backend communication

gTimeCooking        = 30  --Total time cooking on Manual/Auto mode
gTemperature        = 0   --Main temperature inside oven on each mode
gTempProbe          = 0   --Main temperature Probe inside oven on each mode
hours_target        = 0   --Hours target converted from gTimeCooking
mins_target         = 0   --Minutes target converted from gTimeCooking
gInitTemperature    = 0   --Initial temperature detection inside oven at start-running 
gMaxTimeML          = 0   --backup time based on longest time recipe to adjust bars
gTime_Accumulative  = 0   --store used time (seconds) and write on database each five minutes

local gSteamPercent         = 0
local gFanSpeed             = 25
local gCurrent_probe        = 0
local gCurrent_humidity     = 0
local gCurrent_temperature  = 0
local gTimeoutID            = nil

--[[ DISPLAY UPDATE USER PARAMETERS INCOMING FROM BACKEND ]]--

function DisplayCurrentSteam ()
  local new_x = math.ceil( (gSteamPercent / MAX_TICKS) * (SLIDER_MAX - SLIDER_MIN) )
  local percent_bar = math.ceil((new_x / (SLIDER_MAX - SLIDER_MIN)) * MAX_TICKS)
  local data = {}
  gre.set_value("Layer_Combi_Levels.Combi_BallSlider1.slider_offset", new_x)
  data["Layer_Combi_Levels.Combi_TextSlider1.percent"] = string.format('%d%%', gSteamPercent)
  gre.set_data(data)
  SetBarSlider(percent_bar, 1)
end

function DisplayCurrentTemperature ()
  local new_x = math.ceil( ((gTemperature - 30)/MAX_TEMP) * (SLIDER_MAX - SLIDER_MIN) )
  local percent_bar = math.ceil((new_x / (SLIDER_MAX - SLIDER_MIN)) * MAX_TICKS)
  local data = {}
  gre.set_value("Layer_Combi_Levels.Combi_BallSlider2.slider_offset", new_x)
  data["Layer_Combi_Levels.Combi_TextSlider2.percent"] = string.format('%d°C',gTemperature)
  gre.set_data(data)
  SetBarSlider(percent_bar, 2)
  
  --if(gCombiOvenState==RUN_AUTO_STATE)then
    CalcTempStatusCircle(gTemperature)
    gre.set_value("Layer_AutoSteps.text_CircleTemp.data", string.format("%d°C",gTemperature))
  --end
end

--- Muestra el valor de temperatura Probe recibido del backend con cada incremento del encoder 
-- @param None.
-- @return None.
function DisplayCurrentTempProbe ()
  local gTarget_Probe = gTempProbe
  MAX_TEMP   = gre.get_value("Layer_Combi_Levels.Combi_TextSlider5.max_temp")
  local new_x = math.ceil( ((gTarget_Probe)/MAX_TEMP) * (SLIDER_MAX - SLIDER_MIN) )
  local percent_bar = math.ceil((new_x / (SLIDER_MAX - SLIDER_MIN)) * MAX_TICKS)
  local data = {}

  gre.set_value("Layer_Combi_Levels.Combi_BallSlider5.slider_offset", new_x)
  data["Layer_Combi_Levels.Combi_TextSlider5.percent"] = string.format('%d°C',gTarget_Probe)
  gre.set_data(data)
  SetBarSlider(percent_bar, 5) 
  print("Envio de target Temp-probe: ", gTarget_Probe)
  CBUpdateTemperProbe(gTarget_Probe)
end

function DisplayCurrentTime ()
  local data = {}
  --multinivel
  if(gCombiOvenState == RUN_MULTILEVEL_STATE) then
    local totalLevels = #recipeSelPresets

    for i=1, totalLevels  do
      local preset = recipeSelPresets[i]
      local timeLevel = (preset.time > 0) and (preset.time - 1) or 0
      local idLevel = preset.level
      local idAlert = preset.alert
      gTime_Accumulative = gTime_Accumulative + 1
      
      if (timeLevel==0) then
        if not idAlert then
          sendAlert(idLevel)
          preset.alert = true
        end
      end
      --alert_updateLevelTime(i,timeLevel)
      --print("t1:",gTime_Accumulative)
      print("Level: " .. idLevel .. " time updated to " .. timeLevel .. " seconds. Alert status: " .. (idAlert and "ON" or "OFF"))
      preset.time = timeLevel
      data[string.format("Layer_MultiLevel.Data_Level_%d.text_time.data",idLevel)] = string.format('%.2d:%.2d', timeLevel / 60, timeLevel % 60)
      --MAX_BAR_PROGRESS is the maximun ORANGE BAR lenght
      local MAX_BAR_PROGRESS = 370
      local computeTime = (-375 + ((timeLevel * MAX_BAR_PROGRESS) / gMaxTimeML ))  --recipeSelPresets[i].time
      --print("w:",computeTime)
      data[string.format("Layer_MultiLevel.Data_Level_%d.bar_progress.percent",idLevel)] = computeTime
    
    end
    gre.set_data(data)
    
  else
    local new_x = math.ceil( (gTimeCooking / MAX_TIME) * (SLIDER_MAX - SLIDER_MIN) )
    local percent_bar = math.ceil((new_x / (SLIDER_MAX - SLIDER_MIN)) * MAX_TICKS)
    gTime_Accumulative = gTime_Accumulative + 1
    gre.set_value("Layer_Combi_Levels.Combi_BallSlider3.slider_offset", new_x)
    hours_target =  gTimeCooking / 60
    mins_target  =  gTimeCooking % 60
    data["Layer_Combi_Levels.Combi_TextSlider3.percent"] = string.format('%.2d:%.2d m:s', hours_target, mins_target) -- min:sec
    gre.set_data(data)
    data["Layer_WashingStatus.text_TimeProcess.percent"] = string.format('%.2d:%.2d m:s', hours_target, mins_target)
    data["Layer_AutoSteps.text_CircleTime.data"] = string.format('%.2d:%.2d', hours_target, mins_target)
    gre.set_data(data)
    SetBarSlider(percent_bar, 3)
    local new_angle = math.ceil((gTimeCooking * 360) /TIME_WASHING)
    if (new_angle == nil ) then
      new_angle=0
    end
    gre.set_value("Layer_WashingStatus.icon_CircleProgress.angleTime",90 - new_angle)
    gre.set_value("Layer_WashingStatus.icon_CercleBall.angleTime",190 - new_angle)
  end
end

function DisplayCurrentSpeed ()
  local new_x = math.ceil( (gFanSpeed / MAX_TICKS) * (SLIDER_MAX - SLIDER_MIN) )
  local percent_bar = math.ceil((new_x / (SLIDER_MAX - SLIDER_MIN)) * MAX_TICKS)
  local data = {}
  data["Layer_Combi_Levels.Combi_TextSlider4.percent"] = string.format('%d%%', gFanSpeed)
  gre.set_data(data)
  SetBarSlider(percent_bar, 4)
end

function DisplayActualProbe()
  local data ={}
  gTimeoutID = nil
  if(gCombiOvenState==RUN_AUTO_STATE)then
    data["Layer_AutoSteps.text_CircleTime.data"] = string.format('%d°C', gCurrent_probe)
  else
    data["Layer_Combi_Levels.Combi_TextSlider6.percent"] = string.format('%d°C', gCurrent_probe) 
  end
  gre.set_data(data)
end

function DisplayActualHumidity()
  local data ={}
  gTimeoutID = nil
  data["Layer_Combi_Levels.Combi_TextSlider7.percent"] = string.format('%d%%',gCurrent_humidity)
  gre.set_data(data)
end

function DisplayActualTemp()
  local data ={}
  gTimeoutID = nil
  data["Layer_Combi_Levels.Combi_TextSlider2.percent"] = string.format('%d°C',gTemperature)
  gre.set_data(data)
end


function DisplayProgressBar()
  local data = {}
  local deltaTemp
  local percent_bar 
  
  if (gInitTemperature == 0) then 
      gInitTemperature = gCurrent_temperature
  end

  if (gToggleState['Layer_Combi_Menu.bkg_Preheat'] == 1) then
      deltaTemp = gTemperature - gInitTemperature
      
      if(gindexStep == 1 and gCombiOvenState == RUN_MULTILEVEL_STATE)then
        deltaTemp = math.abs (( gCurrent_temperature * 100 ) / gTemperature)
        data["Layer_Pop_ups.icon_preheat_ML.text_preheat.percent"] = string.format('%d%%', deltaTemp)
        gre.set_data(data)
      
      else  
        percent_bar = math.ceil(WIDE_SMALL_BAR - ((gTemperature - gCurrent_temperature) * ( WIDE_SMALL_BAR / deltaTemp)) )
        data["Layer_Combi_Menu.bar_Preheat.percent"] = percent_bar
        data["Layer_Combi_Levels.Combi_TextSlider2.percent"] = string.format('%d°C', gCurrent_temperature)
        gre.set_data(data)
        --percent_bar = math.ceil((gCurrent_temperature * 300) / deltaTemp) 
        CalcTempStatusCircle(gCurrent_temperature)
      end
       
  elseif(gToggleState['Layer_Combi_Menu.bkg_Cooling'] == 1) then
      deltaTemp = gInitTemperature - gTemperature
      percent_bar = math.ceil(WIDE_SMALL_BAR - ((gCurrent_temperature - gTemperature) * (WIDE_SMALL_BAR / deltaTemp)) )
      data["Layer_Combi_Menu.bar_Cooling.percent"] = percent_bar
      gre.set_data(data)

  end  
end 

-- Función para validar el valor
local function validateHrsSteam(hrsSteam, accumulative)
    -- Asegurarse de que el valor no sea nulo y no resulte en un número negativo
    if hrsSteam == nil then
        return false, "Value cannot be nil"
    end
    
    local newHrsSteam = hrsSteam - accumulative
    
    if newHrsSteam < 0 then
        return false, "Value cannot be negative"
    end
    
    return true, nil
end

-- Función para validar los valores
local function validateValues(hrsSteam, hrsConv, accumulative)
    -- Asegurarse de que los valores no sean nulos y no resulten en números negativos
    if hrsSteam == nil or hrsConv == nil then
        return false, "Values cannot be nil"
    end
    
    local newHrsSteam = hrsSteam - accumulative
    local newHrsConv = hrsConv - accumulative
    
    if newHrsSteam < 0 or newHrsConv < 0 then
        return false, "Values cannot be negative"
    end
    
    return true, nil
end

--Stores use time on DB to calculate the total hours cooking oven and set clean oven bar
function UseTimeCounter()
   if(gToggleState['Layer_Combi_Menu.bkg_LoopTimer'] == 1) then
     gTime_Accumulative = gTime_Accumulative + 30   
   end
   --print("t2:",gTime_Accumulative)
   if(gTime_Accumulative>=300 and gCombiOvenState == RUN_WASHING_STATE)then
      local cur = db:execute("SELECT HrsSteam,HrsConv FROM system_configuration WHERE id = 1") --extrae el dato
      local row = cur:fetch ({}, "a")
      local stateUpdate
      if(row.HrsConv <= 100 and TIME_WASHING >= 2460)then
          gTime_Accumulative = 0
          row.HrsConv = 0
          ALERT_DISTURB = false
      elseif(row.HrsSteam <= 100 and TIME_WASHING >= 2460)then
          gTime_Accumulative = 0
          row.HrsSteam = 0
          ALERT_DISTURB = false   
      elseif(row.HrsSteam <= 100 and TIME_WASHING < 2460)then
          gTime_Accumulative = 0
          row.HrsSteam = 0
          ALERT_DISTURB = false        
      elseif(row.HrsSteam > 100 and TIME_WASHING == 1440 )then  
          local isValid, errorMsg = validateHrsSteam(row.HrsSteam, gTime_Accumulative)
          if isValid then
            stateUpdate = string.format("UPDATE system_configuration SET HrsSteam=%d WHERE id=1;",row.HrsSteam - gTime_Accumulative)
          else
            print("Error updating database:", errorMsg)
          end
      else 
          -- Validar los valores antes de construir la consulta
          local isValid, errorMsg = validateValues(row.HrsSteam, row.HrsConv, gTime_Accumulative)
          if isValid then
            gTime_Accumulative = (gTime_Accumulative * 30) /60
            stateUpdate = string.format("UPDATE system_configuration SET HrsSteam=%d, HrsConv=%d WHERE id=1;",row.HrsSteam - gTime_Accumulative, row.HrsConv - gTime_Accumulative)
          else
            print("Error updating database:", errorMsg)
          end
      end   
      local update = db:execute(stateUpdate) --actualiza el dato
      gTime_Accumulative = 0
      
   elseif(gTime_Accumulative>=300 and gCombiOvenMode == 'steam')then
      local cur = db:execute("SELECT HrsSteam FROM system_configuration WHERE id = 1") --extrae el dato
      local row = cur:fetch ({}, "a")
      local stateUpdate = string.format("UPDATE system_configuration SET HrsSteam=%d WHERE id=1;",row.HrsSteam + (gTime_Accumulative/60))
      local update = db:execute(stateUpdate) --actualiza el dato
      gTime_Accumulative = 0
      ALERT_DISTURB = false
      
   elseif((gTime_Accumulative>=300 ) and (gCombiOvenMode == 'combined' or gCombiOvenMode == 'convection') )then
      local cur = db:execute("SELECT HrsConv FROM system_configuration WHERE id = 1")
      local row = cur:fetch ({}, "a")
      local stateUpdate = string.format("UPDATE system_configuration SET HrsConv=%d WHERE id=1;",row.HrsConv + (gTime_Accumulative/60))
      local update = db:execute(stateUpdate)
      gTime_Accumulative = 0
      ALERT_DISTURB = false
   end
end


function SetWarningState(warningCode)
  gre.send_event_data (
    "set_warning",
    "1u1 warningcode", 
    {warningcode = warningCode}, 
    gBackendChannel)
end


--[[ CALLBACKS FUNCTIONS MADE IT BY USER FROM TOUCHSCREEN AND WILL SEND EVENTS TO BACKEND ]]--
--[[  **********************************************************************************  ]]--
--[[  **********************************************************************************  ]]-- 

function CBUpdateSteam(target_steam) 
  gre.send_event_data (
    "update_steam",
    "1u1 percent", 
    {percent = target_steam}, 
    gBackendChannel)
end


function CBUpdateTemperature(target_temperature) 
  gTemperature = target_temperature 
  gre.send_event_data (
    "update_temperature",
    "2u1 usertemp", 
    {usertemp = target_temperature}, 
    gBackendChannel)
end


function CBUpdateTemperProbe(target_probe) 
  gre.send_event_data (
    "update_temprobe",
    "2u1 usertemp", 
    {usertemp = target_probe}, 
    gBackendChannel)
end


function CBUpdateTemperDelta(target_delta) 
  gre.send_event_data (
    "update_tempdelta",
    "2u1 userdelta", 
    {userdelta = target_delta}, 
    gBackendChannel)
end


function CBUpdateTime(sectimer, units) 
  gre.send_event_data (
    "update_time",
    "4u1 timer",
    {timer = sectimer}, 
    gBackendChannel)
end


function CBUpdateFanSpeed(slider_percent) 
  gre.send_event_data (
    "update_fanspeed",
    "1u1 percent", 
    {percent = slider_percent}, 
    gBackendChannel)
end

--Manual modos de cocion 
function CBUpdateMode(mapargs)
   gScreen = mapargs.context_screen
   
  if  (mapargs.context_control == 'Layer_ModeFunctBar.bkg_Heather_on') then
    MAX_TEMP   = gre.get_value("Layer_Combi_Levels.Combi_TextSlider2.max_temp")
    gCombiOvenMode = 'convection'
    CBUpdateSteam(0)
    Wait(2)
    CBUpdateTemperature(30)
    logger.info("Convection mode selected")
    oven_state_service.updateOvenMode(OvenEnums.OvenMode.COOKING)
    oven_state_service.updateCookingMode(OvenEnums.CookingMode.MANUAL)
    oven_state_service.updateManualMode(OvenEnums.ManualMode.CONVECTION)
    oven_state_service.logOvenState()
    
  elseif (mapargs.context_control == 'Layer_ModeFunctBar.bkg_Combined_on') then
    MAX_TEMP   = gre.get_value("Layer_Combi_Levels.Combi_TextSlider2.max_temp")
    gCombiOvenMode = 'combined'
    CBUpdateSteam(0)
    Wait(2)
    CBUpdateTemperature(30)
    logger.info("Combined mode selected")
    oven_state_service.updateOvenMode(OvenEnums.OvenMode.COOKING)
    oven_state_service.updateCookingMode(OvenEnums.CookingMode.MANUAL)
    oven_state_service.updateManualMode(OvenEnums.ManualMode.COMBINED)
    oven_state_service.logOvenState()
    
  elseif (mapargs.context_control == 'Layer_ModeFunctBar.bkg_Steam_on') then
    MAX_TEMP   = gre.get_value("Layer_Combi_Levels.Combi_TextSlider2.max_temp")
    CBUpdateSteam(100)
    Wait(2)
    CBUpdateTemperature(98)
    Wait(2)
    gCombiOvenMode = 'steam'
    logger.info("Steam mode selected")
    oven_state_service.updateOvenMode(OvenEnums.OvenMode.COOKING)
    oven_state_service.updateCookingMode(OvenEnums.CookingMode.MANUAL)
    oven_state_service.updateManualMode(OvenEnums.ManualMode.STEAM)
    oven_state_service.logOvenState()
    
  end
  gre.send_event ("mode_"..gCombiOvenMode, "combioven_backend")
  logger.info("Sending to backend: -> ".."mode_"..gCombiOvenMode)
end


function CBUpdateWashCycle(usercycle)
  gre.send_event_data (
    "update_washcycle",
    "1u1 usercycle", 
    {usercycle = usercycle}, 
    gBackendChannel)
end

function CBUpdateRelay(kxrelay)
    gre.send_event_data (
    "toggle_relay",
    "1u1 relay", 
    {relay = kxrelay}, 
    gBackendChannel)
end

function CBUpdateRecipeInfo(totalSteps, actualStep, typeStep, currLevel)
  gre.send_event_data (
    "update_recipeinfo",
    "1u1 totalsteps 1u1 actualstep 1u1 typestep 1u1 currlevel", 
    {totalsteps = totalSteps,
     actualstep = actualStep,
     typestep  = typeStep, 
     currlevel  = currLevel}, 
    gBackendChannel)
end

function CBUpdateEncoderOptions(min_value,max_value,now_value,step_value,id_parameter)
  gre.send_event_data(
   "enable_encoder_options", 
   "4u1 minvalue 4u1 maxvalue 4u1 nowvalue 1u1 stepvalue 1u1 parameter",
   { minvalue = min_value,
     maxvalue = max_value,
     nowvalue = now_value,
     stepvalue = step_value,
     parameter = id_parameter},
   gBackendChannel)
end


--- Recibe una tabla de estados enviados por el backend cuando existe un cambio
-- @param
-- mapargs: 
-- target_time, encoder_data. target_temperature, current_probe, current_humidity, current_temperature
-- target_steam, target_fanspeed, toggle_preheat, toggle_cooling, toggle_probe, toggle_looptime , encoder_parameter
-- @return None
---------------------------------------------------------------------------------------------------------------------
function CBUpdateCombiOven(mapargs) 
  local ev_data = mapargs.context_event_data
  logger.info("Data received from backend: ")
    
  if (ev_data.target_time ~= nil and ev_data.target_time ~= gTimeCooking) then
    gTimeCooking = ev_data.target_time
    DisplayCurrentTime()
    logger.info("Target time: "..tostring(gTimeCooking))
  end
  
  if (ev_data.target_temperature ~= nil and ev_data.target_temperature ~= gTemperature) then
    gTemperature = ev_data.target_temperature
    DisplayCurrentTemperature()
    logger.info("Target Temperature: "..tostring(gTemperature))
  end
  
  if (ev_data.target_probe ~= nil and ev_data.target_probe ~= gTempProbe) then
    gTempProbe = ev_data.target_probe
    DisplayCurrentTempProbe()
    logger.info("Target Temperature: "..tostring(gTempProbe))
  end
  
  if (ev_data.target_steam ~= nil and ev_data.target_steam ~= gSteamPercent) then
    gSteamPercent = ev_data.target_steam
    DisplayCurrentSteam()
    logger.info("Target Steam: "..tostring(gSteamPercent))
  end

  if (ev_data.target_fanspeed ~= nil and ev_data.target_fanspeed ~= gFanSpeed) then
    gFanSpeed = ev_data.target_fanspeed
    DisplayCurrentSpeed ()
    logger.info("Target FanSpeed: "..tostring(gFanSpeed))
  end
  
  if (ev_data.current_probe ~= nil and ev_data.current_probe ~= gCurrent_probe) then
    gCurrent_probe = ev_data.current_probe
    DisplayActualProbe()
    logger.info("Target Current Probe: "..tostring(gCurrent_probe))
  end
  
  if (ev_data.current_humidity ~= nil and ev_data.current_humidity ~= gCurrent_humidity) then
    gCurrent_humidity = ev_data.current_humidity
    DisplayActualHumidity()
    logger.info("Target Current Humidity: "..tostring(gCurrent_humidity))
  end
  
  if (ev_data.current_temperature ~= nil and ev_data.current_temperature ~= gCurrent_temperature) then
    gCurrent_temperature = ev_data.current_temperature
    DisplayProgressBar()
    logger.info("Target Current Temperature: "..tostring(gCurrent_temperature))
  end
  
  if (ev_data.toggle_preheat ~= nil) then  
    CBSetTogglePreheat('Layer_Combi_Menu.bkg_Preheat', ev_data.toggle_preheat)
    logger.info("Toggle Preheat: "..tostring(ev_data.toggle_preheat))
  end
  
  if (ev_data.toggle_cooling ~= nil) then
    CBSetToggleCooling('Layer_Combi_Menu.bkg_Cooling', ev_data.toggle_cooling)
    logger.info("Toggle Cooling: "..tostring(ev_data.toggle_cooling))
  end
  
  if (ev_data.toggle_looptime ~= nil) then
     CBSetToggleLoopTime('Layer_Combi_Menu.bkg_LoopTimer', ev_data.toggle_looptime)
     logger.info("Toggle Looptime: "..tostring(ev_data.toggle_looptime))
  end
  
  if (ev_data.toggle_probe ~= nil) then
    CBSetToggleProbe('Layer_Combi_Menu.bkg_Probe', ev_data.toggle_probe)
    logger.info("Toggle Probe: "..tostring(ev_data.toggle_probe))
  end
  
  if (ev_data.toggle_state ~= nil) then
    CBSetToggleState(mapargs, ev_data.toggle_state)
    gCombiOvenState = ev_data.toggle_state
    logger.info("Toggle State: "..tostring(gCombiOvenState))
    
  end
  
  if (ev_data.encoder_data ~= nil and encoder_options.data ~= nil and ev_data.encoder_parameter == 6) then
    CBDisplayDataEncoder(ev_data.encoder_data)
    logger.info("Encoder Data: "..tostring(ev_data.encoder_data))
  end
  
end

