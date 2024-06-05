--[[
Copyright 2016, Crank Software Inc.
All Rights Reserved.
For more information email info@cranksoftware.com
** FOR DEMO PURPOSES ONLY **
]]--

-- Variables
local gShifted = 0
local FIND_RECIPE = "Layer_Input.InputField.text"
local SAVE_FOLDER = "Layer_DialogBoxFolder.text_InputField.text"
-- Global Variables
EDIT_PASS  = "Layer_AddPassword.InputPassword.text"
SAVE_NEW_RECIPE = "Layer_AddAutoRecipe.InputNameRecipe.text"
KEYCODE_BACKSPACE = 8
KEYCODE_ENTER     = 13
KEYCODE_SPACE     = 32


local function SplitString(inputstr, sep)
    if (sep == nil) then
      sep = "%s"
    end    
    local t = {}
    local i = 1
    
    for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
      t[i] = str
      i = i + 1
    end
    return t
end


local function TriggerKey(code)
    local data = {}
    local len = string.len(code)
    local i = 1
        
    while (i <= len) do
        data["code"] = string.byte(code, i)
        data["modifiers"] = 0  
		    local success, error = gre.send_event_data("gre.keydown", "4u1 code 4u1 modifiers", data)
		    if (success == false) then
		      print(error)
		    end
		    i = i + 1
    end    
end


local function TriggerRaw(code)
    local data = {}
    data["code"] = code
    data["modifiers"] = 0
    gre.send_event_data("gre.keydown", "4u1 code 4u1 modifiers", data)
end


local function KeyboardShift(layer)
    if (gShifted == 1) then
		    gShifted = 0
    else 
		    gShifted = 1
    end
end


function CBKeyboardPress(mapargs)
    local data = {}
    local val
    if (mapargs.context_control == nil) then
		    return
    end
	
    data = SplitString(mapargs.context_control, ".")  --get name of key
    local key_name = data[2]
    data = {}
    data = gre.get_data(mapargs.context_control..".char")
    local char = data[mapargs.context_control..".char"]
    
    if (key_name == "backspace") then
		    TriggerRaw(KEYCODE_BACKSPACE)
        return
    elseif (key_name == "space") then
        TriggerRaw(KEYCODE_SPACE)
        return		
    elseif (key_name == "enter") or (key_name == "Enter") then
        TriggerRaw(KEYCODE_ENTER)
        return
    elseif (key_name == "abc" or key_name == "123") then
        return
    elseif (key_name == "bkg_123_up") then
        gShifted = 0
        return  
    elseif (key_name == "shift" or key_name == "bkg_shift_up")  then
        KeyboardShift(mapargs.context_layer)
        return
    else	
        if (gShifted ~= 1) then
          val = string.lower(char)
        else 	
          val = char
        end
    end
    TriggerKey(val)
end


function CBInputKeyEvent(mapargs)
    local data = {}
    local key = FIND_RECIPE
    
    if( mapargs.active_context == "Modo_Programacion" ) then
      key = FIND_RECIPE
    elseif( mapargs.active_context == "Ajustes_Modo_Auto" or mapargs.active_context == "Crear_Receta_Manual") then
      key = SAVE_NEW_RECIPE
    elseif( mapargs.active_context == "Administrar_Redes" ) then
      key = EDIT_PASS
    else
      return
    end
    data = gre.get_data(key) 
    local evData = mapargs.context_event_data
    if (evData.code == nil) then
      return
    end
    
    if (evData.code == KEYCODE_BACKSPACE) then    -- backspace key
        local len = string.len(data[key])
        len = len - 1
        local new = string.format("%s", string.sub(data[key],1,len))
        data[key] = new
        gre.set_data(data)   
    elseif (evData.code == KEYCODE_ENTER) then               -- enter key
        --data[gEntryOrder[gEntryIndex].var] = gTempEntry[gEntryOrder[gEntryIndex].name]
        --gre.set_data(data)
        --gTempEntry[gEntryOrder[gEntryIndex].name] = data[key]
        --CBNextEntry()
        --print("here"..data[key])
    else  
        data[key] = data[key]..string.char(evData.code)
        gre.set_data(data)
    end
  
    if (mapargs.context_event_data.code == KEYCODE_ENTER) then
        -- not the enter key
        --print("data:"..data[key])
        FindRecipe(data[key])
        --gTempEntry[gEntryOrder[gEntryIndex].name] = data[key]
    end
end


--    print("Triggered by event : " .. mapargs.context_event)
--    print("Event was targeting : " .. mapargs.active_context)
--    print("hello")
    
       -- data[layer..".shift_R.image"] = image
   -- data[layer..".shift_L.image"] = image
   -- gre.set_data(data)
          --image = "images/btn1_down.png"
              --local data = {}
    --local image

        --image = "images/btn1_up.png"