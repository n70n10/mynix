## ~/.config/fish/conf.d/functions.fish

# ── NixOS rebuild helpers ─────────────────────────────────────────────────────

function nrs --description 'nixos-rebuild switch'
    set -l path (test -n "$argv[1]"; and echo "$argv[1]"; or echo "/etc/nixos")
    set -l host (test -n "$argv[2]"; and echo "$argv[2]"; or echo (hostname))

    echo "🔄 Switching to new system configuration..."
    echo "📁 Path: $path"
    echo "🖥️  Host: $host"

    sudo nixos-rebuild switch --flake $path#$host $argv[3..]

    if test $status -eq 0
        echo "✅ System switched successfully!"
    else
        echo "❌ System switch failed!"
    end
end

function nrt --description 'nixos-rebuild test'
    set -l path (test -n "$argv[1]"; and echo "$argv[1]"; or echo "/etc/nixos")
    set -l host (test -n "$argv[2]"; and echo "$argv[2]"; or echo (hostname))

    echo "🧪 Testing new system configuration..."
    echo "📁 Path: $path"
    echo "🖥️  Host: $host"

    sudo nixos-rebuild test --flake $path#$host $argv[3..]

    if test $status -eq 0
        echo "✅ System test successful! Run 'nrs' to make permanent."
    else
        echo "❌ System test failed!"
    end
end

function nrb --description 'nixos-rebuild boot'
    set -l path (test -n "$argv[1]"; and echo "$argv[1]"; or echo "/etc/nixos")
    set -l host (test -n "$argv[2]"; and echo "$argv[2]"; or echo (hostname))

    echo "💾 Building system configuration for next boot..."
    echo "📁 Path: $path"
    echo "🖥️  Host: $host"

    sudo nixos-rebuild boot --flake $path#$host $argv[3..]

    if test $status -eq 0
        echo "✅ System built successfully! Reboot to apply changes."
    else
        echo "❌ System build failed!"
    end
end

function nup --description 'flake update + rebuild switch'
    set -l path (test -n "$argv[1]"; and echo "$argv[1]"; or echo "/etc/nixos")
    set -l host (test -n "$argv[2]"; and echo "$argv[2]"; or echo (hostname))

    if not test -d "$path"
        echo "❌ Error: Directory '$path' does not exist"
        return 1
    end

    echo "📦 Updating flake inputs..."
    pushd $path

    sudo nix flake update

    if test $status -ne 0
        echo "❌ Flake update failed!"
        popd
        return 1
    end

    echo "🔄 Rebuilding system with updated inputs..."
    sudo nixos-rebuild switch --flake .#$host $argv[3..]

    popd

    if test $status -eq 0
        echo "✅ System updated and switched successfully!"
    else
        echo "❌ System rebuild failed!"
    end
end

function nfu --description 'nix flake update'
    set -l path (test -n "$argv[1]"; and echo "$argv[1]"; or echo "/etc/nixos")

    echo "📦 Updating flake inputs in: $path"
    sudo nix flake update --flake $path $argv[2..]

    if test $status -eq 0
        echo "✅ Flake inputs updated successfully!"
    else
        echo "❌ Flake update failed!"
    end
end

function nfc --description 'nix flake check'
    set -l path (test -n "$argv[1]"; and echo "$argv[1]"; or echo "/etc/nixos")

    echo "🔍 Checking flake integrity..."
    sudo nix flake check $path $argv[2..]

    if test $status -eq 0
        echo "✅ Flake check passed!"
    else
        echo "❌ Flake check failed!"
    end
end

function nrollback --description 'roll back to previous generation'
    echo "⏪ Rolling back to previous system generation..."
    sudo nixos-rebuild switch --rollback

    if test $status -eq 0
        echo "✅ Rollback successful! Previous generation is now active."
    else
        echo "❌ Rollback failed!"
    end
end

function ngens --description 'list system generations'
    echo "📋 Listing system generations:"
    echo "─────────────────────────────────"
    sudo nix-env --list-generations --profile /nix/var/nix/profiles/system
end

function ndiff --description 'diff current system vs next rebuild'
    echo "🔍 Comparing current system with next build..."
    set -l next (nix build /etc/nixos#nixosConfigurations.default.config.system.build.toplevel \
        --no-link --print-out-paths 2>/dev/null)

    if test -z "$next"
        echo "❌ Failed to build next system configuration"
        return 1
    end

    nvd diff /run/current-system $next
end

function nsh --description 'ephemeral nix shell: nsh <pkg>'
    if test -z "$argv[1]"
        echo "❌ Usage: nsh <package> [additional packages...]"
        echo "Example: nsh hello"
        echo "Example: nsh python3 curl"
        return 1
    end

    echo "📦 Entering ephemeral shell with: $argv"
    nix shell nixpkgs#$argv[1] $argv[2..]
end

function dev --description 'nix develop [.#name]'
    if test (count $argv) -eq 0
        echo "🔧 Entering default devshell..."
        nix develop
    else
        echo "🔧 Entering devshell: .#$argv[1]"
        nix develop .#$argv[1]
    end
