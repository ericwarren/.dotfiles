# Arch Linux Installation Guide for Lenovo X1 Carbon Gen 9

This guide provides step-by-step instructions for installing a minimal Arch Linux system with Hyprland on a Lenovo X1 Carbon Generation 9 (16GB RAM) with full disk encryption (LUKS).

## Prerequisites

- Lenovo X1 Carbon Gen 9
- USB drive (at least 2GB)
- Ethernet adapter or working WiFi
- Another computer to create the bootable USB

## Step 1: Create Bootable USB

### On Linux
```bash
# Download the latest Arch ISO
wget https://archlinux.org/iso/latest/archlinux-x86_64.iso

# Find your USB device (be very careful with this)
lsblk

# Write the ISO to USB (replace /dev/sdX with your USB device)
sudo dd bs=4M if=archlinux-x86_64.iso of=/dev/sdX conv=fsync oflag=direct status=progress
```

### On Windows
1. Download the Arch ISO from https://archlinux.org/download/
2. Use Rufus (https://rufus.ie/) or balenaEtcher
3. Select the ISO and your USB drive
4. Use DD mode if prompted

### On macOS
```bash
# Find your USB device
diskutil list

# Unmount the USB (replace diskN with your disk number)
diskutil unmountDisk /dev/diskN

# Write the ISO
sudo dd if=archlinux-x86_64.iso of=/dev/rdiskN bs=1m
```

## Step 2: Configure BIOS/UEFI

1. Power off the laptop
2. Press F1 during boot to enter BIOS
3. Configure the following:
   - **Security → Secure Boot**: Disabled
   - **Config → Sleep State**: Linux
   - **Config → Thunderbolt BIOS Assist Mode**: Enabled
   - **Startup → UEFI/Legacy Boot**: UEFI Only
   - **Startup → Boot Mode**: Quick

4. Press F10 to save and exit

## Step 3: Boot from USB

1. Insert the USB drive
2. Power on and press F12 during boot
3. Select your USB drive from the boot menu
4. When the Arch boot menu appears, select "Arch Linux install medium"

## Step 4: Initial Setup

### Verify UEFI Mode
```bash
ls /sys/firmware/efi/efivars
```
If the directory exists, you're in UEFI mode (required).

### Connect to Internet

#### For WiFi:
```bash
iwctl
device list
station wlan0 scan
station wlan0 get-networks
station wlan0 connect "Your-Network-Name"
exit
```

#### For Ethernet:
Should work automatically if connected.

#### Verify connection:
```bash
ping archlinux.org
```

### Update System Clock
```bash
timedatectl set-ntp true
```

## Step 5: Partition the Disk

### Identify your disk
```bash
lsblk
```
The NVMe SSD will typically be `/dev/nvme0n1`

### IMPORTANT: Wipe existing partitions (if any)
```bash
# Check existing partitions
fdisk -l /dev/nvme0n1

# If you see existing partitions and want to start fresh:
wipefs -af /dev/nvme0n1
# OR use sgdisk to zap all partition data:
sgdisk --zap-all /dev/nvme0n1
```

### Create partitions
```bash
# Start partitioning tool
fdisk /dev/nvme0n1

# Inside fdisk:
g       # Create GPT partition table (will warn about signatures)
        # Answer 'Y' to remove signatures if prompted
n       # New partition
1       # Partition number
        # Press Enter for default first sector
+512M   # Type this for 512MB EFI partition
t       # Change partition type
1       # Select partition 1
1       # Type 1 for EFI System

n       # New partition
2       # Partition number
        # Press Enter for default first sector
        # Press Enter for default last sector (use remaining space)

p       # Print partition table to verify

w       # Write changes and exit
        # Answer 'Y' if asked about removing signatures
```

### Alternative: Using parted (easier)
```bash
parted /dev/nvme0n1
mklabel gpt
mkpart ESP fat32 1MiB 513MiB
set 1 esp on
mkpart primary ext4 513MiB 100%
quit
```

### Encrypt the root partition
```bash
# Encrypt the root partition
cryptsetup luksFormat /dev/nvme0n1p2
# Enter YES (uppercase) when prompted
# Enter your encryption passphrase twice

# Open the encrypted partition
cryptsetup open /dev/nvme0n1p2 cryptroot
# Enter your passphrase
```

### Format partitions
```bash
# Format EFI partition
mkfs.fat -F32 /dev/nvme0n1p1

# Format the encrypted root partition
mkfs.ext4 /dev/mapper/cryptroot
```

### Mount partitions
```bash
# Mount root (encrypted)
mount /dev/mapper/cryptroot /mnt

# Create and mount EFI
mkdir /mnt/boot
mount /dev/nvme0n1p1 /mnt/boot
```

## Step 6: Install Base System

```bash
# Install essential packages (including cryptsetup for encryption)
pacstrap /mnt base linux linux-firmware base-devel intel-ucode networkmanager nano vim cryptsetup

# Generate fstab
genfstab -U /mnt >> /mnt/etc/fstab
```

## Step 7: Configure the System

### Chroot into the new system
```bash
arch-chroot /mnt
```

### Set timezone
```bash
ln -sf /usr/share/zoneinfo/America/New_York /etc/localtime
hwclock --systohc
```

### Set locale
```bash
# Edit locale.gen
nano /etc/locale.gen
# Uncomment: en_US.UTF-8 UTF-8

# Generate locale
locale-gen

# Set locale
echo "LANG=en_US.UTF-8" > /etc/locale.conf
```

### Set hostname
```bash
echo "x1carbon" > /etc/hostname
```

### Configure hosts file
```bash
cat > /etc/hosts << EOF
127.0.0.1   localhost
::1         localhost
127.0.1.1   x1carbon.localdomain x1carbon
EOF
```

### Set root password
```bash
passwd
```

### Configure mkinitcpio for encryption
```bash
# Edit mkinitcpio.conf
nano /etc/mkinitcpio.conf

# Find the HOOKS line and add 'encrypt' before 'filesystems'
# It should look like:
# HOOKS=(base udev autodetect modconf kms keyboard keymap consolefont block encrypt filesystems fsck)

# Regenerate initramfs
mkinitcpio -P
```

## Step 8: Install Bootloader

```bash
# Install systemd-boot
bootctl install

# Get the UUID of the encrypted partition
blkid -s UUID -o value /dev/nvme0n1p2 > /tmp/cryptuuid

# Create boot entry with encryption parameters
cat > /boot/loader/entries/arch.conf << EOF
title   Arch Linux
linux   /vmlinuz-linux
initrd  /intel-ucode.img
initrd  /initramfs-linux.img
options cryptdevice=UUID=$(cat /tmp/cryptuuid):cryptroot root=/dev/mapper/cryptroot rw quiet
EOF

# IMPORTANT: The 'options' line must be ONE SINGLE LINE!
# If it wraps in your editor, that's just visual - don't add any newlines!

# Configure loader
cat > /boot/loader/loader.conf << EOF
default arch.conf
timeout 5
console-mode max
editor no
EOF
```

## Step 9: Create User Account

```bash
# Create your user (replace 'username' with your desired username)
useradd -m -G wheel -s /bin/bash username
passwd username

# Enable sudo for wheel group
EDITOR=nano visudo
# Uncomment: %wheel ALL=(ALL:ALL) ALL
```

## Step 10: Enable Essential Services

```bash
# Enable NetworkManager
systemctl enable NetworkManager

# Exit chroot
exit

# Unmount and reboot
umount -R /mnt
reboot
```

## Step 11: First Boot and Post-Installation

1. Remove the USB drive during reboot
2. Login as your user
3. Connect to network:
   ```bash
   nmtui
   ```

4. Clone your dotfiles and run the setup script:
   ```bash
   # Install git first
   sudo pacman -S git
   
   # Clone dotfiles
   git clone https://github.com/ericwarren/.dotfiles.git ~/.dotfiles
   
   # Run the minimal setup
   cd ~/.dotfiles
   ./setup-x1-arch.sh
   
   # Stow configurations
   stow hyprland wezterm
   ```

5. Start Hyprland:
   ```bash
   Hyprland
   ```

## X1 Carbon Gen 9 Specific Notes

### Recommended packages for X1 Carbon hardware:
```bash
# After first boot, install these for better hardware support:
sudo pacman -S sof-firmware alsa-firmware alsa-ucm-conf \
    mesa vulkan-intel intel-media-driver \
    libva-intel-driver intel-gpu-tools
```


## Troubleshooting

- **Black screen after boot**: Try adding `i915.enable_psr=0` to kernel parameters
- **WiFi not working**: Ensure `linux-firmware` is installed
- **Audio issues**: Install `sof-firmware` package
- **Touchpad not working**: Will be configured when you add more packages later
- **Encryption password not accepted**: Ensure keyboard layout is correct (US layout during install)
- **Boot fails with encryption**: Check UUID in `/boot/loader/entries/arch.conf` matches your encrypted partition
- **ERROR: device '/dev...' at boot**: The `options` line in `/boot/loader/entries/arch.conf` MUST be one single line - no line breaks!

## Next Steps

You now have a minimal Arch Linux installation with Hyprland. You can:
- Add more packages as needed
- Configure Hyprland further
- Set up additional tools and applications

Remember: This is a minimal setup. You'll need to install additional packages for a full desktop experience.