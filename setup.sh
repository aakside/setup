#!/bin/bash

mkdir ~/Dropbox
ln -s ~/Dropbox/Documents
ln -s ~/Dropbox/Music
# TODO: Copy SSH keys?
# TODO: Prompt user to install Dropbox and use ~/Dropbox as installation dir.

# TODO: Install typefaces

# Copy Vim configuration
cp ./.vimrc ~/.vimrc

# Install Pathogen
mkdir -p ~/.vim/{autoload,bundle} && \
  curl -LSso ~/.vim/autoload/pathogen.vim https://tpo.pe/pathogen.vim

# TODO: Check that git is installed

# Install Vim plugins
git clone --depth=1 https://github.com/rust-lang/rust.vim.git ~/.vim/bundle/rust.vim
git clone https://github.com/fatih/vim-go.git ~/.vim/bundle/vim-go
mkdir -p ~/.vim/{ftdetect,indent,syntax} && \
  for d in ftdetect indent syntax ; do curl -o ~/.vim/$d/scala.vim https://raw.githubusercontent.com/derekwyatt/vim-scala/master/$d/scala.vim; done
git clone https://github.com/kchmck/vim-coffee-script.git ~/.vim/bundle/vim-coffee-script/
curl -o ~/.vim/colors/mustang.vim https://raw.githubusercontent.com/croaker/mustang-vim/master/colors/mustang.vim
