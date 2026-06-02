# 小满记账 MVP 设计规格

---

## MVP 一句话目标

> 一个能注册登录、记收支、看统计图、导出 CSV 的 Flutter App + FastAPI 后端。4 周可上架。

---

## MVP 不做

| 不做 | 理由 |
|------|------|
| AI 语音记账 | Phase 2 |
| 微信支付宝同步 | Phase 2 |
| 存钱目标模块 | Phase 2 |
| PDF/图片导出 | Phase 2 |
| 离线模式 (SQLite) | Phase 2 |
| 自定义分类 | Phase 2 |
| 预算功能 | Phase 2 |
| 手机号/微信登录 | Phase 2 |
| 推送通知 | Phase 3 |

---

## 1. 页面设计（7 页 + 2 弹层）

```
Splash ──► Login ──► Home ──┬──► Stats
                            ├──► Records
                            ├──► Settings
                            └──► Add Record (Sheet)
                                  Edit Record (Sheet)
```

### 1.1 闪屏页 (Splash)

```
        ┌──────────────────┐
        │                  │
        │   小 佳 记 账     │   ← 四个字逐字弹出动画
        │                  │
        │   每一笔，都算数   │   ← 副标题
        │                  │
        │  [ 开 始 使 用 ]  │   ← 按钮
        │      跳过          │   ← 小字
        └──────────────────┘
```

- 2.2 秒自动跳转（已看过则跳过）
- 点击「开始使用」立即跳转
- 首次显示，之后 `SharedPreferences` 标记跳过

### 1.2 登录/注册页 (Auth)

```
        ┌──────────────────┐
        │                  │
        │   欢迎回来        │   ← 登录时 / 创建账号（注册时）
        │                  │
        │  ┌────────────┐  │
        │  │  用户名     │  │
        │  └────────────┘  │
        │  ┌────────────┐  │
        │  │  密码       │  │
        │  └────────────┘  │
        │  ┌────────────┐  │   ← 注册时出现
        │  │  确认密码   │  │
        │  └────────────┘  │
        │  □ 记住我         │
        │                  │
        │  [  登  录  ]    │
        │                  │
        │  还没有账号？去注册│
        └──────────────────┘
```

- 登录/注册切换通过底部链接
- 校验：用户名 2-12 字符，密码 ≥6 位，两次密码一致
- 登录成功 → 跳转首页
- 保持旧网站的同款交互逻辑（可复用思路）

### 1.3 首页 (Home)

```
  ┌──────────────────────────┐
  │  小满记账        用户名   │  ← TopBar
  ├──────────────────────────┤
  │  ┌────────────────────┐  │
  │  │    本月结余          │  │
  │  │    ¥ 2,580.00      │  │  ← 大号金额（数字滚动动画）
  │  │  收入 ¥8000         │  │
  │  │  ████████░░ 支出 ¥5420│  │  ← 比例条
  │  └────────────────────┘  │
  │                          │
  │  ┌──────┐  ┌──────┐     │
  │  │ 📈   │  │ 📉   │     │  ← 快捷卡片
  │  │ 收入  │  │ 支出  │     │     点击查看饼图
  │  │ ¥8000│  │ ¥5420│     │
  │  └──────┘  └──────┘     │
  │                          │
  │  最近流水          查看全部│
  │  🍽️ 正餐     -¥22.00     │
  │  🚇 地铁公交  -¥4.00      │  ← 最近 5 条
  │  💼 工资     +¥8000.00    │
  │  ...                     │
  │                          │
  │              [ + 记一笔 ] │  ← FAB 按钮
  └──────────────────────────┘
```

- 底部导航栏：首页 / 统计 / 流水 / 设置（4 个 tab）
- 点击收入/支出卡片 → 弹出该类型的分类饼图详情
- FAB → 弹出记一笔底部弹层

### 1.4 记一笔弹层 (Add Record Sheet)

