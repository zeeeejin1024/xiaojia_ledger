# 小满记账 v2.0 — 架构设计文档

---

## 1. 设计原则

| 原则 | 说明 |
|------|------|
| **轻量优先** | 不引入微服务、消息队列等重组件，一个人能维护 |
| **分层清晰** | 每一层只做一件事，改 UI 不动数据，改数据不动 UI |
| **先跑通再优化** | MVP 阶段 SQLite 够用就不上 MySQL，等用户量上来再迁移 |
| **组件复用** | 按钮、卡片、表单等统一风格，改一处全局生效 |

---

## 2. 项目目录结构

```
D:\我的想法\xiaojia_ledger\
├── backend/                          # FastAPI 后端
│   ├── app/
│   │   ├── __init__.py
│   │   ├── main.py                   # FastAPI 入口 + 中间件挂载
│   │   ├── config.py                 # 环境配置（dev/prod）
│   │   ├── core/
│   │   │   ├── __init__.py
│   │   │   ├── security.py           # JWT 生成/校验、密码哈希
│   │   │   ├── database.py           # SQLAlchemy 引擎 + Session 工厂
│   │   │   └── deps.py               # 依赖注入（get_db, get_current_user）
│   │   ├── models/                   # 数据模型（SQLAlchemy ORM）
│   │   │   ├── __init__.py
│   │   │   ├── user.py
│   │   │   ├── record.py
│   │   │   ├── category.py
│   │   │   ├── savings_goal.py
│   │   │   └── sync_log.py
│   │   ├── schemas/                  # Pydantic 请求/响应模型
│   │   │   ├── __init__.py
│   │   │   ├── user.py
│   │   │   ├── record.py
│   │   │   ├── category.py
│   │   │   ├── savings.py
│   │   │   └── common.py             # 统一响应格式 {code, message, data}
│   │   ├── api/                      # 路由模块（按功能拆分）
│   │   │   ├── __init__.py
│   │   │   ├── router.py             # 汇总所有路由
│   │   │   ├── auth.py               # 注册、登录、刷新Token
│   │   │   ├── records.py            # 记账 CRUD + 筛选查询
│   │   │   ├── categories.py         # 分类获取 + 自定义
│   │   │   ├── savings.py            # 存钱目标 + 自动规则
│   │   │   ├── stats.py              # 月度/年度/分类统计
│   │   │   ├── export.py             # CSV/PDF/JSON 导出
│   │   │   ├── ai.py                 # AI 语音解析
│   │   │   └── sync.py              # 微信/支付宝账单导入
│   │   └── services/                 # 业务逻辑层（与路由解耦）
│   │       ├── __init__.py
│   │       ├── auth_service.py
│   │       ├── record_service.py
│   │       ├── stats_service.py
│   │       ├── savings_service.py
│   │       ├── export_service.py
│   │       ├── ai_service.py
│   │       └── sync_service.py
│   ├── migrations/                   # Alembic 数据库迁移文件
│   ├── tests/                        # 测试
│   ├── requirements.txt
│   ├── alembic.ini
│   └── Dockerfile
│
├── frontend/                         # Flutter App
│   ├── lib/
│   │   ├── main.dart                 # 入口 + MaterialApp + 路由表
│   │   ├── app.dart                  # App Widget（主题、路由）
│   │   ├── core/
│   │   │   ├── theme.dart            # 主题数据（颜色、字体、圆角）
│   │   │   ├── router.dart           # 命名路由 + 路由守卫（未登录跳转）
│   │   │   ├── constants.dart        # 魔法值（分类常量、API 地址）
│   │   │   └── extensions.dart       # Dart 扩展方法（日期格式化等）
│   │   ├── data/
│   │   │   ├── api/
│   │   │   │   ├── api_client.dart   # Dio 单例（Base URL、拦截器、JWT 刷新）
│   │   │   │   ├── auth_api.dart     # 认证相关 API 调用
│   │   │   │   ├── record_api.dart   # 记账记录 API
│   │   │   │   ├── category_api.dart # 分类 API
│   │   │   │   ├── savings_api.dart  # 存钱 API
│   │   │   │   ├── stats_api.dart    # 统计 API
│   │   │   │   ├── export_api.dart   # 导出 API
│   │   │   │   └── ai_api.dart       # AI 语音 API
│   │   │   ├── local/
│   │   │   │   ├── database.dart     # SQLite 本地数据库（drift/sqflite）
│   │   │   │   └── preferences.dart  # SharedPreferences 封装
│   │   │   └── models/               # 数据模型（纯 Dart 类）
│   │   │       ├── record.dart
│   │   │       ├── category.dart
│   │   │       ├── user.dart
│   │   │       ├── savings_goal.dart
│   │   │       └── api_response.dart # 统一响应解析 {code, message, data}
│   │   ├── modules/                  # 功能模块（按 PRD 划分）
│   │   │   ├── auth/                 # 认证模块
│   │   │   │   ├── login_page.dart
│   │   │   │   └── register_page.dart
│   │   │   ├── home/                 # 首页仪表盘
│   │   │   │   ├── home_page.dart
│   │   │   │   ├── widgets/
│   │   │   │   │   ├── balance_card.dart       # 月结余卡片
│   │   │   │   │   ├── income_expense_bar.dart # 收支比例条
│   │   │   │   │   └── recent_records.dart     # 最近流水列表
│   │   │   │   └── providers/
│   │   │   │       └── home_provider.dart      # 首页状态管理
│   │   │   ├── record/               # 记账模块（核心）
│   │   │   │   ├── add_record_page.dart
│   │   │   │   ├── edit_record_page.dart
│   │   │   │   ├── records_list_page.dart
│   │   │   │   ├── widgets/
│   │   │   │   │   ├── type_switcher.dart      # 支出/收入/存钱 切换
│   │   │   │   │   ├── category_picker.dart    # 分类选择器（3级）
│   │   │   │   │   ├── amount_input.dart       # 金额输入（带计算器）
│   │   │   │   │   ├── date_picker.dart        # 日期选择
│   │   │   │   │   └── filter_panel.dart       # 筛选面板
│   │   │   │   └── providers/
│   │   │   │       └── record_provider.dart
│   │   │   ├── stats/                # 统计分析模块
│   │   │   │   ├── stats_page.dart
│   │   │   │   ├── widgets/
│   │   │   │   │   ├── monthly_chart.dart      # 月度柱状图
│   │   │   │   │   ├── yearly_chart.dart       # 年度柱状图
│   │   │   │   │   ├── category_pie_chart.dart # 分类饼图
│   │   │   │   │   └── trend_line_chart.dart   # 趋势折线图
│   │   │   │   └── providers/
│   │   │   │       └── stats_provider.dart
│   │   │   ├── savings/              # 存钱模块
│   │   │   │   ├── savings_page.dart
│   │   │   │   ├── goal_detail_page.dart
│   │   │   │   ├── widgets/
│   │   │   │   │   ├── goal_card.dart          # 目标进度卡片
│   │   │   │   │   ├── auto_rule_card.dart     # 自动存钱规则
│   │   │   │   │   └── coin_animation.dart     # 存钱动画
│   │   │   │   └── providers/
│   │   │   │       └── savings_provider.dart
│   │   │   ├── voice/                # AI 语音记账模块
│   │   │   │   ├── voice_input_page.dart
│   │   │   │   ├── widgets/
│   │   │   │   │   ├── wave_animation.dart     # 录音波形动画
│   │   │   │   │   └── result_confirm.dart     # AI 识别结果确认
│   │   │   │   └── providers/
│   │   │   │       └── voice_provider.dart
│   │   │   ├── export/               # 数据导出模块
│   │   │   │   ├── export_page.dart
│   │   │   │   └── widgets/
│   │   │   │       └── export_options.dart
│   │   │   ├── sync/                 # 账单同步模块
│   │   │   │   ├── sync_page.dart
│   │   │   │   ├── widgets/
│   │   │   │   │   ├── wechat_import.dart
│   │   │   │   │   └── alipay_import.dart
│   │   │   │   └── providers/
│   │   │   │       └── sync_provider.dart
│   │   │   └── settings/             # 设置模块
│   │   │       └── settings_page.dart
│   │   └── shared/
│   │       ├── widgets/              # 全局复用的 UI 组件
│   │       │   ├── app_button.dart         # 统一按钮
│   │       │   ├── app_text_field.dart     # 统一输入框
│   │       │   ├── app_card.dart           # 统一卡片
│   │       │   ├── app_bottom_sheet.dart   # 统一底部弹窗
│   │       │   ├── app_toast.dart          # Toast 提示
│   │       │   ├── skeleton_loader.dart    # 骨架屏
│   │       │   ├── empty_state.dart        # 空状态插画
│   │       │   ├── amount_text.dart        # 金额文字（带符号颜色）
│   │       │   └── category_icon.dart      # 分类图标（emoji 映射）
│   │       └── utils/                # 工具函数
│   │           ├── date_utils.dart         # 日期格式化
│   │           ├── number_utils.dart       # 金额格式化
│   │           ├── csv_parser.dart         # CSV 解析（账单导入）
│   │           ├── export_utils.dart       # 文件导出/分享
│   │           └── validator.dart          # 表单校验
│   ├── assets/
│   │   ├── images/                   # 图片资源
│   │   ├── fonts/                    # 字体文件
│   │   └── sounds/                   # 音效（点击/确认/删除）
│   └── test/
│       ├── unit/
│       └── widget/
│
├── docs/                             # 文档
│   ├── PRD.md                        # 产品需求文档
│   ├── ARCHITECTURE.md               # 本文档
│   └── API.md                        # API 接口文档（FastAPI 自动生成）
│
├── deploy/                           # 部署相关
│   ├── nginx.conf
│   ├── docker-compose.yml
│   └── deploy.sh
│
└── README.md
```

