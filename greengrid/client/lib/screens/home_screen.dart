import 'dart:async';

import 'package:flutter/material.dart';

import '../config/app_colors.dart';
import '../models/carbon_reading.dart';
import '../models/zone_monitored.dart';
import '../services/api_service.dart';
import '../services/connectivity_service.dart';
import '../services/database_helper.dart';
import '../widgets/offline_banner.dart';
import '../widgets/zone_card.dart';
import 'add_zone_screen.dart';
import 'zone_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _api = ApiService();
  final ConnectivityService _connectivity = ConnectivityService();
  final DatabaseHelper _cache = DatabaseHelper.instance;

  bool _loading = true;
  bool _online = true;
  String? _error;

  List<ZoneMonitored> _zones = [];
  final Map<String, CarbonReading?> _readings = {};

  StreamSubscription<bool>? _connSub;

  @override
  void initState() {
    super.initState();
    _initConnectivity();
    _loadAll();
  }

  Future<void> _initConnectivity() async {
    _online = await _connectivity.isOnline();
    if (mounted) setState(() {});
    _connSub = _connectivity.onConnectivityChanged.listen((isOn) {
      if (!mounted) return;
      final wasOffline = !_online;
      setState(() => _online = isOn);
      if (wasOffline && isOn) {
        _showSuccess('Connessione ripristinata, dati aggiornati');
        _loadAll();
      }
    });
  }

  @override
  void dispose() {
    _connSub?.cancel();
    _api.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    _readings.clear();

    if (_online) {
      await _loadOnline();
    } else {
      await _loadOffline();
    }

    if (!mounted) return;
    setState(() => _loading = false);
  }

  Future<void> _loadOnline() async {
    try {
      final zones = await _api.getZones();
      await _cache.cacheZones(zones);
      _zones = zones;
      await Future.wait(zones.map(_loadLiveReading));
    } on ApiException catch (e) {
      await _loadOffline();
      if (_zones.isEmpty) _error = e.message;
    }
  }

  Future<void> _loadOffline() async {
    _zones = await _cache.getCachedZones();
    for (final z in _zones) {
      final cached = await _cache.getCachedReadings(z.zoneKey, limit: 1);
      _readings[z.zoneKey] = cached.isNotEmpty ? cached.first : null;
    }
  }

  Future<void> _loadLiveReading(ZoneMonitored z) async {
    try {
      final res = await _api.getCarbonIntensity(z.zoneKey);
      final dtStr = res['datetime'] as String?;
      final reading = CarbonReading(
        zoneKey: z.zoneKey,
        carbonIntensity: (res['carbonIntensity'] as num?)?.toDouble(),
        readingDatetime: (dtStr != null ? DateTime.tryParse(dtStr) : null) ?? DateTime.now(),
        fetchedAt: DateTime.now(),
      );
      await _cache.cacheReadings(z.zoneKey, [reading]);
      _readings[z.zoneKey] = reading;
    } catch (_) {
      final cached = await _cache.getCachedReadings(z.zoneKey, limit: 1);
      _readings[z.zoneKey] = cached.isNotEmpty ? cached.first : null;
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccess(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _openDetail(ZoneMonitored z) async {
    final result = await Navigator.of(context).push<dynamic>(
      MaterialPageRoute(
        builder: (_) => ZoneDetailScreen(zone: z, apiService: _api),
      ),
    );
    if (result == 'deleted' || result is ZoneMonitored) {
      _loadAll();
    }
  }

  Future<void> _openAdd() async {
    if (!_online) {
      _showError('Impossibile aggiungere zone offline');
      return;
    }
    final result = await Navigator.of(context).push<dynamic>(
      MaterialPageRoute(builder: (_) => AddZoneScreen(apiService: _api)),
    );
    if (result is ZoneMonitored) {
      _showSuccess('Zona "${result.displayName}" aggiunta');
      _loadAll();
    }
  }

  Future<void> _deleteZone(ZoneMonitored z) async {
    if (z.id == null) return;
    try {
      await _api.deleteZone(z.id!);
      await _cache.removeCachedZone(z.id!);
      if (!mounted) return;
      _showSuccess('"${z.displayName}" eliminata');
      _loadAll();
    } on ApiException catch (e) {
      if (!mounted) return;
      _showError('Errore: ${e.message}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('GreenGrid')),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAdd,
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          if (!_online) const OfflineBanner(),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return _buildLoadingState();
    }
    if (_error != null && _zones.isEmpty) {
      return _buildErrorState();
    }
    if (_zones.isEmpty) return _buildEmptyState();

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _loadAll,
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          _buildSummaryHeader(),
          const SizedBox(height: 4),
          ..._zones.map((z) => ZoneCard(
                zone: z,
                latestReading: _readings[z.zoneKey],
                onTap: () => _openDetail(z),
                onDelete: () => _deleteZone(z),
              )),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: const [
        _ShimmerHeader(),
        SizedBox(height: 4),
        _ShimmerCard(),
        _ShimmerCard(),
        _ShimmerCard(),
        _ShimmerCard(),
      ],
    );
  }

  Widget _buildSummaryHeader() {
    final withReading = _readings.values.whereType<CarbonReading>().toList();
    final lastUpdate = withReading
        .map((r) => r.fetchedAt ?? r.readingDatetime)
        .fold<DateTime?>(null, (a, b) => a == null || b.isAfter(a) ? b : a);

    String fmt(DateTime dt) {
      String p(int n) => n.toString().padLeft(2, '0');
      final local = dt.toLocal();
      return '${p(local.hour)}:${p(local.minute)}';
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primarySurface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.eco, color: AppColors.primaryDark, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_zones.length} ${_zones.length == 1 ? 'zona monitorata' : 'zone monitorate'}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (lastUpdate != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Ultimo aggiornamento: ${fmt(lastUpdate)}',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF085041)),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return LayoutBuilder(
      builder: (_, constraints) => RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _loadAll,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: AppColors.primarySurface,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.public,
                        size: 52,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Inizia a monitorare',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Non hai ancora aggiunto zone.\nTocca il pulsante + per monitorare la tua prima zona e vedere l\'intensità carbonica in tempo reale.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: _openAdd,
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Aggiungi zona'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _loadAll,
      child: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              children: [
                const Icon(Icons.cloud_off, size: 48, color: AppColors.textSecondary),
                const SizedBox(height: 12),
                Text(
                  'Impossibile caricare le zone\n$_error',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 12),
                TextButton(onPressed: _loadAll, child: const Text('Riprova')),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ShimmerHeader extends StatefulWidget {
  const _ShimmerHeader();

  @override
  State<_ShimmerHeader> createState() => _ShimmerHeaderState();
}

class _ShimmerHeaderState extends State<_ShimmerHeader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Opacity(
        opacity: 0.4 + (_ctrl.value * 0.4),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          height: 62,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}

class _ShimmerCard extends StatefulWidget {
  const _ShimmerCard();

  @override
  State<_ShimmerCard> createState() => _ShimmerCardState();
}

class _ShimmerCardState extends State<_ShimmerCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Opacity(
        opacity: 0.4 + (_ctrl.value * 0.4),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200, width: 0.5),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 140,
                      height: 14,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 80,
                      height: 10,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 50,
                height: 28,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
