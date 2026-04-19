import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AIService {
  static const _key = 'YOUR_ANTHROPIC_API_KEY';
  static const _url = 'https://api.anthropic.com/v1/messages';

  Future<PlantHealthReport> analyze({
    required String plant,
    required List<Map<String, dynamic>> history,
    required String currentAlert,
  }) async {
    final temps = history.map((r) => (r['temp'] as num?)?.toDouble() ?? 0).toList();
    final hums  = history.map((r) => (r['hum']  as num?)?.toDouble() ?? 0).toList();
    final soils = history.map((r) => (r['soil'] as num?)?.toDouble() ?? 0).toList();

    double avg(List<double> l) => l.isEmpty ? 0 : l.reduce((a,b)=>a+b)/l.length;
    double mn(List<double> l)  => l.isEmpty ? 0 : l.reduce((a,b)=>a<b?a:b);
    double mx(List<double> l)  => l.isEmpty ? 0 : l.reduce((a,b)=>a>b?a:b);

    final prompt = '''
You are a plant health AI for a smart greenhouse.
Plant: $plant
Last 24h sensor averages:
- Temperature: ${avg(temps).toStringAsFixed(1)}C (min: ${mn(temps).toStringAsFixed(1)}, max: ${mx(temps).toStringAsFixed(1)})
- Humidity: ${avg(hums).toStringAsFixed(1)}% RH
- Soil Moisture: ${avg(soils).toStringAsFixed(1)}%
- Current alert: $currentAlert

Optimal ranges:
- hibiscus:  Temp 25-35C, Humidity 60-65%, Soil 28-40%
- sunflower: Temp 22-30C, Humidity 50-60%, Soil 28-40%
- taro:      Temp 24-30C, Humidity 60-65%, Soil 80-90%

Reply ONLY with this exact JSON (no markdown, no backticks, raw JSON only):
{
  "healthScore": <0-100>,
  "status": "Excellent|Good|Fair|Poor|Critical",
  "issues": ["..."],
  "recommendations": ["..."],
  "summary": "one sentence"
}''';

    final res = await http.post(
      Uri.parse(_url),
      headers: {
        'x-api-key': _key,
        'anthropic-version': '2023-06-01',
        'content-type': 'application/json',
      },
      body: jsonEncode({
        'model': 'claude-sonnet-4-20250514',
        'max_tokens': 400,
        'messages': [{'role': 'user', 'content': prompt}]
      }),
    );

    if (res.statusCode != 200) {
      throw Exception('API error ${res.statusCode}: ${res.body}');
    }

    final jsonData = jsonDecode(res.body);
    final text = jsonData['content'][0]['text'] as String;
    final clean = text.replaceAll(RegExp(r'```json|```'), '').trim();
    final parsed = jsonDecode(clean);

    return PlantHealthReport.fromJson(parsed);
  }
}

class PlantHealthReport {
  final int healthScore;
  final String status;
  final List<String> issues;
  final List<String> recommendations;
  final String summary;

  PlantHealthReport.fromJson(Map<String, dynamic> j)
      : healthScore     = j['healthScore'],
        status          = j['status'],
        issues          = List<String>.from(j['issues']),
        recommendations = List<String>.from(j['recommendations']),
        summary         = j['summary'];

  Color get statusColor {
    if (healthScore >= 80) return const Color(0xFF1D9E75);
    if (healthScore >= 60) return Colors.lightGreen;
    if (healthScore >= 40) return Colors.orange;
    return Colors.red;
  }
}