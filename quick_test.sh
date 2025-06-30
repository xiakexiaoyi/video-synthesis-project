#!/bin/bash
# 快速测试脚本 - Linux/Mac

echo "==================================="
echo "    视频合成服务快速测试"
echo "==================================="

# 设置服务器地址
SERVER_URL="${SERVER_URL:-http://localhost:6006}"

# 测试健康检查
echo -e "\n[1] 测试服务器连接..."
curl -s -o /dev/null -w "服务器响应: %{http_code}\n" $SERVER_URL/health

# 准备测试数据
mkdir -p test_data

# 检查测试视频
if [ ! -f "test_data/test_video.mp4" ]; then
    echo -e "\n[!] 请将测试视频放置在: test_data/test_video.mp4"
    exit 1
fi

# 运行快速测试
echo -e "\n[2] 运行视频合成测试..."
python3 test_client.py --quick --server $SERVER_URL

echo -e "\n测试完成!"