import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

import 'oem_catalog.dart';

void main() => runApp(const BleNfcWlcApp());

const renesasBlue = Color(0xFF2A289B);
const appBackground = Color(0xFFF3F7FD);
const surfaceVariant = Color(0xFFE6ECF7);
const riseColor = Color(0xFF2E9F54);
const fallColor = Color(0xFFC62828);
const traceColor = Color(0xFF2A7B91);
const markColor = Color(0xFF29C35A);

class BleNfcWlcApp extends StatelessWidget {
  const BleNfcWlcApp({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = ColorScheme.fromSeed(
      seedColor: renesasBlue,
      brightness: Brightness.light,
      surface: appBackground,
    ).copyWith(
      primary: renesasBlue,
      onPrimary: Colors.white,
      primaryContainer: const Color(0xFFDDE1FF),
      onPrimaryContainer: const Color(0xFF0A0A5C),
      secondary: const Color(0xFF4A5A7A),
      secondaryContainer: const Color(0xFFDCE5F8),
      onSecondaryContainer: const Color(0xFF14264F),
      surface: appBackground,
      onSurface: const Color(0xFF161B27),
      surfaceContainerHighest: const Color(0xFFDBE4F5),
      outline: const Color(0xFF7B879E),
      outlineVariant: const Color(0xFFC5CEDF),
    );
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'BLE NFC WLC',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: scheme,
        scaffoldBackgroundColor: appBackground,
        fontFamily: '.SF Pro Text',
      ),
      home: const BleRootPage(),
    );
  }
}

// =============================================================================
// BLE protocol
// =============================================================================

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

String canonicalBleUuid(Object value) {
  var u = value.toString().toLowerCase().trim();
  u = u.replaceAll('{', '').replaceAll('}', '');

  // CoreBluetooth may expose SIG UUIDs as 16-bit (180f / 2a19),
  // 32-bit (0000180f / 00002a19), or the full Bluetooth base UUID.
  if (RegExp(r'^[0-9a-f]{4}$').hasMatch(u)) {
    return '0000$u-0000-1000-8000-00805f9b34fb';
  }
  if (RegExp(r'^[0-9a-f]{8}$').hasMatch(u)) {
    return '$u-0000-1000-8000-00805f9b34fb';
  }
  return u;
}

bool sameBleUuid(Object a, Object b) =>
    canonicalBleUuid(a) == canonicalBleUuid(b);
int u16(List<int> b, int i) => b[i] | (b[i + 1] << 8);
int u32(List<int> b, int i) => b[i] | (b[i + 1] << 8) | (b[i + 2] << 16) | (b[i + 3] << 24);
String hexBytes(List<int> data, {int max = 128}) => data.take(max).map((e) => e.toRadixString(16).padLeft(2, '0').toUpperCase()).join(' ');

class BatterySample {
  final DateTime time;
  final int percent;
  const BatterySample(this.time, this.percent);
}

class StatusSample {
  final DateTime time;
  final SystemStatus status;
  const StatusSample(this.time, this.status);
}


class EstimatedLevel {
  final DateTime time;
  final double percent;
  final bool disturbed;
  const EstimatedLevel(this.time, this.percent, this.disturbed);
}

class BatteryEstimator {
  static const int spikeMv = 150;
  static const int baselineSamples = 15;
  static const int settleSamples = 2;
  static const double rIntOhm = 0.15;
  static const double smoothing = 0.25;

  static const int etaWindowMs = 3 * 60 * 1000;
  static const int etaMinSpanMs = 30 * 1000;
  static const double minRatePctPerMin = 0.02;
  static const double defaultCcPctPerMin = 1.0;
  static const double defaultCvStartPct = 90.0;
  static const double trickleEndPct = 5.0;
  static const double trickleRateFraction = 0.2;
  static const double fullPct = 99.0;

  static const List<(int, double)> ocv = [
    (3270, 0), (3610, 5), (3690, 10), (3710, 15), (3730, 20),
    (3750, 25), (3770, 30), (3790, 35), (3800, 40), (3820, 45),
    (3840, 50), (3850, 55), (3870, 60), (3910, 65), (3950, 70),
    (3980, 75), (4020, 80), (4080, 85), (4110, 90), (4150, 95),
    (4200, 100),
  ];

  static double levelFromOcv(double mv) {
    if (mv <= ocv.first.$1) return 0;
    if (mv >= ocv.last.$1) return 100;
    for (var i = 1; i < ocv.length; i++) {
      final (v1, p1) = ocv[i];
      if (mv <= v1) {
        final (v0, p0) = ocv[i - 1];
        return p0 + (p1 - p0) * (mv - v0) / (v1 - v0);
      }
    }
    return 100;
  }

  static List<EstimatedLevel> estimate(List<StatusSample> history) {
    final out = <EstimatedLevel>[];
    final vddcWindow = <int>[];
    var settle = 0;
    double? goodMv;
    double? level;

    for (final sample in history) {
      final s = sample.status;
      final baseline = vddcWindow.length >= 3
          ? ([...vddcWindow]..sort())[vddcWindow.length ~/ 2]
          : s.vddcMv;

      if (s.vddcMv - baseline > spikeMv) settle = settleSamples + 1;
      final disturbed = settle > 0;
      if (disturbed) settle--;

      vddcWindow.add(s.vddcMv);
      if (vddcWindow.length > baselineSamples) vddcWindow.removeAt(0);

      if (!disturbed || goodMv == null) {
        final ir = s.charging ? (s.estCurrentMa ?? 0) * rIntOhm : 0.0;
        goodMv = s.vdBatMv - ir;
      }

      final raw = levelFromOcv(goodMv);
      var next = level == null ? raw : level + (raw - level) * smoothing;
      if (level != null) {
        next = s.charging ? math.max(next, level) : math.min(next, level);
      }
      level = next;
      out.add(EstimatedLevel(sample.time, next, disturbed));
    }
    return out;
  }

  static Duration? etaToFull(
      List<StatusSample> history, List<EstimatedLevel> est) {
    if (history.isEmpty || history.length != est.length) return null;
    final lastIdx = history.length - 1;
    final last = history[lastIdx].status;
    if (!last.charging) return null;

    final level = est[lastIdx].percent;
    if (level >= fullPct) return Duration.zero;
    final phase = last.chargerStatus;

    var session = lastIdx;
    while (session > 0 && history[session - 1].status.charging) {
      session--;
    }

    var from = lastIdx;
    while (from > session &&
        history[from - 1].status.chargerStatus == phase &&
        history[lastIdx]
                .time
                .difference(history[from - 1].time)
                .inMilliseconds <=
            etaWindowMs) {
      from--;
    }

    final spanMs =
        history[lastIdx].time.difference(history[from].time).inMilliseconds;
    final measured = spanMs >= etaMinSpanMs
        ? (level - est[from].percent) / (spanMs / 60000.0)
        : 0.0;
    final slope = measured > minRatePctPerMin ? measured : null;

    int? cvIdx;
    for (var i = session; i <= lastIdx; i++) {
      if (history[i].status.chargerStatus == 3) {
        cvIdx = i;
        break;
      }
    }

    final cvStart =
        (cvIdx == null ? defaultCvStartPct : est[cvIdx].percent)
            .clamp(50.0, 98.0);

    double cvMin(double l, double k) =>
        math.log((100.0 - l) / (100.0 - fullPct)) / k;

    final ccRate =
        phase == 2 ? (slope ?? defaultCcPctPerMin) : defaultCcPctPerMin;
    final k0 = ccRate / (100.0 - cvStart);

    late final double minutes;
    if (phase == 3) {
      final k = slope == null ? k0 : slope / (100.0 - level);
      minutes = cvMin(level, k);
    } else if (phase == 2) {
      minutes = level >= cvStart
          ? cvMin(level, k0)
          : (cvStart - level) / ccRate + cvMin(cvStart, k0);
    } else {
      final trickle =
          math.max(0.0, trickleEndPct - level) /
              (defaultCcPctPerMin * trickleRateFraction);
      final from2 = math.max(level, trickleEndPct);
      minutes =
          trickle + (cvStart - from2) / ccRate + cvMin(cvStart, k0);
    }

    return Duration(
      milliseconds: (math.max(0.0, minutes) * 60000).round(),
    );
  }
}

String formatEta(Duration d) {
  final min = (d.inMilliseconds / 60000.0).round();
  if (min < 1) return '<1 min';
  if (min < 60) return '~$min min';
  return '~${min ~/ 60} h ${(min % 60).toString().padLeft(2, '0')} min';
}

String shortPhaseName(int kind) => switch (kind) {
      1 => 'Trickle',
      2 => 'CC',
      3 => 'CV',
      4 => 'Done',
      _ => '',
    };

class RssiSample {
  final DateTime time;
  final int raw;
  final double filtered;
  const RssiSample(this.time, this.raw, this.filtered);
}

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

  bool get charging => rfFieldDetected && chargerStatus >= 1 && chargerStatus <= 3;

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
  const CardInfo(this.present, this.tech, this.protocol, this.idHex, this.sak);

  static CardInfo? parse(List<int> b) {
    if (b.length < 15) return null;
    final n = math.min(b[3], 10);
    final id = b.sublist(4, 4 + n).map((x) => x.toRadixString(16).padLeft(2, '0').toUpperCase()).join(':');
    return CardInfo(b[0] != 0, b[1], b[2], id, b[14]);
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
  const OemStatus(this.chipValid, this.busy, this.rfField, this.writeCount, this.maxCycles, this.result, this.badId, this.error, this.paramCount);

  static OemStatus? parse(List<int> b) {
    if (b.length < 12) return null;
    final count = u16(b, 1);
    return OemStatus(
      (b[0] & 1) != 0,
      (b[0] & 2) != 0,
      (b[0] & 4) != 0,
      count == 0xFFFF ? null : count,
      u16(b, 3),
      b[5],
      b[6],
      u32(b, 7),
      b[11],
    );
  }
}

class PollSettings {
  int pollMode;
  bool typeA, typeB, typeF212, typeF424, typeV;
  bool disableIsoDep, disableNfcDep, ddpc;
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

  bool sameAs(PollSettings? o) {
    if (o == null) return false;
    return encode().join(',') == o.encode().join(',');
  }

  List<int> encode() {
    final flags = (typeA ? 0x01 : 0) |
        (typeB ? 0x02 : 0) |
        (typeF212 ? 0x04 : 0) |
        (typeF424 ? 0x08 : 0) |
        (typeV ? 0x10 : 0) |
        (disableIsoDep ? 0x20 : 0) |
        (disableNfcDep ? 0x40 : 0) |
        (ddpc ? 0x80 : 0);
    return [1, pollMode, flags, freqA, limitA, freqB, limitB, freqF, limitF, freqV, limitV, isoHbr, nfcHbr, initialTech, bailOut, lpcd, lpcdNtf ? 1 : 0, idleMs & 0xFF, (idleMs >> 8) & 0xFF];
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
      freqA: b[3], limitA: b[4], freqB: b[5], limitB: b[6], freqF: b[7], limitF: b[8], freqV: b[9], limitV: b[10],
      isoHbr: b[11], nfcHbr: b[12], initialTech: b[13], bailOut: b[14], lpcd: b[15], lpcdNtf: b[16] != 0, idleMs: u16(b, 17),
    );
  }
}

class PollStatus {
  final bool restarting;
  final int restarts;
  final int error;
  const PollStatus(this.restarting, this.restarts, this.error);
  static PollStatus? parse(List<int> b) => b.length < 7 ? null : PollStatus(b[0] != 0, u16(b, 1), u32(b, 3));
}

class PslStatus {
  final int state;
  final bool continuous;
  final int sweeps;
  final int error;
  const PslStatus(this.state, this.continuous, this.sweeps, this.error);
  static PslStatus? parse(List<int> b) => b.length < 9 ? null : PslStatus(b[0], (b[1] & 1) != 0, u16(b, 2), u32(b, 5));
}

class QParams {
  int spanKhz;
  int stepKhz;
  int avgIndex;
  bool continuous;
  QParams({this.spanKhz = 1600, this.stepKhz = 5, this.avgIndex = 3, this.continuous = true});
  int get startHz => 13560000 - spanKhz * 1000 ~/ 2;
  int get stepHz => stepKhz * 1000;
  int get points => (spanKhz + stepKhz - 1) ~/ stepKhz;
  bool get valid => spanKhz >= 1 && spanKhz <= 5000 && stepKhz >= 1 && stepKhz <= 255 && points >= 1 && points <= 1000;
}

class QResult {
  final int sweep;
  final double q;
  final int resHz, lowHz, upHz;
  const QResult(this.sweep, this.q, this.resHz, this.lowHz, this.upHz);
  static QResult? parse(List<int> b) => b.length < 18 ? null : QResult(u16(b, 0), u32(b, 2) / 100.0, u32(b, 6), u32(b, 10), u32(b, 14));
}

