
local myenv = gre.env({ "target_os", "target_cpu" })
local status_connected = 0
ssid_selected = 0           --Save the SSID selected by user


---Get IP from Win32 if device is connected
local function get_ip_win32()
  local ip_addr = nil
  local f = assert( io.popen("ipconfig"))
  
  for line in f:lines() do                      --if line:match("%sIPv4 Address") ~= nil then
    if line:match("%sDirecci.n IPv4") ~= nil then --testing line with spanish keyboard
      ip_addr=line:match("%d+.%d+.%d+.%d+")
    end
  end 

  f:close()
  return(ip_addr)
end


---Get IP from Linux if device is connected
local function get_ip_linux(ssid)
  local ip_addr = nil
  local conn = false
  local f = assert( io.popen("ifconfig"))
  local out = f:read("*a")
  local data = {}

  for line in out:gmatch("[^\r\n]+") do
    if line:match("%sinet addr:") then
      ip_addr = line:match("(%d+%.%d+%.%d+%.%d+)")
      if ip_addr and ip_addr ~= "127.0.0.1" then   
        conn = true
        break
      else
        conn = false
        ip_addr = nil
      end
    end
  end 
  
  if conn then
    data["Layer_ConfigSettings.text_DevNet.ssid"]  = ssid
    data["Layer_ConfigSettings.text_IPv4Stat.txt"] = string.format("%s",ip_addr)
    data["Layer_TopBar.IconMainMenu_Wifi.dev_connected"] = 255
    gre.set_data(data)
  else
    data["Layer_ConfigSettings.text_DevNet.ssid"]  = "Sin internet"
    data["Layer_ConfigSettings.text_IPv4Stat.txt"] = "Dirección IP"
    data["Layer_TopBar.IconMainMenu_Wifi.dev_connected"] = 0
    gre.set_data(data)   
  end
  
  f:close()
  return(ip_addr)
end

---Validate IP address to get connectivity status
local function get_ip_address()
  local data = {}
  local ip_addr = get_ip()
  
  if ip_addr == nil then
    gre.timer_set_timeout(get_ip_address,10000)
    data["Wifi_List.text_available.ssid_2"] = "Network Disconnected"
  else
    data["Wifi_List.text_available.ssid_2"] = string.format("%s",ip_addr) --prints WiFi available
  end
  gre.set_data(data)
end



---Load WiFi Networks available on Linux
local function showWifiList_linux()
  local ssid_available = nil 
  local wifi_en = assert( io.popen("ifconfig wlan0 up"))
  sleep(2)
  
  local ssid_scan = assert( io.popen("iw wlan0 scan"))
  local netlist = {}
  local isData = false
  
  for line in ssid_scan:lines() do
    if line:match("%sSSID:") ~= nil then
      ssid_available=line:gsub("%sSSID: ","")
      if ssid_available == nil then
        isData = false
        break
      else
        isData = true
        table.insert(netlist,ssid_available)
      end
    end
  end 
  
  if isData then
    local data = {}
    data["rows"] = table.maxn(netlist)
    gre.set_table_attrs("Layer_WifiList.NetworksTable",data)
    
    data={}
    for i=1, table.maxn(netlist) do
      data["Layer_WifiList.NetworksTable.txt."..i..".1"] = netlist[i]
    end
    gre.set_data(data)
    
    data = {}
    data["hidden"] = 0
    gre.set_table_attrs("NetworksTable", data)

  else
    data["hidden"] = 1
    gre.set_table_attrs("NetworksTable", data)
  end
  
  data = {}
  data["hidden"] = true
  gre.set_layer_attrs("Layer_Loading",data) 
  
  gre.animation_stop("StateLoad_Circ")
  gre.animation_stop("StateLoad_Rot")
  
  ssid_scan:close()
  
  return(ssid_available)
end



