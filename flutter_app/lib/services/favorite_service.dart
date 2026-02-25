import 'package:cloud_firestore/cloud_firestore.dart';

class FavoriteService {
  static final _db = FirebaseFirestore.instance;

  static Future<Set<String>> getFavorites(String uid) async {
    final snap = await _db.collection('users').doc(uid).collection('favorites').get();
    return snap.docs.map((d) => d.id).toSet();
  }

  static Future<void> toggleFavorite(String uid, String key, Map<String, dynamic> meta) async {
    final ref = _db.collection('users').doc(uid).collection('favorites').doc(key);
    final doc = await ref.get();
    if (doc.exists) {
      await ref.delete();
    } else {
      await ref.set({
        'title': meta['title'] ?? '',
        'addedAt': FieldValue.serverTimestamp(),
        ...meta,
      });
    }
  }
}
