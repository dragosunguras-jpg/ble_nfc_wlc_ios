import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:permission_handler/permission_handler.dart';

void main() => runApp(const BleNfcWlcApp());

class BleNfcWlcApp extends StatelessWidget {
  const BleNfcWlcApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'BLE NFC WLC',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF005EB8)),
      ),
      home: const ScanPage(),
    );
  }
}

// -----------------------------------------------------------------------------
// UUIDs from the original Android application
// -----------------------------------------------------------------------------
class AppUuids {
  static const batteryService = '0000180f-0000-1000-8000-00805f9b34fb';
  static const batteryLevel = '00002a19-0000-1000-8000-00805f9b34fb';

  static const statusService = '5a1f0001-7b3c-4d8e-9a21-0c4e5b6d7f80';
  static const statusChar = '5a1f0002-7b3c-4d8e-9a21-0c4e5b6d7f80';

  static const cardService = '5a1f0010-7b3c-4d8e-9a21-0c4e5b6d7f80';
  static const cardInfo = '5a1f0011-7b3c-4d8e-9a21-0c4e5b6d7f80';
  static const cardExchange = '5a1f0012-7b3c-4d8e-9a21-0c4e5b6d7f80';

  static const oemService = '5a1f0020-7b3c-4d8e-9a21-0c4e5b6d7f80';
  static const oemStatus = '5a1f0021-7b3c-4d8e-9a21-0c4e5b6d7f80';
  static const oemParams = '5a1f0022-7b3c-4d8e-9a21-0c4e5b6d7f80';
  static const oemControl = '5a1f0023-7b3c-4d8e-9a21-0c4e5b6d7f80';

  static const pslService = '5a1f0030-7b3c-4d8e-9a21-0c4e5b6d7f80';
  static const pslControl = '5a1f0031-7b3c-4d8e-9a21-0c4e5b6d7f80';
  static const pslStatus = '5a1f0032-7b3c-4d8e-9a21-0c4e5b6d7f80';
  static const pslResult = '5a1f0033-7b3c-4d8e-9a21-0c4e5b6d7f80';
  static const pslTrace = '5a1f0034-7b3c-4d8e-9a21-0c4e5b6d7f80';

  static const pollService = '5a1f0040-7b3c-4d8e-9a21-0c4e5b6d7f80';
  static const pollConfig = '5a1f0041-7b3c-4d8e-9a21-0c4e5b6d7f80';
  static const pollControl = '5a1f0042-7b3c-4d8e-9a21-0c4e5b6d7f80';
  static const pollStatus = '5a1f0043-7b3c-4d8e-9a21-0c4e5b6d7f80';
}

String normUuid(Object value) => value.toString().toLowerCase();

String hexBytes(List<int> data) =>
    data.map((e) => e.toRadixString(16).padLeft(2, '0').toUpperCase()).join(' ');

int u16(List<int> b, int i) => b[i] | (b[i + 1] << 8);
int u32(List<int> b, int i) =>
    b[i] | (b[i + 1] << 8) | (b[i + 2] << 16) | (b[i + 3] << 24);

// -----------------------------------------------------------------------------
// Protocol models ported from BleViewModel.kt
// -----------------------------------------------------------------------------
class SystemStatus {
  final bool rfFieldDetected;
  final int error;
  final int chargerStatus;
  final int ntcStatus;
  final int wlcpStatus;
  final bool powerOk;
  final int vddcMv;
  final int vdBatMv;
  final int? estCurrentMa;
  final int? estPowerMw;

  const SystemStatus({
    required this.rfFieldDetected,
    required this.error,
    required this.chargerStatus,
    required this.ntcStatus,
    required this.wlcpStatus,
    required this.powerOk,
    required this.vddcMv,
    required this.vdBatMv,
    this.estCurrentMa,
    this.estPowerMw,
  });

  bool get charging =>
      rfFieldDetected && chargerStatus >= 0x01 && chargerStatus <= 0x03;

  static SystemStatus? parse(List<int> b) {
    if (b.length < 10) return null;
    return SystemStatus(
      rfFieldDetected: b[0] != 0,
      error: b[1],
      chargerStatus: b[2],
      ntcStatus: b[3],
      wlcpStatus: b[4],
      powerOk: b[5] != 0,
      vddcMv: u16(b, 6),
      vdBatMv: u16(b, 8),
      estCurrentMa: b.length >= 14 ? u16(b, 10) : null,
      estPowerMw: b.length >= 14 ? u16(b, 12) : null,
    );
  }
}

class CardInfo {
  final bool present;
  final int tech;
  final int protocol;
  final String idHex;
  final int sak;

  const CardInfo({
    required this.present,
    required this.tech,
    required this.protocol,
    required this.idHex,
    required this.sak,
  });

  static CardInfo? parse(List<int> b) {
    if (b.length < 15) return null;
    final n = b[3].clamp(0, 10);
    final id = b
        .sublist(4, 4 + n)
        .map((x) => x.toRadixString(16).padLeft(2, '0').toUpperCase())
        .join(':');
    return CardInfo(
      present: b[0] != 0,
      tech: b[1],
      protocol: b[2],
      idHex: id,
      sak: b[14],
    );
  }
}

