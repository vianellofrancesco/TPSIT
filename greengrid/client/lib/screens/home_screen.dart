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
      setState(() => _online = isOn);
    });
  }

  @override
  void dispose() {
    _connSub?.cancel();
    _api.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    setState(() { _loading = true; _error = null; });

    List<ZoneMonitored> zones;
    try {
      zones = await _api.getZones();
      await _cache.cacheZones(zones);
    } on ApiException catch (e) {
      zones = await _cache.getCachedZones();
      if (zones.isEmpty) {
        setState(() {
          _loading = false;
          _error   = e.message;
        });
        return;
      }
    }

    _zones = zones;
    _readings.clear();

    await Future.wait(zones.map(_loadReadingForZone));

    if (!mounted) return;
    setState(() => _loading = false);
  }

  Future<void> _loadReadingForZone(ZoneMonitored z) async {
    try {
      final res = await _api.getCarbonIntensity(z.zoneKey);
      final dtStr = res['datetime'] as String?;
      final reading = CarbonReading(
        zoneKey:         z.zoneKey,
        carbonIntensity: (res['carbonIntensity'] as num?)?.toDouble(),
        readingDatetime: (dtStr != null ? DateTime.tryParse(dtStr) : null)
                          ?? DateTime.now(),
        fetchedAt:       DateTime.now(),
      );
      await _cache.cacheReadings(z.zoneKey, [reading]);
      _readings[z.zoneKey] = reading;
    } catch (_) {
      final cached = await _cache.getCachedReadings(z.zoneKey, limit: 1);
      _readings[z.zoneKey] = cached.isNotEmpty ? cached.first : null;
    }
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossibile aggiungere zone offline')),
      );
      return;
    }
    final result = await Navigator.of(context).push<dynamic>(
      MaterialPageRoute(builder: (_) => AddZoneScreen(apiService: _api)),
    );
    if (result is ZoneMonitored) _loadAll();
  }

  Future<void> _deleteZone(ZoneMonitored z) async {
    if (z.id == null) return;
    try {
      await _api.deleteZone(z.id!);
      await _cache.removeCachedZone(z.id!);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('"${z.displayName}" eliminata')),
      );
      _loadAll();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Errore: ${e.message}')),
      );
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
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${_zones.length} ${_zones.length == 1 ? 'zona monitorata' : 'zone monitorate'}',
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.primaryDark,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (lastUpdate != null) ...[
            const SizedBox(height: 4),
            Text(
              'Ultimo aggiornamento: ${fmt(lastUpdate)}',
              style: const TextStyle(fontSize: 12, color: Color(0xFF085041)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return LayoutBuilder(
      builder: (_, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.public_off, size: 64, color: Color(0xFFB4B2A9)),
                  SizedBox(height: 16),
                  Text(
                    'Nessuna zona salvata',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF5F5E5A),
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Tocca + per monitorare una zona',
                    style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                  ),
                ],
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
