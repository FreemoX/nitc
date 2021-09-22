#!/bin/bash
version=1.2.9.1

updateurl="https://raw.githubusercontent.com/FreemoX/nitc/main/proximport.sh"
githubhistory="https://github.com/FreemoX/nitc/commits/main/proximport.sh"
scriptprettyname="Proximport"
scriptname="proximport.sh"
scriptupdatename="proximport.sh.new"
scripthistoryfile="proximport-update-history"

arg1="$1"

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

initiatecolors() {
    COLreset="\e[0m"
    COLbold="\e[1m"
    COLunderline="\e[4m"
    COLblink="\e[5m"

    COLERROR="\e[1m \e[5m \e[31m"
    COLSUCCESS="\e[1m \e[32m"
    COLINFO="\e[1m \e[93m"
    COLFILE="\e[4m"

    COLred="\e[31m"
    COLgreen="\e[32m"
    COLyellow="\e[93m"
}

grabargs() {
    if [[ $arg1 = "--update" ]] || [[ $arg1 = "-u" ]]; then
        wget -q $updateurl -O $scriptupdatename && wait
        chmod +x $scriptupdatename && mv $scriptupdatename $scriptname && echo -e "$COLgreen\nUpdate completed$COLreset\n" || echo -e "$COLERROR\nUpdate failed$COLreset\n"
        rm $scriptupdatename && wait
        echo -e "A restart of $scriptprettyname is needed to apply the updates!\n$scriptprettyname will now auto-close, you can now re-run it"
        close 0
    elif [[ $arg1 = "--copy" ]] || [[ $arg1 = "-c" ]]; then
        mode=0
    elif [[ $arg1 = "--import" ]] || [[ $arg1 = "-i" ]]; then
        mode=1
        copysuccess=1
    elif [[ $arg1 = "--copy-import" ]] || [[ $arg1 = "-ci" ]]; then
        echo -e "$COLINFO\nNOTE: using --copy-import might take too long and cause issues$COLreset\nIt's recommended to do one run with --copy before doing another run with --import\n\nRunning \"--copy-import\" is only adviced on VM disks < 10GB\n"
        sleep 5
        mode=2
    elif [[ $arg1 = "--version" ]] || [[ $arg1 = "-v" ]]; then
        returnversion
    else
        echo -e "\nPlease supply a valid argument from the list below\n"
        echo "-u  | --update         Force update $scriptprettyname"
        echo "-v  | --version        $scriptprettyname installed version and version history"
        echo "-c  | --copy           Copy VM disk from remote server"
        echo "-i  | --import         Import VM disk into a Proxmox VM"
        echo "-ci | --copy-import    Copy and import a VM disk from remote server"
        close 0
    fi
}

runupdate() {
    wget -q $updateurl -O $scriptupdatename && wait
    versionNEW=$(head -2 $scriptupdatename | tail -1 | cut -d '=' -f 2)
    versionNEWL=$(head -2 $scriptupdatename | tail -1 | cut -d '=' -f 2 | cut -d '.' -f 1)
    versionNEWM=$(head -2 $scriptupdatename | tail -1 | cut -d '=' -f 2 | cut -d '.' -f 2)
    versionNEWS=$(head -2 $scriptupdatename | tail -1 | cut -d '=' -f 2 | cut -d '.' -f 3)
    versionNEWO=$(head -2 $scriptupdatename | tail -1 | cut -d '=' -f 2 | cut -d '.' -f 4)
    versionL=$(head -2 $scriptname | tail -1 | cut -d '=' -f 2 | cut -d '.' -f 1)
    versionM=$(head -2 $scriptname | tail -1 | cut -d '=' -f 2 | cut -d '.' -f 2)
    versionS=$(head -2 $scriptname | tail -1 | cut -d '=' -f 2 | cut -d '.' -f 3)
    versionO=$(head -2 $scriptname | tail -1 | cut -d '=' -f 2 | cut -d '.' -f 4)
    if [[ $versionNEWL -gt $versionL ]] || [[ $versionNEWM -gt $versionM ]] || [[ $versionNEWS -gt $versionS ]] || [[ $versionNEWO -gt $versionO ]]; then
        echo -e "$COLINFO\nThere is a new version available!$COLreset\nCurrent version: $version\nNew version:     $versionNEW"
        if [[ $versionNEWO -gt $versionO ]]; then
            echo -e "This is only an optional update containing minor improvements not related to $scriptprettyname's functionality\n"
        fi
        grabhistory
        echo ""
        read -p "Do you want to update $scriptprettyname to $version? [Y|n] " confirm
        if [[ "$confirm" = "y" ]] || [[ "$confirm" = "Y" ]] || [[ "$confirm" = "" ]]; then
            chmod +x $scriptupdatename && mv $scriptupdatename $scriptname && echo -e "$COLgreen\nUpdate completed$COLreset\n" || echo -e "$COLERROR\nUpdate failed$COLreset\n"
            echo "A restart of $scriptprettyname is needed to apply the updates!"
            close 0
        elif [[ "$confirm" = "n" ]] || [[ "$confirm" = "N" ]]; then
            echo "Ok, not updating $scriptprettyname"
        else
            echo "Input was not y|Y, not updating ..."
        fi
    elif [[ $versionNEWL -eq $versionL ]] && [[ $versionNEWM -eq $versionM ]] && [[ $versionNEWS -eq $versionS ]]; then
        echo -e "You are running the newest version!\nCurrent version: $version\n"
    else
        echo -e "$COLERROR\nAn error occured while comparing the versions!$COLreset\nThis is usually caused by the server not being able to reach GitHub\nThis can also be caused by running a version newer than the release on GitHub. You wizard..." && sleep 1
    fi
    rm $scriptupdatename && wait
}

