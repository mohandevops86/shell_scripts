#!/bin/bash

read -p 'Enter your class: ' class 

if [ $class = DevOps ]; then
	echo "Hello, Welcome to DevOps Training"
fi

if [ $class = AWS ]; then
	echo "Hello, Welcome to AWS Training"
fi