class CardExchange {
  final DateTime time;
  final int kind;
  final List<int> data;
  const CardExchange(this.time, this.kind, this.data);
}

class OemStatus {
  final bool chipValid;
  final bool busy;
  final bool rfField;
  final int? writeCount;
  final int maxCycles;
  final int result;
  final int badId;
  final int error;
  final int paramCount;

  const OemStatus({
    required this.chipValid,
    required this.busy,
    required this.rfField,
    required this.writeCount,
    required this.maxCycles,
    required this.result,
    required this.badId,
    required this.error,
    required this.paramCount,
  });

  static OemStatus? parse(List<int> b) {
    if (b.length < 12) return null;
    final count = u16(b, 1);
    return OemStatus(
      chipValid: (b[0] & 1) != 0,
      busy: (b[0] & 2) != 0,
      rfField: (b[0] & 4) != 0,
      writeCount: count == 0xFFFF ? null : count,
      maxCycles: u16(b, 3),
      result: b[5],
      badId: b[6],
      error: u32(b, 7),
      paramCount: b[11],
    );
  }
}

class PollSettings {
  int pollMode;
  bool typeA;
  bool typeB;
  bool typeF212;
  bool typeF424;
  bool typeV;
  bool disableIsoDep;
  bool disableNfcDep;
  bool ddpc;
  int freqA, limitA, freqB, limitB, freqF, limitF, freqV, limitV;
  int isoHbr, nfcHbr, initialTech, bailOut, lpcd;
  bool lpcdNtf;
  int idleMs;

  PollSettings({
    this.pollMode = 1,
    this.typeA = true,
    this.typeB = true,
    this.typeF212 = true,
    this.typeF424 = false,
    this.typeV = true,
    this.disableIsoDep = false,
    this.disableNfcDep = false,
    this.ddpc = false,
    this.freqA = 1,
    this.limitA = 5,
    this.freqB = 1,
    this.limitB = 5,
    this.freqF = 1,
    this.limitF = 5,
    this.freqV = 1,
    this.limitV = 5,
    this.isoHbr = 0,
    this.nfcHbr = 0,
    this.initialTech = 0,
    this.bailOut = 0,
    this.lpcd = 0,
    this.lpcdNtf = false,
    this.idleMs = 100,
  });

  List<int> encode() {
    final flags = (typeA ? 0x01 : 0) |
        (typeB ? 0x02 : 0) |
        (typeF212 ? 0x04 : 0) |
        (typeF424 ? 0x08 : 0) |
        (typeV ? 0x10 : 0) |
        (disableIsoDep ? 0x20 : 0) |
        (disableNfcDep ? 0x40 : 0) |
        (ddpc ? 0x80 : 0);
    return [
      1,
      pollMode,
      flags,
      freqA,
      limitA,
      freqB,
      limitB,
      freqF,
      limitF,
      freqV,
      limitV,
      isoHbr,
      nfcHbr,
      initialTech,
      bailOut,
      lpcd,
      lpcdNtf ? 1 : 0,
      idleMs & 0xFF,
      (idleMs >> 8) & 0xFF,
    ];
  }

  static PollSettings? parse(List<int> b) {
    if (b.length < 19 || b[0] != 1) return null;
    final f = b[2];
    return PollSettings(
      pollMode: b[1],
      typeA: (f & 0x01) != 0,
      typeB: (f & 0x02) != 0,
      typeF212: (f & 0x04) != 0,
      typeF424: (f & 0x08) != 0,
      typeV: (f & 0x10) != 0,
      disableIsoDep: (f & 0x20) != 0,
      disableNfcDep: (f & 0x40) != 0,
      ddpc: (f & 0x80) != 0,
      freqA: b[3],
      limitA: b[4],
      freqB: b[5],
      limitB: b[6],
      freqF: b[7],
      limitF: b[8],
      freqV: b[9],
      limitV: b[10],
      isoHbr: b[11],
      nfcHbr: b[12],
      initialTech: b[13],
      bailOut: b[14],
      lpcd: b[15],
      lpcdNtf: b[16] != 0,
      idleMs: u16(b, 17),
    );
  }

  PollSettings copy() => PollSettings(
        pollMode: pollMode,
        typeA: typeA,
        typeB: typeB,
        typeF212: typeF212,
        typeF424: typeF424,
        typeV: typeV,
        disableIsoDep: disableIsoDep,
        disableNfcDep: disableNfcDep,
        ddpc: ddpc,
        freqA: freqA,
        limitA: limitA,
        freqB: freqB,
        limitB: limitB,
        freqF: freqF,
        limitF: limitF,
        freqV: freqV,
        limitV: limitV,
        isoHbr: isoHbr,
        nfcHbr: nfcHbr,
        initialTech: initialTech,
        bailOut: bailOut,
        lpcd: lpcd,
        lpcdNtf: lpcdNtf,
        idleMs: idleMs,
      );
}

class PollStatus {
  final bool restarting;
  final int restarts;
  final int error;
  const PollStatus(this.restarting, this.restarts, this.error);

