/// 全局常量。
///
/// 需求文档：纯离线优先本地知识库 App，无账号体系、无厂商云。
class AppConstants {
  AppConstants._();

  /// 应用展示名（可改名：匣记 / 拾忆本 / 私藏笔记）
  static const String appName = '物记碎念';

  /// 数据库文件名
  static const String dbFileName = 'app.db';

  /// 远端备份目录结构：/backup/db、/backup/images、/backup/md5、/backup/snapshots
  static const String remoteRootDir = 'backup';

  /// 默认快照保留份数（可在设置中调整为 3 / 5 / 10）
  static const int defaultSnapshotKeep = 5;

  /// 图片默认压缩质量
  static const int defaultImageQuality = 80;

  /// 质保到期提前提醒天数
  static const int warrantyReminderDays = 30;

  /// 物品状态枚举值（与数据库 status 字段一致）
  static const String statusUsing = 'using';
  static const String statusIdle = 'idle';
  static const String statusDiscarded = 'discarded';
  static const String statusLend = 'lend';
}