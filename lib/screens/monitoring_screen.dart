import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/firebase_service.dart';

class MonitoringScreen extends StatefulWidget {
  const MonitoringScreen({super.key});

  @override
  State<MonitoringScreen> createState() => _MonitoringScreenState();
}

class _MonitoringScreenState extends State<MonitoringScreen> {
  final _fb = FirebaseService();
  List<Map<String, dynamic>> _history = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final data = await _fb.getHistory(21);
    setState(() {
      _history = data;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1D9E75),
        title: Text('Monitoring',
            style: GoogleFonts.poppins(
                color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadHistory,
          )
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(
              color: Color(0xFF1D9E75)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _ChartCard(
                    title: 'Temperature (°C)',
                    color: Colors.orange,
                    data: _history.map((r) =>
                        (r['temp'] as num?)?.toDouble() ?? 0).toList(),
                    minY: 10, maxY: 45,
                  ),
                  const SizedBox(height: 16),
                  _ChartCard(
                    title: 'Humidity (% RH)',
                    color: Colors.blue,
                    data: _history.map((r) =>
                        (r['hum'] as num?)?.toDouble() ?? 0).toList(),
                    minY: 0, maxY: 100,
                  ),
                  const SizedBox(height: 16),
                  _ChartCard(
                    title: 'Soil Moisture (%)',
                    color: const Color(0xFF1D9E75),
                    data: _history.map((r) =>
                        (r['soil'] as num?)?.toDouble() ?? 0).toList(),
                    minY: 0, maxY: 100,
                  ),
                ],
              ),
            ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  final String title;
  final Color color;
  final List<double> data;
  final double minY, maxY;

  const _ChartCard({
    required this.title, required this.color,
    required this.data, required this.minY, required this.maxY,
  });

  @override
  Widget build(BuildContext context) {
    final spots = data.asMap().entries.map((e) =>
        FlSpot(e.key.toDouble(), e.value)).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 16),
          SizedBox(
            height: 150,
            child: spots.isEmpty
                ? Center(child: Text('No data yet',
                    style: GoogleFonts.poppins(color: Colors.grey)))
                : LineChart(LineChartData(
                    minY: minY, maxY: maxY,
                    gridData: const FlGridData(show: true),
                    borderData: FlBorderData(show: false),
                    titlesData: const FlTitlesData(show: false),
                    lineBarsData: [
                      LineChartBarData(
                        spots: spots,
                        isCurved: true,
                        color: color,
                        barWidth: 2,
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(
                          show: true,
                          color: color.withOpacity(0.1),
                        ),
                      ),
                    ],
                  )),
          ),
        ],
      ),
    );
  }
}