---

## 3. 四模块架构图

```
┌─────────────────────────────────────────────────────────────────┐
│                       Flutter App                               │
│                                                                 │
│  ┌──────────┐  ┌───────────┐  ┌──────────┐  ┌──────────┐     │
│  │ 录入模块  │  │ 展示模块   │  │ 分析模块  │  │ 导出模块  │     │
│  │          │  │           │  │          │  │          │     │
│  │ 手动记账  │  │ 首页仪表盘 │  │ 月度统计  │  │ CSV 导出  │     │
│  │ 语音记账  │  │ 流水列表   │  │ 年度统计  │  │ PDF 导出  │     │
│  │ 支付同步  │  │ 存钱仪表盘 │  │ 分类排行  │  │ JSON 备份 │     │
│  │ 存钱存入  │  │ 目标进度   │  │ 趋势折线  │  │ 图片分享  │     │
│  └────┬─────┘  └─────┬─────┘  └────┬─────┘  └────┬─────┘     │
│       │              │             │             │            │
│       └──────────────┼─────────────┼─────────────┘            │
│                      │             │                          │
│              ┌───────▼─────┐ ┌─────▼───────┐                 │
│              │ Record API  │ │ Stats API   │                 │
│              │ Category API│ │ Export API  │                 │
│              │ Savings API │ │ AI API      │                 │
│              └───────┬─────┘ └─────┬───────┘                 │
└──────────────────────┼─────────────┼──────────────────────────┘
                       │             │
                       ▼             ▼
┌─────────────────────────────────────────────────────────────────┐
│                    FastAPI Backend                              │
│                                                                 │
│  API Layer ──► Service Layer ──► Model Layer ──► Database      │
└─────────────────────────────────────────────────────────────────┘
```

