#!/bin/bash

#
# Handles configuration for deployment tools
#

# Only load this library once
if [ -z "${_LIB_CONFIG_SH}" ] ; then

LIB_DIR="$( cd "$( dirname "$(readlink -f "${BASH_SOURCE[0]}")" )" && pwd )"

# Include dependencies
# shellcheck source=./lib/lib-logging.sh
source "${LIB_DIR}/lib-logging.sh"

# Config file to read deployment config from
DEPLOYMENT_CONF="${SCRIPT_DIR}/etc/deployment.conf"

# Path of file used to store AWS credentials
# shellcheck disable=SC2034
MACHINE_CREDENTIALS_FILE=".machine-credentials"

# Read config from file
if [ -f "${DEPLOYMENT_CONF}" ] ; then
    log_info "Reading deployment configuration from ${DEPLOYMENT_CONF}"
    # shellcheck source=./etc/deployment.conf.template
    source "${DEPLOYMENT_CONF}"
else
    log_fatal "Unable to read config from '${DEPLOYMENT_CONF}', exiting."
fi


_LIB_CONFIG_SH="LOADED"
log_debug "Loaded lib-config"
fi # END
