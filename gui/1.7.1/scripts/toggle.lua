--[[
Copyright 2021, Pro-Servicios SA de CV.
All Rights Reserved.
Control for all toggle states when user press some buttons to enable/disable
functions. Setup timers to clear messages pop-ups or blink effect.
 ====================     ===============================    ========================     =============
 ||USER Press button|| -> ||toggle_state enable/disable|| -> ||Backend-notification||  -> ||callbacks||
 =====================    ===============================    ========================     =============
For more information email humberto.rodriguez@pro-servicios.com
** Author: Humberto Rodriguez **
]]--

local logger = require("components.logger")
local oven_state_service = require("services.oven_state_service")
local OvenEnums = require("components.oven_status_enums")

gToggleState = {} -- table used to track state for all toggles
gHrsSteam = 0  --Variabel used to track washing ciclyes
gHrsConv =  0 --Variabel used to track washing ciclyes
onRecipeBook = false --trackin recipebook

local timer = 10
local timerID = nil
local timerBlink = 2
local timerBlinkID = nil


---TOGGLE STATES OVEN
STOP_OVEN_STATE     = 0
RUN_SUB_STATE       = 1
RUN_MANUAL_STATE    = 2
RUN_AUTO_STATE      = 3
RUN_MULTILEVEL_STATE= 4
RUN_WASHING_STATE   = 5
RDY_NEXTSTEP_STATE  = 6
PAUSE_BY_DOOR_STATE = 7
FINISHED_STATE      = 8
CONNECT_WATER_STATE = 9
WARNING_STATE       = 10
DIRTY_FILTER_STATE  = 11
OVERHEAT_STATE      = 12
WARNING_THERMO_COLD     =   13
WARNING_THERMO_MAIN     =   14
WARNING_THERMO_BOILER   =   15
WARNING_THERMO_MULPOINT =   16
WARNING_THERMO_ONEPOINT =   17
WARNING_LEVEL_SENSOR    =   18
WARNING_COM_FAILURE     =   19


--[[***********  TIMER FOR POP UP WINDOW MESSAGES ****************]]--
function SetDialogBoxTimer()
  timer = 2  
  timerID = gre.timer_set_interval(TimerOff,250)
end


function ClearDialogTimer()
    local data
    if timerID then
      data = gre.timer_clear_interval(timerID)
    end
end


function TimerOff()
  if (timer>0) then
    timer = timer - 1
  else
    AutoCloseBox()
  end
end


function AutoCloseBox()
   local data = {}
   data["hidden"] = 1
   gre.set_layer_attrs('Layer_DialogBox', data)
   gre.set_layer_attrs('Layer_AddAutoRecipe', data) 
   ClearDialogTimer()
end
--[[******************** END BLINK TIMER **************************]]--



--[[***********  TIMER FOR POP UP WINDOW WARNING 10 SEC ***********]]--
function SetDialogTimer()
  timer = 7  
  timerID = gre.timer_set_interval(TimerTick,1000)
end


function TimerTick()
  if (timer>0) then
    timer = timer - 1
  else
    AutoClose()
  end
end

function AutoClose()
   local data = {}
   data["hidden"] = 1
   gre.set_layer_attrs('Layer_Warnings', data) 
   ClearDialogTimer()
end
--[[******************** END BLINK TIMER **************************]]--




--[[****************  TIMER FOR BLINK AUTO STEP  2 SEC ************]]--

function SetBlinkTimer()
  timerBlink = 2  
  timerBlinkID = gre.timer_set_interval(TimerBlink,500)
end

function TimerBlink()
  if (timerBlink>0) then
    timerBlink = timerBlink - 1
  else
    ToggleBkgStepAuto('Layer_AutoSteps')
  end
end

function ClearBlinkTimer()
    local data
    if timerBlinkID then
      data = gre.timer_clear_interval(timerBlinkID)
    end
end
--[[******************** END BLINK TIMER **************************]]--