---

## 4. 核心模块详细设计

### 4.1 数据录入模块

负责所有"数据进入系统"的通道。

```
┌─ 数据录入模块 ─────────────────────────────┐
│                                            │
│  ┌─────────┐  ┌─────────┐  ┌───────────┐  │
│  │手动录入  │  │语音录入  │  │第三方导入  │  │
│  │         │  │         │  │           │  │
│  │选类型    │  │按住录音  │  │微信CSV    │  │
│  │选分类    │  │ASR转文字 │  │支付宝CSV  │  │
│  │输金额    │  │NLP提取   │  │去重合并   │  │
│  │选日期    │  │用户确认  │  │自动分类   │  │
│  │保存      │  │保存      │  │保存       │  │
│  └────┬────┘  └────┬────┘  └─────┬─────┘  │
│       │            │             │         │
│       ▼            ▼             ▼         │
│  ┌──────────────────────────────────┐     │
│  │        统一录入接口               │     │
│  │   POST /api/v1/records           │     │
│  │   {type, amount, category,       │     │
│  │    date, note, source}           │     │
│  └──────────────────────────────────┘     │
└────────────────────────────────────────────┘
```

**关键文件：**
- Flutter: `lib/modules/record/` — 手动录入
- Flutter: `lib/modules/voice/` — 语音录入
- Flutter: `lib/modules/sync/` — 第三方导入
- Backend: `app/api/records.py` — 统一 API
- Backend: `app/api/ai.py` — AI 语音解析
- Backend: `app/services/ai_service.py` — NLP 规则引擎

