# 小满记账 — 开发速查表

> ⚠️ **行动前必读**：每次修改代码前先查阅本表。不修改已有 IP/端口。端口被占用时使用其他端口。

---

## 一、IP 与端口（禁止修改）

| 项目 | 值 | 说明 |
|------|-----|------|
| 服务器 IP | `114.55.138.55` | 阿里云，禁止修改 |
| 后端端口 | `8000` | uvicorn 内部端口，127.0.0.1 |
| 前端端口 | `80` | Nginx 对外端口 |
| API 基础路径 | `http://114.55.138.55/api/v1` | 前端 constants.dart 硬编码 |
| 后端路径(服务器) | `/www/wwwroot/backend` | v3 部署位置 |

> 如 `8000` 被占用 → 改用 `8001`；如 `80` 被占用 → 改用 `8080`

---

## 二、快速命令

### 前端

```bash
# 环境变量（中文用户名必需）
export PUB_CACHE=/d/flutter_pub_cache
export GRADLE_USER_HOME=/d/gradle_home

# 开发
cd /d/my_thoughts/xiaojia_ledger/frontend
flutter analyze                                    # 检查错误
flutter build apk --release                        # 打包 APK
cp build/app/outputs/flutter-apk/app-release.apk ../小满记账.apk  # 复制到根目录
```

### 后端（服务器）

```bash
systemctl restart xiaojia                          # 重启服务
systemctl status xiaojia                           # 查看状态
journalctl -u xiaojia -f                           # 查看日志
```

---

## 三、版本号（修改代码后必须同步更新）

| 文件 | 字段 | 当前值 |
|------|------|--------|
| `frontend/pubspec.yaml` | `version:` | `2.0.0+1` |
| `frontend/lib/core/constants.dart` | `appVersion` | `2.0.0` |
| `backend/app/config.py` | `VERSION` | `1.0.0` |

---

## 四、文件地图

### 前端核心层 (`frontend/lib/core/`)

| 文件 | 作用 |
|------|------|
| `crayon_theme.dart` | 配色 + 字体样式 |
| `crayon_painter.dart` | HandDrawnBorder 边框 |
| `crayon_widgets.dart` | CrayonCard/Button/FAB/Input/NumberText |
| `crayon_charts.dart` | 手绘饼图 + 柱状图 |
| `crayon_nav_icons.dart` | 5个简笔画导航图标 |
| `crayon_icons.dart` | 手绘箭头/星星图标 |
| `organic_borders.dart` | CloudBorder / WaveBorder / IrregularBox |
| `paper_background.dart` | 纸张纹理背景 |
| `page_turn.dart` | 翻页动画 |
| `constants.dart` | API地址 / 版本号 |
| `router.dart` | 路由表 |
| `haptics.dart` | 触感反馈 |

### 前端页面 (`frontend/lib/modules/`)

| 文件夹 | 文件 | 对应页面 |
|--------|------|----------|
| `auth/` | `splash_page.dart` | 闪屏页 |
| `auth/` | `login_page.dart` | 登录页 |
| `home/` | `home_page.dart` | **首页（主页面，5 Tab容器）** |
| `home/widgets/` | `crayon_title.dart` | 艺术字标题 |
| `home/widgets/` | `wallet_cards.dart` | 钱包分区卡片 |
| `home/widgets/` | `daily_remaining.dart` | 每日可花额度 |
| `home/widgets/` | `ocr_loading.dart` | OCR识别动画 |
| `home/widgets/` | `ocr_result.dart` | OCR结果确认卡 |
| `home/widgets/` | `overbudget_dialog.dart` | 超预算提醒弹窗 |
| `record/` | `add_record_sheet.dart` | 记账底部弹窗 |
| `record/` | `records_list_page.dart` | 流水列表 |
| `stats/` | `stats_page.dart` | 统计页 |
| `savings/` | `savings_page.dart` | 存钱目标 |
| `settings/` | `settings_page.dart` | 设置页 |
| `settings/` | `theme_picker_page.dart` | 主题选择 |
| `sync/` | `sync_page.dart` | 账单导入 |
| `voice/` | `voice_page.dart` | 语音记账 |
| `onboarding/` | `budget_setup.dart` | 首次生活费设置 |
| `ai/` | `weekly_report.dart` | 省钱周报 |
| `ai/` | `subscriptions.dart` | 会员检测 |
| `ai/` | `deals.dart` | 薅羊毛提醒 |

