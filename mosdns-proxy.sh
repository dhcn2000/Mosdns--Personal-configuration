#!/bin/bash

# 检查 /usr/local/bin 目录下是否已经存在 Mosdns 文件
if [ ! -f /usr/local/bin/Mosdns ]; then
  echo "Mosdns 文件不存在，执行安装操作..."
  chmod +x /root/mosdns.sh
  sudo mv /root/mosdns.sh /usr/local/bin/Mosdns
else
  echo "Mosndns 文件已存在，跳过安装操作。"
fi

# 检测是否已经安装 mosdns
if command -v mosdns >/dev/null; then
    echo "mosdns is already installed. Choose an option:"
    echo "1. Start"
    echo "2. Enable auto-start"
    echo "3. Stop"
    echo "4. Remove"
    read -p "Enter your choice [1-4]: " choice
    case $choice in
        1)
            systemctl start mosdns.service
            echo "mosdns started."
            exit 0
            ;;
        2)
            systemctl enable mosdns.service
            echo "Auto-start enabled for mosdns."
            exit 0
            ;;
        3)
            systemctl stop mosdns.service
            echo "mosdns stopped."
            exit 0
            ;;
        4)  rm -rf /var/mosdns
            rm -rf /etc/mosdns
            rm -f /etc/systemd/system/mosdns.service
            rm -f /usr/bin/mosdns
            echo "mosdns removed."
            exit 0
            ;;
        *)
            echo "Invalid choice."
            exit 1
            ;;
    esac
fi

# 如果未安装，继续执行安装流程
echo "mosdns not detected. Proceeding with installation."

# 定义变量
MOSDNS_REPO="IrineSistiana/mosdns"
CONFIG_REPO="https://mirror.ghproxy.com/https://github.com/oppen321/Mosdns--Personal-configuration/archive/refs/heads/main.zip"
DOWNLOAD_DIR="/root"
MOSDNS_DIR="$DOWNLOAD_DIR/mosdns"
MOSDNS_EXEC="/usr/bin/mosdns"


# 创建下载目录
mkdir -p "$MOSDNS_DIR"

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
LATEST_RELEASE=$(curl -s "https://mirror.ghproxy.com/https://raw.githubusercontent.com/oppen321/Mosdns--Personal-configuration/main/mosdns.api")
DOWNLOAD_URL=$(echo "$LATEST_RELEASE" | grep "browser_download_url" | grep "mosdns-linux-${ARCH_SUFFIX}.zip" | cut -d '"' -f 4)

if [ -z "$DOWNLOAD_URL" ]; then
    echo "No suitable mosdns release found for architecture $ARCH."
    exit 1
fi

# 下载 mosdns 发行版到 /root
MOSDNS_ARCHIVE="${MOSDNS_DIR}/mosdns-linux-${ARCH_SUFFIX}.zip"
wget "$DOWNLOAD_URL" -O "$MOSDNS_ARCHIVE"

# 解压 mosdns 发行版到 /root/mosdns
unzip -o -d "$MOSDNS_DIR" "$MOSDNS_ARCHIVE"

# 将 mosdns 可执行文件移到 /usr/bin 并赋予执行权限
mv "$MOSDNS_DIR/mosdns" "$MOSDNS_EXEC"
chmod +x "$MOSDNS_EXEC"

# 下载并解压 Mosdns--Personal-configuration 配置文件到 /root
wget "$CONFIG_REPO" -O "${DOWNLOAD_DIR}/mosdns_config.zip"
unzip -o -d "$DOWNLOAD_DIR" "${DOWNLOAD_DIR}/mosdns_config.zip"

# 创建所需目录
mkdir -p /etc/mosdns
mkdir -p /var/mosdns

# 移动配置文件
mv "$DOWNLOAD_DIR/Mosdns--Personal-configuration-main/mosdns/etc/"* /etc
mv "$DOWNLOAD_DIR/Mosdns--Personal-configuration-main/mosdns/var/"* /var

# 安装并启动 mosdns 服务
mosdns service install -d /usr/bin -c /etc/mosdns/config.yaml
mosdns service start

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

# 启动 mosdns 服务
mosdns service start
echo "mosdns installed and started successfully."

# 清理临时文件
rm -rf "$DOWNLOAD_DIR/mosdns_config.zip"