--[[
0 = STOP_OVEN_STATE
1 = RUN_SUB_STATE
2 = RUN_MANUAL_STATE
3 = RUN_AUTO_STATE
4 = RUN_MULTILEVEL_STATE
5 = RUN_WASHING_STATE
6 = RDY_NEXTSTEP_STATE
7 = PAUSE_BY_DOOR_STATE
8 = FINISHED_STATE
9 = CONNECT_WATER_STATE
10 = WARNING_STATE
11 = DIRTY_FILTER_STATE
12 = OVERHEAT_STATE
--]]
function CBSetToggleState(control, value)

    if (gToggleState[control] == nil) then
    -- if it doesn't exisit yet create the toggle and set it to off
      gToggleState[control] = 0
    end
    
    if (value ~= nil and gToggleState[control] == value) then
      return
    
    else  
      local data = {}
      local datatxt = {}    
    
      if (value == RDY_NEXTSTEP_STATE)then   --ONLY SMART AND MULTILEVEL
          gindexStep = gindexStep + 1
          if(gindexStep>totalSteps) then
              gindexStep=totalSteps
          end     
          if(previousState == RUN_AUTO_STATE) then
              CBSendRecipeStep()
              gCombiOvenState = RUN_AUTO_STATE
              logger.info("Next level in Smart")
              gre.send_event ("toggle_automatic", gBackendChannel)
              
          elseif(previousState == RUN_MULTILEVEL_STATE) then
              CBSendMLRecipeStep()
              gCombiOvenState = RUN_MULTILEVEL_STATE
              logger.info("Next level in Multilevel")
              gre.send_event ("toggle_multilevel", gBackendChannel)
          end

      elseif (value == PAUSE_BY_DOOR_STATE)then
       
       data["hidden"] = 0  
       gre.set_value("Layer_Warnings.text_Error.text",'Cerrar puerta')
       gre.set_value("Layer_Warnings.text_Message.text",'')
       gre.set_value("Layer_Warnings.text_CallService.text",'')    
       gre.set_value("Layer_Warnings.icon_NonWater.alpha",0)
       gre.set_value("Layer_Warnings.icon_Ready.alpha",0)
       gre.set_value("Layer_Warnings.icon_Service.alpha",0)
       gre.set_value("Layer_Warnings.icon_NonProbe.alpha",0)
       gre.set_value("Layer_Warnings.icon_DoorOpen.alpha",255)
       logger.info("Pause by door state")
           
       if gCombiOvenState == RUN_MULTILEVEL_STATE then
         logger.info("Multilevel pause by open door")
         alert_clearLevelAlert(recipeSelPresets)
         
       end
       
       if gCombiOvenState == RUN_WASHING_STATE then
          oven_state_service.OvenState(OvenEnums.OvenState.PAUSED)
          oven_state_service.UserAction(OvenEnums.UserAction.OPEN_DOOR)
          oven_state_service.logOvenState()
          logger.info("Washing pause by open door") 
       end
       ClearDialogTimer()
       
      elseif (value == RUN_SUB_STATE) then
      
      
        if oven_state_service.getWashingMode() then  -- WASHING MODE
          oven_state_service.OvenState(OvenEnums.OvenState.RUNNING)
          oven_state_service.UserAction(OvenEnums.UserAction.CLOSE_DOOR)
          oven_state_service.logOvenState()
          logger.info("Status resume")
        end
        data["hidden"] = 1
       
      elseif (value == FINISHED_STATE)then
       data["hidden"] = 0  
       gre.set_value("Layer_Warnings.text_Error.text",'¡Listo!')
       gre.set_value("Layer_Warnings.text_Message.text",'')
       gre.set_value("Layer_Warnings.text_CallService.text",'')
       gre.set_value("Layer_Warnings.icon_DoorOpen.alpha",0)   
       gre.set_value("Layer_Warnings.icon_NonWater.alpha",0)
       gre.set_value("Layer_Warnings.icon_Service.alpha",0)
       gre.set_value("Layer_Warnings.icon_NonProbe.alpha",0)
       gre.set_value("Layer_Warnings.icon_Ready.alpha",255) 
       oven_state_service.updateOvenState(OvenEnums.OvenState.FINISHED)
       oven_state_service.logOvenState()
       logger.info("Finished process")
       
       if oven_state_service.getOvenMode() == OvenEnums.OvenMode.WASHING then
          oven_state_service.updateOvenMode(OvenEnums.OvenMode.NONE)
          logger.info("¡Proceso de lavado finalizado!")
          
       elseif oven_state_service.getOvenMode() == OvenEnums.OvenMode.COOKING then
          if oven_state_service.getCookingMode() == OvenEnums.CookingMode.MULTILEVEL then
              logger.info("¡Proceso de multinivel finalizado!")
              CBClearMLCart() --se limpia los niveles
          elseif oven_state_service.getCookingMode() == OvenEnums.CookingMode.MANUAL then
              logger.info("¡Modo manual finalizado!")
              if oven_state_service.getManualSubMode()== OvenEnums.ManualSubMode.PROBE then
                logger.info("¡Cocion por sonda finalizado!")
              elseif oven_state_service.getManualSubMode()== OvenEnums.ManualSubMode.TIME then
                logger.info("¡Cocion por tiempo finalizado!")
              end
          elseif oven_state_service.getCookingMode() == OvenEnums.CookingMode.SMART then
              logger.info("¡Modo smart finalizado!")
          end
       end
       oven_state_service.resetOvenState()
       ClearBlinkTimer()
       SetDialogTimer()
       
      elseif (value == CONNECT_WATER_STATE)then
       data["hidden"] = 0  
       gre.set_value("Layer_Warnings.text_Error.text",'Conectar agua')
       gre.set_value("Layer_Warnings.text_Message.text",'')
       gre.set_value("Layer_Warnings.text_CallService.text",'')
       gre.set_value("Layer_Warnings.icon_DoorOpen.alpha",0)   
       gre.set_value("Layer_Warnings.icon_NonProbe.alpha",0) 
       gre.set_value("Layer_Warnings.icon_Ready.alpha",0)
       gre.set_value("Layer_Warnings.icon_Service.alpha",0)
       gre.set_value("Layer_Warnings.icon_NonWater.alpha",255)

       oven_state_service.updateOvenState(OvenEnums.OvenState.PAUSED)
       logger.info("¡water connection alert!")
       ClearDialogTimer()
      
      elseif (value == WARNING_STATE)then
       data["hidden"] = 0  
       gre.set_value("Layer_Warnings.text_Error.text",'Conectar sonda')
       gre.set_value("Layer_Warnings.text_Message.text",'')
       gre.set_value("Layer_Warnings.text_CallService.text",'')
       gre.set_value("Layer_Warnings.icon_DoorOpen.alpha",0)   
       gre.set_value("Layer_Warnings.icon_Ready.alpha",0)
       gre.set_value("Layer_Warnings.icon_NonWater.alpha",0)
       gre.set_value("Layer_Warnings.icon_Service.alpha",0)
       gre.set_value("Layer_Warnings.icon_NonProbe.alpha",255)
       oven_state_service.updateOvenState(OvenEnums.OvenState.PAUSED)
       logger.info("¡Warning state alert!")
       ClearDialogTimer()
       
      elseif (value == WARNING_THERMO_COLD)then
       data["hidden"] = 0  
       gre.set_value("Layer_Warnings.text_Error.text",'Error #114')
       gre.set_value("Layer_Warnings.text_Message.text",'Sensor Cold defectuoso')
       gre.set_value("Layer_Warnings.text_CallService.text",'Llamar a servicio técnico')
       gre.set_value("Layer_Warnings.icon_DoorOpen.alpha",0)   
       gre.set_value("Layer_Warnings.icon_Ready.alpha",0)
       gre.set_value("Layer_Warnings.icon_NonWater.alpha",0)
       gre.set_value("Layer_Warnings.icon_Service.alpha",255)
       gre.set_value("Layer_Warnings.icon_NonProbe.alpha",0)
       oven_state_service.updateOvenState(OvenEnums.OvenState.PAUSED)
       logger.info("¡Warning cold sensor alert!")
       ClearDialogTimer()
       
      elseif (value == WARNING_THERMO_MAIN)then
       data["hidden"] = 0  
       gre.set_value("Layer_Warnings.text_Error.text",'Error #116')
       gre.set_value("Layer_Warnings.text_Message.text",'Sensor Main defectuoso')
       gre.set_value("Layer_Warnings.text_CallService.text",'Llamar a servicio técnico')
       gre.set_value("Layer_Warnings.icon_DoorOpen.alpha",0)   
       gre.set_value("Layer_Warnings.icon_Ready.alpha",0)
       gre.set_value("Layer_Warnings.icon_NonWater.alpha",0)
       gre.set_value("Layer_Warnings.icon_Service.alpha",255)
       gre.set_value("Layer_Warnings.icon_NonProbe.alpha",0)
       oven_state_service.updateOvenState(OvenEnums.OvenState.PAUSED)
       logger.info("¡Warning main sensor alert!")
       ClearDialogTimer()
       
      elseif (value == WARNING_THERMO_BOILER)then
       data["hidden"] = 0  
       gre.set_value("Layer_Warnings.text_Error.text",'Error #115')
       gre.set_value("Layer_Warnings.text_Message.text",'Sensor Boiler defectuoso')
       gre.set_value("Layer_Warnings.text_CallService.text",'Llamar a servicio técnico')
       gre.set_value("Layer_Warnings.icon_DoorOpen.alpha",0)   
       gre.set_value("Layer_Warnings.icon_Ready.alpha",0)
       gre.set_value("Layer_Warnings.icon_NonWater.alpha",0)
       gre.set_value("Layer_Warnings.icon_Service.alpha",255)
       gre.set_value("Layer_Warnings.icon_NonProbe.alpha",0)
       oven_state_service.updateOvenState(OvenEnums.OvenState.PAUSED)
       logger.info("¡Warning boiler sensor alert!")
       ClearDialogTimer()
       
      elseif (value == WARNING_THERMO_MULPOINT)then
       data["hidden"] = 0  
       gre.set_value("Layer_Warnings.text_Error.text",'Error #116')
       gre.set_value("Layer_Warnings.text_Message.text",'Conectar Sonda 5P')
       gre.set_value("Layer_Warnings.text_CallService.text",'')
       gre.set_value("Layer_Warnings.icon_DoorOpen.alpha",0)   
       gre.set_value("Layer_Warnings.icon_Ready.alpha",0)
       gre.set_value("Layer_Warnings.icon_NonWater.alpha",0)
       gre.set_value("Layer_Warnings.icon_Service.alpha",0)
       gre.set_value("Layer_Warnings.icon_NonProbe.alpha",255)
       oven_state_service.updateOvenState(OvenEnums.OvenState.PAUSED)
       logger.info("¡Warning multipoint sensor alert!")
       ClearDialogTimer()

      elseif (value == WARNING_THERMO_ONEPOINT)then
       data["hidden"] = 0  
       gre.set_value("Layer_Warnings.text_Error.text",'Error #110')
       gre.set_value("Layer_Warnings.text_Message.text",'Conectar Sonda 1P')
       gre.set_value("Layer_Warnings.text_CallService.text",'') 
       gre.set_value("Layer_Warnings.icon_DoorOpen.alpha",0)   
       gre.set_value("Layer_Warnings.icon_Ready.alpha",0)
       gre.set_value("Layer_Warnings.icon_NonWater.alpha",0)
       gre.set_value("Layer_Warnings.icon_Service.alpha",0)
       gre.set_value("Layer_Warnings.icon_NonProbe.alpha",255)
       oven_state_service.updateOvenState(OvenEnums.OvenState.PAUSED)
       logger.info("¡Warning onepoint sensor alert!")
       ClearDialogTimer()
       
      elseif (value == WARNING_LEVEL_SENSOR)then
       data["hidden"] = 0  
       datatxt["Layer_Warnings.text_Message.text"] = 'Error #131'
       gre.set_value("Layer_Warnings.text_Error.text",'Error #131')
       gre.set_value("Layer_Warnings.text_Message.text",'Sensor de nivel defectuoso')
       gre.set_value("Layer_Warnings.text_CallService.text",'Llamar a servicio técnico')
       gre.set_value("Layer_Warnings.icon_DoorOpen.alpha",0)   
       gre.set_value("Layer_Warnings.icon_Ready.alpha",0)
       gre.set_value("Layer_Warnings.icon_NonWater.alpha",0)
       gre.set_value("Layer_Warnings.icon_Service.alpha",255)
       gre.set_value("Layer_Warnings.icon_NonProbe.alpha",0)
       oven_state_service.updateOvenState(OvenEnums.OvenState.PAUSED)
       logger.info("¡Warning level sensor alert!")
       ClearDialogTimer()
       
      elseif (value == DIRTY_FILTER_STATE)then
       data["hidden"] = 0  
       gre.set_value("Layer_Warnings.text_Error.text",'Error #131')
       gre.set_value("Layer_Warnings.text_Message.text",'¡Limpiar filtro de aire!')
       gre.set_value("Layer_Warnings.text_CallService.text",'')
       gre.set_value("Layer_Warnings.icon_DoorOpen.alpha",0)   
       gre.set_value("Layer_Warnings.icon_Ready.alpha",0)
       gre.set_value("Layer_Warnings.icon_NonWater.alpha",0)
       gre.set_value("Layer_Warnings.icon_Service.alpha",255)
       gre.set_value("Layer_Warnings.icon_NonProbe.alpha",0)  
       oven_state_service.updateOvenState(OvenEnums.OvenState.STOP) 
       logger.info("¡Warning: dirty filter!")
       ClearDialogTimer()
       
      elseif (value == OVERHEAT_STATE)then
       data["hidden"] = 0  
       gre.set_value("Layer_Warnings.text_Error.text",'Error #131')
       gre.set_value("Layer_Warnings.text_Message.text",'¡Exceso de temperatura!')
       gre.set_value("Layer_Warnings.text_CallService.text",'Llamar a servicio técnico')
       gre.set_value("Layer_Warnings.icon_DoorOpen.alpha",0)   
       gre.set_value("Layer_Warnings.icon_Ready.alpha",0)
       gre.set_value("Layer_Warnings.icon_NonWater.alpha",0)
       gre.set_value("Layer_Warnings.icon_Service.alpha",255)
       gre.set_value("Layer_Warnings.icon_NonProbe.alpha",0)
       oven_state_service.updateOvenState(OvenEnums.OvenState.STOP)
       logger.info("¡Warning: over heat!")
       ClearDialogTimer()
 
      elseif (value == WARNING_RELAY_FAILURE)then
       data["hidden"] = 0  
       gre.set_value("Layer_Warnings.text_Error.text",'Error #510')
       gre.set_value("Layer_Warnings.text_Message.text",'¡Relayboard program failure!')
       gre.set_value("Layer_Warnings.text_CallService.text",'Reiniciar el equipo')
       gre.set_value("Layer_Warnings.icon_DoorOpen.alpha",0)   
       gre.set_value("Layer_Warnings.icon_Ready.alpha",0)
       gre.set_value("Layer_Warnings.icon_NonWater.alpha",0)
       gre.set_value("Layer_Warnings.icon_Service.alpha",255)
       gre.set_value("Layer_Warnings.icon_NonProbe.alpha",0)
       oven_state_service.updateOvenState(OvenEnums.OvenState.STOP)
       logger.info("¡Warning: Internal communication failure!")
       ClearDialogTimer()
       
      elseif (value == WARNING_COM_FAILURE)then
       data["hidden"] = 0  
       gre.set_value("Layer_Warnings.text_Error.text",'Error #511')
       gre.set_value("Layer_Warnings.text_Message.text",'¡Internal communication failure!')
       gre.set_value("Layer_Warnings.text_CallService.text",'Reiniciar el equipo')
       gre.set_value("Layer_Warnings.icon_DoorOpen.alpha",0)   
       gre.set_value("Layer_Warnings.icon_Ready.alpha",0)
       gre.set_value("Layer_Warnings.icon_NonWater.alpha",0)
       gre.set_value("Layer_Warnings.icon_Service.alpha",255)
       gre.set_value("Layer_Warnings.icon_NonProbe.alpha",0)
       oven_state_service.updateOvenState(OvenEnums.OvenState.STOP)
       logger.info("¡Warning: Internal communication failure!")
       ClearDialogTimer()
       
      else
       data["hidden"] = 1
      end    
      gre.set_layer_attrs("Layer_Warnings",data)   
    end
