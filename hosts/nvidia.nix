{ config, pkgs, lib, ... }:

{
  # imports = [ ./hardware-configuration.nix ];

  # ── NVIDIA GPU ───────────────────────────────────────────────────────────────
  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.nvidia = {
    # Alternatives:
    #   config.boot.kernelPackages.nvidiaPackages.beta
    #   config.boot.kernelPackages.nvidiaPackages.open  (open kernel module, Turing+)
    package            = config.boot.kernelPackages.nvidiaPackages.open;
    modesetting.enable = true;
    open               = true;        # set true for Turing+ if you prefer the open module
    nvidiaSettings     = true;
    powerManagement.enable = true;    # enable on laptops
  };

  hardware.graphics = {
    enable      = true;
    enable32Bit = true;
    extraPackages = with pkgs; [ nvidia-vaapi-driver ];
  };

  # ── Wayland / KDE env vars ────────────────────────────────────────────────────
  environment.variables = {
    GBM_BACKEND               = "nvidia-drm";
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
    LIBVA_DRIVER_NAME         = "nvidia";   # VA-API via nvidia-vaapi-driver
  };

  boot.kernelParams = [
    "nvidia-drm.modeset=1"
    "nvidia-drm.fbdev=1"   # required by some Wayland compositors
  ];

  # ── CPU microcode ─────────────────────────────────────────────────────────────
  # Switch to hardware.cpu.amd.updateMicrocode if your NVIDIA box has an AMD CPU
  hardware.cpu.intel.updateMicrocode = true;
}
