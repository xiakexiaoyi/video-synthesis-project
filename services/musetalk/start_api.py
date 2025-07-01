import os
import sys
sys.path.append(os.path.join(os.path.dirname(__file__), 'MuseTalk'))

from fastapi import FastAPI, UploadFile, File, HTTPException
from fastapi.responses import FileResponse
import uvicorn
import tempfile
import shutil
from pathlib import Path

# 设置模型路径
os.environ['MUSETALK_MODEL_PATH'] = str(Path(__file__).parent.parent.parent / "models" / "musetalk")

# 导入MuseTalk模块
from musetalk.utils.utils import get_file_type, get_video_fps, datagen
from musetalk.utils.preprocessing import get_landmark_and_bbox, read_imgs, coord_placeholder
from musetalk.utils.blending import get_image
from musetalk.utils.utils import load_all_model
import cv2
import numpy as np
import torch

app = FastAPI()

# 全局变量存储模型
audio_processor = None
vae = None
unet = None
pe = None
timesteps = None

@app.on_event("startup")
async def startup_event():
    global audio_processor, vae, unet, pe, timesteps
    print("加载MuseTalk模型...")
    audio_processor, vae, unet, pe, timesteps = load_all_model()
    print("模型加载完成")

@app.post("/inference")
async def generate_video(
    audio: UploadFile = File(...),
    video: UploadFile = File(...)
):
    temp_dir = Path(tempfile.mkdtemp())
    
    try:
        # 保存上传的文件
        audio_path = temp_dir / audio.filename
        video_path = temp_dir / video.filename
        
        with open(audio_path, "wb") as f:
            f.write(await audio.read())
        with open(video_path, "wb") as f:
            f.write(await video.read())
        
        # 输出路径
        output_path = temp_dir / "output.mp4"
        
        # 处理视频
        video_fps = get_video_fps(str(video_path))
        
        # 获取视频帧和关键点
        input_img_list = read_imgs(str(video_path))
        coord_list, frame_list = get_landmark_and_bbox(input_img_list, bbox_shift=0)
        
        # 生成数据
        whisper_chunks = datagen(
            whisper_chunks,
            str(audio_path),
            video_fps,
            model_a=audio_processor
        )
        
        # 生成视频帧
        res_frame_list = []
        for i, (whisper_chunk, coord, frame) in enumerate(
            zip(whisper_chunks, coord_list, frame_list)
        ):
            audio_feature = whisper_chunk["audio_feature"]
            gen_frame = get_image(
                audio_feature, 
                frame,
                coord,
                vae,
                unet,
                pe,
                timesteps,
                audio_processor,
                device="cuda" if torch.cuda.is_available() else "cpu"
            )
            res_frame_list.append(gen_frame)
        
        # 保存视频
        height, width = res_frame_list[0].shape[:2]
        fourcc = cv2.VideoWriter_fourcc(*'mp4v')
        out = cv2.VideoWriter(str(output_path), fourcc, video_fps, (width, height))
        
        for frame in res_frame_list:
            out.write(cv2.cvtColor(frame, cv2.COLOR_RGB2BGR))
        out.release()
        
        # 添加音频
        os.system(f'ffmpeg -i {output_path} -i {audio_path} -c:v copy -c:a aac -y {output_path}.tmp.mp4')
        shutil.move(f"{output_path}.tmp.mp4", output_path)
        
        return FileResponse(output_path, media_type="video/mp4")
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        # 清理临时文件
        if temp_dir.exists():
            shutil.rmtree(temp_dir)

@app.get("/health")
async def health():
    return {"status": "healthy", "service": "MuseTalk"}

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=9881)