  static PollStatus? parse(List<int> b) {
    if (b.length < 7) return null;
    return PollStatus(b[0] != 0, u16(b, 1), u32(b, 3));
  }
}

class PslStatus {
  final int state;
  final bool continuous;
  final int sweeps;
  final int error;
  const PslStatus(this.state, this.continuous, this.sweeps, this.error);

  static PslStatus? parse(List<int> b) {
    if (b.length < 9) return null;
    return PslStatus(b[0], (b[1] & 1) != 0, u16(b, 2), u32(b, 5));
  }
}

class QResult {
  final int sweep;
  final double q;
  final int resHz;
  final int lowHz;
  final int upHz;
  const QResult(this.sweep, this.q, this.resHz, this.lowHz, this.upHz);

  static QResult? parse(List<int> b) {
    if (b.length < 18) return null;
    return QResult(
      u16(b, 0),
      u32(b, 2) / 100.0,
      u32(b, 6),
      u32(b, 10),
      u32(b, 14),
    );
  }
}

class QParams {
  int spanKhz;
  int stepKhz;
  int avgIndex;
  bool continuous;
  QParams({
    this.spanKhz = 1600,
    this.stepKhz = 5,
    this.avgIndex = 3,
    this.continuous = true,
  });

  int get startHz => 13560000 - (spanKhz * 1000 ~/ 2);
  int get stepHz => stepKhz * 1000;
  bool get valid {
    if (spanKhz < 1 || spanKhz > 5000 || stepKhz < 1 || stepKhz > 255) {
      return false;
    }
    final points = (spanKhz + stepKhz - 1) ~/ stepKhz;
    return points >= 1 && points <= 1000;
  }
}

// -----------------------------------------------------------------------------
// BLE controller
// -----------------------------------------------------------------------------
class FoundDevice {
  final String id;
  final String name;
  final int rssi;
  final Connectable connectable;
  const FoundDevice(this.id, this.name, this.rssi, this.connectable);
}

enum AppConnectionState { disconnected, connecting, connected }

class BleController extends ChangeNotifier {
  final FlutterReactiveBle ble = FlutterReactiveBle();

  final Map<String, FoundDevice> _devices = {};
  StreamSubscription<DiscoveredDevice>? _scanSub;
  StreamSubscription<ConnectionStateUpdate>? _connSub;
  final List<StreamSubscription<List<int>>> _notifySubs = [];

  List<DiscoveredService> services = [];
  AppConnectionState connectionState = AppConnectionState.disconnected;
  bool scanning = false;
  String? error;
  String? connectedId;
  String? connectedName;

  int? batteryPercent;
  final List<int> rssiHistory = [];
  Timer? _rssiTimer;

  SystemStatus? systemStatus;
  CardInfo? card;
  final List<CardExchange> exchanges = [];
  OemStatus? oemStatus;
  Map<int, int> oemParams = {};
  PollSettings? pollSettings;
  PollStatus? pollStatus;
  PslStatus? pslStatus;
  QResult? qResult;
  final List<int> qAmplitudes = [];
  final List<String> events = [];

  int _asmId = -1;
  int _asmNext = 0;
  final BytesBuilder _asm = BytesBuilder(copy: false);

  List<FoundDevice> get devices => _devices.values.toList();

  void log(String message) {
    final t = DateTime.now();
    final stamp =
        '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:${t.second.toString().padLeft(2, '0')}';
    events.insert(0, '$stamp  $message');
    if (events.length > 200) events.removeLast();
    notifyListeners();
  }

  Future<bool> requestPermissions() async {
    if (Platform.isIOS) return true;
    if (!Platform.isAndroid) return false;

    final statuses = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
    ].request();