returnversion() {
    echo -e "$COLINFO\nCurrent $scriptprettyname version: $version\n $COLreset"
    grabhistory
    close 0
}

grabhistory() {
    wget -q $githubhistory -O $scripthistoryfile && wait
    echo -e "$COLbold\nProximport new versions: $COLINFO"
    fortimes=0
    for i in {1..20}; do
    scannedversion=$(cat $scripthistoryfile | grep 'Link--primary text-bold js-navigation-open markdown-title' | grep 'Proximport v' | cut -d '>' -f 2 | cut -d '<' -f 1 | sed -n $i\ p | cut -c 13-)
    fortimes=$(($fortimes+1))
        if [[ $scannedversion = $version ]]; then
            if [[ $fortimes = 1 ]]; then
                echo -e "No new updates available"
            fi
            break
        fi
        echo "$(cat $scripthistoryfile | grep 'relative-time' | cut -d '>' -f 2 | cut -d '<' -f 1 | sed -n $i\ p ) - $(cat $scripthistoryfile | grep 'Link--primary text-bold js-navigation-open markdown-title' | grep 'Proximport v' | cut -d '>' -f 2 | cut -d '<' -f 1 | sed -n $i\ p ): $(cat $scripthistoryfile | grep 'text-small ws-pre-wrap' | cut -d '>' -f 3 | cut -d '<' -f 1 | sed -n $i\ p )"
    done
    echo " $COLreset "
    rm $scripthistoryfile
}

makescreen() {
    screen -S $scriptname && wait && echo -e "\nYou are now using a screen named \"$scriptname\"\nTo disconnect from the screen, press \'CTRL+A D\'\nTo reconnect to the screen, run \'screen -r $scriptname\'\n\nDO NOT PRESS CTRL+C or abort in any way, that will exit $scriptprettyname and potentially lock the system!\n\n\n" || echo -e "\nUnable to create the screen \"$scriptname\", is screen installed?\n\n"
}

