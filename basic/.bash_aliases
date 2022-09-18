alias l='ls -alh'
alias f='neofetch'
alias t="tmux "
alias ra="ranger"
alias ca="conda activate "
#alias setp="export HTTP_PROXY=http://127.0.0.1:11223;export HTTPS_PROXY=$HTTP_PROXY"
#alias unsetp="unset HTTP_PROXY; unset HTTPS_PROXY"
export proxy_addr=localhost
export proxy_http_port=11223
export proxy_socks_port=11223
function setp() {
    export http_proxy=http://$proxy_addr:$proxy_http_port #如果使用git 不行，这两个http和https改成socks5就行
    export https_proxy=http://$proxy_addr:$proxy_http_port
    export all_proxy=socks5://$proxy_addr:$proxy_socks_port
}
function unsetp() {
    unset http_proxy
    unset https_proxy
    unset all_proxy
}
function testp() {
    curl -v https://www.google.com 2>&1 | egrep 'HTTP/(2|1.1) 200'
}

export PATH="/home/yfy/.local/bin:$PATH"

# Prompt
#export PROMPT="%B%n@%m $PROMPT"
#export RPROMPT="%*"