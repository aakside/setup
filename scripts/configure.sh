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

mkdir -p ~/{Documents,Dropbox,Music}
mkdir -p ~/Dropbox/.config
ln -sfn ~/Documents ~/Dropbox/Documents
cp $ASSETS/.bash_functions ~/.bash_functions && echo 'source ~/.bash_functions' >>~/.bash_profile

if [ "$DISTRO" == "Ubuntu" ]; then
  mkdir -p ~/.purple && ln -sfn ~/.purple ~/Dropbox/.config/.purple
  sudo apt install ack git curl vim
fi

if [ "$DISTRO" == "darwin" ]; then
  mkdir -p ~/Music/Library
  ln -sfn ~/Music/Library ~/Dropbox/Music
  cp $ASSETS/.bash_aliases ~/.bash_aliases && echo 'source ~/.bash_aliases' >>~/.bash_profile
  xcode-select --install && \
    /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)" && \
    brew install ack coreutils ffmpeg flac gdbm gettext glib gnutls \
    adoptopenjdk gradle jpeg lame libogg libpng libtiff libvorbis libvpx \
    libyaml node openjpeg openssl pcre readline sbt sqlite webp wget x264 x265 \
    xvid yarn
else
  ln -sfn ~/Music ~/Dropbox/Music
fi

# Configure git
cp $ASSETS/.gitignore ~/.gitignore
git config --global core.excludesfile ~/.gitignore
git config --global core.editor vim
git config --global user.name "Alvin Ali Khaled"
git config --global user.email aakside@gmail.com

# TODO: Copy SSH keys?
# TODO: Prompt user to install Dropbox and use ~/Dropbox as "Dropbox folder."
#       This has not been trivial.

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