class QTrace {
  final int startHz;
  final int stepHz;
  final List<int> amps;
  const QTrace(this.startHz, this.stepHz, this.amps);
}

enum LogKind { info, ok, warn, error }
enum LogArea { wlc, ptx, ble }
class LogEvent {
  final int id;
  final DateTime time;
  final String text;
  final LogKind kind;
  final LogArea area;
  final bool notify;
  const LogEvent(this.id, this.time, this.text, this.kind, this.area, this.notify);
}

class FoundDevice {
  final String id;
  final String name;
  final int rssi;
  const FoundDevice(this.id, this.name, this.rssi);
}

enum AppConnState { disconnected, connecting, connected }

String techName(int t) => switch (t) {0 => 'NFC-A (ISO 14443-A)', 1 => 'NFC-B (ISO 14443-B)', 2 => 'NFC-F (FeliCa)', 3 => 'NFC-V (ISO 15693)', 4 => 'ACM / P2P', _ => 'Unknown ($t)'};
String protocolName(int p) => switch (p) {2 => 'Type 2 Tag (T2T)', 3 => 'Type 3 Tag (T3T)', 4 => 'Type 4 Tag (T4T / ISO-DEP)', 5 => 'Type 5 Tag (T5T)', 6 => 'NFC-DEP', 0 => 'Undefined', _ => 'Unknown ($p)'};
String idLabel(int tech) => switch (tech) {0 => 'NFCID1', 1 => 'NFCID0', 2 => 'NFCID2', 3 => 'UID', _ => 'ID'};
String chargerName(int v) => switch (v) {0 => 'disabled', 1 => 'trickle charge (TCM)', 2 => 'constant current (CCM)', 3 => 'constant voltage (CVM)', 4 => 'done', _ => '0x${v.toRadixString(16)}'};
String ntcName(int v) => switch (v) {0 => 'normal', 1 => 'cold', 2 => 'hot', _ => '0x${v.toRadixString(16)}'};
String errorName(int v) => v == 0 ? 'none' : '0x${v.toRadixString(16).padLeft(2, '0')}';

String describeNdef(List<int> data) {
  if (data.isEmpty) return 'empty payload';
  // Same intent as Android: show useful text when possible, always keep raw bytes below it.
  final printable = data.where((b) => b == 9 || b == 10 || b == 13 || (b >= 32 && b <= 126)).length;
  if (printable > data.length * .75) {
    return String.fromCharCodes(data).replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F]'), '');
  }
  return 'Binary payload (${data.length} bytes)';
}

// =============================================================================
// BLE controller - iOS CoreBluetooth parity layer
// =============================================================================

class BleController extends ChangeNotifier {
  static const namePrefix = 'Zephyr';
  static const maxSamples = 20000;
  final FlutterReactiveBle ble = FlutterReactiveBle();

  final Map<String, FoundDevice> _found = <String, FoundDevice>{};
  StreamSubscription<DiscoveredDevice>? _scanSub;
  StreamSubscription<ConnectionStateUpdate>? _connSub;
  final List<StreamSubscription<List<int>>> _notifySubs = [];
  Timer? _scanTimer, _connectTimer, _readyTimer, _pollTimer, _pollActionTimer, _oemTimer;

  AppConnState connState = AppConnState.disconnected;
  bool scanning = false;
  String? connectStatus;
  String? error;
  String? connectedId;
  String? connectedName;
  int connectAttempt = 0;
  int connSession = 0;
  List<DiscoveredService> services = [];

  int? batteryPercent;
  final List<BatterySample> batteryHistory = [];
  SystemStatus? systemStatus;
  final List<StatusSample> statusHistory = [];
  int reads = 0, notifications = 0, failedReads = 0;
  bool _batteryReadInProgress = false;
  bool gotBattery = false, gotStatus = false, expectBattery = false, expectStatus = false;

  CardInfo? card;
  final List<CardExchange> exchanges = [];
  bool cardService = false, pollService = false, pslService = false, oemService = false;
  int cardEvents = 0;

  PollStatus? pollStatus;
  PollSettings? pollActive;
  PollSettings? pollDraft;
  bool pollBusy = false;
  String? pollMessage;

  PslStatus? pslStatus;
  QParams qParams = QParams();
  QParams? qRunParams;
  QTrace? qTrace;
  final List<QTrace> qKept = [];
  bool qKeep = false;
  QResult? qResult;
  String? qMessage;
  final List<int> _qAmps = [];

  OemStatus? oemStatus;
  Map<int, int> oemDefaults = {};
  Map<int, int> oemDraft = {};
  bool oemAck = false, oemUnlockRisky = false, oemUploading = false;
  String? oemMessage;
  bool oemMessageIsError = false;

  bool rssiMonitoring = false;
  final List<RssiSample> rssiHistory = [];
  double? filteredRssi;

  final List<LogEvent> events = [];
  int _eventSeq = 0;
  int _asmId = -1, _asmNext = 0;
  BytesBuilder _asm = BytesBuilder(copy: false);

  List<FoundDevice> get devices => _found.values.toList()..sort((a, b) => b.rssi.compareTo(a.rssi));

  void _emit() => notifyListeners();

  void log(String text, LogArea area, {LogKind kind = LogKind.info, bool notify = false}) {
    events.add(LogEvent(++_eventSeq, DateTime.now(), text, kind, area, notify));
    if (events.length > 300) events.removeAt(0);
    _emit();
  }

  void clearEvents() { events.clear(); _emit(); }

  Future<void> startScan() async {
    await stopScan();
    _found.clear();
    error = null;
    scanning = true;
    _emit();
    _scanSub = ble.scanForDevices(withServices: const [], scanMode: ScanMode.lowLatency).listen((d) {
      final name = d.name.trim();
      if (!name.startsWith(namePrefix)) return;
      _found[d.id] = FoundDevice(d.id, name, d.rssi);
      _emit();
    }, onError: (Object e) {
      scanning = false;
      error = 'Scan failed: $e';
      _emit();
    });
    _scanTimer = Timer(const Duration(seconds: 15), stopScan);
  }

  Future<void> stopScan() async {
    _scanTimer?.cancel();
    _scanTimer = null;
    await _scanSub?.cancel();
    _scanSub = null;
    if (scanning) { scanning = false; _emit(); }
  }

  Future<void> connect(FoundDevice d) async {
    await stopScan();
    await _closeConnection(keepIdentity: true);
    connectedId = d.id;
    connectedName = d.name;
    connSession++;
    connectAttempt = 0;
    await _startConnectAttempt();
  }

  Future<void> _startConnectAttempt() async {
    final id = connectedId;
    if (id == null) return;
    connectAttempt++;
    _resetSessionData();
    connState = AppConnState.connecting;
    connectStatus = connectAttempt > 1 ? 'Connecting… (attempt $connectAttempt/3)' : 'Connecting…';
    error = null;
    _emit();

    await _connSub?.cancel();
    _connSub = ble.connectToDevice(id: id, connectionTimeout: const Duration(seconds: 20)).listen((u) async {
      if (u.connectionState == DeviceConnectionState.connected) {
        connectStatus = 'Discovering services…';
        _emit();
        _connectTimer?.cancel();
        await _discoverAndSubscribe();
      } else if (u.connectionState == DeviceConnectionState.disconnected) {
        if (connState == AppConnState.connecting) {
          await _failOrRetry('connection closed');
        } else if (connState == AppConnState.connected) {
          log('Disconnected', LogArea.ble, kind: LogKind.warn, notify: true);
          await _closeConnection(keepIdentity: false);
          error = null;
          _emit();
        }
      }
    }, onError: (Object e) async {
      if (connState == AppConnState.connecting) {
        await _failOrRetry(e.toString());
      } else {
        log('Connection lost: $e', LogArea.ble, kind: LogKind.error, notify: true);
        await _closeConnection(keepIdentity: false);
        error = 'Connection lost';
        _emit();
      }
    });
    _connectTimer = Timer(const Duration(seconds: 20), () => _failOrRetry('timed out'));
  }

  Future<void> _failOrRetry(String reason) async {
    _connectTimer?.cancel();
    await _connSub?.cancel();
    _connSub = null;
    if (connectAttempt < 3 && connectedId != null) {
      connectStatus = 'Retrying… ($reason)';
      _emit();
      await Future<void>.delayed(const Duration(milliseconds: 700));
      if (connectedId != null && connState == AppConnState.connecting) await _startConnectAttempt();
    } else {
      connState = AppConnState.disconnected;
      connectStatus = null;
      error = 'Could not connect ($reason). Check that the board is powered and nearby, then try again.';
      connectedId = null;
      connectedName = null;
      _emit();
    }
  }

  Future<void> cancelConnect() async {
    connectedId = null;
    connectedName = null;
    await _closeConnection(keepIdentity: false);
    error = null;
    _emit();
  }

  Future<void> disconnect() async {
    log('Disconnected', LogArea.ble, kind: LogKind.warn, notify: true);
    await _closeConnection(keepIdentity: false);
    _emit();
  }

  Future<void> _closeConnection({required bool keepIdentity}) async {
    _scanTimer?.cancel(); _connectTimer?.cancel(); _readyTimer?.cancel(); _pollTimer?.cancel(); _pollActionTimer?.cancel(); _oemTimer?.cancel();
    for (final s in _notifySubs) { await s.cancel(); }
    _notifySubs.clear();
    await _connSub?.cancel();
    _connSub = null;
    connState = AppConnState.disconnected;
    services = [];
    if (!keepIdentity) { connectedId = null; connectedName = null; }
  }

  void _resetSessionData() {
    batteryPercent = null; batteryHistory.clear(); _batteryReadInProgress = false; systemStatus = null; statusHistory.clear(); gotBattery = false; gotStatus = false; expectBattery = false; expectStatus = false;
    reads = 0; notifications = 0; failedReads = 0; services = [];
    card = null; exchanges.clear(); cardService = false;
    pollService = false; pollStatus = null; pollActive = null; pollDraft = null; pollMessage = null; pollBusy = false;
    pslService = false; pslStatus = null; qRunParams = null; qTrace = null; qKept.clear(); qResult = null; qMessage = null; _qAmps.clear();
    oemService = false; oemStatus = null; oemDefaults = {}; oemDraft = {}; oemAck = false; oemUnlockRisky = false; oemUploading = false; oemMessage = null;
    rssiMonitoring = false; rssiHistory.clear(); filteredRssi = null;
    events.clear();
  }

  DiscoveredService? _findService(String svc) {
    for (final s in services) {
      if (sameBleUuid(s.serviceId, svc)) return s;
    }
    return null;
  }

  DiscoveredCharacteristic? _findChar(String svc, String chr) {
    final service = _findService(svc);
    if (service == null) return null;

    for (final c in service.characteristics) {
      if (sameBleUuid(c.characteristicId, chr)) return c;
    }
    return null;
  }

  QualifiedCharacteristic? _q(String svc, String chr) {
    final id = connectedId;
    final service = _findService(svc);
    if (id == null || service == null) return null;

    for (final c in service.characteristics) {
      if (sameBleUuid(c.characteristicId, chr)) {
        // Important for iOS: use the UUIDs returned by CoreBluetooth during
        // discovery instead of rebuilding the standard SIG UUID ourselves.
        return QualifiedCharacteristic(
          deviceId: id,
          serviceId: service.serviceId,
          characteristicId: c.characteristicId,
        );
      }
    }
    return null;
  }

  Future<List<int>?> _read(String svc, String chr, {int tries = 1}) async {
    final q = _q(svc, chr);
    if (q == null) return null;
    for (var i = 0; i < tries; i++) {
      try {
        final v = await ble.readCharacteristic(q).timeout(const Duration(seconds: 3));
        return v;
      } catch (_) {
        if (i == tries - 1) failedReads++;
        if (i + 1 < tries) await Future<void>.delayed(const Duration(milliseconds: 150));
      }
    }
    return null;
  }

  Future<bool> _write(String svc, String chr, List<int> value) async {
    final q = _q(svc, chr);
    if (q == null) return false;
    for (var i = 0; i < 3; i++) {
      try {
        // On iOS an encrypted characteristic automatically asks CoreBluetooth to pair.
        // iOS intentionally does not allow apps to auto-enter the passkey like Android does.
        await ble.writeCharacteristicWithResponse(q, value: value).timeout(const Duration(seconds: 30));
        return true;
      } catch (e) {
        if (i == 2) {
          log('Write failed (${chr.substring(0, 8)}): $e', LogArea.ble, kind: LogKind.warn);
          return false;
        }
        await Future<void>.delayed(const Duration(milliseconds: 150));
      }
    }
    return false;
  }

  void _subscribe(String svc, String chr, void Function(List<int>) onData) {
    final q = _q(svc, chr);
    final c = _findChar(svc, chr);
    if (q == null || c == null || (!c.isNotifiable && !c.isIndicatable)) return;
    final sub = ble.subscribeToCharacteristic(q).listen(onData, onError: (Object e) {
      log('Could not enable notifications (${chr.substring(0, 8)}): $e', LogArea.ble, kind: LogKind.warn, notify: true);
    });
    _notifySubs.add(sub);
  }

