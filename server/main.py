from fastapi import FastAPI, UploadFile, File, Form, HTTPException, BackgroundTasks
from fastapi.responses import FileResponse, StreamingResponse
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import List, Optional
import os
import uuid
from pathlib import Path
import shutil
import asyncio
from datetime import datetime

from config import SERVER_HOST, SERVER_PORT, TEMP_DIR, OUTPUT_DIR
from tts_service import TTSService
from video_service import VideoService

app = FastAPI(title="Video Synthesis API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

tts_service = TTSService()
video_service = VideoService()

class TextItem(BaseModel):
    text: str
    index: int

class SynthesisRequest(BaseModel):
    texts: List[str]
    ref_text: Optional[str] = None
    language: str = "zh"

class TaskStatus(BaseModel):
    task_id: str
    status: str
    progress: int
    message: str
    result_urls: Optional[List[str]] = None

tasks = {}

@app.post("/synthesize")
async def synthesize_videos(
    background_tasks: BackgroundTasks,
    texts: str = Form(...),
    video: UploadFile = File(...),
    ref_audio: Optional[UploadFile] = File(None),
    ref_text: Optional[str] = Form(None),
    language: str = Form("zh")
):
    """
    合成视频的主接口
    """
    task_id = str(uuid.uuid4())
    
    task_dir = TEMP_DIR / task_id
    task_dir.mkdir(exist_ok=True)
    
    video_path = task_dir / f"input_{video.filename}"
    with open(video_path, "wb") as f:
        f.write(await video.read())
    
    ref_audio_path = None
    if ref_audio:
        ref_audio_path = task_dir / f"ref_{ref_audio.filename}"
        with open(ref_audio_path, "wb") as f:
            f.write(await ref_audio.read())
    
    text_list = [t.strip() for t in texts.split('\n') if t.strip()]
    
    tasks[task_id] = {
        "status": "processing",
        "progress": 0,
        "message": "任务已创建",
        "result_urls": None
    }
    
    background_tasks.add_task(
        process_synthesis,
        task_id,
        text_list,
        str(video_path),
        str(ref_audio_path) if ref_audio_path else None,
        ref_text,
        language
    )
    
    return {"task_id": task_id}

async def process_synthesis(
    task_id: str,
    texts: List[str],
    video_path: str,
    ref_audio_path: Optional[str],
    ref_text: Optional[str],
    language: str
):
    """
    后台处理合成任务
    """
    try:
        task_dir = TEMP_DIR / task_id
        audio_dir = task_dir / "audios"
        video_dir = task_dir / "videos"
        audio_dir.mkdir(exist_ok=True)
        video_dir.mkdir(exist_ok=True)
        
        tasks[task_id]["status"] = "converting_audio"
        tasks[task_id]["message"] = "正在转换文本为语音..."
        
        audio_paths = await tts_service.batch_text_to_speech(
            texts,
            str(audio_dir),
            ref_audio_path,
            ref_text,
            language
        )
        
        tasks[task_id]["progress"] = 40
        tasks[task_id]["status"] = "generating_videos"
        tasks[task_id]["message"] = "正在生成说话视频..."
        
        video_paths = await video_service.batch_generate_videos(
            audio_paths,
            video_path,
            str(video_dir)
        )
        
        tasks[task_id]["progress"] = 80
        tasks[task_id]["status"] = "merging"
        tasks[task_id]["message"] = "正在合并视频..."
        
        final_output_path = OUTPUT_DIR / f"{task_id}_final.mp4"
        await video_service.merge_videos(video_paths, str(final_output_path))
        
        output_paths = []
        for i, video_path in enumerate(video_paths):
            individual_output = OUTPUT_DIR / f"{task_id}_segment_{i}.mp4"
            shutil.copy(video_path, individual_output)
            output_paths.append(f"/download/{task_id}_segment_{i}.mp4")
        
        output_paths.append(f"/download/{task_id}_final.mp4")
        
        tasks[task_id]["status"] = "completed"
        tasks[task_id]["progress"] = 100
        tasks[task_id]["message"] = "处理完成"
        tasks[task_id]["result_urls"] = output_paths
        
    except Exception as e:
        tasks[task_id]["status"] = "failed"
        tasks[task_id]["message"] = f"处理失败: {str(e)}"
    
    finally:
        if (TEMP_DIR / task_id).exists():
            shutil.rmtree(TEMP_DIR / task_id)

@app.get("/task/{task_id}")
async def get_task_status(task_id: str):
    """
    获取任务状态
    """
    if task_id not in tasks:
        raise HTTPException(status_code=404, detail="任务不存在")
    
    return TaskStatus(**tasks[task_id])

@app.get("/download/{filename}")
async def download_file(filename: str):
    """
    下载生成的视频文件
    """
    file_path = OUTPUT_DIR / filename
    if not file_path.exists():
        raise HTTPException(status_code=404, detail="文件不存在")
    
    return FileResponse(
        file_path,
        media_type="video/mp4",
        filename=filename
    )

@app.delete("/task/{task_id}")
async def delete_task(task_id: str):
    """
    删除任务及其相关文件
    """
    if task_id in tasks:
        del tasks[task_id]
    
    for file in OUTPUT_DIR.glob(f"{task_id}_*"):
        file.unlink()
    
    return {"message": "任务已删除"}

@app.get("/health")
async def health_check():
    """
    健康检查
    """
    return {"status": "healthy", "timestamp": datetime.now().isoformat()}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host=SERVER_HOST, port=SERVER_PORT)