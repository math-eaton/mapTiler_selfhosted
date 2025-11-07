# MapTiler Self-Hosted Server

Self-hosted MapTiler server for serving map tiles from local storage.

## Directory Structure

```
/srv/mapTiler_selfhosted/
├── docker-compose.yml    # Docker Compose configuration
├── .env                  # Environment variables (license key, etc.)
├── config/              # MapTiler configuration persistence
└── styles/              # Custom map styles (optional)

/mnt/pool/gis/           # tile storage directory
├── tiles/               # MBTiles files go here
└── data/                # Other GIS data
```

## Prerequisites

1. Docker and Docker Compose installed
2. MapTiler license key (get from https://cloud.maptiler.com/account/keys/)
3. `/mnt/pool/gis` directory exists and is accessible

## Setup

### 1. Create Required Directories

```bash
# Create GIS storage directory if it doesn't exist
sudo mkdir -p /mnt/pool/gis/{tiles,data,styles}

# Set permissions (adjust user:group as needed)
sudo chown -R $USER:$USER /mnt/pool/gis

# Create local config directories
mkdir -p ./config ./styles
```

### 2. Configure Environment

Edit `.env` and add MapTiler license key:

```bash
MAPTILER_LICENSE_KEY=your_license_key_here
```

### 3. Start the Server

```bash
# Start the server
docker-compose up -d

# View logs
docker-compose logs -f

# Check status
docker-compose ps
```

### 4. Access the Server

- Web UI: http://10.0.0.1:3650
- Health check: http://10.0.0.1:3650/health

**Note:** Port 3650 is used to avoid conflicts with other services (qBittorrent uses 8080)

## Tile Storage

### Directory Layout

Place MBTiles files in `/mnt/pool/gis/tiles/`:

```
/mnt/pool/gis/
└── tiles/
    ├── world.mbtiles
    ├── regional.mbtiles
    └── custom-data.mbtiles
```

### Adding Tiles

1. Generate MBTiles using tools like:
   - Tippecanoe
   - MapTiler Desktop
   - MBUtil
   - GDAL

2. Copy/move MBTiles to `/mnt/pool/gis/tiles/`

3. MapTiler Server will automatically detect and serve them

### Example Tile Generation (Tippecanoe)

```bash
# Example: Convert GeoJSON to MBTiles
tippecanoe -o /mnt/pool/gis/tiles/mydata.mbtiles \
  -z 14 \
  -Z 0 \
  --drop-densest-as-needed \
  --extend-zooms-if-still-dropping \
  input.geojson
```

## Storage Optimization

### mergerfs Pool Setup

`/mnt/pool` is configured with:
- **Disks**: IRON01 (8TB) + IRON02 (8TB)
- **Policy**: `category.create=epmfs` (existing path with most free space)
- **Move on no space**: Enabled with 150GB minimum free space
- **Benefits**: 
  - Automatic load balancing across disks
  - No space waste - uses most free space first
  - Graceful degradation if one disk fills

### Best Practices

1. **Organize tiles by zoom level or region**:
   ```
   /mnt/pool/gis/tiles/
   ├── low-zoom/world.mbtiles
   ├── mid-zoom/regions.mbtiles
   └── high-zoom/city-detailed.mbtiles
   ```

2. **Monitor disk usage**:
   ```bash
   df -h /mnt/pool
   ```

3. **Pre-allocate space for large tile operations**:
   ```bash
   # Check available space before generating large tilesets
   df -h /mnt/pool/gis
   ```

## Management

### Stop the Server

```bash
docker-compose down
```

### Restart the Server

```bash
docker-compose restart
```

### Update to Latest Version

```bash
docker-compose pull
docker-compose up -d
```

### View Logs

```bash
# Follow logs
docker-compose logs -f

# Last 100 lines
docker-compose logs --tail=100
```

### Cleanup

```bash
# Remove container and network (keeps volumes)
docker-compose down

# Remove everything including cache volume
docker-compose down -v
```

## Performance Tuning

### Cache Volume

The Docker Compose includes a named volume `maptiler-cache` for improved performance. This stores:
- Rendered tile cache
- Style processing cache
- Metadata cache

### Resource Limits (Optional)

Add to the service definition in `docker-compose.yml`:

```yaml
services:
  maptiler:
    # ... existing config ...
    deploy:
      resources:
        limits:
          cpus: '4'
          memory: 8G
        reservations:
          memory: 2G
```

## Troubleshooting

### Server won't start

1. Check logs: `docker-compose logs`
2. Verify license key in `.env`
3. Check port 3650 isn't in use: `sudo lsof -i :3650`

### Tiles not appearing

1. Verify MBTiles files are in `/mnt/pool/gis/tiles/`
2. Check file permissions: `ls -la /mnt/pool/gis/tiles/`
3. Restart server: `docker-compose restart`
4. Check logs for errors

### Permission issues

```bash
# Fix ownership
sudo chown -R $USER:$USER /mnt/pool/gis

# Fix permissions
chmod -R 755 /mnt/pool/gis
```

## Integration with Existing mapTiles Project

`/srv/mapTiles` project can consume tiles from this server:

1. Update tile URLs in JavaScript to point to `http://10.0.0.1:3650`
2. Or use nginx reverse proxy to serve both projects together

## Port Assignment

MapTiler uses port **3650** (bound to 10.0.0.1) to avoid conflicts with:
- qBittorrent (8080)
- Prowlarr (9696)
- Sonarr (8989)
- Radarr (7878)
- Lidarr (8686)
- Other media stack services

Access from local network: `http://10.0.0.1:3650`

## Security Considerations

### Production Deployment

1. **Use nginx reverse proxy**:
   - Add SSL/TLS
   - Add authentication
   - Rate limiting

2. **Firewall rules**:
   ```bash
   # Allow only from specific IP range
   sudo ufw allow from 192.168.1.0/24 to any port 3650
   ```

3. **Environment variables**:
   - Never commit `.env` to git
   - Use Docker secrets for sensitive data in production

## Next Steps

1. ✅ Start the MapTiler server
2. 📦 Generate or obtain MBTiles files
3. 📂 Place tiles in `/mnt/pool/gis/tiles/`
4. 🗺️ Access and configure via web UI
5. 🔗 Integrate with mapTiles frontend

## Resources

- [MapTiler Server Documentation](https://docs.maptiler.com/server/)
- [MBTiles Specification](https://github.com/mapbox/mbtiles-spec)
- [Tippecanoe Guide](https://github.com/felt/tippecanoe)
- [MapTiler Cloud](https://www.maptiler.com/)
