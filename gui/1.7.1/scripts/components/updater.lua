--[[
Copyright 2021, Pro-Servicios SA de CV.
All Rights Reserved.
Software update through various interfaces, USB, ETH, WiFi, etc.
For more information email j.perez@pro-servicios.com
** Author: Adrian Cueto
]]--

-- @module usb_updater
updater = {}

--- Constructor for the Updater class
-- @return New instance of Updater

-- Create a new module instance and update metatable 
function updater.new(...)
    local instance = {}
    setmetatable(instance,{__index = usb_update})
    instance:init(...)
    return instance
end 

---
-- Initialize the new module instance
-- @param control #string - The fully qualified name for the control this represents
-- @param down_color #number - The RGB color code for the down state color
function updater:init(interface)
  self.control = interface
end


-- @param command The command to execute
-- @return boolean indicating if the command was successful, and the command output
function updater:execute_command(command)

  if command == nil or type(command) ~= "string" then
    print("Error: command is nil or not a string")
    return false, "Invalid command"
  end
  
  local handle = io.popen(command)
  local result = handle:read("*a")
  local success, exit_code, code = handle:close()
  if not success then
    print("Error executing command: " .. command)
    print("Output: " .. result)
    return false, result
  end
  return true, result
end

--- Checks if a USB drive is connected
-- @return boolean indicating if a USB drive is connected
function updater:is_usb_connected()
  local success, result = self:execute_command("ls /dev/sda1")
  return success
end

--- Mounts the USB drive
-- @return boolean indicating if the USB drive was successfully mounted
function updater:mount_usb()
  if not self:is_usb_connected() then
    print("No USB drive connected.")
    return false
  end
  local success, result = self:execute_command("sudo mount -t ext4 /dev/sda1 /media/usb")
  if not success then
    print("Error mounting USB: " .. result)
    return false
  end
  return true
end


--- Unmounts the USB drive
function updater:unmount_usb()
  local success, result = self:execute_command("sudo umount /media/usb")
  if not success then
    print("Error unmounting USB: " .. result)
  end
end


--- Perfo--- Performs the software update or rollback from the USB drive
-- @param operation The type of operation (update or rollback)
-- @param version The version to rollback to (only required for rollback)
function updater:update_software()
  print("Software update...")

  -- Mount the USB
  if not self:mount_usb() then
    return
  end

  -- Execute the update script
  local success, result = self:execute_command("/media/usb/app.sh update")
  if not success then
    print("Error during software update: " .. result)
    self:unmount_usb()
    return
  end

  -- Unmount the USB
  self:unmount_usb()

  -- Reboot the system
  success, result = self:execute_command("sudo reboot")
  if not success then
    print("Error rebooting the system: " .. result)
  end
end

--- Performs the rollback of software to a specific version from the USB drive
-- @param version The version to rollback to
function updater:rollback_software(version)
  print("Software rollback to version " .. version .. " ...")

  -- Mount the USB
  if not self:mount_usb() then
    return
  end

  -- Execute the rollback script
  local command = string.format("/media/usb/app.sh rollback %s", version)
  local success, result = self:execute_command(command)
  if not success then
    print("Error during software rollback: " .. result)
    self:unmount_usb()
    return
  end

  -- Unmount the USB
  self:unmount_usb()

  -- Reboot the system
  success, result = self:execute_command("sudo reboot")
  if not success then
    print("Error rebooting the system: " .. result)
  end
end

return updater