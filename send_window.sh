#!/bin/bash

if [ "$1" == "--help" ]; then
  test=`echo $0 | cut -c1-2`
  if [ $test != "./" ]; then
      exe=$(basename $0)
  else
      exe=$0
  fi
  echo "This script is used to send current window to another screen (monitor)."
  echo "It assumes that Primary monitor is on the left, and calculates to send the window from current window to the other."
  echo "Only works for 2 monitors so far."
  echo "Unless specified, it keeps current window size"
  echo ""
  echo "Usage: $exe [-flags]"
  echo ""
  echo " --help - shows this help"
  echo " -l     - forces sending to the left"
  echo " -r     - forces sending to the right"
  echo " -x     - forces maximizing after sending"
  echo " -i     - Inverts default assumption that Primary monitor is on the left"
  echo " -c     - Also centers window"

  exit 0
fi

invert=false  # Default setup assumes Primary monitor on the left. This flags inverts it.
max=false     # Maximize after moving screen?
send_to=""    # If no flag set, calculates and checks to which side should window be sent
center=false  # Center window or try to keep its current position

# test for flags
while getopts "ilrx" flag; do
  case "${flag}" in
    i) invert=true ;;
    l) send_to="l" ;;
    r) send_to="r" ;;
    x) max=true    ;;
    c) center=true ;;
  esac
done

# Get display sizes
text=`xrandr | grep 'connected primary' | cut -d' ' -f4 `
display_1_width="`echo $text | cut -d'x' -f1`"
display_1_height="`echo $text | cut -d'x' -f2 | cut -d'+' -f1`"

text=`xrandr | grep 'connected' | grep -v 'primary' | head -1 | cut -d' ' -f3`
display_2_width="`echo $text  | cut -d'x' -f1`"
display_2_height="`echo $text | cut -d'x' -f2 | cut -d'+' -f1`"

# Assumes primary display is on the Left
right_width=$display_2_width
right_height=$display_2_height
left_width=$display_1_width
left_height=$display_1_height

if [ $invert == true ]; then # inverts this assumption in case of -i flag
  right_width=$display_1_width
  right_height=$display_1_height
  left_width=$display_2_width
  left_height=$display_2_height
fi

export DISPLAY=:0.0

#get current window pid
pid=`xprop -root | awk '/_NET_ACTIVE_WINDOW\(WINDOW\)/{print $NF}'`
pid=`printf "0x%.8x" $((pid))`

#get window params
pos=`wmctrl -lGp | grep $pid`
pos_x=`echo $pos | awk '{print $4}'`
pos_y=`echo $pos | awk '{print $5}'`
pre_width=`echo $pos | awk '{print $6}'`
pre_height=`echo $pos | awk '{print $7}'`
wmctrl -r ":ACTIVE:" -b add,maximized_vert,maximized_horz
wmctrl -r ":ACTIVE:" -b remove,maximized_vert,maximized_horz
pos=`wmctrl -lGp | grep $pid`
width=`echo $pos | awk '{print $6}'`
height=`echo $pos | awk '{print $7}'`


# Logs every size information (for development purposes)
echo "pre_height  $pre_height"
echo "pre_width   $pre_width"
echo "position x  $pos_x"
echo "position y  $pos_y"
echo
echo "right width  $right_width"
echo "right height $right_height"
echo "left_width   $left_width"
echo "left_height  $left_height"
echo
echo "height       $height"
echo "width        $width"
echo "sending to   $send_to"
echo "maximize     $max"
echo "invert       $invert"
echo

# Checks if window was maximized
if [ "$pre_width" -eq "$width"  ] && [ "$pre_height" -eq "$height" ]; then
  echo "not maximized - $pre_width = $width  && $pre_height = $height"
  isMax=false
else
  echo "maximized - $pre_width != $width  && $pre_height != $height"
  isMax=true
fi

# Check for monitor's current position
if [ $((pos_x)) -lt $((left_width)) ]; then
  # echo is left
  left=true
else
  # echo is right
  left=false
fi

# Overrides default side to send, in case flags are used
if [ "$send_to" == "l" ]; then
  left=false
fi
if [ "$send_to" == "r" ]; then
  left=true
fi

# Calculates new window position according to the side to send.
if [ $left == false ]; then 
  #send left
  if [ $center == true ]; then
    new_pos_x=$(( (left_width-width)/2 ))
    new_pos_y=$(( (left_height-height)/2 ))
  else
    curr_pos_x=$(( (pos_x-left_width)*100/right_width ))
    new_pos_x=$(( curr_pos_x*left_width/100 ))
    curr_pos_y=$(( pos_y*100/right_height ))
    new_pos_y=$(( curr_pos_y*left_height/100))
    echo $new_pos_x
    echo $new_pos_y
  fi
else
  #send right
  if [ $center == true ]; then
    new_pos_x=$(( left_width+(right_width-width)/2 ))
    new_pos_y=$(( (right_height-height)/2 ))
  else
    curr_pos_x=$(( (pos_x)*100/left_width ))
    new_pos_x=$(( left_width + curr_pos_x*right_width/100 ))
    curr_pos_y=$(( pos_y*100/left_height ))
    new_pos_y=$(( curr_pos_y*right_height/100))
    echo $new_pos_x
    echo $new_pos_y
  fi
fi

#Sends window to new position
wmctrl -r ":ACTIVE:" -b remove,maximized_vert,maximized_horz 
wmctrl -r ":ACTIVE:" -e 0,$new_pos_x,$new_pos_y,-1,-1
echo "new position x = $new_pos_x"
echo "new position y = $new_pos_y"

#Maximizes it, in case flag was used or if window was maximized
if [ $max == true ] || [ $isMax == true ]; then
  echo "Maximizing"  
  wmctrl -r ":ACTIVE:" -b add,maximized_vert,maximized_horz
fi
