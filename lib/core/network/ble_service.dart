import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_ble_peripheral/flutter_ble_peripheral.dart';
import 'package:permission_handler/permission_handler.dart';
import '../constants/ble_constants.dart';

class BleService {
  final _peripheral = FlutterBlePeripheral();
  final Set<int> _nearby = {};
  bool _running = false;

  Future<bool> _ensurePermissions() async {
    final statuses = await [
      Permission.bluetoothAdvertise,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.locationWhenInUse,
    ].request();
    return statuses.values.every((s) => s.isGranted);
  }

  /// 내 user_id 광고 + 주변 스캔 시작. 새 발견마다 onUpdate 호출.
  Future<void> start(int myUserId, void Function(Set<int>) onUpdate) async {
    if (_running) return;
    if (!await _ensurePermissions()) {
      throw Exception('블루투스/위치 권한이 필요해요.');
    }
    _running = true;
    _nearby.clear();

    // 1) 광고: manufacturerData에 user_id를 4바이트로
    final idBytes = (ByteData(4)..setUint32(0, myUserId)).buffer.asUint8List();
    await _peripheral.start(
      advertiseData: AdvertiseData(
        serviceUuid: BleConstants.serviceUuid,
        manufacturerId: BleConstants.manufacturerId,
        manufacturerData: idBytes,
      ),
    );

    // 2) 스캔: 같은 serviceUuid만 잡고, 광고에서 user_id 추출
    FlutterBluePlus.scanResults.listen((results) {
      for (final r in results) {
        final mfg = r.advertisementData.manufacturerData[BleConstants.manufacturerId];
        if (mfg == null || mfg.length < 4) continue;
        final uid = ByteData.sublistView(Uint8List.fromList(mfg)).getUint32(0);
        if (uid != myUserId && _nearby.add(uid)) {
          debugPrint('### 주변 발견: $uid (전체: $_nearby)');
          onUpdate(Set.of(_nearby));
        }
      }
    });
    await FlutterBluePlus.startScan(
      withServices: [Guid(BleConstants.serviceUuid)],
      continuousUpdates: true,
    );
  }

  Future<void> stop() async {
    if (!_running) return;
    _running = false;
    await _peripheral.stop();
    await FlutterBluePlus.stopScan();
    _nearby.clear();
  }

  Set<int> get nearby => Set.of(_nearby);
}