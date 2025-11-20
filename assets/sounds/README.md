# 音效文件说明

此目录用于存放应用的音效文件。需要添加以下音频文件：

## 所需音效文件

1. **click.mp3** - 点击音效
   - 用途：按钮点击
   - 时长：~0.1秒
   - 推荐：轻快的点击声

2. **spin.mp3** - 旋转音效
   - 用途：转盘旋转、老虎机滚动
   - 时长：~2-3秒
   - 推荐：持续的旋转声

3. **success.mp3** - 成功音效
   - 用途：抽奖结果显示
   - 时长：~1-2秒
   - 推荐：欢快的胜利音效

4. **scratch.mp3** - 刮擦音效
   - 用途：刮刮乐刮擦
   - 时长：~0.2秒
   - 推荐：刮纸的声音

## 音频格式要求

- 格式：MP3（推荐）或 WAV
- 采样率：44100 Hz 或更高
- 比特率：128 kbps 或更高
- 文件大小：建议每个文件小于 500KB

## 获取音效资源

可以从以下网站获取免费音效：

- [Freesound](https://freesound.org/)
- [Zapsplat](https://www.zapsplat.com/)
- [Mixkit](https://mixkit.co/free-sound-effects/)
- [Pixabay](https://pixabay.com/sound-effects/)

## 注意事项

- 如果不添加音频文件，应用仍可正常运行，只是没有音效
- FeedbackService 已做好异常处理，缺少音频文件不会导致崩溃
- 请确保音频文件版权符合项目使用要求
