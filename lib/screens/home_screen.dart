import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/firebase_service.dart';
import 'monitoring_screen.dart';
import 'control_screen.dart';
import 'plant_screen.dart';
import 'ai_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _fb = FirebaseService();
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const _DashboardTab(),
    const MonitoringScreen(),
    const ControlScreen(),
    const PlantScreen(),
    const AIScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        backgroundColor: Colors.white,
        indicatorColor: const Color(0xFF1D9E75).withOpacity(0.2),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.show_chart), label: 'Monitor'),
          NavigationDestination(icon: Icon(Icons.tune), label: 'Control'),
          NavigationDestination(icon: Icon(Icons.eco), label: 'Plants'),
          NavigationDestination(icon: Icon(Icons.psychology), label: 'AI'),
        ],
      ),
    );
  }
}

class _DashboardTab extends StatelessWidget {
  const _DashboardTab();

  @override
  Widget build(BuildContext context) {
    final fb = FirebaseService();
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1D9E75),
        title: Text('Florigen Control 🌿',
            style: GoogleFonts.poppins(
                color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          StreamBuilder<bool>(
            stream: fb.systemOnStream(),
            builder: (context, snap) {
              final isOn = snap.data ?? true;
              return Row(children: [
                Text(isOn ? 'ON' : 'OFF',
                    style: const TextStyle(color: Colors.white)),
                Switch(
                  value: isOn,
                  onChanged: (v) => fb.setSystemOn(v),
                  activeColor: Colors.white,
                ),
              ]);
            },
          ),
        ],
      ),
      body: StreamBuilder<Map<String, dynamic>>(
        stream: fb.liveStream(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator(
                color: Color(0xFF1D9E75)));
          }
          final data = snap.data!;
          final temp = (data['temperature'] ?? 0.0).toDouble();
          final hum  = (data['humidity']    ?? 0.0).toDouble();
          final soil = (data['soilMoisture'] ?? 0.0).toDouble();
          final time = data['timestamp']?.toString() ?? '--';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Alert Banner
                StreamBuilder<String>(
                  stream: fb.activePlantStream(),
                  builder: (context, plantSnap) {
                    final plant = plantSnap.data ?? 'hibiscus';
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1D9E75).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(children: [
                        const Icon(Icons.eco, color: Color(0xFF1D9E75)),
                        const SizedBox(width: 8),
                        Text('Active Plant: ${plant.toUpperCase()}',
                            style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF0F6E56))),
                      ]),
                    );
                  },
                ),
                const SizedBox(height: 16),
                Text('Live Readings', style: GoogleFonts.poppins(
                    fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                // Sensor Cards
                Row(children: [
                  Expanded(child: _SensorCard(
                    label: 'Temperature',
                    value: '${temp.toStringAsFixed(1)}°C',
                    icon: Icons.thermostat,
                    color: temp > 35 ? Colors.red : temp < 20
                        ? Colors.blue : const Color(0xFF1D9E75),
                    min: 25, max: 35, current: temp,
                  )),
                  const SizedBox(width: 12),
                  Expanded(child: _SensorCard(
                    label: 'Humidity',
                    value: '${hum.toStringAsFixed(1)}%',
                    icon: Icons.water_drop,
                    color: hum < 60 ? Colors.orange : const Color(0xFF1D9E75),
                    min: 60, max: 65, current: hum,
                  )),
                ]),
                const SizedBox(height: 12),
                _SensorCard(
                  label: 'Soil Moisture',
                  value: '${soil.toStringAsFixed(1)}%',
                  icon: Icons.grass,
                  color: soil < 24 ? Colors.red : soil < 28
                      ? Colors.orange : const Color(0xFF1D9E75),
                  min: 28, max: 40, current: soil,
                  wide: true,
                ),
                const SizedBox(height: 12),
                Text('Last update: $time',
                    style: GoogleFonts.poppins(
                        fontSize: 12, color: Colors.grey)),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SensorCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  final double min, max, current;
  final bool wide;

  const _SensorCard({
    required this.label, required this.value,
    required this.icon, required this.color,
    required this.min, required this.max, required this.current,
    this.wide = false,
  });

  @override
  Widget build(BuildContext context) {
    final progress = ((current - min) / (max - min)).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 6),
            Text(label, style: GoogleFonts.poppins(
                fontSize: 12, color: Colors.grey[600])),
          ]),
          const SizedBox(height: 8),
          Text(value, style: GoogleFonts.poppins(
              fontSize: 24, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(color),
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    );
  }
}