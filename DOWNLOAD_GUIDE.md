# AI 模型下载指南

## 快速开始

运行以下命令下载所有模型：

```bash
# 下载 GPT-SoVITS 模型（使用镜像站）
./download_models_mirror.sh

# 下载 MuseTalk 模型
./download_musetalk_models.sh
```

## 模型文件说明

### GPT-SoVITS 模型
位置：`models/gpt-sovits/`
- `s1bert25hz-5kh-longer-epoch=12-step=369668.ckpt` (1.9GB)
- `s2D2333k.pth`
- `s2G2333k.pth`

### MuseTalk 模型
需要多个子目录：

1. **主模型** - `models/musetalk/`
   - `pytorch_model.bin`
   - `musetalk.json`

2. **SD-VAE** - `models/sd-vae-ft-mse/`
   - `diffusion_pytorch_model.bin`
   - `config.json`

3. **Whisper** - `models/whisper/`
   - `tiny.pt`

4. **DWPose** - `models/dwpose/`
   - `dw-ll_ucoco_384.pth`

5. **Face Parsing** - `models/face-parse-bisent/`
   - `resnet18-5c106cde.pth`
   - `79999_iter.pth` (需要手动下载)

## 下载问题解决

### 1. 使用 HF-Mirror 镜像站
所有脚本默认使用 https://hf-mirror.com/ 镜像站加速下载。

### 2. 使用 aria2 加速
```bash
# 安装 aria2
sudo apt-get install aria2

# 使用 aria2 下载
./download_aria2_mirror.sh
```

### 3. 手动下载
如果自动下载失败，可以手动下载：

**GPT-SoVITS 模型：**
- 访问：https://hf-mirror.com/lj1995/GPT-SoVITS/tree/main/gsv-v2final-pretrained
- 下载后放到：`models/gpt-sovits/`

**MuseTalk 模型：**
- 主模型：https://hf-mirror.com/TMElyralab/MuseTalk
- SD-VAE：https://hf-mirror.com/stabilityai/sd-vae-ft-mse
- 其他模型见 `download_musetalk_models.sh` 中的链接

### 4. 使用代理
```bash
export https_proxy=http://your-proxy:port
export http_proxy=http://your-proxy:port
./download_models_mirror.sh
```

### 5. 检查下载完整性
```bash
# 列出所有模型文件
find models/ -type f -name "*.pth" -o -name "*.ckpt" -o -name "*.bin" -o -name "*.pt" | sort
```

## 常见问题

### 404 错误
- 检查链接是否正确
- 尝试访问 HuggingFace 页面确认文件存在
- 使用备用下载方法

### 下载速度慢
- 使用 aria2 多线程下载
- 使用镜像站
- 在网络较好的时段下载

### 磁盘空间不足
- GPT-SoVITS 模型约 2-3GB
- MuseTalk 模型约 1-2GB
- 确保有至少 10GB 可用空间

## 参考链接

- GPT-SoVITS: https://github.com/RVC-Boss/GPT-SoVITS
- MuseTalk: https://github.com/TMElyralab/MuseTalk
- HF-Mirror: https://hf-mirror.com/