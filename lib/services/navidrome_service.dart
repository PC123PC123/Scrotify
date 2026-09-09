import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:crypto/crypto.dart';

class NavidromeService with ChangeNotifier {
  String? _url;
  String? _user;
  String? _pass;
  bool _connected = false;
  late http.Client _client;

  bool get connected => _connected;

  String _randomSalt() {
    final rnd = Random.secure();
    return List.generate(16, (_) => rnd.nextInt(16).toRadixString(16)).join();
  }

  String _md5(String input) {
    return md5.convert(utf8.encode(input)).toString();
  }

  Future<void> connectByUrl(String url, String user, String pass) async {
    _url = url.endsWith('/') ? url.substring(0, url.length - 1) : url;
    _user = user;
    _pass = pass;
    
    debugPrint('Connecting to $_url with user: $user');
    
    _client = http.Client();
    
    try {
      final salt = _randomSalt();
      final token = _md5('$pass$salt');
      
      final uri = Uri.parse('$_url/rest/ping.view').replace(queryParameters: {
        'u': user,
        's': salt,
        't': token,
        'v': '1.16.1',
        'c': 'Psysonic',
        'f': 'json',
      });
      
      final response = await _client.get(uri);
      
      debugPrint('Auth response status: ${response.statusCode}');
      debugPrint('Auth response body: ${response.body}');
      
      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200 && 
          data['subsonic-response']['status'] == 'ok') {
        _connected = true;
        notifyListeners();
      } else {
        throw Exception('Authentication failed: ${data['subsonic-response']['error']['message']}');
      }
    } catch (e) {
      debugPrint('Connection error: $e');
      rethrow;
    }
  }

  Future<List<dynamic>> getMusicFolders() async {
    if (!_connected) throw Exception('Not connected');
    final salt = _randomSalt();
    final token = _md5('$_pass$salt');
    
    final uri = Uri.parse('$_url/rest/getMusicFolders.view').replace(queryParameters: {
      'u': _user!,
      's': salt,
      't': token,
      'v': '1.16.1',
      'c': 'Psysonic',
      'f': 'json',
    });
    
    final response = await _client.get(uri);
    final data = jsonDecode(response.body);
    final folders = data['subsonic-response']['musicFolder'] as List?;
    return folders ?? [];
  }

  Future<List<dynamic>> getArtists() async {
    if (!_connected) throw Exception('Not connected');
    final salt = _randomSalt();
    final token = _md5('$_pass$salt');
    
    final uri = Uri.parse('$_url/rest/getArtists.view').replace(queryParameters: {
      'u': _user!,
      's': salt,
      't': token,
      'v': '1.16.1',
      'c': 'Psysonic',
      'f': 'json',
    });
    
    final response = await _client.get(uri);
    debugPrint('getArtists response: ${response.body}');
    final data = jsonDecode(response.body);
    
    dynamic indexes = data['subsonic-response']['artists']?['index'];
    
    if (indexes == null) {
      return [];
    }
    
    final List<dynamic> allArtists = [];
    for (var idx in indexes) {
      final artistsList = idx['artist'] as List?;
      if (artistsList != null) {
        allArtists.addAll(artistsList);
      }
    }
    
    debugPrint('getArtists result count: ${allArtists.length}');
    return allArtists;
  }

  Future<List<dynamic>> getIndexes() async {
    if (!_connected) throw Exception('Not connected');
    final salt = _randomSalt();
    final token = _md5('$_pass$salt');
    
    final uri = Uri.parse('$_url/rest/getIndexes.view').replace(queryParameters: {
      'u': _user!,
      's': salt,
      't': token,
      'v': '1.16.1',
      'c': 'Psysonic',
      'f': 'json',
    });
    
    final response = await _client.get(uri);
    debugPrint('getIndexes response: ${response.body}');
    final data = jsonDecode(response.body);
    
    dynamic indexes = data['subsonic-response']['indexes'];
    
    if (indexes == null) {
      return [];
    }
    
    if (indexes is Map && indexes.containsKey('index')) {
      final list = indexes['index'] as List?;
      debugPrint('getIndexes result (from index): $list');
      return list ?? [];
    }
    
    if (indexes is List) {
      debugPrint('getIndexes result: $indexes');
      return indexes;
    }
    
    debugPrint('getIndexes unknown format: $indexes');
    return [];
  }

  Future<List<dynamic>> search(String query) async {
    if (!_connected) throw Exception('Not connected');
    final salt = _randomSalt();
    final token = _md5('$_pass$salt');
    
    final uri = Uri.parse('$_url/rest/search3.view').replace(queryParameters: {
      'query': query,
      'u': _user!,
      's': salt,
      't': token,
      'v': '1.16.1',
      'c': 'Psysonic',
      'f': 'json',
    });
    
    final response = await _client.get(uri);
    final data = jsonDecode(response.body);
    final results = data['subsonic-response']['searchResult3'] as List?;
    return results ?? [];
  }

  void disconnect() async {
    _connected = false;
    _url = null;
    _user = null;
    _pass = null;
    _client.close();
    notifyListeners();
  }
}
