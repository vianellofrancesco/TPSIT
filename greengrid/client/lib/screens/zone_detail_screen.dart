import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../config/app_colors.dart';
import '../models/zone_monitored.dart';
import '../services/api_service.dart';
import '../widgets/power_mix_bar.dart';
import 'edit_zone_screen.dart';


class ZoneDetailScreen extends StatefulWidget {
  final ZoneMonitored zone;
  final ApiService apiService;

  const ZoneDetailScreen({
    super.key,
    required this.zone,
    required this.apiService,
  });

  @override
  State<ZoneDetailScreen> createState() => _ZoneDetailScreenState();
}

class _ZoneDetailScreenState extends State<ZoneDetailScreen> {
  late ZoneMonitored _zone;
  bool _loading = true;
  String? _error;

  double? _intensity;
  DateTime? _intensityUpdatedAt;
  Map<String, num> _breakdown = const {};
  double? _renewablePct;
  List<_HistoryPoint> _history = const [];

  @override
  void initState() {
    super.initState();
    _zone = widget.zone;
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final results = await Future.wait([
        widget.apiService.getCarbonIntensity(_zone.zoneKey),
        widget.apiService.getPowerBreakdown(_zone.zoneKey),
        widget.apiService.getHistory(_zone.zoneKey),
      ]);

      final intensityRes = results[0] as Map<String, dynamic>;
      final breakdownRes = results[1] as Map<String, dynamic>;
      final historyRes   = results[2] as List<Map<String, dynamic>>;

      _intensity = (intensityRes['carbonIntensity'] as num?)?.toDouble();
      final dtStr = intensityRes['datetime'] as String?;
      _intensityUpdatedAt = dtStr != null ? DateTime.tryParse(dtStr) : null;

      final rawBreakdown = breakdownRes['powerConsumptionBreakdown']
                       ?? breakdownRes['powerProductionBreakdown'];
      _breakdown = _numMapFrom(rawBreakdown);
      _renewablePct = (breakdownRes['renewablePercentage'] as num?)?.toDouble();

      _history = historyRes
          .map((e) => _HistoryPoint(
                dt: DateTime.tryParse((e['datetime'] ?? '').toString()) ??
                    DateTime.now(),
                value: (e['carbonIntensity'] as num?)?.toDouble(),
              ))
          .where((p) => p.value != null)
          .toList()
        ..sort((a, b) => a.dt.compareTo(b.dt));

      setState(() => _loading = false);
    } on ApiException catch (e) {
      setState(() {
        _loading = false;
        _error = e.message;
      });
    }
  }

  Map<String, num> _numMapFrom(dynamic raw) {
    if (raw is! Map) return const {};
    final out = <String, num>{};
    raw.forEach((k, v) {
      if (v is num && v > 0) out[k.toString()] = v;
    });
    return out;
  }

  Future<void> _openEdit() async {
    final result = await Navigator.of(context).push<dynamic>(
      MaterialPageRoute(
        builder: (_) => EditZoneScreen(
          zone: _zone,
          apiService: widget.apiService,
        ),
      ),
    );
    if (!mounted) return;
    if (result == 'deleted') {
      Navigator.of(context).pop('deleted');
    } else if (result is ZoneMonitored) {
      setState(() => _zone = result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_zone.displayName)),
      floatingActionButton: FloatingActionButton(
        onPressed: _openEdit,
        child: const Icon(Icons.edit),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        color: AppColors.primary,
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : _error != null
                ? _buildError()
                : _buildContent(),
      ),
    );
  }

  Widget _buildError() {
    return ListView(
      children: [
        Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              const Icon(Icons.cloud_off, size: 48, color: AppColors.textSecondary),
              const SizedBox(height: 12),
              Text(
                'Errore nel caricamento\n$_error',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 12),
              TextButton(onPressed: _load, child: const Text('Riprova')),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildContent() {
    return ListView(
      padding: const EdgeInsets.only(bottom: 80),
      children: [
        _buildHeader(),
        const SizedBox(height: 8),
        _buildSectionTitle('Ultime 24 ore'),
        _buildHistoryCard(),
        const SizedBox(height: 8),
        _buildSectionTitle('Mix energetico'),
        _buildMixCard(),
        if (_zone.notes != null && _zone.notes!.trim().isNotEmpty) ...[
          const SizedBox(height: 12),
          _buildNotesCard(),
        ],
      ],
    );
  }

  Widget _buildHeader() {
    if (_intensity == null) {
      return _headerShell(
        value: const Text('—',
            style: TextStyle(
                fontSize: 52, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
        badge: null,
        subtitle: 'Dati non disponibili',
      );
    }

    final color = AppColors.carbonColor(_intensity!);
    final level = AppColors.carbonLevel(_intensity!);

    return _headerShell(
      value: Text(
        _intensity!.round().toString(),
        style: TextStyle(fontSize: 52, fontWeight: FontWeight.w700, color: color),
      ),
      badge: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          level,
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: color),
        ),
      ),
      subtitle: _intensityUpdatedAt != null
          ? 'Aggiornato ${_relativeTime(_intensityUpdatedAt!)}'
          : null,
    );
  }

  Widget _headerShell({required Widget value, Widget? badge, String? subtitle}) {
    return Container(
      width: double.infinity,
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      child: Column(
        children: [
          value,
          const SizedBox(height: 2),
          const Text(
            'gCO₂eq/kWh',
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
          if (badge != null) ...[
            const SizedBox(height: 4),
            badge,
          ],
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 12, color: Color(0xFFB4B2A9)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHistoryCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200, width: 0.5),
      ),
      child: SizedBox(
        height: 150,
        child: _history.isEmpty
            ? const Center(
                child: Text('Nessun dato storico',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              )
            : CustomPaint(
                painter: _HistoryPainter(_history),
                child: const SizedBox.expand(),
              ),
      ),
    );
  }

  Widget _buildMixCard() {
    if (_breakdown.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200, width: 0.5),
        ),
        child: const Text(
          'Mix energetico non disponibile',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
      );
    }

    final total = _breakdown.values.fold<double>(0, (a, b) => a + b.toDouble());
    final entries = _breakdown.entries
        .map((e) => MapEntry(e.key, e.value.toDouble() / total * 100))
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_renewablePct != null) ...[
            Row(
              children: [
                const Icon(Icons.eco, size: 16, color: AppColors.primaryLight),
                const SizedBox(width: 6),
                Text(
                  'Rinnovabile: ${_renewablePct!.round()}%',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.primaryDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],
          PowerMixBar(breakdown: _breakdown, height: 14, showLegend: false),
          const SizedBox(height: 16),
          for (final e in entries) ...[
            Row(
              children: [
                Text(
                  AppColors.sourceLabel(e.key),
                  style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                ),
                const Spacer(),
                Text(
                  '${e.value.round()}%',
                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: (e.value / 100).clamp(0.0, 1.0),
                minHeight: 6,
                backgroundColor: const Color(0xFFF1EFE8),
                color: AppColors.sourceColor(e.key),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }

  Widget _buildNotesCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.warning,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'La tua nota',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.warningText,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _zone.notes!,
            style: const TextStyle(fontSize: 13, color: Color(0xFF633806)),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Color(0xFF5F5E5A),
        ),
      ),
    );
  }

  String _relativeTime(DateTime dt) {
    final diff = DateTime.now().toUtc().difference(dt.toUtc());
    if (diff.inMinutes < 1) return 'pochi secondi fa';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min fa';
    if (diff.inHours < 24) return '${diff.inHours} h fa';
    return DateFormat('dd/MM HH:mm').format(dt.toLocal());
  }
}

class _HistoryPoint {
  final DateTime dt;
  final double? value;
  const _HistoryPoint({required this.dt, this.value});
}

class _HistoryPainter extends CustomPainter {
  final List<_HistoryPoint> points;
  _HistoryPainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    const double xAxisSpace = 18;
    final chartH = size.height - xAxisSpace;
    final chartW = size.width;

    final baseline = Paint()
      ..color = const Color(0xFFEDEDE6)
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(0, chartH),
      Offset(chartW, chartH),
      baseline,
    );

    if (points.length < 2) {
      _drawXAxisLabels(canvas, size, xAxisSpace);
      return;
    }

    final values = points.map((p) => p.value!).toList();
    final minV = values.reduce((a, b) => a < b ? a : b);
    final maxV = values.reduce((a, b) => a > b ? a : b);
    final span = (maxV - minV).abs() < 1 ? 1 : (maxV - minV);

    final dx = chartW / (points.length - 1);

    final linePath = Path();
    final areaPath = Path();
    for (int i = 0; i < points.length; i++) {
      final x = dx * i;
      final norm = (points[i].value! - minV) / span;
      final y = chartH - norm * (chartH - 8) - 4;
      if (i == 0) {
        linePath.moveTo(x, y);
        areaPath.moveTo(x, chartH);
        areaPath.lineTo(x, y);
      } else {
        linePath.lineTo(x, y);
        areaPath.lineTo(x, y);
      }
    }
    areaPath.lineTo(chartW, chartH);
    areaPath.close();

    canvas.drawPath(
      areaPath,
      Paint()..color = AppColors.primaryLight.withValues(alpha: 0.10),
    );
    canvas.drawPath(
      linePath,
      Paint()
        ..color = AppColors.primaryLight
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );

    _drawXAxisLabels(canvas, size, xAxisSpace);
  }

  void _drawXAxisLabels(Canvas canvas, Size size, double xAxisSpace) {
    const labels = ['00', '06', '12', '18', 'Ora'];
    final y = size.height - xAxisSpace + 4;
    for (int i = 0; i < labels.length; i++) {
      final x = (size.width / (labels.length - 1)) * i;
      final tp = TextPainter(
        text: TextSpan(
          text: labels[i],
          style: const TextStyle(fontSize: 10, color: Color(0xFFB4B2A9)),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      double offsetX = x - tp.width / 2;
      if (i == 0) offsetX = x;
      if (i == labels.length - 1) offsetX = x - tp.width;
      tp.paint(canvas, Offset(offsetX, y));
    }
  }

  @override
  bool shouldRepaint(covariant _HistoryPainter old) => old.points != points;
}
