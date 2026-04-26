import 'package:flutter/material.dart';

import '../config/app_colors.dart';
import '../models/carbon_reading.dart';
import '../models/zone_monitored.dart';
import 'power_mix_bar.dart';

class ZoneCard extends StatelessWidget {
  final ZoneMonitored zone;
  final CarbonReading? latestReading;
  final VoidCallback? onTap;
  final Future<void> Function()? onDelete;

  const ZoneCard({
    super.key,
    required this.zone,
    this.latestReading,
    this.onTap,
    this.onDelete,
  });

  static Color _intensityColor(double v) {
    if (v < 150) return AppColors.primary;
    if (v <= 400) return AppColors.carbonHigh;
    return AppColors.error;
  }

  Future<void> _confirmDelete(BuildContext context) async {
    if (onDelete == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rimuovi zona'),
        content: Text('Vuoi rimuovere "${zone.displayName}" dalle zone monitorate?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Annulla'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Elimina'),
          ),
        ],
      ),
    );
    if (ok == true) await onDelete!.call();
  }

  @override
  Widget build(BuildContext context) {
    final intensity = latestReading?.carbonIntensity;
    final breakdown = latestReading?.powerBreakdown;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        onLongPress: onDelete == null ? null : () => _confirmDelete(context),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: _LeftBlock(zone: zone)),
                  const SizedBox(width: 12),
                  _RightBlock(intensity: intensity),
                ],
              ),
              if (breakdown != null && breakdown.isNotEmpty) ...[
                const SizedBox(height: 10),
                PowerMixBar(
                  breakdown: _toNumMap(breakdown),
                  height: 8,
                  showLegend: false,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Map<String, num> _toNumMap(Map<String, dynamic> m) {
    final out = <String, num>{};
    m.forEach((k, v) {
      if (v is num) {
        out[k] = v;
      } else if (v is String) {
        final n = num.tryParse(v);
        if (n != null) out[k] = n;
      }
    });
    return out;
  }
}

class _LeftBlock extends StatelessWidget {
  final ZoneMonitored zone;
  const _LeftBlock({required this.zone});

  @override
  Widget build(BuildContext context) {
    final notes = zone.notes;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          zone.displayName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          zone.zoneKey,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        if (notes != null && notes.trim().isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            notes,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              fontStyle: FontStyle.italic,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ],
    );
  }
}

class _RightBlock extends StatelessWidget {
  final double? intensity;
  const _RightBlock({this.intensity});

  @override
  Widget build(BuildContext context) {
    if (intensity == null) {
      return const Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '—',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            'gCO₂',
            style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
        ],
      );
    }

    final color = ZoneCard._intensityColor(intensity!);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          intensity!.round().toString(),
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
        const Text(
          'gCO₂',
          style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}
