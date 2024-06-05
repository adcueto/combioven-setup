--[[
Copyright 2016, Crank Software Inc.
All Rights Reserved.
For more information email info@cranksoftware.com
** FOR DEMO PURPOSES ONLY **
]]--

local gLastPressedControl = nil
local gActiveCellPressed = nil
local gFront = 100
local gLevelSelected = 0      --if drag and drop is inside of ML are this will be 1 to 7 if it is outside will be 0
local gStartYposition = 0
local uncopiedFlag = 0
--local MIN_DRAG_LIMIT = 110


local function CloneCellPressed()
  local dk_data = {}
  gFront = gFront + 1
  dk_data["hidden"] = 0 
  dk_data["Layer_MLOptions.drag_recipe.grd_zindex"] = gFront
  gre.clone_object("icon_recipe","drag_recipe","Layer_MLOptions", dk_data) 
  gre.set_data(dk_data)
  gre.set_value("Layer_MLOptions.drag_recipe.alpha",255)
  uncopiedFlag = 1
  --print("bug4")
end


--- this function is called on motion events
function CBDragML(mapargs)
	-- if no control is selected just return
	if (gLastPressedControl == nil) then
		return
	end
	--set postion to touch co-ord, center the control on the screen location
	local ev_data = mapargs.context_event_data;
	local size = gre.get_control_attrs(gLastPressedControl, "width", "height")
	local pos = {}
	
	pos["x"] = ev_data.x - (size.width / 2)
	pos["y"] = ev_data.y -  (size.height / 2)

	if(pos["y"] - gStartYposition < 17) then  
	   return
	elseif(gLastPressedControl == "Layer_MLOptions.RecipesMLTable")then
	  --gre.set_table_attrs("RecipesMLTable", { scroll_enabled = false } )
    if(uncopiedFlag == 0) then
     CloneCellPressed()
     gActiveCellPressed = gLastPressedControl
     gLastPressedControl = "Layer_MLOptions.drag_recipe"
    end
	end

  if((gLastPressedControl == "Layer_MLOptions.drag_recipe") and (pos.y>260) )then
	-- set the control to the new position
	  gre.set_control_attrs(gLastPressedControl, pos)
	  
	  --print(pos["y"])
	--Highlight background level 
	 local data = {}
	 if(pos["y"] >= 380 and pos["y"] <= 490) then          --LEVEL 1
	   data["Layer_MultiLevel.bkg_Level_1.alpha1"] = 255
	   data["Layer_MultiLevel.bkg_Level_2.alpha2"] = 0
	   data["Layer_MultiLevel.bkg_Level_3.alpha3"] = 0
	   gLevelSelected = 1
    elseif(pos["y"] > 490 and pos["y"] <= 600) then      --LEVEL 2
     data["Layer_MultiLevel.bkg_Level_2.alpha2"] = 255
     data["Layer_MultiLevel.bkg_Level_1.alpha1"] = 0
     data["Layer_MultiLevel.bkg_Level_3.alpha3"] = 0
     gLevelSelected = 2
    elseif(pos["y"] > 600 and pos["y"] <= 710) then      --LEVEL 3
     data["Layer_MultiLevel.bkg_Level_3.alpha3"] = 255
     data["Layer_MultiLevel.bkg_Level_2.alpha2"] = 0
     data["Layer_MultiLevel.bkg_Level_4.alpha4"] = 0
     gLevelSelected = 3
    elseif(pos["y"] > 710 and pos["y"] <= 820) then      --LEVEL 4
     data["Layer_MultiLevel.bkg_Level_4.alpha4"] = 255
     data["Layer_MultiLevel.bkg_Level_3.alpha3"] = 0
     data["Layer_MultiLevel.bkg_Level_5.alpha5"] = 0
     gLevelSelected = 4
    elseif(pos["y"] > 820 and pos["y"] <= 930) then      --LEVEL 5
     data["Layer_MultiLevel.bkg_Level_5.alpha5"] = 255
     data["Layer_MultiLevel.bkg_Level_4.alpha4"] = 0
     data["Layer_MultiLevel.bkg_Level_6.alpha6"] = 0
     gLevelSelected = 5
    elseif(pos["y"] > 930 and pos["y"] <= 1040) then      --LEVEL 6
     data["Layer_MultiLevel.bkg_Level_6.alpha6"] = 255
     data["Layer_MultiLevel.bkg_Level_7.alpha7"] = 0
     data["Layer_MultiLevel.bkg_Level_5.alpha5"] = 0
     gLevelSelected = 6
    elseif(pos["y"] > 1040 and pos["y"] <= 1140) then     --LEVEL 7
     data["Layer_MultiLevel.bkg_Level_7.alpha7"] = 255
     data["Layer_MultiLevel.bkg_Level_6.alpha6"] = 0
     data["Layer_MultiLevel.bkg_Level_5.alpha5"] = 0

     gLevelSelected = 7
    
    --[[elseif(pos["y"] < 380) then --pos["y"] > 350 and 
     print("y:",pos["y"])
     print("obj:",gLastPressedControl)
     for i=1, 7 do
       data[string.format("Layer_MultiLevel.bkg_Level_%d.alpha%d",i,i)] = 0
     end
     gLevelSelected = 0
     print("bug1")]]
    else
     for i=1, 7 do
        data[string.format("Layer_MultiLevel.bkg_Level_%d.alpha%d",i,i)] = 0
     end
     gLevelSelected = 0
     gre.set_table_attrs("RecipesMLTable", { scroll_enabled = false } )
	 end
	 gre.set_data(data)	
	end
