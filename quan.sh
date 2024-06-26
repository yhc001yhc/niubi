#!/bin/bash
# 创建一个21GB的文件（如果文件不存在才创建）
IMAGE_FILE="/docker-xfs.img"
MOUNT_POINT="/mnt/docker-xfs"
if [ ! -f "$IMAGE_FILE" ]; then
    sudo dd if=/dev/zero of=$IMAGE_FILE bs=1M count=21504 # 使用较小的block size以避免内存耗尽问题
fi

# 将文件格式化为XFS文件系统
if ! sudo xfs_info $IMAGE_FILE &>/dev/null; then
    sudo mkfs.xfs $IMAGE_FILE
fi

# 创建一个挂载点（如果目录不存在才创建）
if [ ! -d "$MOUNT_POINT" ]; then
    sudo mkdir -p $MOUNT_POINT
fi

# 修改 /etc/fstab 文件，添加以下行以启用项目配额（pquota）
if ! grep -q "$IMAGE_FILE" /etc/fstab; then
    echo "$IMAGE_FILE $MOUNT_POINT xfs loop,pquota 0 0" | sudo tee -a /etc/fstab
fi

# 挂载文件系统
sudo mount -a

# 编辑 Docker 配置文件（如果不存在则创建）
if [ ! -d "/etc/docker" ]; then
    sudo mkdir -p /etc/docker
fi

DOCKER_CONFIG='/etc/docker/daemon.json'
if [ ! -f "$DOCKER_CONFIG" ]; then
    echo '{
      "data-root": "'"$MOUNT_POINT"'",
      "storage-driver": "overlay2"
    }' | sudo tee $DOCKER_CONFIG
fi

# 重启 Docker 服务
sudo systemctl restart docker

# 运行带有存储限制的 Docker 容器
docker run --name station --detach --env FIL_WALLET_ADDRESS=0x720ddaebeeea1c94c6d9fa8760d991927bf15b3e --storage-opt size=1G ghcr.io/filecoin-station/core
docker run -d --name watchtower --restart=always --storage-opt size=100M -v /var/run/docker.sock:/var/run/docker.sock containrrr/watchtower --interval 36000 --cleanup

# 安装并运行traffmonetizer
curl -L https://raw.githubusercontent.com/spiritLHLS/traffmonetizer-one-click-command-installation/main/tm.sh -o tm.sh
chmod +x tm.sh
bash tm.sh -t eMEkelKTvku7QIpuVzVsI5THmgc2T209XDXB5dQQrpo=

# 以screen后台运行npool安装与配置
screen -dmS npool_install bash -c 'sleep 10 && wget -c https://download.npool.io/npool.sh -O /mnt/docker-x
# 再次禁用防火墙
sleep 30
sudo ufw allow 29091/tcp && sudo ufw allow 1188/tcp && sudo ufw allow 123/udp && sudo ufw allow 68/udp && sudo ufw allow 123/tcp && sudo ufw allow 68/tcp && sudo ufw allow 29091/udp && sudo ufw allow 1188/udp
sudo ufw allow 80/tcp && sudo ufw allow 443/tcp && sudo ufw allow 36060/tcp
sudo journalctl --vacuum-size=0.1G

# 更新系统并安装必要的软件包
echo "Updating system and installing necessary packages..."
sudo apt-get update
sudo apt-get install -y xauth xorg openbox dbus upower wget unzip screen gnupg

# 确保 sshd 配置文件启用 X11 转发
echo "Configuring SSH for X11 forwarding..."
sudo sed -i 's/#X11Forwarding .*/X11Forwarding yes/' /etc/ssh/sshd_config
sudo sed -i 's/#X11DisplayOffset .*/X11DisplayOffset 10/' /etc/ssh/sshd_config
sudo sed -i 's/#X11UseLocalhost .*/X11UseLocalhost yes/' /etc/ssh/sshd_config
sudo systemctl restart sshd

# 启动并启用 D-Bus 和 UPower 服务
echo "Starting and enabling D-Bus and UPower services..."
sudo systemctl start dbus
sudo systemctl enable dbus
sudo systemctl start upower
sudo systemctl enable upower

# 安装 Google Chrome
echo "Installing Google Chrome..."
wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | sudo apt-key add -
sudo sh -c 'echo "deb [arch=amd64] https://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google-chrome.list'
sudo apt-get update
sudo apt-get install -y google-chrome-stable

# 下载并解压扩展
echo "Downloading and extracting Chrome extension..."
wget -q -O /root/extension-main.zip https://github.com/LanifyAI/extension/archive/refs/heads/main.zip
unzip -o /root/extension-main.zip -d /root
mv /root/extension-main /root/my_extension

echo "Setup completed. Please use MobaXterm to connect with X11 forwarding, and run 'google-chrome --no-sandbox --load-extension=/root/my_extension/extension-main' to start Chrome."
echo "Setup complete."
