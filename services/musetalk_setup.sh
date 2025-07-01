#!/bin/bash

echo "=== MuseTalk 安装脚本 ==="

SERVICE_DIR="$(dirname "$0")/musetalk"
MODEL_DIR="$(dirname "$0")/../models/musetalk"

# 检查系统依赖
if ! command -v ffmpeg &> /dev/null; then
    echo "警告: 未找到ffmpeg，正在安装..."
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        sudo apt-get update && sudo apt-get install -y ffmpeg
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        brew install ffmpeg
    fi
fi

# 创建目录
mkdir -p "$SERVICE_DIR"
mkdir -p "$MODEL_DIR"

cd "$SERVICE_DIR"

# 克隆MuseTalk仓库
if [ ! -d "MuseTalk" ]; then
    echo "正在克隆MuseTalk仓库..."
    git clone https://github.com/TMElyralab/MuseTalk.git
    cd MuseTalk
else
    echo "MuseTalk已存在，更新中..."
    cd MuseTalk
    git pull
fi

# 创建虚拟环境
if [ ! -d "venv" ]; then
    echo "创建Python虚拟环境..."
    python3 -m venv venv
fi

# 激活虚拟环境并安装依赖
source venv/bin/activate

echo "安装依赖..."
pip install --upgrade pip
pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118
pip install -r requirements.txt
pip install fastapi uvicorn python-multipart

# 下载预训练模型
echo "下载预训练模型..."
cd "$MODEL_DIR"

# MuseTalk模型下载
models=(
    "https://huggingface.co/TMElyralab/MuseTalk/resolve/main/models/dwpose/yolox_l_8x8_300e_coco.pth"
    "https://huggingface.co/TMElyralab/MuseTalk/resolve/main/models/dwpose/dw-ll_ucoco_384.pth"
    "https://huggingface.co/TMElyralab/MuseTalk/resolve/main/models/face-parse-bisent/79999_iter.pth"
    "https://huggingface.co/TMElyralab/MuseTalk/resolve/main/models/sd-vae-ft-mse/diffusion_pytorch_model.bin"
    "https://huggingface.co/TMElyralab/MuseTalk/resolve/main/models/musetalk/musetalk.json"
    "https://huggingface.co/TMElyralab/MuseTalk/resolve/main/models/musetalk/pytorch_model.bin"
)

# 创建模型子目录
mkdir -p dwpose face-parse-bisent sd-vae-ft-mse musetalk

# 下载模型文件
for model_url in "${models[@]}"; do
    filename=$(basename "$model_url")
    subdir=$(echo "$model_url" | cut -d'/' -f8)
    
    if [ ! -f "$subdir/$filename" ]; then
        echo "下载 $filename 到 $subdir/ ..."
        wget -c "$model_url" -O "$subdir/$filename"
    else
        echo "$subdir/$filename 已存在，跳过下载"
    fi
done

# 创建API服务脚本
cat > "${SERVICE_DIR}/start_api.py" << 'EOF'
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
EOF

# 创建简化的MuseTalk API服务（使用命令行接口）
cat > "${SERVICE_DIR}/start_api_simple.py" << 'EOF'
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
EOF

# 创建服务启动脚本
cat > "${SERVICE_DIR}/start_service.sh" << 'EOF'
#!/bin/bash
cd "$(dirname "$0")"
source MuseTalk/venv/bin/activate
export PYTHONPATH="$PWD/MuseTalk:$PYTHONPATH"
python start_api_simple.py
EOF

chmod +x "${SERVICE_DIR}/start_service.sh"

echo "MuseTalk 安装完成！"
echo "启动命令: ${SERVICE_DIR}/start_service.sh"