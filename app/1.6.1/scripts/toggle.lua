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

gToggleState = {} -- table used to track state for all toggles
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


--[[***********  TIMER FOR POP UP WINDOW MESSAGES ****************]]--
function SetDialogBoxTimer()
  timer = 2  
  timerID = gre.timer_set_interval(TimerOff,250)
end


function ClearDialogTimer()
    local data
    data = gre.timer_clear_interval(timerID)
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
    data = gre.timer_clear_interval(timerBlinkID)
end
--[[******************** END BLINK TIMER **************************]]--


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
    
      if (value == RDY_NEXTSTEP_STATE)then
          gindexStep = gindexStep + 1
          if(gindexStep>totalSteps) then
              gindexStep=totalSteps
          end     
          if(previousState == RUN_AUTO_STATE) then
              CBSendRecipeStep()
              gCombiOvenState = RUN_AUTO_STATE
              gre.send_event ("toggle_automatic", gBackendChannel)
              
          elseif(previousState == RUN_MULTILEVEL_STATE) then
              CBSendMLRecipeStep()
              gCombiOvenState = RUN_MULTILEVEL_STATE
              gre.send_event ("toggle_multilevel", gBackendChannel)
          end

      elseif (value == PAUSE_BY_DOOR_STATE)then
       data["hidden"] = 0  
       datatxt["Layer_Warnings.text_Message.text"] = 'Cerrar puerta'
       gre.set_data(datatxt)     
       gre.set_value("Layer_Warnings.icon_NonWater.alpha",0)
       gre.set_value("Layer_Warnings.icon_Ready.alpha",0)
       gre.set_value("Layer_Warnings.icon_Service.alpha",0)
       gre.set_value("Layer_Warnings.icon_NonProbe.alpha",0)
       gre.set_value("Layer_Warnings.icon_DoorOpen.alpha",255)
       ClearDialogTimer()
    
      elseif (value == FINISHED_STATE)then
       data["hidden"] = 0  
       datatxt["Layer_Warnings.text_Message.text"] = '¡Listo!'
       gre.set_data(datatxt)  
       gre.set_value("Layer_Warnings.icon_DoorOpen.alpha",0)   
       gre.set_value("Layer_Warnings.icon_NonWater.alpha",0)
       gre.set_value("Layer_Warnings.icon_Service.alpha",0)
       gre.set_value("Layer_Warnings.icon_NonProbe.alpha",0)
       gre.set_value("Layer_Warnings.icon_Ready.alpha",255)   
       ClearBlinkTimer()
       SetDialogTimer()
       
      elseif (value == CONNECT_WATER_STATE)then
       data["hidden"] = 0  
       datatxt["Layer_Warnings.text_Message.text"] = 'Conectar agua'
       gre.set_data(datatxt)  
       gre.set_value("Layer_Warnings.icon_DoorOpen.alpha",0)   
       gre.set_value("Layer_Warnings.icon_NonProbe.alpha",0) 
       gre.set_value("Layer_Warnings.icon_Ready.alpha",0)
       gre.set_value("Layer_Warnings.icon_Service.alpha",0)
       gre.set_value("Layer_Warnings.icon_NonWater.alpha",255)
       ClearDialogTimer()
      
      elseif (value == WARNING_STATE)then
       data["hidden"] = 0  
       datatxt["Layer_Warnings.text_Message.text"] = 'Conectar sonda'
       gre.set_data(datatxt)  
       gre.set_value("Layer_Warnings.icon_DoorOpen.alpha",0)   
       gre.set_value("Layer_Warnings.icon_Ready.alpha",0)
       gre.set_value("Layer_Warnings.icon_NonWater.alpha",0)
       gre.set_value("Layer_Warnings.icon_Service.alpha",0)
       gre.set_value("Layer_Warnings.icon_NonProbe.alpha",255)
       ClearDialogTimer()
       
      elseif (value == DIRTY_FILTER_STATE)then
       data["hidden"] = 0  
       datatxt["Layer_Warnings.text_Message.text"] = '¡Limpiar filtro de aire!'
       gre.set_data(datatxt)  
       gre.set_value("Layer_Warnings.icon_DoorOpen.alpha",0)   
       gre.set_value("Layer_Warnings.icon_Ready.alpha",0)
       gre.set_value("Layer_Warnings.icon_NonWater.alpha",0)
       gre.set_value("Layer_Warnings.icon_Service.alpha",255)
       gre.set_value("Layer_Warnings.icon_NonProbe.alpha",0)
       --SetDialogTimer()
       ClearDialogTimer()
       
      elseif (value == OVERHEAT_STATE)then
       data["hidden"] = 0  
       datatxt["Layer_Warnings.text_Message.text"] = '¡Exceso de temperatura!'
       gre.set_data(datatxt)  
       gre.set_value("Layer_Warnings.icon_DoorOpen.alpha",0)   
       gre.set_value("Layer_Warnings.icon_Ready.alpha",0)
       gre.set_value("Layer_Warnings.icon_NonWater.alpha",0)
       gre.set_value("Layer_Warnings.icon_Service.alpha",255)
       gre.set_value("Layer_Warnings.icon_NonProbe.alpha",0)
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
  
  print("cntx:"..mapargs.context_control)
