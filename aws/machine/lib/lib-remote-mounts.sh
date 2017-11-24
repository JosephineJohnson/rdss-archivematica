#!/bin/bash

#
# Functions related to the management of mounted filesystems on remote machines.
#

# Only load this library once
if [ -z "${_LIB_REMOTE_MOUNTS_SH}" ] ; then

LIB_DIR="$( cd "$( dirname "$(readlink -f "${BASH_SOURCE[0]}")" )" && pwd )"

# Include dependencies
# shellcheck source=./lib/lib-config.sh
source "${LIB_DIR}/lib-config.sh"

# Remote mounts ################################################################

remote_add_mount()
{
    local -r device_path="$1"
    local -r mount_path="$2"
    local -r mount_type="$3"
    local -r mount_opts="$4"
    local -r fstab_entry="${device_path}	${mount_path}	${mount_type}	${mount_opts}"
    log_info "Adding mount '${mount_path}'..."
    log_debug "Checking fstab entry: ${fstab_entry}"
    # Check if there is already an fstab entry for this mount path
    if [ "$(docker-machine ssh "${DOCKERHOST_INSTANCE}" \
            "grep ${mount_path} /etc/fstab" 2>/dev/null)" != "" ] ; then
        # Mount already exists for given mount path, replace it
        log_debug "Replacing ${fstab_entry}"
        docker-machine ssh "${DOCKERHOST_INSTANCE}" \
            "cp /etc/fstab /tmp/fstab.new && \
            sed 's|.*${mount_path}.*|${fstab_entry}|' /etc/fstab > \
            /tmp/fstab.new"
    else
        # Mount doesn't already exist, append it
        log_debug "Adding ${fstab_entry}"
        docker-machine ssh "${DOCKERHOST_INSTANCE}" \
            "cp /etc/fstab /tmp/fstab.new && echo '${fstab_entry}' >> /tmp/fstab.new"
    fi
    # Update the fstab file with the new mount point
    docker-machine ssh "${DOCKERHOST_INSTANCE}" \
        sudo mv -f /tmp/fstab.new /etc/fstab
    # Create the mount path folder if necessary
    docker-machine ssh "${DOCKERHOST_INSTANCE}" "sudo mkdir -p ${mount_path}"
    # Mount or remount the mount path as necessary
    if [ "$(docker-machine ssh "${DOCKERHOST_INSTANCE}" \
            "mount | grep ${mount_path} " 2>/dev/null)" != "" ] ; then
        # Mount path is already mounted, unmount before mounting
        docker-machine ssh "${DOCKERHOST_INSTANCE}" sudo umount -l "${mount_path}"
    fi
    log_info "Mounting '${mount_path}'..."
    docker-machine ssh "${DOCKERHOST_INSTANCE}" sudo mount "${mount_path}"
}

remote_mount_arkivum()
{
    local -r arkivum_host="$1"
    # Add the fstab entry for the given arkivum host and mount as a CIFS share
    remote_add_mount "//${arkivum_host}/astor" \
        "/mnt/astor" \
        "cifs" \
        "defaults,guest,file_mode=0666,dir_mode=0777,rw 0 1"
}

remote_mount_nfs()
{
    local -r nfs_host="$1"
    # Add the fstab entry for the given nfs host and mount
    remote_add_mount "${nfs_host}:/mnt/nfs" \
        "/mnt/nfs" \
        "nfs" \
        "auto,noatime,nolock,bg,nfsvers=4,tcp,intr"
}

remote_mount_s3fs()
{
    local -r s3_bucket_params="$1"
    if [ "${s3_bucket_params}" != "" ] ; then
        local -r s3_bucket_name="$(echo "$s3_bucket_params" | cut -d: -f1)"
        local -r s3_access_key_id="$(echo "$s3_bucket_params" | cut -d: -f2)"
        local -r s3_secret_key="$(echo "$s3_bucket_params" | cut -d: -f3)"
        local -r s3_bucket_mount_name="$(echo "$s3_bucket_params" | cut -d: -f4)"
        # Add the AWS credentials config (assumes all s3 buckets use same credentials)
        log_info "Updating S3FS credentials..."
        docker-machine ssh "${DOCKERHOST_INSTANCE}" \
            "echo '${s3_bucket_name}:${s3_access_key_id}:${s3_secret_key}' > /tmp/passwd-s3fs && \
                sudo mv /tmp/passwd-s3fs /etc/passwd-s3fs && chmod 640 /etc/passwd-s3fs"
        # Add the fstab entry and mount
        remote_add_mount "${s3_bucket_name}" \
            "/mnt/s3/${s3_bucket_mount_name}" \
            "fuse.s3fs" \
            "_netdev,allow_other,ro,uid=33,gid=33,umask=0000,no_check_certificate 0 0"
    fi
}

_LIB_REMOTE_MOUNTS_SH="LOADED"
log_debug "Loaded lib-remote-mounts"
fi # END
