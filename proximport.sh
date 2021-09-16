#!/bin/bash

if [[ $1 = "update" ]]; then
    echo -e "To update this script, run the following command:\nwget https://raw.githubusercontent.com/FreemoX/nitc/main/proximport.sh && sudo chmod +x proximport.sh"
    exit 0
fi

installdeps() {
    sudo apt install sshpass
}

getinfo() {
    echo -e "\n\nPlease supply the following information for the file copy:\n"
    read -p "Server IP to copy from: " remoteip
    read -p "Username with access to the file: " remoteuser
    read -s -p "$remoteuser's password: " remotepassword
    read -p "FULL file path on the remote server: " remotefile
    read -p "FULL file path for the transfered file (on this system): " localfile
    read -p "Proxmox VM ID: " vmid
    read -p "Proxmox Storage Pool: " localpool
    echo ""
    echo -e "Information you provided:\nServer IP: $remoteip\nRemote User: $remoteuser\nRemote Password: HIDDEN\nFile to copy FROM: $remotefile\nFile to copy TO: $localfile\nVM ID: $vmid\nProxmox storage pool: $localpool"
}

copyfiles() {
    echo -e "\nCopying the file \"$remotefile\" from \"$remoteip\" with the user \"$remoteuser\"...\n"
    #sshpass -p "$remotepassword" scp "$remoteuser"@"$remoteip":"$remotefile" "$localfile"
    scp "$remoteuser"@"$remoteip":"$remotefile" "$localfile"
}

importvm() {
    sudo qm importdisk "$vmid" "$localfile" "$localpool" && wait
    sudo qm rescan && wait
    sudo qm set "$vmid" --scsi0 "$localpool":vm-"$vmid"-disk-0
}

echopost() {
    echo -e "\n\nThe VM should now be imported into Proxmox.\nPlease note that some reconfiguration need to be done within the Proxmox WebGUI, such as:"
    echo -e "- Reconfigure the network interfaces\n    Imported VMs don't usually have network connection out-of-the-box\n    Editing \"/etc/netplan/01-netcfg.yaml\" to include the line \"renderer: networkd\" below the \"version\" line should enable the imported VM to grab DHCP\n    The original VM should be disabled to avoid MAC address conflicts and similar issues"
    echo -e "- Reconfigure the VM Boot Order so it attempts to boot from Disk 0 first\n    This is not strictly needed, but should avoid some issues and increase boot speed"
    echo -e "\n\n"
    read -n 1 -s -p "Press any key to exit this program" confirm;echo -e "\n\n" && exit 0
}

main() {
    installdeps && echo -e "\nDependancies check completed...\n" || echo -e "\nDependancies check failed...\n"
    getinfo && echo -e "\nInformation gathered\n" || echo -e "\nInformation could not be gathered...\n"
    copyfiles && echo -e "\nFiles have been copied...\n" || echo -e "\nFiles could not be copied...\n"
    importvm && echo -e "\nVM import completed...\n" || echo -e "\nVM could not be imported...\n"
    echopost
}

main
