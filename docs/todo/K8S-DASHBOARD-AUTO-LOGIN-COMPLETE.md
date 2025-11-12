# Kubernetes Dashboard - Complete Auto-Login Setup Guide

**Date**: 2025-11-12  
**Status**: ✅ **READY TO USE**  
**Purpose**: Set up automatic login for Kubernetes Dashboard on local machine

---

## 🎯 Overview

This guide shows you how to set up automatic login for the Kubernetes Dashboard so you don't have to enter the token every time. Perfect for local development!

---

## 🚀 Quick Start (Simplest Method)

### Step 1: Start Dashboard with Auto-Copied Token

```bash
cd repo/main
./scripts/dashboard-auto-login.sh
```

**That's it!** The script will:
1. ✅ Start kubectl proxy in background
2. ✅ Copy token to clipboard automatically
3. ✅ Open dashboard in browser
4. ✅ You just paste the token (Ctrl+V / Cmd+V)

### Step 2: Paste Token

When the dashboard opens, just press **Ctrl+V** (or **Cmd+V** on Mac) to paste the token. That's it!

---

## 🔐 Method 1: Clipboard Auto-Copy (Recommended)

### Linux/WSL/Mac

```bash
./scripts/dashboard-auto-login.sh
```

### Windows (PowerShell)

```powershell
.\scripts\dashboard-auto-login.ps1
```

**How it works:**
- Script starts kubectl proxy
- Token is automatically copied to clipboard
- Dashboard opens in browser
- You paste the token (Ctrl+V / Cmd+V)
- Dashboard logs you in

**Benefits:**
- ✅ No typing required
- ✅ One command to start
- ✅ Token always in clipboard
- ✅ Works on all platforms

---

## 🔖 Method 2: Browser Bookmarklet (True Auto-Login)

### Step 1: Generate Bookmarklet

```bash
cd repo/main
./scripts/create-dashboard-bookmarklet-with-token.sh
```

This creates:
- `repo/main/k8s/dashboard-bookmarklet-url.txt` - Bookmarklet URL
- `repo/main/k8s/dashboard-bookmarklet.html` - HTML page with bookmarklet

### Step 2: Create Bookmark

**Option A: Drag and Drop**
1. Open `repo/main/k8s/dashboard-bookmarklet.html` in your browser
2. Drag the "🔐 K8s Dashboard Auto-Login" button to your bookmarks bar
3. Done!

**Option B: Manual Bookmark**
1. Create a new bookmark in your browser (Ctrl+D / Cmd+D)
2. Name it: `K8s Dashboard Auto-Login`
3. Copy the URL from `repo/main/k8s/dashboard-bookmarklet-url.txt`
4. Paste it as the bookmark URL

### Step 3: Use Bookmarklet

1. Start kubectl proxy: `kubectl proxy &`
2. Open dashboard: http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/
3. Click the bookmarklet in your bookmarks bar
4. Token is automatically filled and you're logged in!

**Benefits:**
- ✅ True auto-login - no pasting needed
- ✅ One click to login
- ✅ Works every time
- ✅ No typing required

---

## 🌐 Method 3: Browser Local Storage (Advanced)

### Step 1: Save Token to Browser

1. Open dashboard login page
2. Open browser developer console (F12)
3. Run this JavaScript:

```javascript
// Save token to localStorage
localStorage.setItem('k8s-dashboard-token', 'YOUR_TOKEN_HERE');
```

### Step 2: Auto-Fill Script

Create a bookmarklet that reads from localStorage:

```javascript
javascript:(function(){const token=localStorage.getItem('k8s-dashboard-token');if(token){const input=document.querySelector('input[type="text"][placeholder*="token" i],input[type="password"]');if(input){input.value=token;input.type='text';input.dispatchEvent(new Event('input',{bubbles:true}));setTimeout(()=>{document.querySelector('button[type="submit"]')?.click();},500);}}})();
```

**Benefits:**
- ✅ Token stored in browser
- ✅ No need to regenerate bookmarklet
- ✅ Works across browser sessions

---

## 🔧 Method 4: Browser Extension (Most Advanced)

### Option A: Password Manager

1. Install a password manager extension (LastPass, 1Password, etc.)
2. Save the dashboard token as a password
3. Configure auto-fill for the dashboard URL
4. Token is automatically filled when you visit the dashboard

