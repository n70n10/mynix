# NixOS Installation Guide

**UEFI · LUKS2 · ext4 · systemd-boot · NVMe**

> All commands run as root. Prefix with `sudo -i` from the live environment to drop into a root shell.

---

## 1. Boot the Installer

Download the minimal ISO from [nixos.org/download](https://nixos.org/download) and write it to a USB drive:

```bash
dd if=nixos-minimal-*.iso of=/dev/sdX bs=4M status=progress conv=fsync
```

Boot the target machine from the USB. Select the UEFI entry in the firmware boot menu. If Secure Boot is enabled, disable it first — NixOS does not ship a signed shim by default.

Once the live environment is up, become root:

```bash
sudo -i
```

---

## 2. Networking

The installer brings up networking automatically via DHCP. Verify connectivity:

```bash
ip a
ping -c2 nixos.org
```

For Wi-Fi, use `nmtui` to connect through NetworkManager.

---

## 3. Identify the Drive

```bash
lsblk
```

This guide assumes the target NVMe drive is `/dev/nvme0n1`. Adjust as needed. **All data on the drive will be destroyed.**

---

## 4. Partition the Disk

Create a GPT label, then two partitions: a 1 GiB EFI System Partition and the rest for the LUKS-encrypted root.

```bash
parted /dev/nvme0n1 -- mklabel gpt
parted /dev/nvme0n1 -- mkpart ESP fat32 1MiB 1025MiB
parted /dev/nvme0n1 -- set 1 esp on
parted /dev/nvme0n1 -- mkpart primary 1025MiB 100%
```

Verify the layout:

```bash
parted /dev/nvme0n1 -- print
```

You should see:
- `nvme0n1p1` — 1 GiB, fat32, flags: esp
- `nvme0n1p2` — remainder of disk

---

## 5. Set Up LUKS2 Encryption

Encrypt the root partition. You will be prompted to set and confirm a passphrase.

```bash
cryptsetup luksFormat --type luks2 /dev/nvme0n1p2
```

Open the encrypted device and map it to `cryptroot`:

```bash
cryptsetup open /dev/nvme0n1p2 cryptroot
```

The unlocked device is now available at `/dev/mapper/cryptroot`.

---

## 6. Format the Partitions

Format the EFI partition:

```bash
mkfs.fat -F 32 -n BOOT /dev/nvme0n1p1
```

Format the root partition as ext4:

```bash
mkfs.ext4 -L nixos /dev/mapper/cryptroot
```

---

## 7. Mount the File Systems

```bash
mount /dev/mapper/cryptroot /mnt
mkdir -p /mnt/boot
mount /dev/nvme0n1p1 /mnt/boot
```

---

## 8. Generate the Base Configuration

```bash
nixos-generate-config --root /mnt
```

This creates two files:

- `/mnt/etc/nixos/configuration.nix` — the main system configuration
- `/mnt/etc/nixos/hardware-configuration.nix` — auto-detected hardware, filesystems, and the LUKS device

---

## 9. Edit the Configuration

Open the configuration file:

```bash
nano /mnt/etc/nixos/configuration.nix
```

Below is a minimal configuration matching the assumptions of this guide. Replace placeholder values (`yourhostname`, `youruser`, etc.) with your own.

```nix
{ config, pkgs, ... }:

{
  imports = [ ./hardware-configuration.nix ];

  # Bootloader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # LUKS device — hardware-configuration.nix should have generated this,
  # but verify it matches your setup.
  boot.initrd.luks.devices."cryptroot" = {
    device = "/dev/disk/by-partlabel/primary";
    preLVM = true;
  };

  # Networking
  networking.hostName = "yourhostname";
  networking.networkmanager.enable = true;

  # Locale and time
  time.timeZone = "Europe/Rome"; # adjust to your timezone
  i18n.defaultLocale = "en_US.UTF-8";

  # User account — set a password after first boot with `passwd youruser`
  users.users.youruser = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" ];
  };

  # Allow sudo for the wheel group
  security.sudo.wheelNeedsPassword = true;

  # System packages
  environment.systemPackages = with pkgs; [
    git
    vim
    curl
    wget
  ];

  # Enable SSH (optional but handy)
  # services.openssh.enable = true;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database schema,
  # were chosen. Don't change it after the initial install.
  system.stateVersion = "25.11"; # match the NixOS version you installed
}
```

> **Note on `boot.initrd.luks.devices`:** `nixos-generate-config` usually populates this automatically in `hardware-configuration.nix` using the UUID of `nvme0n1p2`. Check that file and remove the duplicate entry from `configuration.nix` if it is already there.

---

## 10. Install NixOS

```bash
nixos-install
```

The installer will ask you to set a root password at the end. You can set your user password after first boot with `passwd youruser`.

Once it completes:

```bash
reboot
```

Remove the USB drive when the machine restarts.

---

## 11. First Boot

The firmware will hand off to systemd-boot. You will be prompted for the LUKS passphrase before the system continues booting.

Log in as root or your user, then set the user password if you haven't already:

```bash
passwd youruser
```

---

## 12. Post-Install Workflow

Making changes to the system follows a consistent pattern:

1. Edit `/etc/nixos/configuration.nix`.
2. Apply the changes:

```bash
sudo nixos-rebuild switch
```

To update the system to the latest packages on the current channel:

```bash
sudo nix-channel --update
sudo nixos-rebuild switch
```

---

## Reference: Partition Summary

| Partition       | Size      | Type       | Label  | Mount Point |
|-----------------|-----------|------------|--------|-------------|
| `/dev/nvme0n1p1` | 1 GiB    | FAT32 ESP  | BOOT   | `/boot`     |
| `/dev/nvme0n1p2` | remainder | LUKS2      | —      | (unlocks to `/dev/mapper/cryptroot` → `/`) |

---

## Troubleshooting

**systemd-boot not found after reboot** — Verify the EFI partition is mounted at `/boot` (not `/boot/efi`) and that `canTouchEfiVariables` is `true`. Check UEFI firmware boot order.

**Wrong LUKS device path** — Check `hardware-configuration.nix` and ensure the `device` field points to the correct partition by UUID (`/dev/disk/by-uuid/...`) or by-label. UUID is more reliable than `/dev/nvme0n1p2` across reboots.

**nixos-install fails to download** — Check network connectivity inside the installer. Run `ping 8.8.8.8` and verify DNS resolution.
