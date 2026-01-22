# Shell Aliases and Functions
# Common shortcuts for development workflow

# ────────────────────────────────────
# Navigation
# ────────────────────────────────────
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias ~='cd ~'
alias projects='cd ~/projects'
alias tools='cd ~/tools'

# ────────────────────────────────────
# Directory Listing
# ────────────────────────────────────
# Use eza if available, fallback to ls
if command -v eza &> /dev/null; then
    alias ls='eza --icons'
    alias ll='eza -la --icons --git'
    alias la='eza -a --icons'
    alias lt='eza --tree --level=2 --icons'
    alias lta='eza --tree --level=2 -a --icons'
else
    alias ll='ls -lah'
    alias la='ls -A'
fi

# ────────────────────────────────────
# File Operations
# ────────────────────────────────────
alias cp='cp -iv'
alias mv='mv -iv'
alias rm='rm -iv'
alias mkdir='mkdir -pv'

# Use bat for cat if available
if command -v bat &> /dev/null; then
    alias cat='bat --paging=never'
    alias catp='bat'
elif command -v batcat &> /dev/null; then
    alias cat='batcat --paging=never'
    alias catp='batcat'
fi

# ────────────────────────────────────
# Git Shortcuts
# ────────────────────────────────────
alias g='git'
alias gs='git status'
alias ga='git add'
alias gaa='git add -A'
alias gc='git commit'
alias gcm='git commit -m'
alias gp='git push'
alias gpl='git pull'
alias gf='git fetch'
alias gco='git checkout'
alias gcob='git checkout -b'
alias gb='git branch'
alias gba='git branch -a'
alias gl='git log --oneline -20'
alias glog='git log --graph --oneline --decorate'
alias gd='git diff'
alias gds='git diff --staged'
alias gst='git stash'
alias gstp='git stash pop'

# ────────────────────────────────────
# Docker Shortcuts
# ────────────────────────────────────
alias d='docker'
alias dc='docker compose'
alias dps='docker ps'
alias dpsa='docker ps -a'
alias di='docker images'
alias dex='docker exec -it'
alias dlogs='docker logs -f'
alias dprune='docker system prune -af'

# ────────────────────────────────────
# Development
# ────────────────────────────────────
alias py='python'
alias py3='python3'
alias pip='pip3'
alias venv='python -m venv'
alias activate='source venv/bin/activate'

alias nr='npm run'
alias ni='npm install'
alias nid='npm install --save-dev'

# ────────────────────────────────────
# System
# ────────────────────────────────────
alias h='history'
alias hg='history | grep'
alias ports='netstat -tuln'
alias myip='curl -s ifconfig.me'
alias reload='source ~/.bashrc'
alias path='echo $PATH | tr ":" "\n"'

# ────────────────────────────────────
# Search
# ────────────────────────────────────
# Use ripgrep if available
if command -v rg &> /dev/null; then
    alias grep='rg'
fi

# Use fd if available
if command -v fd &> /dev/null; then
    alias find='fd'
elif command -v fdfind &> /dev/null; then
    alias find='fdfind'
fi

# ────────────────────────────────────
# Helpful Functions
# ────────────────────────────────────

# Create directory and cd into it
mkcd() {
    mkdir -p "$1" && cd "$1"
}

# Extract various archive formats
extract() {
    if [[ -f "$1" ]]; then
        case "$1" in
            *.tar.bz2)   tar xjf "$1"    ;;
            *.tar.gz)    tar xzf "$1"    ;;
            *.tar.xz)    tar xJf "$1"    ;;
            *.bz2)       bunzip2 "$1"    ;;
            *.gz)        gunzip "$1"     ;;
            *.tar)       tar xf "$1"     ;;
            *.tbz2)      tar xjf "$1"    ;;
            *.tgz)       tar xzf "$1"    ;;
            *.zip)       unzip "$1"      ;;
            *.Z)         uncompress "$1" ;;
            *.7z)        7z x "$1"       ;;
            *.rar)       unrar x "$1"    ;;
            *)           echo "Cannot extract '$1'" ;;
        esac
    else
        echo "'$1' is not a valid file"
    fi
}

# Quick HTTP server in current directory
serve() {
    local port="${1:-8000}"
    python -m http.server "$port"
}

# Git clone and cd into directory
gclone() {
    git clone "$1" && cd "$(basename "$1" .git)"
}

# Find process by name
psgrep() {
    ps aux | grep -v grep | grep -i "$1"
}
