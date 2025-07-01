#!/usr/bin/env python3
"""
GPT-SoVITS 简化API服务
使用subprocess调用GPT-SoVITS的命令行接口
"""

import os
import sys
import tempfile
import subprocess
import shutil
from pathlib import Path
from fastapi import FastAPI, HTTPException
from fastapi.responses import FileResponse
from pydantic import BaseModel
import uvicorn
import json

app = FastAPI()

# GPT-SoVITS目录
GPT_SOVITS_DIR = Path(__file__).parent / "GPT-SoVITS"

class TTSRequest(BaseModel):
    text: str
    text_language: str = "zh"
    ref_audio_path: str = None
    prompt_text: str = None
    prompt_language: str = "zh"
    top_k: int = 5
    top_p: float = 1.0
    temperature: float = 1.0

@app.post("/tts")
async def text_to_speech(request: TTSRequest):
    """文本转语音接口"""
    temp_dir = Path(tempfile.mkdtemp())
    
    try:
        output_file = temp_dir / "output.wav"
        
        # 构建命令行参数
        cmd = [
            sys.executable,
            str(GPT_SOVITS_DIR / "api.py"),
            "-t", request.text,
            "-o", str(output_file),
            "-l", request.text_language,
            "--top_k", str(request.top_k),
            "--top_p", str(request.top_p),
            "--temperature", str(request.temperature)
        ]
        
        # 添加参考音频和文本（如果提供）
        if request.ref_audio_path and request.prompt_text:
            cmd.extend([
                "-r", request.ref_audio_path,
                "-p", request.prompt_text,
                "-pl", request.prompt_language
            ])
        
        # 设置环境变量
        env = os.environ.copy()
        env["PYTHONPATH"] = str(GPT_SOVITS_DIR)
        
        # 执行命令
        result = subprocess.run(
            cmd,
            env=env,
            capture_output=True,
            text=True,
            cwd=str(GPT_SOVITS_DIR)
        )
        
        if result.returncode != 0:
            raise Exception(f"GPT-SoVITS error: {result.stderr}")
        
        if output_file.exists():
            return FileResponse(
                output_file,
                media_type="audio/wav",
                filename="tts_output.wav"
            )
        else:
            raise Exception("No output file generated")
            
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
        "service": "GPT-SoVITS",
        "mode": "simple"
    }

@app.get("/")
async def root():
    """根路径"""
    return {
        "service": "GPT-SoVITS API",
        "version": "1.0.0",
        "endpoints": {
            "health": "/health",
            "tts": "/tts"
        }
    }

if __name__ == "__main__":
    port = int(os.getenv("GPT_SOVITS_PORT", "9880"))
    host = os.getenv("GPT_SOVITS_HOST", "0.0.0.0")
    
    print(f"Starting GPT-SoVITS Simple API on {host}:{port}")
    uvicorn.run(app, host=host, port=port, log_level="info")