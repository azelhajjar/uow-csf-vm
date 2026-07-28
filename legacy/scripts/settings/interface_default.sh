#!/bin/bash
# Modify grub and disable the predictable network interface naming scheme.


# Function to update GRUB configuration
update_grub() {
  echo "Updating GRUB configuration..."
  sudo sed -i 's/GRUB_CMDLINE_LINUX=""/GRUB_CMDLINE_LINUX="net.ifnames=0 biosdevname=0"/' /etc/default/grub
  sudo update-grub
}

# Function to update network interface names in /etc/network/interfaces
update_interfaces() {
  if [ -f /etc/network/interfaces ]; then
    echo "Updating /etc/network/interfaces..."
    # Replace enp* with eth*
    sudo sed -i 's/enp/eth/g' /etc/network/interfaces
  fi
}

# Function to update network interface names in Netplan configuration
update_netplan() {
  if [ -d /etc/netplan ]; then
    for file in /etc/netplan/*.yaml; do
      echo "Updating $file..."
      # Replace enp* with eth* in Netplan YAML files
      sudo sed -i 's/enp/eth/g' "$file"
    done
    sudo netplan apply
  fi
}

# Function to reboot the system
#reboot_system() {
#  echo "Rebooting the system..."
#  sudo reboot
#}

# Main function to execute all steps
main() {
  update_grub
  #update_interfaces
  #update_netplan
#  reboot_system
}

# Execute the main function
main