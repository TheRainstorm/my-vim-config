#!/usr/bin/env zsh

set -euo pipefail

# 常用变量都放在前面，之后要换源、换目录会比较好改。
REPO_URL="https://github.com/TheRainstorm/my-vim-config"
OH_MY_ZSH_URL="https://github.com/ohmyzsh/ohmyzsh.git"
FZF_URL="https://github.com/junegunn/fzf.git"

SCRIPT_DIR="${0:A:h}"
REPO_DIR="$SCRIPT_DIR"
PREFIX=""
COMMAND="install"
INSTALL_DEPS=1
INSTALL_FZF=1
FZF_OPTION_SET=0

usage() {
    cat <<EOF
Usage:
  ./setup.sh [install] [options]
  ./setup.sh update [options]

Options:
  -p, --prefix DIR     Install files under DIR instead of \$HOME.
  --repo-dir DIR       Use another config repo directory.
  --skip-deps          Skip apt dependency install.
  --no-fzf             Skip fzf.
  --with-fzf           Install/update fzf when running update.
  -h, --help           Show help.

Compatibility:
  ./setup.sh 0         Same as: ./setup.sh --no-fzf
EOF
}

log() {
    print -- "==> $*"
}

die() {
    print -u2 -- "error: $*"
    exit 1
}

parse_args() {
    while (( $# > 0 )); do
        case "$1" in
            install|update) COMMAND="$1" ;;
            0|--no-fzf) INSTALL_FZF=0; FZF_OPTION_SET=1 ;;
            1|--with-fzf) INSTALL_FZF=1; FZF_OPTION_SET=1 ;;
            --skip-deps) INSTALL_DEPS=0 ;;
            --repo-dir)
                (( $# >= 2 )) || die "$1 requires a directory"
                REPO_DIR="${2:A}"
                shift
                ;;
            -p|--prefix)
                (( $# >= 2 )) || die "$1 requires a directory"
                PREFIX="${2:A}"
                shift
                ;;
            -h|--help)
                usage
                exit 0
                ;;
            *) die "unknown argument: $1" ;;
        esac
        shift
    done

    # update 默认只更新配置；需要 fzf 时显式加 --with-fzf。
    [[ "$COMMAND" == "update" ]] && INSTALL_DEPS=0
    [[ "$COMMAND" == "update" && "$FZF_OPTION_SET" == "0" ]] && INSTALL_FZF=0
    [[ -n "$PREFIX" ]] && INSTALL_DEPS=0
}

home_dir() {
    [[ -n "$PREFIX" ]] && print -- "$PREFIX" || print -- "$HOME"
}

copy_file() {
    local src="$1"
    local dst="$(home_dir)/$2"

    mkdir -p "${dst:h}"
    cp "$src" "$dst"
}

copy_dir() {
    local src="$1"
    local dst="$(home_dir)/$2"

    mkdir -p "$dst"
    cp -R "$src"/. "$dst"/
}

append_once() {
    local file="$1"
    local line="$2"

    mkdir -p "${file:h}"
    touch "$file"
    grep -Fqx "$line" "$file" || print -- "$line" >> "$file"
}

insert_once_before_omz() {
    local zshrc="$1"
    local line="$2"
    local tmp

    touch "$zshrc"
    grep -Fqx "$line" "$zshrc" && return 0

    tmp="$(mktemp)"
    awk -v line="$line" '
        $0 == "source $ZSH/oh-my-zsh.sh" && done == 0 {
            print line
            done = 1
        }
        { print }
        END {
            if (done == 0) print line
        }
    ' "$zshrc" > "$tmp"
    mv "$tmp" "$zshrc"
}

clone_or_copy() {
    local local_dir="$1"
    local url="$2"
    local dst="$(home_dir)/$3"

    if [[ -d "$local_dir" ]]; then
        mkdir -p "$dst"
        cp -R "$local_dir"/. "$dst"/
    elif [[ ! -d "$dst" ]]; then
        git clone --depth 1 "$url" "$dst"
    fi
}

update_repo() {
    [[ -d "$REPO_DIR/.git" ]] || die "$REPO_DIR is not a git repo"
    log "Pulling latest config repo"
    git -C "$REPO_DIR" pull --ff-only
}

install_deps() {
    (( INSTALL_DEPS == 1 )) || return 0
    command -v apt >/dev/null 2>&1 || return 0

    log "Installing dependencies"
    sudo apt update
    sudo apt install -y git curl wget
}

install_oh_my_zsh() {
    local root="$(home_dir)"

    if [[ -n "$PREFIX" ]]; then
        log "Preparing oh-my-zsh in prefix"
        clone_or_copy "$HOME/.oh-my-zsh" "$OH_MY_ZSH_URL" ".oh-my-zsh"
        cp "$root/.oh-my-zsh/templates/zshrc.zsh-template" "$root/.zshrc"
        return
    fi

    [[ -d "$HOME/.oh-my-zsh" ]] && return 0

    log "Installing oh-my-zsh"
    RUNZSH=no CHSH=no sh -c \
        "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
}

install_my_configs() {
    local root="$(home_dir)"

    log "Installing config files to $root"

    # shell: 保留 oh-my-zsh 默认 .zshrc，再插入自己的开关和扩展配置。
    insert_once_before_omz "$root/.zshrc" 'DISABLE_AUTO_UPDATE="true"'
    append_once "$root/.zshrc" '[ -f ~/.zsh-custom ] && source ~/.zsh-custom'
    copy_file "$REPO_DIR/basic/.zsh-custom" ".zsh-custom"
    copy_file "$REPO_DIR/basic/.zsh-only" ".zsh-only"
    copy_file "$REPO_DIR/basic/.zsh-zcomet" ".zsh-zcomet"
    [[ "$COMMAND" != "update" || -n "$PREFIX" ]] && copy_file "$REPO_DIR/basic/.zsh-variables" ".zsh-variables"

    # 常用工具配置。
    copy_file "$REPO_DIR/tmux/.tmux.conf" ".tmux.conf"
    copy_file "$REPO_DIR/vim/vimrc" ".vimrc"
    copy_dir "$REPO_DIR/basic/.pip" ".pip"
    copy_file "$REPO_DIR/basic/.gitconfig" ".gitconfig"
}

install_fzf() {
    local root="$(home_dir)"

    (( INSTALL_FZF == 1 )) || return 0

    if [[ -n "$PREFIX" ]]; then
        log "Preparing fzf in prefix"
        clone_or_copy "$HOME/.fzf" "$FZF_URL" ".fzf"
        HOME="$root" "$root/.fzf/install" --all --no-bash --no-fish
        return
    fi

    [[ -d "$HOME/.fzf" ]] || git clone --depth 1 "$FZF_URL" "$HOME/.fzf"
    "$HOME/.fzf/install" --all --no-bash --no-fish
}

main() {
    parse_args "$@"
    [[ "$COMMAND" == "update" ]] && update_repo

    install_deps
    install_oh_my_zsh
    install_my_configs
    install_fzf

    log "$COMMAND finished"
}

main "$@"