  Future<void> _discoverAndSubscribe() async {
    final id = connectedId;
    if (id == null) return;
    try {
      services = await ble.discoverServices(id).timeout(const Duration(seconds: 8));
      connectStatus = 'Loading device data…';
      _emit();

      final stc = _findChar(AppUuids.statusService, AppUuids.statusChar);
      if (stc != null) {
        expectStatus = true;
        _subscribe(AppUuids.statusService, AppUuids.statusChar, (b) => _handleStatus(b, true));
        final v = await _read(AppUuids.statusService, AppUuids.statusChar, tries: 3);
        if (v != null) _handleStatus(v, false);
      }

      cardService = _findChar(AppUuids.cardService, AppUuids.cardInfo) != null;
      if (cardService) {
        _subscribe(AppUuids.cardService, AppUuids.cardInfo, (b) => _handleCard(b));
        _subscribe(AppUuids.cardService, AppUuids.cardExchange, _handleExchangeFragment);
        final v = await _read(AppUuids.cardService, AppUuids.cardInfo, tries: 2);
        if (v != null) _handleCard(v);
      }

      pollService = _findChar(AppUuids.pollService, AppUuids.pollConfig) != null;
      if (pollService) {
        _subscribe(AppUuids.pollService, AppUuids.pollStatus, _handlePollStatusBytes);
        _subscribe(AppUuids.pollService, AppUuids.pollConfig, _handlePollConfigBytes);
        final ps = await _read(AppUuids.pollService, AppUuids.pollStatus, tries: 2);
        if (ps != null) _handlePollStatusBytes(ps);
        await reloadPollSettings();
      }

      pslService = _findChar(AppUuids.pslService, AppUuids.pslStatus) != null;
      if (pslService) {
        _subscribe(AppUuids.pslService, AppUuids.pslStatus, _handlePslStatusBytes);
        _subscribe(AppUuids.pslService, AppUuids.pslResult, (b) { qResult = QResult.parse(b); _emit(); });
        _subscribe(AppUuids.pslService, AppUuids.pslTrace, _handlePslTrace);
        final ps = await _read(AppUuids.pslService, AppUuids.pslStatus, tries: 2);
        if (ps != null) _handlePslStatusBytes(ps);
      }

      oemService = _findChar(AppUuids.oemService, AppUuids.oemStatus) != null;
      if (oemService) {
        _subscribe(AppUuids.oemService, AppUuids.oemStatus, (b) => _handleOemStatus(b, true));
        final os = await _read(AppUuids.oemService, AppUuids.oemStatus, tries: 2);
        if (os != null) _handleOemStatus(os, false);
        final op = await _read(AppUuids.oemService, AppUuids.oemParams, tries: 3);
        if (op != null) _handleOemParams(op);
      }

      final batt = _findChar(
        AppUuids.batteryService,
        AppUuids.batteryLevel,
      );
      if (batt != null) {
        expectBattery = true;

        // Same data source as Android: standard Battery Service 0x180F /
        // Battery Level 0x2A19. No VDBAT-derived fallback is used here.
        _subscribe(
          AppUuids.batteryService,
          AppUuids.batteryLevel,
          (b) => _handleBattery(b, true),
        );

        final v = await _read(
          AppUuids.batteryService,
          AppUuids.batteryLevel,
          tries: 3,
        );
        if (v != null && v.isNotEmpty) {
          _handleBattery(v, false);
          log(
            'Battery Level read: ${v.first.clamp(0, 100)}%',
            LogArea.ble,
          );
        } else {
          log(
            'Battery Level characteristic found, initial read returned no data',
            LogArea.ble,
            kind: LogKind.warn,
          );
        }
      } else {
        final sigServices = services
            .map((s) => canonicalBleUuid(s.serviceId))
            .where((u) => u.startsWith('0000'))
            .join(', ');
        log(
          'Battery Service 0x180F / Battery Level 0x2A19 not found. '
          'Discovered SIG services: $sigServices',
          LogArea.ble,
          kind: LogKind.warn,
        );
      }

      _readyTimer?.cancel();
      _readyTimer = Timer(const Duration(seconds: 8), _markConnected);
      _checkReady();
      _pollTimer?.cancel();
      _pollTimer = Timer.periodic(const Duration(seconds: 1), (_) => _periodic());
    } catch (e) {
      await _failOrRetry('service discovery failed: $e');
    }
  }

  void _checkReady() {
    if ((!expectBattery || gotBattery) && (!expectStatus || gotStatus)) {
      _readyTimer?.cancel();
      Future<void>.delayed(const Duration(milliseconds: 300), _markConnected);
    }
  }

  void _markConnected() {
    if (connectedId == null || connState != AppConnState.connecting) return;
    connState = AppConnState.connected;
    connectStatus = null;
    log('Connected to ${connectedName ?? 'device'}', LogArea.ble, kind: LogKind.ok, notify: true);
    _emit();
  }

  Future<void> _periodic() async {
    if (connState != AppConnState.connected) return;

    if (!_batteryReadInProgress &&
        _findChar(AppUuids.batteryService, AppUuids.batteryLevel) != null) {
      _batteryReadInProgress = true;
      try {
        final b = await _read(
          AppUuids.batteryService,
          AppUuids.batteryLevel,
        );
        if (b != null && b.isNotEmpty) {
          _handleBattery(b, false);
        }
      } finally {
        _batteryReadInProgress = false;
      }
    }

    if (rssiMonitoring && connectedId != null) {
      try {
        final raw = await ble.readRssi(connectedId!);
        filteredRssi = filteredRssi == null ? raw.toDouble() : filteredRssi! * .75 + raw * .25;
        rssiHistory.add(RssiSample(DateTime.now(), raw, filteredRssi!));
        if (rssiHistory.length > maxSamples) rssiHistory.removeAt(0);
        _emit();
      } catch (_) {}
    }
  }

  void _handleBattery(List<int> b, bool notify) {
    if (b.isEmpty) return;
    gotBattery = true;
    final raw = b[0].clamp(0, 100).toInt();
    final held = batteryPercent;
    final pct = held == null ? raw : raw - held > 1 ? raw - 1 : held - raw > 1 ? raw + 1 : held;
    batteryPercent = pct;
    batteryHistory.add(BatterySample(DateTime.now(), pct));
    if (batteryHistory.length > maxSamples) batteryHistory.removeAt(0);
    if (notify) notifications++; else reads++;
    _checkReady();
    _emit();
  }

  void _handleStatus(List<int> b, bool notify) {
    final st = SystemStatus.parse(b);
    if (st == null) return;
    final prev = systemStatus;
    systemStatus = st;
    gotStatus = true;
    statusHistory.add(StatusSample(DateTime.now(), st));
    if (statusHistory.length > maxSamples) statusHistory.removeAt(0);
    _logStatusChanges(prev, st);
    _checkReady();
    _emit();
  }

  void _logStatusChanges(SystemStatus? prev, SystemStatus st) {
    if (prev == null) {
      log('WLC field: ${st.rfFieldDetected ? 'detected, charger ${chargerName(st.chargerStatus)}' : 'none'}', LogArea.wlc);
      return;
    }
    if (prev.rfFieldDetected != st.rfFieldDetected) {
      log(st.rfFieldDetected ? 'WLC field detected' : 'WLC field lost', LogArea.wlc, kind: st.rfFieldDetected ? LogKind.ok : LogKind.warn, notify: true);
    }
    if (prev.chargerStatus != st.chargerStatus && (st.rfFieldDetected || prev.rfFieldDetected)) {
      if (st.chargerStatus == 4) log('Charging done', LogArea.wlc, kind: LogKind.ok, notify: true);
      else if (st.charging) log('Charger: ${chargerName(st.chargerStatus)}', LogArea.wlc, kind: LogKind.ok, notify: true);
      else log('Charger: ${chargerName(st.chargerStatus)}', LogArea.wlc, notify: true);
    }
    if (prev.wlcpStatus != st.wlcpStatus) log(st.wlcpStatus == 1 ? 'WLC poller connected' : 'WLC poller disconnected', LogArea.wlc);
    if (prev.error != st.error) log(st.error == 0 ? 'Error cleared' : 'Error: ${errorName(st.error)}', LogArea.wlc, kind: st.error == 0 ? LogKind.ok : LogKind.error, notify: true);
    if (prev.ntcStatus != st.ntcStatus) log('NTC: ${ntcName(st.ntcStatus)}', LogArea.wlc, kind: st.ntcStatus == 0 ? LogKind.info : LogKind.warn);
  }

  void _handleCard(List<int> b) {
    final ci = CardInfo.parse(b);
    if (ci == null) return;
    final was = card?.present == true;
    card = ci;
    if (ci.present && !was) {
      cardEvents++;
      log('Card detected: ${techName(ci.tech)}, ${protocolName(ci.protocol)}, ${idLabel(ci.tech)} ${ci.idHex}', LogArea.ptx, kind: LogKind.ok, notify: true);
    } else if (!ci.present && was) {
      log('Card removed', LogArea.ptx);
    }
    _emit();
  }

  void _handleExchangeFragment(List<int> b) {
    if (b.length < 4) return;
    final id = b[0], kind = b[1], idx = b[2], total = b[3];
    if (idx == 0) { _asm = BytesBuilder(copy: false); _asmId = id; _asmNext = 0; }
    if (id != _asmId || idx != _asmNext) { _asmId = -1; _asm = BytesBuilder(copy: false); return; }
    _asm.add(b.sublist(4));
    _asmNext++;
    if (idx == total - 1) {
      final ex = CardExchange(DateTime.now(), kind, _asm.takeBytes());
      exchanges.insert(0, ex);
      if (exchanges.length > 30) exchanges.removeLast();
      cardEvents++;
      if (kind == 1) log('Card data: ${describeNdef(ex.data).replaceAll('\n', ' | ').substring(0, math.min(90, describeNdef(ex.data).length))}', LogArea.ptx);
      if (kind == 2) log('Card data: unlock code matched, lock toggled', LogArea.ptx, kind: LogKind.ok, notify: true);
      if (kind == 3) log('Card data exchange failed', LogArea.ptx, kind: LogKind.error);
      if (kind == 4) log('Card has no data exchange (${protocolName(card?.protocol ?? 0)})', LogArea.ptx);
      _asmId = -1;
      _emit();
    }
  }

  void _handlePollConfigBytes(List<int> b) {
    final s = PollSettings.parse(b);
    if (s == null) return;
    pollActive = s;
    pollDraft ??= s.copy();
    _emit();
  }

  void _handlePollStatusBytes(List<int> b) {
    final st = PollStatus.parse(b);
    if (st == null) return;
    final prev = pollStatus;
    pollStatus = st;
    if (prev != null && !st.restarting && (prev.restarting || st.restarts != prev.restarts)) {
      unawaited(reloadPollSettings());
      _pollActionTimer?.cancel();
      pollBusy = false;
      final failed = st.error != 0;
      pollMessage = failed ? 'The reader could not start with these settings (error 0x${st.error.toRadixString(16)}): it uses the defaults.' : 'Done. The reader restarted with the new settings.';
      log(failed ? 'Reader polling settings rejected, defaults restored' : 'Polling settings applied, reader restarted', LogArea.ptx, kind: failed ? LogKind.warn : LogKind.ok);
    }
    _emit();
  }

  void editPoll(PollSettings p) { pollDraft = p; pollMessage = null; _emit(); }
  void revertPoll() { pollDraft = pollActive?.copy(); pollMessage = null; _emit(); }

  Future<void> reloadPollSettings() async {
    final b = await _read(AppUuids.pollService, AppUuids.pollConfig, tries: 3);
    if (b == null) { pollMessage = 'Could not read the settings from the reader. Reconnect to try again.'; _emit(); return; }
    final s = PollSettings.parse(b);
    if (s != null) { pollActive = s; pollDraft = s.copy(); _emit(); }
  }

  Future<void> applyPoll() async {
    final d = pollDraft;
    if (d == null || pollBusy) return;
    pollBusy = true;
    pollMessage = 'Sending the settings, the reader restarts…';
    _emit();
    _pollActionTimer?.cancel();
    _pollActionTimer = Timer(const Duration(seconds: 15), () { pollBusy = false; pollMessage = 'No answer from the reader. Check the connection and try again.'; _emit(); });
    if (!await _write(AppUuids.pollService, AppUuids.pollConfig, d.encode())) { _pollWriteFailed(); return; }
    if (!await _write(AppUuids.pollService, AppUuids.pollControl, [1])) _pollWriteFailed();
  }

  Future<void> restorePollDefaults() async {
    if (pollBusy) return;
    pollBusy = true;
    pollMessage = 'Restoring the defaults, the reader restarts…';
    _emit();
    _pollActionTimer?.cancel();
    _pollActionTimer = Timer(const Duration(seconds: 15), () { pollBusy = false; pollMessage = 'No answer from the reader. Check the connection and try again.'; _emit(); });
    if (!await _write(AppUuids.pollService, AppUuids.pollControl, [2])) _pollWriteFailed();
  }

