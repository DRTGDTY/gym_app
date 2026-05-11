# GymApp - 专业个人健身管理

一个结构清晰、数据准确的专业级个人健身管理APP，基于 Flutter 构建。

## 功能

- **训练记录**: 3步快速记录，自动补全重量、计算Volume、识别PR
- **Cycle 系统**: 自动检测训练周期（练完全身 = 一轮）
- **日历视图**: 训练日打点 + 详情查看
- **组间计时器**: 手动触发，支持暂停/重置/微调
- **营养系统**: Mifflin-St Jeor BMR + TDEE + 动态热量调整
- **数据分析**: PR记录、Volume趋势、体重曲线、Cycle对比
- **导入导出**: JSON格式备份恢复
- **深色主题**: 翠绿单色强调，大数字高信息密度

## 技术栈

- Flutter 3.x
- sqflite (本地数据库)
- Riverpod (状态管理)
- fl_chart (图表)
- share_plus (分享)

## 构建 APK

### 方式一：本地构建
```bash
flutter pub get
flutter build apk --release
```

### 方式二：Codemagic 在线构建
1. 上传到 GitHub
2. 连接 [codemagic.io](https://codemagic.io)
3. 自动构建签名 APK

### 方式三：GitHub Actions
配置 `.github/workflows/build.yml`

## 项目结构

```
lib/
├── main.dart
├── app.dart
├── models/         # 数据模型
├── database/       # SQLite + DAO
├── providers/      # Riverpod 状态管理
├── screens/        # UI 页面
├── widgets/        # 可复用组件
└── utils/          # 算法工具
```

## 个人数据预设

- 身高: 177cm
- 体重: 66.5kg
- 年龄: 23
- BMR: 1661 kcal
- TDEE: ~2575 kcal (中等活跃)
