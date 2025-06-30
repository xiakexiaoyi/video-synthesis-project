import os
from pathlib import Path

BASE_DIR = Path(__file__).parent
TEMP_DIR = BASE_DIR.parent / "temp"
OUTPUT_DIR = BASE_DIR.parent / "output"

TEMP_DIR.mkdir(exist_ok=True)
OUTPUT_DIR.mkdir(exist_ok=True)

GPT_SOVITS_API_URL = os.getenv("GPT_SOVITS_API_URL", "http://localhost:9880")
MUSETALK_API_URL = os.getenv("MUSETALK_API_URL", "http://localhost:9881")

SERVER_HOST = "0.0.0.0"
SERVER_PORT = 6006