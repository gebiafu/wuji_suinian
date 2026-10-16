# 物记碎念（wuji_suinian）

> 纯离线优先的本地个人知识库 App：**物品台账 + 子弹笔记（碎碎念）**
> 数据全部保存在本机 SQLite 与 App 私有目录；WebDAV 仅作为可选的备份 / 同步通道。
> 无后端服务器、无账号体系、无埋点。

技术栈：Flutter + Drift(SQLite) + Riverpod 2 + image_picker + flutter_image_compress
+ flutter_secure_storage + archive + flutter_local_notifications。

---

## 一、已实现的模块（对照需求文档）

### 模块 0：全局基础能力
| 需求 | 实现位置 |
| --- | --- |
| 权限按需申请（相机 / 相册 / 通知） | `lib/data/services/permission_service.dart` |
| 全局跨模块检索 + 关键词高亮 | `lib/features/search/global_search_page.dart`、`lib/features/common/widgets/highlight_text.dart` |
| WebDAV 配置页（多套切换、密码加密存储） | `lib/features/settings/webdav_config_page.dart`、`lib/data/services/secure_store.dart` |
| 手动备份 / 手动恢复（二次确认 + md5 校验） | `lib/data/services/backup_service.dart`、`lib/features/settings/backup_center_page.dart` |
| 自动备份（切后台 / 每日定时） | `lib/data/services/backup_scheduler.dart` |
| 双向同步 + 时间戳冲突检测 + 冲突副本 | `lib/data/services/webdav/sync_policy.dart`、`backup_service.dart#sync` |
| 备份快照（保留 N 份，可回滚） | `backup_service.dart#_writeSnapshot / pruneSnapshots / listSnapshots` |
| 备份状态面板 + 同步日志 + 失败原因 | `lib/features/settings/backup_center_page.dart`、`backup_records` 表 |
| 数据导出 / 导入 ZIP（兜底方案） | `lib/data/services/archive_service.dart` |
| 主题 / 字体大小 / 存储查看 / 清理孤儿图片 / 一键清空 | `lib/features/settings/settings_page.dart`、`storage_page.dart` |
| 关于页 + 本地版本 | `lib/features/settings/about_page.dart` |

### 模块 1：物品台账
多图（拍照 / 相册）、分类、存放位置、状态（在用 / 闲置 / 已丢弃 / 借出）、借出记录、
购买渠道 / 日期 / 质保到期日、备注、标签、筛选（分类 / 位置 / 状态 / 标签）、排序
（新增时间 / 购买时间 / 价格 / 名称）、检索（名称 / 备注 / 位置 / 价格 / 渠道 / 借给谁）、
质保提醒、轻量统计（总数 / 总价值 / 状态 / 分类）、删除时可选是否删原图、复制物品信息。

### 模块 2：子弹笔记（碎碎念）
短信式信息流（底部常驻输入框、最新在底部）、快捷发送、可选附图、待办勾选、置顶、
长按菜单（编辑 / 删除 / 置顶 / 加标签 / 复制）、筛选（待办 / 未完成 / 置顶 / 标签）、全文检索。

### 模块 3：数据关系
物品与碎念各一张主表、相互隔离；图片**不入库**（只存相对路径），
原图位于 `<AppDocuments>/wuji_suinian/asset/images/`。

---

## 二、目录结构

```
lib/
├── main.dart                     # 启动：本地目录 + 本地存储，零网络请求
├── app/
│   ├── app.dart                  # MaterialApp + 底部 3 Tab 外壳 + 自动备份调度
│   └── providers.dart            # Riverpod 依赖注入（数据库 / 服务 / 仓库 / 设置）
├── core/                         # 常量、路径、主题、时间与 md5 工具
├── data/
│   ├── db/                       # Drift 表结构、数据库、DAO
│   ├── repositories/             # 业务仓库（物品 / 碎念 / 标签 / 检索）
│   └── services/                 # 图片、权限、存储统计、ZIP、通知、备份同步、WebDAV
├── domain/models/                # 领域模型（状态枚举、筛选、聚合视图、备份模型）
└── features/                     # 页面与控制器（notes / items / search / settings）
```