---RUN BY TOGGLE BUTTON ON SCREEN
  if (mapargs.context_control == 'Layer_Combi_Levels.Combi_BallSlider5' and gCombiOvenState  ~= RUN_SUB_STATE ) then
    gCombiOvenState = RUN_SUB_STATE
    toggle = 'probe'
    --print("statemnt1")
  
  elseif ((mapargs.context_control == 'Layer_Combi_Menu.bkg_SelTime') and (gToggle_Probe==true) and (gCombiOvenState  ~= RUN_SUB_STATE )) then
    gCombiOvenState = RUN_SUB_STATE
    toggle = 'probe'
    --print("statemnt1-1")  
    
  elseif (mapargs.context_control == 'Layer_Combi_Menu.bkg_Preheat') then
    gCombiOvenState = RUN_SUB_STATE
    toggle = 'preheat'
    --print("statemnt2")
    
  elseif (mapargs.context_control == 'Layer_Combi_Menu.bkg_Cooling') then
    gCombiOvenState = RUN_SUB_STATE
    toggle = 'cooling'
    --print("statemnt3")    
  
  elseif (mapargs.context_control == 'Layer_Combi_Menu.icon_LoopTimer' or mapargs.context_control == 'Layer_Combi_Menu.bkg_LoopTimer') then
    gCombiOvenState = RUN_SUB_STATE
    toggle = 'looptime' 
    --print("statemnt4") 
       
  elseif  (mapargs.context_control == 'Layer_Combi_Levels.Combi_BallSlider3' and gCombiOvenState  ~= RUN_MANUAL_STATE ) then
    gCombiOvenState = RUN_MANUAL_STATE
    toggle = 'manual'
    --print("statemnt5")
          
  elseif  (mapargs.context_control == 'Layer_HomeSettingsBar.bkg_WashControl' or mapargs.context_control == 'Layer_SettingsBar.OperationSelector.bkg_WashControl')then
    gCombiOvenState = RUN_WASHING_STATE
    toggle = 'washing'
    --print("statemnt6")
    
       
    
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
    gCombiOvenState = STOP_OVEN_STATE
    gToggle_Probe=false
    print("by home in sbstat")
    return

  elseif ( (mapargs.context_control == 'Layer_SettingsBar.bkg_Home_On' or mapargs.context_control == 'Layer_SettingsBar.bkg_Menu_On') and ( gCombiOvenState == RUN_MANUAL_STATE ) ) then
    gCombiOvenState = STOP_OVEN_STATE
    toggle = 'manual'
    print("statemnt11")
   
  elseif ( (mapargs.context_control == 'Layer_SettingsBar.bkg_Home_On' or mapargs.context_control == 'Layer_SettingsBar.bkg_Menu_On' or mapargs.context_control == 'Layer_SettingsBar.bkg_Back') and ( gCombiOvenState  == RUN_AUTO_STATE ) ) then
    gCombiOvenState = STOP_OVEN_STATE
    toggle = 'automatic'
    gInitTemperature = 0
    print("statemnt12")
    
  elseif ( (mapargs.context_control == 'Layer_SettingsBar.bkg_Home_On' or mapargs.context_control == 'Layer_SettingsBar.bkg_Menu_On' or mapargs.context_control == 'Layer_MultiLevel.btn_clear') and ( gCombiOvenState == RUN_MULTILEVEL_STATE) ) then
    gCombiOvenState = STOP_OVEN_STATE
    toggle = 'multilevel'
    print("statemnt13")
    
  elseif ( (mapargs.context_control == 'Layer_SettingsBar.bkg_Home_On' or mapargs.context_control == 'Layer_SettingsBar.bkg_Menu_On') and ( gCombiOvenState == RUN_WASHING_STATE) ) then
    gCombiOvenState = STOP_OVEN_STATE
    toggle = 'washing'
    print("statemnt14")
 
  elseif( mapargs.context_control == 'Layer_AutoProcess.bkg_gotoProcess' ) then 
    CBDisplayRecipeSteps_Intelligent()
    CBSendRecipeStep() 
    gCombiOvenState = RUN_AUTO_STATE
    previousState = RUN_AUTO_STATE
    ClearBlinkTimer()
    SetBlinkTimer()
    Wait(2)
    toggle = 'automatic'
    --print("statemnt16")
    

    
