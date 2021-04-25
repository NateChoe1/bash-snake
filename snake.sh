#!/bin/bash

#This program is free software: you can redistribute it and/or modify
#it under the terms of the GNU General Public License as published by
#the Free Software Foundation, either version 3 of the License, or
#(at your option) any later version.
#
#This program is distributed in the hope that it will be useful,
#but WITHOUT ANY WARRANTY; without even the implied warranty of
#MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#GNU General Public License for more details.
#
#You should have received a copy of the GNU General Public License
#along with this program.  If not, see <https://www.gnu.org/licenses/>.

stty raw
#basically cbreak in ncurses
stty -echo
#don't print stdin to the terminal
echo -e "\033[?25l"
#hide the cursor

snake=""
#the first line is the tail, the last line is the head
UP=0
RIGHT=1
DOWN=2
LEFT=3
direction=$RIGHT
length=5
currentX=10
currentY=10
appleX=20
appleY=10

while :
do
	clear
	echo -en "\033[$appleY;${appleX}H\033[1;31;41mO\033[0m"
	for position in $snake
	do
		echo -en "\033[${position}HX"
	done

	escape=$(echo -en "\x1b")
	oldDirection=$direction
	read -t 0
	while [[ $? -eq 0 ]]
	do
		input=$(dd if=/dev/stdin bs=1 count=1 2> /dev/null)
		if [[ "$input" == "$escape" ]]
		#because bash really sucks at escaping strings
		then
			key=$(dd if=/dev/stdin bs=1 count=2 2> /dev/null)
#This variable name is pretty unclear, so let me explain. Each individual arrow key isn't
#its own individual ascii character. When you press the up arrow, 3 characters are actually
#sent, 0x1b[A, down is 0x1b[B, right is 0x1b[C, and left is 0x1b[D. 0x1b, or \033 is the
#character sent when the escape key is pressed. Basically, you detect when escape input is
#sent, and listen for the identifying key.
			case "$key" in
				\[A)
					if [[ $oldDirection != $DOWN ]]
					then
						direction=$UP
					fi
					;;
				\[B)
					if [[ $oldDirection != $UP ]]
					then
						direction=$DOWN
					fi
					;;
				\[C)
					if [[ $oldDirection != $LEFT ]]
					then
						direction=$RIGHT
					fi
					;;
				\[D)
					if [[ $oldDirection != $RIGHT ]]
					then
						direction=$LEFT
					fi
					;;
			esac
		fi
		read -t 0
	done

	case $direction in
		$UP)
			(( currentY-- ))
			;;
		$RIGHT)
			(( currentX++ ))
			;;
		$DOWN)
			(( currentY++ ))
			;;
		$LEFT)
			(( currentX-- ))
			;;
	esac
	sleep 0.2
	if [[ $currentX -eq 0 || $currentY -eq 0 || $currentX -gt $COLUMNS || $currentY -gt $LINES || $(echo "$snake" | grep "^$currentY;$currentX$") != "" ]]
	then
		break
	fi
	snake=$(echo -en "$snake\n$currentY;$currentX")
	if [[ $(echo "$snake" | wc -l) -gt $length ]]
	then
		snake=$(echo "$snake" | tail -n "$length")
	fi
	if [[ $currentX -eq $appleX && $currentY -eq $appleY ]]
	then
		let length=$length+5
		while [[ $(echo "$snake" | grep "$appleY;$appleX") != "" ]]
		do
			let appleX=$(( $RANDOM % $COLUMNS + 1 ))
			let appleY=$(( $RANDOM % $LINES + 1 ))
		done
	fi
done

stty cooked
stty echo
echo -e "\033[?25h"
#undo the stuff from the beginning

clear
echo "You lost. Final score: $length"
