# NixOS Configuration

Flake-based NixOS config with Fish shell, KDE Plasma 6, and devshells for Go and Rust development.

## First-time setup

```
# 1. Clone
git clone git@github.com:n70n10/my-nix.git
cd my-nix

# 2. Deploy to /etc/nixos
./deploy

# 3. Fill in your personal data
$EDITOR /etc/nixos/nixsec/secrets.nix

# 4. Generate hardware config (if not present)
nixos-generate-config --show-hardware-config | sudo tee /etc/nixos/nixsec/hardware-configuration.nix > /dev/null

# 5. Build, switch, and activate Home Manager (may need #<hostmane> the 1st time)
sudo nixos-rebuild switch --flake /etc/nixos
```

## File structure

```
.
├── flake.nix                          # Entrypoint
├── home.nix                           # Home Manager config (dotfiles, git, fish)
├── home
│   ├── git.nix                        # Git config
│   └── linkfactory.nix                # Helper to create symlinks for dotfiles
├── hosts/
│   ├── common.nix                     # Shared config (Plasma, gaming, SSH…)
│   ├── amd.nix                        # AMD GPU + microcode
│   └── nvidia.nix                     # NVIDIA GPU + proprietary driver
├── nixsec/
│   ├── hardware-configuration.nix     # cp from /etc/nixos
│   └── secrets.nix                    # Full name, email, locale etc.
├── dotfiles/                          # Standard dotfiles, symlinked to ~/.config
│   ├── fish/
│   └── ...
├── devshells/
│   ├── go.nix                         # Go toolchain + tools
│   └── rust.nix                       # Rust via rustup + tools
├── deploy.sh                          # Syncs repo → /etc/nixos
└── .gitignore

```

## secrets.nix

Each machine has its own `secrets.nix` — the `hostname` and `gpu` fields tell
the flake which host file to load, so no machine names appear in the repo.
Git identity (`fullName`, `email`) is read from here by Home Manager, so no
separate `gitconfig` file is needed.

```nix
{
  username = "your-username";
  fullName = "Your Full Name";
  email    = "your@email.com";

  # Locale / timezone — find yours with `timedatectl list-timezones`
  timezone  = "Europe/Rome";
  locale    = "en_US.UTF-8";

  # Extra locale overrides — remove keys you don't need, or set to {}
  extraLocale = {};

  # Keyboard — run `localectl list-keymaps` for console maps,
  # `localectl list-x11-keymap-layouts` for X11/Wayland layouts
  keyboardLayout  = "us";
  keyboardVariant = "";

  # Machine identity — keep this out of the repo
  hostname = "my-hostname";   # used for networking.hostName
  gpu      = "amd";           # host file to load: amd or nvidia

  # SSH public key for authorized_keys
  sshPublicKey = "ssh-ed25519 AAAA... your-key-comment";
}
```

## Dotfiles

Dotfiles are managed declaratively by Home Manager via `home.nix` — no manual
symlinking. Git identity is sourced from `secrets.nix`.
`nixos-rebuild switch` activates Home Manager and lays down all symlinks atomically.

## Devshells

```
nix develop .#go      # Go environment
nix develop .#rust    # Rust environment
```

Or use direnv — drop a `.envrc` in your project:

```
use flake /etc/nixos#go
```

## Fish aliases & functions

### Aliases

**Navigation**
| Alias | Does |
| --- | --- |
| `..` / `...` / `....` | cd up 1 / 2 / 3 levels |

**LS / Eza**
| Alias | Does |
| --- | --- |
| `ls` | `eza` with icons, directories first |
| `ll` | `eza -la` with icons and git status |
| `lt` | tree view 2 levels with icons |
| `lta` | tree view 2 levels with icons, including hidden files |
| `tree` | `eza` tree, all files, excluding `.git` |

**Modern replacements**
| Alias | Does |
| --- | --- |
| `cat` | `bat` with syntax highlighting |
| `grep` | `ripgrep` (rg) |
| `find` | `fd` |
| `top` | `btop` |
| `df` | `duf` |
| `du` | `gdu` |

**Editors**
| Alias | Does |
| --- | --- |
| `mi` | `micro` |
| `vi` / `vim` | `nvim` |
| `sv` | `sudo nvim` |

