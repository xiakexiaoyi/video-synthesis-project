#!/usr/bin/env python3
"""
视频合成服务测试客户端
用于测试服务端的所有功能，包括上传和生成
"""

import os
import sys
import time
import requests
import argparse
from pathlib import Path

class TestClient:
    def __init__(self, server_url="http://localhost:6006"):
        self.server_url = server_url
        self.session = requests.Session()
        
    def check_health(self):
        """检查服务器健康状态"""
        print(f"[*] 检查服务器健康状态: {self.server_url}/health")
        try:
            response = self.session.get(f"{self.server_url}/health", timeout=5)
            if response.status_code == 200:
                print(f"[✓] 服务器运行正常: {response.json()}")
                return True
            else:
                print(f"[✗] 服务器响应异常: {response.status_code}")
                return False
        except Exception as e:
            print(f"[✗] 无法连接到服务器: {e}")
            return False
    
    def test_synthesis(self, video_path, texts, ref_audio_path=None, ref_text=None, language="zh"):
        """测试视频合成功能"""
        print("\n[*] 开始测试视频合成功能")
        print(f"    视频文件: {video_path}")
        print(f"    文本内容: {texts}")
        if ref_audio_path:
            print(f"    参考音频: {ref_audio_path}")
        if ref_text:
            print(f"    参考文本: {ref_text}")
        print(f"    语言: {language}")
        
        # 准备文件
        files = {}
        try:
            files['video'] = open(video_path, 'rb')
            if ref_audio_path and os.path.exists(ref_audio_path):
                files['ref_audio'] = open(ref_audio_path, 'rb')
        except Exception as e:
            print(f"[✗] 打开文件失败: {e}")
            return None
        
        # 准备数据
        data = {
            'texts': '\n'.join(texts),
            'language': language
        }
        if ref_text:
            data['ref_text'] = ref_text
        
        # 发送请求
        print("\n[*] 上传文件并创建任务...")
        try:
            response = self.session.post(
                f"{self.server_url}/synthesize",
                files=files,
                data=data,
                timeout=30
            )
            
            if response.status_code == 200:
                task_info = response.json()
                print(f"[✓] 任务创建成功: {task_info}")
                return task_info['task_id']
            else:
                print(f"[✗] 创建任务失败: {response.status_code}")
                print(f"    响应内容: {response.text}")
                return None
                
        except Exception as e:
            print(f"[✗] 请求失败: {e}")
            return None
        finally:
            # 关闭文件
            for f in files.values():
                f.close()
    
    def check_task_status(self, task_id):
        """检查任务状态"""
        print(f"\n[*] 检查任务状态: {task_id}")
        
        max_retries = 60  # 最多等待60次，每次2秒
        retry_count = 0
        
        while retry_count < max_retries:
            try:
                response = self.session.get(f"{self.server_url}/task/{task_id}")
                
                if response.status_code == 200:
                    status = response.json()
                    print(f"[*] 状态: {status['status']} - {status['message']} ({status['progress']}%)")
                    
                    if status['status'] == 'completed':
                        print(f"[✓] 任务完成!")
                        print(f"    结果文件: {status['result_urls']}")
                        return status
                    elif status['status'] == 'failed':
                        print(f"[✗] 任务失败: {status['message']}")
                        return status
                else:
                    print(f"[✗] 获取状态失败: {response.status_code}")
                    return None
                    
            except Exception as e:
                print(f"[✗] 请求失败: {e}")
                return None
            
            retry_count += 1
            time.sleep(2)
        
        print("[✗] 任务超时")
        return None
    
    def download_results(self, result_urls, output_dir="./test_output"):
        """下载结果文件"""
        print(f"\n[*] 下载结果文件到: {output_dir}")
        
        os.makedirs(output_dir, exist_ok=True)
        downloaded_files = []
        
        for url in result_urls:
            filename = os.path.basename(url)
            save_path = os.path.join(output_dir, filename)
            
            try:
                print(f"[*] 下载: {filename}")
                response = self.session.get(f"{self.server_url}{url}", stream=True)
                
                if response.status_code == 200:
                    with open(save_path, 'wb') as f:
                        for chunk in response.iter_content(chunk_size=8192):
                            if chunk:
                                f.write(chunk)
                    print(f"[✓] 已保存: {save_path}")
                    downloaded_files.append(save_path)
                else:
                    print(f"[✗] 下载失败: {response.status_code}")
                    
            except Exception as e:
                print(f"[✗] 下载失败: {e}")
        
        return downloaded_files
    
    def run_full_test(self, video_path, texts, ref_audio_path=None, ref_text=None):
        """运行完整测试流程"""
        print("="*50)
        print("视频合成服务完整测试")
        print("="*50)
        
        # 1. 检查健康状态
        if not self.check_health():
            print("\n[✗] 服务器不可用，测试中止")
            return False
        
        # 2. 创建合成任务
        task_id = self.test_synthesis(video_path, texts, ref_audio_path, ref_text)
        if not task_id:
            print("\n[✗] 创建任务失败，测试中止")
            return False
        
        # 3. 等待任务完成
        status = self.check_task_status(task_id)
        if not status or status['status'] != 'completed':
            print("\n[✗] 任务执行失败，测试中止")
            return False
        
        # 4. 下载结果
        downloaded_files = self.download_results(status['result_urls'])
        
        print("\n" + "="*50)
        print(f"[✓] 测试完成! 共生成 {len(downloaded_files)} 个文件")
        for f in downloaded_files:
            print(f"    - {f}")
        print("="*50)
        
        return True

