#!/usr/bin/env python3
"""
GPT-SoVITS 模拟API服务
提供基本的API接口用于测试和开发
"""

import os
import sys
import tempfile
import wave
import struct
from pathlib import Path
from fastapi import FastAPI, HTTPException
from fastapi.responses import FileResponse
from pydantic import BaseModel
import uvicorn

app = FastAPI()

class TTSRequest(BaseModel):
    text: str
    text_language: str = "zh"
    ref_audio_path: str = None
    prompt_text: str = None
    prompt_language: str = "zh"
    top_k: int = 5
    top_p: float = 1.0
    temperature: float = 1.0

def generate_silence_wav(duration_seconds: float, filename: str):
    """生成指定时长的静音WAV文件"""
    sample_rate = 22050
    num_samples = int(duration_seconds * sample_rate)
    
    with wave.open(filename, 'wb') as wav_file:
        wav_file.setnchannels(1)  # 单声道
        wav_file.setsampwidth(2)   # 16位
        wav_file.setframerate(sample_rate)
        
        # 生成静音数据
        for _ in range(num_samples):
            wav_file.writeframes(struct.pack('h', 0))

@app.post("/tts")
async def text_to_speech(request: TTSRequest):
    """文本转语音接口（模拟）"""
    try:
        # 创建临时文件
        temp_file = tempfile.NamedTemporaryFile(suffix=".wav", delete=False)
        temp_file.close()
        
        # 根据文本长度生成相应时长的静音文件
        duration = len(request.text) * 0.1  # 每个字符0.1秒
        generate_silence_wav(duration, temp_file.name)
        
        print(f"Generated mock audio for text: {request.text[:50]}...")
        
        return FileResponse(
            temp_file.name,
            media_type="audio/wav",
            filename="tts_output.wav"
        )
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/health")
async def health():
    """健康检查接口"""
    return {
        "status": "healthy",
        "service": "GPT-SoVITS",
        "mode": "mock",
        "warning": "This is a mock service for testing"
    }

@app.get("/")
async def root():
    """根路径"""
    return {
        "service": "GPT-SoVITS Mock API",
        "version": "1.0.0",
        "mode": "mock",
        "endpoints": {
            "health": "/health",
            "tts": "/tts"
        },
        "note": "This is a mock service. Replace with actual GPT-SoVITS implementation."
    }

if __name__ == "__main__":
    port = int(os.getenv("GPT_SOVITS_PORT", "9880"))
    host = os.getenv("GPT_SOVITS_HOST", "0.0.0.0")
    
    print(f"Starting GPT-SoVITS Mock API on {host}:{port}")
    print("WARNING: This is a mock service for testing purposes")
    uvicorn.run(app, host=host, port=port, log_level="info")