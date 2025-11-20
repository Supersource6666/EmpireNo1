# 新功能使用说明

## 概述

此版本新增了以下功能：
1. 从 txt 文件加载默认美食列表
2. 自定义美食管理功能
3. 设置页面（音效和震动开关）

所有功能已完全集成，所有 6 个抽奖页面都会自动加载合并后的美食列表（默认美食 + 自定义美食）。

---

## 1. 美食数据管理

### 默认美食列表

**文件位置**: `assets/foods.txt`

**格式说明**:
```
美食名称,Emoji,分类,描述
火锅,🍲,中餐,麻辣鲜香，热气腾腾
寿司,🍣,日韩料理,新鲜美味，精致可口
```

**特点**:
- 使用逗号分隔字段
- 每行一个美食
- 包含 12 种默认美食
- 应用启动时自动加载

### 自定义美食管理

**入口**: 主页右上角的 🍴 图标

**功能**:
1. **查看自定义美食**: 以卡片形式展示所有自定义美食
2. **添加美食**: 
   - 点击右下角的 ➕ 按钮
   - 填写名称、Emoji、分类、描述
   - 点击"添加"完成
3. **删除美食**: 
   - 左滑美食卡片
   - 确认删除

**数据存储**:
- 使用 `SharedPreferences` 持久化存储
- 格式: `name|emoji|category|description`
- 多个美食用 `||` 分隔

---

## 2. 设置页面

**入口**: 主页右上角的 ⚙️ 图标

**功能**:

### 音效开关
- 控制所有页面的音效播放
- 包括：点击音效、旋转音效、成功音效、刮擦音效
- 默认：开启
- 实时生效，无需重启应用

### 震动开关
- 控制所有页面的震动反馈
- 包括：轻震动、中等震动、重震动、成功震动、摇动震动
- 默认：开启
- 实时生效，无需重启应用

### 数据持久化
- 设置保存在本地
- 下次启动应用时自动恢复

---

## 3. 服务架构

### FoodStorageService

**职责**: 管理美食数据的加载、保存和查询

**主要方法**:
```dart
// 加载默认美食（从 assets/foods.txt）
static Future<List<FoodItem>> loadDefaultFoods()

// 获取自定义美食
static Future<List<FoodItem>> getCustomFoods()

// 获取所有美食（默认 + 自定义）
static Future<List<FoodItem>> getAllFoods()

// 保存自定义美食
static Future<void> saveCustomFood(FoodItem food)

// 删除自定义美食
static Future<void> deleteCustomFood(FoodItem food)
```

### SettingsService

**职责**: 管理用户偏好设置

**主要方法**:
```dart
// 音效开关
static Future<bool> isSoundEnabled()
static Future<void> setSoundEnabled(bool enabled)

// 震动开关
static Future<bool> isVibrationEnabled()
static Future<void> setVibrationEnabled(bool enabled)
```

### FeedbackService

**职责**: 提供音效和震动反馈（已更新）

**特点**:
- 所有方法都会先检查设置状态
- 如果设置关闭，则不播放音效或震动
- 确保用户设置得到尊重

---

## 4. 抽奖页面集成

所有 6 个抽奖页面已完成集成：

1. ✅ **大转盘页面** (`lucky_wheel_page.dart`)
2. ✅ **九宫格页面** (`grid_lottery_page.dart`)
3. ✅ **老虎机页面** (`slot_machine_page.dart`)
4. ✅ **随机选择页面** (`random_picker_page.dart`)
5. ✅ **摇一摇页面** (`shake_page.dart`)
6. ✅ **刮刮乐页面** (`scratch_card_page.dart`)

**集成内容**:
- 使用 `FoodStorageService.getAllFoods()` 加载美食
- 在 `initState()` 中异步加载数据
- 显示加载指示器（`CircularProgressIndicator`）
- 数据加载完成后渲染页面

---

## 5. 使用流程

### 用户体验流程

1. **首次启动**:
   - 应用加载 `assets/foods.txt` 中的 12 种默认美食
   - 音效和震动默认开启
   - 可以直接使用任意抽奖模式

2. **添加自定义美食**:
   - 点击主页右上角的 🍴 图标
   - 点击右下角的 ➕ 按钮
   - 填写美食信息
   - 保存后，所有抽奖页面都会显示新增的美食

