#!/bin/bash

##################
# Global Variables
##################
LOG_FILE_LOCATION="/home/$USER/testresultstrigger.log" #log file location.
HTTP_TIMEOUT=120 #time out value used for HTTP requests, set in seconds. In the case of cURL this is the max time allowed for the complete operation.
REMOTE_SERVER_IP=192.168.48.112 #the ip address or the hostname of the remote server.
REQUEST_PAYLOAD="Oops!"
RESPONSE="$(pwd)/out" 
ASSERTION_VALUE="Successful" #a string that is looked for in the service response to validate successful service invocation.
MSG="Oops!"
ENDPOINT="http://192.168.48.112:8080/test-results-manager/update" #the URL of the test result update service.
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
processcomponentinfo()
{
 COMPONENTS=""
 PACKAGE_GREP_REGEX="^org.wso2" #******package name used to filter out irrelevant entries.*****
 DELIMITER="ZX78" #******delimiter used to separate dependencies.******
 COMPONENTS_OUT="$(pwd)/$BUILD_NUMBER"

 mvn -f $WORKSPACE/pom.xml dependency:list |  cut -d] -f2- | sed 's/ //g' | grep -E "$PACKAGE_GREP_REGEX" > "$COMPONENTS_OUT"
  
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

processprojectvariable()
{
python - <<END
import os
displayenvvar=os.environ['POM_DISPLAYNAME']
delimeterposition=displayenvvar.find('-')
productname=displayenvvar[:delimeterposition-1]
print productname
END
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

if [ -z $POM_DISPLAYNAME ]; then
 MSG="POM display name was not set as an environmental variable."
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

#check availability of cURL HTTP client.
dpkg -s python &> /dev/null
if [ $? -gt 0 ]; then
 MSG="Python package was not found. Please install it on the system."
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

MSG="Calling processcomponentinfo function to generate the dependency list parameter."
logmessage $MSG
COMPONENTS_QPARAM="$(processcomponentinfo $POM_ARTIFACTID $BUILD_NUMBER $WORKSPACE)"
echo $COMPONENTS_QPARAM
MSG="Query parameter generated according to input parameters and filter parameter is - $COMPONENTS_QPARAM"
logmessage $MSG

PROJECT_NAME="$(processprojectvariable)"
TEST_PLAN="$(echo $PROJECT_NAME | cut -d2 -f2 | cut -c2-)"
MSG="Project name and test plan values generated are - $PROJECT_NAME $TEST_PLAN"
logmessage $MSG

#Making HTTP request to the result update servlet.
#TESTPLAN="DASC5 Test Plan"
curl -X GET -v -G "$ENDPOINT" --data-urlencode "projectName=$PROJECT_NAME" --data-urlencode "testPlanName=$TEST_PLAN" --data-urlencode "buildNo=$BUILD_NUMBER" --data "components=$COMPONENTS_QPARAM" > "$RESPONSE" 

cat "$RESPONSE" | grep "$ASSERTION_VALUE"

#Asserting HTTP response.
if [ $? -gt 0 ]; then
 MSG="Response assertion failed. The response is availble at $RESPONSE"
 logmessage $MSG
 exit 0
fi
rm -r "$RESPONSE"

#Exiting script.
MSG="Test Result Update service was invoked with the project values. Script run successful, find the execution log at $LOG_FILE_LOCATION"
logmessage $MSG
exit 0
