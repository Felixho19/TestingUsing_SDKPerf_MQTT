#!/bin/bash
. setenv.sh

# Usage:
#
# run_sdkperf.sh PASSPHRASE <MESSAGE_RATE MESSAGE_SIZE NUM_CLIENTS QOS>

PASSPHRASE=$1
if [ -z "$PASSPHRASE" ]
then
	echo "Please enter a password to use for your keystore files"
	exit -1
fi

SCRIPT_DIR=$(dirname "$0")
TOOLS_DIR=$SCRIPT_DIR/tools
if [[ $SCRIPT_DIR =~ "." ]]
then
	KEYS_DIR=$(dirname `pwd`)/keys
else
	KEYS_DIR=$SCRIPT_DIR/../keys
fi 
RESOURCES_DIR=$SCRIPT_DIR/../resources
ALIAS=test_alias

if [ -z "$SDKPERF_MQTT" ]
then
  echo "No SDKPERF_MQTT provided, looking for one in tools"
  SDK_BIN=$TOOLS_DIR/sol-sdkperf-mqtt/sdkperf_mqtt.sh
else
  SDK_BIN=$SDKPERF_MQTT/sdkperf_mqtt.sh
  echo "Found SDKPERF_MQTT in environment using ${SDK_BIN}"
fi

if [ -z "$MQTT_URL" ]
then
	echo "Please set MQTT_URL to the URL for your connection to Solace Cloud"
	exit -1
fi
if [ -z "$MQTT_UID" ]
then
	echo "Please set MQTT_UID to the username for your connection to Solace Cloud"
	exit -1
fi
if [ -z "$MQTT_PASSWORD" ]
then
	echo "Please set MQTT_PASSWORD to the password for your connection to Solace Cloud"
	exit -1
fi


MESSAGE_RATE=$2
if [ -z "$MESSAGE_RATE" ]
then
	MESSAGE_RATE=1000
fi

MESSAGE_SIZE=$3
if [ -z "$MESSAGE_SIZE" ]
then
	MESSAGE_SIZE=100
fi

NUM_CLIENTS=$4
if [ -z "$NUM_CLIENTS" ]
then
	NUM_CLIENTS=1
fi

MQTT_SEND_QOS=$5
if [ -z "$MQTT_SEND_QOS" ]
then
	MQTT_SEND_QOS=0
fi

TOTAL_RATE=$(( $MESSAGE_RATE * $NUM_CLIENTS ))
WARM_UP=$(( $MSG_COUNT_FOR_LATENCY / $TOTAL_RATE + ($MSG_COUNT_FOR_LATENCY % $TOTAL_RATE > 0) ))
if [ $WARM_UP -gt $MAXWARMUP_FOR_LATENCY ]
then
	WARM_UP=$MAXWARMUP_FOR_LATENCY
fi
if [ $WARM_UP -lt $MINWARMUP_FOR_LATENCY ]
then
	WARM_UP=$MINWARMUP_FOR_LATENCY
fi
EXPECT_TIME=$(( $MSG_COUNT_FOR_LATENCY / $TOTAL_RATE ))
if [ $EXPECT_TIME -gt $MAXRUNTIME ]
then
        MSG_COUNT_FOR_LATENCY=$(( $TOTAL_RATE * $MAXRUNTIME ))
fi
MESSAGE_COUNT=$(( $TOTAL_RATE * $WARM_UP + $MSG_COUNT_FOR_LATENCY ))

echo "Attempting to send to Solace Cloud at a rate of $MESSAGE_RATE, count=$MESSAGE_COUNT, size=$MESSAGE_SIZE, clients=$NUM_CLIENTS, QOS=$MQTT_SEND_QOS, WARM_UP=$WARM_UP"

MQTT_RECV_QOS=$MQTT_SEND_QOS
MQTT_CLEAN_SESSION=1

TOPIC_NAME="test/1/"

TEST_NAME=R${MESSAGE_RATE}_S${MESSAGE_SIZE}_C${NUM_CLIENTS}_Q${MQTT_SEND_QOS}

if [ -f "solacecloud_${TEST_NAME}.txt" ]
then
	echo "Skipping test as solacecloud_${TEST_NAME}.txt exists"
else
$SDK_BIN -cip $MQTT_URL -as client-certificate -sslp TLSv1.2 \
	-sslts $KEYS_DIR/truststore.jks -ssltsp $PASSPHRASE  -ssltsf=jks \
	-mn $MESSAGE_COUNT -mr $MESSAGE_RATE  -msa=$MESSAGE_SIZE \
	-mpq $MQTT_SEND_QOS -msq $MQTT_SEND_QOS -mcs $MQTT_CLEAN_SESSION \
	-ptp ${TOPIC_NAME} -ptc $NUM_CLIENTS \
	-stp ${TOPIC_NAME} -stc $NUM_CLIENTS \
	-lat -lwu=$WARM_UP -lg=$LATENCY_GRANULARITY -lb 4096 \
	-cu $MQTT_UID -cp $MQTT_PASSWORD \
	-d -cc $NUM_CLIENTS > solacecloud_${TEST_NAME}.txt 2>&1
fi
