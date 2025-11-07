# Django NT8 Browser Testing Guide

**Date**: November 1, 2025  
**Status**: ✅ Services Running  
**Access**: http://localhost (redirects to https://localhost)

## Prerequisites

✅ **Services Running**:
- fks_main (Django web) - Healthy
- fks_nginx (Reverse proxy) - Healthy
- fks_db (PostgreSQL) - Healthy
- fks_redis (Cache) - Healthy

✅ **Admin Credentials**:
- **Username**: admin
- **Password**: fks2025admin!

✅ **Test Data Created**:
- 1 NT8Account (apex-5678, $250.00 P&L)
- 2 SignalLogs (1 success, 1 failure)

## Browser Testing Checklist

### 1. Initial Access (5 minutes)

**Step 1.1: Open Browser**
```
URL: http://localhost
Expected: Redirects to https://localhost
Note: You'll see SSL warning (self-signed cert) - click "Advanced" → "Proceed"
```

**Step 1.2: Login to Admin**
```
URL: https://localhost/admin/
Username: admin
Password: fks2025admin!
Expected: Django admin dashboard loads
```

✅ **Success Criteria**:
- [ ] No connection refused errors
- [ ] Admin login page loads
- [ ] Credentials accepted
- [ ] Dashboard visible

---

### 2. NT8 Dashboard Testing (10 minutes)

**Step 2.1: Navigate to NT8 Dashboard**
```
URL: https://localhost/ninja/dashboard/
Expected: NT8 account management page loads
```

**Visual Check**:
- [ ] Download button visible ("Download FKS_AsyncStrategy.zip")
- [ ] Build status section present
- [ ] Manual build trigger button visible
- [ ] Account health status table visible

**Step 2.2: Test Package Download**
```
Action: Click "Download FKS_AsyncStrategy.zip" button
Expected: Browser downloads ZIP file (113 KB)
```

**Verify Download**:
```bash
# In terminal, check downloaded file:
ls -lh ~/Downloads/FKS_AsyncStrategy*.zip
unzip -l ~/Downloads/FKS_AsyncStrategy*.zip
```

Expected ZIP contents:
- FKS.dll (275 KB)
- FKS_AsyncStrategy.cs (18.9 KB)
- Info.xml
- AdditionalReferences.txt
- README.txt

**Step 2.3: Watch AJAX Auto-Refresh**
```
Action: Leave dashboard open, watch "Build Status" section
Expected: Updates every 10 seconds without page reload
Note: Look for timestamp changes in build status
```

**Step 2.4: Test Manual Build Trigger**
```
Action: Click "Trigger Manual Build" button
Expected: 
  - Page redirects to build result
  - Shows build output or status
  - Can navigate back to dashboard
```

✅ **Success Criteria**:
- [ ] Dashboard loads without errors
- [ ] Download button works (ZIP downloads)
- [ ] AJAX refresh functional (10-second updates)
- [ ] Build trigger works (redirects correctly)
- [ ] No JavaScript console errors

---

### 3. Admin Interface Testing (10 minutes)

**Step 3.1: NT8Account Admin List**
```
URL: https://localhost/admin/ninja/nt8account/
Expected: Table with 1 account
```

**Visual Checks**:
- [ ] Account number shows masked: "****5678"
- [ ] Firm name: "apex"
- [ ] Port: "8080"
- [ ] Daily P&L: **$250.00 in GREEN**
- [ ] Active: Green checkmark ✓
- [ ] Last signal time displayed

**Step 3.2: NT8Account Detail View**
```
Action: Click on the account row
Expected: Detail form loads
```

**Verify Fields**:
- [ ] Firm dropdown populated
- [ ] Account number: 12345678
- [ ] Socket port: 8080
- [ ] Active checkbox checked
- [ ] Daily P&L: 250.00
- [ ] Timestamps shown (created_at, updated_at)

**Step 3.3: SignalLog Admin List**
```
URL: https://localhost/admin/ninja/signallog/
Expected: Table with 2 signal entries
```

**Visual Checks**:

**Record 1** (Success):
- [ ] Success indicator: Green checkmark ✓
- [ ] Action: "BUY"
- [ ] Price: 4500.25
- [ ] Symbol: ES 03-25
- [ ] Latency: 45ms

**Record 2** (Failure):
- [ ] Success indicator: Red X ✗
- [ ] Action: "SELL"
- [ ] Price: 15000.50
- [ ] Symbol: NQ 03-25
- [ ] Error message visible

**Step 3.4: SignalLog Detail View**
```
Action: Click on a signal row
Expected: Detail form loads with JSON data
```

**Verify Fields**:
- [ ] Account dropdown shows apex-5678
- [ ] Signal data (JSON format) readable
- [ ] Timestamp accurate
- [ ] Success boolean correct
- [ ] Error message shown (if failed)

✅ **Success Criteria**:
- [ ] Color coding works (green P&L, success/fail indicators)
- [ ] Privacy masking working (****5678)
- [ ] All data displays correctly
- [ ] Forms editable and saveable
- [ ] No formatting errors

---

### 4. Installation Guide Testing (5 minutes)

**Step 4.1: Access Installation Guide**
```
URL: https://localhost/ninja/installation/
Expected: Comprehensive installation instructions
```

**Content Checks**:
- [ ] Prerequisites section visible
- [ ] Step-by-step installation instructions
- [ ] Configuration section present
- [ ] Testing section included
- [ ] Support links working

**Step 4.2: Verify Links**
```
Action: Click any internal links
Expected: Navigate correctly, no 404s
```

✅ **Success Criteria**:
- [ ] Page loads completely
- [ ] All sections formatted correctly
- [ ] Links functional
- [ ] Content readable