end


-- checar aqui
function CBToggleControl(mapargs) 
  local toggle	
---RUN BY TOGGLE BUTTON ON SCREEN
  logger.info("Context control: "..mapargs.context_control)
  
  if (mapargs.context_control == 'Layer_Combi_Levels.Combi_BallSlider5' and gCombiOvenState  ~= RUN_SUB_STATE ) then
    gCombiOvenState = RUN_SUB_STATE
    toggle = 'probe'
    logger.info("Probe slider pressed")
    oven_state_service.updateOvenState(OvenEnums.OvenState.RUNNING)
    oven_state_service.logOvenState()
    logger.info("Oven running in probe mode")
    
    --print("statemnt1")
  
  elseif ((mapargs.context_control == 'Layer_Combi_Menu.bkg_SelTime') and (gToggle_Probe==true) and (gCombiOvenState  ~= RUN_SUB_STATE )) then
    gCombiOvenState = RUN_SUB_STATE
    toggle = 'probe'
    logger.info("Preheat button pressed")
    oven_state_service.updateOvenState(OvenEnums.OvenState.RUNNING)
    oven_state_service.logOvenState()
    logger.info("Oven running in preheat mode")
    
    --print("statemnt1-1")  
    
  elseif (mapargs.context_control == 'Layer_Combi_Menu.bkg_Preheat') then
    gCombiOvenState = RUN_SUB_STATE
    toggle = 'preheat'
    oven_state_service.updateOvenState(OvenEnums.OvenState.RUNNING)
    oven_state_service.updateManualSubMode(OvenEnums.ManualSubMode.PREHEAT)
    oven_state_service.logOvenState()
    
    --print("statemnt2: "..toggle)
    
  elseif (mapargs.context_control == 'Layer_Combi_Menu.bkg_Cooling') then
    gCombiOvenState = RUN_SUB_STATE
    toggle = 'cooling'
    logger.info("Cooling button pressed")
    oven_state_service.updateOvenState(OvenEnums.OvenState.RUNNING)
    oven_state_service.updateOvenMode(OvenEnums.OvenMode.COOLING)
    oven_state_service.logOvenState()
    logger.info("Oven running in cooling mode")
    
    print("statemnt3")    
  
  elseif (mapargs.context_control == 'Layer_Combi_Menu.icon_LoopTimer' or mapargs.context_control == 'Layer_Combi_Menu.bkg_LoopTimer') then
    gCombiOvenState = RUN_SUB_STATE
    toggle = 'looptime' 
    logger.info("Looptime button pressed")
    oven_state_service.updateOvenState(OvenEnums.OvenState.RUNNING)
    oven_state_service.updateOvenMode(OvenEnums.OvenMode.COOKING)
    oven_state_service.updateManualSubMode(OvenEnums.ManualSubMode.LOOP)
    oven_state_service.logOvenState()
    logger.info("Oven running in looptime mode")
    
    print("statemnt4") 
       
  elseif  (mapargs.context_control == 'Layer_Combi_Levels.Combi_BallSlider3' and gCombiOvenState  ~= RUN_MANUAL_STATE ) then
    gCombiOvenState = RUN_MANUAL_STATE
    toggle = 'manual'
    logger.info("Time slider pressed")
    oven_state_service.updateOvenState(OvenEnums.OvenState.RUNNING)
    oven_state_service.updateManualSubMode(OvenEnums.ManualSubMode.TIME)
    oven_state_service.logOvenState()
    logger.info("Oven running in time mode")
    print("statemnt5")
          
  elseif  (mapargs.context_control == 'Layer_HomeSettingsBar.bkg_WashControl' or mapargs.context_control == 'Layer_SettingsBar.OperationSelector.bkg_WashControl')then
    gCombiOvenState = RUN_WASHING_STATE
    toggle = 'washing'
    logger.info("Washer button pressed")
    oven_state_service.updateOvenMode(OvenEnums.OvenMode.WASHING)
    --print("statemnt6")
    
    
  elseif (mapargs.context_control == 'Layer_HomeSettingsBar.bkg_Recetas') then
    logger.info("RecipeBook button pressed")
    onRecipeBook = true
    return
    
