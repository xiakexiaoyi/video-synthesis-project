# 部署指南

## 前置要求

1. GPT-SoVITS服务运行在 http://localhost:9880
2. MuseTalk服务运行在 http://localhost:9881
3. Python 3.8+
4. FFmpeg

## 快速启动

### 1. 启动服务端
```bash
./start_server.sh
```

### 2. 启动客户端
```bash
./start_client.sh
```

## Docker部署

使用Docker Compose部署所有服务：

```bash
docker-compose up -d
```

## 环境变量配置

服务端支持以下环境变量：

- `GPT_SOVITS_API_URL`: GPT-SoVITS API地址
- `MUSETALK_API_URL`: MuseTalk API地址

## API文档

服务启动后，访问 http://localhost:8000/docs 查看API文档