    return (statuses[Permission.bluetoothScan]?.isGranted ?? false) &&
        (statuses[Permission.bluetoothConnect]?.isGranted ?? false);
  }

  Future<void> startScan() async {
    if (!await requestPermissions()) {
      error = 'Bluetooth permissions not granted.';
      notifyListeners();
      return;
    }
    await stopScan();
    _devices.clear();
    scanning = true;
    error = null;
    notifyListeners();

    _scanSub = ble
        .scanForDevices(withServices: [], scanMode: ScanMode.lowLatency)
        .listen((d) {
      final name = d.name.trim().isEmpty ? 'Unnamed BLE Device' : d.name.trim();
      _devices[d.id] = FoundDevice(d.id, name, d.rssi, d.connectable);
      notifyListeners();
    }, onError: (Object e) {
      scanning = false;
      error = e.toString();
      notifyListeners();
    });
  }

  Future<void> stopScan() async {
    await _scanSub?.cancel();
    _scanSub = null;
    scanning = false;
    notifyListeners();
  }

  Future<void> connect(FoundDevice device) async {
    await stopScan();
    await disconnect();

    connectionState = AppConnectionState.connecting;
    connectedId = device.id;
    connectedName = device.name;
    error = null;
    log('Connecting to ${device.name} (${device.id})');

    _connSub = ble
        .connectToDevice(
      id: device.id,
      connectionTimeout: const Duration(seconds: 15),
    )
        .listen((update) async {
      if (update.connectionState == DeviceConnectionState.connected) {
        connectionState = AppConnectionState.connected;
        log('Connected');
        await _discoverAndSubscribe();
        _startRssi();
      } else if (update.connectionState ==
          DeviceConnectionState.disconnected) {
        connectionState = AppConnectionState.disconnected;
        log('Disconnected');
        _stopRssi();
      } else if (update.connectionState ==
          DeviceConnectionState.connecting) {
        connectionState = AppConnectionState.connecting;
      }
      notifyListeners();
    }, onError: (Object e) {
      error = 'Connection failed: $e';
      connectionState = AppConnectionState.disconnected;
      log(error!);
    });
  }

  Future<void> disconnect() async {
    _stopRssi();
    for (final s in _notifySubs) {
      await s.cancel();
    }
    _notifySubs.clear();
    await _connSub?.cancel();
    _connSub = null;
    connectionState = AppConnectionState.disconnected;
    services = [];
    connectedId = null;
    connectedName = null;
    notifyListeners();
  }

  void _startRssi() {
    _rssiTimer?.cancel();
    _rssiTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
      final id = connectedId;
      if (id == null || connectionState != AppConnectionState.connected) return;
      try {
        final rssi = await ble.readRssi(id);
        rssiHistory.add(rssi);
        if (rssiHistory.length > 120) rssiHistory.removeAt(0);
        notifyListeners();
      } catch (_) {}
    });
  }

  void _stopRssi() {
    _rssiTimer?.cancel();
    _rssiTimer = null;
  }

  DiscoveredCharacteristic? _findChar(String serviceUuid, String charUuid) {
    final s = services.where((s) => normUuid(s.serviceId) == serviceUuid).toList();
    if (s.isEmpty) return null;
    final c = s.first.characteristics
        .where((c) => normUuid(c.characteristicId) == charUuid)
        .toList();
    return c.isEmpty ? null : c.first;
  }

  QualifiedCharacteristic? _qualified(String serviceUuid, String charUuid) {
    final id = connectedId;
    final c = _findChar(serviceUuid, charUuid);
    if (id == null || c == null) return null;
    return QualifiedCharacteristic(
      deviceId: id,
      serviceId: Uuid.parse(serviceUuid),
      characteristicId: c.characteristicId,
    );
  }

  Future<List<int>?> _read(String serviceUuid, String charUuid) async {
    final q = _qualified(serviceUuid, charUuid);
    if (q == null) return null;
    try {
      return await ble.readCharacteristic(q);
    } catch (e) {
      log('Read failed $charUuid: $e');
      return null;
    }
  }

  Future<bool> _write(String serviceUuid, String charUuid, List<int> value) async {
    final q = _qualified(serviceUuid, charUuid);
    if (q == null) return false;
    try {
      await ble.writeCharacteristicWithResponse(q, value: value);
      return true;
    } catch (e) {
      log('Write failed $charUuid: $e');
      return false;
    }
  }

  void _subscribe(String serviceUuid, String charUuid,
      void Function(List<int>) onData) {
    final q = _qualified(serviceUuid, charUuid);
    final c = _findChar(serviceUuid, charUuid);
    if (q == null || c == null || (!c.isNotifiable && !c.isIndicatable)) return;

    final sub = ble.subscribeToCharacteristic(q).listen(onData,
        onError: (Object e) => log('Notify failed $charUuid: $e'));
    _notifySubs.add(sub);
  }

  Future<void> _discoverAndSubscribe() async {
    final id = connectedId;
    if (id == null) return;
    try {
      services = await ble.discoverServices(id);
      log('GATT discovery: ${services.length} services');

      // Initial reads
      final battery = await _read(AppUuids.batteryService, AppUuids.batteryLevel);
      if (battery != null) _handleBattery(battery);

      final status = await _read(AppUuids.statusService, AppUuids.statusChar);
      if (status != null) _handleStatus(status);

      final ci = await _read(AppUuids.cardService, AppUuids.cardInfo);
      if (ci != null) _handleCard(ci);

      final os = await _read(AppUuids.oemService, AppUuids.oemStatus);
      if (os != null) _handleOemStatus(os);

      final op = await _read(AppUuids.oemService, AppUuids.oemParams);
      if (op != null) _handleOemParams(op);

      final pc = await _read(AppUuids.pollService, AppUuids.pollConfig);
      if (pc != null) {
        pollSettings = PollSettings.parse(pc);
      }

      final ps = await _read(AppUuids.pollService, AppUuids.pollStatus);
      if (ps != null) pollStatus = PollStatus.parse(ps);

      final pss = await _read(AppUuids.pslService, AppUuids.pslStatus);
      if (pss != null) pslStatus = PslStatus.parse(pss);

      // Notifications
      _subscribe(AppUuids.batteryService, AppUuids.batteryLevel, _handleBattery);
      _subscribe(AppUuids.statusService, AppUuids.statusChar, _handleStatus);
      _subscribe(AppUuids.cardService, AppUuids.cardInfo, _handleCard);
      _subscribe(
          AppUuids.cardService, AppUuids.cardExchange, _handleCardExchange);
      _subscribe(AppUuids.oemService, AppUuids.oemStatus, _handleOemStatus);
      _subscribe(AppUuids.oemService, AppUuids.oemParams, _handleOemParams);
      _subscribe(AppUuids.pollService, AppUuids.pollConfig, (b) {
        pollSettings = PollSettings.parse(b);
        notifyListeners();
      });
      _subscribe(AppUuids.pollService, AppUuids.pollStatus, (b) {
        pollStatus = PollStatus.parse(b);
        notifyListeners();
      });
      _subscribe(AppUuids.pslService, AppUuids.pslStatus, (b) {
        pslStatus = PslStatus.parse(b);
        notifyListeners();
      });
      _subscribe(AppUuids.pslService, AppUuids.pslResult, (b) {
        qResult = QResult.parse(b);
        notifyListeners();
      });
      _subscribe(AppUuids.pslService, AppUuids.pslTrace, _handlePslTrace);

      notifyListeners();
    } catch (e) {
      error = 'Service discovery failed: $e';
      log(error!);
    }
  }

  void _handleBattery(List<int> b) {
    if (b.isEmpty) return;
    batteryPercent = b.first.clamp(0, 100);
    notifyListeners();
  }

  void _handleStatus(List<int> b) {
    systemStatus = SystemStatus.parse(b);
    notifyListeners();
  }

  void _handleCard(List<int> b) {
    card = CardInfo.parse(b);
    notifyListeners();
  }

  void _handleOemStatus(List<int> b) {
    oemStatus = OemStatus.parse(b);
    notifyListeners();
  }

  void _handleOemParams(List<int> b) {
    final result = <int, int>{};
    for (var i = 0; i + 2 < b.length; i += 3) {
      result[b[i]] = b[i + 1] | (b[i + 2] << 8);
    }
    oemParams = result;
    notifyListeners();
  }

  void _handleCardExchange(List<int> b) {
    if (b.length < 4) return;
    final id = b[0];
    final kind = b[1];
    final idx = b[2];
    final total = b[3];

    if (idx == 0) {
      _asm.clear();
      _asmId = id;
      _asmNext = 0;
    }
    if (id != _asmId || idx != _asmNext) {
      _asmId = -1;
      _asm.clear();
      return;
    }

    _asm.add(b.sublist(4));
    _asmNext++;
    if (idx == total - 1) {
      final data = _asm.takeBytes();
      exchanges.insert(0, CardExchange(DateTime.now(), kind, data));
      if (exchanges.length > 50) exchanges.removeLast();
      _asmId = -1;
      notifyListeners();
    }
  }

  void _handlePslTrace(List<int> b) {
    if (b.length < 6) return;
    final first = u16(b, 2);
    final count = (b.length - 4) ~/ 2;
    if (first == 0) qAmplitudes.clear();
    if (first != qAmplitudes.length) return;
    for (var i = 0; i < count; i++) {
      qAmplitudes.add(u16(b, 4 + 2 * i));
    }
    notifyListeners();
  }

  Future<void> applyPolling(PollSettings settings) async {
    final ok =
        await _write(AppUuids.pollService, AppUuids.pollConfig, settings.encode());
    if (!ok) return;
    if (await _write(AppUuids.pollService, AppUuids.pollControl, [1])) {
      log('Polling settings sent; reader restart requested.');
    }
  }

  Future<void> restorePollingDefaults() async {
    if (await _write(AppUuids.pollService, AppUuids.pollControl, [2])) {
      log('Polling defaults requested.');
    }
  }

  Future<void> startQ(QParams p) async {
    if (!p.valid) {
      error = 'Invalid Q measurement parameters.';
      notifyListeners();
      return;
    }
    qAmplitudes.clear();
    qResult = null;
    final cmd = [
      1,
      p.spanKhz & 0xFF,
      (p.spanKhz >> 8) & 0xFF,
      p.stepKhz & 0xFF,
      p.avgIndex & 0xFF,
      p.continuous ? 1 : 0,
    ];
    if (await _write(AppUuids.pslService, AppUuids.pslControl, cmd)) {
      log('Q measurement started.');
    }
  }

  Future<void> stopQ() async {
    if (await _write(AppUuids.pslService, AppUuids.pslControl, [2])) {
      log('Q measurement stop requested.');
    }
  }

  Future<void> uploadOemRaw(Map<int, int> values) async {
    final status = oemStatus;
    if (status?.rfField == true) {
      error = 'OEM write blocked: RF field is present.';
      notifyListeners();
      return;
    }
    final ids = values.keys.toList()..sort();
    final entries = <List<int>>[];
    for (final id in ids) {
      final v = values[id]!;
      entries.add([id, v & 0xFF, (v >> 8) & 0xFF]);
    }

    for (var i = 0; i < entries.length; i += 6) {
      final chunk = <int>[];
      for (final e in entries.skip(i).take(6)) {
        chunk.addAll(e);
      }
      final ok = await _write(AppUuids.oemService, AppUuids.oemParams, chunk);
      if (!ok) return;
    }

    // Same commit command as the original Android application.
    final committed = await _write(
      AppUuids.oemService,
      AppUuids.oemControl,
      [0x02, 0x01, 0xA5, 0x5A],
    );
    if (committed) log('OEM parameter commit sent.');
  }

  @override
  void dispose() {
    _scanSub?.cancel();
    _connSub?.cancel();
    for (final s in _notifySubs) {
      s.cancel();
    }
    _rssiTimer?.cancel();
    super.dispose();
  }
}

