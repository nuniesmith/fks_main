# Kubernetes Dashboard - Simple Auto-Login Setup

**Date**: 2025-11-12  
**Status**: ✅ **READY TO USE**  
**Purpose**: One-command dashboard access with token automatically copied to clipboard

---

## 🎯 Quick Start

### Linux/WSL/Mac

```bash
cd repo/main
./scripts/dashboard-auto-login.sh
```

### Windows (PowerShell)

```powershell
cd repo/main
.\scripts\dashboard-auto-login.ps1
```

That's it! The script will:
1. ✅ Start kubectl proxy in background
2. ✅ Copy token to clipboard
3. ✅ Open dashboard in browser
4. ✅ You just paste the token (Ctrl+V / Cmd+V)

---

## 🔧 How It Works

### Token Storage

- Token is saved to: `repo/main/k8s/dashboard-token.txt`
- Token is automatically copied to clipboard
- Token is reused (refreshed if needed)

### kubectl Proxy

- Automatically starts on port 8001
- Runs in background
- Automatically stops any existing proxy

### Browser Access

- Dashboard URL opens automatically
- Token is in clipboard - just paste it
- No need to type or copy token manually

---

## 📋 Usage

### Start Dashboard

```bash
# Linux/WSL/Mac
./scripts/dashboard-auto-login.sh

# Windows
.\scripts\dashboard-auto-login.ps1
```

### Stop Dashboard

```bash
# Linux/WSL/Mac
pkill -f "kubectl proxy"

# Windows
Get-Process kubectl | Where-Object { $_.CommandLine -like '*proxy*' } | Stop-Process
```

### Restart Dashboard

Just run the script again - it will automatically stop the old proxy and start a new one.

---

## 🔐 Token Management

### Token File Location

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

## 🚀 Advanced Options

### Custom Port

Edit the script and change `PROXY_PORT`:

```bash
PROXY_PORT=8002  # Change from 8001 to 8002
```

### Custom Token File

Edit the script and change `TOKEN_FILE`:

```bash
TOKEN_FILE="$HOME/.k8s/dashboard-token.txt"
```

---

## 📊 Dashboard URL

The dashboard is accessible at:

```
http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/
```

This URL is automatically opened when you run the script.

---

## 🔧 Troubleshooting

### Token Not Working

```bash
# Recreate admin user and token
kubectl delete secret admin-user-token -n kubernetes-dashboard
kubectl apply -f repo/main/k8s/manifests/dashboard-admin-user.yaml
sleep 5
./scripts/dashboard-auto-login.sh
```

### Proxy Not Starting

```bash
# Check if port is in use
lsof -i :8001

# Kill existing process
kill <PID>

# Or use different port in script
```

### Clipboard Not Working

If clipboard copy fails, the token will be displayed in the terminal. Just copy it manually.

---

## 🎉 Summary

### One Command to Rule Them All

```bash
./scripts/dashboard-auto-login.sh
```

This single command:
- ✅ Starts kubectl proxy
- ✅ Copies token to clipboard
- ✅ Opens dashboard in browser
- ✅ Ready to paste token (Ctrl+V / Cmd+V)

### Benefits

- ✅ **No Manual Token Entry**: Token is automatically copied to clipboard
- ✅ **One Command**: Just run the script and paste
- ✅ **Automatic Proxy**: kubectl proxy starts automatically
- ✅ **Easy Access**: Dashboard opens automatically
- ✅ **Local Development**: Perfect for local Kubernetes development

---

**Status**: ✅ **READY TO USE**

**Last Updated**: 2025-11-12

**Next Action**: Run `./scripts/dashboard-auto-login.sh` and paste the token (Ctrl+V / Cmd+V)!

---

**Happy Dashboarding!** 🚀

