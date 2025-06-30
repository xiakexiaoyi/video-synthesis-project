import os
from pathlib import Path

# 基础配置
BASE_DIR = Path(__file__).parent
PROJECT_ROOT = BASE_DIR.parent
TEMP_DIR = PROJECT_ROOT / "temp"
OUTPUT_DIR = PROJECT_ROOT / "output"
LOGS_DIR = PROJECT_ROOT / "logs"

# 创建必要的目录
for dir_path in [TEMP_DIR, OUTPUT_DIR, LOGS_DIR]:
    dir_path.mkdir(exist_ok=True)

# 主服务配置（对外统一端口）
SERVER_HOST = "0.0.0.0"
SERVER_PORT = 8000

# 内部服务配置
SERVICES = {
    "gpt_sovits": {
        "name": "GPT-SoVITS",
        "host": "127.0.0.1",
        "port": 9880,
        "health_endpoint": "/health",
        "start_script": str(PROJECT_ROOT / "services" / "gpt-sovits" / "start_service.sh"),
        "enabled": True
    },
    "musetalk": {
        "name": "MuseTalk",
        "host": "127.0.0.1", 
        "port": 9881,
        "health_endpoint": "/health",
        "start_script": str(PROJECT_ROOT / "services" / "musetalk" / "start_service.sh"),
        "enabled": True
    }
}

# 获取内部服务URL
def get_service_url(service_name: str) -> str:
    """获取内部服务的完整URL"""
    service = SERVICES.get(service_name)
    if service:
        return f"http://{service['host']}:{service['port']}"
    return None

GPT_SOVITS_URL = get_service_url("gpt_sovits")
MUSETALK_URL = get_service_url("musetalk")

# 超时配置
REQUEST_TIMEOUT = 300  # 5分钟
HEALTH_CHECK_INTERVAL = 30  # 30秒
SERVICE_START_TIMEOUT = 60  # 1分钟

# 任务配置
MAX_CONCURRENT_TASKS = 5
TASK_CLEANUP_INTERVAL = 3600  # 1小时清理一次过期任务
TASK_EXPIRE_TIME = 86400  # 任务结果保留24小时