```
  ┌──────────────────────────┐
  │  ━━━━━━━━━━━━━━━━━━━━━━  │  ← 拖拽手柄
  │        记一笔              │
  │                          │
  │  [ 支出 ] [ 收入 ] [ 存钱 ]│  ← 类型切换
  │                          │
  │  ┌────────────────────┐  │
  │  │ 🔍 搜索分类...      │  │  ← 搜索框
  │  └────────────────────┘  │
  │                          │
  │  🍽️正餐  🥐早餐  🍿零食  │
  │  🧋奶茶  🍎水果  🌙宵夜  │  ← 分类网格（3列）
  │  🛵外卖  🍞面包  ...    │     点击高亮选中
  │                          │
  │  ┌────────────────────┐  │
  │  │       22.00        │  │  ← 金额（大字等宽）
  │  └────────────────────┘  │
  │  ┌────────────────────┐  │
  │  │  2026-05-11        │  │  ← 日期选择
  │  └────────────────────┘  │
  │  ┌────────────────────┐  │
  │  │  备注（可选）       │  │
  │  └────────────────────┘  │
  │                          │
  │  [       保  存        ] │
  └──────────────────────────┘
```

- 默认选中「支出」类型
- 分类按使用频率排序（常用置顶）
- 金额输入支持小数点
- 日期默认今天
- 必填：金额 > 0、选择了分类
- 保存成功 → Toast + 关闭弹层 + 首页刷新

### 1.5 统计页 (Stats)

```
  ┌──────────────────────────┐
  │  [ 月度 ]  [ 年度 ]       │  ← Tab 切换
  ├──────────────────────────┤
  │  ◀  2026年5月  ▶         │
  │                          │
  │  收入 ¥8000  支出 ¥5420  │  ← 汇总数字
  │  存钱 ¥2000  结余 ¥580   │
  │                          │
  │  收入 ████████████ 8000  │  ← 柱状图
  │  支出 ████████     5420  │     (水平条)
  │  存钱 ████         2000  │
  │                          │
  │  ┌──────┐  ┌──────┐     │
  │  │收入分布│  │支出分布│     │  ← 两个饼图
  │  │  🍽️ 30%│  │ 🍽️ 40%│     │
  │  │  🚇 20%│  │ 🚇 15%│     │
  │  │  ...   │  │  ...   │     │
  │  └──────┘  └──────┘     │
  └──────────────────────────┘
```

- 月度 Tab：当月柱状图 + 收入/支出双饼图 + 图例
- 年度 Tab：12 个月柱状图（收支对比），点击某月可展开月详情
- 图表库：`fl_chart`

### 1.6 流水页 (Records)

```
  ┌──────────────────────────┐
  │  [筛选 ▼]                │
  │  ┌────────────────────┐  │
  │  │类型[全部] 分类[全部]│  │  ← 展开的筛选面板
  │  │日期[从] [到]       │  │
  │  │[筛选] [清除]       │  │
  │  └────────────────────┘  │
  │                          │
  │  2026-05-10              │  ← 日期分组
  │  🍽️ 正餐          -22.00 │
  │  🚇 地铁公交       -4.00 │  ← 点击编辑
  │                          │     长按删除
  │  2026-05-09              │
  │  💼 工资         +8000.00│
  │  🧋 奶茶咖啡     -15.00  │
  │  ...                     │
  │                          │
  │  暂无记录   📭            │  ← 空状态
  └──────────────────────────┘
```

- 按日期倒序分组
- 每条显示：emoji + 分类名 + 日期备注 + 金额（收入绿色带+，支出默认色带-）
- 点击 → 编辑弹层
- 长按 → 确认删除
- 筛选：类型下拉 + 分类下拉 + 日期范围

### 1.7 设置页 (Settings)

```
  ┌──────────────────────────┐
  │  当前用户：江泽锦          │
  ├──────────────────────────┤
  │  背景底色  ○○○○○         │  ← 5 个颜色圆
  │  导出 CSV                │  ← 点击下载
  │  切换账号                │  ← 退出登录
  │  清空我的所有数据         │  ← 红色，双重确认
  │  小满记账 v1.0.0         │  ← 版本号
  └──────────────────────────┘
```

---

## 2. API 设计（共 12 个接口）

### 2.1 认证

| 方法 | 路径 | 请求 | 响应 |
|------|------|------|------|
| POST | `/api/v1/auth/register` | `{username, password}` | `{code, data: {username, token}}` |
| POST | `/api/v1/auth/login` | `{username, password}` | `{code, data: {username, token}}` |
| GET | `/api/v1/auth/me` | — | `{code, data: {username}}` |