---Load WiFi Networks available on Win32
local function showWifiList_win32()   
  local ssid_available = nil
  local ssid_scan = assert( io.popen("netsh wlan show networks mode=bssid"))
  local netlist = {}
  
  for line in ssid_scan:lines() do
    if line:match("SSID %d :") ~= nil then
      ssid_available=line:gsub("SSID %d : ","")
      if ssid_available == nil then 
        break
      else  
        table.insert(netlist,ssid_available)
      end
    end
  end 
  
  local data = {}
  
  data["rows"] = table.maxn(netlist)
  gre.set_table_attrs("Layer_WifiList.NetworksTable",data)
  data={}
  for i=1, table.maxn(netlist) do
    data["Layer_WifiList.NetworksTable.txt."..i..".1"] = netlist[i]
  end
  gre.set_data(data)
  data = {}
  
  if( table.maxn(netlist) ~= nil ) then
    data["hidden"] = 0
    gre.set_table_attrs("NetworksTable", data)
  else 
    data["hidden"] = 1
    gre.set_table_attrs("NetworksTable", data)
  end

  data = {}
  data["hidden"] = 1
  gre.set_layer_attrs("Layer_Loading",data)   
  
  gre.animation_stop("StateLoad_Circ")
  gre.animation_stop("StateLoad_Rot")
  ssid_scan:close()
  
  network_interface_reset()
  
  return(ssid_available)
end





---Start Wi-Fi connection with SSID and Password entered //unfinished function
local function CBConnectWiFiW32()
  local ssid = gre.get_value(ssid_selected)
  local pass = gre.get_value(EDIT_PASS)
  local wifi_start = assert( io.popen(string.format("wifi.sh -i wlan0 -s %s -p %s",ssid,pass)))  
  local data = {}
 
  print(pass)
  data["Layer_WifiList.NetworksTable.txt.1.1"] = "init_connection" 
  gre.set_data(data)
  
  for line in wifi_start:lines() do
    if line:match("%sIPv6: ADDRCONF (NETDEV_CHANGE):wlan0: link becomes ready") ~= nil then 
      data["Layer_WifiList.NetworksTable.txt.1.1"] = "Conection Ok" 
      break
    else
      data["Layer_WifiList.NetworksTable.txt.1.1"] = "Bad Conection" 
    end
  end 
  gre.set_data(data)
  wifi_start:close()
end



---Copy SSID and type from ML_Option List 
function CBCopySSID(mapargs)
  ssid_selected = gre.get_value(string.format("Layer_WifiList.NetworksTable.txt.%d.1",mapargs.context_row))
end


function remove_wpa_supplicant(path)
  local f = io.open(path, "r")
  if f then
    f:close()
    os.remove(path)
    print(path .."existia y fue eliminado")
  end
end


function create_wpa_supplicant(ssid, pass)
  local path = "/etc/wpa_supplicant.conf"
  remove_wpa_supplicant(path)
  
  local f = io.open(path, "w")
  f:write("#PSK/TKIP\n")
  f:write("ctrl_interface=/var/run/wpa_supplicant\n")
  f:write("network={\n")
  f:write("scan_ssid=1\n")
  if pass == nil then
      f:write("key_mgmt=NONE\n")
  else
      f:write(string.format('ssid="%s"\n', ssid))
      f:write(string.format('psk="%s"\n', pass))
      f:write("key_mgmt=WPA-EAP WPA-PSK IEEE8021X NONE\n")
      f:write("group=CCMP TKIP WEP104 WEP40\n")
  end
  f:write("}\n")
  f:close()
end


function update_wpa_supplicant(ssid, pass)
  local conf_file = io.open("/etc/wpa_supplicant.conf", "a")
  if pasw == nil then
      conf_file:write("key_mgmt=NONE\n")
  else
      conf_file:write(string.format('psk="%s"\n', pass))
      conf_file:write("key_mgmt=WPA-EAP WPA-PSK IEEE8021X NONE\n")
      conf_file:write("group=CCMP TKIP WEP104 WEP40\n")
  end
  conf_file:write(string.format('ssid="%s"\n', ssid))
  conf_file:write("}\n")
  conf_file:close()
end


function kill_process(process_name)
  --local check = os.execute("pidof "..process_name )
  res, err = execute_command("pidof "..process_name)
  print("check process: "..res)
  if check then 
    print("killing process"..process_name)
    os.execute("kill -9 $(pidof "..process_name.. ")")
  end
end

function network_interface_reset(interface)
  os.execute("ifconfig "..interface.." down > /dev/null")
  sleep(1)
  os.execute("ifconfig "..interface.." up > /dev/null")
  sleep(1)
end

