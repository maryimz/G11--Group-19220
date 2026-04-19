import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BLEService {
  static const serviceUUID = '12345678-1234-1234-1234-123456789abc';
  static const charUUID    = 'abcdef01-1234-1234-1234-123456789abc';

  BluetoothDevice? _device;
  BluetoothCharacteristic? _char;
  bool get isConnected => _device != null && _char != null;

  // ── SCAN & CONNECT ──
  Future<bool> connect() async {
    try {
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 10));
      await for (var results in FlutterBluePlus.scanResults) {
        for (var r in results) {
          if (r.device.platformName == 'FlorigenESP32') {
            await FlutterBluePlus.stopScan();
            _device = r.device;
            await _device!.connect();
            await _discoverChar();
            return true;
          }
        }
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<void> _discoverChar() async {
    final services = await _device!.discoverServices();
    for (var s in services) {
      if (s.uuid.toString() == serviceUUID) {
        for (var c in s.characteristics) {
          if (c.uuid.toString() == charUUID) {
            _char = c;
          }
        }
      }
    }
  }

  // ── DISCONNECT ──
  Future<void> disconnect() async {
    await _device?.disconnect();
    _device = null;
    _char = null;
  }

  // ── SEND COMMAND ──
  Future<void> sendCommand(String cmd) async {
    if (_char == null) return;
    await _char!.write(cmd.codeUnits);
  }

  // ── LIVE DATA STREAM ──
  Stream<String> liveStream() {
    _char?.setNotifyValue(true);
    return _char!.onValueReceived.map((v) => String.fromCharCodes(v));
    // Format: "28.4,62.1,35,OK"
  }

  // ── HELPER COMMANDS ──
  Future<void> setSystemOn(bool v)       => sendCommand(v ? 'SYS:ON' : 'SYS:OFF');
  Future<void> switchPlant(String plant) => sendCommand('PLANT:$plant');
  Future<void> setFan(bool v)            => sendCommand(v ? 'FAN:ON' : 'FAN:OFF');
  Future<void> setPump(bool v)           => sendCommand(v ? 'PUMP:ON' : 'PUMP:OFF');
  Future<void> setMister(bool v)         => sendCommand(v ? 'MISTER:ON' : 'MISTER:OFF');
  Future<void> setLight(bool v)          => sendCommand(v ? 'LIGHT:ON' : 'LIGHT:OFF');
}