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

update_system() {
    echo "更新系统"
    # 备份sources.list文件
    echo "正在备份原有的 sources.list 文件，请稍候..."
    if [ -f "/etc/apt/sources.list" ]; then
        cp /etc/apt/sources.list /etc/apt/sources.list.bak
        if [ $? -eq 0 ]; then
            echo "原有 sources.list 文件已备份为 sources.list.bak。"
        else
            echo "警告：备份 sources.list 文件失败！"
            exit 1
        fi
    else
        echo "警告：未找到 sources.list 文件，跳过备份步骤。"
    fi

    # 更改sources.list内容
    echo "正在清除原有的 sources.list 内容并添加国内镜像源地址，请稍候..."
    rm -f /etc/apt/sources.list
    if [ $? -eq 0 ]; then
        echo 'deb https://mirrors.aliyun.com/debian/  bookworm main non-free non-free-firmware contrib\n' | tee /etc/apt/sources.list
        echo 'deb-src https://mirrors.aliyun.com/debian/  bookworm main non-free non-free-firmware contrib\n' | tee -a /etc/apt/sources.list
        echo 'deb https://mirrors.aliyun.com/debian-security/  bookworm-security main\n' | tee -a /etc/apt/sources.list
        echo 'deb-src https://mirrors.aliyun.com/debian-security/  bookworm-security main\n' | tee -a /etc/apt/sources.list
        echo 'deb https://mirrors.aliyun.com/debian/  bookworm-updates main non-free non-free-firmware contrib\n' | tee -a /etc/apt/sources.list
        echo 'deb-src https://mirrors.aliyun.com/debian/  bookworm-updates main non-free non-free-firmware contrib\n' | tee -a /etc/apt/sources.list
        echo 'deb https://mirrors.aliyun.com/debian/  bookworm-backports main non-free non-free-firmware contrib\n' | tee -a /etc/apt/sources.list
        echo 'deb-src https://mirrors.aliyun.com/debian/  bookworm-backports main non-free non-free-firmware contrib\n' | tee -a /etc/apt/sources.list

        if [ -f "/etc/apt/sources.list" ] && grep -q "mirrors.aliyun.com" /etc/apt/sources.list; then
            echo "已成功将国内镜像源地址添加到 sources.list。"
        else
            echo "警告：未能成功添加国内镜像源地址！"
            exit 1
        fi
    else
        echo "警告：清除 sources.list 文件内容失败！"
        exit 1
    fi
}

# 定义安装必要的软件包的函数
install_softwares() {
    echo "安装必要的软件包"
    # 更新软件包列表并升级系统
    echo "正在更新软件包列表并升级系统，请稍候..."
    apt update && apt -y upgrade
    if [ $? -eq 0 ]; then
        echo "软件包列表已更新且系统已成功升级。"
    else
        echo "警告：更新软件包列表或升级系统过程中发生错误！"
    fi

    # 安装curl、sudo、jq、procps
    echo "正在安装curl、sudo、jq、procps..."
    apt-get install -y curl sudo jq procps || {
        echo "安装软件包失败。"
        exit 1
    }

    # 检查curl是否安装成功
    if dpkg -s curl >/dev/null 2>&1; then
        echo "curl 已成功安装。"
    else
        echo "警告：curl 安装失败！"
    fi

    # 检查sudo是否安装成功
    if dpkg -s sudo >/dev/null 2>&1; then
        echo "sudo 已成功安装。"
    else
        echo "警告：sudo 安装失败！"
    fi

    # 检查jq是否安装成功
    if dpkg -s procps >/dev/null 2>&1; then
        echo "procps 已成功安装。"
    else
        echo "警告：procps 安装失败！"
    fi
}

# 定义安装CasaOS的函数
install_casaos() {
    echo "安装CasaOS"
    # 安装CasaOS（需确认用户选择）
    echo "正在安装CasaOS，请输入 y 或 Y 以继续..."
    read -p "是否继续安装CasaOS？[y/n]: " choice
    if [ "$choice" = "y" -o "$choice" = "Y" ]; then
        echo "开始安装CasaOS..."
        desired_path="./casaos_installer.sh"
        curl -fsSL https://play.cuse.eu.org/get_casaos.sh -o "$desired_path"
        echo "" >>"$desired_path"
        echo "exit 0" >>"$desired_path"
        if [ $? -eq 0 ]; then
            chmod +x "$desired_path"
            echo "CasaOS 安装脚本已下载并保存到 $desired_path。"
            echo "开始执行CasaOS安装脚本..."
            sudo bash "$desired_path" >>"./casaos_install.log" 2>&1
            if [ $? -eq 0 ]; then
                echo "CasaOS 安装脚本已成功执行。"
                echo "CasaOS 安装日志已保存到 ./casaos_install.log。"
            else
                echo "警告：执行 CasaOS 安装脚本时发生错误！查看 ./casaos_install.log 了解更多信息。"
            fi
        else
            echo "警告：下载 CasaOS 安装脚本时发生错误！"
            exit 1 # 添加错误处理，脚本终止
        fi
    else
        echo "用户取消安装CasaOS。"
    fi
}

# 定义配置IPv6的函数
configure_ipv6() {
    echo "配置IPv6"
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

# 为Docker设置代理
set_docker_proxy() {
    # 默认参数
    DEFAULT_PROXY="127.0.0.1:10809"
    DEFAULT_NO_PROXY="localhost,127.0.0.1,.example.com"

    echo -e "为Docker设置代理\n输入均为空则取消代理"

    # 获取用户输入的代理地址
    read -p "请输入 HTTP 代理地址 (例如 ${DEFAULT_PROXY}): " HTTP_PROXY
    HTTP_PROXY=${HTTP_PROXY:-""}

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

    # 询问是否重启 docker
    read -p "是否重启 docker 服务使其立即生效? (y/n): " choice
    case "$choice" in
    y | Y)
        sudo systemctl daemon-reload
        sudo systemctl restart docker
        echo "Docker 服务已重启."
        ;;
    *)
        echo "Docker 服务未重启."
        ;;
    esac
    read -s -n1 -p "按任意键继续... "
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
    while true; do
        echo "本脚本大部分操作基于 Debian 12 系统，搭配使用教程：https://post.smzdm.com/p/a607edoe/"
        echo ""
        echo "请选择以下功能："
        echo "1. 添加国内源"
        echo "2. 安装必要的软件包"
        echo "3. 安装CasaOS"
        echo "4. 配置IPv6"z
        echo "5. 禁用自动休眠"
        echo "6. 设置默认语言为中文"
        echo "7. 为Docker设置代理"
        echo "q. 退出"
        echo ""
        read -p "请输入功能序号: " input
        case $input in
        1) update_system ;;
        2) install_softwares ;;
        3) install_casaos ;;
        4) configure_ipv6 ;;
        5) disable_autosleep ;;
        6) set_locales ;;
        7) set_docker_proxy ;;
        'q') break ;;
        *) ;;
        esac
    done
fi
echo "脚本执行完毕"
