# Monitor network consistency
while true; do
    curl -w "%{speed_download}\n" -o /dev/null -s https://speed.cloudflare.com/__down?bytes=10485760
    sleep 5
done | awk '{sum+=$1; count++; print $1/1024/1024 " Mbps"} END {print "Average:", sum/count/1024/1024 " Mbps"}'
