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

mkdir -p ~/Code && cp $ASSETS/.stignore "$_"
mkdir -p ~/Documents && cp $ASSETS/.stignore "$_"
mkdir -p ~/Music/Library && cp $ASSETS/.stignore "$_"
mkdir -p ~/"Mobile Downloads" && cp $ASSETS/.stignore "$_"

cp $ASSETS/.bash_aliases ~/.bash_aliases && echo 'source ~/.bash_aliases' >>~/.bash_profile && echo 'source ~/.bash_aliases' >>~/.zprofile

if [ "$DISTRO" == "Ubuntu" ]; then
  cat $ASSETS/.ubuntu_bash_aliases >> ~/.bash_aliases
  sudo apt install \
    curl \
    git
  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.38.0/install.sh | bash
  export NVM_DIR="$HOME/.nvm"
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
  [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
  nvm install node
  curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add - && echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add - && sudo apt-key fingerprint 0EBFCD88 && sudo add-apt-repository    "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
  wget -O- https://updates.signal.org/desktop/apt/keys.asc | gpg --dearmor > signal-desktop-keyring.gpg
  cat signal-desktop-keyring.gpg | sudo tee -a /usr/share/keyrings/signal-desktop-keyring.gpg > /dev/null
  echo 'deb [arch=amd64 signed-by=/usr/share/keyrings/signal-desktop-keyring.gpg] https://updates.signal.org/desktop/apt xenial main' |\
    sudo tee -a /etc/apt/sources.list.d/signal-xenial.list
  sudo add-apt-repository ppa:agornostal/ulauncher
  sudo apt update && sudo apt install \
    ack \
    vim \
    nodejs \
    yarn \
    syncthing \
    apt-transport-https \
    ca-certificates \
    direnv \
    flatpak \
    gnome-software-plugin-flatpak \
    gnupg-agent \
    software-properties-common \
    docker-ce \
    docker-ce-cli \
    containerd.io \
    signal-desktop \
    ulauncher \
    -y
  flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
  sudo usermod -aG docker ${USER}
  sudo chmod 666 /var/run/docker.sock
  sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose && sudo chmod +x /usr/local/bin/docker-compose
  echo "fs.inotify.max_user_watches=204800" | sudo tee -a /etc/sysctl.conf
  sudo sh -c 'echo 204800 > /proc/sys/fs/inotify/max_user_watches'
fi

if [ "$DISTRO" == "darwin" ]; then
  cat $ASSETS/.macos_bash_aliases >> ~/.bash_aliases
  defaults write com.apple.desktopservices DSDontWriteNetworkStores true
  xcode-select --install && \
    /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)" && \
    brew install ack coreutils direnv ffmpeg flac gdbm gettext glib gnutls \
    gradle jpeg lame libogg libpng libtiff libvorbis libvpx \
    libyaml node openjpeg openssl pcre readline sbt sqlite webp wget x264 x265 \
    xvid yarn && \
    echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> /Users/alvinkhaled/.zprofile && \
    eval "$(/opt/homebrew/bin/brew shellenv)"
fi

echo 'eval "$(direnv hook bash)"' >>~/.bashrc
echo 'eval "$(direnv hook zsh)"' >>~/.zshrc

# Configure git
cp $DIR/../.gitignore ~/.gitignore
git config --global core.excludesfile ~/.gitignore
git config --global core.editor vim
git config --global pull.rebase true
git config --global user.name "Alvin Ali Khaled"
git config --global user.email aakside@gmail.com

# TODO: Install typefaces

# Copy Vim configuration
cp $ASSETS/.vimrc ~/.vimrc

# Install Pathogen
mkdir -p ~/.vim/{autoload,bundle,colors,ftdetect,indent,syntax} && \
  curl -LSso ~/.vim/autoload/pathogen.vim https://tpo.pe/pathogen.vim

# Install Vim plugins
git clone --depth=1 https://github.com/rust-lang/rust.vim.git ~/.vim/bundle/rust.vim
git clone https://github.com/fatih/vim-go.git ~/.vim/bundle/vim-go
curl -o ~/.vim/ftdetect/scala.vim https://raw.githubusercontent.com/derekwyatt/vim-scala/master/ftdetect/scala.vim
curl -o ~/.vim/indent/scala.vim https://raw.githubusercontent.com/derekwyatt/vim-scala/master/indent/scala.vim
curl -o ~/.vim/syntax/scala.vim https://raw.githubusercontent.com/derekwyatt/vim-scala/master/syntax/scala.vim
curl -o ~/.vim/colors/mustang.vim https://raw.githubusercontent.com/croaker/mustang-vim/master/colors/mustang.vim
git clone https://github.com/leafgarland/typescript-vim.git ~/.vim/bundle/typescript-vim
