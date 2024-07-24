SavePopup = {}
SavePopup.__index = SavePopup

function SavePopup:new(screen)
  local obj = setmetatable({}, SavePopup)
  obj.screen = screen
  obj.layer = "Layer_AddAutoRecipe"
  obj.isVisible = false
  obj.inputText = ""
  obj.screenParams = {
    layerGrdHidden = {name = "grd_hidden", value = 0},
    keyCapsHidden = {name = "grd_hidden", value = 1},
    keyCapsAlpha = {name = "grd_alpha", value = 255},
    keyNumsHidden = {name = "grd_hidden", value = 1},
    keyMinsAlpha = {name = "grd_alpha", value = 255},
    keyMinsHidden = {name = "grd_hidden", value = 1},
    
  }
  obj.layerParams = {
    messageText = {name = "text_Message.text", value = ""},
    inputNameRecipeText = {name = "InputNameRecipe.text", value = ""},
    inputNameRecipeHidden = {name = "InputNameRecipe.grd_hidden", value = 0},
    lineInputTextHidden = {name = "line_InputText.grd_hidden", value = 0},
    guardarBtnHidden = {name = "bkg_GuardarBtn.grd_hidden", value = 0},
    cancelarBtnHidden = {name = "bkg_CancelarBtn.grd_hidden", value = 0},
    iconConfirmAlpha = {name = "icon_Confirm.alpha", value = 0}
  }

  return obj
end


function SavePopup:show(messageText)
  self.layerParams.messageText.value = messageText
  
  -- habilita los objetos de la ventana
  for _, sparam in pairs(self.screenParams) do
    gre.set_value(self.screen .. "." .. self.layer .. "."  ..sparam.name, sparam.value)
  end
  
  for _, lparam in pairs(self.layerParams) do
    gre.set_value(self.layer .. "."  ..lparam.name, lparam.value)
  end
  
  
  -- Habilitar teclado
  for i = 1, 5 do
    gre.animation_trigger("Up_Keyboard" .. i)
  end
  
  self.isVisible = true
end

function SavePopup:hide()
--cambio de valores
self.layerParams.messageText.value = ""
self.screenParams.layerGrdHidden.value = 1
self.layerParams.inputNameRecipeHidden.value = 1
self.layerParams.guardarBtnHidden.value = 1
self.layerParams.cancelarBtnHidden.value = 1
self.layerParams.iconConfirmAlpha.value = 0

  -- Deshabilita los objetos de la ventana
  for _, sparam in pairs(self.screenParams) do
    gre.set_value(self.screen .. "." .. self.layer .. "."  ..sparam.name, sparam.value)
  end
  
    for _, lparam in pairs(self.layerParams) do
    gre.set_value(self.layer .. "."  ..lparam.name, lparam.value)
  end
    
  self.isVisible = false
end


function SavePopup:save()
  local recipeName = gre.get_value(self.screen .. "." .. self.layer .. ".InputNameRecipe.text")
  print("Guardando en base de datos...")
  -- Ocultar la ventana emergente después de guardar
  self:hide()
end


function SavePopup:cancel()
  -- Ocultar la ventana emergente sin realizar cambios
  
  self:hide()
end

return SavePopup