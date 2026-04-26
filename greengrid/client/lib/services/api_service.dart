import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/carbon_reading.dart';
import '../models/zone_monitored.dart';

class ApiException implements Exception {
  final int statusCode;
  final String message;
  ApiException(this.statusCode, this.message);

  @override
  String toString() => 'ApiException($statusCode): $message';
}

class ApiService {
  final http.Client _client;

  ApiService({http.Client? client}) : _client = client ?? http.Client();

  Future<List<ZoneMonitored>> getZones() async {
    final data = await _get('/zones');
    if (data is! List) {
      throw ApiException(500, 'Risposta zones non valida');
    }
    return data
        .whereType<Map>()
        .map((e) => ZoneMonitored.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<ZoneMonitored> getZone(int id) async {
    final data = await _get('/zones/$id');
    return ZoneMonitored.fromJson(Map<String, dynamic>.from(data as Map));
  }

  Future<ZoneMonitored> createZone(ZoneMonitored zone) async {
    final data = await _post('/zones', zone.toJson());
    return ZoneMonitored.fromJson(Map<String, dynamic>.from(data as Map));
  }

  Future<ZoneMonitored> updateZone(int id, ZoneMonitored zone) async {
    final data = await _put('/zones/$id', zone.toJson());
    return ZoneMonitored.fromJson(Map<String, dynamic>.from(data as Map));
  }

  Future<ZoneMonitored> patchZone(int id, Map<String, dynamic> fields) async {
    final data = await _patch('/zones/$id', fields);
    return ZoneMonitored.fromJson(Map<String, dynamic>.from(data as Map));
  }

  Future<void> deleteZone(int id) async {
    await _delete('/zones/$id');
  }

  Future<List<CarbonReading>> getReadings({String? zoneKey, int limit = 50}) async {
    final qp = <String, String>{'limit': '$limit'};
    if (zoneKey != null && zoneKey.isNotEmpty) qp['zone_key'] = zoneKey;

    final data = await _get('/readings', query: qp);
    if (data is! List) {
      throw ApiException(500, 'Risposta readings non valida');
    }
    return data
        .whereType<Map>()
        .map((e) => CarbonReading.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<void> deleteReading(int id) async {
    await _delete('/readings/$id');
  }

  Future<Map<String, dynamic>> getAvailableZones() async {
    final data = await _get('/proxy/zones');
    return _asMap(data);
  }

  Future<Map<String, dynamic>> getCarbonIntensity(String zoneKey) async {
    final data = await _get('/proxy/carbon-intensity', query: {'zone': zoneKey});
    return _asMap(data);
  }

  Future<Map<String, dynamic>> getPowerBreakdown(String zoneKey) async {
    final data = await _get('/proxy/power-breakdown', query: {'zone': zoneKey});
    return _asMap(data);
  }

  Future<List<Map<String, dynamic>>> getHistory(String zoneKey) async {
    final data = await _get('/proxy/history', query: {'zone': zoneKey});
    final map = _asMap(data);
    final hist = map['history'];
    if (hist is List) {
      return hist
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    return const [];
  }

  Uri _uri(String path, [Map<String, String>? query]) {
    final base = Uri.parse('${ApiConfig.baseUrl}$path');
    if (query == null || query.isEmpty) return base;
    return base.replace(queryParameters: {...base.queryParameters, ...query});
  }

  Map<String, String> get _headers => const {
        'Accept': 'application/json',
        'Content-Type': 'application/json; charset=utf-8',
      };

  Future<dynamic> _get(String path, {Map<String, String>? query}) =>
      _send(() => _client.get(_uri(path, query), headers: _headers));

  Future<dynamic> _post(String path, Object body) => _send(() =>
      _client.post(_uri(path), headers: _headers, body: jsonEncode(body)));

  Future<dynamic> _put(String path, Object body) => _send(() =>
      _client.put(_uri(path), headers: _headers, body: jsonEncode(body)));

  Future<dynamic> _patch(String path, Object body) => _send(() =>
      _client.patch(_uri(path), headers: _headers, body: jsonEncode(body)));

  Future<dynamic> _delete(String path) =>
      _send(() => _client.delete(_uri(path), headers: _headers));

  Future<dynamic> _send(Future<http.Response> Function() fn) async {
    http.Response res;
    try {
      res = await fn().timeout(ApiConfig.timeout);
    } on TimeoutException {
      throw ApiException(408, 'Timeout: il server non risponde');
    } on SocketException {
      throw ApiException(0, 'Connessione non disponibile');
    } on http.ClientException catch (e) {
      throw ApiException(0, 'Errore di rete: ${e.message}');
    }

    final body = res.body;
    dynamic decoded;
    if (body.isNotEmpty) {
      try {
        decoded = jsonDecode(body);
      } catch (_) {
        throw ApiException(res.statusCode, 'Risposta non JSON: $body');
      }
    }

    if (res.statusCode >= 200 && res.statusCode < 300) {
      return decoded;
    }

    final msg = (decoded is Map && decoded['error'] != null)
        ? decoded['error'].toString()
        : 'Errore HTTP ${res.statusCode}';
    throw ApiException(res.statusCode, msg);
  }

  Map<String, dynamic> _asMap(dynamic v) {
    if (v is Map<String, dynamic>) return v;
    if (v is Map) return Map<String, dynamic>.from(v);
    throw ApiException(500, 'Risposta attesa come oggetto JSON');
  }

  void dispose() => _client.close();
}
