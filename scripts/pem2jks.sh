#!/bin/bash -x

SCRIPT_DIR=$(dirname "$0")
PASSPHRASE=$1
if [ -z "$PASSPHRASE" ]
then
	echo "Please enter a password to use for your keystore files"
	exit -1
fi

TOOLS_DIR=$SCRIPT_DIR/tools
KEYS_DIR=$SCRIPT_DIR/../keys
RESOURCES_DIR=$SCRIPT_DIR/../resources
ALIAS=test_alias

# First we need to turn our PEM file into a p12 file for access by keytool
if [ -z "$CERT_ID" ]
then
	CLIENT_ID_JSON=$KEYS_DIR/awsiot_client_id.json
	if [ -e $CLIENT_ID_JSON ]
	then
		CERT_ID=$(cat $CLIENT_ID_JSON | jq -r .certificateId )
  		echo "Using existing CERT_ID=$CERT_ID"
	else
		echo "Couldn't find CLIENT_ID_JSON file, and no CERT_ID env variable set"
		exit -1
	fi
else
	echo "Using CERT_ID=$CERT_ID from env variable"
fi

AWS_CLIENT_PRIVATEKEY=$KEYS_DIR/${CERT_ID}_privateKey.pem
if [ -e $AWS_CLIENT_PRIVATEKEY ]
then
	echo "Converting private key file $AWS_CLIENT_PRIVATEKEY to pk12 format"
	openssl pkcs12 -export -out $KEYS_DIR/${CERT_ID}_client.p12 \
		-inkey $AWS_CLIENT_PRIVATEKEY \
		-in $KEYS_DIR/${CERT_ID}_cert.pem \
		-name $ALIAS \
		-CAfile $KEYS_DIR/aws-iot-rootCA.crt -caname root \
		-passout pass:${PASSPHRASE}
else
	echo "Can't find private key file $AWS_CLIENT_PRIVATEKEY"
	exit -1
fi

if [ -e $KEYS_DIR/${CERT_ID}_private.p12 ]
then
	# First a store with just the public key of the AWS Service
	keytool -import -file $KEYS_DIR/aws-iot-rootCA.crt \
		-keypass $PASSPHRASE -destkeystore $KEYS_DIR/truststore.jks \
		-storepass $PASSPHRASE -deststorepass $PASSPHRASE \
		-trustcacerts
	
	# Now a store with the public/private key for our client
	keytool -importkeystore -srckeystore $KEYS_DIR/${CERT_ID}_client.p12 -srcstoretype PKCS12 \
		-keypass $PASSPHRASE -destkeystore $KEYS_DIR/clientstore.jks -storepass $PASSPHRASE -deststorepass $PASSPHRASE \
		-srcstorepass $PASSPHRASE
else
	echo "Can't find private key file $KEYS_DIR/${CERT_ID}_private.p12"
	exit -1
fi





