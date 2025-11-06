#!/bin/bash
# MapTiler Server Setup Script

set -e

echo "🗺️  MapTiler Self-Hosted Server Setup"
echo "======================================"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if running as root
if [ "$EUID" -eq 0 ]; then 
    echo -e "${RED}❌ Please do not run this script as root${NC}"
    exit 1
fi

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo -e "${RED}❌ Docker is not installed${NC}"
    echo "Please install Docker first: https://docs.docker.com/engine/install/ubuntu/"
    exit 1
fi

# Check if Docker Compose is installed
if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
    echo -e "${RED}❌ Docker Compose is not installed${NC}"
    echo "Please install Docker Compose first"
    exit 1
fi

echo -e "${GREEN}✓${NC} Docker is installed"
echo ""

# Create GIS storage directories
echo "📁 Creating storage directories..."
GIS_BASE="/mnt/pool/gis"

if [ ! -d "$GIS_BASE" ]; then
    echo -e "${YELLOW}⚠${NC}  $GIS_BASE does not exist"
    echo "Creating $GIS_BASE..."
    sudo mkdir -p "$GIS_BASE"
fi

# Create subdirectories
sudo mkdir -p "$GIS_BASE/tiles"
sudo mkdir -p "$GIS_BASE/data"
sudo mkdir -p "$GIS_BASE/styles"

# Set ownership to current user
echo "Setting ownership to $USER..."
sudo chown -R "$USER:$USER" "$GIS_BASE"

# Set proper permissions
chmod -R 755 "$GIS_BASE"

echo -e "${GREEN}✓${NC} Created directories:"
echo "  - $GIS_BASE/tiles   (for MBTiles files)"
echo "  - $GIS_BASE/data    (for other GIS data)"
echo "  - $GIS_BASE/styles  (for custom styles)"
echo ""

# Create local config directories
echo "📁 Creating local config directories..."
mkdir -p ./config
mkdir -p ./styles

echo -e "${GREEN}✓${NC} Created local directories"
echo ""

# Check for license key in .env
if [ ! -f ".env" ]; then
    echo -e "${YELLOW}⚠${NC}  .env file not found, creating from template..."
    cat > .env << EOF
# MapTiler Server Configuration
MAPTILER_LICENSE_KEY=

# Optional settings
# MAPTILER_PORT=8080
# MAPTILER_LOG_LEVEL=info
EOF
fi

if ! grep -q "MAPTILER_LICENSE_KEY=.\+" .env; then
    echo -e "${YELLOW}⚠${NC}  MapTiler license key not set in .env"
    echo ""
    echo "To get a license key:"
    echo "  1. Visit: https://cloud.maptiler.com/account/keys/"
    echo "  2. Create a free account or sign in"
    echo "  3. Copy your license key"
    echo "  4. Add it to .env file: MAPTILER_LICENSE_KEY=your_key_here"
    echo ""
    read -p "Do you want to enter your license key now? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        read -p "Enter your MapTiler license key: " LICENSE_KEY
        sed -i "s/MAPTILER_LICENSE_KEY=.*/MAPTILER_LICENSE_KEY=$LICENSE_KEY/" .env
        echo -e "${GREEN}✓${NC} License key saved to .env"
    else
        echo "You can add it later by editing .env"
    fi
else
    echo -e "${GREEN}✓${NC} License key is configured"
fi
echo ""

# Display disk space
echo "💾 Storage status:"
df -h "$GIS_BASE" | tail -n 1
echo ""

# Ask if user wants to start the server
read -p "Do you want to start the MapTiler server now? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo ""
    echo "🚀 Starting MapTiler server..."
    docker-compose up -d
    echo ""
    echo -e "${GREEN}✓${NC} Server started!"
    echo ""
    echo "📊 Server status:"
    docker-compose ps
    echo ""
    echo "🌐 Access the server at: http://10.0.0.1:8280"
    echo "📝 View logs with: docker-compose logs -f"
    echo ""
else
    echo ""
    echo "To start the server later, run:"
    echo "  docker-compose up -d"
    echo ""
fi

echo "======================================"
echo -e "${GREEN}✅ Setup complete!${NC}"
echo ""
echo "Next steps:"
echo "  1. Add your MBTiles files to: $GIS_BASE/tiles/"
echo "  2. Access the web UI: http://10.0.0.1:8280"
echo "  3. Read the README.md for more information"
echo ""
