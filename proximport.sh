#!/bin/bash
version=1.2.4.0

# Proximport
# A simple bash script that handles the importation of VM disks into a Proxmox VM
#
# Versioning explained:
#     1st number is major release, providing new functionality to core features
#     2nd number is medium release, greatly improving on existing core features
#     3rd number is minor release, containing bug-fixes and similar improvements
#     4th number is micro release, containing improvements not strictly needing an upgrade
#
# Current limitation:
#     - The --copy function only uses standard scp port
#     - There are currently minimal checks; if something goes wrong, Proximport will still continue doing its thing
#     - There is no way to pass a remote password through Proximport; this has to be provided interactively
# 
# Proximport was made by Franz Rolfsvaag 2021
# This software is released freely as-is; no guarantees or support is provided, use at your own discression!

if [[ $1 = "--update" ]] || [[ $1 = "-u" ]]; then
    runupdate
elif [[ $1 = "--copy" ]] || [[ $1 = "-c" ]]; then
    mode=0
elif [[ $1 = "--import" ]] || [[ $1 = "-i" ]]; then
    mode=1
elif [[ $1 = "--copy-import" ]] || [[ $1 = "-ci" ]]; then
    echo -e "\nNOTE: using --copy-import might take too long and cause issues\nIt's recommended to do one run with --copy before doing another run with --import\n\nRunning \"--copy-import\" is only adviced on VM disks < 10GB\n"
    sleep 5
    mode=2
elif [[ $1 = "--version" ]] || [[ $1 = "-v" ]]; then
    echo -e "\nCurrent Proximport version: $version\n"
    exit 0
else
    echo -e "\nPlease supply a valid argument from the list below\n"
    echo "-u  | --update         Update Proximport"
    echo "-uf | --update-forced  Force an update/downgrade from the latest GitHub release"
    echo "-v  | --version        Proximport installed version"
    echo "-c  | --copy           Copy VM disk from remote server"
    echo "-i  | --import         Import VM disk into a Proxmox VM"
    echo "-ci | --copy-import    Copy and import a VM disk from remote server"
    exit 0
fi

runupdate() {
    wget https://raw.githubusercontent.com/FreemoX/nitc/main/proximport.sh -O proximport.sh.new && wait
    versionNEW=$(head -2 proximport.sh.new | tail -1 | cut -d '=' -f 2)
    versionNEWL=$(head -2 proximport.sh.new | tail -1 | cut -d '=' -f 2 | cut -d '.' -f 1)
    versionNEWM=$(head -2 proximport.sh.new | tail -1 | cut -d '=' -f 2 | cut -d '.' -f 2)
    versionNEWS=$(head -2 proximport.sh.new | tail -1 | cut -d '=' -f 2 | cut -d '.' -f 3)
    versionL=$(head -2 proximport.sh | tail -1 | cut -d '=' -f 2 | cut -d '.' -f 1)
    versionM=$(head -2 proximport.sh | tail -1 | cut -d '=' -f 2 | cut -d '.' -f 2)
    versionS=$(head -2 proximport.sh | tail -1 | cut -d '=' -f 2 | cut -d '.' -f 3)
    if [[ $versionNEWL -gt $versionL ]] || [[ $versionNEWM -gt $versionM ]] || [[ $versionNEWS -gt $versionS ]]; then
        echo -e "\nThere is a new version available!\nCurrent version: $version\nNew version:     $versionNEW"
        echo -e "\n\n"
        read -p "Do you want to update proximport to $version? [y|n]" confirm
        if [[ $confirm = "y" ]] || [[ $confirm = "Y" ]]; then
            chmod +x proximport.sh.new && mv proximport.sh.new proximport.sh && echo -e "\nUpdate completed\n" || echo -e "\nUpdate failed\n"
        else
            echo "Input was not y|Y, not updating ..."
        fi
    elif [[ $versionNEWL -eq $versionL ]] && [[ $versionNEWM -eq $versionM ]] && [[ $versionNEWS -eq $versionS ]]; then
        echo -e "\nUpdate not needed, already at the latest version!\nCurrent version: $version"
        rm proximport.sh.new
    else
        echo -e "\nAn error occured while comparing the versions!\nThis is usually caused by the server not being able to reach GitHub\nThis can also be caused by running a version newer than the release on GitHub. You wizard..."
        exit 1
    fi
    exit 0
}

makescreen() {
    screen -S proximport.sh && echo -e "\nYou are now using a screen named \"proximport.sh\"\nTo disconnect from the screen, press \'CTRL+A D\'\nTo reconnect to the screen, run \'screen -r proximport.sh\'\n\nDO NOT PRESS CTRL+C or abort in any way, that will exit proximport and potentially lock the system!\n\n\n" || echo -e "\nUnable to create the screen \"proximport.sh\", is screen installed?\n\n"
}

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
        echo -e "\n"
    fi
    echo -e "\n\n"
    read -n 1 -s -p "Press any key to exit this program" confirm;echo -e "\n\n" && exit 0
}

main() {
    runupdate
    makescreen
    getinfo && echo -e "\nInformation gathered\n" || echo -e "\nInformation could not be gathered...\n"
    if [[ "$mode" = 0 ]] || [[ "$mode" = 2 ]]; then
        copyfiles && echo -e "\nFiles have been copied...\n" || echo -e "\nFiles could not be copied...\n"
    elif [[ "$mode" = 1 ]] || [[ "$mode" = 2 ]]; then
        importvm && echo -e "\nVM import completed...\n" || echo -e "\nVM could not be imported...\n"
    fi
    echopost
}

main
