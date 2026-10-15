$ErrorActionPreference = "Stop"

Write-Host "Creating iOS-only Flutter project..." -ForegroundColor Cyan

if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
    throw "Flutter was not found in PATH. Open a terminal where 'flutter --version' works."
}

# Preserve the ported application files while Flutter generates native iOS scaffolding.
$pubspec = Get-Content ".\pubspec.yaml" -Raw
$main = Get-Content ".\lib\main.dart" -Raw

flutter create `
  --platforms=ios `
  --org com.dragos `
  --project-name ble_nfc_wlc_ios `
  .

# Restore our application files.
Set-Content ".\pubspec.yaml" $pubspec -Encoding UTF8
Set-Content ".\lib\main.dart" $main -Encoding UTF8

flutter pub get

# ---------------------------------------------------------------------------
# iOS configuration
# ---------------------------------------------------------------------------

$plistPath = ".\ios\Runner\Info.plist"
$plist = Get-Content $plistPath -Raw

# Friendly name shown on the iPhone.
$plist = $plist -replace '<key>CFBundleDisplayName</key>\s*<string>[^<]*</string>', @'
<key>CFBundleDisplayName</key>
	<string>BLE NFC WLC</string>
'@

if ($plist -notmatch "NSBluetoothAlwaysUsageDescription") {
    $keys = @'
	<key>NSBluetoothAlwaysUsageDescription</key>
	<string>BLE NFC WLC uses Bluetooth to discover, connect to, configure and diagnose supported BLE devices.</string>
	<key>NSBluetoothPeripheralUsageDescription</key>
	<string>BLE NFC WLC uses Bluetooth to communicate with supported BLE devices.</string>
	<key>ITSAppUsesNonExemptEncryption</key>
	<false/>
'@
    $plist = $plist -replace '</dict>', "$keys`r`n</dict>"
}

Set-Content $plistPath $plist -Encoding UTF8

# Use one clean bundle identifier for Apple Developer / App Store Connect.
$pbxPath = ".\ios\Runner.xcodeproj\project.pbxproj"
$pbx = Get-Content $pbxPath -Raw
$pbx = [regex]::Replace(
    $pbx,
    'PRODUCT_BUNDLE_IDENTIFIER = [^;]+;',
    'PRODUCT_BUNDLE_IDENTIFIER = com.dragos.blenfcwlc;'
)
Set-Content $pbxPath $pbx -Encoding UTF8

Write-Host ""
Write-Host "iOS-only project prepared successfully." -ForegroundColor Green
Write-Host ""
Write-Host "Bundle ID: com.dragos.blenfcwlc"
Write-Host "Display name: BLE NFC WLC"
Write-Host ""
Write-Host "Next:"
Write-Host "  git init"
Write-Host "  git add ."
Write-Host '  git commit -m "Initial iOS port of BLE NFC WLC"'
Write-Host "  git branch -M main"
Write-Host "  git remote add origin <YOUR_REPO_URL>"
Write-Host "  git push -u origin main"
Write-Host ""
Write-Host "Then build the iOS app with Codemagic/TestFlight."
