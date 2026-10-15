# BLE NFC WLC — iOS only

This repository is the **iOS-only Flutter port** of the supplied Android application.

The original Android project remains separate and unchanged.

## Why Flutter for the iOS port?

The original application is Android-native Kotlin/Jetpack Compose and uses Android's `BluetoothGatt` APIs. That code cannot run directly on iOS.

This port keeps the application logic in Dart/Flutter and uses CoreBluetooth through `flutter_reactive_ble`. It fits the current workflow:

**Windows / Android Studio -> GitHub -> Codemagic -> TestFlight -> iPhone**

There is intentionally **no Android target** in this repository.

## Current iOS port

The port includes the core protocol areas from the Android application:

- BLE scanning
- connect / disconnect
- GATT service discovery
- Battery Service / Battery Level
- system status
- WLC-related status information
- NFC card information
- NFC/card exchange reassembly
- OEM status and raw parameter read/write
- polling configuration read/write/default restore
- PSL / antenna Q measurement commands and results
- RSSI monitoring
- BLE/GATT diagnostics
- application event log

## Android-only behavior not reproduced

Some behavior in the original project relies on Android-only or hidden Bluetooth APIs and should **not** be copied to iOS:

- Android pairing/PIN broadcast interception
- `BluetoothDevice.removeBond()`
- hidden `BluetoothGatt.refresh()`
- Android-specific GATT status/cache workarounds

On iOS, pairing/security/cache behavior is controlled by CoreBluetooth/iOS.

## First setup on Windows

Extract the project and open PowerShell in its root folder:

```powershell
.\setup_ios.ps1
```

This creates **only** the Flutter `ios/` target.

It also configures:

- app display name: `BLE NFC WLC`
- Bundle ID: `com.dragos.blenfcwlc`
- Bluetooth permission descriptions
- `ITSAppUsesNonExemptEncryption = false`

You do **not** need to build iOS locally on Windows.

## Push to GitHub

Create an empty GitHub repository, then:

```powershell
git init
git add .
git commit -m "Initial iOS port of BLE NFC WLC"
git branch -M main
git remote add origin <YOUR_GITHUB_REPO_URL>
git push -u origin main
```

## Apple Developer

Create an App ID with:

```text
com.dragos.blenfcwlc
```

Then create the corresponding app in App Store Connect.

If you want a different final Bundle ID, change it **before** registering the App ID.

## Codemagic

Configure similarly to BLE Inspector:

- Platform: iOS
- Flutter: Stable
- Xcode: current/latest supported
- Mode: Release
- Code signing: Automatic
- Provisioning profile: App Store
- Bundle ID: `com.dragos.blenfcwlc`
- App Store Connect publishing: enabled

## Build numbers

For every new TestFlight upload, increase:

```yaml
version: 0.1.0+1
```

to:

```yaml
version: 0.1.0+2
```

and so on.

## Recommended first validation on iPhone

Before spending time recreating every visual detail from Android, verify the BLE protocol on the real hardware:

1. expected device appears in scan
2. connection succeeds
3. expected custom services are discovered
4. System Status can be read
5. notifications arrive
6. NFC/card data arrives
7. polling writes are accepted
8. PSL/Q commands are accepted
9. OEM reads work
10. only after that, validate OEM writes on hardware where that is safe

The original Android application is the behavioral reference; this repository is the independent iOS implementation.
