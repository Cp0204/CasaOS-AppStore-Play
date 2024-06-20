#!/usr/bin/bash

# 检查是否为root用户执行脚本
if [ "$(id -u)" != "0" ]; then
    echo "该脚本需要以 root 权限运行" 1>&2
    exit 1
fi

clear
echo '
   _____                 ____   _____   _   _               ____  _
  / ____|               / __ \ / ____| | \ | |             |  _ \(_)
 | |     __ _ ___  __ _| |  | | (___   |  \| | _____      _| |_) |_  ___
 | |    / _` / __|/ _` | |  | |\___ \  | . ` |/ _ \ \ /\ / /  _ <| |/ _ \
 | |___| (_| \__ \ (_| | |__| |____) | | |\  |  __/\ V  V /| |_) | |  __/
  \_____\__,_|___/\__,_|\____/|_____/  |_| \_|\___| \_/\_/ |____/|_|\___|

 By: 什么都不懂的臭弟弟, 猪哥哥, Cp0204 @ CasaOS Club

 欢迎使用 CasaOS 小白辅助脚本
 bash <(wget -qO- https://play.cuse.eu.org/casaos_newbie.sh)
'

chenge_linuxmirrors() {
    echo "> 更换系统软件源"
    bash <(curl -sSL https://linuxmirrors.cn/main.sh)
}

# 更新系统软件
update_softwares() {
    echo "> 更新系统软件"
    apt update && apt -y upgrade
    if [ $? -eq 0 ]; then
        echo "系统软件已更新。"
    else
        echo "警告：更新软件过程中发生错误！"
    fi

    # 定义需要安装的软件包数组
    packages=("sudo" "curl" "procps")

    # 检查是否有软件包需要安装
    need_install=false
    for package in "${packages[@]}"; do
        if ! dpkg -l | grep -q "^ii  $package"; then
            need_install=true
            break
        fi
    done

    # 询问用户安装软件包
    if $need_install; then
        echo "> 将安装以下常用软件包（如果尚未安装）"
        echo "- curl (用于网络传输)"
        echo "- sudo (用于管理权限)"
        echo "- procps (用于查看进程信息)"
        read -p "是否继续？(Y/n): " choice
        [[ -z "${INPUT}" ]] && INPUT=Y
        case "$choice" in
        [Yy] | [Yy][Ee][Ss])
            # 安装软件包，并对异常情况做出处理
            for package in "${packages[@]}"; do
                # 检查软件包是否已经安装
                if dpkg -l | grep -q "^ii  $package"; then
                    echo "$package 已安装，跳过"
                else
                    echo "正在安装 $package..."
                    apt-get install -y "$package"
                fi
            done
            # 检查软件包是否安装成功
            for package in "${packages[@]}"; do
                if dpkg -l | grep -q "^ii  $package"; then
                    echo "$package 已成功安装。"
                else
                    echo "警告：$package 安装失败！"
                fi
            done
            ;;
        n | N) exit 0 ;;
        *) echo "输入错误，请重新输入。" && update_softwares ;;
        esac
    else
        echo "> 所有常用软件包都已经安装。"
    fi
}

# 定义安装CasaOS的函数
install_casaos() {
    echo "> 安装CasaOS"
    # 安装CasaOS（需确认用户选择）
    read -p "将执行 CasaOS 安装脚本，是否继续？[Y/n]: " choice
    [[ -z "${choice}" ]] && choice=Y
    if [ "$choice" = "y" -o "$choice" = "Y" ]; then
        echo "开始安装CasaOS..."
        sudo bash -c "$(wget -qO- https://play.cuse.eu.org/get_casaos.sh)"
    else
        echo "取消安装CasaOS。"
    fi
}

# 定义配置IPv6的函数
configure_ipv6() {
    echo "> 配置IPv6"
    # 检查IPv6是否启用
    ipv6_enabled=$(/sbin/sysctl -n net.ipv6.conf.all.disable_ipv6)
    if [ "$ipv6_enabled" -ne 0 ]; then
        echo "IPv6 未启用，请检查网络配置。"
        exit 1
    fi
    # 获取NAS的IPv6地址段
    ipv6_subnet=$(ip -6 route show | grep -v "fe80" | /usr/bin/awk '{ print $1 }' | head -n 1)
    if [ -z "$ipv6_subnet" ]; then
        echo "未能获取到IPv6地址段，请手动指定。"
        exit 3
    fi
    echo "检测到IPv6地址段：$ipv6_subnet"
    # 编辑Docker配置文件的操作
    docker_config="/etc/docker/daemon.json"
    # 检查daemon.json文件是否存在，如果不存在则创建一个空的配置文件
    if [ ! -f "$docker_config" ]; then
        echo "{}" >$docker_config # 创建一个空的JSON文件
        echo "daemon.json不存在，已创建空文件。"
    fi
    # 备份原有配置文件，使用日期时间作为备份文件的一部分，以保留多个备份
    backup_file="${docker_config}-backup-$(date +'%Y-%m-%d_%H-%M-%S')"
    cp $docker_config $backup_file
    echo "已备份当前配置到$backup_file"
    # 更新配置
    echo "正在更新Docker的IPv6配置..."
    /usr/bin/jq '. + {ipv6: true, "fixed-cidr-v6": "'$ipv6_subnet'", experimental: true, ip6tables: true}' $docker_config >"${docker_config}.tmp" && mv "${docker_config}.tmp" $docker_config
    if [ $? -ne 0 ]; then
        echo "更新配置失败，请先确认是否已安装jq命令。"
        exit 4
    fi
    # 重启Docker服务，根据NAS的实际情况可能需要调整此命令
    echo "重启Docker服务..."
    sudo systemctl restart docker
    if [ $? -eq 0 ]; then
        echo "Docker服务重启成功。"
    else
        echo "Docker服务重启失败，请手动重启服务。"
        exit 5
    fi
    echo "配置完成，请执行 docker network inspect bridge 来确认 docker 配置。"
}

# 定义禁用自动休眠的函数
disable_autosleep() {
    echo "禁用自动休眠"
    # 提示用户是否禁用自动休眠
    read -p "您是否要禁用 Debian 系统的自动休眠功能？(y/n) " user_choice
    if [ "$user_choice" = "y" -o "$user_choice" = "Y" ]; then
        echo "正在禁用 Debian 系统的自动休眠功能，请稍候..."

        # 备份 /etc/systemd/logind.conf 文件
        sudo cp /etc/systemd/logind.conf /etc/systemd/logind.conf.bak
        if [ $? -eq 0 ]; then
            echo "文件已备份为 /etc/systemd/logind.conf.bak。"
        else
            echo "警告：备份 /etc/systemd/logind.conf 文件失败！"
        fi

        # 修改登录管理器配置以禁用自动休眠
        for config_line in 'HandleLidSwitch=ignore' 'HandleLidSwitchDocked=ignore' 'HandleLidSwitchExternalPower=ignore' 'IdleAction=ignore' 'IdleActionSec=0'; do
            echo $config_line | sudo tee -a /etc/systemd/logind.conf
        done
        if [ $? -eq 0 ]; then
            echo "登录管理器配置文件已成功修改。"

            # 验证配置生效
            for config_check in 'HandleLidSwitch=ignore' 'HandleLidSwitchDocked=ignore' 'HandleLidSwitchExternalPower=ignore' 'IdleAction=ignore' 'IdleActionSec=0'; do
                grep_result=$(grep -x "$config_check" /etc/systemd/logind.conf)
                if [ -z "$grep_result" ]; then
                    echo "警告：'$config_check' 配置未在 /etc/systemd/logind.conf 中找到，请手动检查文件内容。"
                fi
            done
        else
            echo "警告：修改登录管理器配置文件失败！"
        fi

        # 重启登录管理器服务以应用更改
        sudo systemctl restart systemd-logind
        if [ $? -eq 0 ]; then
            echo "登录管理器服务已成功重启，自动休眠功能已被禁用。"
        else
            echo "警告：重启登录管理器服务失败，自动休眠功能可能未被禁用。"
        fi
    else
        echo "自动休眠功能保持启用状态，如需禁用请重新运行此脚本并选择 y。"
    fi
}

# 设置默认语言为中文
set_locales() {
    # 更新软件包信息
    apt update
    # 安装语言包
    apt install -y locales
    # 配置中文环境
    sed -i '/zh_CN.UTF-8/s/^# //g' /etc/locale.gen
    locale-gen zh_CN.UTF-8
    # 设置默认语言为中文
    update-locale LANG=zh_CN.UTF-8
    echo "语言设置为中文已完成，可能需要重启系统。"
    read -p "您是否要重启系统？(y/n) " user_choice
    if [ "$user_choice" = "y" -o "$user_choice" = "Y" ]; then
        reboot
    else
        echo "已取消重启系统，如需重启请手动运行。"
    fi
}

# Docker网络优化
docker_network_optimization() {
    echo "> Docker网络优化"
    # 获取 Docker 当前设置
    docker_info=$(sudo docker info)
    http_proxy=$(echo "$docker_info" | grep 'HTTP Proxy' | awk -F ': ' '{print $2}')
    https_proxy=$(echo "$docker_info" | grep 'HTTPS Proxy' | awk -F ': ' '{print $2}')
    no_proxy=$(echo "$docker_info" | grep 'No Proxy' | awk -F ': ' '{print $2}')
    registry_mirrors=$(echo "$docker_info" | grep 'Registry Mirrors' -A 1 | tail -n 1 | sed 's/  //')
    echo "==========当前 Docker 设置=============="
    echo "代理:"
    echo "- HTTP Proxy: $http_proxy"
    echo "- HTTPS Proxy: $https_proxy"
    echo "- No Proxy: $no_proxy"
    echo ""
    echo "Docker Registry 源:"
    echo "- $registry_mirrors"
    echo "======================================="
    echo "请选择网络优化方式（二选一即可）："
    echo "1. 设置 Docker 代理"
    echo "2. 更换 Docker Registry 源"
    echo "q. 退出"

    read -p "选择: " choice
    case "$choice" in
    1)
        set_docker_proxy
        ;;
    2)
        switch_docker_source
        ;;
    "q")
        return
        ;;
    *)
        echo "未正确选择，退出"
        return
        ;;
    esac

    # 询问是否重启 docker
    if [ "$choice" = "1" -o "$choice" = "2" ]; then
        read -p "是否重启 docker 服务使其立即生效? (Y/n): " choice
        [[ -z "${choice}" ]] && choice=Y
        case "$choice" in
        [Yy] | [Yy][Ee][Ss])
            sudo systemctl restart docker
            echo "Docker 服务已重启."
            ;;
        *)
            echo "Docker 服务未重启."
            ;;
        esac
    fi
    read -s -n1 -p "按任意键继续... "
}

set_docker_proxy() {
    # 默认参数
    DEFAULT_PROXY="127.0.0.1:10809"
    DEFAULT_NO_PROXY="localhost,127.0.0.1,.example.com"

    echo -e "> 为Docker设置代理，输入均为空则取消代理，q退出"

    # 获取用户输入的代理地址
    read -p "请输入 HTTP 代理地址 (例如 ${DEFAULT_PROXY}): " HTTP_PROXY
    HTTP_PROXY=${HTTP_PROXY:-""}
    if [ "$HTTP_PROXY" = "q" ]; then
        return
    fi

    read -p "请输入 HTTPS 代理地址 (默认同 HTTP 代理 ${HTTP_PROXY}): " HTTPS_PROXY
    HTTPS_PROXY=${HTTPS_PROXY:-$HTTP_PROXY}

    read -p "请输入不代理的主机/域名，用逗号分隔 (默认 ${DEFAULT_NO_PROXY}): " NO_PROXY
    NO_PROXY=${NO_PROXY:-$DEFAULT_NO_PROXY}

    # 判断是否需要取消代理
    if [ -z "$HTTP_PROXY" ] && [ -z "$HTTPS_PROXY" ]; then
        sudo rm -f /etc/systemd/system/docker.service.d/proxy.conf
        echo "已取消 Docker 代理设置."
    else
        sudo mkdir -p /etc/systemd/system/docker.service.d
        echo "[Service]
Environment=\"HTTP_PROXY=http://$HTTP_PROXY\"
Environment=\"HTTPS_PROXY=http://$HTTPS_PROXY\"
Environment=\"NO_PROXY=$NO_PROXY\"" | sudo tee /etc/systemd/system/docker.service.d/proxy.conf
        echo "已更新 Docker 代理设置:"
        echo "  - HTTP_PROXY:  $HTTP_PROXY"
        echo "  - HTTPS_PROXY: $HTTPS_PROXY"
        echo "  - NO_PROXY:    $NO_PROXY"
    fi
    sudo systemctl daemon-reload
}

switch_docker_source() {
    echo "> 切换Docker镜像源"
    # bash <(curl -sSL https://linuxmirrors.cn/docker.sh)
    bash <(curl -sSL https://gitee.com/xjxjin/scripts/raw/main/check_docker_registry.sh)
}

disk_usage() {
    echo "> 磁盘使用情况分析"
    # 检查 gdu 命令是否存在。
    command -v gdu >/dev/null 2>&1 || {
        # 请求用户安装
        read -r -p "未找到 gdu 命令。是否要安装? [Y/n]" INPUT
        [[ -z "${INPUT}" ]] && INPUT=Y
        case "$INPUT" in
        [Yy] | [Yy][Ee][Ss])
            # 安装 gdu
            apt-get update && apt-get install -y gdu # Debian/Ubuntu
            # yum install -y gdu # CentOS/RHEL
            ;;
        *)
            echo "取消安装 gdu 无法分析"
            return 1
            ;;
        esac
    }
    # 输入分析的目录
    read -r -p "请输入要分析的目录(默认为/): " target_dir
    target_dir="${target_dir:-/}"
    # 使用 gdu 分析磁盘使用情况。
    gdu "$target_dir"
}

# 脚本入口
if [ $# -gt 0 ]; then
    # 如果有命令行参数，则直接执行对应的函数
    function_name="$1"
    echo "直接进入子功能 $function_name , 更多选项请运行以上命令"
    echo ">"
    shift
    $function_name "$@"
else
    echo ""
    echo "本脚本大部分操作基于 Debian 12 系统，搭配使用教程：https://post.smzdm.com/p/a607edoe"
    while true; do
        echo ""
        echo "请选择以下功能："
        echo "1. 更换系统软件源"
        echo "2. 更新系统软件"
        echo "3. 安装CasaOS(国内优化脚本)"
        echo "4. 配置IPv6"
        echo "5. 禁用自动休眠"
        echo "6. 设置系统语言为中文"
        echo "7. Docker网络优化"
        echo "8. 磁盘用量分析"
        echo "q. 退出"
        echo ""
        read -p "请输入功能序号: " input
        case $input in
        1) chenge_linuxmirrors ;;
        2) update_softwares ;;
        3) install_casaos ;;
        4) configure_ipv6 ;;
        5) disable_autosleep ;;
        6) set_locales ;;
        7) docker_network_optimization ;;
        8) disk_usage ;;
        'q') break ;;
        *) ;;
        esac
    done
fi
echo "脚本执行完毕"
