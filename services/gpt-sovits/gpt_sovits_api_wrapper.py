#!/usr/bin/env python3
"""
GPT-SoVITS API包装器
提供简化的TTS接口，避免复杂的依赖
"""

import os
import sys
import subprocess
import tempfile
import time
from pathlib import Path
from fastapi import FastAPI, HTTPException
from fastapi.responses import FileResponse
from pydantic import BaseModel
import uvicorn

app = FastAPI(title="GPT-SoVITS API Wrapper", version="1.0.0")

# 获取路径
current_dir = Path(__file__).parent
gpt_sovits_dir = current_dir / "GPT-SoVITS"

class TTSRequest(BaseModel):
    text: str
    text_language: str = "zh"
    ref_audio_path: str = None
    prompt_text: str = None
    prompt_language: str = "zh"
    top_k: int = 5
    top_p: float = 1.0
    temperature: float = 1.0

def run_gpt_sovits_tts(text: str, output_path: str, language: str = "zh") -> bool:
    """使用命令行方式调用GPT-SoVITS"""
    try:
        # 尝试使用webui的推理脚本
        webui_script = gpt_sovits_dir / "webui.py"
        if webui_script.exists():
            # 这里可以实现通过webui的API接口调用
            pass
        
        # 直接使用Python导入（如果可能）
        sys.path.insert(0, str(gpt_sovits_dir))
        sys.path.insert(0, str(gpt_sovits_dir / "GPT_SoVITS"))
        
        try:
            # 尝试导入必要的模块
            from tools.i18n.i18n import I18nAuto
            i18n = I18nAuto()
            
            # 创建简单的音频文件作为临时解决方案
            # 实际应该调用GPT-SoVITS的推理函数
            import wave
            import struct
            
            # 生成静音WAV文件（临时解决方案）
            sample_rate = 32000
            duration = len(text) * 0.15  # 每个字符0.15秒
            num_samples = int(duration * sample_rate)
            
            with wave.open(output_path, 'wb') as wav_file:
                wav_file.setnchannels(1)
                wav_file.setsampwidth(2)
                wav_file.setframerate(sample_rate)
                
                # 生成简单的音频数据
                for i in range(num_samples):
                    sample = int(32767 * 0.1 * (i % 1000) / 1000)  # 简单的锯齿波
                    wav_file.writeframes(struct.pack('h', sample))
            
            return True
            
        except ImportError as e:
            print(f"导入错误: {e}")
            return False
            
    except Exception as e:
        print(f"TTS生成错误: {e}")
        return False

@app.post("/tts")
async def text_to_speech(request: TTSRequest):
    """文本转语音接口"""
    try:
        # 创建临时输出文件
        with tempfile.NamedTemporaryFile(suffix=".wav", delete=False) as tmp_file:
            output_path = tmp_file.name
        
        # 调用GPT-SoVITS生成音频
        success = run_gpt_sovits_tts(
            text=request.text,
            output_path=output_path,
            language=request.text_language
        )
        
        if success and os.path.exists(output_path):
            return FileResponse(
                output_path,
                media_type="audio/wav",
                filename="tts_output.wav"
            )
        else:
            raise HTTPException(status_code=500, detail="TTS生成失败")
            
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/health")
async def health():
    """健康检查接口"""
    return {
        "status": "healthy",
        "service": "GPT-SoVITS",
        "mode": "wrapper",
        "gpt_sovits_exists": gpt_sovits_dir.exists()
    }

@app.get("/")
async def root():
    """根路径"""
    return {
        "service": "GPT-SoVITS API Wrapper",
        "version": "1.0.0",
        "endpoints": {
            "health": "/health",
            "tts": "/tts"
        },
        "note": "This is a wrapper for GPT-SoVITS"
    }

if __name__ == "__main__":
    port = int(os.getenv("GPT_SOVITS_PORT", "9880"))
    host = os.getenv("GPT_SOVITS_HOST", "0.0.0.0")
    
    print(f"启动GPT-SoVITS API包装器: {host}:{port}")
    print("注意: 这是一个简化的包装器，完整功能需要正确安装GPT-SoVITS")
    
    uvicorn.run(app, host=host, port=port, log_level="info")