---TOGGLE SPRAY PULSE AND CHANGE TIME -> PROBE
  elseif (mapargs.context_control == 'Layer_Combi_Menu.bkg_Spray' or mapargs.context_control == 'Layer_Combi_Menu.bkg_Spray'  or mapargs.context_control == 'Layer_AutoSteps.icon_Spray') then
    toggle = 'spray'
    --print("statemnt17")
  
  elseif (mapargs.context_control == 'Layer_Combi_Menu.icon_Probe' and gCombiOvenState == RUN_SUB_STATE ) then
    toggle = 'probe'
    gCombiOvenState = STOP_OVEN_STATE
    gToggle_Probe=false
    --print("statemnt18")
  
  else 
    --clear global variables
    gToggle_Probe=false
    createRecipe  = {}
    prevIndxRecipe = 1
    nowIndxRecipe  = 1
    gFilterActived = 0
    typeRecipe = nil  
    print("statemnt19")
    return
  
  end
  gre.send_event ("toggle_"..toggle, gBackendChannel)
  --print("toggle_"..toggle)
end



function CBSetTogglePreheat(control, value)
    local alpha_value
    local data = {}
    
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
    gre.set_value("Layer_Combi_Menu.bkg_Preheat.pressed_key", alpha_value)
    gre.set_value("Layer_Combi_Menu.bar_Preheat.percent", 0)
    gre.set_value("Layer_Combi_Menu.bar_Preheat.alpha", alpha_value)
    gre.set_value("Layer_Combi_Menu.text_Preheat.alpha", alpha_value)
    gInitTemperature = 0             --Variable to calc DeltaTemp bar
end



function CBSetToggleCooling(control, value)
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
  
  if (mapargs.context_control == 'Layer_ModeWashing.01_bkg_WashOut') then
    TIME_WASHING=720
    user_select = 1
    
  elseif (mapargs.context_control == 'Layer_ModeWashing.02_bkg_Shining') then
    TIME_WASHING=1440
    user_select = 2
    
  elseif (mapargs.context_control == 'Layer_ModeWashing.03_bkg_ECO') then
    TIME_WASHING=2460
    user_select = 3
    
  elseif (mapargs.context_control == 'Layer_ModeWashing.04_bkg_Intermedio') then
    TIME_WASHING=3600
    user_select = 4
    
  elseif (mapargs.context_control == 'Layer_ModeWashing.05_bkg_Regular') then
    TIME_WASHING=5700
    user_select = 5
    
  elseif (mapargs.context_control == 'Layer_ModeWashing.06_bkg_Intenso') then
    TIME_WASHING=9000
    user_select = 6
    
  end
  CBUpdateTime(TIME_WASHING, 0)
  CBUpdateWashCycle(user_select)
  Wait(5)
end