function connect_wpa_supplicant(interface)

  kill_process("wpa_supplicant")
  os.execute("ifconfig "..interface.." up > /dev/null")
  sleep(2)
  os.execute("wpa_supplicant -Dnl80211,wext -i"..interface.." -c/etc/wpa_supplicant.conf  >/dev/null &")
  print("waiting")
  sleep(3)
  
  local status = os.execute("wpa_cli -i"..interface.." status | grep 'COMPLETED' >/dev/null ")
  print("check status: "..status)
  if status == 0 then
    os.execute("udhcpc -i"..interface)
    print("Finshed!")
    
  else
    print("try to connect again...")
    sleep(3)
    status = os.execute("wpa_cli -i"..interface.." status | grep 'COMPLETED' >/dev/null ")
    if status == 0 then
      os.execute("udhcpc -i"..interface)
      print("Finshed!")
    else
      print("connect faild,please check the passward and ssid")
      kill_process("wpa_supplicant")
    end
  end
end

---Funcion sleep
function sleep(segundos)
    os.execute("sleep " .. segundos)
end

---Función para verificar si la red ya está configurada en wpa_supplicant.conf
local function isNetAdd(ssid)
  local file = assert(io.open("/etc/wpa_supplicant.conf", "r"))
  local content = file:read("*all")
  file:close()
  -- Buscar el SSID dentro del contenido utilizando una expresión regular
  local escaped_ssid = ssid:gsub("%p", "%%%1")
  local is_network_added = string.match(content, 'network%s*={.-ssid%s*=%s*["\']' .. escaped_ssid .. '["\'].-}')
  if is_network_added ~= nil then 
    return true
  end
  return false
end

---Funcion para verificar conexion
local function isConnected() 
  local handle = assert(io.popen("sudo iw dev wlan0 link"))
  local output = handle:read("*a")
  local isNotConnected = string.match(output, "Not connected.")
  handle:close()  
  if isNotConnected then
      return false
  end
  return true
end

---Funcion para para ejecutar cualquier comando
function execute_command(cmd)
    local handle = io.popen(cmd)
    local result = handle:read("*a")
    local _, _, exit_code = handle:close()
    return result, exit_code
end


---Funcion para para ejecutar cualquier comando de manera asincrona
function async_execute_command(cmd)
    return coroutine.create(function()
        local result, exit_code = execute_command(cmd)
        coroutine.yield(result, exit_code)
    end)
end

---Esperar el resultado de una funcion asincrona
function await(coroutine_handle)
    local status, result, exit_code = coroutine.resume(coroutine_handle)
    if not status then
        error(result)
    end
    return result, exit_code
end

---Start Wi-Fi connection with SSID and Password entered on Linux
function CBConnectWiFi()
  local ip_addr = nil
  local pass = gre.get_value(EDIT_PASS)
  local data = {}
  
  
  print("Connecting to",ssid_selected)
  
  status_connected = 1
  create_wpa_supplicant(ssid_selected, pass)
  connect_wpa_supplicant("wlan0")
  
  --local cmd = string.format("/usr/bin/cmd/wifi.sh -i wlan0 -s %s -p %s", ssid_selected, pass)
  --local co = async_execute_command(cmd)
  --local result, exit_code = await(co)

    
  ip_addr = get_ip_linux(ssid_selected)
  print("IP Connection:",ip_addr)
   
  if ip_addr ~= nil then
    data["hidden"] = true
    gre.set_value("screenName", "Modo_Configuracion")
    gre.send_event("ScreenTransition")
    gre.set_layer_attrs("Layer_Loading",data)

    print("Connected")
  else
    data["hidden"] = true
    gre.set_layer_attrs("Layer_Loading",data) 
    status_connected = 0
    print("Not connected")
  end

  gre.animation_stop("StateLoad_Circ")
  gre.animation_stop("StateLoad_Rot")
  --network_interface_reset("wlan0")
  print("Finshed!")

end


---Scan to discover Wi-Fi networks 
function CBScanNetwork(mapargs)
  if myenv["target_os"] == "linux" then
     showWifiList_linux()
  elseif myenv["target_os"] == "win32" and status_connected == 0 then
     showWifiList_win32()
  else
     return
  end
end


--- @param gre#context mapargs
function CBWifiConnected(mapargs)
   local ip_addr = nil
    
   if myenv["target_os"] == "linux"  then --and row.NetSsid ~= nil and row.NetPass ~= nil 
  
     local handle = assert(io.popen("sudo iw dev wlan0 link"))
     local output = handle:read("*a")
     local isNotConnected = string.match(output, "Not connected.")

     if not (isNotConnected) then
        local ssid_pattern = "SSID: ([^\n]+)"
        local ssid = output:match(ssid_pattern)
  
        ip_addr = get_ip_linux(ssid)
  
        if ip_addr == nil then
            ip_addr = get_ip_linux(ssid)
        end  
     end
     handle:close()
   end
end