end

function ngc --description "Delete system generations older than specified age and clean bootloader"
    if test -z "$argv[1]"
        echo "❌ Usage: ngc <age>"
        echo "📖 Examples: ngc 7d, ngc 30d, ngc 2w"
        return 1
    end

    set -l age $argv[1]

    # Validate age format
    if not string match -r '^\d+[dhw]|^\d{4}-\d{2}-\d{2}$' $age
        echo "❌ Error: Invalid age format '$age'"
        echo "📖 Use formats like: 7d, 12h, 2w, or 2024-01-15"
        return 1
    end

    echo "🗑️  Cleaning up generations older than $age..."

    # ── Nix profile cleanup ────────────────────────────────────────────

    echo "📁 Wiping system profile history..."
    sudo nix profile wipe-history --profile /nix/var/nix/profiles/system --older-than $age

    # Home-manager cleanup
    if test -d ~/.local/state/nix/profiles/home-manager
        echo "🏠 Wiping home-manager profile history..."
        nix profile wipe-history --profile ~/.local/state/nix/profiles/home-manager --older-than $age
    end

    echo "👤 Wiping user profile history..."
    nix profile wipe-history --older-than $age

    # ── Bootloader cleanup ─────────────────────────────────────────────

    echo "🖥️  Cleaning bootloader entries..."

    # Detect which bootloader is being used
    if test -d /boot/loader/entries
        echo "🔧 Detected systemd-boot"

        # Get actual generation numbers from nix profile (skip header line)
        set -l keep_gens (sudo nix-env --list-generations --profile /nix/var/nix/profiles/system | tail -n +2 | awk '{print $1}')

        echo "📌 Keeping boot entries for generations: $keep_gens"

        # Get boot entry files and extract generation numbers (unique)
        set -l boot_files /boot/loader/entries/nixos-generation-*.conf
        set -l removed_count 0

        for file in $boot_files
            if test -f "$file"
                # Extract generation number from filename
                set gen (echo $file | string replace -r '.*nixos-generation-([0-9]+)\.conf' '$1')

                # Check if this generation should be kept
                if not contains $gen $keep_gens
                    echo "🗑️  Removing boot entry for generation $gen"
                    sudo rm -f "$file"
                    set removed_count (math $removed_count + 1)
                end
            end
        end

        echo "✅ Removed $removed_count boot entries"

        # Regenerate bootloader configuration
        echo "🔄 Regenerating bootloader configuration..."
        set -l path (test -n "$argv[2]"; and echo "$argv[2]"; or echo "/etc/nixos")
        set -l host (test -n "$argv[3]"; and echo "$argv[3]"; or echo (hostname))

        sudo nixos-rebuild boot --flake $path#$host > /dev/null 2>&1

        echo "✅ Bootloader configuration regenerated"

    else if test -f /boot/grub/grub.cfg
        echo "🔧 Detected GRUB bootloader"
        set -l path (test -n "$argv[2]"; and echo "$argv[2]"; or echo "/etc/nixos")
        set -l host (test -n "$argv[3]"; and echo "$argv[3]"; or echo (hostname))
        sudo nixos-rebuild boot --flake $path#$host > /dev/null 2>&1
        echo "✅ GRUB configuration regenerated"
    else
        echo "⚠️  Could not detect bootloader type, skipping bootloader cleanup"
    end

    # ── Garbage collection ────────────────────────────────────────────

    echo "🧹 Running garbage collection as root..."
    sudo nix-collect-garbage --delete-old

    echo "🧹 Running garbage collection as user..."
    nix-collect-garbage --delete-old

    echo "✅ Done!"

    # Show summary
    echo ""
    echo "📊 Summary:"
    echo "  • System profiles cleaned for age: $age"

    if test -d /boot/loader/entries
        set remaining (ls /boot/loader/entries/nixos-generation-*.conf 2>/dev/null | wc -l)
        echo "  • Remaining boot entries: $remaining"
    end

    echo "  • Disk usage on /nix/store:"
    df -h /nix/store | tail -1 | awk '{print "    " $3 " used / " $4 " available (" $5 ")"}'
end

# ── Filesystem helpers ────────────────────────────────────────────────────────

function mkcd --description 'mkdir -p + cd'
    if test -z "$argv[1]"
        echo "❌ Usage: mkcd <directory>"
        return 1
    end

    echo "📁 Creating directory: $argv[1]"
    mkdir -p $argv[1] && cd $argv[1]

    if test $status -eq 0
        echo "✅ Now in: "(pwd)
    else
        echo "❌ Failed to create directory"
    end
end

function fcd --description 'fuzzy cd into subdirectory'
    echo "🔍 Searching for directories..."
    set -l dir (find . -type d 2>/dev/null | fzf +m)

    if test -n "$dir"
        echo "📁 Changing to: $dir"
        cd $dir
        echo "✅ Now in: "(pwd)
    else
        echo "❌ No directory selected"
        return 1
    end
