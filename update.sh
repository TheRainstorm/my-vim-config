#!/usr/bin/zsh

# main
main () {
cd ~/.my-vim-config

cp basic/.zsh* ~/
source ~/.zshrc

cp tmux/.tmux.conf ~/

cp -r basic/.pip ~/
cp basic/.gitconfig ~/
echo "update finish"
}

main

