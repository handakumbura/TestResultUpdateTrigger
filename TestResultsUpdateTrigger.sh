#!/bin/bash

##################
# Global Variables
##################
LOG_FILE_LOCATION="/home/$USER/testresultstrigger.log" #log file location
HTTP_TIMEOUT=120 #time out value used for HTTP requests, set in seconds.
REMOTE_SERVER_IP=localhost
MSG="Oops!"
ENDPOINT=""

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

#check availability of cURL HTTP client
dpkg -s curl &> /dev/null
if [ $? -gt 0 ]; then
 MSG="cURL HTTP client was not found. Please install it on the system."
 logmessage $MSG
 exit 1;
fi

#check remote server availability
ping -q -c 2 -w $HTTP_TIMEOUT $REMOTE_SERVER_IP &> /dev/null
if [ $? -gt 0 ]; then
 MSG="Remote server is inaccessible. Check server accessibility and remote server values set in script."
 logmessage $MSG
 exit 1;
fi


MSG="Preliminary checks passed. Continuing with the script run."
echo "$MSG"
logmessage $MSG


#------------------
