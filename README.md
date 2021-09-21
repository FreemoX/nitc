# Proximport | proximport.sh
Bash script handling the importation of KVM QEMU VMs into Proxmox.<br>**NOTE**: Proximport needs to be run as sudo<br><br>
**Usage:**<ul>
  <li>-u --update<br>
    Update proximport. Redundant above version 1.2.4 since an auto-update check is implemented
  <li>-c --copy<br>
    Copy/transfer VM disk image from external server to the current server
  <li>-i --import<br>
    Import a local VM disk image into an existing Proxmox VM
  <li>-ci --copy-import<br>
    Runs both -c and -i in sequence. Note that this might take too long and get timed out. Use at your own risk
  <li>-v --version<br>
    Display the installed version of Proximport
