import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/firebase_service.dart';

class ControlScreen extends StatefulWidget {
  const ControlScreen({super.key});

  @override
  State<ControlScreen> createState() => _ControlScreenState();
}

class _ControlScreenState extends State<ControlScreen> {
  final _fb = FirebaseService();
  bool _manualMode = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1D9E75),
        title: Text('Manual Control',
            style: GoogleFonts.poppins(
                color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: StreamBuilder<Map<String, dynamic>>(
        stream: _fb.actuatorsStream(),
        builder: (context, snap) {
          final actuators = snap.data ?? {};
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Auto/Manual Toggle
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Control Mode',
                              style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.bold, fontSize: 16)),
                          Text(_manualMode ? 'Manual' : 'Automatic',
                              style: GoogleFonts.poppins(
                                  color: _manualMode
                                      ? Colors.orange
                                      : const Color(0xFF1D9E75))),
                        ],
                      ),
                      Switch(
                        value: _manualMode,
                        activeColor: Colors.orange,
                        onChanged: (v) {
                          setState(() => _manualMode = v);
                          if (!v) _fb.setAutoMode();
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Actuator Controls
                ...['fan', 'light', 'pump', 'mister', 'drain'].map((name) =>
                  _ActuatorTile(
                    name: name,
                    isOn: actuators[name] as bool? ?? false,
                    enabled: _manualMode,
                    onChanged: (v) => _fb.setActuator(name, v),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ActuatorTile extends StatelessWidget {
  final String name;
  final bool isOn, enabled;
  final ValueChanged<bool> onChanged;

  const _ActuatorTile({
    required this.name, required this.isOn,
    required this.enabled, required this.onChanged,
  });

  IconData get _icon {
    switch (name) {
      case 'fan':    return Icons.air;
      case 'light':  return Icons.lightbulb;
      case 'pump':   return Icons.water;
      case 'mister': return Icons.cloud;
      case 'drain':  return Icons.outbond;
      default:       return Icons.device_unknown;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isOn && enabled
              ? const Color(0xFF1D9E75)
              : Colors.transparent,
        ),
      ),
      child: Row(
        children: [
          Icon(_icon,
              color: isOn && enabled
                  ? const Color(0xFF1D9E75)
                  : Colors.grey,
              size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name.toUpperCase(),
                    style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                Text(enabled ? (isOn ? 'Running' : 'Stopped') : 'Auto mode',
                    style: GoogleFonts.poppins(
                        fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
          Switch(
            value: isOn,
            activeColor: const Color(0xFF1D9E75),
            onChanged: enabled ? onChanged : null,
          ),
        ],
      ),
    );
  }
}