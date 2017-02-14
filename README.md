# TestResultUpdateTrigger
This bash script is writ to trigger an internal build test case update mechanism as a Jenkins post step. Internal script variables,

Variable | Purpose
--- | ---
LOG_FILE_LOCATION | captures the fully qualified path/name of the file that will be used to log script output.
HTTP_TIMEOUT | timeout value used for HTTP requests, set in seconds.
REMOTE_SERVER_IP | ip address or the hostname of the remote server.
MSG | a variable used to pass messages to the logging function. 
ENDPOINT | URL of the test result update servlet.