---

### 4.2 数据展示模块

负责所有"把数据呈现给用户"的视图。

```
┌─ 数据展示模块 ─────────────────────────────┐
│                                            │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐ │
│  │首页仪表盘 │  │流水列表   │  │存钱仪表盘 │ │
│  │          │  │          │  │          │ │
│  │月结余卡片 │  │日期分组   │  │目标卡片   │ │
│  │收支比例条 │  │筛选面板   │  │进度动画   │ │
│  │最近N条   │  │长按删除   │  │自动规则   │ │
│  │快捷入口   │  │下拉刷新   │  │存入记录   │ │
│  └──────────┘  └──────────┘  └──────────┘ │
│                                            │
│  数据流: Provider → API → JSON → 渲染      │
│  离线策略: 先读本地 SQLite → 请求远程 →     │
│           合并结果 → 更新本地              │
└────────────────────────────────────────────┘
```

**关键文件：**
- Flutter: `lib/modules/home/` — 首页
- Flutter: `lib/modules/record/records_list_page.dart` — 流水列表
- Flutter: `lib/modules/savings/savings_page.dart` — 存钱仪表盘
- Flutter: `lib/data/local/database.dart` — 离线 SQLite

---

### 4.3 统计分析模块

负责数据的聚合计算和可视化。

```
┌─ 统计分析模块 ───────────────────────────┐
│                                          │
│  API 数据        前端渲染                 │
│  ┌─────────┐    ┌──────────────────┐    │
│  │月度统计  │───►│ 月度柱状图        │    │
│  │(按月聚合)│    │ (收支对比)       │    │
│  │         │    │ 饼图 (分类占比)   │    │
│  ├─────────┤    ├──────────────────┤    │
│  │年度统计  │───►│ 年度柱状图        │    │
│  │(按年聚合)│    │ (12个月趋势)     │    │
│  ├─────────┤    ├──────────────────┤    │
│  │分类排行  │───►│ 排行列表          │    │
│  │(Top N)  │    │ (花钱最多类别)    │    │
│  ├─────────┤    ├──────────────────┤    │
│  │趋势数据  │───►│ 折线图            │    │
│  │(按日聚合)│    │ (近30天趋势)      │    │
│  └─────────┘    └──────────────────┘    │
│                                          │
│  计算逻辑: Service 层纯函数，不依赖框架     │
│  图表库: fl_chart (已安装)                │
└──────────────────────────────────────────┘
```

