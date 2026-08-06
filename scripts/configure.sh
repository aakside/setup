#!/bin/bash

set -e

# Check OS. Taken from https://askubuntu.com/questions/459402/how-to-know-if-the-running-platform-is-ubuntu-or-centos-with-help-of-a-bash-scri
UNAME=$(uname | tr "[:upper:]" "[:lower:]")
# If Linux, try to determine specific distribution
if [ "$UNAME" == "linux" ]; then
    # If available, use LSB to identify distribution
    if [ -f /etc/lsb-release -o -d /etc/lsb-release.d ]; then
        export DISTRO=$(lsb_release -i | cut -d: -f2 | sed s/'^\t'//)
    # Otherwise, use release info file
    else
        export DISTRO=$(ls -d /etc/[A-Za-z]*[_-][rv]e[lr]* | grep -v "lsb" | cut -d'/' -f3 | cut -d'-' -f1 | cut -d'_' -f1)
    fi
fi
# For everything else (or if above failed), just use generic identifier
[ "$DISTRO" == "" ] && export DISTRO=$UNAME
unset UNAME

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ASSETS=$DIR/../assets

# Append a line to a file only if it isn't already present, so re-running this
# script doesn't accumulate duplicate lines. Creates the file if it's missing.
append_once() {
  local line="$1" file="$2"
  grep -qxF -- "$line" "$file" 2>/dev/null || echo "$line" >>"$file"
}

mkdir -p ~/Code && cp $ASSETS/.stignore "$_" && cp $ASSETS/default_stignore "$_/stignore"
mkdir -p ~/Documents && cp $ASSETS/.stignore "$_" && cp $ASSETS/default_stignore "$_/stignore"
mkdir -p ~/Music/Library && cp $ASSETS/.stignore "$_" && cp $ASSETS/default_stignore "$_/stignore"
mkdir -p ~/"Mobile Downloads" && cp $ASSETS/.stignore "$_" && cp $ASSETS/default_stignore "$_/stignore"

cp $ASSETS/.bash_aliases ~/.bash_aliases
append_once 'source ~/.bash_aliases' ~/.bash_profile
append_once 'source ~/.bash_aliases' ~/.zprofile

if [ "$DISTRO" == "Ubuntu" ]; then
  cat $ASSETS/.ubuntu_bash_aliases >> ~/.bash_aliases
  # Enable Ubuntu's stock colored prompt (green user@host, blue path). It's
  # gated on TERM matching *-256color, which Ghostty's xterm-ghostty doesn't;
  # flipping force_color_prompt on turns it on regardless of terminal.
  sed -i 's/^#force_color_prompt=yes/force_color_prompt=yes/' ~/.bashrc
  sudo apt install \
    curl \
    git \
    -y
  curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add - && echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add - && sudo apt-key fingerprint 0EBFCD88 && sudo add-apt-repository    "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
  wget -O- https://updates.signal.org/desktop/apt/keys.asc | gpg --dearmor > signal-desktop-keyring.gpg
  cat signal-desktop-keyring.gpg | sudo tee /usr/share/keyrings/signal-desktop-keyring.gpg > /dev/null
  echo 'deb [arch=amd64 signed-by=/usr/share/keyrings/signal-desktop-keyring.gpg] https://updates.signal.org/desktop/apt xenial main' |\
    sudo tee /etc/apt/sources.list.d/signal-xenial.list
  sudo add-apt-repository ppa:agornostal/ulauncher
  sudo apt update && sudo apt install \
    ack \
    build-essential \
    g++ \
    gcc \
    vim \
    apt-transport-https \
    ca-certificates \
    check \
    cifs-utils \
    containerd.io \
    direnv \
    doxygen \
    docker-ce \
    docker-ce-cli \
    flatpak \
    gnome-software-plugin-flatpak \
    gnome-tweaks \
    gnupg-agent \
    graphviz \
    keyutils \
    libbz2-dev \
    libcairo2-dev \
    libevdev-dev \
    libffi-dev \
    libglib2.0-dev \
    libgtk-3-dev \
    libmtdev-dev \
    libsqlite3-dev \
    libreadline-dev \
    libssl-dev \
    libsystemd-dev \
    libudev-dev \
    libwacom-dev \
    meson \
    ncurses-dev \
    pkg-config \
    python3-pytest-xdist \
    python3-recommonmark \
    python3-sphinx \
    python3-sphinx-rtd-theme \
    ripgrep \
    signal-desktop \
    sqlite3 \
    syncthing \
    software-properties-common \
    tk-dev \
    ulauncher \
    valgrind \
    webp-pixbuf-loader \
    zsh \
    -y
  flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
  snap list ghostty >/dev/null 2>&1 || sudo snap install ghostty --classic
  sudo usermod -aG docker ${USER}
  sudo chmod 666 /var/run/docker.sock
  sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose && sudo chmod +x /usr/local/bin/docker-compose
  grep -qxF 'fs.inotify.max_user_watches=204800' /etc/sysctl.conf || echo "fs.inotify.max_user_watches=204800" | sudo tee -a /etc/sysctl.conf
  sudo sh -c 'echo 204800 > /proc/sys/fs/inotify/max_user_watches'
  gsettings set org.gnome.desktop.interface clock-show-seconds true
  gsettings set org.gnome.desktop.peripherals.touchpad tap-and-drag false
  mkdir -p ~/bin && wget --no-check-certificate https://www.styluslabs.com/download/write-tgz -O write-tgz && tar -xzf write-tgz -C ~/bin && rm write-tgz && cd ~/bin/Write && ./setup.sh
fi

if [ "$DISTRO" == "darwin" ]; then
  cat $ASSETS/.macos_bash_aliases >> ~/.bash_aliases
  defaults write com.apple.desktopservices DSDontWriteNetworkStores true
  defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true
  xcode-select -p >/dev/null 2>&1 || xcode-select --install
  command -v brew >/dev/null 2>&1 || \
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  brew install ack coreutils direnv ffmpeg flac gdbm gettext glib gnutls \
    gradle jpeg lame libogg libpng libtiff libvorbis libvpx libyaml \
    openjpeg openssl pcre readline ripgrep sbt sqlite webp wget x264 x265 xvid
  brew list --cask ghostty >/dev/null 2>&1 || brew install --cask ghostty
  append_once 'eval "$(/opt/homebrew/bin/brew shellenv)"' ~/.zprofile
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

append_once 'eval "$(direnv hook bash)"' ~/.bashrc
append_once 'eval "$(direnv hook zsh)"' ~/.zshrc
# Skip if already installed; RUNZSH=no keeps the installer from exec'ing zsh
# and halting the rest of this script.
[ -d "$HOME/.oh-my-zsh" ] || RUNZSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# Install fnm and nodejs
curl -fsSL https://fnm.vercel.app/install | bash
source ~/.bashrc
fnm completions --shell bash | sudo tee /usr/share/bash-completion/completions/fnm > /dev/null
mkdir -p ~/.oh-my-zsh/completions
fnm completions --shell zsh > ~/.oh-my-zsh/completions/_fnm
append_once 'eval "$(fnm env --use-on-cd)"' ~/.bashrc
append_once 'eval "$(fnm env --use-on-cd)"' ~/.zshrc
fnm use 20
corepack enable

# Configure git
cp $DIR/../.gitignore ~/.gitignore
git config --global core.excludesfile ~/.gitignore
git config --global core.editor vim
git config --global pull.rebase true
git config --global user.name "Alvin Ali Khaled"
git config --global user.email aakside@gmail.com

# TODO: Install typefaces

# Copy Ghostty configuration (Ghostty reads this XDG path on both Linux and
# macOS, so one file works everywhere).
mkdir -p ~/.config/ghostty && cp $ASSETS/ghostty/config ~/.config/ghostty/config

# Copy Vim configuration
cp $ASSETS/.vimrc ~/.vimrc

# Install Pathogen
mkdir -p ~/.vim/{autoload,bundle,colors,ftdetect,indent,syntax} && \
  curl -LSso ~/.vim/autoload/pathogen.vim https://tpo.pe/pathogen.vim

# Install Vim plugins
curl -o ~/.vim/colors/mustang.vim https://raw.githubusercontent.com/croaker/mustang-vim/master/colors/mustang.vim