  void _pollWriteFailed() { _pollActionTimer?.cancel(); pollBusy = false; pollMessage = 'Could not send the settings. If iOS asks for the board passkey, complete pairing and try again.'; _emit(); }

  void setQParams(QParams p) { qParams = p; _emit(); }
  void setQKeep(bool v) { qKeep = v; if (!v) qKept.clear(); _emit(); }
  void clearQ() { _qAmps.clear(); qTrace = null; qKept.clear(); qResult = null; qMessage = null; _emit(); }

  Future<void> startQ() async {
    if (!qParams.valid || (pslStatus?.state ?? 0) != 0) return;
    _qAmps.clear();
    qRunParams = QParams(spanKhz: qParams.spanKhz, stepKhz: qParams.stepKhz, avgIndex: qParams.avgIndex, continuous: qParams.continuous);
    if (qKeep && qTrace != null) { qKept.add(qTrace!); if (qKept.length > 6) qKept.removeAt(0); } else if (!qKeep) qKept.clear();
    qTrace = null; qResult = null; qMessage = 'Starting: the reader is stopped and its RF field switched off…'; _emit();
    final p = qParams;
    final ok = await _write(AppUuids.pslService, AppUuids.pslControl, [1, p.spanKhz & 0xFF, (p.spanKhz >> 8) & 0xFF, p.stepKhz & 0xFF, p.avgIndex & 0xFF, p.continuous ? 1 : 0]);
    if (!ok) { qMessage = 'Could not send the request. If iOS asks for the board passkey, complete pairing and try again.'; _emit(); }
  }

  Future<void> stopQ() async {
    qMessage = 'Stopping: the reader restarts automatically…'; _emit();
    if (!await _write(AppUuids.pslService, AppUuids.pslControl, [2])) { qMessage = 'Could not send the request.'; _emit(); }
  }

  void _handlePslStatusBytes(List<int> b) {
    final st = PslStatus.parse(b); if (st == null) return;
    final prev = pslStatus; pslStatus = st;
    if (st.state == 0 && prev != null && prev.state != 0) qMessage = null;
    if (prev?.state != st.state) {
      if (st.state == 1) log('Q measurement started, reader paused', LogArea.ptx);
      if (st.state == 2) log('Q measurement stopped, restarting the reader', LogArea.ptx);
      if (st.state == 0 && prev != null && prev.state != 0) log('Reader running again', LogArea.ptx, kind: LogKind.ok);
    }
    _emit();
  }

  void _handlePslTrace(List<int> b) {
    if (b.length < 6 || qRunParams == null) return;
    final first = u16(b, 2);
    final n = (b.length - 4) ~/ 2;
    final p = qRunParams!;
    QTrace? finished;
    if (first == 0) {
      if (_qAmps.isNotEmpty) finished = QTrace(p.startHz, p.stepHz, List<int>.from(_qAmps));
      _qAmps.clear();
    }
    if (first != _qAmps.length) return;
    for (var i = 0; i < n; i++) _qAmps.add(u16(b, 4 + 2 * i));
    if (finished != null && qKeep) { qKept.add(finished); if (qKept.length > 6) qKept.removeAt(0); }
    qTrace = QTrace(p.startHz, p.stepHz, List<int>.from(_qAmps));
    _emit();
  }

  void _handleOemStatus(List<int> b, bool notify) {
    final st = OemStatus.parse(b); if (st == null) return;
    oemStatus = st;
    if (notify && oemUploading && !st.busy && st.result != 0) {
      _oemTimer?.cancel();
      final offender = OemCatalog.byId[st.badId]?.title;
      switch (st.result) {
        case 1: oemMessage = 'Done. The parameters are written to the chip and the chip was reset.'; oemMessageIsError = false; break;
        case 2: oemMessage = 'The chip could not write the parameters (error ${st.error}). Check the write counter.'; oemMessageIsError = true; break;
        case 3: oemMessage = 'Rejected: the write was not acknowledged.'; oemMessageIsError = true; break;
        case 4: oemMessage = 'Rejected: an RF field is present. Remove the charger and try again.'; oemMessageIsError = true; break;
        case 5: oemMessage = 'The driver rejected${offender == null ? ' the parameters' : ' "$offender"'} (error ${st.error}). Check values that depend on each other.'; oemMessageIsError = true; break;
        case 6: oemMessage = "Rejected: the chip's write cycle limit is reached."; oemMessageIsError = true; break;
        case 7: oemMessage = 'A write is already in progress.'; oemMessageIsError = true; break;
        default: oemMessage = 'Unknown answer (${st.result}).'; oemMessageIsError = true;
      }
      oemUploading = false; oemAck = false;
      log('OEM upload: $oemMessage', LogArea.wlc, kind: oemMessageIsError ? LogKind.error : LogKind.ok, notify: true);
    }
    _emit();
  }

  void _handleOemParams(List<int> b) {
    final map = <int, int>{};
    for (var i = 0; i + 2 < b.length; i += 3) map[b[i]] = b[i + 1] | (b[i + 2] << 8);
    if (map.length < OemCatalog.params.length) return;
    oemDefaults = map;
    if (oemDraft.isEmpty) oemDraft = Map<int, int>.from(map);
    _emit();
  }

  void setOemAck(bool v) { oemAck = v; _emit(); }
  void setOemUnlockRisky(bool v) { oemUnlockRisky = v; _emit(); }
  void revertOem() { oemDraft = Map<int, int>.from(oemDefaults); oemMessage = null; _emit(); }

  void setOemValue(int id, int value) {
    final before = oemDraft[id];
    oemDraft[id] = value;
    if (id == 1 && before != null && (before & 0x80) != (value & 0x80)) {
      final mode = value & 0x80;
      for (final dep in [2, 3, 4]) {
        final cur = oemDraft[dep]; if (cur == null || (cur & 0x80) == mode) continue;
        final p = OemCatalog.byId[dep]; if (p == null) continue;
        if (dep == 4) {
          final old = p.options.where((o) => o.value == cur).map((o) => o.physical ?? 0).firstOrNull ?? 0;
          final candidates = p.options.where((o) => (o.value & 0x80) == mode && o.physical != null).toList();
          candidates.sort((a, b) => ((a.physical! - old).abs()).compareTo((b.physical! - old).abs()));
          if (candidates.isNotEmpty) oemDraft[dep] = candidates.first.value;
        } else {
          oemDraft[dep] = value;
        }
      }
    }
    oemMessage = null; _emit();
  }

  Future<void> uploadOem() async {
    if (oemUploading || !oemAck || oemDraft.length < OemCatalog.params.length) return;
    final st = oemStatus;
    if (st != null && (st.rfField || st.busy || (st.writeCount != null && st.writeCount! >= st.maxCycles))) return;
    oemUploading = true; oemAck = false; oemMessage = 'Sending the parameters…'; oemMessageIsError = false; _emit();
    _oemTimer?.cancel();
    _oemTimer = Timer(const Duration(seconds: 40), () { if (oemUploading) { oemUploading = false; oemMessageIsError = true; oemMessage = 'No answer from the device. The write may still have happened: check the write counter.'; log('OEM upload failed: $oemMessage', LogArea.wlc, kind: LogKind.error, notify: true); _emit(); } });
    final entries = <List<int>>[];
    for (final p in OemCatalog.params) {
      final v = oemDraft[p.id];
      if (v == null) { _oemFail('Parameters are not loaded yet.'); return; }
      entries.add([p.id, v & 0xFF, (v >> 8) & 0xFF]);
    }
    for (var i = 0; i < entries.length; i += 6) {
      final bytes = <int>[];
      for (final e in entries.skip(i).take(6)) bytes.addAll(e);
      if (!await _write(AppUuids.oemService, AppUuids.oemParams, bytes)) { _oemFail('Could not send the parameters.'); return; }
    }
    oemMessage = 'Writing to the chip…'; _emit();
    if (!await _write(AppUuids.oemService, AppUuids.oemControl, [0x02, 0x01, 0xA5, 0x5A])) {
      _oemFail('The write request was sent but not confirmed. It may or may not have reached the chip: check the write counter.');
    }
  }

  void _oemFail(String msg) { _oemTimer?.cancel(); oemUploading = false; oemMessage = msg; oemMessageIsError = true; log('OEM upload failed: $msg', LogArea.wlc, kind: LogKind.error, notify: true); _emit(); }

  void setRssiMonitoring(bool on) { rssiMonitoring = on; filteredRssi = null; if (on) rssiHistory.clear(); _emit(); }

  @override
  void dispose() {
    _scanTimer?.cancel(); _connectTimer?.cancel(); _readyTimer?.cancel(); _pollTimer?.cancel(); _pollActionTimer?.cancel(); _oemTimer?.cancel();
    _scanSub?.cancel(); _connSub?.cancel();
    for (final s in _notifySubs) { s.cancel(); }
    super.dispose();
  }
}

extension FirstOrNullExt<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

// =============================================================================
// App shell / navigation
// =============================================================================

enum AppScreen { overview, wlc, ptx, ra6b1 }
String screenTitle(AppScreen s) => switch (s) {AppScreen.overview => 'Overview', AppScreen.wlc => 'WLC', AppScreen.ptx => 'PTX205R', AppScreen.ra6b1 => 'RA6B1'};
String screenSubtitle(AppScreen s) => switch (s) {AppScreen.overview => 'Board and events', AppScreen.wlc => 'Wireless charging · RRQ36031', AppScreen.ptx => 'NFC card reader', AppScreen.ra6b1 => 'Bluetooth LE microcontroller'};
LogArea? screenArea(AppScreen s) => switch (s) {AppScreen.overview => null, AppScreen.wlc => LogArea.wlc, AppScreen.ptx => LogArea.ptx, AppScreen.ra6b1 => LogArea.ble};
AppScreen screenForArea(LogArea a) => switch (a) {LogArea.wlc => AppScreen.wlc, LogArea.ptx => AppScreen.ptx, LogArea.ble => AppScreen.ra6b1};

class BleRootPage extends StatefulWidget {
  const BleRootPage({super.key});
  @override State<BleRootPage> createState() => _BleRootPageState();
}

class _BleRootPageState extends State<BleRootPage> {
  late final BleController c;
  AppScreen screen = AppScreen.overview;
  int lastSession = -1, lastEventId = 0;
  LogEvent? toast;
  Timer? toastTimer;

  @override void initState() { super.initState(); c = BleController()..addListener(_changed); }
  @override void dispose() { toastTimer?.cancel(); c.removeListener(_changed); c.dispose(); super.dispose(); }

  void _changed() {
    if (!mounted) return;
    if (c.connState == AppConnState.connected && lastSession != c.connSession) { lastSession = c.connSession; screen = AppScreen.overview; }
    final fresh = c.events.where((e) => e.id > lastEventId).toList();
    if (fresh.isNotEmpty) {
      lastEventId = fresh.last.id;
      final e = fresh.where((e) => e.notify && !(c.connState == AppConnState.connected && screenArea(screen) == e.area)).lastOrNull;
      if (e != null) {
        toast = e;
        toastTimer?.cancel();
        toastTimer = Timer(const Duration(milliseconds: 3500), () { if (mounted) setState(() => toast = null); });
      }
    }
    setState(() {});
  }

  void _go(AppScreen s) { setState(() { screen = s; if (toast != null && screenArea(s) == toast!.area) toast = null; }); Navigator.maybePop(context); }

