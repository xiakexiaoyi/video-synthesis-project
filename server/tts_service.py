import os
import requests
import json
from pathlib import Path
from typing import Optional
import aiofiles
import asyncio
from config import GPT_SOVITS_API_URL, TEMP_DIR

class TTSService:
    def __init__(self):
        self.api_url = GPT_SOVITS_API_URL
        
    async def text_to_speech(
        self, 
        text: str, 
        output_path: str,
        ref_audio_path: Optional[str] = None,
        ref_text: Optional[str] = None,
        language: str = "zh"
    ) -> str:
        """
        调用GPT-SoVITS API将文本转换为语音
        """
        try:
            data = {
                "text": text,
                "text_language": language,
                "top_k": 5,
                "top_p": 1,
                "temperature": 1
            }
            
            if ref_audio_path and ref_text:
                data.update({
                    "ref_audio_path": ref_audio_path,
                    "prompt_text": ref_text,
                    "prompt_language": language
                })
            
            response = requests.post(
                f"{self.api_url}/tts",
                json=data,
                stream=True,
                timeout=60
            )
            
            if response.status_code == 200:
                async with aiofiles.open(output_path, 'wb') as f:
                    for chunk in response.iter_content(chunk_size=1024):
                        if chunk:
                            await f.write(chunk)
                return output_path
            else:
                raise Exception(f"TTS API error: {response.status_code}")
                
        except Exception as e:
            raise Exception(f"TTS conversion failed: {str(e)}")
    
    async def batch_text_to_speech(
        self,
        texts: list[str],
        output_dir: str,
        ref_audio_path: Optional[str] = None,
        ref_text: Optional[str] = None,
        language: str = "zh"
    ) -> list[str]:
        """
        批量转换文本为语音
        """
        output_dir = Path(output_dir)
        output_dir.mkdir(exist_ok=True)
        
        tasks = []
        for i, text in enumerate(texts):
            output_path = str(output_dir / f"audio_{i}.wav")
            task = self.text_to_speech(
                text, 
                output_path,
                ref_audio_path,
                ref_text,
                language
            )
            tasks.append(task)
        
        results = await asyncio.gather(*tasks)
        return results