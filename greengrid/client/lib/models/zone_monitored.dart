class ZoneMonitored {
  final int? id;
  final String zoneKey;
  final String zoneName;
  final String? userLabel;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ZoneMonitored({
    this.id,
    required this.zoneKey,
    required this.zoneName,
    this.userLabel,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  factory ZoneMonitored.fromJson(Map<String, dynamic> json) {
    return ZoneMonitored(
      id:         _parseInt(json['id']),
      zoneKey:    json['zone_key']   as String,
      zoneName:   json['zone_name']  as String,
      userLabel:  json['user_label'] as String?,
      notes:      json['notes']      as String?,
      createdAt:  _parseDate(json['created_at']),
      updatedAt:  _parseDate(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'zone_key':   zoneKey,
      'zone_name':  zoneName,
      'user_label': userLabel,
      'notes':      notes,
    };
  }

  Map<String, dynamic> toJsonForPatch(List<String> fields) {
    final Map<String, dynamic> all = {
      'zone_key':   zoneKey,
      'zone_name':  zoneName,
      'user_label': userLabel,
      'notes':      notes,
    };
    return {for (final f in fields) if (all.containsKey(f)) f: all[f]};
  }

  factory ZoneMonitored.fromSqlite(Map<String, dynamic> row) {
    return ZoneMonitored(
      id:         row['id'] as int?,
      zoneKey:    row['zone_key']   as String,
      zoneName:   row['zone_name']  as String,
      userLabel:  row['user_label'] as String?,
      notes:      row['notes']      as String?,
      createdAt:  _parseDate(row['created_at']),
      updatedAt:  _parseDate(row['updated_at']),
    );
  }

  Map<String, dynamic> toSqlite() {
    return {
      if (id != null) 'id': id,
      'zone_key':   zoneKey,
      'zone_name':  zoneName,
      'user_label': userLabel,
      'notes':      notes,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  ZoneMonitored copyWith({
    int? id,
    String? zoneKey,
    String? zoneName,
    String? userLabel,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ZoneMonitored(
      id:         id        ?? this.id,
      zoneKey:    zoneKey   ?? this.zoneKey,
      zoneName:   zoneName  ?? this.zoneName,
      userLabel:  userLabel ?? this.userLabel,
      notes:      notes     ?? this.notes,
      createdAt:  createdAt ?? this.createdAt,
      updatedAt:  updatedAt ?? this.updatedAt,
    );
  }

  String get displayName =>
      (userLabel != null && userLabel!.trim().isNotEmpty) ? userLabel! : zoneName;

  static int? _parseInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is String) return int.tryParse(v);
    if (v is num) return v.toInt();
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
}
