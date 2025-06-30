# 视频合成项目

基于GPT-SoVITS和MuseTalk的视频合成系统

## 项目结构

```
video-synthesis-project/
├── server/          # 服务端代码
├── client/          # 桌面客户端代码
├── temp/           # 临时文件目录
└── output/         # 输出视频目录
```

## 依赖项

### 服务端
- Python 3.8+
- FastAPI
- GPT-SoVITS
- MuseTalk
- ffmpeg

### 客户端
- Python 3.8+
- PyQt5/Tkinter
- requests