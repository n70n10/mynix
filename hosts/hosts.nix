{ config, pkgs, lib, secrets, hostname, ... }:

{
  # ── zswap ─────────────────────────────────────────────────────────────────
  boot.zswap = {
    enable         = true;
    compressor     = "zstd";
    maxPoolPercent = 20;
  };
  swapDevices = [ {
    device = "/var/lib/swapfile";
    size   = 16 * 1024; # 16GB
  } ];

  # ── Plymouth boot splash ──────────────────────────────────────────────────
  boot.plymouth = {
    enable = true;
    theme  = "bgrt";   # default KDE theme — change to any installed theme
  };

  # Silent boot — suppress kernel/systemd noise during splash
  boot.consoleLogLevel = 3;
  boot.initrd.verbose  = false;
  boot.kernelParams = [
    "quiet"
    "splash"
    "boot.shell_on_fail"
    "udev.log_priority=3"
    "rd.systemd.show_status=auto"
  ];

  # ── Bootloader ───────────────────────────────────────────────────────────────
  boot.loader = {
    systemd-boot.enable      = true;
    systemd-boot.consoleMode = "max";
    efi.canTouchEfiVariables = true;
  };

  # ── Networking ───────────────────────────────────────────────────────────────
  networking = {
    hostName              = hostname;
    networkmanager.enable = true;
  };

  # ── Locale & time ────────────────────────────────────────────────────────────
  time.timeZone = secrets.timezone;

  i18n = {
    defaultLocale       = secrets.locale;
    extraLocaleSettings = secrets.extraLocale or {};
  };

  # ── Keyboard ─────────────────────────────────────────────────────────────────
  # console keymap (TTY)
  console.keyMap = secrets.keyboardLayout;

  # X11/Wayland keymap — picked up by libxkbcommon, works with Plasma on Wayland
  services.xserver.xkb = {
    layout  = secrets.keyboardLayout;
    variant = secrets.keyboardVariant;
  };

  # ── User ─────────────────────────────────────────────────────────────────────
  users.users.${secrets.username} = {
    isNormalUser = true;
    description  = secrets.fullName;
    extraGroups  = [ "wheel" "networkmanager" "audio" "video" "input" "gamemode" ];
    shell        = pkgs.fish;
    openssh.authorizedKeys.keys = [ secrets.sshPublicKey ];
  };

  # ── Shell ────────────────────────────────────────────────────────────────────
  programs.fish.enable = true;

  # ── SSH ──────────────────────────────────────────────────────────────────────
  services.openssh = {
    enable   = true;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin        = "no";
    };
  };

  programs.ssh.startAgent = true;

  # ── Desktop: KDE Plasma 6 ────────────────────────────────────────────────────
  services.desktopManager.plasma6.enable = true;

  # Plasma Login Manager (unstable only — replaces SDDM on nixos-unstable)
  # Note: SDDM is no longer supported on nixos-unstable when using Plasma 6.
  services.displayManager.plasma-login-manager.enable = true;

  # ── Sound: PipeWire ──────────────────────────────────────────────────────────
  # Plasma 6 enables PipeWire automatically; these are explicit for clarity.
  services.pulseaudio.enable = false;
  security.rtkit.enable      = true;
  services.pipewire = {
    enable            = true;
    alsa.enable       = true;
    alsa.support32Bit = true;
    pulse.enable      = true;
    jack.enable       = true;
  };

  # Workaround for https://github.com/NixOS/nixpkgs/issues/432137
  # Qt can't find pipewire-0.3 at runtime — expose it via LD_LIBRARY_PATH
  environment.variables.LD_LIBRARY_PATH =
    lib.mkForce "${pkgs.pipewire}/lib:${pkgs.pipewire.jack}/lib";

  # ── Flatpak ───────────────────────────────────────────────────────────────
  services.flatpak.enable = true;
  # Add Flathub after install: flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

  # ── Applications ──────────────────────────────────────────────────────────
  programs.firefox.enable = true;
  programs.steam = {
    enable                         = true;
    remotePlay.openFirewall        = true;
    dedicatedServer.openFirewall   = true;
    # Pass gamemode into Steam's runtime
    extraCompatPackages            = [ pkgs.proton-ge-bin ];
  };

  programs.gamemode.enable = true;

  # ── Nix ──────────────────────────────────────────────────────────────────────
  nix = {
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      auto-optimise-store   = true;
      trusted-users         = [ "root" secrets.username ];
    };
    gc = {
      automatic = true;
      dates     = "weekly";
      options   = "--delete-older-than 14d";
    };
  };

  nixpkgs.config.allowUnfree = true;

  # ── System packages ──────────────────────────────────────────────────────────
  environment.systemPackages = with pkgs; [
    # Build tools needed system-wide
    gcc gnumake pkg-config

    # Hooks into PAM/systemd
    direnv nix-direnv

    # KDE extras
    kdePackages.kcalc
    kdePackages.ark
    kdePackages.partitionmanager
    kdePackages.filelight        # disk usage visualiser
    wl-clipboard

    # Gaming
    # lutris                     # this is pulling openldap with fails to build miserably
    # heroic                     # install lutris and heroic as flatpaks
    mangohud
    gamemode
  ];

  # direnv / nix-direnv for devshells
  programs.direnv = {
    enable            = true;
    nix-direnv.enable = true;
  };

  # ── Fonts ────────────────────────────────────────────────────────────────────
  fonts.packages = with pkgs; [
    adwaita-fonts
    nerd-fonts.jetbrains-mono
    nerd-fonts.fira-code
    noto-fonts
    noto-fonts-color-emoji
  ];

  system.stateVersion = "25.11";
}