  @override
  Widget build(BuildContext context) {
    final connected = c.connState == AppConnState.connected;
    return Scaffold(
      drawer: connected ? Drawer(child: SafeArea(child: _drawer())) : null,
      appBar: AppBar(
        backgroundColor: appBackground,
        surfaceTintColor: Colors.transparent,
        leading: connected ? Builder(builder: (ctx) => IconButton(icon: const Icon(Icons.menu), onPressed: () => Scaffold.of(ctx).openDrawer())) : null,
        titleSpacing: connected ? 0 : 16,
        title: connected ? Row(children: [BatteryIndicator(percent: c.batteryPercent, charging: c.systemStatus?.charging == true), const SizedBox(width: 12), Expanded(child: Text(c.connectedName ?? '', overflow: TextOverflow.ellipsis))]) : Text(c.connectedName ?? 'BLE NFC'),
        actions: connected ? [Padding(padding: const EdgeInsets.only(right: 12), child: OutlinedButton(onPressed: c.disconnect, child: const Text('Disconnect')))] : null,
        bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Divider(height: 1, color: Theme.of(context).colorScheme.outlineVariant)),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: SizedBox(
          height: 48,
          child: InkWell(
            onTap: connected ? () => setState(() => screen = AppScreen.overview) : null,
            child: const Center(child: RenesasLogo()),
          ),
        ),
      ),
      body: Stack(fit: StackFit.expand, children: [
        Padding(padding: const EdgeInsets.all(16), child: _body()),
        if (toast != null) Positioned(top: 12, left: 16, right: 16, child: EventToast(event: toast!, onTap: () => _go(screenForArea(toast!.area)))),
      ]),
    );
  }

  Widget _drawer() => Column(children: [
    Padding(padding: const EdgeInsets.fromLTRB(24, 24, 24, 8), child: Align(alignment: Alignment.centerLeft, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [GestureDetector(onTap: () => _go(AppScreen.overview), child: const RenesasLogo()), const SizedBox(height: 10), Text('Choose a part of the board', style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant))]))),
    const Divider(),
    for (final s in AppScreen.values) ListTile(selected: screen == s, selectedTileColor: Theme.of(context).colorScheme.primaryContainer.withOpacity(.5), title: Text(screenTitle(s), style: const TextStyle(fontWeight: FontWeight.w600)), subtitle: Text(screenSubtitle(s), style: const TextStyle(fontSize: 12)), onTap: () => _go(s)),
  ]);

  Widget _body() {
    if (c.connState == AppConnState.disconnected) return Column(children: [
      SizedBox(width: double.infinity, child: c.scanning ? OutlinedButton(onPressed: c.stopScan, child: const Text('Stop scanning')) : FilledButton(onPressed: c.startScan, child: const Text('Scan for "Zephyr*"'))),
      if (c.error != null) Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text(c.error!, style: TextStyle(color: Theme.of(context).colorScheme.error))),
      if (c.scanning && c.devices.isEmpty) const Padding(padding: EdgeInsets.all(16), child: Text('Searching…')),
      Expanded(child: ListView.separated(itemCount: c.devices.length, separatorBuilder: (_, __) => const Divider(height: 1), itemBuilder: (_, i) { final d = c.devices[i]; return ListTile(contentPadding: const EdgeInsets.symmetric(vertical: 4), title: Text(d.name), subtitle: Text('${d.id}  •  ${d.rssi} dBm', style: const TextStyle(fontSize: 12)), trailing: FilledButton(onPressed: () => c.connect(d), child: const Text('Connect')), onTap: () => c.connect(d)); })),
    ]);
    if (c.connState == AppConnState.connecting) return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [Row(children: [const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)), const SizedBox(width: 12), Expanded(child: Text(c.connectStatus ?? 'Connecting…'))]), const SizedBox(height: 12), OutlinedButton(onPressed: c.cancelConnect, child: const Text('Cancel')), if (c.error != null) Text(c.error!, style: TextStyle(color: Theme.of(context).colorScheme.error))]);
    return switch (screen) {
      AppScreen.overview => OverviewScreen(c: c, onNavigate: (s) => setState(() => screen = s)),
      AppScreen.wlc => WlcScreen(c: c),
      AppScreen.ptx => PtxScreen(c: c),
      AppScreen.ra6b1 => Ra6b1Screen(c: c),
    };
  }
}

class RenesasLogo extends StatelessWidget {
  const RenesasLogo({super.key});

  @override
  Widget build(BuildContext context) => const Text(
        'RENESAS',
        style: TextStyle(
          color: renesasBlue,
          fontWeight: FontWeight.w900,
          fontSize: 18,
          letterSpacing: 1.8,
        ),
      );
}

class BatteryIndicator extends StatelessWidget {
  final int? percent; final bool charging;
  const BatteryIndicator({super.key, this.percent, required this.charging});
  Color get fill => percent == null ? Colors.grey : percent! <= 20 ? Colors.red : percent! <= 50 ? Colors.amber.shade700 : Colors.green;
  @override Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [CustomPaint(size: const Size(28, 15), painter: _BatteryPainter((percent ?? 0) / 100, fill, charging)), const SizedBox(width: 4), Text(percent == null ? '--' : '$percent%', style: const TextStyle(fontSize: 13))]);
}

class _BatteryPainter extends CustomPainter {
  final double pct; final Color fill; final bool charging;
  _BatteryPainter(this.pct, this.fill, this.charging);
  @override void paint(Canvas canvas, Size size) {
    final p = Paint()..style = PaintingStyle.stroke..strokeWidth = 1.5..color = Colors.black87;
    final body = Rect.fromLTWH(0.75, .75, size.width - 4, size.height - 1.5);
    canvas.drawRRect(RRect.fromRectAndRadius(body, const Radius.circular(2)), p);
    canvas.drawRect(Rect.fromLTWH(size.width - 3, size.height * .3, 3, size.height * .4), Paint()..color = Colors.black87);
    final inner = body.deflate(2.6); canvas.drawRect(Rect.fromLTWH(inner.left, inner.top, inner.width * pct.clamp(0, 1), inner.height), Paint()..color = fill);
    if (charging) { final bolt = Path()..moveTo(size.width*.53, 2)..lineTo(size.width*.38, 8)..lineTo(size.width*.50, 8)..lineTo(size.width*.42, 13)..lineTo(size.width*.64, 6.3)..lineTo(size.width*.52, 6.3)..close(); canvas.drawPath(bolt, Paint()..color = Colors.black87); }
  }
  @override bool shouldRepaint(covariant _BatteryPainter old) => old.pct != pct || old.fill != fill || old.charging != charging;
}

class EventToast extends StatelessWidget {
  final LogEvent event; final VoidCallback onTap;
  const EventToast({super.key, required this.event, required this.onTap});
  Color get dot => switch(event.kind) {LogKind.info => Colors.blueGrey.shade200, LogKind.ok => Colors.greenAccent.shade200, LogKind.warn => Colors.orange.shade300, LogKind.error => Colors.red.shade300};
  @override Widget build(BuildContext context) => Material(elevation: 6, color: Theme.of(context).colorScheme.inverseSurface, borderRadius: BorderRadius.circular(24), child: InkWell(borderRadius: BorderRadius.circular(24), onTap: onTap, child: Padding(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10), child: Row(mainAxisSize: MainAxisSize.min, children: [Container(width: 8, height: 8, decoration: BoxDecoration(color: dot, shape: BoxShape.circle)), const SizedBox(width: 8), Expanded(child: Text(event.text, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: Theme.of(context).colorScheme.onInverseSurface, fontSize: 13))), const SizedBox(width: 10), Text(screenTitle(screenForArea(event.area)), style: TextStyle(color: Colors.blueGrey.shade200, fontSize: 11))]))));
}

// =============================================================================
// Overview
// =============================================================================

class OverviewScreen extends StatelessWidget {
  final BleController c; final ValueChanged<AppScreen> onNavigate;
  const OverviewScreen({super.key, required this.c, required this.onNavigate});
  @override Widget build(BuildContext context) => Column(children: [
    Expanded(child: Board3D(wlcActive: c.systemStatus?.rfFieldDetected == true, cardActive: c.card?.present == true, onPart: (p) => onNavigate(switch(p) {BoardPart.wlc => AppScreen.wlc, BoardPart.nfc => AppScreen.ptx, BoardPart.mcu => AppScreen.ra6b1}))),
    const SizedBox(height: 8),
    SizedBox(height: 140, child: EventTerminal(events: c.events, onClear: c.clearEvents)),
  ]);
}

enum BoardPart { wlc, nfc, mcu }
class Board3D extends StatelessWidget {
  final bool wlcActive, cardActive;
  final ValueChanged<BoardPart> onPart;

  const Board3D({
    super.key,
    required this.wlcActive,
    required this.cardActive,
    required this.onPart,
  });

  @override
  Widget build(BuildContext context) => Container(
        color: const Color(0xFFF0F4FC),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 20),
        child: Image.asset(
          'assets/board3d_preview.png',
          fit: BoxFit.contain,
        ),
      );
}

class EventTerminal extends StatelessWidget {
  final List<LogEvent> events; final VoidCallback onClear;
  const EventTerminal({super.key, required this.events, required this.onClear});
  Color color(LogKind k) => switch(k) {LogKind.info => const Color(0xFF546E7A), LogKind.ok => const Color(0xFF2E7D32), LogKind.warn => const Color(0xFFB26A00), LogKind.error => const Color(0xFFC62828)};
  String hhmmss(DateTime t) => '${t.hour.toString().padLeft(2,'0')}:${t.minute.toString().padLeft(2,'0')}:${t.second.toString().padLeft(2,'0')}';
  @override Widget build(BuildContext context) => Container(decoration: BoxDecoration(color: surfaceVariant, borderRadius: BorderRadius.circular(8)), child: Column(children: [Row(children: [const Expanded(child: Padding(padding: EdgeInsets.only(left: 10), child: Text('events', style: TextStyle(fontFamily: 'monospace', fontSize: 10, color: Color(0xFF90A4AE))))), TextButton(onPressed: events.isEmpty ? null : onClear, child: const Text('clear', style: TextStyle(fontSize: 10)))]), Expanded(child: events.isEmpty ? const Align(alignment: Alignment.topLeft, child: Padding(padding: EdgeInsets.symmetric(horizontal: 10), child: Text('waiting for events…', style: TextStyle(fontFamily: 'monospace', fontSize: 10, color: Color(0xFF90A4AE))))) : ListView.builder(reverse: true, padding: const EdgeInsets.symmetric(horizontal: 10), itemCount: events.length, itemBuilder: (_, i) { final e = events[events.length-1-i]; return Text('${hhmmss(e.time)}  ${e.text}', style: TextStyle(fontFamily: 'monospace', fontSize: 10, color: color(e.kind))); }))]));
}

// =============================================================================
// WLC
// =============================================================================

class WlcScreen extends StatefulWidget { final BleController c; const WlcScreen({super.key, required this.c}); @override State<WlcScreen> createState() => _WlcScreenState(); }
class _WlcScreenState extends State<WlcScreen> { int tab=0; @override Widget build(BuildContext context) { final c=widget.c; return Column(children:[_tabs(['Status','Battery graph','OEM'],tab,(v)=>setState(()=>tab=v)), const SizedBox(height:8), Expanded(child: switch(tab){0=>_WlcStatus(c),1=>BatteryGraph(c:c),_=>OemScreen(c:c)})]); } }

Widget _tabs(List<String> labels,int selected,ValueChanged<int> onTap) => TabBarLike(labels: labels, selected: selected, onTap: onTap);
class TabBarLike extends StatelessWidget { final List<String> labels; final int selected; final ValueChanged<int> onTap; const TabBarLike({super.key,required this.labels,required this.selected,required this.onTap}); @override Widget build(BuildContext context)=>Row(children:[for(var i=0;i<labels.length;i++) Expanded(child: InkWell(onTap:()=>onTap(i), child: Column(children:[Padding(padding:const EdgeInsets.symmetric(vertical:12),child:Text(labels[i],textAlign:TextAlign.center,style:TextStyle(fontWeight:FontWeight.w600,color:selected==i?renesasBlue:Theme.of(context).colorScheme.onSurface))),Container(height:selected==i?3:1,color:selected==i?renesasBlue:Theme.of(context).colorScheme.outlineVariant)])))]); }

class _WlcStatus extends StatelessWidget { final BleController c; const _WlcStatus(this.c); @override Widget build(BuildContext context) { final s=c.systemStatus; return ListView(children:[Text('Battery: ${c.batteryPercent?.toString() ?? '--'}%'), const SizedBox(height:8), if(s==null) const Text('Waiting for system status…') else ...[
  _detail('RF field',s.rfFieldDetected?'detected':'none'), _detail('Charger',chargerName(s.chargerStatus)), _detail('NTC',ntcName(s.ntcStatus)), _detail('WLC poller',s.wlcpStatus==1?'connected':'disconnected'), _detail('Power OK',s.powerOk?'yes':'no'), _detail('VDDC','${s.vddcMv} mV'), _detail('VDBAT','${s.vdBatMv} mV'), _detail('Estimated current',s.estCurrentMa==null?'-':'${s.estCurrentMa} mA'), _detail('Estimated power',s.estPowerMw==null?'-':'${s.estPowerMw} mW'), _detail('Error',errorName(s.error)),
], const Divider(), const Text('Services seen by the phone',style:TextStyle(fontWeight:FontWeight.w600)), for(final svc in c.services) Padding(padding:const EdgeInsets.symmetric(vertical:3),child:Text('${serviceName(normUuid(svc.serviceId))}\n${normUuid(svc.serviceId)}',style:const TextStyle(fontSize:12))) ]); } }
Widget _detail(String a,String b)=>Padding(padding:const EdgeInsets.symmetric(vertical:5),child:Row(children:[Expanded(flex:4,child:Text(a,style:const TextStyle(color:Color(0xFF65728A)))),Expanded(flex:6,child:Text(b))]));
String serviceName(String u)=>u.startsWith('00001800')?'Generic Access':u.startsWith('00001801')?'Generic Attribute':u.startsWith('0000180f')?'Battery Service':u.startsWith('5a1f0001')?'System Status (custom)':u.startsWith('5a1f0010')?'Card Reader (custom)':u.startsWith('5a1f0020')?'OEM Config (custom)':u.startsWith('5a1f0030')?'PSL / Q measurement (custom)':u.startsWith('5a1f0040')?'Polling settings (custom)':u.startsWith('2e130421')?'Smart lock control (demo)':'Service';