### Option B: Custom Extension

Create a simple browser extension that:
1. Stores the token in extension storage
2. Auto-fills the token when on dashboard login page
3. Optionally auto-clicks the login button

---

## 📋 Complete Workflow

### Daily Use

1. **Start Dashboard**:
   ```bash
   ./scripts/dashboard-auto-login.sh
   ```

2. **Paste Token**:
   - Dashboard opens automatically
   - Token is in clipboard
   - Press Ctrl+V / Cmd+V
   - Done!

### With Bookmarklet

1. **Start Proxy**:
   ```bash
   kubectl proxy &
   ```

2. **Open Dashboard**:
   - Open: http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/

3. **Click Bookmarklet**:
   - Click the "🔐 K8s Dashboard Auto-Login" bookmark
   - You're automatically logged in!

---

## 🛠️ Scripts Available

### Main Scripts

- **`dashboard-auto-login.sh`** - Start dashboard with token in clipboard (Recommended)
- **`dashboard-auto-login.ps1`** - PowerShell version for Windows
- **`create-dashboard-bookmarklet-with-token.sh`** - Generate bookmarklet with token
- **`setup-k8s-dashboard.sh`** - Initial dashboard setup

### Helper Scripts

- **`stop-k8s-dashboard.sh`** - Stop kubectl proxy
- **`start-dashboard-simple.sh`** - Simple dashboard starter

---

## 🔐 Token Management

### Token Location

```
repo/main/k8s/dashboard-token.txt
```

### Token Refresh

Token is automatically refreshed if:
- Token file doesn't exist
- Token is invalid or expired
- Admin user doesn't exist

### Manual Token Refresh

```bash
# Delete token file
rm repo/main/k8s/dashboard-token.txt

# Run auto-login script (will recreate token)
./scripts/dashboard-auto-login.sh
```

---

## 🎉 Recommended Setup (Local Use)

### For Daily Use

1. **Use the simple script**:
   ```bash
   ./scripts/dashboard-auto-login.sh
   ```

2. **Paste token when prompted** (Ctrl+V / Cmd+V)

3. **That's it!**

### For True Auto-Login

1. **Generate bookmarklet**:
   ```bash
   ./scripts/create-dashboard-bookmarklet-with-token.sh
   ```

2. **Create bookmark** from the generated HTML page

3. **Use bookmarklet** when on dashboard login page

---

## 🔧 Troubleshooting

### Token Not Working

```bash
# Recreate token
rm repo/main/k8s/dashboard-token.txt
./scripts/dashboard-auto-login.sh
```

### Bookmarklet Not Working

1. Check if token is still valid
2. Regenerate bookmarklet:
   ```bash
   ./scripts/create-dashboard-bookmarklet-with-token.sh
   ```
3. Update bookmark with new URL

### Clipboard Not Working

If clipboard copy fails, the token will be displayed in the terminal. Just copy it manually.

---

## 📊 Comparison of Methods

| Method | Setup | Usage | Auto-Login | Security |
|--------|-------|-------|------------|----------|
| **Clipboard** | ✅ Easy | Paste token | ⚠️ Manual paste | ✅ Safe |
| **Bookmarklet** | ✅ Easy | Click bookmark | ✅ Automatic | ✅ Safe (local) |
| **Local Storage** | ⚠️ Manual | Click bookmark | ✅ Automatic | ⚠️ Browser storage |
| **Extension** | ⚠️ Complex | Automatic | ✅ Automatic | ✅ Secure |

**Recommendation**: Use **Clipboard method** for simplicity, or **Bookmarklet method** for true auto-login.

---

## 🎉 Summary

### Simplest Method (Recommended)

```bash
./scripts/dashboard-auto-login.sh
```

Then paste the token (Ctrl+V / Cmd+V). That's it!

### True Auto-Login Method

1. Generate bookmarklet: `./scripts/create-dashboard-bookmarklet-with-token.sh`
2. Create bookmark from generated HTML
3. Click bookmark when on dashboard login page
4. Automatically logged in!

---

**Status**: ✅ **READY TO USE**

**Last Updated**: 2025-11-12

**Next Action**: Run `./scripts/dashboard-auto-login.sh` and paste the token (Ctrl+V / Cmd+V)!

---

**Happy Dashboarding!** 🚀

