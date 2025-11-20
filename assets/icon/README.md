# 应用图标说明

## 图标主题
**一碗米饭旁一双筷子** 🍚🥢

## ✅ 图标状态
图标文件已完成并部署到Android项目中！

### 已部署的图标文件
- ✅ `android/res/mipmap-hdpi/` - 72x72 图标
- ✅ `android/res/mipmap-mdpi/` - 48x48 图标
- ✅ `android/res/mipmap-xhdpi/` - 96x96 图标
- ✅ `android/res/mipmap-xxhdpi/` - 144x144 图标
- ✅ `android/res/mipmap-xxxhdpi/` - 192x192 图标
- ✅ `android/res/mipmap-anydpi-v26/` - 自适应图标配置
- ✅ `android/play_store_512.png` - 512x512 Play Store图标

## 需要的图标文件

### 方案一：使用在线工具生成
1. 访问 [Canva](https://www.canva.com/) 或 [Figma](https://www.figma.com/)
2. 创建 1024x1024 的画布
3. 设计内容：
   - 背景：橙色渐变 (#FF9800 到 #F57C00)
   - 中心：一个白色的饭碗图标
   - 旁边：交叉的筷子
   - 风格：简约扁平化

4. 导出为 PNG 格式，命名为：
   - `app_icon.png` (1024x1024) - 完整图标
   - `app_icon_foreground.png` (1024x1024, 透明背景) - 前景图标

5. 将文件放入此目录

### 方案二：使用 Emoji 组合（临时方案）
如果暂时没有设计工具，可以使用以下 emoji 组合：
- 🍚 (米饭) + 🥢 (筷子)

### 方案三：使用AI生成工具
使用 AI 图像生成工具（如 DALL-E, Midjourney 等）生成：

提示词示例：
```
A simple, flat design app icon featuring a white bowl of rice with steam rising, 
and a pair of wooden chopsticks crossed beside it, on an orange gradient background, 
minimalist style, clean lines, suitable for mobile app icon
```

## 生成步骤

1. 将 `app_icon.png` 和 `app_icon_foreground.png` 放入此目录

2. 运行命令生成所有尺寸的图标：
```bash
flutter pub get
flutter pub run flutter_launcher_icons
```

3. 重新编译应用：
```bash
flutter clean
flutter run
```

## 当前状态
⚠️ 需要添加图标文件才能生成应用图标

## 临时替代方案
如果现在没有图标文件，我已经配置好了系统，您可以：
1. 先使用默认图标
2. 后续准备好图标文件后，放入此目录
3. 运行生成命令即可更新

## 推荐的图标设计
- **主色调**: 橙色 (#FF9800) - 代表温暖和食物
- **前景**: 白色碗+棕色筷子 - 简洁明了
- **风格**: 扁平化、圆角、现代
- **尺寸**: 1024x1024 像素（标准应用图标尺寸）