## 三、数据库设计

表结构与需求文档第四节一致：`tags`、`items`、`item_images`、`bullet_notes`、
`bullet_note_tag_rel`、`item_tag_rel`，时间统一存 unix 毫秒时间戳。
额外增加 `backup_records` 表用于「同步日志 / 备份状态面板」。
表结构由 `test/database_schema_test.dart` 断言校验。

## 四、WebDAV 远端目录结构

```
<remoteDir>/db/app.db              最新正式备份
<remoteDir>/db/app.db.tmp          上传中间文件（校验成功后才 MOVE 覆盖，避免坏文件覆盖唯一备份）
<remoteDir>/md5/app.db.md5         数据库 md5 校验文件（恢复前校验，失败拒绝恢复）
<remoteDir>/images/**              全量图片目录（增量上传：大小一致则跳过）
<remoteDir>/snapshots/<id>/        历史快照（app.db + app.db.md5 + manifest.json）
<remoteDir>/state/sync_state.json  同步基准（db md5 + 图片 size/mtime），用于判断哪端更新
```

同步策略：**基于内容 md5 + 文件修改时间戳**。
远端新于本地 → 拉取；本地新于远端 → 上传；一致 → 跳过；
两端都修改 → **冲突，自动生成冲突副本，不自动合并**，由用户在备份中心选择以哪边为准。

## 五、开发与验证命令

```bash
# 代码生成（Drift）
dart run build_runner build --delete-conflicting-outputs

# 静态分析
flutter analyze

# 单元测试（Windows 上需要把 sqlite3.dll 放在项目根目录或 PATH 中）
flutter test

# 运行
flutter run
```

测试覆盖：表结构校验、数据库级联删除、物品/碎念仓库（筛选、排序、检索、标签、统计、
质保清单、多图替换、按需删图）、同步策略决策（上传/下载/冲突）、WebDAV 客户端
（multistatus 解析、请求头、中文路径编码、错误处理）、备份链路（备份结构 / md5 / 快照
与清理 / 恢复校验 / md5 失败拒绝恢复 / 同步上传 / 同步下载 / 冲突不覆盖）、
ZIP 导出导入（含 md5 防篡改）。

### GitHub Actions 自动构建（CI）

仓库内置 `.github/workflows/build-apk.yml`：推送到 `main` / `master` 分支，或在仓库
Actions 页面手动「Run workflow」，会自动执行 `flutter analyze` → `flutter test` →
`flutter build apk --release`，并将 `app-release.apk` 上传到该次运行的 **Artifacts**
（保留 30 天，点开运行记录即可下载）。

- 运行环境：`ubuntu-latest` + JDK 21 + Flutter 3.47.7（与本地一致，可在工作流文件中调整）。
- APK 目前使用 debug 签名，可直接安装到自己的手机；若需上架或长期分发，
  请配置正式签名（`android/key.properties` + GitHub Secrets，参考 Flutter 官方文档）。
- 注意：仓库根目录应为本项目根目录（`pubspec.yaml` 所在目录），工作流中的路径才能对上。

## 六、已知边界（与需求文档「风险与边界设计」一致）

1. WebDAV 不支持多人实时协同，仅适合备份与单设备轮换（手机 A 备份 → 手机 B 恢复）。
2. 断点续传按**文件粒度**实现：已成功上传的文件不会重复上传；单个大文件内部不分片续传，
   但通过「临时文件 + 大小校验 + MOVE 原子替换」保证中断不会损坏远端正式备份。
3. iOS 后台自动备份触发不稳定，建议手动备份或使用导出 ZIP。
4. 数据库本身未加密（SQLCipher 为后续可选增强项）；WebDAV 密码已用
   `flutter_secure_storage` 加密保存。
5. WebDAV 客户端为自建最小实现（PROPFIND / MKCOL / PUT / GET / DELETE / MOVE），
   为的是完全控制请求头并便于单元测试；如需更复杂能力可替换为 `webdav_client` 等库。
