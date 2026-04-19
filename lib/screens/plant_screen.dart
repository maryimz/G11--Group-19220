import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/firebase_service.dart';

class PlantScreen extends StatelessWidget {
  const PlantScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final fb = FirebaseService();
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1D9E75),
        title: Text('Plant Database',
            style: GoogleFonts.poppins(
                color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: StreamBuilder<String>(
        stream: fb.activePlantStream(),
        builder: (context, snap) {
          final active = snap.data ?? 'hibiscus';
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _PlantCard(
                  name: 'Hibiscus sabdariffa',
                  arabicName: 'كركدي',
                  emoji: '🌺',
                  isActive: active == 'hibiscus',
                  tempDay: '25–35°C',
                  tempNight: '18–21°C',
                  humidity: '60–65%',
                  soil: '28–40%',
                  onSelect: () => fb.switchPlant('hibiscus'),
                ),
                const SizedBox(height: 16),
                _PlantCard(
                  name: 'Helianthus annuus',
                  arabicName: 'عباد الشمس',
                  emoji: '🌻',
                  isActive: active == 'sunflower',
                  tempDay: '22–30°C',
                  tempNight: '15–19°C',
                  humidity: '50–60%',
                  soil: '28–40%',
                  onSelect: () => fb.switchPlant('sunflower'),
                ),
                const SizedBox(height: 16),
                _PlantCard(
                  name: 'Colocasia esculenta',
                  arabicName: 'قلقاس',
                  emoji: '🌿',
                  isActive: active == 'taro',
                  tempDay: '24–30°C',
                  tempNight: '18–22°C',
                  humidity: '60–65%',
                  soil: '80–90%',
                  onSelect: () => fb.switchPlant('taro'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _PlantCard extends StatelessWidget {
  final String name, arabicName, emoji;
  final String tempDay, tempNight, humidity, soil;
  final bool isActive;
  final VoidCallback onSelect;

  const _PlantCard({
    required this.name, required this.arabicName, required this.emoji,
    required this.tempDay, required this.tempNight,
    required this.humidity, required this.soil,
    required this.isActive, required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isActive ? const Color(0xFF1D9E75) : Colors.transparent,
          width: 2,
        ),
        boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8)],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 40)),
              const SizedBox(width: 16),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold, fontSize: 14)),
                  Text(arabicName, style: GoogleFonts.poppins(
                      color: const Color(0xFF1D9E75), fontSize: 16,
                      fontWeight: FontWeight.w600)),
                ],
              )),
              if (isActive)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1D9E75),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('Active',
                      style: GoogleFonts.poppins(
                          color: Colors.white, fontSize: 12)),
                ),
            ],
          ),
          const SizedBox(height: 16),
          _InfoRow('Temp (Day)',   tempDay,   Icons.wb_sunny),
          _InfoRow('Temp (Night)', tempNight, Icons.nightlight),
          _InfoRow('Humidity',     humidity,  Icons.water_drop),
          _InfoRow('Soil Moisture', soil,     Icons.grass),
          const SizedBox(height: 16),
          if (!isActive)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onSelect,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1D9E75),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: Text('Switch to this plant',
                    style: GoogleFonts.poppins(color: Colors.white)),
              ),
            ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label, value;
  final IconData icon;
  const _InfoRow(this.label, this.value, this.icon);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(width: 8),
        Text(label, style: GoogleFonts.poppins(
            fontSize: 13, color: Colors.grey[600])),
        const Spacer(),
        Text(value, style: GoogleFonts.poppins(
            fontSize: 13, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}