#!/bin/bash

#
# Functions related to logging.
#

# Only load this library once
if [ -z "${_LIB_LOGGING_SH}" ] ; then

# Log output
LOG_OUTFILE=${LOG_OUTFILE:-"$(pwd)/logs/${PROGNAME}-$(date --utc +"%y%m%d%H%M%S").log"}
mkdir -p "$(dirname "${LOG_OUTFILE}")"

# Logging ######################################################################

log_alert()
{
    log_msg "\\e[101mALERT\\e[0m" "\\e[101m${1}\\e[0m"
}

log_debug()
{
    if [ -n "${DEBUG}" ] ; then
        log_msg "\\e[37mDEBUG" "${1}\\e[0m"
    fi
}

log_error()
{
    log_msg "\\e[91mERROR\\e[0m" "${1}"
}

log_fatal()
{
    log_msg "\\e[95mFATAL\\e[0m" "${1}"
    exit 1
}

log_info()
{
    log_msg "\\e[92mINFO \\e[0m" "${1}"
}

log_msg()
{
    local -r level="$1"
    local -r msg="[$(date --utc +"%Y-%m-%d %H:%M:%S")Z] [${level}] $2"
    >&2 echo -e "${msg}"
    # Remove control characters before writing to file
    stripfmt "${msg}" >> "${LOG_OUTFILE}"
}

log_note()
{
    log_msg "\\e[96mNOTE \\e[0m" "\\e[96m${1}\\e[0m"
}

log_warn()
{
    log_msg "\\e[33mWARN \\e[0m" "${1}"
}

stripfmt()
{
    echo -e "$1" | sed -r "s/\\x1B\\[([0-9];)?([0-9]{1,3}(;[0-9]{1,3})?)?[mGK]//g"
}

_LIB_LOGGING_SH="LOADED"
log_debug "Loaded lib-logging"
fi # END
