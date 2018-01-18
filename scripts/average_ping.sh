#!/bin/bash
# Script to calculate the average ping time

TOTAL=0
COUNT=0
while read line
do
	if [ -z "$line" ]
	then
		echo "$line // $PINGTIME // $COUNT"
	else
		PINGTIME=$(echo "$line" | cut -d "=" -f4 | cut -d " " -f1)
		TOTAL=$( echo "$TOTAL + $PINGTIME" | bc )
		COUNT=$(( $COUNT + 1 ))
		echo "$line // $PINGTIME // $COUNT"
	fi
done < "${1:-/dev/stdin}"
AVG_PING=$( echo "$TOTAL / $COUNT * 1.0" | bc )
echo "Average ping time: $AVG_PING"


