# FKS Trading Platform - Access Guide

**Domain**: https://fkstrading.xyz  
**Local Testing**: https://localhost  
**Created**: 2025-11-01  
**Status**: ✅ Ready for Use

---

## 🔑 Login Credentials

### Admin Account
```
Username: admin
Password: fks2025admin!
```

**Roles**: 
- Admin panel access
- NT8 account management
- Signal testing
- Full system access

### Security Notes
⚠️ **Change password after first login in production**
- Navigate to: https://fkstrading.xyz/admin/
- Click "Change password" link
- Use strong password (12+ characters, mixed case, numbers, symbols)

---

## 🌐 Access URLs

### Production Domain (fkstrading.xyz)

| Service | URL | Purpose |
|---------|-----|---------|
| **Dashboard** | https://fkstrading.xyz/ninja/dashboard/ | NT8 account management |
| **Admin Panel** | https://fkstrading.xyz/admin/ | Django admin interface |
| **Package Download** | https://fkstrading.xyz/ninja/download/ | NT8 strategy package |
| **Installation Guide** | https://fkstrading.xyz/ninja/installation/ | NT8 setup instructions |
| **Backtest Results** | https://fkstrading.xyz/backtest/ | Strategy performance |
| **Login** | https://fkstrading.xyz/login/ | Authentication page |
| **Logout** | https://fkstrading.xyz/logout/ | Sign out |

### Local Testing (localhost)

| Service | URL | Purpose |
|---------|-----|---------|
| **Dashboard** | https://localhost/ninja/dashboard/ | NT8 account management |
| **Admin Panel** | https://localhost/admin/ | Django admin interface |
| **Package Download** | https://localhost/ninja/download/ | NT8 strategy package |
| **Installation Guide** | https://localhost/ninja/installation/ | NT8 setup instructions |
| **Backtest Results** | https://localhost/backtest/ | Strategy performance |

**Note**: Local testing uses self-signed SSL certificate - browser will show security warning (safe to proceed)

---

## 🚀 Quick Start

### First Login (Local Testing)

1. **Open browser**: Navigate to https://localhost/login/
2. **Accept SSL warning**: Click "Advanced" → "Proceed to localhost (unsafe)"
3. **Enter credentials**:
   - Username: `admin`
   - Password: `fks2025admin!`
4. **Click "Login"**
5. **Verify access**: Should redirect to dashboard

### First Login (Production Domain)

1. **DNS Setup Required**: Point `fkstrading.xyz` A record to server IP
   ```bash
   # Check current DNS
   nslookup fkstrading.xyz
   
   # Should return your server's public IP
   ```

2. **Access**: https://fkstrading.xyz/login/

3. **SSL Certificate**: 
   - Currently using self-signed certificate
   - For production, obtain Let's Encrypt certificate:
     ```bash
     docker-compose run --rm certbot certonly \
       --webroot \
       --webroot-path=/var/www/certbot \
       -d fkstrading.xyz \
       -d www.fkstrading.xyz
     ```

4. **Login**: Use admin credentials above

---

## 🛠️ Domain Configuration

### Current Setup (Already Configured ✅)

**Django Settings** (`src/services/web/src/django/settings.py`):
```python
ALLOWED_HOSTS = [
    'localhost',
    '127.0.0.1',
    'fkstrading.xyz',
    'www.fkstrading.xyz',
    'testserver',
]

CSRF_TRUSTED_ORIGINS = [
    'https://localhost',
    'https://fkstrading.xyz',
    'https://www.fkstrading.xyz',
]
```

**Nginx Configuration** (`nginx/conf.d/default.conf`):
```nginx
server_name fkstrading.xyz www.fkstrading.xyz localhost;
```

### DNS Configuration (Required for Production)

**A Records** (Point to your server IP):
```
fkstrading.xyz         A    YOUR_SERVER_IP
www.fkstrading.xyz     A    YOUR_SERVER_IP
```

**Example** (using Cloudflare/Namecheap/GoDaddy):
```
Type    Name    Value           TTL
A       @       192.0.2.1       Auto
A       www     192.0.2.1       Auto
```

**Verification**:
```bash
# Check DNS propagation
dig fkstrading.xyz +short
# Should return: YOUR_SERVER_IP

# Test HTTP access
curl -I http://fkstrading.xyz
# Should return: 301 redirect to HTTPS

# Test HTTPS access
curl -k -I https://fkstrading.xyz
# Should return: 200 OK
```

---

## 🔒 SSL/TLS Configuration

### Current State: Self-Signed Certificate

**Location**: `nginx/ssl/`
- `nginx-selfsigned.crt` - Certificate
- `nginx-selfsigned.key` - Private key

**Browser Behavior**:
- ⚠️ Shows security warning ("Your connection is not private")
- Safe for local testing
- **NOT suitable for production**

### Production: Let's Encrypt (Free SSL)

**Setup Steps**:

1. **Install Certbot**:
   ```bash
   # Already in docker-compose.yml
   docker-compose run --rm certbot --version
   ```

2. **Obtain Certificate**:
   ```bash
   # One-time certificate request
   docker-compose run --rm certbot certonly \
     --webroot \
     --webroot-path=/var/www/certbot \
     -d fkstrading.xyz \
     -d www.fkstrading.xyz \
     --email your-email@example.com \
     --agree-tos \
     --no-eff-email
   ```

3. **Update Nginx Config**:
   ```nginx
   # Replace self-signed paths with:
   ssl_certificate /etc/letsencrypt/live/fkstrading.xyz/fullchain.pem;
   ssl_certificate_key /etc/letsencrypt/live/fkstrading.xyz/privkey.pem;
   ```

