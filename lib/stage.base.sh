#!/bin/bash

_base-init() {
    # make sure we have dependencies
    hash vagrant 2>/dev/null || { echo >&2 "ERROR: vagrant not found.  Aborting."; exit 1; }
    hash VBoxManage 2>/dev/null || { echo >&2 "ERROR: VBoxManage not found.  Aborting."; exit 1; }
    hash 7z 2>/dev/null || { echo >&2 "ERROR: 7z not found. Aborting."; exit 1; }
    hash curl 2>/dev/null || { echo >&2 "ERROR: curl not found. Aborting."; exit 1; }

    VBOX_VERSION="$(VBoxManage --version)"

    if hash mkisofs 2>/dev/null; then
      MKISOFS="$(which mkisofs)"
    elif hash genisoimage 2>/dev/null; then
      MKISOFS="$(which genisoimage)"
    else
      echo >&2 "ERROR: mkisofs or genisoimage not found.  Aborting."
      exit 1
    fi

    set -o nounset
    set -o errexit
    #set -o xtrace

    # Configurations

    # Env option: Use headless mode or GUI
    #VM_GUI="${VM_GUI:-}"
    #if [ "x${VM_GUI}" == "xyes" ] || [ "x${VM_GUI}" == "x1" ]; then
      STARTVM="VBoxManage startvm ${HOST_BOX_NAME} --type gui"
    #else
    #  STARTVM="VBoxManage startvm ${HOST_BOX_NAME} --type headless"
    #fi
    STOPVM="VBoxManage controlvm ${HOST_BOX_NAME} poweroff"

    # Env option: Use custom preseed.cfg or default
    DEFAULT_PRESEED="preseed.cfg"
    PRESEED="${PRESEED:-"$DEFAULT_PRESEED"}"

    # Env option: Use custom late_command.sh or default
    DEFAULT_LATE_CMD="${HOST_FOLDER_BASE}/late_command.sh"
    LATE_CMD="${LATE_CMD:-"$DEFAULT_LATE_CMD"}"

    # Parameter changes from 4.2 to 4.3
    if [[ "$VBOX_VERSION" < 4.3 ]]; then
      PORTCOUNT="--sataportcount 1"
    else
      PORTCOUNT="--portcount 1"
    fi

      MD5="md5sum"
}

_base-clean() {


    # start with a clean slate
    if VBoxManage list runningvms | grep "${HOST_BOX_NAME}" >/dev/null 2>&1; then
      Echo "Stopping vm ..."
      ${STOPVM}
    fi
    if VBoxManage showvminfo "${HOST_BOX_NAME}" >/dev/null 2>&1; then
      Echo "Unregistering vm ..."
      VBoxManage unregistervm "${HOST_BOX_NAME}" --delete
    fi
    if [ -d "${HOST_FOLDER_BUILD}" ]; then
      Echo "Cleaning build directory ..."
      chmod -R u+w "${HOST_FOLDER_BUILD}"
      rm -rf "${HOST_FOLDER_BUILD}"
    fi
    if [ -f "${HOST_FOLDER_ISO}/custom.iso" ]; then
      Echo "Removing custom iso ..."
      rm "${HOST_FOLDER_ISO}/custom.iso"
    fi
    if [ -f "${HOST_FOLDER_BASE}/${HOST_BOX_NAME}.box" ]; then
      Echo "Removing old ${HOST_BOX_NAME}.box" ...
      rm "${HOST_FOLDER_BASE}/${HOST_BOX_NAME}.box"
    fi

    # Setting things back up again
    mkdir -p "${HOST_FOLDER_ISO}"
    mkdir -p "${HOST_FOLDER_BUILD}"
    mkdir -p "${FOLDER_VBOX}"
    mkdir -p "${HOST_FOLDER_ISO_CUSTOM}"
    mkdir -p "${HOST_FOLDER_ISO_INITRD}"

}

