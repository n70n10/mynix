#!/usr/bin/env bash
set -euo pipefail

# Colours
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

DEST="/etc/nixos"
SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ── Nix config → /etc/nixos ──────────────────────────────────────────────────

TARGETS=(
    flake.nix
    flake.lock
    home/home.nix
    home/git.nix
    home/linkfactory.nix
    hosts/hosts.nix
    hosts/amd.nix
    hosts/nvidia.nix
    nixsec/hardware-configuration.nix
    nixsec/secrets.nix
    devshells/go.nix
    devshells/rust.nix
)

echo "Deploying NixOS config: $SRC → $DEST"
echo

for target in "${TARGETS[@]}"; do
    src_file="$SRC/$target"
    dst_file="$DEST/$target"

    # Skip if source doesn't exist
    if [[ ! -f "$src_file" ]]; then
        echo -e "  ${YELLOW}skip${NC}   $target (not found)"
        continue
    fi

    # If it's a nixsec file or flake.lock and it already exists at the destination, skip it
    if [[ "$target" == nixsec/* ]] || [[ "$target" == flake.lock ]] && [[ -f "$dst_file" ]]; then
        echo -e "  ${YELLOW}skip${NC}   $target (files exists)"
        continue
    fi

    # Create destination directory if needed
    dst_dir="$(dirname "$dst_file")"
    if [[ ! -d "$dst_dir" ]]; then
        sudo mkdir -p "$dst_dir"
    fi

    # Only copy if different
    if sudo diff -q "$src_file" "$dst_file" &>/dev/null; then
        echo -e "  ok     $target"
    else
        sudo cp "$src_file" "$dst_file"
        echo -e "  ${GREEN}copied${NC} $target"
    fi
done

echo
echo "Done. Run 'nrs' to rebuild (includes Home Manager activation)."
