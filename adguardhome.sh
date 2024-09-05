#!/bin/bash

# 检测设备架构
ARCH=$(uname -m)
if [[ $ARCH == "x86_64" ]]; then
    ARCH="amd64"
elif [[ $ARCH == "aarch64" ]]; then
    ARCH="arm64"
elif [[ $ARCH == "armv7l" ]]; then
    ARCH="armv7"
else
    echo "Unsupported architecture: $ARCH"
    exit 1
fi

# 检查是否已安装 AdGuardHome
if command -v AdGuardHome >/dev/null 2>&1; then
    echo "AdGuardHome 已经安装。请选择以下操作："
    echo "1. 启动 AdGuardHome"
    echo "2. 停止 AdGuardHome"
    echo "3. 设置自启动"
    echo "4. 删除 AdGuardHome"
    read -p "请输入数字选择: " choice

    case $choice in
        1)
            sudo systemctl start AdGuardHome
            echo "AdGuardHome 已启动。"
            ;;
        2)
            sudo systemctl stop AdGuardHome
            echo "AdGuardHome 已停止。"
            ;;
        3)
            sudo systemctl enable AdGuardHome
            echo "AdGuardHome 已设置为开机自启。"
            ;;
        4)
            sudo systemctl stop AdGuardHome
            sudo systemctl disable AdGuardHome
            sudo rm -rf /opt/AdGuardHome /etc/systemd/system/AdGuardHome.service
            echo "AdGuardHome 已删除。"
            ;;
        *)
            echo "无效的选择。"
            ;;
    esac

    exit 0
fi

# 获取最新版本号
echo "正在获取 AdGuardHome 最新版本..."
LATEST_VERSION=$(curl -s https://api.github.com/repos/AdguardTeam/AdGuardHome/releases/latest | grep '"tag_name"' | sed -E 's/.*"([^"]+)".*/\1/')

if [ -z "$LATEST_VERSION" ]; then
    echo "无法获取最新版本信息。"
    exit 1
fi

echo "最新版本为: $LATEST_VERSION"

# 下载 AdGuardHome 对应版本
DOWNLOAD_URL="https://github.com/AdguardTeam/AdGuardHome/releases/download/${LATEST_VERSION}/AdGuardHome_linux_${ARCH}.tar.gz"

echo "正在下载 AdGuardHome..."
wget $DOWNLOAD_URL -O AdGuardHome.tar.gz

# 检查下载是否成功
if [ $? -ne 0 ]; then
    echo "下载失败，请检查网络连接或版本信息。"
    exit 1
fi

echo "解压 AdGuardHome..."
tar -zxf AdGuardHome.tar.gz -C /root
mv /root/AdGuardHome /root/adguardhome

# 进入 AdGuardHome 目录并安装
cd /root/adguardhome
sudo ./AdGuardHome -s install

# 清理下载的压缩文件
rm -f /root/AdGuardHome.tar.gz

echo "AdGuardHome 已成功安装并启动。您可以通过以下方式管理服务："
echo "sudo systemctl start AdGuardHome  # 启动"
echo "sudo systemctl stop AdGuardHome   # 停止"
echo "sudo systemctl enable AdGuardHome # 设置自启动"
