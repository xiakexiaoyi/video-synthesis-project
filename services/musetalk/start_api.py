#!/usr/bin/env python3
"""
MuseTalk API启动脚本
如果MuseTalk存在，启动其API；否则提供基本的视频合成功能
"""

import os
import sys
import subprocess
from pathlib import Path

# 获取路径
current_dir = Path(__file__).parent
musetalk_dir = current_dir / "MuseTalk"

# 检查MuseTalk是否存在
if musetalk_dir.exists():
    # 如果MuseTalk存在，尝试导入并运行
    sys.path.insert(0, str(musetalk_dir))
    os.chdir(musetalk_dir)
    
    # 检查是否有inference.py
    if (musetalk_dir / "inference.py").exists():
        print("找到MuseTalk，启动推理服务...")
        # 这里应该导入MuseTalk的模块并启动服务
        # 但由于MuseTalk的具体实现可能不同，我们使用FastAPI包装
        
from fastapi import FastAPI, UploadFile, File, HTTPException
from fastapi.responses import FileResponse
import uvicorn
import tempfile
import shutil

app = FastAPI()

@app.post("/inference")
async def generate_video(
    audio: UploadFile = File(...),
    video: UploadFile = File(...)
):
    """视频合成接口"""
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
        
        if musetalk_dir.exists() and (musetalk_dir / "inference.py").exists():
            # 使用MuseTalk进行推理
            cmd = [
                sys.executable,
                str(musetalk_dir / "inference.py"),
                "--video", str(video_path),
                "--audio", str(audio_path),
                "--result_dir", str(temp_dir)
            ]
            
            env = os.environ.copy()
            env["PYTHONPATH"] = str(musetalk_dir)
            
            result = subprocess.run(
                cmd,
                env=env,
                capture_output=True,
                text=True,
                cwd=str(musetalk_dir)
            )
            
            if result.returncode != 0:
                print(f"MuseTalk错误: {result.stderr}")
                # 如果MuseTalk失败，使用ffmpeg作为后备
                subprocess.run([
                    'ffmpeg', '-i', str(video_path), '-i', str(audio_path),
                    '-c:v', 'copy', '-c:a', 'aac', '-shortest', '-y', str(output_path)
                ], check=True)
        else:
            # 没有MuseTalk，使用ffmpeg合并
            print("MuseTalk未安装，使用ffmpeg合并音视频...")
            subprocess.run([
                'ffmpeg', '-i', str(video_path), '-i', str(audio_path),
                '-c:v', 'copy', '-c:a', 'aac', '-shortest', '-y', str(output_path)
            ], check=True)
        
        # 查找输出文件
        if not output_path.exists():
            output_files = list(temp_dir.glob("*.mp4"))
            if output_files:
                output_path = output_files[0]
        
        if output_path.exists():
            return FileResponse(
                output_path,
                media_type="video/mp4",
                filename="synthesized_video.mp4"
            )
        else:
            raise Exception("未生成输出文件")
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        # 延迟清理
        pass

@app.get("/health")
async def health():
    """健康检查接口"""
    return {
        "status": "healthy",
        "service": "MuseTalk",
        "musetalk_installed": musetalk_dir.exists()
    }

@app.get("/")
async def root():
    """根路径"""
    return {
        "service": "MuseTalk API",
        "version": "1.0.0",
        "endpoints": {
            "health": "/health",
            "inference": "/inference"
        },
        "musetalk_installed": musetalk_dir.exists()
    }

if __name__ == "__main__":
    port = int(os.getenv("MUSETALK_PORT", "9881"))
    host = os.getenv("MUSETALK_HOST", "0.0.0.0")
    
    print(f"启动MuseTalk API服务: {host}:{port}")
    if not musetalk_dir.exists():
        print("警告: MuseTalk未安装，使用ffmpeg作为后备方案")
    
    uvicorn.run(app, host=host, port=port, log_level="info")