import sys
import os
import json
from pathlib import Path
from PyQt5.QtWidgets import *
from PyQt5.QtCore import *
from PyQt5.QtGui import *
import requests
from datetime import datetime
import tempfile
import shutil

# 获取资源路径（支持打包后的exe）
def resource_path(relative_path):
    try:
        base_path = sys._MEIPASS
    except Exception:
        base_path = os.path.abspath(".")
    return os.path.join(base_path, relative_path)

class WorkerThread(QThread):
    progress_update = pyqtSignal(str)
    task_complete = pyqtSignal(dict)
    error_occurred = pyqtSignal(str)
    
    def __init__(self, server_url, texts, video_path, ref_audio_path=None, ref_text=None, language="zh"):
        super().__init__()
        self.server_url = server_url
        self.texts = texts
        self.video_path = video_path
        self.ref_audio_path = ref_audio_path
        self.ref_text = ref_text
        self.language = language
        self.task_id = None
        
    def run(self):
        try:
            self.progress_update.emit("正在上传文件...")
            
            files = {'video': open(self.video_path, 'rb')}
            if self.ref_audio_path:
                files['ref_audio'] = open(self.ref_audio_path, 'rb')
            
            data = {
                'texts': '\n'.join(self.texts),
                'language': self.language
            }
            if self.ref_text:
                data['ref_text'] = self.ref_text
            
            response = requests.post(
                f"{self.server_url}/synthesize",
                files=files,
                data=data
            )
            
            if response.status_code == 200:
                self.task_id = response.json()['task_id']
                self.progress_update.emit(f"任务已创建: {self.task_id}")
                
                while True:
                    status_response = requests.get(
                        f"{self.server_url}/task/{self.task_id}"
                    )
                    
                    if status_response.status_code == 200:
                        status = status_response.json()
                        self.progress_update.emit(
                            f"状态: {status['status']} - {status['message']} ({status['progress']}%)"
                        )
                        
                        if status['status'] == 'completed':
                            self.task_complete.emit(status)
                            break
                        elif status['status'] == 'failed':
                            self.error_occurred.emit(status['message'])
                            break
                    
                    self.msleep(2000)
            else:
                self.error_occurred.emit(f"上传失败: {response.status_code}")
                
        except Exception as e:
            self.error_occurred.emit(str(e))
        finally:
            for file in files.values():
                file.close()

