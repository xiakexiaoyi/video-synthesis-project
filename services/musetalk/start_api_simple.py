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

MUSETALK_DIR = Path(__file__).parent / "MuseTalk"

@app.post("/inference")
async def generate_video(
    audio: UploadFile = File(...),
    video: UploadFile = File(...)
):
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
        
        # 调用MuseTalk命令行
        cmd = [
            sys.executable,
            str(MUSETALK_DIR / "inference.py"),
            "--video", str(video_path),
            "--audio", str(audio_path),
            "--result_dir", str(temp_dir),
            "--use_saved_coord"
        ]
        
        env = os.environ.copy()
        env["PYTHONPATH"] = str(MUSETALK_DIR)
        
        result = subprocess.run(
            cmd,
            env=env,
            capture_output=True,
            text=True,
            cwd=str(MUSETALK_DIR)
        )
        
        if result.returncode != 0:
            raise Exception(f"MuseTalk error: {result.stderr}")
        
        # 查找输出文件
        output_files = list(temp_dir.glob("*.mp4"))
        if output_files and output_files[0] != video_path:
            return FileResponse(output_files[0], media_type="video/mp4")
        else:
            raise Exception("No output file generated")
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        # 延迟清理，让文件能够被下载
        pass

@app.get("/health")
async def health():
    return {"status": "healthy", "service": "MuseTalk"}

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=9881)