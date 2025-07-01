#!/usr/bin/env python3
"""
MuseTalk 模拟API服务
提供基本的API接口用于测试和开发
"""

import os
import sys
import tempfile
import shutil
import subprocess
from pathlib import Path
from fastapi import FastAPI, UploadFile, File, HTTPException
from fastapi.responses import FileResponse
import uvicorn

app = FastAPI()

@app.post("/inference")
async def generate_video(
    audio: UploadFile = File(...),
    video: UploadFile = File(...)
):
    """视频合成接口（模拟）"""
    temp_dir = Path(tempfile.mkdtemp())
    
    try:
        # 保存上传的文件
        audio_path = temp_dir / "audio.wav"
        video_path = temp_dir / "video.mp4"
        output_path = temp_dir / "output.mp4"
        
        with open(audio_path, "wb") as f:
            f.write(await audio.read())
        with open(video_path, "wb") as f:
            f.write(await video.read())
        
        print(f"Mock video synthesis: {video.filename} + {audio.filename}")
        
        # 使用ffmpeg简单合并音视频（模拟）
        cmd = [
            'ffmpeg',
            '-i', str(video_path),
            '-i', str(audio_path),
            '-c:v', 'copy',
            '-c:a', 'aac',
            '-map', '0:v:0',
            '-map', '1:a:0',
            '-shortest',
            '-y',
            str(output_path)
        ]
        
        result = subprocess.run(cmd, capture_output=True, text=True)
        
        if result.returncode == 0 and output_path.exists():
            return FileResponse(
                output_path,
                media_type="video/mp4",
                filename="synthesized_video.mp4"
            )
        else:
            # 如果ffmpeg失败，直接返回原视频
            shutil.copy(video_path, output_path)
            return FileResponse(
                output_path,
                media_type="video/mp4",
                filename="synthesized_video.mp4"
            )
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        # 延迟清理临时文件
        pass

@app.get("/health")
async def health():
    """健康检查接口"""
    return {
        "status": "healthy",
        "service": "MuseTalk",
        "mode": "mock",
        "warning": "This is a mock service for testing"
    }

@app.get("/")
async def root():
    """根路径"""
    return {
        "service": "MuseTalk Mock API",
        "version": "1.0.0",
        "mode": "mock",
        "endpoints": {
            "health": "/health",
            "inference": "/inference"
        },
        "note": "This is a mock service. Replace with actual MuseTalk implementation."
    }

if __name__ == "__main__":
    port = int(os.getenv("MUSETALK_PORT", "9881"))
    host = os.getenv("MUSETALK_HOST", "0.0.0.0")
    
    print(f"Starting MuseTalk Mock API on {host}:{port}")
    print("WARNING: This is a mock service for testing purposes")
    uvicorn.run(app, host=host, port=port, log_level="info")