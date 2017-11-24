#!/bin/bash

#
# Functions related to the combined management of AWS and Docker Machine 
# sessions and credentials.
#

# Only load this library once
if [ -z "${_LIB_SESSION_SH}" ] ; then

LIB_DIR="$( cd "$( dirname "$(readlink -f "${BASH_SOURCE[0]}")" )" && pwd )"

# Include dependencies
# shellcheck source=./lib/lib-config.sh
source "${LIB_DIR}/lib-config.sh"

# Session handling #############################################################

session_get()
{
    # Get or create our AWS session
    aws_session_get
    # Update the Docker Machine config with new credentials
    docker_machine_update_driver_auth_config
}

# Removes the old session and gets a new one
session_refresh()
{
    session_rm && session_get
}

session_rm()
{
    # Remove the AWS session
    aws_session_rm
    # Remove our credentials file
    rm -f "${MACHINE_CREDENTIALS_FILE}"
}

_LIB_SESSION_SH="LOADED"
log_debug "Loaded lib-session"
fi # END
