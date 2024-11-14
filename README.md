# KVM Virtual Machine Creation Script

## Description
This script is designed to automate the creation of KVM-based virtual machines using a qcow2 image (Debian or Ubuntu). It allows users to specify various parameters such as CPU, memory, disk size, network settings, and more. It also configures the VM using cloud-init and customizes the network setup.

## Requirements
Before running this script, ensure you have the following:

- A cloud-ready qcow2 image (Debian or Ubuntu). This image should be downloaded from the internet and placed in the same directory as the script.
- KVM and libvirt installed and configured on your system.

### Dependencies:
- `qemu-img`
- `mkpasswd`
- `virt-install`

You can install the required dependencies with the following commands:

```bash
sudo apt-get install qemu-utils whois virtinst
```

## Directory Setup:
- Make sure that the directory /opt/kvm_pool exists, or the script will create it for you.

## How to Use
- Download a cloud-ready qcow2 image (Debian or Ubuntu) and place it in the same directory as this script.
- Run the script with the following command:

‍‍‍```bash
bash kvm-vm-manager.sh create <image_name> --hostname <vm_name> --cpu <cpu_count> --memory <memory_size> --disk <disk_size> --ip <ip_address> --gateway <gateway> --netmask <netmask> --username <username> --password <password> --dns1 <dns1> --dns2 <dns2>
``
### Example usage:
```bash
bash kvm-vm-manager.sh create debian12.img --hostname vmtest --cpu 1 --memory 1024 --disk 10 --ip 172.16.0.1 --gateway 172.16.0.254 --netmask 24 --username debian --password 123 --dns1 8.8.8.8 --dns2 4.2.2.4
```
The script will:

### Validate the inputs.
- Create the necessary cloud-init configuration files.
- Create the virtual machine using virt-install.
- Clean up temporary files once the VM is created.

## Notes
### Bugs and Improvements:
- This script is still in development and may contain bugs. I will be improving it over time to automate more tasks and fix issues. Please report any bugs you encounter, and I will address them in future updates.

## Future Enhancements:
- I plan to add more automation to the script to streamline the process, such as handling image downloads and automatic cloud-init configuration.

## Available Commands
- create: Creates a new virtual machine based on the specified parameters.
- kill <vm_name>: Kills and removes the specified VM.
- killall: Kills and removes all virtual machines.
- help: Displays this help message.

## Disclaimer
- This script is provided as-is, and while it is intended to be functional, it may require updates or modifications depending on your system setup and configuration.