def create_test_files():
    """创建测试文件"""
    test_dir = Path("./test_data")
    test_dir.mkdir(exist_ok=True)
    
    # 创建测试视频文件（模拟）
    video_path = test_dir / "test_video.mp4"
    if not video_path.exists():
        print(f"[!] 请将测试视频文件放置在: {video_path}")
        return None, None
    
    # 创建测试音频文件（模拟）
    audio_path = test_dir / "test_audio.wav"
    if not audio_path.exists():
        audio_path = None
    
    return str(video_path), str(audio_path) if audio_path else None

def main():
    parser = argparse.ArgumentParser(description="视频合成服务测试客户端")
    parser.add_argument("--server", default="http://localhost:6006", help="服务器地址")
    parser.add_argument("--video", help="视频文件路径")
    parser.add_argument("--audio", help="参考音频文件路径（可选）")
    parser.add_argument("--texts", nargs="+", help="要合成的文本（多段）")
    parser.add_argument("--ref-text", help="参考文本（可选）")
    parser.add_argument("--quick", action="store_true", help="快速测试模式（使用默认测试数据）")
    
    args = parser.parse_args()
    
    # 创建测试客户端
    client = TestClient(args.server)
    
    if args.quick:
        # 快速测试模式
        print("[*] 快速测试模式")
        video_path, audio_path = create_test_files()
        
        if not video_path:
            print("[✗] 缺少测试文件，请准备 test_data/test_video.mp4")
            sys.exit(1)
        
        texts = ["这是第一段测试文本", "这是第二段测试文本", "测试完成"]
        ref_text = "这是参考文本的内容"
        
        client.run_full_test(video_path, texts, audio_path, ref_text)
        
    elif args.video and args.texts:
        # 自定义测试
        if not os.path.exists(args.video):
            print(f"[✗] 视频文件不存在: {args.video}")
            sys.exit(1)
        
        if args.audio and not os.path.exists(args.audio):
            print(f"[✗] 音频文件不存在: {args.audio}")
            sys.exit(1)
        
        client.run_full_test(args.video, args.texts, args.audio, args.ref_text)
        
    else:
        # 交互式测试
        print("交互式测试模式")
        print("-" * 30)
        
        # 健康检查
        if not client.check_health():
            sys.exit(1)
        
        # 输入测试参数
        video_path = input("\n请输入视频文件路径: ").strip()
        if not os.path.exists(video_path):
            print(f"[✗] 文件不存在: {video_path}")
            sys.exit(1)
        
        texts = []
        print("\n请输入要合成的文本（每行一段，输入空行结束）:")
        while True:
            text = input().strip()
            if not text:
                break
            texts.append(text)
        
        if not texts:
            print("[✗] 至少需要输入一段文本")
            sys.exit(1)
        
        audio_path = input("\n参考音频文件路径（可选，直接回车跳过）: ").strip()
        if audio_path and not os.path.exists(audio_path):
            print(f"[!] 音频文件不存在，将忽略: {audio_path}")
            audio_path = None
        
        ref_text = input("\n参考文本（可选，直接回车跳过）: ").strip()
        
        # 运行测试
        client.run_full_test(video_path, texts, audio_path or None, ref_text or None)

if __name__ == "__main__":
    main()