_base-make-iso() {
    ISO_FILENAME="${HOST_FOLDER_ISO}/`basename ${ISO_URL}`"
    INITRD_FILENAME="${HOST_FOLDER_ISO}/initrd.gz"

    # download the installation disk if you haven't already or it is corrupted somehow
    Echo "Downloading `basename ${ISO_URL}` ..."
    if [ ! -e "${ISO_FILENAME}" ]; then
      curl --output "${ISO_FILENAME}" -L "${ISO_URL}"
    fi

    # make sure download is right...
    ISO_HASH=$($MD5 "${ISO_FILENAME}" | cut -d ' ' -f 1)
    if [ "${ISO_MD5}" != "${ISO_HASH}" ]; then
      echo "ERROR: MD5 does not match. Got ${ISO_HASH} instead of ${ISO_MD5}. Aborting."
      exit 1
    fi

    # customize it
    echo "Creating Custom ISO"
    if [ ! -e "${HOST_FOLDER_ISO}/custom.iso" ]; then

      echo "Using 7zip"
      7z x "${ISO_FILENAME}" -o"${HOST_FOLDER_ISO_CUSTOM}"

      # If that didn't work, you have to update p7zip
      if [ ! -e $HOST_FOLDER_ISO_CUSTOM ]; then
        echo "Error with extracting the ISO file with your version of p7zip. Try updating to the latest version."
        exit 1
      fi

      # backup initrd.gz
      echo "Backing up current init.rd ..."
      FOLDER_INSTALL=$(ls -1 -d "${HOST_FOLDER_ISO_CUSTOM}/install."* | sed 's/^.*\///')
      chmod u+w "${HOST_FOLDER_ISO_CUSTOM}/${FOLDER_INSTALL}" "${HOST_FOLDER_ISO_CUSTOM}/install" "${HOST_FOLDER_ISO_CUSTOM}/${FOLDER_INSTALL}/initrd.gz"
      cp -r "${HOST_FOLDER_ISO_CUSTOM}/${FOLDER_INSTALL}/"* "${HOST_FOLDER_ISO_CUSTOM}/install/"
      mv "${HOST_FOLDER_ISO_CUSTOM}/install/initrd.gz" "${HOST_FOLDER_ISO_CUSTOM}/install/initrd.gz.org"

      # stick in our new initrd.gz
      echo "Installing new initrd.gz ..."
      cd "${HOST_FOLDER_ISO_INITRD}"
      if [ "$OSTYPE" = "msys" ]; then
        gunzip -c "${HOST_FOLDER_ISO_CUSTOM}/install/initrd.gz.org" | sudo cpio -i --make-directories || true
      else
        gunzip -c "${HOST_FOLDER_ISO_CUSTOM}/install/initrd.gz.org" | sudo cpio -id || true
      fi
        sudo chown -R ${CURRENT_USER}:${CURRENT_USER_GROUP} "$HOST_FOLDER_BASE"

      cd "${HOST_FOLDER_BASE}"
      if [ "${PRESEED}" != "${DEFAULT_PRESEED}" ] ; then
        echo "Using custom preseed file ${PRESEED}"
      fi
      cp "${PRESEED}" "${HOST_FOLDER_ISO_INITRD}/preseed.cfg"
      cd "${HOST_FOLDER_ISO_INITRD}"
      find . | cpio --create --format='newc' | gzip  > "${HOST_FOLDER_ISO_CUSTOM}/install/initrd.gz"

      # clean up permissions
      echo "Cleaning up Permissions ..."
      chmod u-w "${HOST_FOLDER_ISO_CUSTOM}/install" "${HOST_FOLDER_ISO_CUSTOM}/install/initrd.gz" "${HOST_FOLDER_ISO_CUSTOM}/install/initrd.gz.org"

      # replace isolinux configuration
      echo "Replacing isolinux config ..."
      cd "${HOST_FOLDER_BASE}"
      chmod u+w "${HOST_FOLDER_ISO_CUSTOM}/isolinux" "${HOST_FOLDER_ISO_CUSTOM}/isolinux/isolinux.cfg"
      rm "${HOST_FOLDER_ISO_CUSTOM}/isolinux/isolinux.cfg"
      cp isolinux.cfg "${HOST_FOLDER_ISO_CUSTOM}/isolinux/isolinux.cfg"
      chmod u+w "${HOST_FOLDER_ISO_CUSTOM}/isolinux/isolinux.bin"

      # add late_command script
      echo "Add late_command script ..."
      chmod u+w "${HOST_FOLDER_ISO_CUSTOM}"
      cp "${LATE_CMD}" "${HOST_FOLDER_ISO_CUSTOM}/late_command.sh"



      echo "Running mkisofs ..."
      "$MKISOFS" -r -V "Custom Debian Install CD" \
        -cache-inodes -quiet \
        -J -l -b isolinux/isolinux.bin \
        -c isolinux/boot.cat -no-emul-boot \
        -boot-load-size 4 -boot-info-table \
        -o "${HOST_FOLDER_ISO}/custom.iso" "${HOST_FOLDER_ISO_CUSTOM}"
    fi
}

