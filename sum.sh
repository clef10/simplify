#!/bin/bash

# Takes the integer input and displays the sum
 
[[ "$#" -lt 1 ]] && echo "Usage: bash $0 space-separated-integers" && exit
for INPUT in $@
do 
	[[ $INPUT =~ ^[0-9]+$ ]] && >/dev/null || F='1'
done
[[ $F == '1' ]] && echo "Usage: bash $0 space-separated-integers" || ( echo $@ | sed "s/ /+/g" | bc )