---STOP BY HOME ACCESS OR SETTINGS BUTTON
  elseif ( (mapargs.context_control == 'Layer_SettingsBar.bkg_Home_On' or mapargs.context_control == 'Layer_SettingsBar.bkg_Menu_On') and ( gToggleState['Layer_Combi_Menu.bkg_Probe'] == 1 ) ) then
    gCombiOvenState = STOP_OVEN_STATE
    gToggle_Probe=false
    toggle = 'probe'
       
    print("statemnt7")

  elseif ( (mapargs.context_control == 'Layer_SettingsBar.bkg_Home_On' or mapargs.context_control == 'Layer_SettingsBar.bkg_Menu_On') and ( gToggleState['Layer_Combi_Menu.bkg_Preheat'] == 1 ) ) then
    gCombiOvenState = STOP_OVEN_STATE
    toggle = 'preheat'
    print("statemnt8")
    
  elseif ( (mapargs.context_control == 'Layer_SettingsBar.bkg_Home_On' or mapargs.context_control == 'Layer_SettingsBar.bkg_Menu_On') and ( gToggleState['Layer_Combi_Menu.bkg_Cooling'] == 1 ) ) then
    gCombiOvenState = STOP_OVEN_STATE
    toggle = 'cooling'
    print("statemnt9")
  
  elseif ( (mapargs.context_control == 'Layer_SettingsBar.bkg_Home_On' or mapargs.context_control == 'Layer_SettingsBar.bkg_Menu_On') and ( gToggleState['Layer_Combi_Menu.bkg_LoopTimer'] == 1 ) ) then
    gCombiOvenState = STOP_OVEN_STATE
    toggle = 'looptime'
    print("statemnt10")
    


