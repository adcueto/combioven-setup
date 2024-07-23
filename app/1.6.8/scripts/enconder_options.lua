--[[ Constructor to create a new Encoder object
   @param args Table containing fixed encoder configuration
    This table should have the following structure:             
         {
           config = {param = 1, min = 0, max = 100, step = 1, data = 'humidity'},
           recipe = createRecipe,
           channel = gBackendChannel

         }
---]]

-- @param createRecipe Table containing recipes to fetch data from (optional)
-- @param gBackendChannel Backend channel for sending event data (assumed to be defined elsewhere)
-- @return New instance of Encoder
encoder_options = {}

function encoder_options:new(channel)
  self.channel = channel
  self.encoderId = 6
  self.data = nil
  self.parameter = nil
  
end

-- Private function to update encoder options
local function updateEncoderOptions(min_value, max_value, now_value, step_value, id_parameter)
  -- This function sends event data to update encoder options
  gre.send_event_data(
    "enable_encoder_options", 
    "4u1 minvalue 4u1 maxvalue 4u1 nowvalue 1u1 stepvalue 1u1 parameter",
    { 
      minvalue = min_value,
      maxvalue = max_value,
      nowvalue = now_value,
      stepvalue = step_value,
      parameter = id_parameter
    },
    self.channel
  )
end

-- Method to create and enable the encoder
function encoder_options:createEnableEncoder(config,recipe, index)
  -- If the selected configuration exists
  if type(config) ~= "table" and type(recipe) ~= "table"  then
    error("Expected 'config' to be a table")
  else
    -- Get the current value for the encoder from createRecipe table if available
    local data_value = recipe[index][config.data]
    self.data = data_value ~= nil and data_value or config.min
    self.parameter = config.param
    
    -- Update encoder options with the appropriate values
    updateEncoderOptions(
      config.min, 
      config.max, 
      self.data, 
      config.step, 
      self.encoderId
    )
  end
end



return encoder_options