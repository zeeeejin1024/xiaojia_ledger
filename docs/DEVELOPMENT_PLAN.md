# 小满记账 v2.0 — 开发计划

---

## 总览

```
Phase 1 (4周)         Phase 2 (4周)         Phase 3 (2周)
    MVP                  AI + 同步              商业化
┌─────────────┐    ┌─────────────────┐    ┌──────────────┐
│后端基础      │    │语音记账          │    │会员系统       │
│Flutter 前端  │───►│微信支付宝同步     │───►│应用内购买     │
│注册登录      │    │PDF/图片导出      │    │广告接入       │
│记账增删改查  │    │存钱目标功能      │    │上架应用商城   │
│分类 + 统计   │    │                 │    │              │
│CSV 导出      │    │                 │    │              │
└─────────────┘    └─────────────────┘    └──────────────┘
     可上架              完整版                 开始盈利
```

---

## Phase 1: MVP（4 周）

> 目标：一个能记账、看统计、导出 CSV 的最小可用 App，可以上架测试。

### W1: 项目基建 + 认证

| # | 任务 | 文件 | 预计 |
|---|------|------|------|
| 1.1 | 后端项目初始化 | `backend/app/main.py`, `config.py` | 0.5d |
| 1.2 | 数据库模型：User、Category | `backend/app/models/user.py`, `category.py` | 0.5d |
| 1.3 | Core：JWT + 密码哈希 | `backend/app/core/security.py`, `deps.py` | 1d |
| 1.4 | 注册/登录 API | `backend/app/api/auth.py` | 1d |
| 1.5 | Flutter 项目初始化 + 主题 + 路由 | `frontend/lib/main.dart`, `app.dart`, `core/` | 1d |
| 1.6 | 登录/注册页面 | `frontend/lib/modules/auth/` | 1d |
| 1.7 | ApiClient + JWT 拦截器 | `frontend/lib/data/api/api_client.dart` | 1d |

**验收**：能注册新用户 → 登录 → 拿到 Token → 进入空白首页

### W2: 记账核心

| # | 任务 | 文件 | 预计 |
|---|------|------|------|
| 2.1 | 预设分类种子数据 | `backend/app/models/category.py` (seed) | 0.5d |
| 2.2 | 分类 API（获取分类树） | `backend/app/api/categories.py` | 0.5d |
| 2.3 | Record 模型 + Schema | `backend/app/models/record.py`, `schemas/record.py` | 0.5d |
| 2.4 | 记账 CRUD API | `backend/app/api/records.py`, `services/record_service.py` | 1d |
| 2.5 | 添加记账页面（类型切换 + 分类选择 + 金额 + 日期 + 备注） | `frontend/lib/modules/record/add_record_page.dart` | 2d |
| 2.6 | 流水列表页（按日期分组 + 筛选面板） | `frontend/lib/modules/record/records_list_page.dart` | 1.5d |
| 2.7 | 编辑/删除记录 | `frontend/lib/modules/record/edit_record_page.dart` | 1d |

**验收**：能添加/编辑/删除/查看记录，分类显示 emoji，筛选能正常过滤

### W3: 统计 + 首页

| # | 任务 | 文件 | 预计 |
|---|------|------|------|
| 3.1 | 月度/年度统计 Service | `backend/app/services/stats_service.py` | 1d |
| 3.2 | 统计 API（月度汇总、年度汇总、分类排行） | `backend/app/api/stats.py` | 0.5d |
| 3.3 | 首页仪表盘（月结余卡片 + 收支条 + 最近流水） | `frontend/lib/modules/home/` | 1.5d |
| 3.4 | 月度统计页（柱状图 + 饼图） | `frontend/lib/modules/stats/` | 2d |
| 3.5 | 年度统计页（12 月柱状图） | `frontend/lib/modules/stats/` | 1d |
| 3.6 | 分类排行统计 | `frontend/lib/modules/stats/widgets/category_ranking.dart` | 0.5d |

**验收**：首页显示月度资产和最近流水，统计页有柱状图和饼图，月度/年度切换正常

### W4: 导出 + 设置 + 收尾

