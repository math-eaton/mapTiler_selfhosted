#!/bin/bash
# MapTiler Server Status Check

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   MapTiler Server Status Check        ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
echo ""

# Check if Docker is running
echo -e "${BLUE}🐳 Docker Status:${NC}"
if systemctl is-active --quiet docker; then
    echo -e "${GREEN}✓${NC} Docker is running"
else
    echo -e "${RED}✗${NC} Docker is not running"
    echo "  Start with: sudo systemctl start docker"
fi
echo ""

# Check if container is running
echo -e "${BLUE}📦 Container Status:${NC}"
if docker ps | grep -q maptiler-server; then
    echo -e "${GREEN}✓${NC} MapTiler container is running"
    docker ps --filter name=maptiler-server --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
else
    echo -e "${RED}✗${NC} MapTiler container is not running"
    if docker ps -a | grep -q maptiler-server; then
        echo -e "${YELLOW}⚠${NC}  Container exists but is stopped"
        echo "  Start with: docker-compose up -d"
    else
        echo "  Create with: docker-compose up -d"
    fi
fi
echo ""

# Check license key
echo -e "${BLUE}🔑 License Key:${NC}"
if [ -f ".env" ]; then
    if grep -q "MAPTILER_LICENSE_KEY=.\+" .env; then
        echo -e "${GREEN}✓${NC} License key is configured"
    else
        echo -e "${YELLOW}⚠${NC}  License key is not set in .env"
        echo "  Get your key from: https://cloud.maptiler.com/account/keys/"
    fi
else
    echo -e "${RED}✗${NC} .env file not found"
fi
echo ""

# Check storage
echo -e "${BLUE}💾 Storage Status:${NC}"
if [ -d "/mnt/pool/gis" ]; then
    echo -e "${GREEN}✓${NC} Storage directory exists: /mnt/pool/gis"
    echo ""
    df -h /mnt/pool/gis | tail -n 1 | awk '{printf "  Total: %s\n  Used:  %s (%s)\n  Free:  %s\n", $2, $3, $5, $4}'
    echo ""
    
    # Check for tiles
    if [ -d "/mnt/pool/gis/tiles" ]; then
        TILE_COUNT=$(find /mnt/pool/gis/tiles -name "*.mbtiles" -o -name "*.pmtiles" 2>/dev/null | wc -l)
        if [ "$TILE_COUNT" -gt 0 ]; then
            echo -e "${GREEN}✓${NC} Found $TILE_COUNT tile file(s)"
            echo "  Tiles directory: /mnt/pool/gis/tiles/"
            find /mnt/pool/gis/tiles -maxdepth 1 -type f \( -name "*.mbtiles" -o -name "*.pmtiles" \) -exec basename {} \; 2>/dev/null | head -n 5 | sed 's/^/    • /'
            if [ "$TILE_COUNT" -gt 5 ]; then
                echo "    ... and $((TILE_COUNT - 5)) more"
            fi
        else
            echo -e "${YELLOW}⚠${NC}  No tile files found in /mnt/pool/gis/tiles/"
            echo "  Add MBTiles files to get started"
        fi
    else
        echo -e "${YELLOW}⚠${NC}  Tiles directory not found: /mnt/pool/gis/tiles"
    fi
else
    echo -e "${RED}✗${NC} Storage directory not found: /mnt/pool/gis"
    echo "  Run ./setup.sh to create directories"
fi
echo ""

# Check network connectivity
echo -e "${BLUE}🌐 Network Status:${NC}"
if docker ps | grep -q maptiler-server; then
    if curl -s http://10.0.0.1:8280/health > /dev/null 2>&1; then
        echo -e "${GREEN}✓${NC} Server is responding on http://10.0.0.1:8280"
        echo -e "  ${GREEN}→${NC} Web UI: http://10.0.0.1:8280"
    else
        echo -e "${YELLOW}⚠${NC}  Server is running but not responding on port 8280"
        echo "  Check logs: docker-compose logs"
    fi
else
    echo -e "${RED}✗${NC} Server is not running"
fi
echo ""

# Check logs for errors
if docker ps | grep -q maptiler-server; then
    echo -e "${BLUE}📋 Recent Logs:${NC}"
    docker logs --tail 5 maptiler-server 2>&1 | sed 's/^/  /'
    echo ""
    echo -e "  View full logs: ${YELLOW}docker-compose logs -f${NC}"
    echo ""
fi

# Summary
echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   Quick Commands                       ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
echo ""
echo "  Start:   docker-compose up -d"
echo "  Stop:    docker-compose down"
echo "  Restart: docker-compose restart"
echo "  Logs:    docker-compose logs -f"
echo "  Update:  docker-compose pull && docker-compose up -d"
echo ""
echo -e "  Setup:   ./setup.sh"
echo -e "  Status:  ./status.sh (this script)"
echo ""
