#!/bin/bash -e

# ===============================================
# SCRIPT METADATA AND INITIAL SETUP
# Non-interactive configuration setup script.
# User needs to log out/log back in to apply changes.
# ===============================================

ZSHRC_FILE="$HOME/.zshrc"
TMUX_CONF_FILE="$HOME/.tmux.conf"

echo "Starting non-interactive environment configuration script."
echo "================================================="
echo "Note: You will be prompted for your password for sudo commands."

# ===============================================
# CORE FUNCTIONS
# ===============================================

# Function to update package lists and install core utilities
install_core_packages() {
    echo "--- Package Installation ---"

    PACKAGES=(
        curl        # required for Oh My Zsh installer
        git
        zsh
        tmux
        btop
        bat
        lsd
        fzf
        zoxide
        neovim
        unzip       # required for Nerd Font extraction
        fontconfig  # required for fc-cache
    )

    sudo apt update
    sudo apt install -y "${PACKAGES[@]}"
    echo "✅ Core packages installed successfully."
}

# Function to install JetBrainsMono Nerd Font
install_nerd_font() {
    echo "--- Nerd Font Installation ---"

    local FONT_DIR="$HOME/.local/share/fonts/NerdFonts"
    mkdir -p "$FONT_DIR"

    if fc-list | grep -qi "JetBrainsMono Nerd Font"; then
        echo "JetBrainsMono Nerd Font already installed. Skipping."
        return
    fi

    echo "Downloading JetBrainsMono Nerd Font..."
    local TMP_ZIP
    TMP_ZIP=$(mktemp --suffix=.zip)
    curl -fsSL "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip" -o "$TMP_ZIP"
    unzip -q "$TMP_ZIP" -d "$FONT_DIR"
    rm -f "$TMP_ZIP"
    fc-cache -fv "$FONT_DIR" > /dev/null 2>&1
    echo "✅ JetBrainsMono Nerd Font installed."
}

# Function to install and configure Oh My Zsh and plugins
setup_zsh() {
    echo "--- Zsh & Oh My Zsh Setup ---"

    if [ ! -d "$HOME/.oh-my-zsh" ]; then
        echo "Installing Oh My Zsh..."
        RUNZSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
    else
        echo "Oh My Zsh already installed."
    fi

    # Install required plugins
    local HIGHLIGHT_DIR="$HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting"
    local AUTOSUGGEST_DIR="$HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions"

    [ ! -d "$HIGHLIGHT_DIR" ] && echo "Installing zsh-syntax-highlighting plugin..." && git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$HIGHLIGHT_DIR"
    [ ! -d "$AUTOSUGGEST_DIR" ] && echo "Installing zsh-autosuggestions plugin..." && git clone https://github.com/zsh-users/zsh-autosuggestions.git "$AUTOSUGGEST_DIR"

    echo "Configuring $ZSHRC_FILE..."

    if ! grep -q "zsh-syntax-highlighting" "$ZSHRC_FILE"; then
        sed -i 's/plugins=(/plugins=(zsh-syntax-highlighting zsh-autosuggestions /' "$ZSHRC_FILE"
    fi

    sed -i 's/ZSH_THEME=".*"/ZSH_THEME="lukerandall"/' "$ZSHRC_FILE"

    echo "✅ Zsh configuration updated."
}

# Function to configure Tmux Plugin Manager (TPM)
configure_tmux() {
    echo "--- Tmux Setup ---"

    TPM_DIR="$HOME/.tmux/plugins/tpm"
    if [ ! -d "$TPM_DIR" ]; then
        echo "Installing Tmux Plugin Manager (TPM)..."
        git clone https://github.com/tmux-plugins/tpm "$TPM_DIR"
    else
        echo "TPM already installed."
    fi

    echo "Creating $TMUX_CONF_FILE..."
    cat > "$TMUX_CONF_FILE" <<EOF
# ===============================================
# TMUX CONFIGURATION
# ===============================================

set -g @plugin 'tmux-plugins/tpm'
set -g @plugin 'tmux-plugins/tmux-sensible'
set -g @plugin 'arcticicestudio/nord-tmux'
set -g @plugin 'tmux-plugins/tmux-prefix-highlight'

set -g mouse on

run '${TPM_DIR}/tpm'
EOF

    echo "✅ Tmux configuration file created."
    echo "🚨 ACTION REQUIRED: Start tmux and press 'prefix + I' to install plugins."
}