getinfo() {
    if [[ "$mode" = 0 ]]; then
        echo -e "\n\nPlease supply the following information for the file copy:\n"
        read -p "Server IP to copy from: " remoteip
        read -p "Username with access to the file: " remoteuser
        read -p "FULL file path on the remote server: " remotefile
        read -p "FULL file path for the transfered file (on this system): " localfile
        if [[ -f "$localfile" ]]; then
            echo -e "$COLINFO\nThat file already exists!$COLreset\nIt needs to be removed in order to proceed!"
            read -p "Remove $localfile ? [Y|n]: " confirm
            if [[ "$confirm" = "y" ]] || [[ "$confirm" = "Y" ]] || [[ "$confirm" = "" ]]; then
                echo "Removing $localfile ..."
                sudo rm $localfile && wait
            elif [[ "$confirm" = "n" ]] || [[ "$confirm" = "N" ]]; then
                echo "Ok, not removing the old file $localfile"
            else
                echo "Input was not y|Y, aborting ..."
                close 0
            fi
        fi
        echo -e "\nInformation you provided:\nServer IP: $remoteip\nRemote User: $remoteuser\nFile to copy FROM: $remotefile\nFile to copy TO: $localfile"
        read -p "Is the information above correct? [Y|n]: " confirm
        if [[ "$confirm" = "y" ]] || [[ "$confirm" = "Y" ]] || [[ "$confirm" = "" ]]; then
            echo "Ok"
        elif [[ "$confirm" = "n" ]] || [[ "$confirm" = "N" ]]; then
            echo "Ok, we'll try that again"
            getinfo
        else
            echo -e "Input was not y|Y ...\nPlease supply your information again\n"
            getinfo
        fi
    elif [[ "$mode" = 1 ]]; then
        read -p "FULL file path for the transfered file (on this system): " localfile
        read -p "Proxmox VM ID: " vmid
        read -p "Proxmox Storage Pool: " localpool
        echo -e "\nInformation you provided:\nVM Disk to import: $localfile\nVM ID: $vmid\nProxmox storage pool: $localpool"
        read -p "Is the information above correct? [Y|n]: " confirm
        if [[ "$confirm" = "y" ]] || [[ "$confirm" = "Y" ]] || [[ "$confirm" = "" ]]; then
            echo "Ok"
        elif [[ "$confirm" = "n" ]] || [[ "$confirm" = "N" ]]; then
            echo "Ok, we'll try that again"
            getinfo
        else
            echo -e "Input was not y|Y ...\nPlease supply your information again\n"
            getinfo
        fi
    elif [[ "$mode" = 2 ]]; then
        echo -e "\n\nPlease supply the following information for the file copy:\n"
        read -p "Server IP to copy from: " remoteip
        read -p "Username with access to the file: " remoteuser
        read -p "FULL file path on the remote server: " remotefile
        read -p "FULL file path for the transfered file (on this system): " localfile
        read -p "Proxmox VM ID: " vmid
        read -p "Proxmox Storage Pool: " localpool
        echo -e "\nInformation you provided:\nServer IP: $remoteip\nRemote User: $remoteuser\nFile to copy FROM: $remotefile\nFile to copy TO: $localfile\nVM ID: $vmid\nProxmox storage pool: $localpool"
        read -p "Is the information above correct? [Y|n]: " confirm
        if [[ "$confirm" = "y" ]] || [[ "$confirm" = "Y" ]] || [[ "$confirm" = "" ]]; then
            echo "Ok"
        elif [[ "$confirm" = "n" ]] || [[ "$confirm" = "N" ]]; then
            echo "Ok, we'll try that again"
            getinfo
        else
            echo -e "Input was not y|Y ...\nPlease supply your information again\n"
            getinfo
        fi
    fi
}

copyfiles() {
    echo -e "\nCopying the file \"$remotefile\" from \"$remoteip\" with the user \"$remoteuser\"...\n"
    scp "$remoteuser"@"$remoteip":"$remotefile" "$localfile" && wait && copysuccess=1
}

importvm() {
    sudo qm importdisk "$vmid" "$localfile" "$localpool" && wait && importdisksuccess=1
    sudo qm rescan && wait && rescansuccess=1
    sudo qm set "$vmid" --scsi0 "$localpool":vm-"$vmid"-disk-0 && setvmmaindisk=1
}

