-- utils/env_loader.lua

local env_loader = {}

function env_loader.load_library(lib_name)
    local myenv = gre.env({ "target_os", "target_cpu" })
    if myenv.target_os == "win32" then
        package.cpath = gre.SCRIPT_ROOT .. "\\" .. "libs" .. "\\" .. "windows-" .. myenv.target_cpu .. "\\" .. lib_name .. ".dll;" .. package.cpath
    else
        package.cpath = gre.SCRIPT_ROOT .. "/" .. "libs" .. "/" .. "linux-" .. myenv.target_cpu .. "/" .. lib_name .. ".so;" .. package.cpath
    end
    local lib = require(lib_name)
    return lib
end

return env_loader