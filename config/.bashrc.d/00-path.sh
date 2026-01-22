# PATH Configuration
# Loaded first to ensure paths are available for other modules

# Local bin directories
export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/bin:$PATH"

# NVM (Node Version Manager)
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# Pyenv (Python Version Manager)
export PYENV_ROOT="$HOME/.pyenv"
if [[ -d "$PYENV_ROOT/bin" ]]; then
    export PATH="$PYENV_ROOT/bin:$PATH"
    eval "$(pyenv init -)" 2>/dev/null || true
fi

# Rust/Cargo
if [[ -f "$HOME/.cargo/env" ]]; then
    . "$HOME/.cargo/env"
fi

# Go
if [[ -d "/usr/local/go/bin" ]]; then
    export PATH="$PATH:/usr/local/go/bin"
    export PATH="$PATH:$HOME/go/bin"
fi

# Ruby (rbenv)
if [[ -d "$HOME/.rbenv/bin" ]]; then
    export PATH="$HOME/.rbenv/bin:$PATH"
    eval "$(rbenv init -)" 2>/dev/null || true
fi

# FZF
if [[ -f ~/.fzf.bash ]]; then
    source ~/.fzf.bash
fi