---STOP BY MACHINE STATES
  elseif ( (mapargs.context_control == 'Layer_SettingsBar.bkg_Home_On' or mapargs.context_control == 'Layer_SettingsBar.bkg_Menu_On') and ( gCombiOvenState == RUN_SUB_STATE ) ) then
    logger.info("Probe: Exit by home pressed")
    gCombiOvenState = STOP_OVEN_STATE
    gToggle_Probe = false
    oven_state_service.resetOvenState()
    oven_state_service.logOvenState()
    logger.info("Oven stop")
    --print("by home in sbstat")
    return

  elseif ( (mapargs.context_control == 'Layer_SettingsBar.bkg_Home_On' or mapargs.context_control == 'Layer_SettingsBar.bkg_Menu_On') and ( gCombiOvenState == RUN_MANUAL_STATE ) ) then
    logger.info("Time: Exit by home pressed")
    gCombiOvenState = STOP_OVEN_STATE
    toggle = 'manual'
    oven_state_service.resetOvenState()
    oven_state_service.logOvenState()
    logger.info("Oven stop")
    --print("statemnt11")
   
  elseif ( (mapargs.context_control == 'Layer_SettingsBar.bkg_Home_On' or mapargs.context_control == 'Layer_SettingsBar.bkg_Menu_On' or mapargs.context_control == 'Layer_SettingsBar.bkg_Back') and ( gCombiOvenState  == RUN_AUTO_STATE ) ) then
    gCombiOvenState = STOP_OVEN_STATE
    toggle = 'automatic'
    logger.info("Smart: Exit by home pressed")
    oven_state_service.resetOvenState()
    oven_state_service.logOvenState()
    logger.info("Oven stop")
    gInitTemperature = 0
    --print("statemnt12")
  elseif ( mapargs.context_control == 'Layer_MultiLevel.btn_clear') and ( gCombiOvenState == RUN_MULTILEVEL_STATE) then
    logger.info("ML: Clear button pressed")
    gCombiOvenState = STOP_OVEN_STATE
    toggle = 'multilevel'
    oven_state_service.logOvenState()
    CBClearMLCart()  -- se limpia los niveles     
 
  elseif ((mapargs.context_control == 'Layer_SettingsBar.bkg_Home_On' or mapargs.context_control == 'Layer_SettingsBar.bkg_Menu_On') and ( gCombiOvenState == RUN_MULTILEVEL_STATE) ) then
    gCombiOvenState = STOP_OVEN_STATE
    toggle = 'multilevel'
    logger.info("Multilevel: Exit by home pressed")
    oven_state_service.resetOvenState()
    oven_state_service.logOvenState()
    CBClearMLCart()  -- se limpia los niveles     
    --print("statemnt13")
    
  elseif ( (mapargs.context_control == 'Layer_SettingsBar.bkg_Home_On' or mapargs.context_control == 'Layer_SettingsBar.bkg_Menu_On') and ( gCombiOvenState == RUN_WASHING_STATE) ) then
    gCombiOvenState = STOP_OVEN_STATE
    toggle = 'washing'
    
    logger.info("Washing: Exit by home pressed")
    oven_state_service.resetOvenState()
    oven_state_service.logOvenState()
    logger.info("Oven stop")
    --print("statemnt14")
 
  elseif( mapargs.context_control == 'Layer_AutoProcess.bkg_gotoProcess' ) then 
    logger.info("Start Process button pressed")
    CBDisplayRecipeSteps_Intelligent()   -- se muestra los pasos y parametros de la receta en pantalla
    CBSendRecipeStep()                   -- se envia al backend la informacion de cada paso
    gCombiOvenState = RUN_AUTO_STATE     -- se pone en modo run
    previousState = RUN_AUTO_STATE       -- se actualiza ek estado del horno previo
    ClearBlinkTimer()                    -- se limpia cualquier alerta
    SetBlinkTimer()                      -- se blinkea los pasos
    Wait(2)
    toggle = 'automatic'
    oven_state_service.updateOvenState(OvenEnums.OvenState.RUNNING)
    oven_state_service.updateOvenMode(OvenEnums.OvenMode.COOKING)
    oven_state_service.updateCookingMode(OvenEnums.CookingMode.SMART)
    oven_state_service.logOvenState()
    logger.info("Oven running in smart mode")
    print("statemnt16")
    
  
    
