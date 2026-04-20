import 'dart:convert';

class CarbonReading {
  final int? id;
  final String zoneKey;
  final double? carbonIntensity;
  final double? renewablePercentage;
  final double? fossilPercentage;
  final Map<String, dynamic>? powerBreakdown;
  final DateTime readingDatetime;
  final DateTime? fetchedAt;

  const CarbonReading({
    this.id,
    required this.zoneKey,
    this.carbonIntensity,
    this.renewablePercentage,
    this.fossilPercentage,
    this.powerBreakdown,
    required this.readingDatetime,
    this.fetchedAt,
  });

  factory CarbonReading.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic>? breakdown;
    final raw = json['power_breakdown_json'];
    if (raw is Map<String, dynamic>) {
      breakdown = raw;
    } else if (raw is Map) {
      breakdown = Map<String, dynamic>.from(raw);
    } else if (raw is String && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map) breakdown = Map<String, dynamic>.from(decoded);
      } catch (_) {
        breakdown = null;
      }
    }

    return CarbonReading(
      id:                  _parseInt(json['id']),
      zoneKey:             json['zone_key'] as String,
      carbonIntensity:     _parseDouble(json['carbon_intensity']),
      renewablePercentage: _parseDouble(json['renewable_percentage']),
      fossilPercentage:    _parseDouble(json['fossil_percentage']),
      powerBreakdown:      breakdown,
      readingDatetime:     _parseDate(json['reading_datetime']) ?? DateTime.now(),
      fetchedAt:           _parseDate(json['fetched_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'zone_key':             zoneKey,
      'carbon_intensity':     carbonIntensity,
      'renewable_percentage': renewablePercentage,
      'fossil_percentage':    fossilPercentage,
      'power_breakdown_json': powerBreakdown != null ? jsonEncode(powerBreakdown) : null,
      'reading_datetime':     _formatForMysql(readingDatetime),
    };
  }

  factory CarbonReading.fromSqlite(Map<String, dynamic> row) {
    Map<String, dynamic>? breakdown;
    final raw = row['power_breakdown_json'];
    if (raw is String && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map) breakdown = Map<String, dynamic>.from(decoded);
      } catch (_) {}
    }

    return CarbonReading(
      id:                  row['id'] as int?,
      zoneKey:             row['zone_key'] as String,
      carbonIntensity:     _parseDouble(row['carbon_intensity']),
      renewablePercentage: _parseDouble(row['renewable_percentage']),
      fossilPercentage:    _parseDouble(row['fossil_percentage']),
      powerBreakdown:      breakdown,
      readingDatetime:     _parseDate(row['reading_datetime']) ?? DateTime.now(),
      fetchedAt:           _parseDate(row['fetched_at']),
    );
  }

  Map<String, dynamic> toSqlite() {
    return {
      if (id != null) 'id': id,
      'zone_key':             zoneKey,
      'carbon_intensity':     carbonIntensity,
      'renewable_percentage': renewablePercentage,
      'fossil_percentage':    fossilPercentage,
      'power_breakdown_json': powerBreakdown != null ? jsonEncode(powerBreakdown) : null,
      'reading_datetime':     readingDatetime.toIso8601String(),
      'fetched_at':           fetchedAt?.toIso8601String(),
    };
  }

  static int? _parseInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is String) return int.tryParse(v);
    if (v is num) return v.toInt();
    return null;
  }

  static double? _parseDouble(dynamic v) {
    if (v == null) return null;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
  }

  static DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    if (v is String && v.isNotEmpty) {
      final s = v.contains('T') ? v : v.replaceFirst(' ', 'T');
      return DateTime.tryParse(s);
    }
    return null;
  }

  static String _formatForMysql(DateTime dt) {
    final u = dt.toUtc();
    String p(int n, [int w = 2]) => n.toString().padLeft(w, '0');
    return '${p(u.year, 4)}-${p(u.month)}-${p(u.day)} ${p(u.hour)}:${p(u.minute)}:${p(u.second)}';
  }
}