class BatteryGraph extends StatefulWidget {
  final BleController c;
  const BatteryGraph({super.key, required this.c});

  @override
  State<BatteryGraph> createState() => _BatteryGraphState();
}

class _BatteryGraphState extends State<BatteryGraph> {
  bool showBatt = true;
  bool showVbat = true;
  bool showVddc = true;
  bool showPower = false;
  bool showPhases = true;

  @override
  Widget build(BuildContext context) {
    final c = widget.c;
    final s = c.systemStatus;

    final estimate = BatteryEstimator.estimate(c.statusHistory);
    final estNow = estimate.isEmpty ? null : estimate.last.percent.round();
    final eta = BatteryEstimator.etaToFull(c.statusHistory, estimate);

    String stateText;
    Color? stateColor;
    if (c.batteryHistory.isEmpty && s == null) {
      stateText = 'Waiting for data…';
      stateColor = null;
    } else if (s?.charging == true) {
      stateText =
          'Charging · ${shortPhaseName(s!.chargerStatus)}'
          '${eta == null ? '' : ' · full in ${formatEta(eta)}'}';
      stateColor = riseColor;
    } else if (s?.rfFieldDetected == true && s?.chargerStatus == 4) {
      stateText = 'Charged (done)';
      stateColor = riseColor;
    } else if (c.batteryHistory.length < 2) {
      stateText = 'Collecting data…';
      stateColor = null;
    } else {
      final last = c.batteryHistory.last;
      BatterySample first = c.batteryHistory.first;
      for (final h in c.batteryHistory.reversed) {
        if (last.time.difference(h.time).inMinutes <= 5) {
          first = h;
        } else {
          break;
        }
      }
      final dtMin =
          last.time.difference(first.time).inMilliseconds / 60000.0;
      final rate = dtMin < .5 ? null : (last.percent - first.percent) / dtMin;
      if (rate != null && rate < -0.05) {
        stateText = 'Discharging  ${rate.toStringAsFixed(1)} %/min';
        stateColor = fallColor;
      } else {
        stateText = rate == null ? 'Collecting data…' : 'Stable';
        stateColor = null;
      }
    }

    return ListView(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              '${c.batteryPercent ?? '--'}%',
              style: TextStyle(
                fontSize: 28,
                color: batteryDisplayColor(c.batteryPercent),
              ),
              maxLines: 1,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                stateText,
                maxLines: 2,
                style: TextStyle(
                  color: stateColor ??
                      Theme.of(context).colorScheme.onSurface,
                  fontSize: 14,
                ),
              ),
            ),
            if (estNow != null) ...[
              const SizedBox(width: 8),
              Text(
                'Est. $estNow%',
                style: const TextStyle(
                  color: Color(0xFFE6A21A),
                  fontSize: 16,
                ),
                maxLines: 1,
              ),
            ],
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 9,
              ),
              decoration: BoxDecoration(
                color: riseColor,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Text(
                '● LIVE',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _seriesChip(
                'Battery [%]',
                showBatt,
                const Color(0xFF388E3C),
                () => setState(() => showBatt = !showBatt),
              ),
              _seriesChip(
                'VDBAT [V]',
                showVbat,
                const Color(0xFF7E57C2),
                () => setState(() => showVbat = !showVbat),
              ),
              _seriesChip(
                'VDDC [V]',
                showVddc,
                const Color(0xFFEF6C00),
                () => setState(() => showVddc = !showVddc),
              ),
              _seriesChip(
                'Power [mW]',
                showPower,
                const Color(0xFF00897B),
                () => setState(() => showPower = !showPower),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  selected: showPhases,
                  onSelected: (_) =>
                      setState(() => showPhases = !showPhases),
                  label: const Text(
                    'Charger phases',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        if (showPhases)
          const Row(
            children: [
              _Legend(Color(0xFFFFA000), 'Trickle'),
              SizedBox(width: 12),
              _Legend(Color(0xFF1E88E5), 'CC'),
              SizedBox(width: 12),
              _Legend(Color(0xFF8E24AA), 'CV'),
              SizedBox(width: 12),
              _Legend(Color(0xFF43A047), 'Done'),
            ],
          ),
        const SizedBox(height: 8),
        if (showBatt)
          SizedBox(
            height: 130,
            child: SimpleHistoryChart(
              samples: c.statusHistory,
              battery: c.batteryHistory,
              kind: 0,
            ),
          ),
        if (showVbat)
          SizedBox(
            height: 130,
            child: SimpleHistoryChart(
              samples: c.statusHistory,
              battery: c.batteryHistory,
              kind: 1,
            ),
          ),
        if (showVddc)
          SizedBox(
            height: 130,
            child: SimpleHistoryChart(
              samples: c.statusHistory,
              battery: c.batteryHistory,
              kind: 2,
            ),
          ),
        if (showPower)
          SizedBox(
            height: 130,
            child: SimpleHistoryChart(
              samples: c.statusHistory,
              battery: c.batteryHistory,
              kind: 3,
            ),
          ),
        const Padding(
          padding: EdgeInsets.only(top: 12),
          child: Text(
            'Drag to scroll · pinch to zoom · tap a point for details',
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF65728A),
            ),
          ),
        ),
      ],
    );
  }

  Widget _seriesChip(
    String text,
    bool on,
    Color color,
    VoidCallback toggle,
  ) =>
      Padding(
        padding: const EdgeInsets.only(right: 8),
        child: FilterChip(
          selected: on,
          onSelected: (_) => toggle(),
          selectedColor: const Color(0xFFDDE5F8),
          avatar: Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          label: Text(
            text,
            style: TextStyle(
              color: on
                  ? const Color(0xFF1D2940)
                  : Colors.grey,
              fontSize: 12,
            ),
          ),
        ),
      );
}

Color batteryDisplayColor(int? percent) {
  if (percent == null) return Colors.grey;
  if (percent <= 20) return const Color(0xFFD32F2F);
  if (percent <= 50) return const Color(0xFFFBC02D);
  return const Color(0xFF388E3C);
}

class _Legend extends StatelessWidget {
  final Color color;
  final String text;

  const _Legend(this.color, this.text);

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Container(
            width: 10,
            height: 10,
            color: color.withOpacity(.5),
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(fontSize: 11),
          ),
        ],
      );
}

class SimpleHistoryChart extends StatelessWidget {final List<StatusSample> samples;final List<BatterySample> battery;final int kind;const SimpleHistoryChart({super.key,required this.samples,required this.battery,required this.kind});@override Widget build(BuildContext context)=>CustomPaint(painter:_HistoryPainter(samples,battery,kind),child:Container());}
class _HistoryPainter extends CustomPainter {final List<StatusSample>s;final List<BatterySample>b;final int kind;_HistoryPainter(this.s,this.b,this.kind);@override void paint(Canvas c,Size z){final grid=Paint()..color=const Color(0xFFD5DDE9)..strokeWidth=1;for(var i=0;i<=4;i++){final y=8+(z.height-24)*i/4;c.drawLine(Offset(42,y),Offset(z.width-8,y),grid);}for(var i=0;i<=4;i++){final x=42+(z.width-50)*i/4;c.drawLine(Offset(x,8),Offset(x,z.height-16),grid);}List<double> v=[];Color col;String label;if(kind==0){v=b.map((e)=>e.percent.toDouble()).toList();col=Colors.green;label='Battery';}else if(kind==1){v=s.map((e)=>e.status.vdBatMv/1000).toList();col=Colors.deepPurple;label='VDBAT';}else if(kind==2){v=s.map((e)=>e.status.vddcMv/1000).toList();col=Colors.deepOrange;label='VDDC';}else{v=s.map((e)=>(e.status.estPowerMw??0).toDouble()).toList();col=Colors.teal;label='Power';}if(v.isEmpty){_txt(c,'$label --',Offset(48,12),col);return;}double lo=kind==0?0:v.reduce(math.min),hi=kind==0?100:v.reduce(math.max);if((hi-lo).abs()<.01){lo-=.1;hi+=.1;}final path=Path();for(var i=0;i<v.length;i++){final x=42+(z.width-50)*(i/math.max(1,v.length-1));final y=8+(z.height-24)*(1-(v[i]-lo)/(hi-lo));if(i==0)path.moveTo(x,y);else path.lineTo(x,y);}c.drawPath(path,Paint()..color=col..style=PaintingStyle.stroke..strokeWidth=3..strokeCap=StrokeCap.round);final last=v.last;_txt(c,'$label ${kind==0?last.toStringAsFixed(0):last.toStringAsFixed(2)}${kind==0?' %':kind==3?' mW':' V'}',Offset(48,12),col);}
void _txt(Canvas c,String t,Offset o,Color col){final tp=TextPainter(text:TextSpan(text:t,style:TextStyle(fontSize:12,color:col)),textDirection:TextDirection.ltr)..layout();tp.paint(c,o);} @override bool shouldRepaint(covariant _HistoryPainter o)=>true;}

// =============================================================================
// PTX205R - card reader / polling / PSL
// =============================================================================

class PtxScreen extends StatefulWidget {final BleController c;const PtxScreen({super.key,required this.c});@override State<PtxScreen> createState()=>_PtxScreenState();}
class _PtxScreenState extends State<PtxScreen>{int tab=0;int lastCard=0;@override Widget build(BuildContext context){final c=widget.c;return Column(children:[_tabs(['Card reader','Polling','PSL'],tab,(v)=>setState(()=>tab=v)),const SizedBox(height:8),Expanded(child:switch(tab){0=>CardReaderScreen(c:c),1=>PollingScreen(c:c),_=>PslScreen(c:c)})]);}}


class NfcLogoPainter extends CustomPainter {
  final Color color;

  const NfcLogoPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final center = Offset(size.width / 2, size.height / 2);
    final base = size.shortestSide;

    // Four rounded "radio-wave" arcs inspired by the NFC Forum mark used
    // by the Android reference UI. Kept vector-based so it scales cleanly
    // on iPhone/iPad without an extra raster asset.
    for (var i = 0; i < 4; i++) {
      final inset = base * (0.12 + i * 0.09);
      final rect = Rect.fromCenter(
        center: center,
        width: base - inset * 2,
        height: base - inset * 2,
      );
      stroke.strokeWidth = base * (0.035 - i * 0.003);
      canvas.drawArc(
        rect,
        -0.78,
        1.56,
        false,
        stroke,
      );
      canvas.drawArc(
        rect,
        2.36,
        1.56,
        false,
        stroke,
      );
    }

    final dot = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, base * 0.035, dot);
  }

  @override
  bool shouldRepaint(covariant NfcLogoPainter oldDelegate) =>
      oldDelegate.color != color;
}

class CardReaderScreen extends StatelessWidget {
  final BleController c;

  const CardReaderScreen({
    super.key,
    required this.c,
  });