### 2.2 记录

| 方法 | 路径 | 请求 | 响应 |
|------|------|------|------|
| GET | `/api/v1/records` | `?month=YYYY-MM` | `{code, data: [Record]}` |
| POST | `/api/v1/records` | `{type, amount, category_id, date, note}` | `{code, data: Record}` |
| PUT | `/api/v1/records/{id}` | `{field, value}` | `{code}` |
| DELETE | `/api/v1/records/{id}` | — | `{code}` |

### 2.3 分类

| 方法 | 路径 | 请求 | 响应 |
|------|------|------|------|
| GET | `/api/v1/categories` | — | `{code, data: [CategoryTree]}` |

### 2.4 统计

| 方法 | 路径 | 请求 | 响应 |
|------|------|------|------|
| GET | `/api/v1/stats/monthly` | `?month=YYYY-MM` | `{code, data: MonthlyStats}` |
| GET | `/api/v1/stats/yearly` | `?year=YYYY` | `{code, data: YearlyStats}` |

### 2.5 导出

| 方法 | 路径 | 请求 | 响应 |
|------|------|------|------|
| GET | `/api/v1/export/csv` | `?month=YYYY-MM` | CSV 文件流 |

### 统一响应格式

```json
{
  "code": 0,
  "message": "ok",
  "data": { ... }
}
```

| code | 含义 |
|------|------|
| 0 | 成功 |
| 400 | 参数错误 |
| 401 | 未登录 / Token 过期 |
| 409 | 冲突（如用户名已存在） |
| 500 | 服务器错误 |

---

## 3. 数据模型（MVP 精简版）

### 3.1 数据库表

```
users
├── id           INT PK AUTO_INCREMENT
├── username     VARCHAR(24) UNIQUE NOT NULL
├── password_hash VARCHAR(255) NOT NULL
├── created_at   DATETIME DEFAULT NOW()

categories
├── id           INT PK AUTO_INCREMENT
├── parent_id    INT NULL (FK → categories.id)
├── name         VARCHAR(50) NOT NULL
├── type         ENUM('income','expense','savings')
├── emoji        VARCHAR(10)
├── sort_order   INT DEFAULT 0

records
├── id           INT PK AUTO_INCREMENT
├── user_id      INT FK → users.id (INDEX)
├── type         ENUM('income','expense','savings')
├── amount       DECIMAL(12,2)
├── category_id  INT FK → categories.id
├── date         DATE (INDEX: user_id + date)
├── note         VARCHAR(200)
├── created_at   DATETIME DEFAULT NOW()
```

### 3.2 分类种子数据（MVP 预设 60 个）

```
支出 (11个大类, 51个子类)
├── 餐饮: 早餐, 午餐, 晚餐, 宵夜, 零食, 奶茶咖啡, 水果, 外卖, 烘焙面包
├── 交通: 地铁公交, 打车, 加油, 停车, 高铁火车, 飞机, 共享单车
├── 购物: 衣服鞋帽, 化妆品护肤, 电子产品, 家居日用, 书籍文具, 超市杂货
├── 娱乐: 电影演出, 游戏氪金, KTV聚会, 旅行旅游, 运动健身, 桌游密室
├── 居住: 房租, 水电燃气, 物业, 网费话费, 维修家装, 保洁清洁
├── 学习: 课程培训, 考试报名, 资料打印
├── 医疗: 看病门诊, 买药, 体检, 牙科眼科
├── 人情: 送礼红包, 婚礼份子, 聚餐AA
├── 宠物: 宠物粮食, 宠物医疗, 宠物用品
├── 生活服务: 理发造型, 按摩SPA, 快递物流, 会员订阅
└── 其他支出

收入 (1个大类, 9个子类)
└── 收入来源: 工资, 奖金年终, 兼职接单, 理财收益, 红包收入, 退款报销, 二手出售, 房租收入, 其他收入

存钱 (1个大类, 7个子类)
└── 储蓄方式: 定期存款, 活期储蓄, 基金定投, 股票投资, 目标储蓄, 应急金, 其他存钱
```

---

## 4. Flutter 组件树

