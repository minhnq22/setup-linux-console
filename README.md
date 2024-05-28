# setup-linux-console
Setup some config for Linux server.

```
#!/bin/bash -e

sudo apt update

# Check if git is installed
if ! command -v git &> /dev/null; then
    echo "Git is not installed. Installing..."
    sudo apt install -y git
fi

# Check if zsh is installed
if ! command -v zsh &> /dev/null; then
    echo "Zsh is not installed. Installing..."
    sudo apt install -y zsh
fi

# Check if Oh My Zsh is installed
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    echo "Oh My Zsh is not installed. Installing..."
    RUNZSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi

# Install zsh-syntax-highlighting plugin
if [ ! -d "$HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting" ]; then
    echo "Installing zsh-syntax-highlighting plugin..."
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git $HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting
fi

# Install zsh-autosuggestions plugin
if [ ! -d "$HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions" ]; then
    echo "Installing zsh-autosuggestions plugin..."
    git clone https://github.com/zsh-users/zsh-autosuggestions.git $HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions
fi

# Update .zshrc to enable plugins and set theme
if ! grep -q "zsh-syntax-highlighting" $HOME/.zshrc; then
    sed -i -e 's/plugins=(/plugins=(zsh-syntax-highlighting zsh-autosuggestions /' $HOME/.zshrc
fi
sed -i -e 's/ZSH_THEME=".*"/ZSH_THEME="lukerandall"/' $HOME/.zshrc

# Change default shell to zsh
chsh -s $(which zsh)

echo "Oh My Zsh installation with plugins completed."

# Check if tmux is installed
if ! command -v tmux &> /dev/null; then
    echo "Tmux is not installed. Installing..."
    sudo apt install -y tmux
fi

# Check if tmux plugin manager (TPM) is installed
if [ ! -d "$HOME/.tmux/plugins/tpm" ]; then
    echo "Tmux Plugin Manager (TPM) is not installed. Installing..."
    git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
fi

echo "Tmux and TPM installation completed."

# Create .tmux.conf file
cat <<EOF > $HOME/.tmux.conf
# List of plugins
set -g @plugin 'tmux-plugins/tpm'
set -g @plugin 'tmux-plugins/tmux-sensible'
set -g @plugin 'arcticicestudio/nord-tmux'
set -g @plugin 'tmux-plugins/tmux-prefix-highlight'
set -g mouse on

# Initialize TMUX plugin manager (keep this line at the very bottom of tmux.conf)
run '~/.tmux/plugins/tpm/tpm'
EOF

# Install Tmux plugins
$HOME/.tmux/plugins/tpm/bin/install_plugins

echo "Tmux configuration file created and plugins installed."

# Install bat
if ! command -v batcat &> /dev/null; then
    echo "Bat is not installed. Installing..."
    sudo apt install -y bat
fi

# Install lsd
if ! command -v lsd &> /dev/null; then
    echo "LSD is not installed. Installing..."
    sudo apt install -y lsd
fi

echo "Bat and LSD installation completed."

# Add aliases to .zshrc
if ! grep -q "alias ls='lsd --group-dirs first'" $HOME/.zshrc; then
    cat <<EOF >> $HOME/.zshrc
# Aliases for LSD and BAT
alias ls='lsd --group-dirs first'
alias tree='lsd --tree'
alias bat='batcat --theme=base16-256'
alias cat='batcat --pager=never'
EOF
fi

echo "Aliases added to .zshrc."
```
