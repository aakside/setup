#!/bin/bash

set -e

# Vertify git is installed
which git > /dev/null
if [ $? -ne 0 ]; then
  echo "Install git."
  exit 1
fi

# TODO: Configure git

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ASSETS=$DIR/../assets

mkdir -p ~/{Documents,Dropbox,Music,.purple}
mkdir -p ~/Dropbox/.config
ln -s ~/Documents ~/Dropbox/Documents
ln -s ~/Music ~/Dropbox/Music
ln -s ~/.purple ~/Dropbox/.config/.purple # TODO: Link if OS is Ubuntu?
# TODO: Copy SSH keys?
# TODO: Copy Firefox profiles?
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
