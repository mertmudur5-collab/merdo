import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/favorite_service.dart';
import 'detail.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<dynamic> deals = [];
  bool loading = true;
  Set<String> favorites = {};
  bool fromCache = false;
  String fetchedAt = '';

  @override
  void initState() {
    super.initState();
    loadAll();
  }

  Future<void> loadAll() async {
    setState(() => loading = true);
    final data = await ApiService.fetchDeals();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) favorites = await FavoriteService.getFavorites(uid);
    fromCache = data['cached'] == true;
    fetchedAt = (data['fetchedAt'] ?? '') as String;
    setState(() {
      deals = data['combined'] ?? [];
      loading = false;
    });
  }

  Future<void> _toggleFavorite(String key, String title, Map<String, dynamic> meta) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    await FavoriteService.toggleFavorite(uid, key, {'title': title, ...meta});
    final newFavs = await FavoriteService.getFavorites(uid);
    setState(() => favorites = newFavs);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('GameDeals'), actions: [
        IconButton(
            onPressed: () async {
              await AuthService.signOut();
            },
            icon: const Icon(Icons.logout))
      ]),
      body: RefreshIndicator(
        onRefresh: loadAll,
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : Column(children: [
                if (fromCache)
                  Container(
                    width: double.infinity,
                    color: Colors.orange.shade100,
                    padding: const EdgeInsets.all(8),
                    child: Text('Çevrimdışı veri gösteriliyor. Son güncelleme: $fetchedAt', textAlign: TextAlign.center),
                  ),
                Expanded(
                  child: ListView.builder(
                    itemCount: deals.length,
                    itemBuilder: (context, idx) {
                      final item = deals[idx];
                      final steam = item['steam'];
                      final epic = item['epic'];
                      final title = steam?['title'] ?? epic?['title'] ?? item['key'];
                      final key = item['key'] ?? title;
                      final isFav = favorites.contains(key);

                      double? steamPrice;
                      double? epicPrice;
                      try {
                        if (steam != null) steamPrice = double.tryParse((steam['price_final'] ?? steam['price'] ?? '').toString().replaceAll(',', '.'));
                        if (epic != null) epicPrice = double.tryParse((epic['price'] ?? '').toString().replaceAll(',', '.'));
                      } catch (_) {}

                      String subtitle;
                      if (steamPrice != null || epicPrice != null) {
                        if (steamPrice != null && epicPrice != null) {
                          final cheaper = steamPrice < epicPrice ? 'Steam' : (epicPrice < steamPrice ? 'Epic' : 'Eşit');
                          subtitle = '$cheaper daha ucuz — Steam: ${steamPrice.toStringAsFixed(2)} | Epic: ${epicPrice.toStringAsFixed(2)}';
                        } else if (steamPrice != null) {
                          subtitle = 'Steam: ${steamPrice.toStringAsFixed(2)}';
                        } else {
                          subtitle = 'Epic: ${epicPrice.toStringAsFixed(2)}';
                        }
                      } else {
                        subtitle = 'Steam: ${steam != null ? (steam['price_final']?.toString() ?? '—') : '—'}  |  Epic: ${epic != null ? (epic['price']?.toString() ?? '—') : '—'}';
                      }

                      return ListTile(
                        title: Text(title),
                        subtitle: Text(subtitle),
                        trailing: IconButton(
                          icon: Icon(isFav ? Icons.favorite : Icons.favorite_border, color: isFav ? Colors.red : null),
                          onPressed: () => _toggleFavorite(key, title, {'steam': steam, 'epic': epic}),
                        ),
                        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => DetailScreen(item: item, keyId: key))),
                      );
                    },
                  ),
                )
              ]),
    );
  }
}
