import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class CompareScreen extends StatelessWidget {
  final Map<String, dynamic> item;
  final String keyId;
  const CompareScreen({super.key, required this.item, required this.keyId});

  Uri? _steamUrl(Map<String, dynamic>? steam) {
    final id = steam?['id'] ?? steam?['appId'];
    if (id == null) return null;
    return Uri.parse('https://store.steampowered.com/app/$id');
  }

  Uri? _epicSearchUrl(Map<String, dynamic>? epic, String title) {
    final q = Uri.encodeComponent(title);
    return Uri.parse('https://www.epicgames.com/store/tr/search?q=$q');
  }

  Future<void> _open(Uri? uri) async {
    if (uri == null) return;
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      // ignore: avoid_print
      print('Could not launch $uri');
    }
  }

  @override
  Widget build(BuildContext context) {
    final steam = item['steam'];
    final epic = item['epic'];
    final title = steam?['title'] ?? epic?['title'] ?? keyId;

    double? steamPriceNum;
    double? epicPriceNum;
    try {
      if (steam != null) {
        final v = steam['price_final'] ?? steam['price'] ?? steam['price_final'];
        if (v != null) steamPriceNum = double.tryParse(v.toString().replaceAll(',', '.'));
      }
      if (epic != null) {
        final v = epic['price'] ?? epic['price_final'] ?? epic['price_raw'];
        if (v != null) epicPriceNum = double.tryParse(v.toString().replaceAll(',', '.'));
      }
    } catch (_) {}

    String diffText = '—';
    Color? steamCardColor;
    Color? epicCardColor;
    if (steamPriceNum != null || epicPriceNum != null) {
      if (steamPriceNum != null && epicPriceNum != null) {
        final diff = (steamPriceNum - epicPriceNum).abs();
        diffText = diff.toStringAsFixed(2);
        if (steamPriceNum < epicPriceNum) steamCardColor = Colors.green.shade50; else if (epicPriceNum < steamPriceNum) epicCardColor = Colors.green.shade50;
      } else if (steamPriceNum != null) {
        diffText = steamPriceNum.toStringAsFixed(2);
        steamCardColor = Colors.green.shade50;
      } else {
        diffText = epicPriceNum!.toStringAsFixed(2);
        epicCardColor = Colors.green.shade50;
      }
    }

    return Scaffold(
      appBar: AppBar(title: Text('Karşılaştır: $title')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(children: [
          Row(children: [
            Expanded(
              child: Card(
                child: Container(
                  color: steamCardColor,
                  padding: const EdgeInsets.all(12.0),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Steam', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text('Başlık: ${steam?['title'] ?? '—'}'),
                    Text('İndirim: ${steam?['discount_percent'] ?? '—'}%'),
                    Text('Fiyat (final): ${steamPriceNum != null ? steamPriceNum.toStringAsFixed(2) : (steam?['price_final'] ?? '—')}'),
                    const SizedBox(height: 8),
                    ElevatedButton(onPressed: () => _open(_steamUrl(steam)), child: const Text('Steam mağazasını aç')),
                  ]),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Card(
                child: Container(
                  color: epicCardColor,
                  padding: const EdgeInsets.all(12.0),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Epic Games', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text('Başlık: ${epic?['title'] ?? '—'}'),
                    Text('Fiyat bilgisi: ${epicPriceNum != null ? epicPriceNum.toStringAsFixed(2) : (epic?['price'] ?? '—')}'),
                    const SizedBox(height: 8),
                    ElevatedButton(onPressed: () => _open(_epicSearchUrl(epic, title)), child: const Text('Epic mağazasını ara')),
                  ]),
                ),
              ),
            ),
          ]),
          const Divider(),
          const SizedBox(height: 8),
          Text('Fiyat farkı: $diffText'),
        ]),
      ),
    );
  }
}
