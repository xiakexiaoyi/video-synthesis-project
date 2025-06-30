#!/bin/bash

# MuseTalk 模型快速下载修复脚本

echo "================================================"
echo "     MuseTalk 模型快速下载修复"
echo "================================================"
echo ""
echo "此脚本提供多种下载 MuseTalk 模型的方法"
echo ""

# 使用新的下载脚本
if [ -f "./download_musetalk_models_v2.sh" ]; then
    echo "运行修正版下载脚本..."
    ./download_musetalk_models_v2.sh
else
    echo "错误: 找不到 download_musetalk_models_v2.sh"
    exit 1
fi