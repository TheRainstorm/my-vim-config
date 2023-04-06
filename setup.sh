#!/usr/bin/zsh

# clone repo
clone_repo () {
    if [ -d ~/.my-vim-config ]; then
        echo "~/.my-vim-config exist, skip clone"
    else
        git clone https://github.com/TheRainstorm/my-vim-config ~/.my-vim-config
        if [ ! $?=0 ]; then
            echo "clone failed, exit"
            exit 1
        fi
    fi
}

# install dependency
check_dep () {
    sudo apt update
    sudo apt install git curl 
    echo "sudo apt install git curl" 
    return 0
}

# setup zsh
setup_zsh () {
sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" <<EOF
    y
EOF

output=$(cat ~/.zshrc|grep zsh-custom |wc -l)
if [ $output = "0" ]; then
    echo "[ -f ~/.zsh-custom ] && source ~/.zsh-custom" >> ~/.zshrc
fi

cp basic/.zsh* ~/

source ~/.zshrc
}

# setup fzf
setup_fzf () {
git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
~/.fzf/install <<EOF
y
y
y
EOF

source ~/.zshrc
}

# tmux
setup_tmux () {
    cp tmux/.tmux.conf ~/
}
# utils
setup_others () {
    cp -r basic/.pip ~/
    cp basic/.gitconfig ~/
}

# main
main () {
check_dep
clone_repo
cd ~/.my-vim-config

setup_zsh
setup_fzf
setup_tmux
setup_others
}

main
