#!/bin/bash

##################
# Global Variables
##################
LOG_FILE_LOCATION="/home/$USER/testresultstrigger.log" #log file location.
HTTP_TIMEOUT=120 #time out value used for HTTP requests, set in seconds. In the case of cURL this is the max time allowed for the complete operation.
REMOTE_SERVER_IP=localhost #the ip address or the hostname of the remote server.
REQUEST_PAYLOAD="Oops!"
RESPONSE="$(pwd)/out" 
ASSERTION_VALUE="HTTP/1.1 200 OK" #a string that is looked for in the service response to validate successful service invocation.
MSG="Oops!"
ENDPOINT="https://10.100.5.74:8243/testresultupdater" #the URL of the test result update service.
COMPONENTS_QPARAM=""
COMPONENTS_OUT="Oops!"

##################
# Functions
##################
logmessage()
{
 DATELOCAL=`date`
 echo "$DATELOCAL : $MSG" >> "$LOG_FILE_LOCATION"
 return
}

# INPUT POM_ARTIFACTID POM_ARTIFACTID WORKSPACE  
processprojectinfo()
{
 COMPONENTS=""
 PACKAGE_NAME="org.wso2" #package name used to filter out irrelevant entries.
 DELIMITER="-" #delimiter used to separate dependencies.
 COMPONENTS_OUT="$(pwd)/$POM_ARTIFACTID$BUILD_NUMBER"

 mvn -f $WORKSPACE/pom.xml dependency:list | ( [[ $? == 0 ]] && grep "$PACKAGE_NAME" ) | cut -d] -f2- | sed 's/ //g' > "$COMPONENTS_OUT"
  
 #asserting dependency command redirection.
  if [ $? -gt 0 ]; then
   MSG="Something went wrong while generating the project dependency list. Run command manually to diagnose."
   logmessage MSG
   exit 1
  fi

 #generate query parameter
 for LINE in $(< $COMPONENTS_OUT); do
        COMPONENTS="$COMPONENTS$DELIMITER$LINE"
 done

 rm -r $COMPONENTS_OUT #cleanup.
 echo $COMPONENTS
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

if [ -z $WORKSPACE ]; then
 MSG="Workspace was not set as an environmental variable."
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

MSG="Calling processprojectinfo function to generate the dependency list parameter."
logmessage $MSG
COMPONENTS_QPARAM="$(processprojectinfo $POM_ARTIFACTID $BUILD_NUMBER $WORKSPACE)"
MSG="Query parameter generated according to input parameters and filter parameter is - $COMPONENTS_QPARAM"
logmessage $MSG

####
#WIP
####

REQUEST_PAYLOAD="$BUILD_NUMBER/$POM_ARTIFACTID/$POM_VERSION"
#Making HTTP request to the result update servlet.
curl -X GET -k -i -f -m $HTTP_TIMEOUT -H "Accept: application/json" "$ENDPOINT/$REQUEST_PAYLOAD" > "$RESPONSE"
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
