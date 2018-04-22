#!/bin/bash

### Before your main script
sample() {
	echo "Sample Function"
	return 1
	echo "One more line in function"
}

## Main Script
sample
echo "Exit Status of Function = $?"