3. **调整设置**:
   - 点击主页右上角的 ⚙️ 图标
   - 根据需要开启或关闭音效/震动
   - 返回主页，设置立即生效

4. **使用抽奖**:
   - 选择任意抽奖模式
   - 系统自动加载所有美食（默认 + 自定义）
   - 根据设置播放音效和震动

---

## 6. 技术实现细节

### 数据加载流程

```
应用启动
  ↓
抽奖页面打开
  ↓
initState() 调用
  ↓
_loadFoods() 异步加载
  ↓
FoodStorageService.getAllFoods()
  ├─ loadDefaultFoods() (读取 assets/foods.txt)
  └─ getCustomFoods() (读取 SharedPreferences)
  ↓
合并两个列表
  ↓
setState() 更新界面
  ↓
显示美食列表
```

### 设置检查流程

```
用户触发操作（如点击按钮）
  ↓
调用 FeedbackService 方法
  ↓
检查 SettingsService 设置状态
  ├─ isSoundEnabled() - 检查音效开关
  └─ isVibrationEnabled() - 检查震动开关
  ↓
如果开启，执行反馈
如果关闭，直接返回
```

---

## 7. 文件修改清单

### 新增文件
- ✅ `lib/pages/settings_page.dart` - 设置页面
- ✅ `lib/pages/custom_food_page.dart` - 自定义美食管理页面
- ✅ `lib/services/food_storage_service.dart` - 美食数据服务
- ✅ `lib/services/settings_service.dart` - 设置管理服务
- ✅ `assets/foods.txt` - 默认美食列表

### 修改文件
- ✅ `lib/main.dart` - 添加导航按钮
- ✅ `lib/services/feedback_service.dart` - 集成设置检查
- ✅ `lib/pages/lucky_wheel_page.dart` - 集成数据加载
- ✅ `lib/pages/grid_lottery_page.dart` - 集成数据加载
- ✅ `lib/pages/slot_machine_page.dart` - 集成数据加载
- ✅ `lib/pages/random_picker_page.dart` - 集成数据加载
- ✅ `lib/pages/shake_page.dart` - 集成数据加载
- ✅ `lib/pages/scratch_card_page.dart` - 集成数据加载
- ✅ `pubspec.yaml` - 添加依赖和资源配置
- ✅ `README.md` - 更新文档

---

## 8. 测试建议

### 功能测试

1. **默认美食加载**:
   - 启动应用
   - 打开任意抽奖页面
   - 确认显示 12 种默认美食

2. **自定义美食**:
   - 添加一个新美食
   - 打开不同的抽奖页面
   - 确认新美食在所有页面都显示
   - 删除自定义美食，确认删除成功

3. **设置功能**:
   - 关闭音效，点击按钮确认无声音
   - 开启音效，点击按钮确认有声音
   - 关闭震动，操作手机确认无震动
   - 开启震动，操作手机确认有震动

4. **数据持久化**:
   - 添加自定义美食
   - 修改设置
   - 重启应用
   - 确认数据和设置都保留

### 边界测试

1. **空数据**:
   - 删除所有自定义美食
   - 确认应用仍然正常工作（显示默认美食）

2. **大量数据**:
   - 添加多个自定义美食（如 20+ 个）
   - 确认所有页面都能正常显示和操作

3. **特殊字符**:
   - 添加包含特殊字符的美食（如 emoji、标点符号）
   - 确认保存和显示正常

---

## 9. 常见问题

### Q: 自定义美食会覆盖默认美食吗？
A: 不会。自定义美食会与默认美食合并显示。

### Q: 删除自定义美食后能恢复吗？
A: 不能。删除操作是永久的。建议确认后再删除。

### Q: 修改 foods.txt 文件需要重新安装应用吗？
A: 是的。assets 文件需要重新编译才能生效。

### Q: 设置关闭后，之前的音效文件还会被加载吗？
A: 会加载，但不会播放。这样可以快速切换设置。

### Q: 可以导出自定义美食吗？
A: 当前版本不支持。这是未来计划中的功能。

---

## 10. 下一步改进建议

- [ ] 添加美食导入/导出功能
- [ ] 支持编辑自定义美食
- [ ] 添加美食分类筛选
- [ ] 支持美食收藏功能
- [ ] 添加历史记录
- [ ] 支持自定义音效
- [ ] 支持自定义震动模式

---

**更新时间**: 2024
**版本**: v2.0
**维护者**: GitHub Copilot
