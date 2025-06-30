# 视频合成服务测试指南

## 测试客户端使用说明

### 1. 准备测试环境

确保已安装 Python 3.x 和 requests 库：
```bash
pip install requests
```

### 2. 准备测试文件

创建 `test_data` 目录并放入测试视频：
```
test_data/
  └── test_video.mp4  (必需)
  └── test_audio.wav  (可选)
```

### 3. 运行测试

#### Windows 用户
直接双击运行 `测试客户端.bat`，选择测试模式：
- 1: 快速测试（使用默认测试数据）
- 2: 自定义测试（指定文件和文本）
- 3: 交互式测试（逐步输入）
- 4: 仅测试服务器连接

#### Linux/Mac 用户
```bash
# 快速测试
./quick_test.sh

# 或使用 Python 直接运行
python test_client.py --quick
```

### 4. 命令行参数

```bash
# 完整测试示例
python test_client.py \
  --server http://localhost:6006 \
  --video test_data/test_video.mp4 \
  --audio test_data/test_audio.wav \
  --texts "第一段文本" "第二段文本" "第三段文本" \
  --ref-text "这是参考文本"

# 仅测试连接
python test_client.py --server http://localhost:6006
```

### 5. 测试流程

1. **健康检查**: 验证服务器是否运行
2. **上传文件**: 上传视频和音频文件
3. **创建任务**: 提交合成任务
4. **状态轮询**: 每2秒检查一次任务状态
5. **下载结果**: 任务完成后下载生成的视频

### 6. 输出结果

测试结果将保存在 `test_output/` 目录中：
```
test_output/
  ├── output_segment_1.mp4
  ├── output_segment_2.mp4
  └── output_segment_3.mp4
```

### 7. 故障排查

- **无法连接服务器**: 检查服务端是否在 6006 端口运行
- **文件上传失败**: 确保视频文件存在且格式正确
- **任务失败**: 查看服务端日志了解详细错误信息

### 8. 自定义服务器地址

如果服务器运行在 AutoDL 或其他地址：
```bash
# Windows
set SERVER_URL=http://your-server:6006
测试客户端.bat

# Linux/Mac
export SERVER_URL=http://your-server:6006
./quick_test.sh
```