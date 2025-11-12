# Kubernetes Dashboard - Auto Login Setup

**Date**: 2025-11-12  
**Status**: ✅ **READY TO USE**  
**Purpose**: Automatically start Kubernetes Dashboard with saved token for local development

---

## 🎯 Overview

This guide shows you how to set up automatic login for the Kubernetes Dashboard on your local machine, so you don't have to enter the token every time.

---

## 🚀 Quick Start

### Option 1: Bash Script (Linux/WSL/Mac)

```bash
cd repo/main
./scripts/start-k8s-dashboard-auto.sh
```

### Option 2: PowerShell Script (Windows)

```powershell
cd repo/main
.\scripts\k8s-dashboard-auto-login.ps1
```

---

## 📋 Features

- ✅ **Automatic Token Management**: Saves token to file and reuses it
- ✅ **Auto-Starts kubectl Proxy**: Automatically starts kubectl proxy in background
- ✅ **Copies Token to Clipboard**: Token is copied to clipboard for easy pasting
- ✅ **Opens Dashboard in Browser**: Automatically opens dashboard in default browser
- ✅ **Creates Admin User**: Automatically creates admin user if it doesn't exist
- ✅ **Token Refresh**: Automatically refreshes token if it's older than 24 hours

---

## 🔧 Setup

### Prerequisites

- Kubernetes cluster running (minikube, Docker Desktop, or other)
- `kubectl` installed
- Browser installed

### Installation

1. **Make scripts executable** (Linux/WSL/Mac):
   ```bash
   chmod +x repo/main/scripts/start-k8s-dashboard-auto.sh
   chmod +x repo/main/scripts/stop-k8s-dashboard.sh
   ```

2. **Run the auto-login script**:
   ```bash
   ./scripts/start-k8s-dashboard-auto.sh
   ```

   Or on Windows:
   ```powershell
   .\scripts\k8s-dashboard-auto-login.ps1
   ```

---

## 📊 How It Works

### 1. Token Management

- Token is saved to `repo/main/k8s/dashboard-token.txt`
- Token is automatically refreshed if it's older than 24 hours
- Token is copied to clipboard for easy pasting

### 2. kubectl Proxy

- Automatically starts `kubectl proxy` on port 8001
- Runs in background
- Automatically stops any existing proxy on the same port

### 3. Dashboard Access

- Dashboard URL: `http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/`
- Token is automatically copied to clipboard
- Browser automatically opens to dashboard URL

---

## 🔐 Token Storage

### Token File Location

```
repo/main/k8s/dashboard-token.txt
```

### Token File Format

```
Kubernetes Dashboard Admin Token
================================

Token:
<your-token-here>

Access URL:
http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/

Generated: 2025-11-12 10:00:00
```

### Token Refresh

- Token is automatically refreshed if it's older than 24 hours
- Token is created when admin user is created
- Token is stored securely in Kubernetes secret

---

## 🛠️ Usage

### Start Dashboard

```bash
# Linux/WSL/Mac
./scripts/start-k8s-dashboard-auto.sh

# Windows
.\scripts\k8s-dashboard-auto-login.ps1
```

### Stop Dashboard

```bash
# Linux/WSL/Mac
./scripts/stop-k8s-dashboard.sh

# Windows (PowerShell)
Get-Process kubectl | Where-Object { $_.CommandLine -like '*proxy*' } | Stop-Process
```

### Manual Stop

```bash
# Find proxy process
ps aux | grep "kubectl proxy"

# Kill proxy process
kill <PID>

# Or kill all kubectl proxy processes
pkill -f "kubectl proxy"
```

---

## 🌐 Browser Auto-Login

### Option 1: Clipboard (Recommended)

1. Run the auto-login script
2. Token is automatically copied to clipboard
3. Paste token when prompted in dashboard

### Option 2: Bookmarklet

1. Create a bookmark with the bookmarklet script
2. Click bookmark when on dashboard login page
3. Token is automatically filled in

### Option 3: Browser Extension

1. Install a password manager or clipboard extension
2. Save token to password manager
3. Auto-fill token when prompted

---

## 🔧 Troubleshooting

### Token Not Working

```bash
# Delete token file and recreate
rm repo/main/k8s/dashboard-token.txt
./scripts/start-k8s-dashboard-auto.sh
```

### Proxy Not Starting

```bash
# Check if port is already in use
lsof -i :8001

# Kill existing process
kill <PID>

# Or use different port
kubectl proxy --port=8002
```

### Dashboard Not Loading

```bash
# Check if dashboard is deployed
kubectl get pods -n kubernetes-dashboard

# Check dashboard logs
kubectl logs -n kubernetes-dashboard deployment/kubernetes-dashboard

# Restart dashboard
kubectl rollout restart deployment/kubernetes-dashboard -n kubernetes-dashboard
```

### Admin User Not Created

```bash
# Manually create admin user
kubectl apply -f repo/main/k8s/manifests/dashboard-admin-user.yaml

# Get token
kubectl get secret admin-user-token -n kubernetes-dashboard -o jsonpath='{.data.token}' | base64 --decode
```

---

## 📚 Advanced Configuration

### Custom Port

Edit the script and change `PROXY_PORT`:

```bash
PROXY_PORT=8002  # Change from 8001 to 8002
```

### Custom Token File Location

Edit the script and change `TOKEN_FILE`:

```bash
TOKEN_FILE="$HOME/.k8s/dashboard-token.txt"
```

### Auto-Refresh Token

Token is automatically refreshed if it's older than 24 hours. To change this, edit the script:

```bash
# Check if token is still valid (file modified within last 24 hours)
if [ $(find "$TOKEN_FILE" -mtime -1 2>/dev/null) ]; then
    # Use existing token
fi
```

Change `-mtime -1` to `-mtime -7` for 7 days, etc.

---

## 🎉 Summary

### Complete Workflow

1. **Start Dashboard**: Run `./scripts/start-k8s-dashboard-auto.sh`
2. **Token Copied**: Token is automatically copied to clipboard
3. **Browser Opens**: Dashboard opens in default browser
4. **Paste Token**: Paste token when prompted (already in clipboard)
5. **Access Dashboard**: Dashboard is now accessible

### Benefits

- ✅ **No Manual Token Entry**: Token is automatically copied to clipboard
- ✅ **Automatic Proxy**: kubectl proxy starts automatically
- ✅ **Token Management**: Token is saved and reused
- ✅ **Easy Access**: One command to start dashboard
- ✅ **Local Development**: Perfect for local Kubernetes development

---

**Status**: ✅ **READY TO USE**

**Last Updated**: 2025-11-12

**Next Action**: Run `./scripts/start-k8s-dashboard-auto.sh` to start dashboard with auto-login!

---

**Happy Dashboarding!** 🚀