// -----------------------------------------------------------------------------
// Scan page
// -----------------------------------------------------------------------------
class ScanPage extends StatefulWidget {
  const ScanPage({super.key});

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  late final BleController controller;

  @override
  void initState() {
    super.initState();
    controller = BleController()..addListener(_refresh);
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    controller.removeListener(_refresh);
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final devices = controller.devices;

    return Scaffold(
      appBar: AppBar(title: const Text('BLE NFC WLC')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: controller.scanning ? null : controller.startScan,
                    icon: const Icon(Icons.bluetooth_searching),
                    label: const Text('Start scan'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: controller.scanning ? controller.stopScan : null,
                    icon: const Icon(Icons.stop),
                    label: const Text('Stop'),
                  ),
                ),
              ],
            ),
          ),
          if (controller.scanning) const LinearProgressIndicator(),
          if (controller.error != null)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                controller.error!,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          Expanded(
            child: devices.isEmpty
                ? const Center(child: Text('No BLE devices found'))
                : ListView.separated(
                    itemCount: devices.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final d = devices[i];
                      return ListTile(
                        leading: const Icon(Icons.bluetooth),
                        title: Text(d.name),
                        subtitle: Text('${d.id}\nRSSI ${d.rssi} dBm'),
                        isThreeLine: true,
                        trailing: d.connectable == Connectable.unavailable
                            ? const Icon(Icons.block)
                            : const Icon(Icons.chevron_right),
                        onTap: () async {
                          await controller.connect(d);
                          if (!context.mounted) return;
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  DevicePage(controller: controller),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Connected device UI
// -----------------------------------------------------------------------------
class DevicePage extends StatefulWidget {
  final BleController controller;
  const DevicePage({super.key, required this.controller});

  @override
  State<DevicePage> createState() => _DevicePageState();
}

class _DevicePageState extends State<DevicePage> {
  int tab = 0;

  BleController get c => widget.controller;

  @override
  void initState() {
    super.initState();
    c.addListener(_refresh);
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    c.removeListener(_refresh);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screens = <Widget>[
      OverviewTab(c),
      WlcTab(c),
      NfcTab(c),
      PollingTab(c),
      PslTab(c),
      OemTab(c),
      BleDiagnosticsTab(c),
    ];
    final labels = ['Overview', 'WLC', 'NFC', 'Polling', 'PSL', 'OEM', 'BLE'];

    return Scaffold(
      appBar: AppBar(
        title: Text(c.connectedName ?? 'Device'),
        actions: [
          IconButton(
            tooltip: 'Disconnect',
            onPressed: () async {
              await c.disconnect();
              if (context.mounted) Navigator.of(context).pop();
            },
            icon: const Icon(Icons.link_off),
          ),
        ],
      ),
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: tab,
            onDestinationSelected: (i) => setState(() => tab = i),
            labelType: NavigationRailLabelType.all,
            destinations: [
              for (final label in labels)
                NavigationRailDestination(
                  icon: const Icon(Icons.circle_outlined),
                  selectedIcon: const Icon(Icons.circle),
                  label: Text(label),
                ),
            ],
          ),
          const VerticalDivider(width: 1),
          Expanded(child: screens[tab]),
        ],
      ),
    );
  }
}

Widget section(String title, List<Widget> children) => Card(
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );

Widget kv(String key, Object? value) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 145, child: Text(key)),
          Expanded(child: SelectableText(value?.toString() ?? '-')),
        ],
      ),
    );