### 数据层 (`frontend/lib/data/`)

| 文件 | 作用 |
|------|------|
| `api/api_client.dart` | Dio HTTP 客户端（JWT 拦截器） |
| `api/auth_api.dart` | 登录/注册 API |
| `api/category_api.dart` | 分类 API |
| `api/record_api.dart` | 记录 CRUD API |
| `api/savings_api.dart` | 存钱目标 API |
| `api/stats_api.dart` | 统计 API |
| `models/record.dart` | 记录模型 |
| `models/category.dart` | 分类模型 |
| `models/user.dart` | 用户模型 |
| `models/api_response.dart` | API 响应模型 |

---

## 五、API 端点速查

所有端点前缀：`http://114.55.138.55/api/v1`

| 方法 | 路径 | 用途 |
|------|------|------|
| POST | `/auth/register` | 注册 |
| POST | `/auth/login` | 登录（返回 token） |
| GET | `/auth/me` | 用户信息 |
| GET | `/categories` | 分类列表 |
| GET | `/records?month=YYYY-MM` | 记录列表 |
| POST | `/records` | 添加记录 |
| PUT | `/records/{id}` | 更新记录 |
| DELETE | `/records/{id}` | 删除记录 |
| GET | `/stats/monthly?month=YYYY-MM` | 月度统计 |
| GET | `/stats/yearly?year=YYYY` | 年度统计 |
| GET | `/export/csv` | 导出 CSV |
| GET | `/export/json` | 导出 JSON |
| GET | `/savings/goals` | 存钱目标 |
| POST | `/savings/goals` | 创建目标 |
| POST | `/savings/deposit` | 存入 |
| POST | `/sync/parse` | 解析账单 CSV |
| POST | `/ai/parse` | AI 文本解析 |
| POST | `/ai/voice` | AI 语音识别 |
| POST | `/ai/ocr` | 截图 OCR（base64） |
| POST | `/ai/ocr/batch` | 批量 OCR |
| GET | `/settings/budget` | 获取生活费设置 |
| PUT | `/settings/budget` | 更新生活费设置 |
| GET | `/wallets` | 钱包分区列表 |
| PUT | `/wallets` | 更新钱包 |
| GET | `/ai/report/weekly` | 省钱周报 |
| GET | `/ai/subscriptions` | 会员检测 |
| GET | `/deals` | 优惠提醒 |
| POST | `/deals` | 添加提醒 |

---

## 六、服务器部署流程

1. 本地修改后端文件
2. 创建/更新 `deploy/deploy_v3.sh`
3. 用户通过宝塔面板终端执行脚本
4. `systemctl restart xiaojia` 生效

**后端代码位置**：
- 本地：`D:\my_thoughts\xiaojia_ledger\backend\`
- 服务器：`/www/wwwroot/backend/`

---

## 七、常见注意事项

1. **中文路径**：Windows 用户名 `江泽锦` 导致 Flutter/Gradle 路径问题，必须设置 `PUB_CACHE` 和 `GRADLE_USER_HOME`
2. **OCR 是存根**：`backend/app/api/ocr.py` 的 `_mock_ocr()` 返回空字符串，需接入真实 OCR 服务
3. **数据库**：SQLite，表由 SQLAlchemy `create_all` 自动创建
4. **首次设置流程**：闪屏 → 登录 → 检查 `budget_setup_done` → 未设置则跳转 `/onboarding/budget`
5. **首页是 5 Tab 容器**：修改各 Tab 内容不需改 home_page 结构，只需改对应页面文件