function CBExecuteWashRecommend()
  local user_select
  local data = {}
  local get_recommend = gre.get_value("Layer_DialogBoxSuggest.text_InputField.text" )
  
  if (get_recommend == 'Enjuague rapido    12 min') then
    gre.set_value("Layer_WashingStatus.Group_DoorStatus.grd_hidden",0)
    gre.set_value("Layer_WashingStatus.Group_WashPils.grd_hidden",1)
    gre.set_value("Layer_WashingStatus.Group_Discaler.grd_hidden",1)
    data["Layer_TopBar.IconMainMenu_Status.mode_status"] = 'Siga las indicaciones'
    data["Layer_WashingStatus.text_TitleWashProcess.washing_title"] = 'Enjuague rápido'
    data["Layer_WashingStatus.text_StepMsg.text"] = ''
    TIME_WASHING=720
    user_select = 1
    
  elseif (get_recommend == 'Descalcificado     24 min') then
    gre.set_value("Layer_WashingStatus.Group_DoorStatus.grd_hidden",1)
    gre.set_value("Layer_WashingStatus.Group_WashPils.grd_hidden",1)
    gre.set_value("Layer_WashingStatus.Group_Discaler.grd_hidden",0)
    data["Layer_TopBar.IconMainMenu_Status.mode_status"] = 'Siga las indicaciones'
    data["Layer_WashingStatus.text_TitleWashProcess.washing_title"] = 'Descalcificado'
    data["Layer_WashingStatus.text_StepMsg.text"] = 'Mantener lleno deposito descalcificante'
    TIME_WASHING=1440
    user_select = 2
    
  elseif (get_recommend == 'Lavado Eco   66 min') then
    gre.set_value("Layer_WashingStatus.Group_DoorStatus.grd_hidden",1)
    gre.set_value("Layer_WashingStatus.Group_WashPils.grd_hidden",0)
    gre.set_value("Layer_WashingStatus.Group_Discaler.grd_hidden",1)
    data["Layer_TopBar.IconMainMenu_Status.mode_status"] = 'Siga las indicaciones'
    data["Layer_WashingStatus.text_TitleWashProcess.washing_title"] = 'Lavado ECO'
    data["Layer_WashingStatus.text_StepMsg.text"] = 'Mantener lleno los depositos'
    TIME_WASHING=2460
    user_select = 3
    
  elseif (get_recommend == 'Lavado Intermedio   90 min') then
    gre.set_value("Layer_WashingStatus.Group_DoorStatus.grd_hidden",1)
    gre.set_value("Layer_WashingStatus.Group_WashPils.grd_hidden",0)
    gre.set_value("Layer_WashingStatus.Group_Discaler.grd_hidden",1)
    data["Layer_TopBar.IconMainMenu_Status.mode_status"] = 'Siga las indicaciones'
    data["Layer_WashingStatus.text_TitleWashProcess.washing_title"] = 'Lavado intermedio'
    data["Layer_WashingStatus.text_StepMsg.text"] = 'Mantener lleno los depositos'
    TIME_WASHING=3600
    user_select = 4
    
  elseif (get_recommend == 'Lavado Regular   120 min') then
    gre.set_value("Layer_WashingStatus.Group_DoorStatus.grd_hidden",1)
    gre.set_value("Layer_WashingStatus.Group_WashPils.grd_hidden",0)
    gre.set_value("Layer_WashingStatus.Group_Discaler.grd_hidden",1)
    data["Layer_TopBar.IconMainMenu_Status.mode_status"] = 'Siga las indicaciones'
    data["Layer_WashingStatus.text_TitleWashProcess.washing_title"] = 'Lavado Regular'
    data["Layer_WashingStatus.text_StepMsg.text"] = 'Mantener lleno los depositos'
    TIME_WASHING=5700
    user_select = 5
    
  elseif (get_recommend == 'Lavado Intenso   150 min') then
    gre.set_value("Layer_WashingStatus.Group_DoorStatus.grd_hidden",1)
    gre.set_value("Layer_WashingStatus.Group_WashPils.grd_hidden",0)
    gre.set_value("Layer_WashingStatus.Group_Discaler.grd_hidden",1)
    data["Layer_TopBar.IconMainMenu_Status.mode_status"] = 'Siga las indicaciones'
    data["Layer_WashingStatus.text_TitleWashProcess.washing_title"] = 'Lavado intenso'
    data["Layer_WashingStatus.text_StepMsg.text"] = 'Mantener lleno los depositos'
    TIME_WASHING=9000
    user_select = 6
    
  end
   gre.set_data(data)
  CBUpdateTime(TIME_WASHING, 0)
  CBUpdateWashCycle(user_select)
  Wait(5)
end

local function ToggleShowCPUTemp(control)
  local data = {} 
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
    kx_select ='10'
    
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
    
  else return
  end
  
  CBUpdateRelay(kx_select)
end
