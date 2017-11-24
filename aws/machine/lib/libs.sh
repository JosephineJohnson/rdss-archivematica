#!/bin/bash

#
# Main include file for library functions. This includes all other libraries.
#

# Only load this library once
if [ -z "${_LIB_LIBS_SH}" ] ; then

LIB_DIR="$( cd "$( dirname "$(readlink -f "${BASH_SOURCE[0]}")" )" && pwd )"

# Import the individual module files
# shellcheck source=./lib/lib-aws.sh
source "${LIB_DIR}/lib-aws.sh"
# shellcheck source=./lib/lib-config.sh
source "${LIB_DIR}/lib-config.sh"
# shellcheck source=./lib/lib-docker.sh
source "${LIB_DIR}/lib-docker.sh"
# shellcheck source=./lib/lib-logging.sh
source "${LIB_DIR}/lib-logging.sh"
# shellcheck source=./lib/lib-remote-mounts.sh
source "${LIB_DIR}/lib-remote-mounts.sh"
# shellcheck source=./lib/lib-session.sh
source "${LIB_DIR}/lib-session.sh"

_LIB_LIBS_SH="LOADED"
log_debug "Loaded libs"
fi # END