**关键文件：**
- Backend: `app/services/stats_service.py` — 聚合计算
- Backend: `app/api/stats.py` — 统计 API
- Flutter: `lib/modules/stats/` — 统计页面
- Flutter: `lib/data/api/stats_api.dart` — API 调用

---

### 4.4 数据导出模块

负责数据的导出、备份、分享。

```
┌─ 数据导出模块 ────────────────────────────┐
│                                            │
│  用户选择: 格式 + 范围 + 内容              │
│       │                                    │
│       ▼                                    │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐ │
│  │CSV 导出   │  │PDF 导出   │  │JSON 导出 │ │
│  │Excel可用  │  │可打印     │  │数据迁移   │ │
│  │流式传输   │  │服务端渲染 │  │流式传输  │ │
│  └──────────┘  └──────────┘  └──────────┘ │
│                                            │
│  ┌──────────┐  ┌──────────┐              │
│  │图片导出   │  │自动备份   │              │
│  │社交分享   │  │云端存储   │              │
│  │前端渲染   │  │定时任务   │              │
│  └──────────┘  └──────────┘              │
│                                            │
│  大文件: 异步任务 + 下载链接                │
│  小文件: 直接返回                          │
└────────────────────────────────────────────┘
```

**关键文件：**
- Backend: `app/services/export_service.py` — 导出逻辑
- Backend: `app/api/export.py` — 导出 API
- Flutter: `lib/modules/export/` — 导出页面
- Flutter: `lib/shared/utils/export_utils.dart` — 文件保存/分享

---

## 5. 数据模型设计

### 5.1 后端 SQLAlchemy 模型

```python
# ===== user.py =====
class User(Base):
    __tablename__ = "users"

    id:          int (自增主键)
    username:    str(24) 唯一索引
    password_hash: str(255)
    avatar_url:  str(255) 可空
    created_at:  datetime
    updated_at:  datetime (自动更新)

    # 关联
    records:     List[Record]      # 一对多
    goals:       List[SavingsGoal] # 一对多
    categories:  List[Category]    # 一对多 (自定义分类)
    settings:    UserSettings      # 一对一


# ===== record.py =====
class Record(Base):
    __tablename__ = "records"

    id:          int (自增主键)
    user_id:     int → users.id (外键 + 索引)
    type:        Enum("income", "expense", "savings")
    amount:      Decimal(12,2)
    category_id: int → categories.id (外键)
    date:        date (索引: 联合 user_id + date)
    note:        str(200) 可空
    source:      Enum("manual", "voice", "wechat", "alipay") 默认 "manual"
    created_at:  datetime


# ===== category.py =====
class Category(Base):
    __tablename__ = "categories"

    id:          int (自增主键)
    parent_id:   int → categories.id 可空 (二级/三级分类)
    name:        str(50)
    type:        Enum("income", "expense", "savings")
    emoji:       str(10) 可空
    sort_order:  int 默认 0
    is_system:   bool 默认 True (True=系统预设, False=用户自定义)
    user_id:     int → users.id 可空 (自定义分类专属用户)


# ===== savings_goal.py =====
class SavingsGoal(Base):
    __tablename__ = "savings_goals"

    id:             int (自增主键)
    user_id:        int → users.id
    name:           str(100)
    target_amount:  Decimal(12,2)
    current_amount: Decimal(12,2) 默认 0
    deadline:       date 可空
    emoji:          str(10) 可空
    is_completed:   bool 默认 False
    created_at:     datetime


# ===== sync_log.py =====
class SyncLog(Base):
    __tablename__ = "sync_logs"

    id:                int (自增主键)
    user_id:           int → users.id
    source:            Enum("wechat", "alipay")
    raw_data:          JSON (原始账单数据)
    matched_record_id: int → records.id 可空
    status:            Enum("pending", "matched", "ignored", "conflict")
    synced_at:         datetime


# ===== user_settings.py =====
class UserSettings(Base):
    __tablename__ = "user_settings"

    user_id:             int → users.id (主键，一对一)
    theme:               str(20) 默认 "rice"
    currency:            str(10) 默认 "CNY"
    first_day_of_month:  int 默认 1
    budget_monthly:      Decimal(12,2) 可空
    budget_alert_enabled: bool 默认 True
```

