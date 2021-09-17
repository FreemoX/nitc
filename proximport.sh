#!/bin/bash
version=1.2.0

if [[ $1 = "--update" ]]; then
    wget https://raw.githubusercontent.com/FreemoX/nitc/main/proximport.sh -o proximport.sh.new && wait
    versionNEW=$(head -2 proximport.sh.new | tail -1)
    versionNEWL=$(head -2 proximport.sh.new | tail -1 | cut -d \= -f 2 | cut -d \. -f 1)
    versionNEWM=$(head -2 proximport.sh.new | tail -1 | cut -d \= -f 2 | cut -d \. -f 2)
    versionNEWS=$(head -2 proximport.sh.new | tail -1 | cut -d \= -f 2 | cut -d \. -f 3)
    versionL=$(head -2 proximport.sh | tail -1 | cut -d \= -f 2 | cut -d \. -f 1)
    versionM=$(head -2 proximport.sh | tail -1 | cut -d \= -f 2 | cut -d \. -f 2)
    versionS=$(head -2 proximport.sh | tail -1 | cut -d \= -f 2 | cut -d \. -f 3)
    if [[ $versionNEWL -gt $versionL ]] || [[ $versionNEWM -gt $versionM ]] || [[ $versionNEWS -gt $versionS ]]; then
        echo -e "\nThere is a new version available!\nCurrent version: $version\nNew version:     $versionNEW"
        chmod +x proximport.sh.new && mv proximport.sh.new proximport.sh && echo "Update completed" || echo "Update failed"
    elif [[ "$versionNEW" = "$version" ]]; then
        echo -e "\nUpdate not needed, already at the latest version!"
    else
        echo -e "\nFailed to compare versions! Is the server online?"
        exit 1
    fi
    exit 0
elif [[ $1 = "--copy" ]]; then
    mode=0
elif [[ $1 = "--import" ]]; then
    mode=1
elif [[ $1 = "--copy-import" ]]; then
    echo -e "\nNOTE: using --copy-import might take too long and cause issues\nIt's recommended to do one run with --copy before doing another run with --import"
    sleep 5
    mode=2
else
    echo -e "\nPlease supply an argument"
    echo "--update       Update Proximport"
    echo "--copy         Copy VM disk from remote server"
    echo "--import       Import VM disk into a Proxmox VM"
    echo "--copy-import  Copy and import a VM disk from remote server"
    exit 0
fi

getinfo() {
    if [[ "$mode" = 0 ]]; then
        echo -e "\n\nPlease supply the following information for the file copy:\n"
        read -p "Server IP to copy from: " remoteip
        read -p "Username with access to the file: " remoteuser
        read -p "FULL file path on the remote server: " remotefile
        read -p "FULL file path for the transfered file (on this system): " localfile
        echo -e "\nInformation you provided:\nServer IP: $remoteip\nRemote User: $remoteuser\nFile to copy FROM: $remotefile\nFile to copy TO: $localfile"
    elif [[ "$mode" = 1 ]]; then
        read -p "FULL file path for the transfered file (on this system): " localfile
        read -p "Proxmox VM ID: " vmid
        read -p "Proxmox Storage Pool: " localpool
        echo -e "\nInformation you provided:\nVM Disk to import: $localfile\nVM ID: $vmid\nProxmox storage pool: $localpool"
    elif [[ "$mode" = 2 ]]; then
        echo -e "\n\nPlease supply the following information for the file copy:\n"
        read -p "Server IP to copy from: " remoteip
        read -p "Username with access to the file: " remoteuser
        read -p "FULL file path on the remote server: " remotefile
        read -p "FULL file path for the transfered file (on this system): " localfile
        read -p "Proxmox VM ID: " vmid
        read -p "Proxmox Storage Pool: " localpool
        echo -e "\nInformation you provided:\nServer IP: $remoteip\nRemote User: $remoteuser\nFile to copy FROM: $remotefile\nFile to copy TO: $localfile\nVM ID: $vmid\nProxmox storage pool: $localpool"
    fi
}

copyfiles() {
    echo -e "\nCopying the file \"$remotefile\" from \"$remoteip\" with the user \"$remoteuser\"...\n"
    scp "$remoteuser"@"$remoteip":"$remotefile" "$localfile"
}

importvm() {
    sudo qm importdisk "$vmid" "$localfile" "$localpool" && wait
    sudo qm rescan && wait
    sudo qm set "$vmid" --scsi0 "$localpool":vm-"$vmid"-disk-0
}

echopost() {
    if [[ "$mode" = 0 ]]; then
        echo -e "The VM Disk should now be copied from the remote server, and stored on this server under:\n$localfile\n\nRemember to re-run Proximport with the \"--import\" argument to start the import"
    elif [[ "$mode" = 1 ]] || [[ "$mode" = 2 ]]; then
        echo -e "\n\nThe VM should now be imported into Proxmox.\nPlease note that some reconfiguration need to be done within the Proxmox WebGUI, such as:"
        echo -e "- Reconfigure the network interfaces\n    Imported VMs don't usually have network connection out-of-the-box\n    Editing \"/etc/netplan/01-netcfg.yaml\" to include the line \"renderer: networkd\" below the \"version\" line should enable the imported VM to grab DHCP\n    The original VM should be disabled to avoid MAC address conflicts and similar issues"
        echo -e "- Reconfigure the VM Boot Order so it attempts to boot from Disk 0 first\n    This is not strictly needed, but should avoid some issues and increase boot speed"
    fi
    echo -e "\n\n"
    read -n 1 -s -p "Press any key to exit this program" confirm;echo -e "\n\n" && exit 0
}

main() {
    getinfo && echo -e "\nInformation gathered\n" || echo -e "\nInformation could not be gathered...\n"
    if [[ "$mode" = 0 ]] || [[ "$mode" = 2 ]]; then
        copyfiles && echo -e "\nFiles have been copied...\n" || echo -e "\nFiles could not be copied...\n"
    elif [[ "$mode" = 1 ]] || [[ "$mode" = 2 ]]; then
        importvm && echo -e "\nVM import completed...\n" || echo -e "\nVM could not be imported...\n"
    fi
    echopost
}

main
