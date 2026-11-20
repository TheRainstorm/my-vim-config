#!/usr/bin/env zsh

# source 时也在独立进程中运行，避免严格模式影响当前交互 shell。
if [[ "$ZSH_EVAL_CONTEXT" == *:file ]]; then
    command zsh -f "${${(%):-%N}:A}" "$@"
    return $?
fi

set -euo pipefail

# 常用变量都放在前面，之后要换源、换目录会比较好改。
REPO_URL="https://github.com/TheRainstorm/my-vim-config"
OH_MY_ZSH_URL="https://github.com/ohmyzsh/ohmyzsh.git"
FZF_URL="https://github.com/junegunn/fzf.git"

SCRIPT_DIR="${0:A:h}"
REPO_DIR="$SCRIPT_DIR"
DEFAULT_REPO_DIR="$HOME/Repo/my-vim-config"
REPO_DIR_OPTION_SET=0
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
  --repo-dir DIR       Use or clone the config repo at DIR.
  --skip-deps          Skip apt dependency install.
  --no-fzf             Skip fzf.
  --with-fzf           Install/update fzf when running update.
  -h, --help           Show help.

Compatibility:
  ./setup.sh 0         Same as: ./setup.sh --no-fzf

When run outside the config repo, clone it into \$HOME/Repo/my-vim-config.
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
                REPO_DIR_OPTION_SET=1
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

    # 可选条件不满足也属于正常解析结果。
    return 0
}

home_dir() {
    [[ -n "$PREFIX" ]] && print -- "$PREFIX" || print -- "$HOME"
}

copy_file() {
    local src="$1"
    local dst="$(home_dir)/$2"

    log "Copy ${dst/#$HOME/~}"
    mkdir -p "${dst:h}"
    cp "$src" "$dst"
}

copy_dir() {
    local src="$1"
    local dst="$(home_dir)/$2"

    log "Copy ${dst/#$HOME/~}/"
    mkdir -p "$dst"
    cp -R "$src"/. "$dst"/
}

append_once() {
    local file="$1"
    local line="$2"

    mkdir -p "${file:h}"
    touch "$file"
    if grep -Fqx "$line" "$file"; then
        log "Keep ${file/#$HOME/~}"
    else
        log "Append ${file/#$HOME/~}"
        print -- "$line" >> "$file"
    fi
}

insert_once_before_omz() {
    local zshrc="$1"
    local line="$2"
    local tmp

    touch "$zshrc"
    if grep -Fqx "$line" "$zshrc"; then
        log "Keep ${zshrc/#$HOME/~}"
        return 0
    fi

    log "Patch ${zshrc/#$HOME/~}"
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

has_config_files() {
    local repo="$1"
    local file

    for file in basic/.zsh-custom basic/.zsh-only basic/.zsh-zcomet \
                basic/.gitconfig tmux/.tmux.conf vim/vimrc; do
        [[ -f "$repo/$file" ]] || return 1
    done
    [[ -d "$repo/basic/.pip" ]]
}

ensure_config_repo() {
    if has_config_files "$REPO_DIR"; then
        log "Use config repo $REPO_DIR"
        return 0
    fi

    if (( REPO_DIR_OPTION_SET == 0 )); then
        REPO_DIR="$DEFAULT_REPO_DIR"
    fi
    if has_config_files "$REPO_DIR"; then
        log "Use config repo $REPO_DIR"
        return 0
    fi

    command -v git >/dev/null 2>&1 || die "git is required to clone the config repo"
    [[ ! -e "$REPO_DIR" ]] || die "$REPO_DIR exists but is missing config files; choose another --repo-dir"
    mkdir -p "${REPO_DIR:h}"
    log "Clone config repo to $REPO_DIR"
    git clone --depth 1 "$REPO_URL" "$REPO_DIR"
    has_config_files "$REPO_DIR" || die "cloned repo is missing required config files"
}

update_repo() {
    [[ -d "$REPO_DIR/.git" ]] || die "$REPO_DIR is not a git repo"
    log "Pulling latest config repo"
    git -C "$REPO_DIR" pull --ff-only
}

install_deps() {
    if (( INSTALL_DEPS != 1 )); then
        log "Skip dependency install"
        return 0
    fi
    if ! command -v apt >/dev/null 2>&1; then
        log "Skip dependency install: apt not found"
        return 0
    fi

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

    if [[ -d "$HOME/.oh-my-zsh" ]]; then
        log "Keep ~/.oh-my-zsh"
        return 0
    fi

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
    if [[ "$COMMAND" != "update" || -n "$PREFIX" ]]; then
        if [[ -f "$REPO_DIR/basic/.zsh-variables" ]]; then
            copy_file "$REPO_DIR/basic/.zsh-variables" ".zsh-variables"
        else
            log "Skip optional .zsh-variables: not included in config repo"
        fi
    fi

    # 常用工具配置。
    copy_file "$REPO_DIR/tmux/.tmux.conf" ".tmux.conf"
    copy_file "$REPO_DIR/vim/vimrc" ".vimrc"
    copy_dir "$REPO_DIR/basic/.pip" ".pip"
    copy_file "$REPO_DIR/basic/.gitconfig" ".gitconfig"
}

install_fzf() {
    local root="$(home_dir)"

    if (( INSTALL_FZF != 1 )); then
        log "Skip fzf"
        return 0
    fi

    if [[ -n "$PREFIX" ]]; then
        log "Preparing fzf in prefix"
        clone_or_copy "$HOME/.fzf" "$FZF_URL" ".fzf"
        HOME="$root" "$root/.fzf/install" --all --no-bash --no-fish
        return
    fi

    [[ -d "$HOME/.fzf" ]] || git clone --depth 1 "$FZF_URL" "$HOME/.fzf"
    log "Configure fzf"
    "$HOME/.fzf/install" --all --no-bash --no-fish
}

main() {
    parse_args "$@"
    install_deps
    ensure_config_repo
    [[ "$COMMAND" == "update" ]] && update_repo

    install_oh_my_zsh
    install_my_configs
    install_fzf

    log "$COMMAND finished"
}

main "$@"