### 5.2 Flutter Dart 模型

```dart
// ===== record.dart =====
class Record {
  final int id;
  final int userId;
  final String type;      // "income" | "expense" | "savings"
  final double amount;
  final int categoryId;
  final String categoryName;  // JOIN 后的分类名
  final String categoryEmoji; // JOIN 后的 emoji
  final String date;
  final String? note;
  final String source;    // "manual" | "voice" | "wechat" | "alipay"

  factory Record.fromJson(Map<String, dynamic> json);
  Map<String, dynamic> toJson();
}

// ===== category.dart =====
class Category {
  final int id;
  final int? parentId;
  final String name;
  final String type;
  final String? emoji;
  final List<Category> children;  // 子分类

  factory Category.fromJson(Map<String, dynamic> json);
}

// ===== savings_goal.dart =====
class SavingsGoal {
  final int id;
  final String name;
  final double targetAmount;
  final double currentAmount;
  final String? deadline;
  final String? emoji;
  final bool isCompleted;

  double get progress => targetAmount > 0 ? currentAmount / targetAmount : 0;
  double get remaining => targetAmount - currentAmount;

  factory SavingsGoal.fromJson(Map<String, dynamic> json);
}

// ===== api_response.dart =====
class ApiResponse<T> {
  final int code;
  final String message;
  final T? data;

  bool get isSuccess => code == 0;

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic)? fromJsonT,
  );
}
```

---

## 6. 数据流设计

### 6.1 请求生命周期

```
用户在 Flutter 点击「保存」
  → Provider 调用 ApiClient
  → ApiClient 自动附加 JWT Header
  → 发起 POST /api/v1/records
  → FastAPI 中间件校验 JWT → 提取 user_id
  → 路由 → Service 层（验证 + 业务逻辑）
  → Model 层 → 写入数据库
  → 返回统一格式 {"code":0, "message":"ok", "data":{...}}
  → ApiClient 拦截器检查 code
     ├─ code=0: Provider 更新本地状态 + UI 刷新
     ├─ code=401: 自动刷新 Token → 重试
     └─ code!=0: 弹出错误提示
```

### 6.2 离线模式策略

```
┌─ 写入 ──────────────────────────────────────┐
│ 用户添加记录                                 │
│   → 先写入本地 SQLite（立即可见）             │
│   → 后台同步到服务器                         │
│   → 同步成功 → 标记已同步                    │
│   → 同步失败 → 加入待重试队列                │
└─────────────────────────────────────────────┘

┌─ 读取 ──────────────────────────────────────┐
│ 用户打开首页                                 │
│   → 先展示本地 SQLite 缓存（秒开）            │
│   → 后台拉取服务器最新数据                   │
│   → 合并（服务器数据优先，本地未同步的保留）   │
│   → 更新本地缓存 + UI 刷新                   │
└─────────────────────────────────────────────┘
```

---

## 7. 代码规范

### 7.1 Python 后端规范

