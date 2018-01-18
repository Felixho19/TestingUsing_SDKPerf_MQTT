#!/bin/sh
. `pwd`/setenv.sh
PASSPHRASE=$1
if [ -z "$PASSPHRASE" ]
then
	echo "Please enter a password to use for your keystore files"
	exit -1
fi
if [ -z "$SOLACECLOUD_MQTT_URL" ]
then
	SOLACECLOUD_MQTT_URL=$2
fi
if [ -z "$SOLACECLOUD_MQTT_URL" ]
then
	echo "Please set SOLACECLOUD_MQTT_URL to the URL for your connection to Solace Cloud"
	exit -1
fi
if [ -z "$SOLACECLOUD_MQTT_UID" ]
then
	SOLACECLOUD_MQTT_UID=$3
fi
if [ -z "$SOLACECLOUD_MQTT_PASSWORD" ]
then
	SOLACECLOUD_MQTT_PASSWORD=$4
fi
export MQTT_URL=$SOLACECLOUD_MQTT_URL
export MQTT_UID=$SOLACECLOUD_MQTT_UID
export MQTT_PASSWORD=$SOLACECLOUD_MQTT_PASSWORD

for CLIENTS in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20
do
	./run_sdkperf_solacecloud.sh $PASSPHRASE 100 100 $CLIENTS 0
done

for RATE in 200 300 400 500 600 700 800 900 1000 1100 1200 1300 1400 1500 1600 1700 1800 1900 2000
do
	./run_sdkperf_solacecloud.sh $PASSPHRASE $RATE 100 1 0
done

if [ -z "$AWS_MQTT_URL" ]
then
	AWS_MQTT_URL=$5
fi	
if [ -z "$AWS_MQTT_URL" ]
then
	echo "Please set AWS_MQTT_URL to the URL for AWS IOT eg =ssl://data.iot.eu-west-1.amazonaws.com:8883"
	exit -1
fi
export MQTT_URL=$AWS_MQTT_URL

for CLIENTS in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20
do
	./run_sdkperf_aws.sh $PASSPHRASE 100 100 $CLIENTS 0
done

for RATE in 200 300 400 500 600 700 800 900 1000 1100 1200 1300 1400 1500 1600 1700 1800 1900 2000
do
	./run_sdkperf_aws.sh $PASSPHRASE $RATE 100 1 0
done