---TOGGLE SPRAY PULSE AND CHANGE TIME -> PROBE
  elseif (mapargs.context_control == 'Layer_Combi_Menu.bkg_Spray' or mapargs.context_control == 'Layer_Combi_Menu.bkg_Spray'  or mapargs.context_control == 'Layer_AutoSteps.icon_Spray') then
    toggle = 'spray'
    logger.info("Spray button pressed")
    oven_state_service.updateCookingMode(OvenEnums.CookingMode.MANUAL)
    oven_state_service.updateManualSubMode(OvenEnums.ManualSubMode.SPRAY)
    oven_state_service.logOvenState()
    
    --print("statemnt17")
  
  elseif (mapargs.context_control == 'Layer_Combi_Menu.icon_Probe' and gCombiOvenState == RUN_SUB_STATE ) then
    toggle = 'probe'
    --gCombiOvenState = STOP_OVEN_STATE -- continua el modo time, no para el horno
    logger.info("Time button pressed")
    gToggle_Probe=false
    --print("statemnt18")
    
  elseif (mapargs.context_control == 'Layer_Combi_Menu.icon_Probe' or mapargs.context_control == 'Layer_Combi_Menu.bkg_Probe') and gCombiOvenState == STOP_OVEN_STATE then
    logger.info("Probe button pressed")
    oven_state_service.updateOvenMode(OvenEnums.OvenMode.COOKING)
    oven_state_service.updateCookingMode(OvenEnums.CookingMode.MANUAL)
    oven_state_service.updateManualSubMode(OvenEnums.ManualSubMode.PROBE)
    oven_state_service.logOvenState()
    gToggle_Probe = true
    return
  
  --Flags Clean
  elseif (mapargs.context_control == 'Layer_SettingsBar.bkg_Home_On' and onRecipeBook) then
    isEditRecipeBook = false  --limpia la bandera de edicion de recetas
    gFilterActived = 0  --se limpia el filtro de busqueda en el recetario
    onRecipeBook = false
    isRecipeBook = false
    logger.info("RecipeBook Flags Cleaned")
    return
    
  else 
    --clear global variables
    gToggle_Probe=false
    createRecipe  = {}
    prevIndxRecipe = 1
    nowIndxRecipe  = 1
    gFilterActived = 0
    typeRecipe = nil
    isEditRecipeBook = false
    oven_state_service.logOvenState()
    print("statemnt19")
    return
  
  end
  gre.send_event ("toggle_"..toggle, gBackendChannel)
  logger.info("Sending data to the backend: -> ".."toggle_"..toggle)
end



function CBSetTogglePreheat(control, value)
    local alpha_value
    local data = {}
    logger.info("Toggle Preheat")
    
    if (gToggleState[control] == nil) then
    -- if it doesn't exisit yet create the toggle and set it to off
      gToggleState[control] = 0
      alpha_value=0
    end
    
    if (value ~= nil and gToggleState[control] == value) then
      return
    end
    
    if (value == nil) then
      if (gToggleState[control] == 0) then
        gToggleState[control] = 1       
      else
        gToggleState[control] = 0
      end
    else
      gToggleState[control] = value
      alpha_value= (255 * value )  
      if (value == 1)then
          gre.set_value("Layer_Combi_Menu.bkg_Cooling.pressed_key", 0)
      else 
          data["Layer_Combi_Levels.Combi_TextSlider2.percent"] = string.format('%d°C', gTemperature)
          gre.set_data(data)
      end
    end
    gre.set_value("Layer_Combi_Menu.bar_Preheat.grd_hidden", false)
    gre.set_value("Layer_Combi_Menu.text_Preheat.grd_hidden", false)
    
    gre.set_value("Layer_Combi_Menu.bkg_Preheat.pressed_key", alpha_value)
    gre.set_value("Layer_Combi_Menu.bar_Preheat.percent", 0)
    gre.set_value("Layer_Combi_Menu.bar_Preheat.alpha", alpha_value)
    gre.set_value("Layer_Combi_Menu.text_Preheat.alpha", alpha_value)

    gInitTemperature = 0             --Variable to calc DeltaTemp bar
end



function CBSetToggleCooling(control, value)
    local alpha_value
    logger.info("Toggle Cooling")
    
    if (gToggleState[control] == nil) then
    -- if it doesn't exisit yet create the toggle and set it to off
      gToggleState[control] = 0
      alpha_value=0
    end
    
    if (value ~= nil and gToggleState[control] == value) then
      return
    end
    
    if (value == nil) then
      if (gToggleState[control] == 0) then
        gToggleState[control] = 1       
      else
        gToggleState[control] = 0
      end
    else
      gToggleState[control] = value
      alpha_value= (255 * value )
      if (value == 1)then
         gre.set_value("Layer_Combi_Menu.bkg_Preheat.pressed_key", 0)
      end
    end
    gre.set_value("Layer_Combi_Menu.bkg_Cooling.pressed_key", alpha_value)
    gre.set_value("Layer_Combi_Menu.bar_Cooling.percent", 0)
    gre.set_value("Layer_Combi_Menu.bar_Cooling.alpha", alpha_value)
    gre.set_value("Layer_Combi_Menu.text_Cooling.alpha", alpha_value)
    gInitTemperature = 0
end



function CBSetToggleProbe(control, value)
    local alpha_value
    
    if (gToggleState[control] == nil) then
    -- if it doesn't exisit yet create the toggle and set it to off
      gToggleState[control] = 0
      alpha_value=0
    end
    
    if (value ~= nil and gToggleState[control] == value) then
      return
    end
    
    if (value == nil) then
      if (gToggleState[control] == 0) then
        gToggleState[control] = 1
      else
        gToggleState[control] = 0
        
      end
    else
      gToggleState[control] = value
      alpha_value= (255 * value )
    end  
    --gre.set_value("Layer_Combi_Menu.icon_Time.pressed_key", alpha_value)
    --gre.set_value("Layer_Combi_Menu.bkg",value,...)
    gre.set_value("Layer_Combi_Menu.icon_Probe.pressed_key", alpha_value)
    gre.set_value("Layer_Combi_Menu.bkg_Probe.pressed_key", alpha_value)
    --print("alphaTime:",alpha_value)
end


function CBSetToggleLoopTime(control, value)
    local alpha_value
    logger.info("Toggle Looping")
    if (gToggleState[control] == nil) then
    -- if it doesn't exisit yet create the toggle and set it to off
      gToggleState[control] = 0
      alpha_value=0
    end
    
    if (value ~= nil and gToggleState[control] == value) then
      return
    end
    
    if (value == nil) then
      if (gToggleState[control] == 0) then
        gToggleState[control] = 1
      else
        gToggleState[control] = 0
      end
    else
      gToggleState[control] = value
      alpha_value= (255 * value )
      if (value == 1)then
         gre.set_value("Layer_Combi_Menu.bkg_Preheat.pressed_key", 0)
         gre.set_value("Layer_Combi_Menu.bkg_Cooling.pressed_key", 0)
      end
    end   
    gre.set_value("Layer_Combi_Menu.bkg_LoopTimer.pressed_key", alpha_value)
