import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/firebase_service.dart';
import '../services/ai_service.dart';

class AIScreen extends StatefulWidget {
  const AIScreen({super.key});

  @override
  State<AIScreen> createState() => _AIScreenState();
}

class _AIScreenState extends State<AIScreen> {
  final _fb = FirebaseService();
  final _ai = AIService();
  PlantHealthReport? _report;
  bool _loading = false;

  Future<void> _analyze() async {
  setState(() => _loading = true);
  try {
    // ← بيجيب الـ active plant من Firebase
    final plant = await _fb.activePlantStream().first;
    final history = await _fb.getHistory(21);
    final alert = await _fb.getCurrentAlert();
    final report = await _ai.analyze(
      plant: plant,
      history: history,
      currentAlert: alert,
    );
    setState(() => _report = report);
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')));
  }
  setState(() => _loading = false);
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1D9E75),
        title: Text('AI Plant Health',
            style: GoogleFonts.poppins(
                color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _loading ? null : _analyze,
                icon: _loading
                    ? const SizedBox(width: 20, height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.psychology, color: Colors.white),
                label: Text(
                    _loading ? 'Analyzing...' : 'Analyze Plant Health',
                    style: GoogleFonts.poppins(
                        color: Colors.white, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1D9E75),
                  padding: const EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_report != null) ...[
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(children: [
                  Text('Health Score',
                      style: GoogleFonts.poppins(color: Colors.grey)),
                  const SizedBox(height: 8),
                  Text('${_report!.healthScore}%',
                      style: GoogleFonts.poppins(
                          fontSize: 48, fontWeight: FontWeight.bold,
                          color: _report!.statusColor)),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: _report!.statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(_report!.status,
                        style: GoogleFonts.poppins(
                            color: _report!.statusColor,
                            fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 12),
                  Text(_report!.summary,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(color: Colors.grey[600])),
                ]),
              ),
              const SizedBox(height: 16),
              if (_report!.issues.isNotEmpty)
                _ListCard(title: '⚠️ Issues', items: _report!.issues,
                    color: Colors.orange),
              const SizedBox(height: 16),
              if (_report!.recommendations.isNotEmpty)
                _ListCard(title: '✅ Recommendations',
                    items: _report!.recommendations,
                    color: const Color(0xFF1D9E75)),
            ] else
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(children: [
                  const Icon(Icons.psychology_outlined,
                      size: 64, color: Color(0xFF1D9E75)),
                  const SizedBox(height: 16),
                  Text('Press the button to analyze\nyour plant health',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(color: Colors.grey)),
                ]),
              ),
          ],
        ),
      ),
    );
  }
}

class _ListCard extends StatelessWidget {
  final String title;
  final List<String> items;
  final Color color;
  const _ListCard({required this.title, required this.items, required this.color});

  @override
  Widget build(BuildContext context) {
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
          const SizedBox(height: 12),
          ...items.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.circle, size: 8, color: color),
                const SizedBox(width: 8),
                Expanded(child: Text(item,
                    style: GoogleFonts.poppins(fontSize: 13))),
              ],
            ),
          )),
        ],
      ),
    );
  }
}