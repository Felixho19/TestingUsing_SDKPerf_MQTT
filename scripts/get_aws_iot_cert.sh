#!/bin/bash

SCRIPT_DIR=$(dirname "$0")
TOOLS_DIR=$SCRIPT_DIR/tools
KEYS_DIR=$SCRIPT_DIR/../keys
RESOURCES_DIR=$SCRIPT_DIR/../resources

if [ -e $SDK_BIN ]
then
  STATUS="SDK Perf MQTT Found"
else
  echo "Couldn't find SDKPerf for MQTT at ${SDK_BIN} exiting..."
  exit -1
fi
echo "SDKPerf for MQTT found at ${SDK_BIN}"

if [ -z "$AWS_CMD" ]
then
  echo "Please set AWS_CMD to the location of the aws tool"
  exit -1
fi

CLIENT_ID_JSON=$KEYS_DIR/awsiot_client_id.json
if [ -e $CLIENT_ID_JSON ]
then
  CERT_ARN=$(cat $CLIENT_ID_JSON | jq -r .certificateArn )
  CERT_ID=$(cat $CLIENT_ID_JSON | jq -r .certificateId )
  AWS_CLIENT_CERT=$KEYS_DIR/${CERT_ID}_cert.pem
  echo "Using existing CERT_ARN=$CERT_ARN"
else
  echo "Creating client cert for AWS IOT..."
  $AWS_CMD iot create-keys-and-certificate --set-as-active --certificate-pem-outfile $KEYS_DIR/awsiot_client_cert.pem \
  	--public-key-outfile $KEYS_DIR/awsiot_client_publicKey.pem \
  	--private-key-outfile $KEYS_DIR/awsiot_client_privateKey.pem > $CLIENT_ID_JSON 2>&1
  CERT_ARN=$(cat $CLIENT_ID_JSON | jq -r .certificateArn )
  CERT_ID=$(cat $CLIENT_ID_JSON | jq -r .certificateId )
  mv $KEYS_DIR/awsiot_client_privateKey.pem $KEYS_DIR/${CERT_ID}_privateKey.pem 
  mv $KEYS_DIR/awsiot_client_publicKey.pem $KEYS_DIR/${CERT_ID}_publicKey.pem 
  mv $KEYS_DIR/awsiot_client_cert.pem $KEYS_DIR/${CERT_ID}_cert.pem
  cp $KEYS_DIR/awsiot_client_id.json $KEYS_DIR/${CERT_ID}_client_id.json
  echo "	Created client cert CERT_ARN=$CERT_ARN"
fi

# See http://docs.aws.amazon.com/iot/latest/developerguide/managing-device-certs.html for URL
if [ -e $KEYS_DIR/aws-iot-rootCA.crt ]
then
  AWS_ROOT_CERT=$KEYS_DIR/aws-iot-rootCA.crt
else
  echo "Downloading AWS IOT root cert"
  wget https://www.symantec.com/content/en/us/enterprise/verisign/roots/VeriSign-Class%203-Public-Primary-Certification-Authority-G5.pem -O $KEYS_DIR/aws-iot-rootCA.crt
  AWS_ROOT_CERT=$KEYS_DIR/aws-iot-rootCA.crt
fi

# Create a policy if it doesn't exist
if [ -e $RESOURCES_DIR/iot_policy_applied.json ]
then
  POLICY_ARN=$(cat $RESOURCES_DIR/iot_policy_applied.json | jq -r '.policyArn')
  echo "Using existing POLICY_ARN=$POLICY_ARN"
else
  $AWS_CMD iot create-policy --policy-name "PubSubToAnyTopic" --policy-document file://$RESOURCES_DIR/iot_policy.json > $RESOURCES_DIR/iot_policy_applied.json 2>&1
  POLICY_ARN=$(cat $RESOURCES_DIR/iot_policy_applied.json | jq -r '.policyArn')
  echo "Create POLICY_ARN=$POLICY_ARN"
fi

# Apply the policy to the certificate
$AWS_CMD iot attach-principal-policy --principal $CERT_ARN --policy-name "PubSubToAnyTopic"



