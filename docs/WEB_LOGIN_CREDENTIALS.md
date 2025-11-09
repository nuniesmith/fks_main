# FKS Trading Web Interface - Login Credentials

**Domain**: https://fkstrading.xyz  
**Date Created**: November 1, 2025  
**Status**: ✅ Active & Configured

---

## 🔐 Admin Login Credentials

### Django Admin Panel
**URL**: https://fkstrading.xyz/admin/

**Credentials**:
- **Username**: `admin`
- **Password**: `fks2025admin!`

**Access Level**: Full administrative access
- User management
- NT8 account management
- Signal log monitoring
- Database admin
- Site configuration

---

## 📱 Application Access URLs

### Main Dashboard
**URL**: https://fkstrading.xyz/ninja/dashboard/
- NT8 package downloads
- Build status monitoring
- Account health overview
- Signal management

### NT8 Management
**URL**: https://fkstrading.xyz/admin/ninja/nt8account/
- Manage prop firm accounts
- View daily P&L (color-coded)
- Monitor socket connections
- Track signal counts

### Signal History
**URL**: https://fkstrading.xyz/admin/ninja/signallog/
- View all trading signals
- Success/failure tracking
- Latency monitoring
- Error analysis

### Installation Guide
**URL**: https://fkstrading.xyz/ninja/installation/
- Complete NT8 setup instructions
- Troubleshooting guide
- Configuration help

### System Health
**URL**: https://fkstrading.xyz/health
- Service status monitoring
- Database connectivity
- Redis cache status

### Celery Monitoring (Flower)
**URL**: https://fkstrading.xyz/flower/
- Task queue monitoring
- Worker status
- Task history
- Performance metrics

---

## 🌐 Domain Configuration

### Current Setup
- **Primary Domain**: fkstrading.xyz
- **WWW Redirect**: www.fkstrading.xyz → fkstrading.xyz
- **HTTP Redirect**: http:// → https:// (automatic)
- **SSL/TLS**: Self-signed certificate (will upgrade to Let's Encrypt)

### DNS Requirements
For external access, ensure DNS is configured:
```
A Record:     fkstrading.xyz → [Your Server IP]
CNAME Record: www.fkstrading.xyz → fkstrading.xyz
```

### Local Testing
If testing locally, add to `/etc/hosts`:
```
127.0.0.1  fkstrading.xyz www.fkstrading.xyz
```

---

## 🔒 Security Features

### Active Protections
- ✅ HTTPS-only (auto-redirect from HTTP)
- ✅ TLS 1.2/1.3 only
- ✅ HSTS headers (strict transport security)
- ✅ X-Frame-Options (clickjacking protection)
- ✅ Content-Security-Policy
- ✅ Rate limiting (10 req/s general, 30 req/s API)
- ✅ Connection limiting (20 concurrent per IP)
- ✅ CSRF protection (Django)
- ✅ Session security (HttpOnly, Secure cookies)

### Authentication
- Django session-based authentication
- Password hashing (PBKDF2 SHA256)
- Session timeout: 7 days
- Login required for all admin/dashboard pages

---

## 🚀 Quick Start Guide

### Step 1: Access the Site
1. Open browser: https://fkstrading.xyz
2. Accept SSL certificate warning (self-signed)
   - Click "Advanced" → "Proceed to fkstrading.xyz"

### Step 2: Login
1. Navigate to: https://fkstrading.xyz/admin/
2. Enter credentials:
   - Username: `admin`
   - Password: `fks2025admin!`
3. Click "Log in"

### Step 3: Explore Dashboard
1. Visit: https://fkstrading.xyz/ninja/dashboard/
2. Test features:
   - Download NT8 package
   - View build status
   - Monitor account health
   - Check signal logs

---

## 📋 Testing Checklist

### Basic Access (5 minutes)
- [ ] Domain resolves (https://fkstrading.xyz)
- [ ] HTTPS redirect working (http:// → https://)
- [ ] Admin login successful
- [ ] Dashboard loads
- [ ] Static files loading (CSS/JS)

### Admin Panel (10 minutes)
- [ ] NT8Account list displays
- [ ] Color-coded P&L visible ($250.00 green)
- [ ] Privacy masking working (****5678)
- [ ] SignalLog list displays
- [ ] Success/failure indicators (✓/✗)

### Package Download (5 minutes)
- [ ] Download button works
- [ ] ZIP file downloads (113 KB)
- [ ] Contains: DLL, source, manifests

### Navigation (5 minutes)
- [ ] All links working
- [ ] No 404 errors
- [ ] Proper redirects
- [ ] Logout/login cycle works

---

## 🔧 Service Management

### Check Services
```bash
# Verify all services running
docker-compose ps

# Check specific service
docker-compose ps nginx web db redis
```

### Restart Services
```bash
# Restart web service
docker-compose restart web

# Restart Nginx
docker-compose restart nginx

# Restart all
docker-compose restart
```

### View Logs
```bash
# All services
docker-compose logs -f

# Nginx only
docker-compose logs -f nginx

# Django only
docker-compose logs -f web

# Last 100 lines
docker-compose logs --tail=100 web
```

### Access Django Shell
```bash
# Interactive shell
docker-compose exec web python manage.py shell

# Create additional users
docker-compose exec web python manage.py createsuperuser
```

---

## 🆘 Troubleshooting

### Issue 1: SSL Certificate Warning
**Symptom**: "Your connection is not private"
**Solution**: 
- Expected with self-signed certificate
- Click "Advanced" → "Proceed to fkstrading.xyz"
- For production, configure Let's Encrypt:
  ```bash
  docker-compose run --rm certbot certonly --webroot \
    -w /var/www/certbot \
    -d fkstrading.xyz \
    -d www.fkstrading.xyz
  ```

### Issue 2: Domain Not Resolving
**Symptom**: "Can't reach this page"
**Solution**:
- Check DNS configuration
- Verify server IP in A record
- Test with: `nslookup fkstrading.xyz`
- For local testing, add to `/etc/hosts`

### Issue 3: 502 Bad Gateway
**Symptom**: Nginx shows 502 error
**Solution**:
```bash
# Check if web service is healthy
docker-compose ps web

# View web service logs
docker-compose logs web

# Restart if needed
docker-compose restart web nginx
```

### Issue 4: Login Not Working
**Symptom**: Invalid credentials or redirect loop
**Solution**:
```bash
# Reset admin password
docker-compose exec web python manage.py shell <<EOF
from django.contrib.auth import get_user_model
User = get_user_model()
user = User.objects.get(username='admin')
user.set_password('fks2025admin!')
user.save()
print("Password reset successfully!")
