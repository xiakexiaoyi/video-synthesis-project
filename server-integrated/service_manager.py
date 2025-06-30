import os
import sys
import subprocess
import asyncio
import aiohttp
import psutil
from typing import Dict, Optional
from datetime import datetime
from pathlib import Path
from config import SERVICES, LOGS_DIR, HEALTH_CHECK_INTERVAL, SERVICE_START_TIMEOUT

class ServiceManager:
    """管理内部服务的启动、停止和健康检查"""
    
    def __init__(self):
        self.services_status = {}
        self.processes = {}
        self.health_check_task = None
        
    async def start_all_services(self):
        """启动所有配置的服务"""
        print("=" * 60)
        print("启动内部服务...")
        print("=" * 60)
        
        for service_id, service_config in SERVICES.items():
            if service_config['enabled']:
                await self.start_service(service_id)
        
        # 等待所有服务就绪
        await self.wait_all_services_ready()
        
        # 启动健康检查
        self.health_check_task = asyncio.create_task(self.health_check_loop())
        
    async def start_service(self, service_id: str) -> bool:
        """启动单个服务"""
        service = SERVICES.get(service_id)
        if not service:
            print(f"[错误] 未知服务: {service_id}")
            return False
        
        print(f"[{service['name']}] 正在启动...")
        
        # 检查端口是否被占用
        if self.is_port_in_use(service['port']):
            print(f"[{service['name']}] 端口 {service['port']} 已被占用，尝试连接现有服务...")
            if await self.check_service_health(service_id):
                print(f"[{service['name']}] 现有服务运行正常")
                self.services_status[service_id] = "running"
                return True
            else:
                print(f"[{service['name']}] 端口被占用但服务无响应")
                return False
        
        # 启动服务进程
        try:
            # Windows系统
            if sys.platform == "win32":
                # 将.sh脚本转换为.bat
                script_path = service['start_script'].replace('.sh', '.bat')
                if not Path(script_path).exists():
                    # 如果没有.bat文件，尝试使用Python脚本
                    script_dir = Path(service['start_script']).parent
                    python_script = script_dir / "start_api.py"
                    if python_script.exists():
                        cmd = [sys.executable, str(python_script)]
                    else:
                        print(f"[{service['name']}] 找不到启动脚本")
                        return False
                else:
                    cmd = [script_path]
                
                # 创建日志文件
                log_file = LOGS_DIR / f"{service_id}.log"
                with open(log_file, 'w') as f:
                    process = subprocess.Popen(
                        cmd,
                        stdout=f,
                        stderr=subprocess.STDOUT,
                        cwd=Path(script_path).parent if 'script_path' in locals() else None
                    )
            else:
                # Linux/Mac系统
                log_file = LOGS_DIR / f"{service_id}.log"
                with open(log_file, 'w') as f:
                    process = subprocess.Popen(
                        ['bash', service['start_script']],
                        stdout=f,
                        stderr=subprocess.STDOUT
                    )
            
            self.processes[service_id] = process
            self.services_status[service_id] = "starting"
            
            print(f"[{service['name']}] 进程已启动 (PID: {process.pid})")
            return True
            
        except Exception as e:
            print(f"[{service['name']}] 启动失败: {e}")
            self.services_status[service_id] = "failed"
            return False
    
    async def stop_all_services(self):
        """停止所有服务"""
        print("\n正在停止所有服务...")
        
        # 停止健康检查
        if self.health_check_task:
            self.health_check_task.cancel()
        
        # 停止所有进程
        for service_id, process in self.processes.items():
            service_name = SERVICES[service_id]['name']
            try:
                if process.poll() is None:  # 进程还在运行
                    print(f"[{service_name}] 正在停止...")
                    process.terminate()
                    try:
                        process.wait(timeout=5)
                    except subprocess.TimeoutExpired:
                        process.kill()
                    print(f"[{service_name}] 已停止")
            except Exception as e:
                print(f"[{service_name}] 停止失败: {e}")
        
        self.processes.clear()
        self.services_status.clear()
    
    async def check_service_health(self, service_id: str) -> bool:
        """检查服务健康状态"""
        service = SERVICES.get(service_id)
        if not service:
            return False
        
        url = f"http://{service['host']}:{service['port']}{service['health_endpoint']}"
        
        try:
            async with aiohttp.ClientSession() as session:
                async with session.get(url, timeout=aiohttp.ClientTimeout(total=5)) as resp:
                    return resp.status == 200
        except:
            return False
    
    async def wait_all_services_ready(self):
        """等待所有服务就绪"""
        print("\n等待服务就绪...")
        start_time = datetime.now()
        
        while (datetime.now() - start_time).seconds < SERVICE_START_TIMEOUT:
            all_ready = True
            
            for service_id, service in SERVICES.items():
                if not service['enabled']:
                    continue
                
                if await self.check_service_health(service_id):
                    if self.services_status.get(service_id) != "running":
                        print(f"[{service['name']}] ✓ 服务就绪")
                        self.services_status[service_id] = "running"
                else:
                    all_ready = False
            
            if all_ready:
                print("\n所有服务已就绪！")
                return True
            
            await asyncio.sleep(2)
        
        print("\n[警告] 部分服务启动超时")
        return False
    
    async def health_check_loop(self):
        """定期健康检查"""
        while True:
            try:
                await asyncio.sleep(HEALTH_CHECK_INTERVAL)
                
                for service_id, service in SERVICES.items():
                    if not service['enabled']:
                        continue
                    
                    is_healthy = await self.check_service_health(service_id)
                    current_status = self.services_status.get(service_id)
                    
                    if is_healthy and current_status != "running":
                        print(f"[{service['name']}] 服务恢复正常")
                        self.services_status[service_id] = "running"
                    elif not is_healthy and current_status == "running":
                        print(f"[{service['name']}] 服务异常")
                        self.services_status[service_id] = "unhealthy"
                        
                        # 尝试重启服务
                        print(f"[{service['name']}] 尝试重启...")
                        await self.restart_service(service_id)
                        
            except asyncio.CancelledError:
                break
            except Exception as e:
                print(f"[健康检查] 错误: {e}")
    
    async def restart_service(self, service_id: str):
        """重启服务"""
        # 先停止
        if service_id in self.processes:
            process = self.processes[service_id]
            if process.poll() is None:
                process.terminate()
                try:
                    process.wait(timeout=5)
                except subprocess.TimeoutExpired:
                    process.kill()
        
        # 再启动
        await self.start_service(service_id)
    
    def is_port_in_use(self, port: int) -> bool:
        """检查端口是否被占用"""
        for conn in psutil.net_connections():
            if conn.laddr.port == port and conn.status == 'LISTEN':
                return True
        return False
    
    def get_services_status(self) -> Dict[str, dict]:
        """获取所有服务状态"""
        status = {}
        for service_id, service in SERVICES.items():
            status[service_id] = {
                "name": service['name'],
                "port": service['port'],
                "status": self.services_status.get(service_id, "unknown"),
                "enabled": service['enabled']
            }
        return status

# 全局服务管理器实例
service_manager = ServiceManager()