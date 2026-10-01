#!/bin/zsh
# Build Monthly Budget.app and install it to ~/Applications
set -e
cd "$(dirname "$0")"
python3 build.py
APP="build/Monthly Budget.app"; C="$APP/Contents"
rm -rf build && mkdir -p "$C/MacOS" "$C/Resources"
cp index.html "$C/Resources/"
mkdir -p "$C/Resources/fonts" && cp fonts/*.woff2 "$C/Resources/fonts/"
cat > "$C/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleName</key><string>Monthly Budget</string>
<key>CFBundleDisplayName</key><string>Monthly Budget</string>
<key>CFBundleIdentifier</key><string>io.github.silentrosehill.monthlybudget</string>
<key>CFBundleExecutable</key><string>MonthlyBudget</string>
<key>CFBundlePackageType</key><string>APPL</string>
<key>CFBundleShortVersionString</key><string>1.0</string>
<key>CFBundleVersion</key><string>1</string>
<key>CFBundleIconFile</key><string>AppIcon</string>
<key>LSMinimumSystemVersion</key><string>26.0</string>
<key>NSHighResolutionCapable</key><true/>
</dict></plist>
PLIST
rm -rf build/AppIcon.iconset && mkdir -p build/AppIcon.iconset
for s in 16 32 128 256 512; do
  sips -z $s $s icon/wallet1024.png --out build/AppIcon.iconset/icon_${s}x${s}.png >/dev/null
  sips -z $((s*2)) $((s*2)) icon/wallet1024.png --out build/AppIcon.iconset/icon_${s}x${s}@2x.png >/dev/null
done
iconutil -c icns build/AppIcon.iconset -o "$C/Resources/AppIcon.icns"
swiftc -O -o "$C/MacOS/MonthlyBudget" main.swift -framework Cocoa -framework WebKit
codesign --force --deep -s - "$APP"
pkill -f "MacOS/MonthlyBudget" || true
sleep 1
mkdir -p ~/Applications && rm -rf ~/Applications/"Monthly Budget.app" && cp -R "$APP" ~/Applications/
open ~/Applications/"Monthly Budget.app"
echo "Installed ~/Applications/Monthly Budget.app"