  @override
  Widget build(BuildContext context) {
    final card = c.card;
    final detected = card?.present == true;

    return Stack(
      children: [
        Center(
          child: CustomPaint(
            size: const Size(290, 290),
            painter: NfcLogoPainter(
              detected
                  ? riseColor.withOpacity(.5)
                  : Colors.black.withOpacity(.08),
            ),
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!c.cardService)
              const Text(
                'The connected firmware has no Card Reader service.',
              )
            else ...[
              Text(
                detected ? 'Card detected' : 'Waiting for a card…',
                style: TextStyle(
                  fontSize: 22,
                  color: detected
                      ? riseColor
                      : Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 10),
              if (detected && card != null) ...[
                _detail('Technology', techName(card.tech)),
                _detail('Protocol', protocolName(card.protocol)),
                _detail(
                  idLabel(card.tech),
                  card.idHex.isEmpty ? '-' : card.idHex,
                ),
                if (card.tech == 0)
                  _detail(
                    'SAK',
                    '0x${card.sak.toRadixString(16).padLeft(2, '0').toUpperCase()}',
                  ),
              ],
              const Divider(),
              const Text('Data exchange'),
              Expanded(
                child: c.exchanges.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Text(
                          'Nothing exchanged yet.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF65728A),
                          ),
                        ),
                      )
                    : ListView.separated(
                        itemCount: c.exchanges.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (_, i) {
                          final ex = c.exchanges[i];

                          final title = switch (ex.kind) {
                            1 => 'NDEF message read',
                            2 => 'NDEF read – unlock code matched, lock toggled',
                            3 => 'Data exchange failed',
                            4 => 'Card protocol has no data exchange',
                            _ => 'Unknown event (${ex.kind})',
                          };

                          final time =
                              '${ex.time.hour.toString().padLeft(2, '0')}:'
                              '${ex.time.minute.toString().padLeft(2, '0')}:'
                              '${ex.time.second.toString().padLeft(2, '0')}';

                          final truncated =
                              ex.data.length >= 128 ? '  (cut at 128 bytes)' : '';

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '$time  $title',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: ex.kind == 2
                                        ? riseColor
                                        : ex.kind == 3
                                            ? fallColor
                                            : const Color(0xFF65728A),
                                  ),
                                ),
                                if (ex.kind == 1 || ex.kind == 2)
                                  Text(
                                    describeNdef(ex.data),
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                if (ex.data.isNotEmpty)
                                  Text(
                                    '${ex.data.length} bytes: '
                                    '${hexBytes(ex.data)}$truncated',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF65728A),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class PollingScreen extends StatefulWidget {final BleController c;const PollingScreen({super.key,required this.c});@override State<PollingScreen> createState()=>_PollingScreenState();}
class _PollingScreenState extends State<PollingScreen>{
  static const modes={1:'NFC Forum',2:'EMVCo',3:'ISO'}; static const strategies={0:'Automatic',1:'NFC-A first',2:'NFC-B first',3:'NFC-F first',4:'NFC-V first'};static const bail={0:'No bail-out',1:'After NFC-A',2:'After NFC-A or B',3:'After NFC-A, B or F'};
  @override Widget build(BuildContext context){final c=widget.c,s=c.pollDraft;if(!c.pollService)return const Text('The connected firmware has no polling settings service.');if(s==null)return const Text('Loading the settings…');final busy=c.pollBusy||c.pollStatus?.restarting==true,changed=!s.sameAs(c.pollActive);return ListView(children:[const Text('Polling settings',style:TextStyle(fontSize:20,fontWeight:FontWeight.bold)),const SizedBox(height:12),const Text('The reader looks for cards in a loop. Changes only take effect after the reader is restarted: Apply stops it, switches the RF field off and starts it again with the new settings.',style:TextStyle(fontSize:12,color:Color(0xFF65728A))),_section('Discovery loop'),Wrap(spacing:8,runSpacing:8,children:[_pick('Poll mode',s.pollMode,modes,!busy,(v){s.pollMode=v;c.editPoll(s.copy());}),_pick('Polling strategy',s.initialTech,strategies,!busy,(v){s.initialTech=v;c.editPoll(s.copy());}),_pick('Loop',s.lpcd==0?0:s.lpcd==1?1:2,const {0:'Regular',1:'LPCD',2:'Hybrid'},!busy,(v){s.lpcd=v==0?0:v==1?1:2;c.editPoll(s.copy());}),_pick('Bail-out strategy',s.bailOut,bail,!busy,(v){s.bailOut=v;c.editPoll(s.copy());})]),_section('Technologies'),_tech('Type A',s.typeA,s.freqA,s.limitA,busy,(v){s.typeA=v;},(v){s.freqA=v;},(v){s.limitA=v;}),_tech('Type B',s.typeB,s.freqB,s.limitB,busy,(v){s.typeB=v;},(v){s.freqB=v;},(v){s.limitB=v;}),_tech('Type F 212 kbps',s.typeF212,s.freqF,s.limitF,busy,(v){s.typeF212=v;},(v){s.freqF=v;},(v){s.limitF=v;}),CheckboxListTile(value:s.typeF424,onChanged:busy?null:(v){s.typeF424=v??false;c.editPoll(s.copy());},title:const Text('Type F 424 kbps',style:TextStyle(fontSize:13)),subtitle:const Text('(frequency and limit as Type F 212)',style:TextStyle(fontSize:10)),controlAffinity:ListTileControlAffinity.leading,contentPadding:EdgeInsets.zero),_tech('Type V',s.typeV,s.freqV,s.limitV,busy,(v){s.typeV=v;},(v){s.freqV=v;},(v){s.limitV=v;}),_section('Protocols'),CheckboxListTile(value:s.disableIsoDep,onChanged:busy?null:(v){s.disableIsoDep=v??false;c.editPoll(s.copy());},title:const Text('Disable ISO-DEP'),contentPadding:EdgeInsets.zero),CheckboxListTile(value:s.disableNfcDep,onChanged:busy?null:(v){s.disableNfcDep=v??false;c.editPoll(s.copy());},title:const Text('Disable NFC-DEP (P2P)'),contentPadding:EdgeInsets.zero),CheckboxListTile(value:s.ddpc,onChanged:busy?null:(v){s.ddpc=v??false;c.editPoll(s.copy());},title:const Text('Enable DDPC (dynamic power control)'),contentPadding:EdgeInsets.zero),_section('Timing'),Row(children:[const Expanded(child:Text('Idle time between poll cycles')),SizedBox(width:90,child:TextFormField(initialValue:s.idleMs.toString(),enabled:!busy,keyboardType:TextInputType.number,onChanged:(v){s.idleMs=int.tryParse(v)??s.idleMs;c.editPoll(s.copy());},decoration:const InputDecoration(isDense:true,border:OutlineInputBorder()))),const Text(' ms')]),const SizedBox(height:12),if(changed&&!busy)const Text('Not applied yet: the reader still runs with the previous settings.',style:TextStyle(fontSize:12,color:fallColor)),const SizedBox(height:6),FilledButton(onPressed:changed&&!busy?c.applyPoll:null,child:Text(busy?'Restarting the reader…':'Apply and restart reader')),Row(children:[Expanded(child:OutlinedButton(onPressed:changed&&!busy?c.revertPoll:null,child:const Text('Revert edits'))),const SizedBox(width:8),Expanded(child:OutlinedButton(onPressed:!busy?c.restorePollDefaults:null,child:const Text('Firmware defaults')))]),if(c.pollMessage!=null)Text(c.pollMessage!,style:TextStyle(fontSize:11,color:c.pollMessage!.startsWith('Done')?riseColor:busy?const Color(0xFF65728A):fallColor)),const SizedBox(height:8),const Text('"Firmware defaults" (A, B, F 212 and V, every cycle, 5 devices, 100 ms) also restarts the reader. The settings are kept in RAM: after the board is reset it starts with the defaults again.',style:TextStyle(fontSize:10,color:Color(0xFF65728A)))]);}
  Widget _section(String s)=>Padding(padding:const EdgeInsets.only(top:18,bottom:8),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(s,style:const TextStyle(fontSize:16,fontWeight:FontWeight.bold)),const Divider()]));
  Widget _pick(String label,int value,Map<int,String> opts,bool en,ValueChanged<int> cb)=>Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(label,style:const TextStyle(fontSize:10,color:Color(0xFF65728A))),DropdownButton<int>(value:opts.containsKey(value)?value:opts.keys.first,onChanged:en?(v){if(v!=null)cb(v);}:null,items:[for(final e in opts.entries)DropdownMenuItem(value:e.key,child:Text(e.value,style:const TextStyle(fontSize:13)))])]);
  Widget _tech(String name,bool enabled,int freq,int limit,bool busy,ValueChanged<bool> e,ValueChanged<int> f,ValueChanged<int> l)=>Row(children:[Checkbox(value:enabled,onChanged:busy?null:(v){e(v??false);widget.c.editPoll(widget.c.pollDraft!.copy());}),Expanded(child:Text(name,style:const TextStyle(fontSize:13))),_miniDrop('Poll frequency',freq,{for(var i=1;i<=10;i++)i:i==1?'every cycle':'every ${i}th'},!busy,(v){f(v);widget.c.editPoll(widget.c.pollDraft!.copy());}),const SizedBox(width:6),_miniDrop('Device limit',limit,{for(final i in [1,2,3,4,5,6,8,10,15,20,30,40,50])i:'$i'},!busy,(v){l(v);widget.c.editPoll(widget.c.pollDraft!.copy());})]);
  Widget _miniDrop(String label,int v,Map<int,String> m,bool en,ValueChanged<int> cb)=>Column(children:[Text(label,style:const TextStyle(fontSize:9,color:Color(0xFF65728A))),DropdownButton<int>(value:m.containsKey(v)?v:m.keys.first,onChanged:en?(x){if(x!=null)cb(x);}:null,items:[for(final e in m.entries)DropdownMenuItem(value:e.key,child:Text(e.value,style:const TextStyle(fontSize:11)))])]);
}

class PslScreen extends StatefulWidget {final BleController c;const PslScreen({super.key,required this.c});@override State<PslScreen> createState()=>_PslScreenState();}
class _PslScreenState extends State<PslScreen>{@override Widget build(BuildContext context){final c=widget.c,p=c.qParams,st=c.pslStatus,running=(st?.state??0)!=0,measuring=st?.state==1;return ListView(children:[const Text('Antenna Q measurement',style:TextStyle(fontSize:20,fontWeight:FontWeight.bold)),const SizedBox(height:12),Row(children:[FilledButton(onPressed:!running&&p.valid?c.startQ:null,child:const Text('Start')),const SizedBox(width:8),OutlinedButton(onPressed:running?c.stopQ:null,child:const Text('Stop')),const Spacer(),Checkbox(value:c.qKeep,onChanged:(v)=>c.setQKeep(v??false)),const Text('Keep trace'),const SizedBox(width:8),OutlinedButton(onPressed:c.clearQ,child:const Text('Clear'))]),const SizedBox(height:10),Wrap(spacing:8,children:[_qPick('Span',p.spanKhz,[400,800,1200,1600,2000,2400],running,(v){p.spanKhz=v;c.setQParams(p);}),_qPick('Step',p.stepKhz,[1,2,5,10,20,25,50,100],running,(v){p.stepKhz=v;c.setQParams(p);}),_qPick('Average',p.avgIndex,List.generate(7,(i)=>i),running,(v){p.avgIndex=v;c.setQParams(p);},display:(v)=>['1 sample','2 samples','4 samples','8 samples','16 samples','32 samples','64 samples'][v])]),SwitchListTile(value:p.continuous,onChanged:running?null:(v){p.continuous=v;c.setQParams(p);},title:const Text('Continuous (repeat the sweep until Stop)',style:TextStyle(fontSize:13)),contentPadding:EdgeInsets.zero),if(!p.valid)Text('Span / step gives ${p.points} points; at most 1000 are possible.',style:const TextStyle(fontSize:11,color:fallColor)),Text(switch(st?.state){1=>'Measuring · sweep ${(st?.sweeps??0)+1}',2=>'Restarting the reader…',_=>'Reader running'},style:TextStyle(fontSize:13,color:measuring?traceColor:const Color(0xFF65728A))),if(measuring)LinearProgressIndicator(value:((c.qTrace?.amps.length??0)/(c.qRunParams?.points??1)).clamp(0,1).toDouble(),color:traceColor),if(c.qMessage!=null)Padding(padding:const EdgeInsets.symmetric(vertical:6),child:Text(c.qMessage!,style:const TextStyle(fontSize:11,color:Color(0xFF65728A)))),if(st!=null&&st.error!=0)Text('Last error 0x${st.error.toRadixString(16).padLeft(4,'0')} (ADC clipping: lower the amplitude / check the antenna)',style:const TextStyle(fontSize:11,color:fallColor)),SizedBox(height:300,child:CustomPaint(painter:QChartPainter(c.qKept+[if(c.qTrace!=null)c.qTrace!],c.qResult,c.qRunParams??c.qParams))),const SizedBox(height:8),Row(children:[Expanded(child:Column(children:[_detail('Center',c.qResult==null?'-':_mhz(c.qResult!.resHz)),_detail('Upper corner',c.qResult==null?'-':_mhz(c.qResult!.upHz))])),Expanded(child:Column(children:[_detail('Lower corner',c.qResult==null?'-':_mhz(c.qResult!.lowHz)),_detail('Q-factor',c.qResult==null?'-':c.qResult!.q.toStringAsFixed(2))]))]),const SizedBox(height:8),const Text('Starting a measurement stops the card reader and switches its RF field off. When you stop it, the field is switched off again and the reader restarts automatically.',style:TextStyle(fontSize:10,color:Color(0xFF65728A)))]);}
  Widget _qPick(String label,int value,List<int> values,bool running,ValueChanged<int> cb,{String Function(int)? display})=>Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(label,style:const TextStyle(fontSize:10,color:Color(0xFF65728A))),DropdownButton<int>(value:values.contains(value)?value:values.first,onChanged:running?null:(v){if(v!=null)cb(v);},items:[for(final v in values)DropdownMenuItem(value:v,child:Text(display?.call(v)??'$v kHz',style:const TextStyle(fontSize:12)))])]);
  String _mhz(int hz)=>hz==0?'-':'${(hz/1e6).toStringAsFixed(3)} MHz';
}
class QChartPainter extends CustomPainter{final List<QTrace>traces;final QResult?result;final QParams p;QChartPainter(this.traces,this.result,this.p);double db(int a)=>20*math.log(math.max(a,1)/1000)/math.ln10;@override void paint(Canvas c,Size s){final left=42.0,top=16.0,right=8.0,bottom=28.0,w=s.width-left-right,h=s.height-top-bottom;if(w<=0||h<=0)return;final vals=traces.expand((t)=>t.amps).map(db).toList();double lo=vals.isEmpty?-40:vals.reduce(math.min)-1,hi=vals.isEmpty?-10:vals.reduce(math.max)+1;if(hi-lo<10)lo=hi-10;double xOf(double hz)=>left+w*(hz-p.startHz)/(p.spanKhz*1000);double yOf(double d)=>top+h*(1-(d-lo)/(hi-lo));final gp=Paint()..color=const Color(0xFFD7DFEA)..strokeWidth=1;for(var i=0;i<=5;i++){final y=top+h*i/5;c.drawLine(Offset(left,y),Offset(left+w,y),gp);final v=hi-(hi-lo)*i/5;_paintText(c,v.toStringAsFixed(0),Offset(8,y-7),const Color(0xFF65728A),10);}for(var i=0;i<=4;i++){final x=left+w*i/4;c.drawLine(Offset(x,top),Offset(x,top+h),gp);}for(var ti=0;ti<traces.length;ti++){final t=traces[ti];if(t.amps.length<2)continue;final path=Path();for(var i=0;i<t.amps.length;i++){final x=xOf(t.startHz+i*t.stepHz.toDouble()),y=yOf(db(t.amps[i]));if(i==0)path.moveTo(x,y);else path.lineTo(x,y);}c.drawPath(path,Paint()..color=traceColor.withOpacity(ti==traces.length-1?1:.3)..style=PaintingStyle.stroke..strokeWidth=ti==traces.length-1?2.5:1.3);}final r=result,cur=traces.isEmpty?null:traces.last;if(r!=null&&cur!=null){for(final m in [(r.lowHz,'Lower'),(r.resHz,'Center'),(r.upHz,'Upper')]){final hz=m.$1;if(hz==0)continue;final x=xOf(hz.toDouble());c.drawLine(Offset(x,top),Offset(x,top+h),Paint()..color=markColor.withOpacity(.45)..strokeWidth=1);final idx=((hz-cur.startHz)/cur.stepHz).round();if(idx>=0&&idx<cur.amps.length)c.drawCircle(Offset(x,yOf(db(cur.amps[idx]))),5,Paint()..color=markColor);_paintText(c,'${m.$2} ${(hz/1e6).toStringAsFixed(3)}',Offset((x-30).clamp(left,left+w-70),top+(m.$2=='Center'?0:m.$2=='Lower'?15:30)),traceColor,9);}}if(traces.isEmpty)_paintText(c,'press Start to measure',Offset(left+w/2-60,top+h/2),const Color(0xFF65728A),12);}
void _paintText(Canvas c,String t,Offset o,Color col,double fs){final tp=TextPainter(text:TextSpan(text:t,style:TextStyle(fontSize:fs,color:col)),textDirection:TextDirection.ltr)..layout();tp.paint(c,o);}@override bool shouldRepaint(covariant QChartPainter o)=>true;}

// =============================================================================
// OEM
// =============================================================================

class OemScreen extends StatefulWidget {final BleController c;const OemScreen({super.key,required this.c});@override State<OemScreen> createState()=>_OemScreenState();}
class _OemScreenState extends State<OemScreen>{String? openGroup;@override Widget build(BuildContext context){final c=widget.c;if(!c.oemService)return const Text('The connected firmware has no OEM Config service.');final st=c.oemStatus;if(c.oemDraft.isEmpty)return const Center(child:Text('Loading OEM parameters…'));final blocked=st?.rfField==true||st?.busy==true||(st?.writeCount!=null&&st!.writeCount!>=st.maxCycles);return ListView(children:[const Text('OEM parameters',style:TextStyle(fontSize:20,fontWeight:FontWeight.bold)),const SizedBox(height:6),Text('Chip set: ${st?.chipValid==true?'valid':'unknown'}  •  NVM writes: ${st?.writeCount?.toString()??'--'} / ${st?.maxCycles??0}',style:const TextStyle(fontSize:12,color:Color(0xFF65728A))),if(st?.rfField==true)const Padding(padding:EdgeInsets.only(top:6),child:Text('Remove the WLC field before writing OEM parameters.',style:TextStyle(color:fallColor))),const SizedBox(height:8),for(final g in OemCatalog.groups)ExpansionTile(initiallyExpanded:openGroup==g,onExpansionChanged:(v)=>setState(()=>openGroup=v?g:null),title:Text(g,style:const TextStyle(fontWeight:FontWeight.w600)),children:[for(final p in OemCatalog.params.where((x)=>x.group==g))_OemParamTile(c:c,p:p)]),const Divider(),CheckboxListTile(value:c.oemAck,onChanged:c.oemUploading?null:(v)=>c.setOemAck(v??false),title:const Text('I understand that uploading writes the RRQ36031 NVM and consumes one write cycle.',style:TextStyle(fontSize:12)),controlAffinity:ListTileControlAffinity.leading,contentPadding:EdgeInsets.zero),if(OemCatalog.params.any((p)=>p.risky))SwitchListTile(value:c.oemUnlockRisky,onChanged:(v)=>c.setOemUnlockRisky(v),title:const Text('Unlock risky parameters'),contentPadding:EdgeInsets.zero),if(c.oemMessage!=null)Padding(padding:const EdgeInsets.symmetric(vertical:6),child:Text(c.oemMessage!,style:TextStyle(fontSize:12,color:c.oemMessageIsError?fallColor:riseColor))),FilledButton(onPressed:!blocked&&c.oemAck&&!c.oemUploading?c.uploadOem:null,child:Text(c.oemUploading?'Uploading…':'Upload parameters to chip')),OutlinedButton(onPressed:c.oemUploading?null:c.revertOem,child:const Text('Revert to firmware defaults')),const SizedBox(height:8),const Text('The phone first stages the complete parameter table. Only after every chunk is accepted is the commit command sent to the firmware.',style:TextStyle(fontSize:10,color:Color(0xFF65728A)))]);}}
class _OemParamTile extends StatelessWidget{final BleController c;final OemParam p;const _OemParamTile({required this.c,required this.p});@override Widget build(BuildContext context){final v=c.oemDraft[p.id]??0,locked=p.risky&&!c.oemUnlockRisky;Widget editor;if(p.kind==OemKind.boolValue){editor=Switch(value:v!=0,onChanged:locked?null:(b)=>c.setOemValue(p.id,b?1:0));}else if(p.kind==OemKind.enumValue&&p.options.isNotEmpty){final options=p.options;final selected=options.any((o)=>o.value==v)?v:options.first.value;editor=DropdownButton<int>(value:selected,onChanged:locked?null:(x){if(x!=null)c.setOemValue(p.id,x);},items:[for(final o in options)DropdownMenuItem(value:o.value,child:ConstrainedBox(constraints:const BoxConstraints(maxWidth:220),child:Text(o.label,overflow:TextOverflow.ellipsis,style:const TextStyle(fontSize:12))))]);}else{editor=SizedBox(width:95,child:TextFormField(initialValue:p.hex?'0x${v.toRadixString(16)}':'$v',enabled:!locked,keyboardType:TextInputType.number,onFieldSubmitted:(s){final x=p.hex?int.tryParse(s.replaceFirst('0x',''),radix:16):int.tryParse(s);if(x!=null&&x>=p.min&&x<=p.max)c.setOemValue(p.id,x);},decoration:InputDecoration(isDense:true,suffixText:p.unit.isEmpty?null:p.unit,border:const OutlineInputBorder())));}return Padding(padding:const EdgeInsets.symmetric(horizontal:8,vertical:6),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Row(children:[Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(p.title,style:const TextStyle(fontSize:13,fontWeight:FontWeight.w600)),Text('${p.key} · ID ${p.id}',style:const TextStyle(fontSize:9,color:Color(0xFF7B879E)))])),editor]),if(p.help.isNotEmpty)Padding(padding:const EdgeInsets.only(top:4),child:Text(p.help,style:const TextStyle(fontSize:10,color:Color(0xFF65728A))))]));}}

