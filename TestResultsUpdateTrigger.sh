#!/bin/bash

##################
# Global Variables
##################
LOG_FILE_LOCATION="/home/$USER/testresultstrigger.log" #log file location.
HTTP_TIMEOUT=120 #time out value used for HTTP requests, set in seconds.
REMOTE_SERVER_IP=localhost
REQUEST_PAYLOAD="Oops!"
RESPONSE="$(pwd)/out"
ASSERTION_VALUE="HTTP/1.1 200 OK"
MSG="Oops!"
ENDPOINT="https://10.100.5.74:8243/testresultupdater"

##################
# Functions
##################
logmessage()
{
 DATELOCAL=`date`
 echo "$DATELOCAL : $MSG" >> "$LOG_FILE_LOCATION"
 return
}

failover()
{
 return
}

##################
# Checks
##################

#checks for the needed env variables.
if [ -z $POM_ARTIFACTID ]; then
 MSG="ArtifactId was not set as an environmental variable." 
 logmessage $MSG
 exit 1;  
fi

if [ -z $POM_VERSION ]; then
 MSG="POM version was not set as an environmental variable."
 logmessage $MSG
 exit 1;
fi

if [ -z $BUILD_NUMBER ]; then
 MSG="Build number was not set as an environmental variable."
 logmessage $MSG
 exit 1;
fi

#check availability of cURL HTTP client.
dpkg -s curl &> /dev/null
if [ $? -gt 0 ]; then
 MSG="cURL HTTP client was not found. Please install it on the system."
 logmessage $MSG
 exit 1;
fi

#check remote server availability.
ping -q -c 2 -w $HTTP_TIMEOUT $REMOTE_SERVER_IP &> /dev/null
if [ $? -gt 0 ]; then
 MSG="Remote server is inaccessible. Check server accessibility and remote server values set in script."
 logmessage $MSG
 exit 1;
fi


MSG="Preliminary checks passed. Continuing with the script run."
echo "$MSG"
logmessage $MSG
MSG="Parameters for the script run: timeout- $HTTP_TIMEOUT, remote ip- $REMOTE_SERVER_IP, EPR - $ENDPOINT, response file- $RESPONSE, assertion- $ASSERTION_VALUE"
logmessage $MSG

###################
# Invocation Logic
###################

REQUEST_PAYLOAD="$BUILD_NUMBER/$POM_ARTIFACTID/$POM_VERSION"
#Making HTTP request to the result update servlet.
curl -X GET -k -i -f -m $HTTP_TIMEOUT -H "Accept: application/json" "$ENDPOINT/$REQUEST_PAYLOAD" > out
cat "$RESPONSE" | grep "$ASSERTION_VALUE"

#Asserting HTTP response.
if [ $? -gt 0 ]; then
 MSG="Response assertion failed. The response is availble at $RESPONSE"
 logmessage $MSG
 exit 1
fi
rm -r "$RESPONSE"

#Exiting script.
MSG="Test Result Update service was invoked with the project values. Script run successful."
logmessage $MSG
exit 0
