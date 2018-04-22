#!/bin/bash

read -p 'Enter Website: ' website 
if [ -z "$website" ]; then 
	echo -e "\e[31mYou need to enter a web domain\e[0m"
	exit 1
fi

ping -c 3 $website &>/dev/null
STAT=$?

if [ "$STAT" -eq 0 ]; then 
	echo -e "Ping :: \e[32mOK\e[0m"
	exit 0
elif [ "$STAT" -gt 0 ]; then 
	echo -e "Ping :: \e[31mNotOK\e[0m"
	exit 1
fi