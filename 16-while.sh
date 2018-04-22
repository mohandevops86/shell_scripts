#!/bin/bash

i=12
while [ $i -gt 0 ]; do 
	ps -ef | grep systemd | grep -v grep &>/dev/null
	if [ $? -ne 0 ]; then 
		break
	fi
	sleep 5
	i=$(($i-1))
done
ps -ef | grep systemd | grep -v grep &>/dev/null
if [ $? -eq 0 ]; then 
	echo "Process still running"
else
	echo "Process not running"
fi