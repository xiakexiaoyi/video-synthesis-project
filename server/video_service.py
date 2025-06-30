import os
import requests
import json
import shutil
import subprocess
from pathlib import Path
from typing import Optional
import aiofiles
import asyncio
from config import MUSETALK_API_URL, TEMP_DIR, OUTPUT_DIR

class VideoService:
    def __init__(self):
        self.api_url = MUSETALK_API_URL
        
    async def generate_talking_video(
        self,
        audio_path: str,
        video_path: str,
        output_path: str
    ) -> str:
        """
        使用MuseTalk生成说话视频
        """
        try:
            with open(audio_path, 'rb') as audio_file:
                with open(video_path, 'rb') as video_file:
                    files = {
                        'audio': ('audio.wav', audio_file, 'audio/wav'),
                        'video': ('video.mp4', video_file, 'video/mp4')
                    }
                    
                    response = requests.post(
                        f"{self.api_url}/inference",
                        files=files,
                        timeout=300
                    )
            
            if response.status_code == 200:
                async with aiofiles.open(output_path, 'wb') as f:
                    await f.write(response.content)
                return output_path
            else:
                raise Exception(f"MuseTalk API error: {response.status_code}")
                
        except Exception as e:
            raise Exception(f"Video generation failed: {str(e)}")
    
    async def merge_videos(
        self,
        video_paths: list[str],
        output_path: str
    ) -> str:
        """
        合并多个视频文件
        """
        try:
            list_file = TEMP_DIR / "concat_list.txt"
            
            with open(list_file, 'w') as f:
                for video_path in video_paths:
                    f.write(f"file '{os.path.abspath(video_path)}'\n")
            
            cmd = [
                'ffmpeg',
                '-f', 'concat',
                '-safe', '0',
                '-i', str(list_file),
                '-c', 'copy',
                '-y',
                output_path
            ]
            
            process = await asyncio.create_subprocess_exec(
                *cmd,
                stdout=asyncio.subprocess.PIPE,
                stderr=asyncio.subprocess.PIPE
            )
            
            stdout, stderr = await process.communicate()
            
            if process.returncode != 0:
                raise Exception(f"FFmpeg error: {stderr.decode()}")
            
            os.remove(list_file)
            return output_path
            
        except Exception as e:
            raise Exception(f"Video merge failed: {str(e)}")
    
    async def batch_generate_videos(
        self,
        audio_paths: list[str],
        video_path: str,
        output_dir: str
    ) -> list[str]:
        """
        批量生成说话视频
        """
        output_dir = Path(output_dir)
        output_dir.mkdir(exist_ok=True)
        
        tasks = []
        for i, audio_path in enumerate(audio_paths):
            output_path = str(output_dir / f"video_{i}.mp4")
            task = self.generate_talking_video(
                audio_path,
                video_path,
                output_path
            )
            tasks.append(task)
        
        results = await asyncio.gather(*tasks)
        return results