---

### 5. Navigation & UX Testing (5 minutes)

**Step 5.1: Menu Navigation**
```
Action: Test all navigation links
Expected: Smooth transitions, no broken links
```

Links to test:
- [ ] Dashboard → Admin
- [ ] Admin → Dashboard
- [ ] Admin → NT8Accounts → back
- [ ] Admin → SignalLogs → back

**Step 5.2: Responsive Design**
```
Action: Resize browser window
Expected: Layout adapts (mobile-friendly)
```

**Step 5.3: Logout/Login**
```
Action: Log out, then log back in
Expected: Session maintained, redirect to login works
```

✅ **Success Criteria**:
- [ ] Navigation smooth
- [ ] No broken links
- [ ] Responsive layout
- [ ] Session handling correct

---

### 6. Error Handling Testing (5 minutes)

**Step 6.1: Test Invalid URLs**
```
URL: https://localhost/ninja/nonexistent/
Expected: 404 page or redirect
```

**Step 6.2: Test Unauthenticated Access**
```
Action: Log out, try accessing dashboard
Expected: Redirect to login page
```

**Step 6.3: Browser Console**
```
Action: Open DevTools (F12) → Console tab
Expected: No JavaScript errors (except SSL warnings)
```

✅ **Success Criteria**:
- [ ] 404 handling graceful
- [ ] Auth redirects work
- [ ] No console errors
- [ ] Error messages user-friendly

---

## Common Issues & Solutions

### Issue 1: SSL Certificate Warning
**Symptom**: Browser shows "Your connection is not private"
**Solution**: 
- Click "Advanced"
- Click "Proceed to localhost (unsafe)"
- This is expected with self-signed certificates

### Issue 2: Port Already in Use
**Symptom**: `docker-compose up` fails with port 80 error
**Solution**:
```bash
# Check what's using port 80
sudo lsof -i :80

# Stop conflicting service
sudo systemctl stop apache2  # or nginx
```

### Issue 3: Nginx 502 Bad Gateway
**Symptom**: Nginx loads but shows 502 error
**Solution**:
```bash
# Check if web service is healthy
docker-compose ps web

# Restart if needed
docker-compose restart web nginx
```

### Issue 4: Download Button Not Working
**Symptom**: Click download, nothing happens
**Solution**:
- Check browser console for errors
- Verify build files exist: `docker-compose exec web ls -lh /app/src/services/ninja/bin/Release/`
- Test direct URL: `https://localhost/ninja/download/`

### Issue 5: AJAX Not Updating
**Symptom**: Build status never refreshes
**Solution**:
- Check browser console for errors
- Verify `/ninja/build-status/` endpoint: `curl https://localhost/ninja/build-status/ -k`
- Check JavaScript: Look for `setInterval` in page source

---

## Testing Results Template

Use this to document your findings:

```
BROWSER TESTING RESULTS
========================
Date: [Fill in]
Browser: [Chrome/Firefox/Edge]
OS: [Linux/Windows/Mac]

Dashboard Access:
[ ] URL loads
[ ] Download works
[ ] AJAX refresh working
[ ] Build trigger functional

Admin Interface:
[ ] NT8Account list loads
[ ] Color coding correct
[ ] Privacy masking works
[ ] SignalLog list loads
[ ] Success indicators visible

Installation Guide:
[ ] Page loads
[ ] Content complete
[ ] Links functional

Issues Found:
1. [Describe any issues]
2. 
3. 

Overall Status: [PASS/FAIL]
Deployment Ready: [YES/NO]
```

---

## Next Steps After Testing

### If All Tests Pass ✅
1. Document any minor UI improvements needed
2. Proceed to Windows NT8 integration testing
3. Consider production deployment

### If Issues Found ❌
1. Document specific errors in testing results
2. Check browser console for JavaScript errors
3. Review Nginx logs: `docker-compose logs nginx`
4. Review Django logs: `docker-compose logs web`
5. Fix issues and re-test

---

## Quick Test Commands

```bash
# Check service health
docker-compose ps

# View live logs (all services)
docker-compose logs -f

# View Django logs only
docker-compose logs -f web

# View Nginx logs only
docker-compose logs -f nginx

# Restart all services
docker-compose restart

# Stop all services
docker-compose down

# Start all services
docker-compose up -d
```

---

## Access URLs Summary

| Description | URL | Auth Required |
|-------------|-----|---------------|
| **Homepage** | https://localhost/ | No |
| **Admin Login** | https://localhost/admin/ | Yes |
| **NT8 Dashboard** | https://localhost/ninja/dashboard/ | Yes |
| **Package Download** | https://localhost/ninja/download/ | Yes |
| **Build Status API** | https://localhost/ninja/build-status/ | Yes |
| **Installation Guide** | https://localhost/ninja/installation/ | Yes |
| **NT8Account Admin** | https://localhost/admin/ninja/nt8account/ | Yes |
| **SignalLog Admin** | https://localhost/admin/ninja/signallog/ | Yes |

---

## Expected Test Duration

- **Initial Access**: 5 minutes
- **Dashboard Testing**: 10 minutes
- **Admin Interface**: 10 minutes
- **Installation Guide**: 5 minutes
- **Navigation/UX**: 5 minutes
- **Error Handling**: 5 minutes

**Total**: ~40 minutes for comprehensive testing

---

## Success Metrics

**Minimum Acceptable**:
- All pages load (6/6)
- Download works
- Admin interface functional
- No critical errors

**Ideal**:
- All tests pass (100%)
- AJAX refresh working
- Color coding perfect
- Responsive design works
- Zero console errors

---

*For automated test results, see `docs/TESTING_COMPLETE.md`*