**Git**
| Alias | Does |
| --- | --- |
| `g` | `git` |
| `gs` | `git status` |
| `ga` | `git add` |
| `gaa` | `git add -A` |
| `gc` | `git commit` |
| `gcm` | `git commit -m` |
| `gca` | `git commit --amend` |
| `gco` | `git checkout` |
| `gcob` | `git checkout -b` |
| `gpl` | `git pull` |
| `gps` | `git push` |
| `gpsu` | `git push --set-upstream origin (git branch --show-current)` |
| `gl` | `git log --oneline --graph --decorate` |
| `gd` | `git diff` |
| `gds` | `git diff --staged` |
| `grb` | `git rebase` |
| `gst` | `git stash` |
| `gstp` | `git stash pop` |
| `lg` | `lazygit` |

**Go**
| Alias | Does |
| --- | --- |
| `gob` | `go build ./...` |
| `got` | `go test ./...` |
| `gotr` | `go test -race ./...` |
| `gotv` | `go test -v ./...` |
| `gom` | `go mod tidy` |
| `gor` | `go run .` |
| `gogen` | `go generate ./...` |

**Cargo / Rust**
| Alias | Does |
| --- | --- |
| `cb` | `cargo build` |
| `cr` | `cargo run` |
| `ct` | `cargo test` |
| `cta` | `cargo test -- --include-ignored` |
| `cc` | `cargo check` |
| `ccl` | `cargo clippy` |
| `cft` | `cargo fmt` |
| `cw` | `cargo watch` |

**Misc**
| Alias | Does |
| --- | --- |
| `ports` | `ss -tulnp` — show listening ports |
| `myip` | `curl -s https://ifconfig.me` — show external IP |
| `reload` | `exec fish` — restart fish session |

### Functions

**NixOS rebuild helpers**
| Function | Does |
| --- | --- |
| `nrs [path] [host]` | `nixos-rebuild switch` — defaults to `/etc/nixos` and current hostname |
| `nrt [path] [host]` | `nixos-rebuild test` |
| `nrb [path] [host]` | `nixos-rebuild boot` |
| `nup [path] [host]` | `nix flake update` + rebuild switch (runs in flake directory) |
| `nfu [path]` | `nix flake update` |
| `nfc [path]` | `nix flake check` |
| `nrollback` | roll back to previous generation |
| `ngens` | list system generations |
| `ndiff` | diff current system vs what the next rebuild would produce |
| `nsh <pkg>` | ephemeral `nix shell nixpkgs#<pkg>` |
| `dev [name]` | `nix develop [.#name]` — without args runs default devshell |
| `ngc <age>` | delete generations older than `<age>` (e.g., `7d`, `30d`) and garbage collect |

**Filesystem helpers**
| Function | Does |
| --- | --- |
| `mkcd <dir>` | `mkdir -p` + `cd` in one step |
| `fcd` | fuzzy `cd` into any subdirectory using `fzf` |
| `fe` | fuzzy open a file in `$EDITOR` using `fzf` |
| `bak <file>` | copy `<file>` to `<file>.bak` |
| `ex <archive>` | extract any archive (tar, zip, 7z, zst, gz, bz2…) |

**Git**
| Function | Does |
| `gsquash <N> [msg]` | squash last N commits into a single commit; uses combined messages or custom message if provided |

**Misc**
| Function | Does |
| --- | --- |
| `every <s> <cmd>` | repeat `<cmd>` every `<s>` seconds |
| `pr` | push current branch + `gh pr create --fill` |
| `paths` | print `$PATH` one entry per line |

## Notes

* **NVIDIA CPU microcode**: `nvidia.nix` assumes Intel.
  Swap to `hardware.cpu.amd.updateMicrocode` if your NVIDIA machine has an AMD CPU.
* **hardware-configuration.nix**: safe to commit if you don't mind disk UUIDs
  being public. Remove from `.gitignore` and `git add` it explicitly.
* **Rust toolchain**: managed by `rustup` inside the devshell for easy target/channel
  switching. If you prefer a fully declarative approach, replace with `rust-overlay`.
* **Flatpak**: add Flathub once after install:
  `flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo`
* **Tide prompt**: run `tide configure` once after install — settings persist
  in `~/.config/fish/fish_variables` and survive rebuilds.
