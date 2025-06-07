#!/bin/bash

# =============== CẤU HÌNH ===============
OUTPUT_FILE="speedtest_results.txt"
TEST_SIZES=("10485760 10MB" "104857600 100MB" "1073741824 1GB")
RUN_COUNT=10
DELAY=5
# ========================================

# Lấy thông tin kernel
KERNEL_VERSION=$(uname -r)

convert_to_mbps() {
  echo "scale=2; $1/1024/1024" | bc
}

run_test() {
  local size_bytes=$1
  local size_label=$2
  local speeds=()
  
  # Warm-up request
  curl -o /dev/null -s "https://speed.cloudflare.com/__down?bytes=$size_bytes"
  sleep 2

  for ((i=1; i<=$RUN_COUNT; i++)); do
    speed_bytes=$(curl -w "%{speed_download}" -o /dev/null -s "https://speed.cloudflare.com/__down?bytes=$size_bytes")
    speeds+=($(convert_to_mbps $speed_bytes))
    sleep $DELAY
  done

  # Tính toán
  sum=0
  max=${speeds[0]}
  min=${speeds[0]}
  for v in "${speeds[@]}"; do
    sum=$(echo "$sum + $v" | bc)
    (( $(echo "$v > $max" | bc -l) )) && max=$v
    (( $(echo "$v < $min" | bc -l) )) && min=$v
  done
  avg=$(echo "scale=2; $sum / ${#speeds[@]}" | bc)

  # Log ngắn gọn
  echo "===== $size_label =====" | tee -a $OUTPUT_FILE
  echo "All runs: ${speeds[*]} MB/s" | tee -a $OUTPUT_FILE
  echo "Min: $min MB/s" | tee -a $OUTPUT_FILE
  echo "Max: $max MB/s" | tee -a $OUTPUT_FILE
  echo "Avg: $avg MB/s" | tee -a $OUTPUT_FILE
  echo "" | tee -a $OUTPUT_FILE
}

# Main
echo "Speed Test started at $(date '+%Y-%m-%d %H:%M:%S') by $KERNEL_VERSION" | tee -a $OUTPUT_FILE
echo "----------------------------------" | tee -a $OUTPUT_FILE

for test_case in "${TEST_SIZES[@]}"; do
  size_bytes=$(echo $test_case | awk '{print $1}')
  size_label=$(echo $test_case | awk '{print $2}')
  run_test $size_bytes $size_label
done

echo "Test completed" | tee -a $OUTPUT_FILE
