#!/bin/bash
# Pre-flight check for MapTiler deployment

echo "Checking for port conflicts before starting MapTiler..."
echo ""

# Check if port 3650 is available
if sudo lsof -i :3650 >/dev/null 2>&1; then
    echo "Port 3650 is already in use:"
    sudo lsof -i :3650
    echo ""
    echo "MapTiler cannot start. Free up port 3650 or change the port in docker-compose.yml"
    exit 1
else
    echo "Port 3650 is available"
fi

echo ""
echo "Current port usage on 10.0.0.1:"
echo ""
sudo netstat -tulpn 2>/dev/null | grep "10.0.0.1" | awk '{print $4}' | sort -t: -k2 -n | while read addr; do
    port=$(echo $addr | cut -d: -f2)
    pid=$(sudo lsof -i :$port -t 2>/dev/null | head -1)
    if [ ! -z "$pid" ]; then
        process=$(ps -p $pid -o comm= 2>/dev/null || echo "unknown")
        echo "  Port $port: $process"
    fi
done

echo ""
echo "No conflicts detected - safe to start MapTiler on port 3650"
echo ""
echo "To start: docker-compose up -d"
