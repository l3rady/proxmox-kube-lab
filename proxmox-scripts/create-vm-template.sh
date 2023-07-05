#!/bin/bash
ubuntuImageURL=https://cloud-images.ubuntu.com/releases/22.04/release/ubuntu-22.04-server-cloudimg-amd64.img
ubuntuImageFilename=$(basename $ubuntuImageURL)
ubuntuImageBaseURL=$(dirname $ubuntuImageURL)
proxmoxTemplateID="${TMPL_ID:-9000}"
proxmoxTemplateName="${TMPL_NAME:-ubuntu-2204}"
scriptTmpPath=/tmp/promox-scripts

init () {
    [ $(id -u) == 0 ] && apt-get update && apt-get install sudo -y || exit 1
    clean
    installRequirements
    mkdir -p $scriptTmpPath
    vmDiskStorage="${PM_STORAGE:-$(sudo pvesm status | awk '$2 != "dir" {print $1}' | tail -n 1)}"
    cd $scriptTmpPath
}

installRequirements () {
    dpkg -l libguestfs-tools &> /dev/null || \
    apt update -y && sudo apt install libguestfs-tools -y
}

getImage () {
    local _img=/tmp/$ubuntuImageFilename
    local imgSHA256SUM=$(curl -s $ubuntuImageBaseURL/SHA256SUMS | grep $ubuntuImageFilename | awk '{print $1}')
    if [ -f "$_img" ] && [[ $(sha256sum $_img | awk '{print $1}') == $imgSHA256SUM ]]
    then
        echo "The image file exists and the signature is OK"
    else
        wget $ubuntuImageURL -O $_img
    fi
    
    cp $_img $ubuntuImageFilename
}

enableCPUHotplug () {
    virt-customize -a $ubuntuImageFilename \
    --run-command 'echo "SUBSYSTEM==\"cpu\", ACTION==\"add\", TEST==\"online\", ATTR{online}==\"0\", ATTR{online}=\"1\"" > /lib/udev/rules.d/80-hotplug-cpu.rules' 
}

installQemuGA () {
    virt-customize -a $ubuntuImageFilename \
    --run-command 'sudo apt update -y && sudo apt install qemu-guest-agent -y && sudo systemctl start qemu-guest-agent'
}

resetMachineID () {
    virt-customize -x -a $ubuntuImageFilename \
    --run-command 'sudo echo -n >/etc/machine-id'
}

createProxmoxVMTemplate () {
    qm destroy $proxmoxTemplateID --purge || true
    qm create $proxmoxTemplateID --name $proxmoxTemplateName --memory 2048 --cores 2 --net0 virtio,bridge=vmbr0
    qm importdisk $proxmoxTemplateID $ubuntuImageFilename $vmDiskStorage
    qm set $proxmoxTemplateID --scsihw virtio-scsi-single --virtio0 $vmDiskStorage:vm-$proxmoxTemplateID-disk-0
    qm set $proxmoxTemplateID --boot c --bootdisk virtio0
    qm set $proxmoxTemplateID --ide2 $vmDiskStorage:cloudinit
    qm set $proxmoxTemplateID --serial0 socket --vga serial0
    qm set $proxmoxTemplateID --agent enabled=1,fstrim_cloned_disks=1
    qm template $proxmoxTemplateID
}

clean () { 
    rm -rf $scriptTmpPath 
}

init
getImage
enableCPUHotplug
installQemuGA
resetMachineID
createProxmoxVMTemplate
clean

