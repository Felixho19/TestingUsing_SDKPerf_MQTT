# Solace_TestingMQTT_AWS
Testing Solace Cloud (running in AWS) and AWS IOT performance as a MQTT transport 

## SDKPerf for MQTT
This test uses the SDKPerf tool for MQTT provided by Solace. [Download](http://dev.solace.com/downloads/download_sdkperf/) the `sol-sdkperf-mqtt-<Version Number>.zip` archive and place in the scripts/tools directory. Extract and then create a soft link from the specific version to `scripts/tools/sol-sdkperf-mqtt`.

```
cd scripts/tools
unzip sol-sdkperf-mqtt-8.1.0.9.zip
ln -s sol-sdkperf-mqtt-8.1.0.9 sol-sdkperf-mqtt
```


## Setup for AWS IOT
### AWS command line tools
In order to configure your AWS IOT environment you need the `aws` tool. On Mac OSX this may be installed by following the guide [on the AWS site](http://docs.aws.amazon.com/cli/latest/userguide/cli-install-macos.html)

Run `aws configure` and enter your AWS access credentials (access key ID and Secret) and which region you wish to access (for Europe I use `eu-west-1` as that's where Solace Cloud runs).

### Generate a certificate on AWS
The first time `scripts/get_aws_iot_cert.sh` script is run it creates a new cert on AWS IOT and applies a policy which allows you to publish to and subscribe to any topic using this cert. The cert is stored as `keys/<uuid>.cert` and the file `keys/awsiot_client_id.json` contains the certificate's ARN and id.
You can generate multiple certs by removing the file `keys/awsiot_client_id.json` and re-running the script.
This script also downloads the root CA cert used by AWS IOT if necessary.

```
AWS_CMD=~/Library/Python/2.7/bin/aws
./scripts/get_aws_iot_cert.sh
```

### Package the cert in a key store
The SDKPerf tool uses two Java Key Stores when invoking services using TLS/SSL.
Run `scripts/pem2jks.sh` to create these and load the root and other certs into it. The key stores are protected by a password, in all the examples which follow we use `myPasskey`

```
./scripts/pem2jks.sh myPasskey
```
This script creates two keystores in the `keys` directory

- clientstore.jks (contains the client identity)
- truststore.jks (contains root cert used by AWS)

## Setup for Solace Cloud
Solace cloud uses a different root cert than AWS so run the following to update the `truststore.jks` file.
```
./scripts/get_solacecloud_cert.sh myPasskey
```

# Running the tests
The scripts `run_sdkperf_aws.sh` and `run_sdkperf_solacecloud.sh` are wrappers around SDKPerf which take the following parameters:

| Name | Default | Description |
|:--|:--|:--|
| PASSPHRASE | | Mandatory. Password used to access keystores |
| MESSAGE_RATE | 1000 | Messages to send per second per client |
| MESSAGE_SIZE | 100 | Message payload size in bytes |
| NUM_CLIENTS | 1 | Number of clients to use |
| QOS | 0 | Quality of service, 0 or 1 supported |

The test sends at a fixed rate using the configured number of clients. Each client publishes to an individual topic (`test/1/<clientId>`) and subscribes to the same topic. The test runs for a warmup period (between 30 and 90 secs) and then starts monitoring end-to-end latency (for 20,000 messages). At the end of the test a detailed report is generated containing the latency histogram for the test.
The min and max warmup periods and number of messages to use for latency measurement are set in the `setenv.sh` script.

The `runTests.sh` script invokes the `run_sdkperf_XXX.sh` repeatedly varying the message rate, size and number of clients.

You can of course run the tests from a local machine, in which case there is latency from your network to AWS, or inside AWS.

# Testing on AWS

1. First install ansible
	 - for example on MacOS using homebrew
		- <code>brew install ansible</code>
1. Set up the AWS access and secret keys in the environment settings
    - E.g. run the following from shell
        - <code>export AWS_ACCESS_KEY_ID="your access key id"</code>
        - <code>export AWS_SECRET_ACCESS_KEY="your secret access key"</code>
1. Modify vars/client.yml
    - update all the ec2_* values accordingly, specifically
    - Update the ec2_image to the AMI ID of the CentOS image to be launched
    - Update the ec2_keypair to the keypair to be used
1. Launch
	- <code>export ANSIBLE_CONFIG=./ansible.cfg</code>
    - <code>ansible-playbook -vv -i localhost, -e "type=client" provision-client.yml</code>
1. Run the tests
	
```
export SOLACECLOUD_MQTT_URL=ssl://host.solace.cloud:port
export SOLACECLOUD_MQTT_UID=solace-cloud-client
export SOLACECLOUD_MQTT_PASSWORD=
export AWS_MQTT_URL=ssl://data.iot.eu-west-1.amazonaws.com:8883
ansible-playbook -v -e "type=client" run-tests.yml
```

In order to find the AMI id for the CentOS7 image follow [Finding AMI ids](https://wiki.centos.org/Cloud/AWS#head-cc841c2a7d874025ae24d427776e05c7447024b2) in the CentOS Wiki
```
aws --region eu-west-1 ec2 describe-images --owners aws-marketplace --filters Name=product-code,Values=aw0evgkw8e5c1q413zgy5pjce
```
The most recent AMI at time of writing is from 2017-12-05 and has ID `ami-192a9460`.

## Analysing the results
The test scripts generate a series of text files in the directory where they are run. The names follow the pattern `<target>_R<rate>_S<size>_C<clients>_Q<qos>.txt`

Copy the results files to the `data` directory and then run the `process_results.sh` script.

```
cd scripts/
mv *.txt ../data
scp -i /path/to/myKeyPair.pem cents@<client_ip>:/home/centos/scripts/*.txt ../data
./process_results.sh <instance_type> <region> 
```

The script generates a CSV file `results.csv` containing one line for each test run. The `<instance_type>` and `<region>` parameters are placed in the second and third columns and may be used to keep track of multiple test sets.

<!-- details><summary>Testing on AWS</summary>
</details -->
