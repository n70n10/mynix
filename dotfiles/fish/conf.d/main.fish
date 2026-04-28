## ~/.config/fish/config.fish

set -g fish_greeting ""

# ── Aliases ───────────────────────────────────────────────────────────────────

# navigation
abbr -a -- ..   'cd ..'
abbr -a -- ...  'cd ../..'
abbr -a -- .... 'cd ../../..'

# ls → eza
abbr -a ls   'eza --icons --group-directories-first'
abbr -a ll   'eza -la --icons --group-directories-first --git'
abbr -a lt   'eza --tree --level=2 --icons'
abbr -a lta  'eza --tree --level=2 --icons -a'
abbr -a tree 'eza -TA -I ".git"'

# replacements
abbr -a cat  'bat'
abbr -a grep 'rg'
abbr -a find 'fd'
abbr -a top  'btop'
abbr -a df   'duf'
abbr -a du   'gdu'

# editors
abbr -a mi   'micro'
abbr -a vi   'nvim'
abbr -a vim  'nvim'
abbr -a sv   'sudo nvim'

# git
abbr -a g    'git'
abbr -a gs   'git status'
abbr -a ga   'git add'
abbr -a gaa  'git add -A'
abbr -a gc   'git commit'
abbr -a gcm  'git commit -m'
abbr -a gca  'git commit --amend'
abbr -a gco  'git checkout'
abbr -a gcob 'git checkout -b'
abbr -a gpl  'git pull'
abbr -a gps  'git push'
abbr -a gpsu 'git push --set-upstream origin (git branch --show-current)'
abbr -a gl   'git log --oneline --graph --decorate'
abbr -a gd   'git diff'
abbr -a gds  'git diff --staged'
abbr -a grb  'git rebase'
abbr -a gst  'git stash'
abbr -a gstp 'git stash pop'
abbr -a lg   'lazygit'

# go
abbr -a gob   'go build ./...'
abbr -a got   'go test ./...'
abbr -a gotr  'go test -race ./...'
abbr -a gotv  'go test -v ./...'
abbr -a gom   'go mod tidy'
abbr -a gor   'go run .'
abbr -a gogen 'go generate ./...'

# cargo
abbr -a cb  'cargo build'
abbr -a cr  'cargo run'
abbr -a ct  'cargo test'
abbr -a cta 'cargo test -- --include-ignored'
abbr -a cc  'cargo check'
abbr -a ccl 'cargo clippy'
abbr -a cft 'cargo fmt'
abbr -a cw  'cargo watch'

# misc
abbr -a ports  'ss -tulnp'
abbr -a myip   'curl -s https://ifconfig.me'
abbr -a reload 'exec fish'