// =============================================================================
// RA6B1 / RSSI
// =============================================================================

class Ra6b1Screen extends StatefulWidget {final BleController c;const Ra6b1Screen({super.key,required this.c});@override State<Ra6b1Screen> createState()=>_Ra6b1ScreenState();}
class _Ra6b1ScreenState extends State<Ra6b1Screen>{int tab=0;@override void dispose(){widget.c.setRssiMonitoring(false);super.dispose();}@override Widget build(BuildContext context){final c=widget.c;return Column(children:[_tabs(['Info','Proximity'],tab,(v){setState(()=>tab=v);if(v==0)c.setRssiMonitoring(false);}),const SizedBox(height:8),Expanded(child:tab==0?_RaInfo(c):_Proximity(c))]);}}
class _RaInfo extends StatelessWidget{final BleController c;const _RaInfo(this.c);@override Widget build(BuildContext context)=>ListView(children:[const Text('Bluetooth LE',style:TextStyle(fontSize:18,fontWeight:FontWeight.bold)),_detail('Device name',c.connectedName??'-'),_detail('Identifier',c.connectedId??'-'),_detail('Pairing','managed by iOS / CoreBluetooth'),_detail('Signal at scan',c.devices.where((d)=>d.id==c.connectedId).firstOrNull?.rssi.toString()??'-'),const Divider(),const Text('Battery service traffic',style:TextStyle(fontWeight:FontWeight.w600)),_detail('Reads OK','${c.reads}'),_detail('Notifications','${c.notifications}'),_detail('Read failures','${c.failedReads}'),const Divider(),const Text('Services seen by the phone',style:TextStyle(fontWeight:FontWeight.w600)),for(final s in c.services)Padding(padding:const EdgeInsets.symmetric(vertical:4),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(serviceName(normUuid(s.serviceId)),style:const TextStyle(fontSize:13)),Text(normUuid(s.serviceId),style:const TextStyle(fontSize:10,color:Color(0xFF65728A)))]))]);}
class _Proximity extends StatelessWidget{final BleController c;const _Proximity(this.c);double? get dist=>c.filteredRssi==null?null:math.pow(10,(-59-c.filteredRssi!)/(10*2)).toDouble();@override Widget build(BuildContext context)=>Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[const Text('Distance from the phone to the board, estimated from the RSSI of the connection.',style:TextStyle(fontSize:13,color:Color(0xFF65728A))),const SizedBox(height:12),Align(alignment:Alignment.centerLeft,child:FilledButton(onPressed:()=>c.setRssiMonitoring(!c.rssiMonitoring),child:Text(c.rssiMonitoring?'Stop monitoring':'Start monitoring'))),if(c.rssiMonitoring)...[const SizedBox(height:16),ProximityBar(distance:dist,rssi:c.filteredRssi)],if(c.rssiHistory.isNotEmpty)Expanded(child:CustomPaint(painter:RssiChartPainter(c.rssiHistory),child:Container()))]);}
class ProximityBar extends StatelessWidget{final double?distance,rssi;const ProximityBar({super.key,this.distance,this.rssi});@override Widget build(BuildContext context){final pos=((distance??0)/15).clamp(0,1).toDouble();return Column(children:[Row(children:[const Expanded(child:Text('Distance',style:TextStyle(fontSize:12,color:Color(0xFF65728A)))),Text(distance==null?'no signal reading':'≈ ${distance!.toStringAsFixed(1)} m   (${rssi!.round()} dBm)',style:const TextStyle(fontWeight:FontWeight.w600))]),const SizedBox(height:5),LayoutBuilder(builder:(_,b)=>Stack(alignment:Alignment.centerLeft,children:[Container(height:10,decoration:BoxDecoration(borderRadius:BorderRadius.circular(5),gradient:const LinearGradient(colors:[Colors.green,Colors.yellow,Colors.red]))),Positioned(left:(b.maxWidth-18)*pos,child:Container(width:18,height:18,decoration:const BoxDecoration(shape:BoxShape.circle,color:Colors.white),child:Center(child:Container(width:12,height:12,decoration:const BoxDecoration(shape:BoxShape.circle,color:Color(0xFF263238))))))])),const Row(mainAxisAlignment:MainAxisAlignment.spaceBetween,children:[Text('0 m',style:TextStyle(fontSize:10)),Text('5 m',style:TextStyle(fontSize:10)),Text('10 m',style:TextStyle(fontSize:10)),Text('15+ m',style:TextStyle(fontSize:10))])]);}}
class RssiChartPainter extends CustomPainter{final List<RssiSample>s;RssiChartPainter(this.s);@override void paint(Canvas c,Size z){if(s.length<2)return;final vals=s.take(240).map((e)=>e.filtered).toList();var lo=vals.reduce(math.min)-3,hi=vals.reduce(math.max)+3;final p=Path();for(var i=0;i<vals.length;i++){final x=30+(z.width-40)*i/(vals.length-1),y=10+(z.height-30)*(1-(vals[i]-lo)/(hi-lo));if(i==0)p.moveTo(x,y);else p.lineTo(x,y);}c.drawPath(p,Paint()..color=renesasBlue..style=PaintingStyle.stroke..strokeWidth=2);}@override bool shouldRepaint(covariant RssiChartPainter o)=>true;}
