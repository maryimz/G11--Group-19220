import 'package:firebase_database/firebase_database.dart';

class FirebaseService {
  final _ref = FirebaseDatabase.instance.ref('florigen');

  // ── LIVE DATA STREAM ──
  Stream<Map<String, dynamic>> liveStream() {
    return _ref.child('live').onValue.map((e) =>
        Map<String, dynamic>.from(e.snapshot.value as Map? ?? {}));
  }

  // ── SYSTEM ON/OFF ──
  Future<void> setSystemOn(bool v) =>
      _ref.child('actuators/systemOn').set(v);

  // ── SWITCH PLANT ──
  Future<void> switchPlant(String plant) async {
    await _ref.child('control/activePlant').set(plant);
    await _ref.child('control/manualOverride').set(false);
  }

  // ── MANUAL ACTUATOR ──
  Future<void> setActuator(String name, bool v) async {
    await _ref.child('actuators/$name').set(v);
    await _ref.child('control/manualOverride').set(true);
  }

  // ── AUTO MODE ──
  Future<void> setAutoMode() =>
      _ref.child('control/manualOverride').set(false);

  // ── GET HISTORY ──
  Future<List<Map<String, dynamic>>> getHistory(int lastN) async {
    final snap = await _ref.child('history').limitToLast(lastN).get();
    List<Map<String, dynamic>> list = [];
    if (snap.exists) {
      for (var child in snap.children) {
        list.add(Map<String, dynamic>.from(child.value as Map));
      }
    }
    return list;
  }

  // ── GET CURRENT ALERT ──
  Future<String> getCurrentAlert() async {
    final snap = await _ref.child('alerts/current').get();
    return snap.value?.toString() ?? 'OK';
  }

  // ── ACTIVE PLANT STREAM ──
  Stream<String> activePlantStream() {
    return _ref.child('control/activePlant').onValue.map((e) =>
        e.snapshot.value?.toString() ?? 'hibiscus');
  }

  // ── SYSTEM STATUS STREAM ──
  Stream<bool> systemOnStream() {
    return _ref.child('actuators/systemOn').onValue.map((e) =>
        e.snapshot.value as bool? ?? true);
  }

  // ── ACTUATORS STREAM ──
  Stream<Map<String, dynamic>> actuatorsStream() {
    return _ref.child('actuators').onValue.map((e) =>
        Map<String, dynamic>.from(e.snapshot.value as Map? ?? {}));
  }
}