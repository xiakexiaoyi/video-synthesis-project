#!/usr/bin/env python3
"""
GPT-SoVITS API Wrapper
通过启动webui并提供REST API接口
"""

import os
import sys
import subprocess
import time
import requests
import tempfile
from pathlib import Path
from fastapi import FastAPI, HTTPException
from fastapi.responses import FileResponse
from pydantic import BaseModel
import uvicorn
import threading

app = FastAPI()

# GPT-SoVITS进程
gpt_sovits_process = None
WEBUI_PORT = 9879  # GPT-SoVITS WebUI端口

class TTSRequest(BaseModel):
    text: str
    text_language: str = "zh"
    ref_audio_path: str = None
    prompt_text: str = None
    prompt_language: str = "zh"
    top_k: int = 5
    top_p: float = 1.0
    temperature: float = 1.0

def start_gpt_sovits_webui():
    """启动GPT-SoVITS WebUI"""
    global gpt_sovits_process
    
    current_dir = Path(__file__).parent
    gpt_sovits_dir = current_dir / "GPT-SoVITS"
    
    if not gpt_sovits_dir.exists():
        print(f"Error: GPT-SoVITS directory not found at {gpt_sovits_dir}")
        return False
    
    # 启动webui
    cmd = [sys.executable, "webui.py", "--port", str(WEBUI_PORT)]
    
    env = os.environ.copy()
    env["PYTHONPATH"] = str(gpt_sovits_dir)
    
    try:
        gpt_sovits_process = subprocess.Popen(
            cmd,
            cwd=str(gpt_sovits_dir),
            env=env,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE
        )
        
        # 等待服务启动
        print("Waiting for GPT-SoVITS WebUI to start...")
        for i in range(30):
            try:
                response = requests.get(f"http://localhost:{WEBUI_PORT}")
                if response.status_code == 200:
                    print(f"GPT-SoVITS WebUI started on port {WEBUI_PORT}")
                    return True
            except:
                pass
            time.sleep(1)
        
        print("GPT-SoVITS WebUI failed to start")
        return False
        
    except Exception as e:
        print(f"Error starting GPT-SoVITS: {e}")
        return False

@app.on_event("startup")
async def startup_event():
    """启动时运行GPT-SoVITS WebUI"""
    thread = threading.Thread(target=start_gpt_sovits_webui)
    thread.daemon = True
    thread.start()
    
    # 等待一段时间让WebUI启动
    time.sleep(5)

@app.on_event("shutdown")
async def shutdown_event():
    """关闭时停止GPT-SoVITS WebUI"""
    global gpt_sovits_process
    if gpt_sovits_process:
        gpt_sovits_process.terminate()
        gpt_sovits_process.wait()

@app.post("/tts")
async def text_to_speech(request: TTSRequest):
    """文本转语音接口"""
    try:
        # 创建临时输出文件
        output_file = tempfile.NamedTemporaryFile(suffix=".wav", delete=False).name
        
        # 构建请求数据
        data = {
            "text": request.text,
            "text_language": request.text_language,
            "top_k": request.top_k,
            "top_p": request.top_p,
            "temperature": request.temperature,
            "output_path": output_file
        }
        
        if request.ref_audio_path and request.prompt_text:
            data.update({
                "ref_audio_path": request.ref_audio_path,
                "prompt_text": request.prompt_text,
                "prompt_language": request.prompt_language
            })
        
        # 发送请求到WebUI API
        response = requests.post(
            f"http://localhost:{WEBUI_PORT}/tts",
            json=data,
            timeout=60
        )
        
        if response.status_code == 200:
            if os.path.exists(output_file):
                return FileResponse(
                    output_file,
                    media_type="audio/wav",
                    filename="tts_output.wav"
                )
            else:
                raise Exception("Output file not generated")
        else:
            raise Exception(f"WebUI API error: {response.status_code}")
            
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/health")
async def health():
    """健康检查接口"""
    try:
        # 检查WebUI是否运行
        response = requests.get(f"http://localhost:{WEBUI_PORT}", timeout=5)
        webui_status = response.status_code == 200
    except:
        webui_status = False
    
    return {
        "status": "healthy" if webui_status else "unhealthy",
        "service": "GPT-SoVITS",
        "webui_running": webui_status,
        "webui_port": WEBUI_PORT
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
        "webui_port": WEBUI_PORT
    }

if __name__ == "__main__":
    port = int(os.getenv("GPT_SOVITS_PORT", "9880"))
    host = os.getenv("GPT_SOVITS_HOST", "0.0.0.0")
    
    print(f"Starting GPT-SoVITS API Wrapper on {host}:{port}")
    uvicorn.run(app, host=host, port=port, log_level="info")