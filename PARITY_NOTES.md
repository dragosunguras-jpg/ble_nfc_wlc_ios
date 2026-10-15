# BLE NFC WLC — iOS parity update

This patch uses the supplied Android Kotlin application and the architecture presentation as the reference implementation.

## Files to replace / add

Replace:
- `lib/main.dart`
- `pubspec.yaml`
- `ios/Runner/Info.plist`

Add:
- `lib/oem_catalog.dart`
- `assets/board3d_preview.png`

Do **not** replace `ios/Runner.xcodeproj/project.pbxproj`; keep the bundle-ID fix already made in the existing project.

## What was brought back from Android

### UI / navigation
- Renesas blue theme and light blue-white background
- shared top bar with menu, battery icon, board name and Disconnect
- Renesas footer acting as Home
- drawer: Overview / WLC / PTX205R / RA6B1
- Overview board, clickable WLC/NFC/RA6B1 regions, active green states
- Overview event terminal
- toast notifications that jump to the relevant board area
- WLC tabs: Status / Battery graph / OEM
- PTX205R tabs: Card reader / Polling / PSL
- RA6B1 tabs: Info / Proximity
- NFC background logo changing state on card detection
- Polling controls and labels matching the Android structure
- PSL controls, progress and Q trace chart
- OEM catalog generated from the Android `OemCatalog.kt`

### BLE / protocol behavior
- scan only devices whose advertised name starts with `Zephyr`
- 15-second scan timeout
- up to 3 connection attempts
- waits for initial Battery/System Status before showing the connected UI, with timeout fallback
- same custom UUID map
- same little-endian parsers
- same Card Exchange fragment reassembly
- Battery notifications + 1-second read polling
- Battery percentage hysteresis
- System Status change events
- Polling: Config -> Control apply -> Status/reload flow and 15-second timeout
- PSL: start/stop, status/result/trace, keep trace
- OEM: full 46-parameter catalog, 6 entries/18 bytes per chunk, commit `02 01 A5 5A`, 40-second result timeout
- OEM current-range dependency handling for IDs 1/2/3/4
- connected RSSI monitoring

## iOS-only differences that cannot be made API-identical to Android

The user-visible goal is parity, but iOS/CoreBluetooth does not expose these Android APIs:

- `BluetoothGatt.refresh()` / manual GATT-cache clearing
- `BluetoothDevice.removeBond()`
- Android `ACTION_PAIRING_REQUEST` interception
- automatic insertion of the fixed demo PIN by the application
- direct readout of Android bond state

For encrypted GATT writes, iOS/CoreBluetooth owns pairing. If the board requires the passkey, iOS presents its pairing UI. This is a platform restriction, not an omitted app feature.

## Apply automatically

From the extracted patch directory:

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
.\APPLY_UPDATE.ps1 "C:\AleMele\RenesasBLEApp\ble_nfc_wlc_ios"
```

Then:

```powershell
cd C:\AleMele\RenesasBLEApp\ble_nfc_wlc_ios
git status
git add .
git commit -m "Port Android BLE NFC WLC UI and behavior to iOS"
git push
```

Build with Codemagic. The patch sets `version: 0.1.0+2`, so App Store Connect receives build 2.

## Reference screenshots

The `reference_ui/` directory contains the Android screenshots extracted from the supplied presentation. They are not runtime UI assets; they are included for visual comparison during TestFlight validation.