# Function to configure Btop
configure_btop() {
    echo "--- Btop Setup ---"

    local BTOP_CONF_DIR="$HOME/.config/btop"
    local BTOP_CONF_FILE="$BTOP_CONF_DIR/btop.conf"

    mkdir -p "$BTOP_CONF_DIR"

    # Use the built-in Default theme; flat-remix path is not bundled on all distros
    local THEME_VALUE="Default"

    if [ -f "$BTOP_CONF_FILE" ]; then
        sed -i 's|^color_theme =.*|color_theme = "'"$THEME_VALUE"'"|' "$BTOP_CONF_FILE"
    else
        echo "color_theme = \"$THEME_VALUE\"" > "$BTOP_CONF_FILE"
    fi

    echo "✅ btop configuration completed."
}

# Function to install Neovim with NvChad starter config
setup_neovim() {
    echo "--- Neovim + NvChad Setup ---"

    local NVIM_CONF_DIR="$HOME/.config/nvim"

    if [ -d "$NVIM_CONF_DIR" ]; then
        echo "Neovim config directory already exists. Skipping NvChad install."
        return
    fi

    echo "Installing NvChad starter config..."
    git clone https://github.com/NvChad/starter "$NVIM_CONF_DIR"
    echo "✅ NvChad starter config installed."
    echo "🚨 ACTION REQUIRED: Run 'nvim' to complete NvChad plugin installation."
}

# Function to add aliases and function definitions to .zshrc
add_aliases_and_functions() {
    echo "--- Aliases and Zsh Functions Setup ---"

    if grep -q "alias ls='lsd --group-dirs first'" "$ZSHRC_FILE"; then
        echo "Aliases already present in $ZSHRC_FILE. Skipping."
        return
    fi

    # Detect the bat binary name (batcat on Debian/Ubuntu, bat on other distros)
    local BAT_BIN
    if command -v batcat &>/dev/null; then
        BAT_BIN="batcat"
    else
        BAT_BIN="bat"
    fi

    echo "Adding custom aliases and fzf functions to $ZSHRC_FILE..."

    cat >> "$ZSHRC_FILE" <<EOF

# ===============================================
# CUSTOM ALIASES & FUNCTIONS
# ===============================================

# Aliases for LSD (better 'ls') and BAT (better 'cat')
alias ls='lsd --group-dirs first'
alias tree='lsd --tree'
alias cat='${BAT_BIN} --pager=never --style=plain'

# FZF configuration for fuzzy finding
alias fzf='fzf --exact --tac --height 40% --reverse --inline-info --preview-window=up:3:wrap --preview "echo {}"'

# FZF History Search Function: Binds to Ctrl+F (^F)
__search_history() {
    local selected_command
    selected_command=\$(history 0 | awk '{\$1=""; if (!seen[\$0]++) print \$0}' | fzf)

    if [[ -n \$selected_command ]]; then
        BUFFER=\$(echo "\$selected_command" | sed 's/^[ \t]*//')
        CURSOR=\$#BUFFER
    fi
    zle clear-screen
}
zle -N __search_history
bindkey '^F' __search_history

# Zoxide Initialization
eval "\$(zoxide init zsh)"

EOF

    echo "✅ Aliases and functions added."
}

# Function to change default shell
change_default_shell() {
    echo "--- Shell Configuration ---"
    if [ "$(basename "$SHELL")" != "zsh" ]; then
        echo "Setting default shell for $USER to Zsh..."
        sudo chsh -s "$(which zsh)" "$USER"
    else
        echo "Default shell is already Zsh. Skipping."
    fi
}

# ===============================================
# MAIN EXECUTION FLOW
# ===============================================

install_core_packages
install_nerd_font
setup_zsh
add_aliases_and_functions
configure_tmux
configure_btop
setup_neovim
change_default_shell

echo "================================================="
echo "✅ Script execution complete. Configuration is saved."
echo ""
echo "Next steps:"
echo "  1. LOG OUT and LOG BACK IN to apply Zsh as the default shell"
echo "  2. Start tmux and press 'prefix + I' to install tmux plugins"
echo "  3. Run 'nvim' to complete NvChad plugin installation"
echo "================================================="

# ===============================================
# END OF SCRIPT
# ===============================================
