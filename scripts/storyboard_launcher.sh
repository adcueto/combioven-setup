#!/bin/sh

   echo 0 >/sys/class/backlight/backlight\@0/brightness
   systemctl stop weston
   killall sbengine
   echo "Starting Storyboard from SCP..."

   echo 0 >> /sys/class/graphics/fbcon/cursor_blink
   echo -e '\033[9;0]' >> /dev/tty1
   echo 0 >> /sys/class/graphics/fb0/blank

   export SBROOT=/usr/crank/runtimes/linux-imx8yocto-armle-opengles_2.0-obj
   export SB_ENGINE=$SBROOT/bin/sbengine
   export LAUNCHER_APP=/usr/crank/apps/interface/combioven-gui.gapp
   export SB_PLUGINS=$SBROOT/plugins
   export LD_LIBRARY_PATH=$SBROOT/lib
   export SBIO_CONSOLE_LOGGING

   TOUCH="-omtdev,device=/dev/input/touchscreen0"

   OPTIONS="-vv -ogreio,channel=combioven_frontend -oscreen_mgr,fullscreen -ogfi-input,rotate=90 -orender_mgr,rotate=90,x=0,y=0 $TOUCH"
    
   $SB_ENGINE $OPTIONS $LAUNCHER_APP
   
   echo 100 >/sys/class/backlight/backlight\@0/brightness
     
