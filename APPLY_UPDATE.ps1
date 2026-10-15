$ErrorActionPreference = "Stop"

# Run this script FROM THE EXTRACTED PATCH FOLDER.
# Pass the existing Flutter iOS project folder, for example:
# .\APPLY_UPDATE.ps1 "C:\AleMele\RenesasBLEApp\ble_nfc_wlc_ios"

param(
    [Parameter(Mandatory=$true)]
    [string]$ProjectRoot
)

$PatchRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = (Resolve-Path $ProjectRoot).Path

if (-not (Test-Path "$ProjectRoot\ios\Runner\Info.plist")) {
    throw "This does not look like the BLE NFC WLC Flutter iOS project: $ProjectRoot"
}

New-Item -ItemType Directory -Force "$ProjectRoot\lib" | Out-Null
New-Item -ItemType Directory -Force "$ProjectRoot\assets" | Out-Null

Copy-Item "$PatchRoot\lib\main.dart" "$ProjectRoot\lib\main.dart" -Force
Copy-Item "$PatchRoot\lib\oem_catalog.dart" "$ProjectRoot\lib\oem_catalog.dart" -Force
Copy-Item "$PatchRoot\assets\board3d_preview.png" "$ProjectRoot\assets\board3d_preview.png" -Force
Copy-Item "$PatchRoot\pubspec.yaml" "$ProjectRoot\pubspec.yaml" -Force
Copy-Item "$PatchRoot\ios\Runner\Info.plist" "$ProjectRoot\ios\Runner\Info.plist" -Force

Push-Location $ProjectRoot
try {
    flutter pub get
    Write-Host "" 
    Write-Host "Parity update applied." -ForegroundColor Green
    Write-Host "Build number is now 2 (version 0.1.0+2)."
    Write-Host "Next: git add . ; git commit ; git push ; Codemagic build."
} finally {
    Pop-Location
}