class OverviewTab extends StatelessWidget {
  final BleController c;
  const OverviewTab(this.c, {super.key});

  @override
  Widget build(BuildContext context) {
    final s = c.systemStatus;
    return ListView(
      children: [
        section('Connection', [
          kv('State', c.connectionState.name),
          kv('Device', c.connectedName),
          kv('ID', c.connectedId),
          kv('Battery', c.batteryPercent == null ? '-' : '${c.batteryPercent}%'),
          kv('Services', c.services.length),
        ]),
        if (s != null)
          section('System status', [
            kv('RF field', s.rfFieldDetected),
            kv('Charging', s.charging),
            kv('Charger state', '0x${s.chargerStatus.toRadixString(16)}'),
            kv('WLC status', '0x${s.wlcpStatus.toRadixString(16)}'),
            kv('Power OK', s.powerOk),
            kv('VDDC', '${s.vddcMv} mV'),
            kv('VDBAT', '${s.vdBatMv} mV'),
            kv('Estimated current', s.estCurrentMa == null ? '-' : '${s.estCurrentMa} mA'),
            kv('Estimated power', s.estPowerMw == null ? '-' : '${s.estPowerMw} mW'),
            kv('Error', '0x${s.error.toRadixString(16).padLeft(2, '0')}'),
          ]),
        section('Events', [
          Row(
            children: [
              OutlinedButton(
                onPressed: c.events.isEmpty ? null : () {
                  c.events.clear();
                  c.notifyListeners();
                },
                child: const Text('Clear'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (final e in c.events.take(50))
            Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: SelectableText(e,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
            ),
        ]),
      ],
    );
  }
}

class WlcTab extends StatelessWidget {
  final BleController c;
  const WlcTab(this.c, {super.key});

  @override
  Widget build(BuildContext context) {
    final s = c.systemStatus;
    return ListView(
      children: [
        section('Wireless power / battery', [
          kv('Battery', c.batteryPercent == null ? '-' : '${c.batteryPercent}%'),
          kv('RF field', s?.rfFieldDetected),
          kv('Charging', s?.charging),
          kv('VDDC', s == null ? '-' : '${s.vddcMv} mV'),
          kv('VDBAT', s == null ? '-' : '${s.vdBatMv} mV'),
          kv('NTC status', s?.ntcStatus),
          kv('WLCP status', s?.wlcpStatus),
          kv('Estimated current',
              s?.estCurrentMa == null ? '-' : '${s!.estCurrentMa} mA'),
          kv('Estimated power',
              s?.estPowerMw == null ? '-' : '${s!.estPowerMw} mW'),
        ]),
      ],
    );
  }
}

String techName(int t) => switch (t) {
      0 => 'NFC-A (ISO 14443-A)',
      1 => 'NFC-B (ISO 14443-B)',
      2 => 'NFC-F (FeliCa)',
      3 => 'NFC-V (ISO 15693)',
      4 => 'ACM / P2P',
      _ => 'Unknown ($t)',
    };

String protocolName(int p) => switch (p) {
      2 => 'Type 2 Tag (T2T)',
      3 => 'Type 3 Tag (T3T)',
      4 => 'Type 4 Tag (T4T / ISO-DEP)',
      5 => 'Type 5 Tag (T5T)',
      6 => 'NFC-DEP',
      0 => 'Undefined',
      _ => 'Unknown ($p)',
    };

class NfcTab extends StatelessWidget {
  final BleController c;
  const NfcTab(this.c, {super.key});

  @override
  Widget build(BuildContext context) {
    final card = c.card;
    return ListView(
      children: [
        section('Card reader', [
          kv('Present', card?.present),
          kv('Technology', card == null ? '-' : techName(card.tech)),
          kv('Protocol', card == null ? '-' : protocolName(card.protocol)),
          kv('ID', card?.idHex),
          if (card?.tech == 0)
            kv('SAK', '0x${card!.sak.toRadixString(16).padLeft(2, '0')}'),
        ]),
        section('Data exchange', [
          if (c.exchanges.isEmpty) const Text('Nothing exchanged yet.'),
          for (final ex in c.exchanges)
            ListTile(
              dense: true,
              title: Text('Kind ${ex.kind} â€¢ ${ex.time.toLocal()}'),
              subtitle: SelectableText(hexBytes(ex.data)),
            ),
        ]),
      ],
    );
  }
}

class PollingTab extends StatefulWidget {
  final BleController c;
  const PollingTab(this.c, {super.key});

  @override
  State<PollingTab> createState() => _PollingTabState();
}

class _PollingTabState extends State<PollingTab> {
  PollSettings? draft;

  @override
  Widget build(BuildContext context) {
    final c = widget.c;
    final active = c.pollSettings;
    draft ??= active?.copy() ?? PollSettings();
    final d = draft!;

    return ListView(
      children: [
        section('Polling / discovery loop', [
          kv('Reader restarting', c.pollStatus?.restarting),
          kv('Restart count', c.pollStatus?.restarts),
          kv('Last error', c.pollStatus?.error),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('NFC-A'),
            value: d.typeA,
            onChanged: (v) => setState(() => d.typeA = v),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('NFC-B'),
            value: d.typeB,
            onChanged: (v) => setState(() => d.typeB = v),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('NFC-F 212'),
            value: d.typeF212,
            onChanged: (v) => setState(() => d.typeF212 = v),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('NFC-F 424'),
            value: d.typeF424,
            onChanged: (v) => setState(() => d.typeF424 = v),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('NFC-V'),
            value: d.typeV,
            onChanged: (v) => setState(() => d.typeV = v),
          ),
          TextFormField(
            initialValue: d.idleMs.toString(),
            decoration: const InputDecoration(labelText: 'Idle time (ms)'),
            keyboardType: TextInputType.number,
            onChanged: (v) => d.idleMs = int.tryParse(v) ?? d.idleMs,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              FilledButton(
                onPressed: () => c.applyPolling(d),
                child: const Text('Apply + restart'),
              ),
              OutlinedButton(
                onPressed: c.restorePollingDefaults,
                child: const Text('Restore defaults'),
              ),
              TextButton(
                onPressed: () => setState(() {
                  draft = c.pollSettings?.copy() ?? PollSettings();
                }),
                child: const Text('Revert edits'),
              ),
            ],
          ),
        ]),
      ],
    );
  }
}

class PslTab extends StatefulWidget {
  final BleController c;
  const PslTab(this.c, {super.key});

  @override
  State<PslTab> createState() => _PslTabState();
}

class _PslTabState extends State<PslTab> {
  final params = QParams();

  @override
  Widget build(BuildContext context) {
    final c = widget.c;
    return ListView(
      children: [
        section('Antenna Q measurement', [
          kv('State', c.pslStatus?.state),
          kv('Continuous', c.pslStatus?.continuous),
          kv('Sweeps', c.pslStatus?.sweeps),
          kv('Error', c.pslStatus?.error),
          TextFormField(
            initialValue: params.spanKhz.toString(),
            decoration: const InputDecoration(labelText: 'Span (kHz)'),
            keyboardType: TextInputType.number,
            onChanged: (v) => params.spanKhz = int.tryParse(v) ?? params.spanKhz,
          ),
          TextFormField(
            initialValue: params.stepKhz.toString(),
            decoration: const InputDecoration(labelText: 'Step (kHz)'),
            keyboardType: TextInputType.number,
            onChanged: (v) => params.stepKhz = int.tryParse(v) ?? params.stepKhz,
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Continuous'),
            value: params.continuous,
            onChanged: (v) => setState(() => params.continuous = v),
          ),
          Wrap(
            spacing: 8,
            children: [
              FilledButton(
                  onPressed: () => c.startQ(params), child: const Text('Start')),
              OutlinedButton(onPressed: c.stopQ, child: const Text('Stop')),
            ],
          ),
          if (c.qResult != null) ...[
            const Divider(),
            kv('Q', c.qResult!.q.toStringAsFixed(2)),
            kv('Resonance',
                '${(c.qResult!.resHz / 1000000).toStringAsFixed(3)} MHz'),
            kv('Lower', '${c.qResult!.lowHz} Hz'),
            kv('Upper', '${c.qResult!.upHz} Hz'),
          ],
          kv('Trace points', c.qAmplitudes.length),
        ]),
      ],
    );
  }
}

class OemTab extends StatefulWidget {
  final BleController c;
  const OemTab(this.c, {super.key});

  @override
  State<OemTab> createState() => _OemTabState();
}

class _OemTabState extends State<OemTab> {
  final edits = <int, int>{};

  @override
  Widget build(BuildContext context) {
    final c = widget.c;
    final status = c.oemStatus;
    final ids = c.oemParams.keys.toList()..sort();

    return ListView(
      children: [
        section('OEM status', [
          kv('Chip valid', status?.chipValid),
          kv('Busy', status?.busy),
          kv('RF field', status?.rfField),
          kv('Write count', status?.writeCount),
          kv('Max cycles', status?.maxCycles),
          kv('Result', status?.result),
          kv('Bad parameter ID', status?.badId),
          kv('Error', status?.error),
          const SizedBox(height: 8),
          const Text(
            'This first iOS port exposes the same raw OEM IDs/values. '
            'The Android catalog labels and dependency rules can be ported next.',
          ),
        ]),
        section('OEM parameters', [
          if (ids.isEmpty) const Text('Parameters not loaded yet.'),
          for (final id in ids)
            Row(
              children: [
                SizedBox(width: 70, child: Text('ID $id')),
                Expanded(
                  child: TextFormField(
                    initialValue: c.oemParams[id].toString(),
                    keyboardType: TextInputType.number,
                    onChanged: (v) {
                      final parsed = int.tryParse(v);
                      if (parsed != null) edits[id] = parsed;
                    },
                  ),
                ),
              ],
            ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: ids.isEmpty
                ? null
                : () {
                    final values = Map<int, int>.from(c.oemParams);
                    values.addAll(edits);
                    c.uploadOemRaw(values);
                  },
            icon: const Icon(Icons.upload),
            label: const Text('Upload raw OEM set'),
          ),
          const SizedBox(height: 8),
          const Text(
            'Warning: OEM writes consume NVM cycles. Verify values before upload.',
            style: TextStyle(color: Colors.orange),
          ),
        ]),
      ],
    );
  }
}

class BleDiagnosticsTab extends StatelessWidget {
  final BleController c;
  const BleDiagnosticsTab(this.c, {super.key});

  @override
  Widget build(BuildContext context) {
    final current = c.rssiHistory.isEmpty ? null : c.rssiHistory.last;
    return ListView(
      children: [
        section('BLE diagnostics', [
          kv('RSSI', current == null ? '-' : '$current dBm'),
          kv('Samples', c.rssiHistory.length),
          kv('Service count', c.services.length),
          const SizedBox(height: 8),
          for (final s in c.services)
            ExpansionTile(
              title: Text(normUuid(s.serviceId)),
              children: [
                for (final ch in s.characteristics)
                  ListTile(
                    dense: true,
                    title: SelectableText(normUuid(ch.characteristicId)),
                    subtitle: Text([
                      if (ch.isReadable) 'READ',
                      if (ch.isWritableWithResponse) 'WRITE',
                      if (ch.isWritableWithoutResponse) 'WRITE_NR',
                      if (ch.isNotifiable) 'NOTIFY',
                      if (ch.isIndicatable) 'INDICATE',
                    ].join(' | ')),
                  ),
              ],
            ),
        ]),
      ],
    );
  }
}

