import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/favorite_service.dart';

class DetailScreen extends StatefulWidget {
  final Map<String, dynamic> item;
  final String keyId;
  const DetailScreen({super.key, required this.item, required this.keyId});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  bool isFav = false;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadFav();
  }

  Future<void> _loadFav() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return setState(() { loading = false; });
    final favs = await FavoriteService.getFavorites(uid);
    setState(() {
      isFav = favs.contains(widget.keyId);
      loading = false;
    });
  }

  Future<void> _toggle() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    await FavoriteService.toggleFavorite(uid, widget.keyId, {'title': widget.item['steam']?['title'] ?? widget.item['epic']?['title']});
    await _loadFav();
  }

  @override
  Widget build(BuildContext context) {
    final steam = widget.item['steam'];
    final epic = widget.item['epic'];
    final title = steam?['title'] ?? epic?['title'] ?? widget.keyId;
    final score = widget.item['score'] ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          loading
              ? const Padding(padding: EdgeInsets.all(12.0), child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)))
              : IconButton(
                  onPressed: _toggle,
                  icon: Icon(isFav ? Icons.favorite : Icons.favorite_border, color: isFav ? Colors.red : null),
                )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          if (steam != null) ...[
            const Text('Steam', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            Text('İndirim: ${steam['discount_percent'] ?? '—'}%'),
            Text('Fiyat (final): ${steam['price_final'] ?? '—'}'),
            const SizedBox(height: 12),
          ],
          if (epic != null) ...[
            const Text('Epic Games', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            Text('Fiyat bilgisi mevcut değil veya scraping gerekli'),
            const SizedBox(height: 12),
          ],
          const Divider(),
          const SizedBox(height: 8),
          Text('Eşleştirme skor: ${score.toStringAsFixed(2)}'),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => CompareScreen(item: widget.item, keyId: widget.keyId)));
            },
            child: const Text('Mağaza karşılaştırmasını gör'),
          )
        ]),
      ),
    );
  }
}
