#!/bin/bash

##################
# Global Variables
##################
#LOG_FILE_LOCATION=`/home/$USER/resultsupdatetrigger.log` #log file location
HTTP_TIMEOUT=120 #time out value used for HTTP requests, set in seconds.
REMOTE_SERVER_IP=localhost
MSG="unset"


##################
#functions
##################
logmessage()
{
 DATELOCAL=`date`
 echo "$DATELOCAL : $MSG" >> ../testout
 return
}




##################
#checks
##################

#checks for the needed env variables.
if [ -z $POM_ARTIFACTID ]; then
 MSG="artifactId was not set as an environmental variable." 
 logmessage $MSG
 exit 1;  
fi

if [ -z $POM_VERSION ]; then
 MSG="pom version was not set as an environmental variable."
 logmessage $MSG
 exit 1;
fi

#check for remote server availability
ping -q -c 2 -w $HTTP_TIMEOUT $REMOTE_SERVER_IP
if [ $? -gt 0 ]; then
 MSG="remote server is inaccessible. Check server accessibility and remote server values set in script."
 logmessage $MSG
 exit 1;
fi

echo "Preliminary checks passed. Continuing with the script run."
