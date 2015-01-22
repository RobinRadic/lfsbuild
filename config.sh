#!/bin/bash

FOLDER_ROOT=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
FOLDER_TMP="${FOLDER_ROOT}/.tmp"
FOLDER_BUILD="${FOLDER_ROOT}/build"

CURRENT_USER=radic
CURRENT_USER_GROUP=users

HOST_BOX_NAME="lfs-host"
ISO_URL="http://cdimage.debian.org/debian-cd/7.8.0/amd64/iso-cd/debian-7.8.0-amd64-netinst.iso"
ISO_MD5="a91fba5001cf0fbccb44a7ae38c63b6e"

# location, location, location
#FOLDER_VBOX="${FOLDER_ROOT}/build"
HOST_FOLDER_BASE="${FOLDER_TMP}"
HOST_FOLDER_ISO="${HOST_FOLDER_BASE}/iso"
HOST_FOLDER_BUILD="${HOST_FOLDER_BASE}/build"
HOST_FOLDER_ISO_CUSTOM="${HOST_FOLDER_BUILD}/iso/custom"
HOST_FOLDER_ISO_INITRD="${HOST_FOLDER_BUILD}/iso/initrd"


CLIENT_BOX_NAME="lfs-client"