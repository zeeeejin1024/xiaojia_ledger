# 小佳记账 — 部署指南

## 1. 上传代码到服务器

```bash
# 在本地打包
cd D:\我的想法\xiaojia_ledger
tar -czf xiaojia_backend.tar.gz backend/

# 上传到服务器
scp xiaojia_backend.tar.gz root@114.55.138.55:/root/
```

## 2. 服务器安装依赖

```bash
ssh root@114.55.138.55

cd /root
tar -xzf xiaojia_backend.tar.gz

# 安装依赖（使用清华镜像加速）
pip install -r backend/requirements.txt -i https://pypi.tuna.tsinghua.edu.cn/simple
pip install reportlab -i https://pypi.tuna.tsinghua.edu.cn/simple

# 创建数据目录
mkdir -p /root/xiaojia_ledger/backend/data
```

## 3. 配置 systemd 服务

```bash
cp /root/xiaojia_ledger/deploy/xiaojia.service /etc/systemd/system/
systemctl daemon-reload
systemctl enable xiaojia
systemctl start xiaojia
systemctl status xiaojia
```

## 4. 配置 Nginx

```bash
# 如果使用宝塔面板：
# 在宝塔面板 → 网站 → 添加配置 → 粘贴 deploy/nginx.conf 内容

# 如果手动配置 Nginx：
cp /root/xiaojia_ledger/deploy/nginx.conf /etc/nginx/conf.d/xiaojia.conf
nginx -t
systemctl reload nginx
```

## 5. 验证

```bash
# 测试 API
curl http://114.55.138.55/
curl http://114.55.138.55/docs
curl -X POST http://114.55.138.55/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{"username":"test","password":"123456"}'
```

## 6. 更新与重启

```bash
# 上传新代码后
systemctl restart xiaojia
systemctl status xiaojia

# 查看日志
journalctl -u xiaojia -f
```

## 注意事项

- 服务器需要 Python 3.12+
- 使用 SQLite 作为数据库（无需安装 MySQL）
- Nginx 需要配置 CORS（已在 FastAPI 中处理）
- 防火墙需要开放 80 端口
