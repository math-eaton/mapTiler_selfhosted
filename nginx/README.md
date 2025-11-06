# Nginx Setup for MapTiler Server

## Quick Setup

### 1. Install Nginx

```bash
sudo apt update
sudo apt install nginx
```

### 2. Copy Configuration

```bash
# Copy the config file
sudo cp nginx/maptiler.conf /etc/nginx/sites-available/maptiler

# Edit and update your domain name
sudo nano /etc/nginx/sites-available/maptiler

# Enable the site
sudo ln -s /etc/nginx/sites-available/maptiler /etc/nginx/sites-enabled/

# Test configuration
sudo nginx -t

# Reload nginx
sudo systemctl reload nginx
```

### 3. Setup SSL with Let's Encrypt (Optional)

```bash
# Install certbot
sudo apt install certbot python3-certbot-nginx

# Obtain SSL certificate
sudo certbot --nginx -d tiles.yourdomain.com

# Certbot will automatically update the nginx config
# Or manually uncomment the HTTPS section in maptiler.conf
```

### 4. Firewall Configuration

```bash
# Allow HTTP and HTTPS
sudo ufw allow 'Nginx Full'

# Or specific ports
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
```

## Local Network Access Only

If you only want local network access, use this simpler config:

```nginx
server {
    listen 80;
    server_name _;
    
    # Only allow local network
    allow 192.168.1.0/24;  # Adjust to your network
    deny all;
    
    location / {
        proxy_pass http://localhost:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

## Benefits of Using Nginx

1. **SSL/TLS encryption** - Secure tile serving
2. **Caching** - Reduce load on MapTiler server
3. **Access control** - IP whitelist/blacklist
4. **Rate limiting** - Prevent abuse
5. **Load balancing** - Multiple MapTiler instances
6. **Custom domain** - tiles.yourdomain.com

## Monitoring

```bash
# Check nginx status
sudo systemctl status nginx

# View access logs
sudo tail -f /var/log/nginx/access.log

# View error logs
sudo tail -f /var/log/nginx/error.log
```

## Troubleshooting

**502 Bad Gateway?**
- Check if MapTiler is running: `docker-compose ps`
- Check nginx error logs

**Permission denied?**
- Check SELinux: `sudo setsebool -P httpd_can_network_connect 1`

**Certificate errors?**
- Renew certificates: `sudo certbot renew`
- Test renewal: `sudo certbot renew --dry-run`
