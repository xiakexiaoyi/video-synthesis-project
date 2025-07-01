#!/usr/bin/env python3
"""
MuseTalk API服务
提供完整的MuseTalk视频合成功能
"""

import os
import sys
import subprocess
import tempfile
import shutil
from pathlib import Path
from fastapi import FastAPI, UploadFile, File, HTTPException
from fastapi.responses import FileResponse
import uvicorn
import importlib.util

# 获取路径
current_dir = Path(__file__).parent
musetalk_dir = current_dir / "MuseTalk"

# 创建FastAPI应用
app = FastAPI(title="MuseTalk API", version="1.0.0")

# 检查MuseTalk是否已安装
musetalk_installed = musetalk_dir.exists()

if musetalk_installed:
    # 添加MuseTalk到Python路径
    sys.path.insert(0, str(musetalk_dir))
    os.environ['PYTHONPATH'] = f"{musetalk_dir}:{os.environ.get('PYTHONPATH', '')}"

@app.on_event("startup")
async def startup_event():
    """启动时检查依赖"""
    if musetalk_installed:
        # 检查必要的依赖
        required_modules = ['cv2', 'numpy', 'torch', 'torchvision']
        missing_modules = []
        
        for module in required_modules:
            if importlib.util.find_spec(module) is None:
                missing_modules.append(module)
        
        if missing_modules:
            print(f"警告: 缺少依赖模块: {', '.join(missing_modules)}")
            print("MuseTalk可能无法正常工作")
    else:
        print("警告: MuseTalk未安装")
        print("请运行 musetalk_setup.sh 安装MuseTalk")

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
        output_dir = temp_dir / "results"
        output_dir.mkdir(exist_ok=True)
        
        with open(audio_path, "wb") as f:
            content = await audio.read()
            f.write(content)
            
        with open(video_path, "wb") as f:
            content = await video.read()
            f.write(content)
        
        if musetalk_installed:
            # 使用MuseTalk进行推理
            inference_script = musetalk_dir / "inference.py"
            
            if inference_script.exists():
                cmd = [
                    sys.executable,
                    str(inference_script),
                    "--video_path", str(video_path),
                    "--audio_path", str(audio_path),
                    "--bbox_shift", "0",
                    "--result_dir", str(output_dir)
                ]
                
                env = os.environ.copy()
                env["PYTHONPATH"] = str(musetalk_dir)
                
                print(f"执行MuseTalk推理: {' '.join(cmd)}")
                
                result = subprocess.run(
                    cmd,
                    env=env,
                    capture_output=True,
                    text=True,
                    cwd=str(musetalk_dir)
                )
                
                if result.returncode == 0:
                    # 查找生成的视频文件
                    output_files = list(output_dir.glob("*.mp4"))
                    if output_files:
                        output_path = output_files[0]
                        return FileResponse(
                            output_path,
                            media_type="video/mp4",
                            filename="synthesized_video.mp4"
                        )
                    else:
                        raise Exception("MuseTalk未生成输出文件")
                else:
                    error_msg = f"MuseTalk推理失败: {result.stderr}"
                    print(error_msg)
                    raise Exception(error_msg)
            else:
                raise Exception(f"找不到MuseTalk推理脚本: {inference_script}")
        else:
            # MuseTalk未安装，使用ffmpeg合并音视频
            output_path = temp_dir / "output.mp4"
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
                raise Exception(f"视频合成失败: {result.stderr}")
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        # 延迟清理临时文件，让响应能够完成
        pass

@app.get("/health")
async def health():
    """健康检查接口"""
    return {
        "status": "healthy",
        "service": "MuseTalk",
        "musetalk_installed": musetalk_installed,
        "port": 9881
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
        "musetalk_installed": musetalk_installed
    }

if __name__ == "__main__":
    port = int(os.getenv("MUSETALK_PORT", "9881"))
    host = os.getenv("MUSETALK_HOST", "0.0.0.0")
    
    print(f"启动MuseTalk API服务: {host}:{port}")
    if not musetalk_installed:
        print("警告: MuseTalk未安装，将使用ffmpeg作为后备方案")
        print("要获得完整功能，请运行: ./musetalk_setup.sh")
    
    uvicorn.run(app, host=host, port=port, log_level="info")