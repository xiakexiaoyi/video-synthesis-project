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
