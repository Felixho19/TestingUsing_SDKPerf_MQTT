#!/bin/sh
#
# Script to download the CA cert used by Solace Cloud (https://cloud.solace.com/) and 
# store it in the truststore used by SDKperf

PASSPHRASE=$1
if [ -z "$PASSPHRASE" ]
then
	echo "Please enter a password to use for your keystore files"
	exit -1
fi

SCRIPT_DIR=$(dirname "$0")
if [[ $SCRIPT_DIR =~ "." ]]
then
	KEYS_DIR=$(dirname `pwd`)/keys
else
	KEYS_DIR=$SCRIPT_DIR/../keys
fi 

# See http://docs.aws.amazon.com/iot/latest/developerguide/managing-device-certs.html for URL
if [ -e $KEYS_DIR/solace-cloud-rootCA.crt ]
then
  SOLACECLOUD_ROOT_CERT=$KEYS_DIR/solace-cloud-rootCA.crt
else
  echo "Downloading Solace Cloud root cert"
  wget https://www.thawte.com/roots/thawte_Primary_Root_CA.pem -O $KEYS_DIR/solace-cloud-rootCA.crt
  SOLACECLOUD_ROOT_CERT=$KEYS_DIR/solace-cloud-rootCA.crt
fi

# Now put the root key of the SolaceCloud Service into our truststore
keytool -import -file $KEYS_DIR/solace-cloud-rootCA.crt \
		-keypass $PASSPHRASE -destkeystore $KEYS_DIR/truststore.jks \
		-storepass $PASSPHRASE -deststorepass $PASSPHRASE \
		-trustcacerts -alias SolaceCloudRootCA