```
MaterialApp
├── SplashPage
├── AuthPage (Login / Register)
└── MainShell (Scaffold + BottomNavigationBar)
    ├── HomePage
    │   ├── BalanceCard
    │   ├── IncomeExpenseBar
    │   ├── QuickCards (IncomeCard, ExpenseCard)
    │   ├── RecentRecords (5 items)
    │   └── FAB → AddRecordSheet
    ├── StatsPage
    │   ├── TabBar (月度 / 年度)
    │   ├── MonthStatsTab
    │   │   ├── MonthNav (◀ 月份 ▶)
    │   │   ├── StatsSummary (收入/支出/结余)
    │   │   ├── BarChart (月度柱状图)
    │   │   ├── PieChart (收入分布)
    │   │   └── PieChart (支出分布)
    │   └── YearStatsTab
    │       ├── YearNav (◀ 年份 ▶)
    │       ├── StatsSummary
    │       └── YearlyBarChart (12月柱状图)
    ├── RecordsPage
    │   ├── FilterPanel (类型/分类/日期)
    │   └── DateGroupedList
    └── SettingsPage
        ├── CurrentUser
        ├── ThemePicker (5色)
        ├── ExportCSV
        ├── SwitchAccount
        └── ClearData
```

---

## 5. 数据流

```
┌──── Widget ────┐     ┌── Provider ────┐     ┌── ApiClient ──┐
│                 │     │                 │     │                │
│ BalanceCard     │◄────│ HomeProvider    │────►│ AuthApi        │
│ RecentRecords   │     │ .balance        │     │ RecordApi      │
│ QuickCards      │     │ .recentRecords  │     │ StatsApi       │
│                 │     │ .fetchMonth()   │     │ CategoryApi    │
└─────────────────┘     └─────────────────┘     │ ExportApi      │
                                                └───────┬────────┘
                                                        │
                                              ┌─────────▼────────┐
                                              │   Dio Instance   │
                                              │   Base URL       │
                                              │   JWT 拦截器      │
                                              │   错误统一处理     │
                                              └──────────────────┘
```

- **Widget**：纯 UI，从 Provider 读数据，不直接调 API
- **Provider**：持有状态，调用 ApiClient，通知 Widget 刷新
- **ApiClient**：Dio 封装，自动带 Token，自动处理 401

---

## 6. W1-W4 任务分解

### W1：基建 + 认证

```
□ 后端 FastAPI 骨架 (main.py, config.py, database.py)
□ models: User, Category (种子数据)
□ core: JWT (security.py), 依赖注入 (deps.py)
□ API: POST /auth/register, POST /auth/login, GET /auth/me
□ Flutter 项目初始化 (main.dart, theme.dart, router.dart)
□ ApiClient (Dio + JWT 拦截器)
□ AuthPage (登录/注册 UI)
□ SplashPage
```

### W2：记账核心

```
□ models: Record
□ schemas: RecordCreate, RecordOut
□ API: CRUD /records
□ API: GET /categories
□ CategoryPicker 组件（3 列网格 + emoji + 搜索）
□ AddRecordSheet（类型切换 + 分类选择 + 金额 + 日期 + 备注）
□ RecordsPage（日期分组列表）
□ EditRecordSheet（编辑弹层 + 删除）
□ FilterPanel（类型/分类/日期筛选）
```

### W3：统计 + 首页

```
□ Service: stats_service.py (聚合计算)
□ API: GET /stats/monthly, GET /stats/yearly
□ BalanceCard（月结余 + 数字动画）
□ IncomeExpenseBar（比例条）
□ QuickCards（收入/支出点击看饼图）
□ RecentRecords（最近 5 条）
□ MonthStatsTab（柱状图 + 双饼图）
□ YearStatsTab（12 月柱状图，点击看月详情）
□ HomePage 组装
```

### W4：导出 + 收尾

```
□ API: GET /export/csv
□ SettingsPage（主题切换 + 导出 + 清空数据 + 退出）
□ 共享组件（Toast, SkeletonLoader, EmptyState, AmountText）
□ BottomNavigationBar + 路由完善
□ Bug 修复 + 真机测试
□ App 图标 + 启动图
□ 打包：flutter build apk --release
```

---

*文档版本: v1.0 | 创建日期: 2026-05-11*