end


---Copy name and type from ML_Option List 
function CBCopyCellData(mapargs)
  recipe_id = gre.get_value(string.format("Layer_MLOptions.RecipesMLTable.recipe_id.%d.%d",mapargs.context_row,mapargs.context_col))
  local dk_data = {}  
  dk_data["Layer_MLOptions.icon_recipe.txt.1.1"] =  gre.get_value(string.format("Layer_MLOptions.RecipesMLTable.name.%d.%d",mapargs.context_row,mapargs.context_col))
  gre.set_data(dk_data)
end



--- When a release happens, clear the saved control name
function CBReleaseML(mapargs)
	gLastPressedControl = nil
	uncopiedFlag = 0
	local dk_data = {}
	if(gLevelSelected ~= 0) then
	  CheckPresetsML(recipe_id, gLevelSelected)   --recipe_id recipe selected
	  dk_data["Layer_MultiLevel.bkg_PlayML.pressed"] = 0
  else
    gLastPressedControl = nil
    gLevelSelected = 0
    uncopiedFlag = 0
	end
  gFront = gFront + 1
  dk_data["hidden"] = 0 
  dk_data["Layer_MLOptions.drag_recipe.grd_zindex"] = 0
  dk_data["Layer_MLOptions.drag_recipe.alpha"] = 0  
  dk_data["Layer_MLOptions.RecipesMLTable.grd_zindex"] = gFront
  dk_data[string.format("Layer_MultiLevel.bkg_Level_%d.alpha%d",gLevelSelected,gLevelSelected)] = 0
  gre.set_data(dk_data) 
  gre.delete_object("Layer_MLOptions.drag_recipe")
  gre.set_table_attrs("RecipesMLTable", {scroll_enabled = true} )
end



--- Save name and start Y position to verify Drag or Scroll motion
function CBCheckDragStartML(mapargs)
  local data = {}  
  data["hidden"] = 0  
  for i=1, 7 do
    data[string.format("Layer_MultiLevel.bkg_Level_%d.alpha%d",i,i)] = 0
  end
  gre.set_data(data)
  gLastPressedControl = mapargs.context_control
  local ev_data = mapargs.context_event_data;
  gStartYposition = ev_data.y
end


function CBStopScrollTable(mapargs)
  gLastPressedControl = nil
  gre.set_table_attrs("RecipesMLTable", {scroll_enabled = true} )
end


function ShowDischargeMsg(level_id)
  local data = {}
  local strname = string.format("Layer_Pop_ups.icon_level_ready_%d",level_id)
  data["hidden"] = 0
  gre.set_group_attrs(strname,data)  --Set Window discharge level msg
  data[string.format("Layer_MultiLevel.bkg_Level_%d.alpha%d",level_id,level_id)] = 255
  gre.set_data(data) 
end


function ClearDischargeMsg()
  local data = {}
  local strname
  
  data["hidden"] = 1
  for i=1, 7 do
    strname = string.format("Layer_Pop_ups.icon_level_ready_%d",i)
    gre.set_group_attrs(strname,data)  --Set Window discharge level msg
    data[string.format("Layer_MultiLevel.bkg_Level_%d.alpha%d",i,i)] = 0
  end
  gre.set_data(data)
end


--[[
function CBPressClone(mapargs)
  local data = {}
  data["x"] = 28
  data["y"] = 500
  data["hidden"] = 0
  gre.clone_object("icon_recipe", "drag_recipe", "Layer_MultiLevel", data)
end

  data["Layer_MultiLevel.drag_recipe.hidden"] = 1 
  data["Layer_MultiLevel.icon_recipe.hidden"] = 1 
  gre.set_data(data)
]]--



