#!/bin/bash

# 定义变量
MOSDNS_REPO="IrineSistiana/mosdns"
CONFIG_REPO="https://github.com/oppen321/Mosdns--Personal-configuration/archive/refs/heads/main.zip"
TMP_DIR=$(mktemp -d)

# 检测设备架构
ARCH=$(uname -m)
case "$ARCH" in
    x86_64)
        ARCH_SUFFIX="amd64"
        ;;
    armv7l)
        ARCH_SUFFIX="armv7"
        ;;
    aarch64)
        ARCH_SUFFIX="arm64"
        ;;
    *)
        echo "Unsupported architecture: $ARCH"
        exit 1
        ;;
esac

# 获取最新的 mosdns 发行版信息
LATEST_RELEASE=$(curl -s "https://api.github.com/repos/${MOSDNS_REPO}/releases/latest")
DOWNLOAD_URL=$(echo "$LATEST_RELEASE" | grep "browser_download_url" | grep "mosdns-linux-${ARCH_SUFFIX}.zip" | cut -d '"' -f 4)

if [ -z "$DOWNLOAD_URL" ]; then
    echo "No suitable mosdns release found for architecture $ARCH."
    exit 1
fi

# 下载 mosdns 发行版
MOSDNS_ARCHIVE="${TMP_DIR}/mosdns-linux-${ARCH_SUFFIX}.zip"
wget "$DOWNLOAD_URL" -O "$MOSDNS_ARCHIVE"

# 下载并解压配置文件
wget "$CONFIG_REPO" -O "${TMP_DIR}/config.zip"
unzip -o "${TMP_DIR}/config.zip" -d "${TMP_DIR}"

# 创建所需目录
mkdir -p /etc/mosdns
mkdir -p /var/mosdns
touch /var/disable-ads.txt

# 检测 53 端口并处理冲突
if lsof -i :53 >/dev/null; then
    echo "Port 53 is occupied. Stopping and disabling systemd-resolved.service..."
    systemctl stop systemd-resolved.service
    systemctl disable systemd-resolved.service
    # 再次检查 53 端口
    if lsof -i :53 >/dev/null; then
        echo "Port 53 is still occupied. Please check manually."
        exit 1
    fi
fi

# 解压 mosdns 发行版
unzip -o -d "${TMP_DIR}/mosdns" "$MOSDNS_ARCHIVE"

# 移动文件到正确目录并安装 mosdns
mv "${TMP_DIR}/mosdns/etc/*" /etc
mv "${TMP_DIR}/mosdns/var/*" /var
mosdns service install -d /usr/bin -c /etc/mosdns/config.yaml

# 启动 mosdns
mosdns service start

# 检测是否已经安装 mosdns
if command -v mosdns >/dev/null; then
    echo "mosdns is already installed. Choose an option:"
    echo "1. Start"
    echo "2. Enable auto-start"
    echo "3. Pause"
    echo "4. Remove"
    read -p "Enter your choice [1-4]: " choice
    case $choice in
        1) mosdns service start ;;
        2) systemctl enable mosdns.service ;;
        3) mosdns service stop ;;
        4) mosdns service remove ;;
        *) echo "Invalid choice." ;;
    esac
fi

# 清理临时目录
rm -rf "$TMP_DIR"