| # | 任务 | 文件 | 预计 |
|---|------|------|------|
| 4.1 | CSV 导出 API | `backend/app/services/export_service.py`, `api/export.py` | 0.5d |
| 4.2 | 导出页面（选择格式 + 范围 + 下载） | `frontend/lib/modules/export/` | 1d |
| 4.3 | 设置页（主题切换 + 用户名 + 版本号） | `frontend/lib/modules/settings/` | 0.5d |
| 4.4 | 底部导航 + 路由完善 | `frontend/lib/core/router.dart` | 0.5d |
| 4.5 | 全局空状态 + Toast + 骨架屏 | `frontend/lib/shared/widgets/` | 0.5d |
| 4.6 | Bug 修复 + 打包测试 | — | 2d |
| 4.7 | App 图标 + 启动图制作 | `assets/` | 1d |

**验收**：所有页面正常流转，能导出 CSV，主题能切换，可打包 APK 安装到手机

---

## Phase 2: AI + 同步（4 周）

> 目标：拥有语音记账、支付同步、存钱目标三个差异化功能。

### W5-6: AI 语音记账

| # | 任务 | 说明 |
|---|------|------|
| 5.1 | 接入讯飞语音 SDK | Android/iOS 配置 |
| 5.2 | 语音录入页面 | 麦克风按钮 + 波形动画 |
| 5.3 | NLP 解析引擎 | 本地规则：金额提取、类型判断、分类匹配 |
| 5.4 | DeepSeek API 兜底 | 复杂语句交给大模型 |
| 5.5 | 识别结果确认页 | 用户可手动修改各字段 |

### W6-7: 支付同步

| # | 任务 | 说明 |
|---|------|------|
| 6.1 | 微信 CSV 解析器 | 解析微信账单导出格式 |
| 6.2 | 支付宝 CSV 解析器 | 解析支付宝账单导出格式 |
| 6.3 | 商户名 → 分类映射表 | "美团"→外卖，"滴滴"→打车，200+ 规则 |
| 6.4 | 去重合并逻辑 | 按日期+金额+商户名去重 |
| 6.5 | 导入预览页面 | 展示匹配结果，用户修正 |
| 6.6 | 同步记录日志 | SyncLog 表记录每次导入 |

### W7-8: 存钱目标 + 增强导出

| # | 任务 | 说明 |
|---|------|------|
| 7.1 | SavingsGoal 模型 + CRUD API | 创建/编辑/删除目标 |
| 7.2 | 存钱页面（目标卡片 + 进度条） | 带动画过渡 |
| 7.3 | 自动存钱规则 | 每日固定/凑整存/按周月 |
| 7.4 | 存钱罐动画 | 存入时金币掉落效果 |
| 7.5 | PDF 导出（服务端渲染） | reportlab |
| 7.6 | 图片导出（月度账单卡片） | 前端渲染 + 截图 |

---

## Phase 3: 商业化（2 周）

> 目标：可以开始产生收入的完整产品。

| # | 任务 | 说明 |
|---|------|------|
| 8.1 | 会员等级设计 | 免费版/高级版/家庭版 |
| 8.2 | Google Play Billing 接入 | Android 内购 |
| 8.3 | App Store IAP 接入 | iOS 内购 |
| 8.4 | 广告位预留（AdMob） | 免费用户插屏广告 |
| 8.5 | 崩溃监控（Sentry） | 接入 + 上报 |
| 8.6 | 推送通知（FCM） | 每日记账提醒、超预算告警 |
| 8.7 | 隐私政策页 + 用户协议页 | 上架必备 |
| 8.8 | 应用商店截图 + 描述文案 | 各尺寸截图 |

---

## Phase 4: 持续迭代（长期）

| 功能 | 优先级 |
|------|--------|
| 华为/小米/Apple Wallet 适配 | P2 |
| Web 管理后台 | P2 |
| Windows/Mac 桌面端 | P3 |
| 家庭共享记账 | P3 |
| 外币支持 | P3 |
| 多人协作记账（室友聚餐 AA） | P3 |

---

## 当前进度

| Phase | 状态 | 开始 | 完成 |
|-------|------|------|------|
| Phase 1 MVP | ⏳ 进行中 | 2026-05-11 | — |
| Phase 2 AI+Sync | ⏳ 待开始 | — | — |
| Phase 3 商业化 | ⏳ 待开始 | — | — |

---

*文档版本: v1.0 | 最后更新: 2026-05-11*
