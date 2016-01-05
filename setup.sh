#!/bin/bash

mkdir ~/Dropbox
ln -s ~/Dropbox/Documents
ln -s ~/Dropbox/Music
# TODO: Copy SSH keys?
# TODO: Prompt user to install Dropbox and use ~/Dropbox as installation dir.

# TODO: Install typefaces

# Copy Vim configuration
cp ./.vim ~/.vim
cp ./.vimrc ~/.vimrc

# Install Pathogen
curl -LSso ~/.vim/autoload/pathogen.vim https://tpo.pe/pathogen.vim