```python
# === 命名规范 ===
# 文件: snake_case (user_service.py, record_api.py)
# 类:   PascalCase (UserService, RecordCreate)
# 函数: snake_case (get_monthly_stats, create_record)
# 常量: UPPER_SNAKE (MAX_RECORDS_PER_PAGE = 20)

# === 路由函数规范：薄薄一层，不写业务逻辑 ===
@router.post("/records")
async def create_record(
    data: RecordCreate,           # Pydantic 自动校验
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    service = RecordService(db)
    record = service.create(user.id, data)
    return success(data=record.to_dict())

# === Service 层：所有业务逻辑在这里 ===
class RecordService:
    def __init__(self, db: Session):
        self.db = db

    def create(self, user_id: int, data: RecordCreate) -> Record:
        # 校验 + 写库 + 返回
        ...

    def get_monthly(self, user_id: int, month: str) -> List[Record]:
        ...

# === Schema：请求用 *Create，响应用 *Out ===
class RecordCreate(BaseModel):
    type: Literal["income", "expense", "savings"]
    amount: float = Field(gt=0)
    category_id: int
    date: date
    note: str | None = None

class RecordOut(BaseModel):
    id: int
    type: str
    amount: float
    category_name: str
    category_emoji: str | None
    date: date
    note: str | None
```

### 7.2 Dart/Flutter 前端规范

```dart
// === 命名规范 ===
// 文件: snake_case (record_provider.dart, balance_card.dart)
// 类:   PascalCase (RecordProvider, BalanceCard)
// 变量/函数: camelCase (monthlyBalance, fetchRecords)
// 常量: camelCase (maxRecordsPerPage = 20)
// 私有: 前缀 _ (_fetchData, _buildHeader)

// === Provider 模式（每个模块一个 Provider） ===
class RecordProvider extends ChangeNotifier {
  List<Record> _records = [];
  bool _isLoading = false;

  List<Record> get records => _records;
  bool get isLoading => _isLoading;

  Future<void> fetchRecords({String? month}) async {
    _isLoading = true;
    notifyListeners();
    try {
      _records = await RecordApi.getRecords(month: month);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

// === Widget：只管 UI，不调 API ===
class BalanceCard extends StatelessWidget {
  final double balance;
  final double income;
  final double expense;
  final VoidCallback? onTap;

  // API 调用由 Provider 负责
  // Widget 只负责渲染 Provider 给的数据
}

// === API 调用：统一错误处理 ===
class RecordApi {
  static Future<List<Record>> getRecords({String? month}) async {
    final response = await ApiClient.instance.get('/records', query: {'month': month});
    final apiResp = ApiResponse.fromJson(response.data, (d) => d);
    if (apiResp.isSuccess) {
      return (apiResp.data as List).map((e) => Record.fromJson(e)).toList();
    }
    throw ApiException(apiResp.code, apiResp.message);
  }
}
```

### 7.3 通用规范

| 规范 | 说明 |
|------|------|
| **函数长度** | 不超过 30 行，超了就拆 |
| **文件长度** | 不超过 300 行，超了就拆模块 |
| **嵌套层级** | 不超过 3 层 if/for |
| **重复代码** | 出现 2 次抽函数，3 次抽类 |
| **注释** | 只解释"为什么"，不解释"是什么" |
| **提交信息** | `类型: 描述` 如 `feat: 添加语音记账` `fix: 金额负数校验` |
| **魔法值** | 全部放到 `constants.dart` 或 `config.py` |

### 7.4 Git 分支策略（一人开发）

```
main          ← 生产分支，只接受 PR 合并
  └─ develop  ← 开发分支
       ├─ feat/voice-input     ← 功能分支
       ├─ feat/sync-wechat
       └─ fix/amount-validation
```

---

## 8. MVP 阶段最小实现清单

MVP 只做这 6 件事，其他后续迭代：

```
□ Flutter 项目初始化 + 主题系统 + 路由
□ 用户注册/登录 (JWT)
□ 记账核心：添加、编辑、删除、列表
□ 3 级分类系统（系统预设，先不做自定义）
□ 首页仪表盘 + 月度统计（柱状图 + 饼图）
□ 导出 CSV
```

MVP 不做的：
- ✗ 语音记账（Phase 2）
- ✗ 支付同步（Phase 2）
- ✗ 存钱目标（Phase 2）
- ✗ 离线模式（Phase 2）
- ✗ PDF/图片导出（Phase 2）

---

*文档版本: v1.0 | 创建日期: 2026-05-11*
