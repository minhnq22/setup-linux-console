# setup-linux-console.sh

```
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
    
    # List of packages to install, including zoxide, bat, lsd, fzf
    PACKAGES=(
        git 
        zsh 
        tmux 
        btop 
        bat 
        lsd 
        fzf 
        zoxide # Added zoxide
    )
    
    # Update and install packages non-interactively
    sudo apt update
    sudo apt install -y "${PACKAGES[@]}"
    
    if [ $? -eq 0 ]; then
        echo "✅ Core packages installed successfully."
    else
        echo "❌ Error installing core packages. Exiting."
        exit 1
    fi
}

# Function to install and configure Oh My Zsh and plugins
setup_zsh() {
    echo "--- Zsh & Oh My Zsh Setup ---"

    # Check and install Oh My Zsh
    if [ ! -d "$HOME/.oh-my-zsh" ]; then
        echo "Installing Oh My Zsh..."
        RUNZSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
    else
        echo "Oh My Zsh already installed."
    fi

    # Install required plugins
    HIGHLIGHT_DIR="$HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting"
    AUTOSUGGEST_DIR="$HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions"
    
    [ ! -d "$HIGHLIGHT_DIR" ] && echo "Installing zsh-syntax-highlighting plugin..." && git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$HIGHLIGHT_DIR"
    [ ! -d "$AUTOSUGGEST_DIR" ] && echo "Installing zsh-autosuggestions plugin..." && git clone https://github.com/zsh-users/zsh-autosuggestions.git "$AUTOSUGGEST_DIR"

    # Update .zshrc with plugins and theme
    echo "Configuring $ZSHRC_FILE..."
    
    if ! grep -q "zsh-syntax-highlighting" "$ZSHRC_FILE"; then
        sed -i -e 's/plugins=(/plugins=(zsh-syntax-highlighting zsh-autosuggestions /' "$ZSHRC_FILE"
    fi
    
    sed -i -e 's/ZSH_THEME=".*"/ZSH_THEME="lukerandall"/' "$ZSHRC_FILE"

    echo "Zsh configuration updated."
}

# Function to configure Tmux Plugin Manager (TPM)
configure_tmux() {
    echo "--- Tmux Setup ---"

    # Check and install Tmux Plugin Manager (TPM)
    TPM_DIR="$HOME/.tmux/plugins/tpm"
    if [ ! -d "$TPM_DIR" ]; then
        echo "Installing Tmux Plugin Manager (TPM)..."
        git clone https://github.com/tmux-plugins/tpm "$TPM_DIR"
    else
        echo "TPM already installed."
    fi

    # Create .tmux.conf file with desired plugins and settings
    echo "Creating $TMUX_CONF_FILE..."
    cat <<EOF > "$TMUX_CONF_FILE"
# ===============================================
# TMUX CONFIGURATION
# ===============================================

# List of plugins managed by TPM
set -g @plugin 'tmux-plugins/tpm'
set -g @plugin 'tmux-plugins/tmux-sensible'
set -g @plugin 'arcticicestudio/nord-tmux'
set -g @plugin 'tmux-plugins/tmux-prefix-highlight'

# Enable mouse support
set -g mouse on

# Initialize TMUX plugin manager (keep this line at the very bottom of tmux.conf)
run '$TPM_DIR/tpm'
EOF

    echo "Tmux configuration file created and ready for plugin installation."
    echo "🚨 ACTION REQUIRED: After logging in and starting Zsh, please start tmux and press 'prefix + I' to install plugins."

    echo "Tmux configuration completed."
}

# Function to configure Btop
configure_btop() {
    echo "--- Btop Setup ---"
    
    BTOP_CONF_DIR="$HOME/.config/btop"
    BTOP_CONF_FILE="$BTOP_CONF_DIR/btop.conf"
    THEME_PATH="/usr/share/btop/themes/flat-remix.theme"

    if [ ! -d "$BTOP_CONF_DIR" ]; then
        mkdir -p "$BTOP_CONF_DIR"
    fi
    
    if [ -f "$BTOP_CONF_FILE" ]; then
        sed -i 's|^color_theme =.*|color_theme = "'"$THEME_PATH"'"|' "$BTOP_CONF_FILE"
    else
        echo "color_theme = \"$THEME_PATH\"" > "$BTOP_CONF_FILE"
    fi

    echo "btop configuration completed."
}

# Function to add aliases and function definitions to .zshrc
add_aliases_and_functions() {
    echo "--- Aliases and Zsh Functions Setup ---"

    if ! grep -q "alias ls='lsd --group-dirs first'" "$ZSHRC_FILE"; then
        echo "Adding custom aliases and fzf functions to $ZSHRC_FILE..."
        
        cat <<EOF >> "$ZSHRC_FILE"

# ===============================================
# CUSTOM ALIASES & FUNCTIONS
# ===============================================

# Aliases for LSD (better 'ls') and BAT (better 'cat')
alias ls='lsd --group-dirs first'
alias tree='lsd --tree'
# Updated: Added --style=plain to batcat alias
alias cat='batcat --pager=never --style=plain' 

# FZF configuration for fuzzy finding
alias fzf='fzf --exact --tac --height 40% --reverse --inline-info --preview-window=up:3:wrap --preview "echo {}"'

# FZF History Search Function: Binds to Ctrl+F (^F)
__search_history() {
    local selected_command
    selected_command=$(history 0 | awk '{\$1=""; if (!seen[\$0]++) print \$0}' | fzf)
    
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
    else
        echo "Aliases and functions already present in $ZSHRC_FILE. Skipping."
    fi
}

# Function to change default shell
change_default_shell() {
    echo "--- Shell Configuration ---"
    # Change default shell to zsh without forcing application (no interaction needed)
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
setup_zsh
add_aliases_and_functions
configure_tmux
configure_btop
change_default_shell

echo "================================================="
echo "✅ Script execution complete. Configuration is saved."
echo "🚨 FINAL ACTION REQUIRED: Please LOG OUT and LOG BACK IN (or restart your terminal/system) to apply Zsh as the default shell and load all new configurations."

# ===============================================
# END OF SCRIPT
# ===============================================
```
