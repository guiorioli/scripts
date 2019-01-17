#!/bin/bash

invert=false
max=false

# idiomatic parameter and option handling in sh
while getopts "ilrx" flag; do
  case "${flag}" in
    i) invert=true ;;
    l) send_to="l" ;;
    r) send_to="r" ;;
    x) max=true    ;;
  esac
done
text=`xrandr | grep 'connected primary' | cut -d' ' -f4 `
display_1_width="`echo $text | cut -d'x' -f1`"
display_1_height="`echo $text | cut -d'x' -f2 | cut -d'+' -f1`"

text=`xrandr | grep 'connected' | grep -v 'primary' | head -1 | cut -d' ' -f3`
display_2_width="`echo $text  | cut -d'x' -f1`"
display_2_height="`echo $text | cut -d'x' -f2 | cut -d'+' -f1`"

right_width=$display_2_width
right_height=$display_2_height
left_width=$display_1_width
left_height=$display_1_height

if [ $invert == true ]; then
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
wmctrl -r ":ACTIVE:" -b remove,maximized_vert,maximized_horz
pos=`wmctrl -lGp | grep $pid`
width=`echo $pos | awk '{print $6}'`
height=`echo $pos | awk '{print $7}'`

isMax=true
if [ $pre_width == $width  ] && [ $pre_height == $height ]; then
  echo "not maximized"
  isMax=false
fi

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
echo "width = $width"
echo "height = $height"
echo "sending to $send_to"
echo "maximize = $max"
echo "invert = $invert"
echo

left=false
if [ $((pos_x)) -lt $((left_width)) ]; then
  echo is left
  left=true
else
  echo is right
fi



if [ "$send_to" == "l" ]; then
  left=false
fi
if [ "$send_to" == "r" ]; then
  left=true
fi


if [ $left == false ]; then 
  #send left
  new_pos_x=$(( (left_width-width)/2 ))
  new_pos_y=$(( (left_height-height)/2 ))
  wmctrl -r ":ACTIVE:" -b remove,maximized_vert,maximized_horz
  wmctrl -r ":ACTIVE:" -e 0,$new_pos_x,$new_pos_y,-1,-1
else
  #send right
  new_pos_x=$(( left_width+(right_width-width)/2 ))
  new_pos_y=$(( (right_height-height)/2 ))
  wmctrl -r ":ACTIVE:" -b remove,maximized_vert,maximized_horz 
  wmctrl -r ":ACTIVE:" -e 0,$new_pos_x,$new_pos_y,-1,-1
fi
# echo "new position x = $new_pos_x"
# echo "new position y = $new_pos_y"
if [ $max == true ] || [ $isMax == true ]; then
  # echo "Maximizing"  
  wmctrl -r ":ACTIVE:" -b add,maximized_vert,maximized_horz
fi
