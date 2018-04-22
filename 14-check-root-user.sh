#!/bin/bash

if [ $USER = root ]; then 
	echo "Yes, You are are root user"
else
	echo "No, You are not a root user"
fi

ID=$(id -u)
if [ $ID -ne 0 ]; then 
	echo "No, You are not a root user"
else
	echo "Yes, You are are root user"
fi