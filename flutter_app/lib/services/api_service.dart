import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const _base = 'http://10.0.2.2:3000'; // Android emulator -> host
  static const _cacheKey = 'cached_deals_v1';

  static Future<Map<String, dynamic>> fetchDeals() async {
    final url = Uri.parse('$_base/deals');
    try {
      final r = await http.get(url).timeout(const Duration(seconds: 8));
      if (r.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(r.body) as Map<String, dynamic>;
        // Cache response
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_cacheKey, json.encode(data));
        return {...data, 'cached': false};
      } else {
        return await _readCacheOrEmpty();
      }
    } catch (e) {
      return await _readCacheOrEmpty();
    }
  }

  static Future<Map<String, dynamic>> _readCacheOrEmpty() async {
    final prefs = await SharedPreferences.getInstance();
    final s = prefs.getString(_cacheKey);
    if (s == null) return {'combined': [], 'cached': false};
    try {
      final Map<String, dynamic> data = json.decode(s) as Map<String, dynamic>;
      return {...data, 'cached': true};
    } catch (_) {
      return {'combined': [], 'cached': false};
    }
  }
}
