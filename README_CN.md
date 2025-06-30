# 视频合成项目 - 完整使用指南

这是一个基于GPT-SoVITS和MuseTalk的视频合成系统，可以将文字转换为语音，并生成口型同步的视频。

## 功能特点

- 🎙️ 文字转语音：使用GPT-SoVITS生成自然的语音
- 🎬 口型同步：使用MuseTalk实现视频口型同步
- 📝 批量处理：支持多段文本批量转换
- 🖥️ 桌面客户端：提供友好的图形界面
- 🚀 一键部署：自动安装所有依赖和服务

## 系统要求

- 操作系统：Windows 10/11 (推荐WSL2)、Ubuntu 20.04+、macOS 10.15+
- Python 3.8 或更高版本
- 至少 8GB RAM
- 推荐使用 NVIDIA GPU（CUDA 11.8+）
- 约 10GB 磁盘空间（用于模型文件）

## 快速开始

### 第一步：下载项目

```bash
cd /mnt/e/Ai/videos/video-synthesis-project
```

### 第二步：运行安装脚本

```bash
# Linux/macOS/WSL2
./install.sh

# Windows (在Git Bash中运行)
bash install.sh
```

安装时会出现以下选项：
1. **完整安装**（推荐新手）：自动安装所有组件
2. **仅安装主程序**：如果你已经有GPT-SoVITS和MuseTalk服务
3. **仅安装GPT-SoVITS**：单独安装语音合成服务
4. **仅安装MuseTalk**：单独安装视频合成服务

### 第三步：启动服务

#### 方式一：启动所有服务（推荐）
```bash
./services/start_all.sh
```

#### 方式二：分别启动各个服务
```bash
# 1. 启动GPT-SoVITS
./services/gpt-sovits/start_service.sh

# 2. 启动MuseTalk
./services/musetalk/start_service.sh

# 3. 启动主服务
./start_server.sh
```

### 第四步：启动客户端

新开一个终端窗口：
```bash
./start_client.sh
```

## 使用说明

### 客户端操作

1. **输入文本**：在文本框中输入多段文本，每行一段
2. **选择视频**：点击"选择视频"按钮，选择一个参考视频文件
3. **参考音频**（可选）：如果想要特定的声音风格，可以上传参考音频
4. **开始合成**：点击"开始合成"按钮
5. **下载结果**：合成完成后，点击"下载结果"保存视频

### 测试模式

如果暂时无法安装完整的GPT-SoVITS和MuseTalk，可以使用Mock服务进行测试：

```bash
# 启动Mock服务
cd services
python gpt_sovits_mock.py &  # 在9880端口
python musetalk_mock.py &     # 在9881端口

# 然后启动主服务
cd ..
./start_server.sh
```

## 常见问题

### 1. 安装失败

**问题**：提示"未找到Python3"
**解决**：
- Windows: 从 [python.org](https://www.python.org/downloads/) 下载安装
- Ubuntu: `sudo apt-get install python3 python3-pip`
- macOS: `brew install python3`

**问题**：提示"未找到Git"
**解决**：
- Windows: 从 [git-scm.com](https://git-scm.com/) 下载安装
- Ubuntu: `sudo apt-get install git`
- macOS: `brew install git`

### 2. 服务启动失败

**问题**：端口被占用
**解决**：
- 检查端口：`netstat -tuln | grep -E '9880|9881|8000'`
- 修改配置文件 `server/config.py` 中的端口号

**问题**：模型下载失败
**解决**：
- 检查网络连接
- 使用代理：`export https_proxy=http://your-proxy:port`
- 手动下载模型文件到 `models/` 目录

### 3. GPU相关问题

**问题**：未检测到GPU
**解决**：
- 检查驱动：`nvidia-smi`
- 安装CUDA：访问 [NVIDIA官网](https://developer.nvidia.com/cuda-downloads)
- 使用CPU版本：安装时会自动选择

### 4. 客户端连接失败

**问题**：无法连接到服务器
**解决**：
- 确认服务已启动：`ps aux | grep python`
- 检查防火墙设置
- 确认服务器地址正确（默认 http://localhost:8000）

## 高级配置

### 修改服务地址

编辑 `server/config.py`：
```python
GPT_SOVITS_API_URL = "http://localhost:9880"  # GPT-SoVITS地址
MUSETALK_API_URL = "http://localhost:9881"    # MuseTalk地址
SERVER_HOST = "0.0.0.0"                        # 主服务监听地址
SERVER_PORT = 8000                             # 主服务端口
```

### 使用自定义模型

1. 将模型文件放到 `models/` 相应目录
2. 修改服务启动脚本中的模型路径
3. 重启服务

### Docker部署

如果你熟悉Docker，也可以使用Docker Compose：
```bash
docker-compose up -d
```

## 项目结构

```
video-synthesis-project/
├── install.sh              # 一键安装脚本
├── services/              # 服务相关文件
│   ├── gpt_sovits_setup.sh   # GPT-SoVITS安装脚本
│   ├── musetalk_setup.sh     # MuseTalk安装脚本
│   ├── start_all.sh          # 启动所有服务
│   └── stop_all.sh           # 停止所有服务
├── server/                # 服务端代码
│   ├── main.py              # FastAPI主程序
│   ├── tts_service.py       # 文字转语音服务
│   └── video_service.py     # 视频合成服务
├── client/                # 客户端代码
│   └── main.py              # PyQt5界面程序
├── models/                # 模型文件目录
├── temp/                  # 临时文件
├── output/                # 输出文件
└── logs/                  # 日志文件
```

## 停止服务

```bash
# 停止所有服务
./services/stop_all.sh

# 或手动停止
pkill -f "python.*main.py"
pkill -f "python.*start_api"
```

## 获取帮助

- 查看日志：`tail -f logs/*.log`
- 检查服务状态：`curl http://localhost:8000/health`
- 提交问题：在项目仓库创建Issue

## 注意事项

1. 首次运行需要下载较大的模型文件，请耐心等待
2. 建议使用GPU加速，CPU运行会比较慢
3. 确保有足够的磁盘空间（至少10GB）
4. 生成的视频文件会保存在 `output/` 目录

祝你使用愉快！如有问题，请查看日志文件或联系技术支持。