4. **Reload Nginx**:
   ```bash
   docker-compose restart fks_nginx
   ```

5. **Auto-Renewal** (already configured):
   ```bash
   # Certbot runs daily at 12:00 PM
   # Check cron job:
   docker-compose logs certbot
   ```

---

## 📱 Testing Checklist

### After Domain Setup

- [ ] DNS resolves to server IP (`dig fkstrading.xyz`)
- [ ] HTTP redirects to HTTPS (`curl -I http://fkstrading.xyz`)
- [ ] HTTPS loads without errors (`curl -k https://fkstrading.xyz`)
- [ ] Login page accessible (`https://fkstrading.xyz/login/`)
- [ ] Admin credentials work
- [ ] Dashboard loads (`https://fkstrading.xyz/ninja/dashboard/`)
- [ ] Package download works (`https://fkstrading.xyz/ninja/download/`)

### Browser Testing (Already Started)

- [ ] Initial access (login page)
- [ ] Dashboard functionality
- [ ] Admin interface
- [ ] Installation guide
- [ ] Navigation (all menu items)
- [ ] Error handling (404, 500)

**Reference**: See `docs/BROWSER_TESTING_GUIDE.md` for comprehensive checklist

---

## 🚨 Troubleshooting

### Issue: "This site can't be reached"

**Cause**: DNS not configured or propagated

**Fix**:
```bash
# Check DNS
nslookup fkstrading.xyz

# If returns "NXDOMAIN":
# 1. Add A record in DNS provider
# 2. Wait 5-60 minutes for propagation
# 3. Try again
```

### Issue: "Your connection is not private"

**Cause**: Using self-signed certificate

**Fix (Local Testing)**:
1. Click "Advanced"
2. Click "Proceed to localhost (unsafe)"
3. Continue testing

**Fix (Production)**:
1. Obtain Let's Encrypt certificate (steps above)
2. Update Nginx configuration
3. Restart Nginx

### Issue: "CSRF verification failed"

**Cause**: CSRF_TRUSTED_ORIGINS mismatch

**Fix**:
```python
# Already configured in settings.py:
CSRF_TRUSTED_ORIGINS = [
    'https://fkstrading.xyz',
    'https://www.fkstrading.xyz',
]

# If using different domain, add it:
CSRF_TRUSTED_ORIGINS.append('https://yourdomain.com')
```

### Issue: Login redirect loop

**Cause**: Session cookie domain mismatch

**Fix**:
```python
# In settings.py, set:
SESSION_COOKIE_DOMAIN = '.fkstrading.xyz'  # Note the leading dot
```

### Issue: 502 Bad Gateway

**Cause**: Web service not running

**Fix**:
```bash
# Check service status
docker-compose ps web

# If not healthy, check logs
docker-compose logs web

# Restart if needed
docker-compose restart web
```

---

## 🔧 Service Management

### Check All Services
```bash
# Status
docker-compose ps

# Should show:
# fks_nginx   - healthy
# fks_main    - healthy (web service)
# fks_db      - healthy
# fks_redis   - healthy
```

### Restart Services
```bash
# Restart web only
docker-compose restart web

# Restart Nginx only
docker-compose restart fks_nginx

# Restart all services
docker-compose restart
```

### View Logs
```bash
# Web service logs
docker-compose logs -f web

# Nginx logs
docker-compose logs -f fks_nginx

# All logs
docker-compose logs -f
```

---

## 📊 Health Monitoring

### Endpoints

| Check | URL | Expected |
|-------|-----|----------|
| **Nginx** | https://fkstrading.xyz/ | 302 redirect |
| **Django** | https://fkstrading.xyz/admin/ | Login page |
| **Health** | https://fkstrading.xyz/health/ | JSON status |
| **Dashboard** | https://fkstrading.xyz/ninja/dashboard/ | Dashboard UI |

### Quick Health Check
```bash
# Test all endpoints
./BROWSER_TEST_START.sh

# Or manual check
curl -k -I https://localhost/health/
# Expected: HTTP/2 200
```

---

## 📚 Additional Resources

### Documentation
- **Browser Testing**: `docs/BROWSER_TESTING_GUIDE.md` (40-minute comprehensive checklist)
- **Testing Summary**: `docs/TESTING_COMPLETE.md` (automated test results)
- **Backtest Fix**: `docs/BACKTEST_FIX.md` (production bug fix documentation)
- **Architecture**: `docs/ARCHITECTURE.md` (system overview)

### Quick Commands
```bash
# Start browser testing
./BROWSER_TEST_START.sh

# Check service health
docker-compose ps

# View web logs
docker-compose logs web

# Restart web service
docker-compose restart web
```

### Support
- **Issues**: https://github.com/nuniesmith/fks/issues
- **Documentation**: `/home/jordan/Documents/fks/docs/`
- **Logs**: `/home/jordan/Documents/fks/logs/`

---

## ✅ Current Status

**Domain**: ✅ Configured (fkstrading.xyz)  
**DNS**: ⏳ Pending setup (point A record to server IP)  
**SSL**: ⚠️ Self-signed (upgrade to Let's Encrypt for production)  
**Services**: ✅ Running and healthy  
**Login**: ✅ Working (admin/fks2025admin!)  
**Testing**: ✅ Environment ready  

**Next Steps**:
1. ✅ **DONE**: Backtest page fixed
2. ⏳ **TODO**: Point DNS to server IP
3. ⏳ **TODO**: Obtain Let's Encrypt certificate
4. ⏳ **TODO**: Continue browser testing
5. ⏳ **TODO**: Change admin password (production)

---

**Ready to Use**: You can now access the platform at https://fkstrading.xyz (after DNS setup) or https://localhost (local testing) 🚀
