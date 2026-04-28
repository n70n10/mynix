{ pkgs, config, lib, secrets, ... }:

let
  symlinks = import ./linkfactory.nix { inherit config lib; };
  hd = config.home.homeDirectory;
in
{
  imports = [
    ./git.nix
  ];

  # ── Ghostty terminal ──────────────────────────────────────────────────────
  programs.ghostty.enable = true;

  # ── Fish ──────────────────────────────────────────────────────────────────
  programs.fish = {
    enable = true;
    plugins = [
      { name = "tide";     src = pkgs.fishPlugins.tide.src; }
      { name = "fzf-fish"; src = pkgs.fishPlugins.fzf-fish.src; }
      { name = "autopair"; src = pkgs.fishPlugins.autopair.src; }
      { name = "done";     src = pkgs.fishPlugins.done.src; }
    ];
    interactiveShellInit = ''
      set -g fish_greeting ""
    '';
  };

  home = {
    username      = secrets.username;
    homeDirectory = "/home/${secrets.username}";
    stateVersion  = "25.11";

    packages = with pkgs; [
      # Editors
      micro neovim

      # CLI tools
      bat eza fzf ripgrep fd btop duf

      # Dev tools
      gh lazygit delta

      # Utilities
      fastfetch tokei hyperfine nvd
    ];

    activation = symlinks [
      { source = "${hd}/my-nix/dotfiles/fish/conf.d/main.fish";
        target = "${hd}/.config/fish/conf.d/main.fish"; }
      { source = "${hd}/my-nix/dotfiles/fish/conf.d/functions.fish";
        target = "${hd}/.config/fish/conf.d/functions.fish"; }

      { source = "${hd}/my-nix/dotfiles/micro/settings.json";
        target = "${hd}/.config/micro/settings.json"; }
      { source = "${hd}/my-nix/dotfiles/micro/bindings.json";
        target = "${hd}/.config/micro/bindings.json"; }
      { source = "${hd}/my-nix/dotfiles/micro/colorschemes/rose-pine.micro";
        target = "${hd}/.config/micro/colorschemes/rose-pine.micro"; }

      { source = "${hd}/my-nix/dotfiles/nvim"; target = "${hd}/.config/nvim"; }

      { source = "${hd}/my-nix/dotfiles/ghostty"; target = "${hd}/.config/ghostty"; }

];

    sessionPath = [ "$HOME/.local/bin" ];
  };

  services.home-manager.autoExpire = {
    enable = true;
    store.cleanup = true; # Runs nix-collect-garbage automatically
  };

  programs.home-manager.enable = true;
}