end


function ToggleBkgStepAuto(control)
  local data = {} 
  logger.info("Toggle Looping")
  
  if (gToggleState[control] == nil) then
   -- if it doesn't exisit yet create the toggle and set it to off
     gToggleState[control] = 0
  end
   
  if (gToggleState[control] == 0) then
      gToggleState[control] = 1
      data["Layer_ListTableSteps.RecipesAutoSteps.bkg."..gPreviousIndex..".1"] = 0--'images/bar_list_step.png'
  else
      gToggleState[control] = 0
      data["Layer_ListTableSteps.RecipesAutoSteps.bkg."..gindexStep..".1"] = 255--'images/bar_liststep_highlight.png'
  end
  gre.set_data(data)
end




function CBSelectWashCycle(mapargs)
  local user_select
  oven_state_service.updateOvenState(OvenEnums.OvenState.RUNNING)
  oven_state_service.updateOvenMode(OvenEnums.OvenMode.WASHING)
  
  if (mapargs.context_control == 'Layer_ModeWashing.01_bkg_WashOut') then  --lavado rapido
    TIME_WASHING=720
    user_select = 1
    oven_state_service.updateWashingMode(OvenEnums.WashingMode.QUICK)
    
  elseif (mapargs.context_control == 'Layer_ModeWashing.02_bkg_Shining') then --Descalcificado
    TIME_WASHING=1440
    user_select = 2
    oven_state_service.updateWashingMode(OvenEnums.WashingMode.DESCALCIFICATION)
    --gHrsSteam = row.HrsSteam - math.ceil(TIME_WASHING * 0.6)
    --gHrsConv = row.HrsConv - math.ceil(TIME_WASHING * 0.4)
    
  elseif (mapargs.context_control == 'Layer_ModeWashing.03_bkg_ECO') then --Lavado Eco
    TIME_WASHING=2460
    user_select = 3
    oven_state_service.updateWashingMode(OvenEnums.WashingMode.ECO)
    --gHrsSteam = row.HrsSteam - math.ceil(TIME_WASHING * 0.5)
    --gHrsConv = row.HrsConv - math.ceil(TIME_WASHING * 0.5)
    
  elseif (mapargs.context_control == 'Layer_ModeWashing.04_bkg_Intermedio') then  --Lavado Intermedio
    TIME_WASHING=3600
    user_select = 4
    oven_state_service.updateWashingMode(OvenEnums.WashingMode.INTERMEDIATE)
    --gHrsSteam = row.HrsSteam - math.ceil(TIME_WASHING * 0.5)
    --gHrsConv = row.HrsConv - math.ceil(TIME_WASHING * 0.5)
    
  elseif (mapargs.context_control == 'Layer_ModeWashing.05_bkg_Regular') then --Lavado Regular
    TIME_WASHING=5700
    user_select = 5
    oven_state_service.updateWashingMode(OvenEnums.WashingMode.REGULAR)
    --gHrsSteam = row.HrsSteam - math.ceil(TIME_WASHING * 0.5)
    --gHrsConv = row.HrsConv - math.ceil(TIME_WASHING * 0.5)
    
  elseif (mapargs.context_control == 'Layer_ModeWashing.06_bkg_Intenso') then --Lavado Intenso
    TIME_WASHING=9000
    user_select = 6
    oven_state_service.updateWashingMode(OvenEnums.WashingMode.INTENSE)
    --gHrsSteam = row.HrsSteam - math.ceil(TIME_WASHING * 0.7)
    --gHrsConv = row.HrsConv - math.ceil(TIME_WASHING * 0.3)
    
  end
  oven_state_service.logOvenState()
  CBUpdateTime(TIME_WASHING, 0)
  CBUpdateWashCycle(user_select)
  Wait(5)
end


