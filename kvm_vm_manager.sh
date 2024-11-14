#!/bin/bash

function create_vm() {
  # Validate inputs
  [[ -z $image_name ]] && echo "image_name is empty" && exit 1
  [[ -z $vm_name ]] && echo "vm_name is empty" && exit 1
  [[ -z $cpu ]] && echo "cpu is empty" && exit 1
  [[ -z $memory ]] && echo "memory is empty" && exit 1
  [[ -z $disk_size ]] && echo "disk_size is empty" && exit 1
  [[ -z $username ]] && echo "username is empty" && exit 1
  [[ -z $password ]] && echo "password is empty" && exit 1
  [[ -z $ip_address ]] && echo "ip_address is empty" && exit 1
  [[ -z $netmask ]] && echo "netmask is empty" && exit 1
  [[ -z $gateway ]] && echo "gateway is empty" && exit 1
  [[ -z $dns1 ]] && dns1="8.8.8.8" && echo "Setting Default DNS $dns1 for dns1"
  [[ -z $dns2 ]] && dns2="4.2.2.4" && echo "Setting Default DNS $dns2 for dns1"

  # Create /opt/kvm_pool if it doesn't exist
  [[ ! -d /opt/kvm_pool ]] &&  mkdir -p /opt/kvm_pool

  # Copy the base image and rename it
  [[ ! -f ./$image_name ]] && echo "You need to put your qcow2 disk near the script, file $image_name Not Found." && exit 1
  cp ./$image_name /opt/kvm_pool
  mv /opt/kvm_pool/$image_name /opt/kvm_pool/$vm_name.img
  qemu-img resize /opt/kvm_pool/$vm_name.img $disk_size"G"
  
  # Generate the hashed password and escape any $ characters in the hash
  hashed_password=$(echo "$password" | mkpasswd -m sha-512 -s)

  # Create cloud-init configuration with the appropriate values
  echo "
#cloud-config

hostname: $vm_name
timezone: Asia/Tehran
users:
  - name: $username
    groups: [ sudo ]
    shell: /bin/bash
    lock_passwd: false
    passwd: \"$hashed_password\"

ntp:
  servers:
    - time1.google.com
    - time2.google.com
    - time3.google.com
" > $vm_name-config

  echo "
version: 2
ethernets:
  enp1s0:
    dhcp4: no
    addresses:
      - ${ip_address}/${netmask}
    gateway4: $gateway
    nameservers:
      addresses:
        - $dns1
        - $dns2
" > $vm_name-config-network

  # Create the cloud-init ISO
  cloud-localds cloudinit.iso $vm_name-config -N $vm_name-config-network

  # Install the VM using virt-install
  sudo virt-install \
    --name $vm_name \
    --vcpus $cpu \
    --memory $memory \
    --disk path=/opt/kvm_pool/$vm_name.img,format=qcow2 \
    --disk path=cloudinit.iso,device=cdrom \
    --network network=nat \
    --os-variant debian12 \
    --import \
    --noautoconsole

  # Cleanup temporary files
  rm -f cloudinit.iso $vm_name-config $vm_name-config-network
  virsh detach-device $vm_name --file disk.xml --config
}

function help_me() {
  echo "To create a VM, please download a cloud-ready (qcow2) image (debian or ubuntu) then place it near this script."
  echo "Initialize your KVM settings (nat.xml) and create the /opt/kvm_pool directory. Install the dependencies (qemu-img, mkpasswd, virt-install)."
  echo "Then you are good to go."
  echo "Example usage:"
  echo "bash kvm-vm-manager.sh create debian12.img --hostname vmtest --cpu 1 --memory 1024 --disk 10 --ip 172.16.0.1 --gateway 172.16.0.254 --netmask 24 --username debian --password 123 --dns1 8.8.8.8 --dns2 4.2.2.4" 
}

function kill_vm(){
  local vm_name=$1
  vm=$(virsh list --all | grep -iw $vm_name | awk '{print $2}')
  virsh destroy $vm
  virsh undefine $vm --remove-all-storage --nvram
}
function kill_allvm() {
  vm_list=$(virsh list --all | awk 'NR>2 {print $2}')
  for vm in ${vm_list[@]} ; do
  kill_vm $vm
  done
}
function get_inputs() {
  while [ $# -gt 0 ]; do
    case $1 in
      kill | remove | delete)
      kill_vm $2 && {
        echo "$2 Vm removed." 
        exit 1
      } || {
        echo Failed to Remove $2 VM.
      }
      ;;
      killall | removeall | deleteall)
      kill_allvm && {
        echo "All Vms removed." 
        exit 1
      } || {
        echo Failed to Remove all or some VMs.
      }
      ;;
      --ip)
        ip_address=$2
        shift
        shift
      ;;
      --gateway)
        gateway=$2
        shift
        shift
      ;;
      --netmask)
        netmask=$2
        shift
        shift
      ;;
      --hostname)
        vm_name=$2
        shift
        shift
      ;;
      create | run)
        image_name=$2
        create_virtualmachine="true"
        shift
        shift
      ;;
      --username)
        username=$2
        shift
        shift
      ;;
      --password)
        password=$2
        shift
        shift
      ;;
      --cpu)
        cpu=$2
        shift
        shift
      ;;
      --memory)
        memory=$2
        shift
        shift
      ;;
      --disk)
        disk_size=$2
        shift
        shift
      ;;
      --dns1)
        dns1=$2
        shift
        shift
      ;;
      --dns2)
        dns2=$2
        shift
        shift
      ;;
      --help | help | -h)
        help_me
        exit 0
      ;;
      *)
        cmd="$@"
        shift
      ;;
    esac
  done
}

# Check dependencies before running
command -v mkpasswd >/dev/null 2>&1 || { echo "mkpasswd is required but not installed. Exiting."; exit 1; }
command -v qemu-img >/dev/null 2>&1 || { echo "qemu-img is required but not installed. Exiting."; exit 1; }
command -v virt-install >/dev/null 2>&1 || { echo "virt-install is required but not installed. Exiting."; exit 1; }

# Process inputs and create the VM
get_inputs $@
if [[ $create_virtualmachine == "true" ]]; then
create_vm || {
  echo "VM Creation Failed."
  exit 1
}
fi
