# Quick Split Commands

## 🚀 Execute Split
```bash
cd /home/jordan/Documents/code/fks
./scripts/split-all-repos.sh
```

## 🔍 Verify Before Split
```bash
./scripts/verify-split.sh
```

## 📊 Review After Split
```bash
cd /tmp/fks_split
for repo in fks_ai fks_api fks_app fks_data fks_execution fks_ninja fks_meta fks_web; do
  echo "=== $repo ==="
  cd ${repo}_temp
  git log --oneline | head -3
  echo ""
  cd ..
done
```

## �� Push to GitHub (One at a time)
```bash
cd /tmp/fks_split/fks_ai_temp && git push -u origin main --force
cd /tmp/fks_split/fks_api_temp && git push -u origin main --force
cd /tmp/fks_split/fks_app_temp && git push -u origin main --force
cd /tmp/fks_split/fks_data_temp && git push -u origin main --force
cd /tmp/fks_split/fks_execution_temp && git push -u origin main --force
cd /tmp/fks_split/fks_ninja_temp && git push -u origin main --force
cd /tmp/fks_split/fks_meta_temp && git push -u origin main --force
cd /tmp/fks_split/fks_web_temp && git push -u origin main --force
```

## 🔄 Or Push All (After verification)
```bash
cd /tmp/fks_split
for repo in fks_ai fks_api fks_app fks_data fks_execution fks_ninja fks_meta fks_web; do
  cd ${repo}_temp && git push -u origin main --force && cd ..
done
```

## ✅ Verify on GitHub
```bash
# Open in browser
xdg-open https://github.com/nuniesmith/fks_ai
xdg-open https://github.com/nuniesmith/fks_api
xdg-open https://github.com/nuniesmith/fks_app
xdg-open https://github.com/nuniesmith/fks_data
```

## 🧹 Cleanup (After successful push)
```bash
rm -rf /tmp/fks_split
```
