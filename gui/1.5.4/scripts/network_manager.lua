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
  local f = assert( io.popen("ifconfig"))
  local out = f:read("*a")
  local data = {}

  for line in out:gmatch("[^\r\n]+") do
    if line:match("%sinet addr:") then
      ip_addr = line:match("(%d+%.%d+%.%d+%.%d+)")
      if ip_addr and ip_addr ~= "127.0.0.1" then   
        data["Layer_ConfigSettings.text_DevNet.ssid"]  = ssid
        data["Layer_ConfigSettings.text_IPv4Stat.txt"] = string.format("%s",ip_addr)
        data["Layer_TopBar.IconMainMenu_Wifi.dev_connected"] = 255
        gre.set_data(data)
        break
      else
        ip_addr = nil
      end
    end
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
  local ssid_scan = assert( io.popen("iw wlan0 scan"))
  local netlist = {}
  
    
  for line in ssid_scan:lines() do
    if line:match("%sSSID:") ~= nil then
      ssid_available=line:gsub("%sSSID: ","")
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
  
  wifi_en:close()
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


-- Función para verificar si la red ya está configurada en wpa_supplicant.conf
local function addNetwork(ssid)
  local file = assert(io.open("/etc/wpa_supplicant.conf", "r"))
  local content = file:read("*all")
  local isNetAdd = false
  file:close()
  -- Buscar el SSID dentro del contenido utilizando una expresión regular
  local escaped_ssid = ssid:gsub("%p", "%%%1")
  local is_network_added = string.match(content, 'network%s*={.-ssid%s*=%s*["\']' .. escaped_ssid .. '["\'].-}')
  if is_network_added ~= nil then 
    isNetAdd = true
  end
  return isNetAdd
end

--Verificar conexion
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


---Start Wi-Fi connection with SSID and Password entered on Linux
function CBConnectWiFi()
  local ip_addr = nil
  local pass = gre.get_value(EDIT_PASS)
  local data = {}
  
  status_connected = 1
 
  local sys_cmd = assert(io.popen(string.format("usr/bin/cmd/wifi.sh -i %s wlan0 -s %s",ssid_selected,pass)))
  sys_cmd:close()

  os.execute("sleep 1")

  ip_addr = get_ip_linux(ssid_selected)
  print("ip: ", ip_addr)
   
  if ip_addr ~= nil then
   data["hidden"] = 1
   
   gre.set_layer_attrs("Layer_Loading",data) 
   gre.set_value("screenName", "Modo_Configuracion")
   gre.send_event("ScreenTransition")
   print("transicion")

  else
    
    data["hidden"] = 1
    gre.set_layer_attrs("Layer_Loading",data) 
    status_connected = 0
    print("lista")
  end
  
  
  gre.animation_stop("StateLoad_Circ")
  gre.animation_stop("StateLoad_Rot")
  print("terminado")


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


--[[

Secuencia de comandos linux para conectar a WIFI:

rfkil
0) pkill udhcpc
0) pkill wpa_supplicant   -- mata cualquier servicio de conexion con wpa_supplicant
1) ifconfig -a  --preguntar si wlan0 is present
2) ifconfig wlan0 up --levantar wlan0
3) iw wlan0 scan
4  wpa_passphrase "TELMEX-WiLink2-AE56" "M4W2_AE566" >> /etc/wpa_supplicant.conf --add credentials
5) wpa_supplicant -B -i wlan0 -D wext -c /etc/wpa_supplicant.conf --run wpa supplicant tool
6) iw dev wlan0 link
7) udhcpc -i wlan0

]]--

