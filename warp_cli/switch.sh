#!/bin/bash 
red() {
    echo -e "\033[31m\033[01m$1\033[0m"
} 
green() {
    echo -e "\033[32m\033[01m$1\033[0m"
} 
yellow() {
    echo -e "\033[33m\033[01m$1\033[0m"
}

# 判断系统及定义系统安装依赖方式
REGEX=("debian" "ubuntu" "centos|red hat|kernel|oracle linux|alma|rocky" "'amazon linux'")
RELEASE=("Debian" "Ubuntu" "CentOS" "CentOS")
PACKAGE_UPDATE=("apt -y update" "apt -y update" "yum -y update" "yum -y update")
PACKAGE_INSTALL=("apt -y install" "apt -y install" "yum -y install" "yum -y install")
PACKAGE_REMOVE=("apt -y remove" "apt -y remove" "yum -y remove" "yum -y remove")
PACKAGE_UNINSTALL=("apt -y autoremove" "apt -y autoremove" "yum -y autoremove" "yum -y autoremove")

CMD=("$(grep -i pretty_name /etc/os-release 2>/dev/null | cut -d \" -f2)" "$(hostnamectl 2>/dev/null | grep -i system | cut -d : -f2)" "$(lsb_release -sd 2>/dev/null)" "$(grep -i description /etc/lsb-release 2>/dev/null | cut -d \" -f2)" "$(grep . /etc/redhat-release 2>/dev/null)" "$(grep . /etc/issue 2>/dev/null | cut -d \\ -f1 | sed '/^[ ]*$/d')") 

for i in "${CMD[@]}"; do
    SYS="$i" && [[ -n $SYS ]] && break
done

for ((int = 0; int < ${#REGEX[@]}; int++)); do
    [[ $(echo "$SYS" | tr '[:upper:]' '[:lower:]') =~ ${REGEX[int]} ]] && SYSTEM="${RELEASE[int]}" && [[ -n $SYSTEM ]] && break
done

[[ -z $SYSTEM ]] && red "不支持当前VPS的系统，请使用主流操作系统" && exit 1
[[ -z $(type -P warp-cli) ]] && red "WARP-Cli代理模式未安装，脚本即将退出！" && exit 1

switch(){
    if [[ $(warp-cli --accept-tos status) =~ Connected ]]; then
        warp-cli --accept-tos disconnect
        green "WARP-Cli代理模式关闭成功！"
        rm -f switch.sh
        exit 1
    fi
    if [[ $(warp-cli --accept-tos status) =~ Disconnected ]]; then
        yellow "正在启动Warp-Cli代理模式"
        warp-cli --accept-tos connect >/dev/null 2>&1
        until [[ $(warp-cli --accept-tos status) =~ Connected ]]; do
            red "启动Warp-Cli代理模式失败，正在尝试重启"
            warp-cli --accept-tos disconnect >/dev/null 2>&1
            warp-cli --accept-tos connect >/dev/null 2>&1
            sleep 5
        done
        warp-cli --accept-tos enable-always-on >/dev/null 2>&1
        WARPCliPort=$(warp-cli --accept-tos settings 2>/dev/null | grep 'WarpProxy on port' | awk -F "port " '{print $2}')
        green "WARP-Cli代理模式启动成功！"
        yellow "本地Socks5代理为：127.0.0.1:$WARPCliPort"
        rm -f switch.sh
        exit 1
    fi
}

switch