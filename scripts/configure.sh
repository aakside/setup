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

mkdir -p ~/{Documents,Music}
mkdir -p ~/Music/Library
cp $ASSETS/.bash_functions ~/.bash_functions && echo 'source ~/.bash_functions' >>~/.bash_profile
cp $ASSETS/.bash_aliases ~/.bash_aliases && echo 'source ~/.bash_aliases' >>~/.bash_profile

if [ "$DISTRO" == "Ubuntu" ]; then
  echo $ASSETS/.ubuntu_bash_aliases >> ~/.bash_aliases
  curl -sL https://deb.nodesource.com/setup_14.x | sudo -E bash -
  curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add - && echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add - && sudo apt-key fingerprint 0EBFCD88 && sudo add-apt-repository    "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
  sudo apt update && sudo apt install \
    ack \
    git \
    curl \
    vim \
    nodejs \
    yarn \
    syncthing \
    apt-transport-https \
    ca-certificates \
    gnupg-agent \
    software-properties-common \
    docker-ce \
    docker-ce-cli \
    containerd.io
  sudo usermod -aG docker aak
  sudo curl -L "https://github.com/docker/compose/releases/download/1.26.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose && sudo chmod +x /usr/local/bin/docker-compose
fi

if [ "$DISTRO" == "darwin" ]; then
  echo $ASSETS/.macos_bash_aliases >> ~/.bash_aliases
  cp $ASSETS/.bash_aliases ~/.bash_aliases && echo 'source ~/.bash_aliases' >>~/.bash_profile
  xcode-select --install && \
    /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)" && \
    brew install ack coreutils ffmpeg flac gdbm gettext glib gnutls \
    adoptopenjdk gradle jpeg lame libogg libpng libtiff libvorbis libvpx \
    libyaml node openjpeg openssl pcre readline sbt sqlite webp wget x264 x265 \
    xvid yarn
fi

# Configure git
cp $ASSETS/.gitignore ~/.gitignore
git config --global core.excludesfile ~/.gitignore
git config --global core.editor vim
git config --global user.name "Alvin Ali Khaled"
git config --global user.email aakside@gmail.com

# TODO: Copy SSH keys?

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
git clone https://github.com/kchmck/vim-coffee-script.git ~/.vim/bundle/vim-coffee-script/
curl -o ~/.vim/colors/mustang.vim https://raw.githubusercontent.com/croaker/mustang-vim/master/colors/mustang.vim
git clone https://github.com/leafgarland/typescript-vim.git ~/.vim/bundle/typescript-vim