_base-make-virtual() {
    echo "Creating VM Box..."
    # create virtual machine
    if ! VBoxManage showvminfo "${HOST_BOX_NAME}" >/dev/null 2>&1; then
      VBoxManage createvm \
        --name "${HOST_BOX_NAME}" \
        --ostype Debian_64 \
        --register \
        --basefolder "${FOLDER_VBOX}"

      VBoxManage modifyvm "${HOST_BOX_NAME}" \
        --pae on \
        --cpus 6 \
        --memory 4100 \
        --boot1 dvd \
        --boot2 disk \
        --boot3 none \
        --boot4 none \
        --vram 12 \
        --rtcuseutc on

      VBoxManage storagectl "${HOST_BOX_NAME}" \
        --name "IDE Controller" \
        --add ide \
        --controller PIIX4 \
        --hostiocache on

      VBoxManage storageattach "${HOST_BOX_NAME}" \
        --storagectl "IDE Controller" \
        --port 1 \
        --device 0 \
        --type dvddrive \
        --medium "${HOST_FOLDER_ISO}/custom.iso"

      VBoxManage storagectl "${HOST_BOX_NAME}" \
        --name "SATA Controller" \
        --add sata \
        --controller IntelAhci \
        $PORTCOUNT \
        --hostiocache off

      VBoxManage createhd \
        --filename "${FOLDER_VBOX}/${HOST_BOX_NAME}/${HOST_BOX_NAME}.vdi" \
        --size 40960

      VBoxManage storageattach "${HOST_BOX_NAME}" \
        --storagectl "SATA Controller" \
        --port 0 \
        --device 0 \
        --type hdd \
        --medium "${FOLDER_VBOX}/${HOST_BOX_NAME}/${HOST_BOX_NAME}.vdi"

      ${STARTVM}

      echo -n "Waiting for installer to finish "
      while VBoxManage list runningvms | grep "${HOST_BOX_NAME}" >/dev/null; do
        sleep 20
        echo -n "."
      done
      echo ""

      VBoxManage storageattach "${HOST_BOX_NAME}" \
        --storagectl "IDE Controller" \
        --port 1 \
        --device 0 \
        --type dvddrive \
        --medium emptydrive
    fi
}

_base-make-vagrant() {
    echo "Building Vagrant Box ..."
    vagrant package --base "${HOST_BOX_NAME}" --output "${HOST_BOX_NAME}.box"
}
# references:
# http://blog.ericwhite.ca/articles/2009/11/unattended-debian-lenny-install/
# http://docs-v1.vagrantup.com/v1/docs/base_boxes.html
# http://www.debian.org/releases/stable/example-preseed.txt
