#!/bin/bash

  sleep 1
  for i in {1..100};
  do 
   sleep 0.01
   echo $i >/sys/class/backlight/backlight\@0/brightness
  done