end

function fe --description 'fuzzy open file in $EDITOR'
    if test -z "$EDITOR"
        echo "⚠️  Warning: \$EDITOR not set, using 'vim'"
        set -l EDITOR vim
    end

    echo "🔍 Searching for files..."
    set -l file (fzf +m)

    if test -n "$file"
        echo "✏️  Opening: $file"
        $EDITOR $file
    else
        echo "❌ No file selected"
        return 1
    end
end

function bak --description 'copy <file> to <file>.bak'
    if test -z "$argv[1]"
        echo "❌ Usage: bak <filename>"
        return 1
    end

    if not test -f "$argv[1]"
        echo "❌ Error: '$argv[1]' is not a valid file"
        return 1
    end

    echo "💾 Creating backup: $argv[1].bak"
    cp $argv[1] $argv[1].bak

    if test $status -eq 0
        echo "✅ Backup created successfully"
    else
        echo "❌ Backup failed"
    end
end

function ex --description 'extract any archive'
    if test -z "$argv[1]"
        echo "❌ Usage: ex <archive-file>"
        return 1
    end

    if not test -f $argv[1]
        echo "❌ Error: '$argv[1]' is not a valid file"
        return 1
    end

    echo "📦 Extracting: $argv[1]"

    switch $argv[1]
        case '*.tar.bz2'
            tar xjf $argv[1]
        case '*.tar.gz'
            tar xzf $argv[1]
        case '*.tar.xz'
            tar xJf $argv[1]
        case '*.tar.zst'
            tar --zstd -xf $argv[1]
        case '*.bz2'
            bunzip2 $argv[1]
        case '*.gz'
            gunzip $argv[1]
        case '*.tar'
            tar xf $argv[1]
        case '*.tbz2'
            tar xjf $argv[1]
        case '*.tgz'
            tar xzf $argv[1]
        case '*.zip'
            unzip $argv[1]
        case '*.7z'
            7z x $argv[1]
        case '*.zst'
            zstd -d $argv[1]
        case '*'
            echo "❌ Error: '$argv[1]' cannot be extracted (unknown format)"
            return 1
    end

    if test $status -eq 0
        echo "✅ Extraction complete!"
    else
        echo "❌ Extraction failed!"
    end
end

# ── Git ──────────────────────────────────────────────────────────────────────

function gsquash --description 'squash last N commits'
    if test -z "$argv[1]"
        echo "❌ Usage: gsquash <N> [commit-message]"
        echo "📖 Examples:"
        echo "   gsquash 3                    # Squash last 3 commits, edit message"
        echo "   gsquash 3 'Fix all bugs'     # Squash with custom message"
        return 1
    end

    if not string match -r '^\d+$' $argv[1]
        echo "❌ Error: N must be a number"
        return 1
    end

    echo "📦 Squashing last $argv[1] commit(s)..."
    git reset --soft "HEAD~$argv[1]"

    if test $status -ne 0
        echo "❌ Failed to reset commits"
        return 1
    end

    if test -n "$argv[2]"
        echo "💾 Committing with message: $argv[2]"
        git commit -m "$argv[2]"
    else
        echo "✏️  Please enter commit message..."
        git commit
    end

    if test $status -eq 0
        echo "✅ Squash successful!"
    else
        echo "❌ Squash failed!"
    end
end

# ── Misc ──────────────────────────────────────────────────────────────────────

function every --description 'repeat <cmd> every <s> seconds'
    if test -z "$argv[1]" -o -z "$argv[2]"
        echo "❌ Usage: every <seconds> <command>"
        echo "📖 Example: every 5 'date'"
        echo "📖 Example: every 10 'ls -la'"
        return 1
    end

    if not string match -r '^\d+$' $argv[1]
        echo "❌ Error: Interval must be a number (seconds)"
        return 1
    end

    set -l interval $argv[1]
    set -l cmd $argv[2..]

    echo "⏰ Running '$cmd' every $interval seconds..."
    echo "⚠️  Press Ctrl+C to stop"
    echo ""

    while true
        eval $cmd
        sleep $interval
    end
end

function pr --description 'push branch + gh pr create --fill'
    set -l current_branch (git branch --show-current)

    if test -z "$current_branch"
        echo "❌ Not in a git repository or no branch checked out"
        return 1
    end

    echo "📤 Pushing branch: $current_branch"
    git push --set-upstream origin $current_branch

    if test $status -ne 0
        echo "❌ Push failed!"
        return 1
    end

    echo "🔀 Creating pull request..."
    gh pr create --fill

    if test $status -eq 0
        echo "✅ Pull request created successfully!"
    else
        echo "❌ Pull request creation failed!"
    end
end

function paths --description 'print $PATH one entry per line'
    echo "📋 Current PATH entries:"
    echo "─────────────────────────"
    string split : $PATH | while read -l line
        if test -n "$line"
            echo "  $line"
        end
    end
end