class VideoSynthesisClient(QMainWindow):
    def __init__(self):
        super().__init__()
        self.server_url = "http://localhost:6006"
        self.init_ui()
        self.setWindowIcon(QIcon(resource_path("icon.ico")))
        
    def init_ui(self):
        self.setWindowTitle("视频合成客户端 v1.0")
        self.setGeometry(100, 100, 900, 700)
        
        # 设置样式
        self.setStyleSheet("""
            QMainWindow {
                background-color: #f5f5f5;
            }
            QGroupBox {
                font-weight: bold;
                border: 2px solid #cccccc;
                border-radius: 5px;
                margin-top: 10px;
                padding-top: 10px;
            }
            QGroupBox::title {
                subcontrol-origin: margin;
                left: 10px;
                padding: 0 5px 0 5px;
            }
            QPushButton {
                background-color: #4CAF50;
                color: white;
                border: none;
                padding: 8px 16px;
                border-radius: 4px;
                font-weight: bold;
            }
            QPushButton:hover {
                background-color: #45a049;
            }
            QPushButton:disabled {
                background-color: #cccccc;
            }
            QTextEdit {
                border: 1px solid #cccccc;
                border-radius: 4px;
                padding: 5px;
            }
        """)
        
        central_widget = QWidget()
        self.setCentralWidget(central_widget)
        layout = QVBoxLayout(central_widget)
        
        server_group = QGroupBox("服务器设置")
        server_layout = QHBoxLayout()
        server_layout.addWidget(QLabel("服务器地址:"))
        self.server_input = QLineEdit(self.server_url)
        server_layout.addWidget(self.server_input)
        server_group.setLayout(server_layout)
        layout.addWidget(server_group)
        
        text_group = QGroupBox("文本输入")
        text_layout = QVBoxLayout()
        text_layout.addWidget(QLabel("请输入多段文本（每行一段）:"))
        self.text_edit = QTextEdit()
        self.text_edit.setPlaceholderText("第一段文本\n第二段文本\n第三段文本...")
        text_layout.addWidget(self.text_edit)
        text_group.setLayout(text_layout)
        layout.addWidget(text_group)
        
        file_group = QGroupBox("文件选择")
        file_layout = QGridLayout()
        
        file_layout.addWidget(QLabel("参考视频:"), 0, 0)
        self.video_path_label = QLabel("未选择")
        file_layout.addWidget(self.video_path_label, 0, 1)
        self.select_video_btn = QPushButton("选择视频")
        self.select_video_btn.clicked.connect(self.select_video)
        file_layout.addWidget(self.select_video_btn, 0, 2)
        
        file_layout.addWidget(QLabel("参考音频(可选):"), 1, 0)
        self.audio_path_label = QLabel("未选择")
        file_layout.addWidget(self.audio_path_label, 1, 1)
        self.select_audio_btn = QPushButton("选择音频")
        self.select_audio_btn.clicked.connect(self.select_audio)
        file_layout.addWidget(self.select_audio_btn, 1, 2)
        
        file_layout.addWidget(QLabel("参考文本(可选):"), 2, 0)
        self.ref_text_input = QLineEdit()
        file_layout.addWidget(self.ref_text_input, 2, 1, 1, 2)
        
        file_group.setLayout(file_layout)
        layout.addWidget(file_group)
        
        control_layout = QHBoxLayout()
        self.process_btn = QPushButton("开始合成")
        self.process_btn.clicked.connect(self.start_synthesis)
        control_layout.addWidget(self.process_btn)
        
        self.download_btn = QPushButton("下载结果")
        self.download_btn.setEnabled(False)
        self.download_btn.clicked.connect(self.download_results)
        control_layout.addWidget(self.download_btn)
        
        layout.addLayout(control_layout)
        
        self.progress_text = QTextEdit()
        self.progress_text.setReadOnly(True)
        self.progress_text.setMaximumHeight(150)
        layout.addWidget(self.progress_text)
        
        self.video_path = None
        self.audio_path = None
        self.result_urls = None
        
    def select_video(self):
        file_path, _ = QFileDialog.getOpenFileName(
            self, "选择参考视频", "", "视频文件 (*.mp4 *.avi *.mov)"
        )
        if file_path:
            self.video_path = file_path
            self.video_path_label.setText(os.path.basename(file_path))
    
    def select_audio(self):
        file_path, _ = QFileDialog.getOpenFileName(
            self, "选择参考音频", "", "音频文件 (*.wav *.mp3)"
        )
        if file_path:
            self.audio_path = file_path
            self.audio_path_label.setText(os.path.basename(file_path))
    
    def start_synthesis(self):
        texts = self.text_edit.toPlainText().strip().split('\n')
        texts = [t.strip() for t in texts if t.strip()]
        
        if not texts:
            QMessageBox.warning(self, "警告", "请输入至少一段文本")
            return
        
        if not self.video_path:
            QMessageBox.warning(self, "警告", "请选择参考视频")
            return
        
        self.server_url = self.server_input.text()
        self.process_btn.setEnabled(False)
        self.download_btn.setEnabled(False)
        self.progress_text.clear()
        
        self.worker = WorkerThread(
            self.server_url,
            texts,
            self.video_path,
            self.audio_path,
            self.ref_text_input.text(),
            "zh"
        )
        
        self.worker.progress_update.connect(self.update_progress)
        self.worker.task_complete.connect(self.on_task_complete)
        self.worker.error_occurred.connect(self.on_error)
        
        self.worker.start()
    
    def update_progress(self, message):
        timestamp = datetime.now().strftime("%H:%M:%S")
        self.progress_text.append(f"[{timestamp}] {message}")
    
    def on_task_complete(self, result):
        self.result_urls = result['result_urls']
        self.download_btn.setEnabled(True)
        self.process_btn.setEnabled(True)
        self.update_progress("合成完成！可以下载结果了。")
        QMessageBox.information(self, "完成", "视频合成完成！")
    
    def on_error(self, error_message):
        self.process_btn.setEnabled(True)
        self.update_progress(f"错误: {error_message}")
        QMessageBox.critical(self, "错误", error_message)
    
    def download_results(self):
        if not self.result_urls:
            return
        
        save_dir = QFileDialog.getExistingDirectory(self, "选择保存目录")
        if not save_dir:
            return
        
        self.update_progress("开始下载文件...")
        
        for url in self.result_urls:
            filename = os.path.basename(url)
            response = requests.get(f"{self.server_url}{url}", stream=True)
            
            if response.status_code == 200:
                save_path = os.path.join(save_dir, filename)
                with open(save_path, 'wb') as f:
                    for chunk in response.iter_content(chunk_size=8192):
                        f.write(chunk)
                self.update_progress(f"已下载: {filename}")
            else:
                self.update_progress(f"下载失败: {filename}")
        
        self.update_progress("所有文件下载完成！")
        QMessageBox.information(self, "完成", f"文件已保存到: {save_dir}")

def main():
    app = QApplication(sys.argv)
    app.setApplicationName("视频合成客户端")
    app.setOrganizationName("VideoSynthesis")
    
    # 设置应用图标
    app.setWindowIcon(QIcon(resource_path("icon.ico")))
    
    window = VideoSynthesisClient()
    window.show()
    sys.exit(app.exec_())

if __name__ == "__main__":
    main()