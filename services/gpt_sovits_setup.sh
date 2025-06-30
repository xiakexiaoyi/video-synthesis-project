#!/bin/bash

echo "=== GPT-SoVITS 安装脚本 ==="

SERVICE_DIR="$(dirname "$0")/gpt-sovits"
MODEL_DIR="$(dirname "$0")/../models/gpt-sovits"

# 检查Python版本
python_version=$(python3 --version 2>&1 | awk '{print $2}')
if [ -z "$python_version" ]; then
    echo "错误: 未找到Python3，请先安装Python 3.8或更高版本"
    exit 1
fi

# 创建目录
mkdir -p "$SERVICE_DIR"
mkdir -p "$MODEL_DIR"

cd "$SERVICE_DIR"

# 克隆GPT-SoVITS仓库
if [ ! -d "GPT-SoVITS" ]; then
    echo "正在克隆GPT-SoVITS仓库..."
    git clone https://github.com/RVC-Boss/GPT-SoVITS.git
    cd GPT-SoVITS
else
    echo "GPT-SoVITS已存在，更新中..."
    cd GPT-SoVITS
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

# 下载预训练模型
echo "下载预训练模型..."
cd "$MODEL_DIR"

# 下载基础模型
models=(
    "https://huggingface.co/lj1995/GPT-SoVITS/resolve/main/gsv-v2final-pretrained/s1bert25hz-5kh-longer-epoch=12-step=369668.ckpt"
    "https://huggingface.co/lj1995/GPT-SoVITS/resolve/main/gsv-v2final-pretrained/s2D2333k.pth"
    "https://huggingface.co/lj1995/GPT-SoVITS/resolve/main/gsv-v2final-pretrained/s2G2333k.pth"
)

for model_url in "${models[@]}"; do
    filename=$(basename "$model_url")
    if [ ! -f "$filename" ]; then
        echo "下载 $filename ..."
        wget -c "$model_url" -O "$filename"
    else
        echo "$filename 已存在，跳过下载"
    fi
done

# 创建API服务启动脚本
cat > "$SERVICE_DIR/start_api.py" << 'EOF'
import os
import sys
sys.path.append(os.path.join(os.path.dirname(__file__), 'GPT-SoVITS'))

from fastapi import FastAPI, HTTPException
from fastapi.responses import FileResponse
from pydantic import BaseModel
import uvicorn
import tempfile
import uuid

# 导入GPT-SoVITS模块
from GPT_SoVITS.inference_webui import change_gpt_weights, change_sovits_weights, get_tts_wav

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

@app.on_event("startup")
async def startup_event():
    # 加载默认模型
    gpt_path = "../../models/gpt-sovits/s1bert25hz-5kh-longer-epoch=12-step=369668.ckpt"
    sovits_path = "../../models/gpt-sovits/s2G2333k.pth"
    
    if os.path.exists(gpt_path) and os.path.exists(sovits_path):
        change_gpt_weights(gpt_path)
        change_sovits_weights(sovits_path)
        print("模型加载成功")
    else:
        print("警告: 模型文件未找到")

@app.post("/tts")
async def text_to_speech(request: TTSRequest):
    try:
        output_file = tempfile.mktemp(suffix=".wav")
        
        get_tts_wav(
            ref_wav_path=request.ref_audio_path,
            prompt_text=request.prompt_text,
            prompt_language=request.prompt_language,
            text=request.text,
            text_language=request.text_language,
            how_to_cut="按标点符号切",
            top_k=request.top_k,
            top_p=request.top_p,
            temperature=request.temperature,
            ref_free=request.ref_audio_path is None,
            if_freeze=False,
            speed=1,
            inp_refs=[],
            output_path=output_file
        )
        
        return FileResponse(output_file, media_type="audio/wav")
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/health")
async def health():
    return {"status": "healthy", "service": "GPT-SoVITS"}

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=9880)
EOF

# 创建服务启动脚本
cat > "$SERVICE_DIR/start_service.sh" << 'EOF'
#!/bin/bash
cd "$(dirname "$0")"
source GPT-SoVITS/venv/bin/activate
python start_api.py
EOF

chmod +x "$SERVICE_DIR/start_service.sh"

echo "GPT-SoVITS 安装完成！"
echo "启动命令: $SERVICE_DIR/start_service.sh"