import 'dart:async';

import 'package:flutter/material.dart';

import '../config/app_colors.dart';
import '../models/zone_monitored.dart';
import '../services/api_service.dart';
import '../services/connectivity_service.dart';
import '../services/database_helper.dart';

class AddZoneScreen extends StatefulWidget {
  final ApiService apiService;
  const AddZoneScreen({super.key, required this.apiService});

  @override
  State<AddZoneScreen> createState() => _AddZoneScreenState();
}

class _AddZoneScreenState extends State<AddZoneScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  bool _loadingZones = true;
  String? _loadError;
  List<_ZoneOption> _allZones = [];
  String _query = '';

  _ZoneOption? _selected;
  Map<String, dynamic>? _liveIntensity;
  final TextEditingController _labelCtrl = TextEditingController();
  final TextEditingController _notesCtrl = TextEditingController();
  bool _saving = false;

  final ConnectivityService _connectivity = ConnectivityService();
  bool _online = true;
  StreamSubscription<bool>? _connSub;

  @override
  void initState() {
    super.initState();
    _initConnectivity();
    _searchCtrl.addListener(() {
      setState(() => _query = _searchCtrl.text.trim());
    });
  }

  Future<void> _initConnectivity() async {
    _online = await _connectivity.isOnline();
    if (mounted) setState(() {});
    if (_online) _loadZones();
    _connSub = _connectivity.onConnectivityChanged.listen((isOn) {
      if (!mounted) return;
      final wasOffline = !_online;
      setState(() => _online = isOn);
      if (wasOffline && isOn && _allZones.isEmpty) _loadZones();
    });
  }

  @override
  void dispose() {
    _connSub?.cancel();
    _searchCtrl.dispose();
    _labelCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadZones() async {
    setState(() {
      _loadingZones = true;
      _loadError = null;
    });
    try {
      final raw = await widget.apiService.getAvailableZones();
      final options = <_ZoneOption>[];
      raw.forEach((key, value) {
        if (value is Map) {
          final name = (value['zoneName'] ?? value['countryName'] ?? key).toString();
          options.add(_ZoneOption(key: key, name: name));
        } else {
          options.add(_ZoneOption(key: key, name: key));
        }
      });
      options.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      setState(() {
        _allZones = options;
        _loadingZones = false;
      });
    } on ApiException catch (e) {
      setState(() {
        _loadError = e.message;
        _loadingZones = false;
      });
    }
  }

  List<_ZoneOption> get _filtered {
    if (_query.length < 2) return const [];
    final q = _query.toLowerCase();
    return _allZones
        .where((z) => z.name.toLowerCase().contains(q) || z.key.toLowerCase().contains(q))
        .take(50)
        .toList();
  }

  Future<void> _selectZone(_ZoneOption option) async {
    setState(() {
      _selected = option;
      _liveIntensity = null;
    });
    try {
      final res = await widget.apiService.getCarbonIntensity(option.key);
      if (!mounted) return;
      setState(() => _liveIntensity = res);
    } catch (_) {}
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

  Future<void> _saveZone() async {
    if (_selected == null) return;

    final online = await ConnectivityService().isOnline();
    if (!online) {
      if (!mounted) return;
      _showError('Impossibile salvare, controlla la connessione');
      return;
    }

    setState(() => _saving = true);
    try {
      final zone = ZoneMonitored(
        zoneKey: _selected!.key,
        zoneName: _selected!.name,
        userLabel: _labelCtrl.text.trim().isEmpty ? null : _labelCtrl.text.trim(),
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      );
      final created = await widget.apiService.createZone(zone);
      await DatabaseHelper.instance.cacheZone(created);
      if (!mounted) return;
      Navigator.of(context).pop(created);
    } on ApiException catch (e) {
      if (!mounted) return;
      final msg = e.statusCode == 409 ? 'Zona già salvata' : 'Errore: ${e.message}';
      _showError(msg);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Aggiungi zona')),
      body: !_online
          ? _buildOfflineLock()
          : _selected == null
              ? _buildSearchPhase()
              : _buildCustomizePhase(),
    );
  }

  Widget _buildOfflineLock() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.cloud_off, size: 64, color: AppColors.textSecondary),
            SizedBox(height: 16),
            Text(
              'Per aggiungere una nuova zona è necessaria la connessione internet',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchPhase() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchCtrl,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
              hintText: 'Cerca paese o zona...',
              hintStyle: const TextStyle(color: Color(0xFFB4B2A9)),
              suffixIcon: _query.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      color: AppColors.textSecondary,
                      onPressed: () {
                        _searchCtrl.clear();
                      },
                    )
                  : null,
            ),
          ),
        ),
        Expanded(child: _buildSearchResults()),
      ],
    );
  }

  Widget _buildSearchResults() {
    if (_loadingZones) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: AppColors.primary),
            SizedBox(height: 12),
            Text(
              'Caricamento zone disponibili...',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }
    if (_loadError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off, size: 48, color: AppColors.textSecondary),
              const SizedBox(height: 12),
              Text(
                'Impossibile caricare le zone\n$_loadError',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 12),
              TextButton(onPressed: _loadZones, child: const Text('Riprova')),
            ],
          ),
        ),
      );
    }
    if (_query.length < 2) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.search, size: 40, color: AppColors.textSecondary),
              SizedBox(height: 10),
              Text(
                'Digita almeno 2 caratteri per cercare',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      );
    }
    final results = _filtered;
    if (results.isEmpty) {
      return const Center(
        child: Text(
          'Nessuna zona trovata',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemCount: results.length,
      itemBuilder: (_, i) => _ResultTile(
        option: results[i],
        onTap: () => _selectZone(results[i]),
      ),
    );
  }

  Widget _buildCustomizePhase() {
    final sel = _selected!;
    final intensity = (_liveIntensity?['carbonIntensity'] as num?)?.toDouble();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Zona selezionata',
                        style: TextStyle(fontSize: 12, color: Color(0xFF085041)),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        sel.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryDark,
                        ),
                      ),
                      Text(
                        sel.key,
                        style: const TextStyle(fontSize: 13, color: Color(0xFF085041)),
                      ),
                    ],
                  ),
                ),
                if (intensity != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        intensity.round().toString(),
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          color: AppColors.carbonColor(intensity),
                        ),
                      ),
                      const Text(
                        'gCO₂/kWh',
                        style: TextStyle(fontSize: 11, color: Color(0xFF085041)),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _labelCtrl,
            decoration: const InputDecoration(
              labelText: 'La tua etichetta',
              hintText: 'es. Casa, Ufficio...',
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _notesCtrl,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Note personali',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: _saving ? null : _saveZone,
              child: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Salva zona'),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.textSecondary),
            onPressed: _saving ? null : () => setState(() => _selected = null),
            child: const Text('Torna alla ricerca'),
          ),
        ],
      ),
    );
  }
}

class _ZoneOption {
  final String key;
  final String name;
  const _ZoneOption({required this.key, required this.name});
}

class _ResultTile extends StatelessWidget {
  final _ZoneOption option;
  final VoidCallback onTap;
  const _ResultTile({required this.option, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        option.name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        option.key,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Color(0xFFB4B2A9)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
