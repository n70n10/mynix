{ config, pkgs, lib, ... }:

{
  # ── AMD GPU ──────────────────────────────────────────────────────────────────
  hardware.graphics = {
    enable      = true;
    enable32Bit = true;
  };

  # Unlock all power-play features (fan curves, overclocking headroom, etc.)
  boot.kernelParams = [ "amdgpu.ppfeaturemask=0xffffffff" ];

  # ── CPU microcode ─────────────────────────────────────────────────────────────
  hardware.cpu.amd.updateMicrocode = true;
}