echopost() {
    if [[ "$mode" = 0 ]]; then
        if [[ $copysuccess -ne 1 ]]; then
            echo -e "$COLERROR\n\nTRANSFER ERROR: The VM disk file could not be copied from the remote server!$COLreset\n\n"
        elif [[ $copysuccess -eq 1 ]]; then
            echo -e "The VM Disk should now be copied from the remote server, and stored on this server under:\n$localfile\n\nRemember to re-run $scriptprettyname with the \"--import\" argument to start the import"
        else
            echo -e "$COLERROR\n\nUNKNOWN ERROR: An unknown error occured!$COLreset\n\n"
        fi
    elif [[ "$mode" = 1 ]] || [[ "$mode" = 2 ]]; then
        if [[ $copysuccess -ne 1 ]] || [[ $importdisksuccess -ne 1 ]] || [[ $rescansuccess -ne 1 ]] || [[ $setvmmaindisk -ne 1 ]]; then
            echo -e "$COLERROR\n\nERROR: An error occured during the operation....$COLreset\nThe following tasks returned a failed flag:\n"
            if [[ $copysuccess -ne 1 ]]; then
                echo "- File transfer from remote server"
            fi
            if [[ $importdisksuccess -ne 1 ]]; then
                echo "- Importing disk image to Proxmox"
            fi
            if [[ $rescansuccess -ne 1 ]]; then
                echo "- Rescanning Proxmox disks"
            fi
            if [[ $setvmmaindisk -ne 1 ]]; then
                echo "- Assigning the imported disk as the main disk"
            fi
            echo -e "NOTE: The top failed task indicates which task in the chain failed"
        elif [[ $copysuccess -eq 1 ]] && [[ $importdisksuccess -eq 1 ]] && [[ $rescansuccess -eq 1 ]] && [[ $setvmmaindisk -eq 1 ]]; then
            echo -e "$CULSUCCESS\n\nThe VM should now be imported into Proxmox.$COLreset\nPlease note that some reconfiguration need to be done within the Proxmox WebGUI, such as:"
            echo -e "- Reconfigure the network interfaces\n    Imported VMs don't usually have network connection out-of-the-box\n    Editing \"/etc/netplan/01-netcfg.yaml\" to include the line \"renderer: networkd\" below the \"version\" line should enable the imported VM to grab DHCP\n    The original VM should be disabled to avoid MAC address conflicts and similar issues"
            echo -e "- Reconfigure the VM Boot Order so it attempts to boot from Disk 0 first\n    This is not strictly needed, but should avoid some issues and increase boot speed"
            echo -e "\n"
        else
            echo -e "$COLERROR\n\nUNKNOWN ERROR: An unknown error occured!$COLreset\n\n"
        fi
    fi
    echo -e "\n\n"
    read -n 1 -s -p "Press any key to exit $scriptprettyname" confirm;echo -e "\n\n" && close 0
}

close() {
    echo "$COLreset"
    if test -f "$localfile"; then
        while :
        do
            read -p "Do you wish to delete $localfile? [Y|n]: " confirm
            if [[ "$confirm" = "y" ]] || [[ "$confirm" = "Y" ]] || [[ "$confirm" = "" ]]; then
                rm $localfile && echo "$localfile has been deleted" || echo "Unable to delete $localfile..."
                break
            elif [[ "$confirm" = "n" ]] || [[ "$confirm" = "N" ]]; then
                echo "Ok, not deleting $localfile"
                break
            else
                echo -e "Input was not recognized, try again\n"
            fi
        done
    fi
    if test -f "$scriptupdatename"; then
        rm $scriptupdatename
    fi
    exit $1
}

main() {
    grabargs
    initiatecolors || echo -e "\nERROR: Could not initiate terminal colors for some reason...\nProceeding anyway\n"
    runupdate || echo -e "\nERROR: Function \"runupdate\" returned non-zero exit code!\nDo you have network access?\nProceeding without updating\n"
    # makescreen
    getinfo && wait && echo -e "$COLSUCCESS\nInformation gathered$COLreset\n" || echo -e "$COLERROR\nInformation could not be gathered...$COLreset\n"
    if [[ "$mode" = 0 ]] || [[ "$mode" = 2 ]]; then
        copyfiles && wait && echo -e "$COLSUCCESS\nFiles have been copied...$COLreset\n" || echo -e "$COLERROR\nFiles could not be copied...$COLreset\n"
    elif [[ "$mode" = 1 ]] || [[ "$mode" = 2 ]]; then
        importvm && wait && echo -e "$COLSUCCESS\nVM import completed...$COLreset\n" || echo -e "$COLERROR\nVM could not be imported...$COLreset\n"
    fi
    echopost
}

main || echo -e "CRITICAL ERROR: Uhm... So this is awkward. The function \"main\" failed executing...\nTry installing a different version, you can find them at: $githubhistory\nRemember to make $scriptprettyname executable after downloading it\n\n"
