#!/usr/bin/zsh

# main
main () {
cd ~/.my-vim-config

#cp basic/.zsh-* ~/
rsync -av --exclude=.zsh-variables basic/.zsh-* ~/
source ~/.zshrc

cp tmux/.tmux.conf ~/

cp -r basic/.pip ~/
cp basic/.gitconfig ~/
echo "update finish"
}

main

