# 小满记账 (XiaoMan Ledger)

一个面向学生和年轻上班族的智能记账 App，支持 AI 语音记账，截屏记账、微信/支付宝账单同步、多维度存钱管理。

## 技术栈

| 层 | 技术 |
|----|------|
| 移动端 | Flutter 3.41+ (Dart) |
| 后端 | FastAPI (Python 3.12) |
| 数据库 | MySQL 8.0 + Redis |
| 语音识别 | 讯飞语音 SDK |
| AI 引擎 | 本地 NLP 规则 + DeepSeek API |
| 平台 | iOS / Android |

## 项目结构

```
xiaojia_ledger/
├── backend/          # FastAPI 后端服务
├── frontend/         # Flutter 移动端
├── docs/             # 项目文档
│   ├── PRD.md        # 产品需求文档
│   └── ARCHITECTURE.md  # 架构设计文档
└── deploy/           # 部署配置
```

## 快速开始

### 环境要求
- Flutter SDK 3.41+
- Python 3.12+
- MySQL 8.0

### 启动后端

```bash
cd backend
python -m venv venv
source venv/bin/activate  # Windows: venv\Scripts\activate
pip install -r requirements.txt
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

API 文档自动生成：`http://localhost:8000/docs`

### 启动前端

```bash
cd frontend
flutter pub get
flutter run
```

### 打包发布

```bash
# Android
flutter build apk --release

# iOS
flutter build ios --release
```

## 相关文档

- [产品需求文档 (PRD)](docs/PRD.md)
- [架构设计文档](docs/ARCHITECTURE.md)
- [API 接口文档](http://localhost:8000/docs)（启动后端后访问）

## 开发计划

- [x] 环境搭建 & 项目初始化
- [ ] Phase 1: MVP（基础记账 + 统计 + 导出）
- [ ] Phase 2: AI 语音 + 支付同步
- [ ] Phase 3: 商业化 & 上架

## License

Copyright 2026 江泽锦. All rights reserved.