function CBExecuteWashRecommend()
  local user_select
  local data = {}
  local get_recommend = gre.get_value("Layer_DialogBoxSuggest.text_InputField.text" )
  oven_state_service.updateOvenState(OvenEnums.OvenState.RUNNING)
  oven_state_service.updateOvenMode(OvenEnums.OvenMode.WASHING)

      
  if (get_recommend == 'Enjuague rapido    12 min') then
    gre.set_value("Layer_WashingStatus.Group_DoorStatus.grd_hidden",0)
    gre.set_value("Layer_WashingStatus.Group_WashPils.grd_hidden",1)
    gre.set_value("Layer_WashingStatus.Group_Discaler.grd_hidden",1)
    data["Layer_TopBar.IconMainMenu_Status.mode_status"] = 'Siga las indicaciones'
    data["Layer_WashingStatus.text_TitleWashProcess.washing_title"] = 'Enjuague rápido'
    data["Layer_WashingStatus.text_StepMsg.text"] = ''
    TIME_WASHING=720
    user_select = 1
    oven_state_service.updateWashingMode(OvenEnums.WashingMode.QUICK)
    
  elseif (get_recommend == 'Descalcificado     24 min') then
    gre.set_value("Layer_WashingStatus.Group_DoorStatus.grd_hidden",1)
    gre.set_value("Layer_WashingStatus.Group_WashPils.grd_hidden",1)
    gre.set_value("Layer_WashingStatus.Group_Discaler.grd_hidden",0)
    data["Layer_TopBar.IconMainMenu_Status.mode_status"] = 'Siga las indicaciones'
    data["Layer_WashingStatus.text_TitleWashProcess.washing_title"] = 'Descalcificado'
    data["Layer_WashingStatus.text_StepMsg.text"] = 'Mantener lleno deposito descalcificante'
    TIME_WASHING=1440
    user_select = 2
    oven_state_service.updateWashingMode(OvenEnums.WashingMode.DESCALCIFICATION)
    
  elseif (get_recommend == 'Lavado Eco   66 min') then
    gre.set_value("Layer_WashingStatus.Group_DoorStatus.grd_hidden",1)
    gre.set_value("Layer_WashingStatus.Group_WashPils.grd_hidden",0)
    gre.set_value("Layer_WashingStatus.Group_Discaler.grd_hidden",1)
    data["Layer_TopBar.IconMainMenu_Status.mode_status"] = 'Siga las indicaciones'
    data["Layer_WashingStatus.text_TitleWashProcess.washing_title"] = 'Lavado ECO'
    data["Layer_WashingStatus.text_StepMsg.text"] = 'Mantener lleno los depositos'
    TIME_WASHING=2460
    user_select = 3
    oven_state_service.updateWashingMode(OvenEnums.WashingMode.ECO)
    
  elseif (get_recommend == 'Lavado Intermedio   90 min') then
    gre.set_value("Layer_WashingStatus.Group_DoorStatus.grd_hidden",1)
    gre.set_value("Layer_WashingStatus.Group_WashPils.grd_hidden",0)
    gre.set_value("Layer_WashingStatus.Group_Discaler.grd_hidden",1)
    data["Layer_TopBar.IconMainMenu_Status.mode_status"] = 'Siga las indicaciones'
    data["Layer_WashingStatus.text_TitleWashProcess.washing_title"] = 'Lavado intermedio'
    data["Layer_WashingStatus.text_StepMsg.text"] = 'Mantener lleno los depositos'
    TIME_WASHING=3600
    user_select = 4
    oven_state_service.updateWashingMode(OvenEnums.WashingMode.INTERMEDIATE)
    
  elseif (get_recommend == 'Lavado Regular   120 min') then
    gre.set_value("Layer_WashingStatus.Group_DoorStatus.grd_hidden",1)
    gre.set_value("Layer_WashingStatus.Group_WashPils.grd_hidden",0)
    gre.set_value("Layer_WashingStatus.Group_Discaler.grd_hidden",1)
    data["Layer_TopBar.IconMainMenu_Status.mode_status"] = 'Siga las indicaciones'
    data["Layer_WashingStatus.text_TitleWashProcess.washing_title"] = 'Lavado Regular'
    data["Layer_WashingStatus.text_StepMsg.text"] = 'Mantener lleno los depositos'
    TIME_WASHING=5700
    user_select = 5
    oven_state_service.updateWashingMode(OvenEnums.WashingMode.REGULAR)
    
  elseif (get_recommend == 'Lavado Intenso   150 min') then
    gre.set_value("Layer_WashingStatus.Group_DoorStatus.grd_hidden",1)
    gre.set_value("Layer_WashingStatus.Group_WashPils.grd_hidden",0)
    gre.set_value("Layer_WashingStatus.Group_Discaler.grd_hidden",1)
    data["Layer_TopBar.IconMainMenu_Status.mode_status"] = 'Siga las indicaciones'
    data["Layer_WashingStatus.text_TitleWashProcess.washing_title"] = 'Lavado intenso'
    data["Layer_WashingStatus.text_StepMsg.text"] = 'Mantener lleno los depositos'
    TIME_WASHING=9000
    user_select = 6
    oven_state_service.updateWashingMode(OvenEnums.WashingMode.INTENSE)
    
  end
  
  oven_state_service.logOvenState()
  gre.set_data(data)
  CBUpdateTime(TIME_WASHING, 0)
  CBUpdateWashCycle(user_select)
  Wait(5)
end

local function ToggleShowCPUTemp(control)
  local data = {} 
  logger.info("Toggle CPU Temperature")
  
  if (gToggleState[control] == nil) then
   -- if it doesn't exisit yet create the toggle and set it to off
     gToggleState[control] = 0
  end

  if (gToggleState[control] == 0) then
      gToggleState[control] = 1
      data["Layer_RelayState.17_text_Opt17.pressed_btn"] = 255
  else
      gToggleState[control] = 0
      data["Layer_RelayState.17_text_Opt17.pressed_btn"] = 0
  end
  gre.set_data(data)
end



function CBToggleRelayService(mapargs)
  local kx_select
 
  if (mapargs.context_control == 'Layer_RelayState.01_text_Opt1' ) then
    kx_select ='1'
    
  elseif (mapargs.context_control == 'Layer_RelayState.02_text_Opt2' ) then
    kx_select ='2'
    
  elseif (mapargs.context_control == 'Layer_RelayState.03_text_Opt3' ) then
    kx_select ='3'

  elseif( mapargs.context_control == 'Layer_RelayState.04_text_Opt4' ) then 
    kx_select ='4'
    
  elseif( mapargs.context_control == 'Layer_RelayState.05_text_Opt5' ) then 
    kx_select ='5'
      
  elseif( mapargs.context_control == 'Layer_RelayState.06_text_Opt6' ) then 
    kx_select ='6'  
  
  elseif( mapargs.context_control == 'Layer_RelayState.07_text_Opt7' ) then 
    kx_select ='7'
  
  elseif( mapargs.context_control == 'Layer_RelayState.08_text_Opt8' ) then 
    kx_select ='8'
  
  elseif( mapargs.context_control == 'Layer_RelayState.09_text_Opt9' ) then 
    kx_select ='9'  
    
  elseif( mapargs.context_control == 'Layer_RelayState.10_text_Opt10' ) then 
    kx_select ='0'
    
  elseif( mapargs.context_control == 'Layer_RelayState.11_text_Opt11' ) then 
    kx_select ='11'
    
  elseif( mapargs.context_control == 'Layer_RelayState.12_text_Opt12' ) then 
    kx_select ='12'
    
  elseif( mapargs.context_control == 'Layer_RelayState.13_text_Opt13' ) then 
    kx_select ='13'
    
  elseif( mapargs.context_control == 'Layer_RelayState.14_text_Opt14' ) then 
    kx_select ='14'
    
  elseif( mapargs.context_control == 'Layer_RelayState.15_text_Opt15' ) then 
    kx_select ='15'
 
  elseif( mapargs.context_control == 'Layer_RelayState.16_text_Opt16' ) then 
    kx_select ='16'
      
  elseif( mapargs.context_control == 'Layer_RelayState.17_text_Opt17' ) then
    ToggleShowCPUTemp(mapargs.context_control)
    return
  elseif( mapargs.context_control == 'Layer_RelayState.18_text_Opt18' ) then 
    kx_select ='18'
    
  else return
  end
  logger.info("Toggle Relay Service: "..kx_select)
  CBUpdateRelay(kx_select)
end
