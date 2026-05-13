#!/bin/bash
# 小佳记账 — 服务器一键部署脚本
# 在宝塔面板 → 终端 中粘贴运行

set -e
echo "=== 小佳记账 服务端部署 ==="

cd /root

# 1. 上传代码包到 /root/xiaojia_backend.tar.gz（通过宝塔面板 → 文件上传）
# 等待文件到达...
if [ ! -f xiaojia_backend.tar.gz ]; then
    echo "请先将 xiaojia_backend.tar.gz 上传到 /root/ 目录"
    exit 1
fi

# 2. 解压
tar -xzf xiaojia_backend.tar.gz -C /root/

# 3. 安装 Python 依赖
pip3 install fastapi uvicorn sqlalchemy pydantic python-jose passlib[bcrypt] python-multipart reportlab -i https://pypi.tuna.tsinghua.edu.cn/simple

# 4. 停止旧服务（如果存在）
systemctl stop xiaojia 2>/dev/null || true
kill $(lsof -t -i:8000) 2>/dev/null || true

# 5. 创建 systemd 服务
cat > /etc/systemd/system/xiaojia.service << 'SERVICE'
[Unit]
Description=小佳记账 API
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/root/backend
ExecStart=/usr/bin/python3 -m uvicorn app.main:app --host 127.0.0.1 --port 8000
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
SERVICE

systemctl daemon-reload
systemctl enable xiaojia
systemctl restart xiaojia

# 6. Nginx 配置（如果还没配）
if ! grep -q "114.55.138.55" /www/server/panel/vhost/nginx/*.conf 2>/dev/null; then
    echo "请在宝塔面板 → 网站 → 添加站点 → 配置反向代理到 http://127.0.0.1:8000"
fi

echo "=== 部署完成 ==="
curl -s http://127.0.0.1:8000/
