#!/bin/bash
# Script to process output of test runs

TYPE=$1
REGION=$2
SOLACE_VERSION=$3
if [ -z "$VERSION" ]
then
	SOLACE_VERSION = "8_4"
fi
STATS_FILE="results.csv"
DATA_DIR=../data
echo "file,instance type,region,target,version,message size,qos,no clients,desired rate,publish rate,subscribe rate,avg latency,50 percentile,95 percentile,99 percentile,99.9 percentile,std deviation" > $STATS_FILE
for INFILE in $DATA_DIR/*.txt;
do
	OUTFILE=${INFILE/\.txt/.csv}
	OUTIMG=${INFILE/\.txt/.png}
	echo "Processing $INFILE -> $OUTFILE"
	echo "bin,latency,count"> $OUTFILE
	cat $INFILE |grep "BI:" | cut -d ":" -d " " -f2 -f4 -f6| xargs printf "%i,%i,%i\n" 	>> $OUTFILE
	
	TARGET=$(echo $INFILE | cut -d "_" -f1 | cut -d "/" -f3 )
	case "$TARGET" in 
  		"solacecloud")
    		VERSION=$SOLACE_VERSION
    		;;
    	*)
    		VERSION="1_0"
    		;;
	esac
	
	DDRATE=$( echo $INFILE | cut -d "_" -f2 | cut -d "R" -f2 )
	SIZE=$(echo $INFILE | cut -d "_" -f3 | cut -d "S" -f2 )
	CLIENTS=$( echo $INFILE | cut -d "_" -f4 | cut -d "C" -f2 )
	QOS=$(echo $INFILE | cut -d "_" -f5 | cut -d "Q" -f2 | cut -d "." -f1)
	DRATE=$(( $DDRATE * $CLIENTS ))
	
	PUBRATE=$(cat $INFILE | grep "Computed publish rate (msg/sec) =" | cut -d "=" -f2 | cut -d "." -f1| xargs)
	SUBRATE=$(cat $INFILE | grep "Computed subscriber rate (msg/sec across all subscribers)" | cut -d "=" -f2 | xargs)
	AVGLAT=$(cat $INFILE | grep "Average latency for subs" | cut -d "=" -f2 | cut -d " " -f2 | xargs)
	s50LAT=$(cat $INFILE | grep "50th percentile latency" | cut -d "=" -f2 | cut -d " " -f2 | xargs)
	s95LAT=$(cat $INFILE | grep "95th percentile latency" | cut -d "=" -f2 | cut -d " " -f2 | xargs)
	s99LAT=$(cat $INFILE | grep "99th percentile latency" | cut -d "=" -f2 | cut -d " " -f2 | xargs)
	s999LAT=$(cat $INFILE | grep "99.9th percentile latency " | cut -d "=" -f2 | cut -d " " -f2 | xargs)
	SDLAT=$(cat $INFILE | grep "Standard Deviation " | cut -d "=" -f2 | cut -d " " -f2 | xargs)
	
	echo "$INFILE,$TYPE,$REGION,$TARGET,$VERSION,$SIZE,$QOS,$CLIENTS,$DRATE,$PUBRATE,$SUBRATE,$AVGLAT,$s50LAT,$s95LAT,$s99LAT,$s999LAT,$SDLAT" >> $STATS_FILE
	#Rscript GraphSDKPerfLatency.R -f $OUTFILE -o $OUTIMG
done