# TestResultUpdateTrigger
This bash script was writ to trigger an internal build test case update mechanism as a Jenkins post job step. Internal script variables,

Variable | Purpose
--- | ---
LOG_FILE_LOCATION | captures the fully qualified path/name of the file that will be used to log script output.
HTTP_TIMEOUT | captures the timeout value used for HTTP requests, set in seconds.
REMOTE_SERVER_IP | captures the ip address or the hostname of the remote server.
REQUEST_PAYLOAD | a variable used to hold the generated request payload. 
RESPONSE | captures the name of a temporary file that gets created to assert the service invocation response.
ASSERTION_VALUE | captures a string that is looked for in the service response to validate successful service invocation.
MSG | a variable used to pass messages to logging function. 
ENDPOINT | captures the URL of the test result update service.
COMPONENTS_QPARAM | captures the generated project components list.
COMPONENTS_OUT | captures the name of a temporary file that gets created while generating components list.
