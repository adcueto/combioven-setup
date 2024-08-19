local logger = require("components.logger")
local oven_state_service = require("services.oven_state_service")
local OvenEnums = require("components.oven_status_enums")


-- Constants defining various thresholds and limits
local MAX_CLEAN_BAR = 690            -- Maximum clean bar in pixels
local MAX_TIME_DIRTY = 7200          -- Comvection: Maximum time in dirty state in minutes (5 days)
local MAX_TIME_CALOUT = 6000         -- Steam: Maximum time before calout in minutes (4 days)
local DIRT_PERCENT_ALERT_90 = 90     -- Alert at 90% dirt level
local DIRT_PERCENT_ALERT_70 = 70     -- Alert at 70% dirt level

-- DISTURB ALERT
ALERT_DISTURB = false

-- Internal function to set the washing alert with appropriate messages and state changes
local function setWashAlert(alertDisturb, message, image)
    ALERT_DISTURB = alertDisturb
    gre.set_value("Layer_SettingsBar.OperationSelector.grd_hidden", true)
    gre.set_value("Modo_Lavado.Layer_DialogBoxSuggest.grd_hidden", false)
    gre.set_value("Layer_DialogBoxSuggest.text_Message.text", message)
    gre.set_value("Layer_DialogBoxSuggest.icon_Confirm.image", image)
    gre.set_value("screenName", "Modo_Lavado")
    gre.send_event("ScreenTransition")
    gCombiOvenState = RUN_WASHING_STATE
    oven_state_service.updateOvenState(OvenEnums.OvenState.START)
    oven_state_service.updateOvenMode(OvenEnums.OvenMode.WASHING)
    oven_state_service.updateWashingMode(OvenEnums.WashingMode.NONE)
    oven_state_service.logOvenState()
    logger.warn(message)
    gre.send_event("toggle_washing", gBackendChannel)
end
    
-- Function to show washing alert based on the oven's usage hours
function ShowWashAlert()
    -- Query to fetch steam and convection hours from the system configuration
    local statement = "SELECT HrsSteam, HrsConv FROM system_configuration WHERE id=1;"
    local cur = db:execute(statement)
    local row = cur:fetch({}, "a")
    
    local MinSteam = row.HrsSteam
    local MinConv = row.HrsConv
    local data = {}
    -- Calculate the percentage of dirtiness for boiler and camera
    local percentBoiler = math.ceil((MinSteam * MAX_CLEAN_BAR) / MAX_TIME_CALOUT)
    local percentCamera = math.ceil((MinConv * MAX_CLEAN_BAR) / MAX_TIME_DIRTY)
       
    if(percentCamera>MAX_CLEAN_BAR)then
      percentCamera=MAX_CLEAN_BAR
    elseif(percentBoiler>MAX_CLEAN_BAR)then
      percentBoiler=MAX_CLEAN_BAR
    end
     
    data["Layer_ModeWashing.Slider1.Slider_Color.percent"] = percentCamera
    data["Layer_ModeWashing.Slider2.Slider_Color.percent"] = percentBoiler
    gre.set_data(data)
    -- Define dirty limit thresholds for 90% and 70% alerts
    local boilerdirtylimit = {
        [90] = math.ceil((MAX_TIME_CALOUT * DIRT_PERCENT_ALERT_90) / 100),
        [70] = math.ceil((MAX_TIME_CALOUT * DIRT_PERCENT_ALERT_70) / 100)
    }
    
    local camdirtylimit = {
        [90] = math.ceil((MAX_TIME_DIRTY * DIRT_PERCENT_ALERT_90) / 100),
        [70] = math.ceil((MAX_TIME_DIRTY * DIRT_PERCENT_ALERT_70) / 100)
    }
    GetCleanRecommends(percentCamera, percentBoiler) 

    -- Check if either the boiler or camera dirtiness exceeds thresholds
    if MinSteam >= MAX_TIME_CALOUT or MinConv >= MAX_TIME_DIRTY then
        setWashAlert(true, "Peligro: Por favor, realice una limpieza ahora.", "images/icon_TitleWashProcess.png")
    elseif (MinSteam >= boilerdirtylimit[90] or MinConv >= camdirtylimit[90]) and gCombiOvenState == STOP_OVEN_STATE then
        setWashAlert(true, "Advertencia: horno muy sucio. Por favor, realice una limpieza.", "images/icon_TitleWashProcess.png")
    elseif (MinSteam >= boilerdirtylimit[70] or MinConv >= camdirtylimit[70]) and gCombiOvenState == STOP_OVEN_STATE then
        setWashAlert(false, "Horno sucio. Por favor, realice la limpieza recomendada.", "images/icon_TitleWashProcess.png")
    end
end