import 'package:flutter/material.dart';

import '../config/app_colors.dart';

/// Barra colorata che visualizza il mix energetico di una zona, più una
/// legenda opzionale con le percentuali.
///
/// La `breakdown` ha come chiavi i nomi delle fonti come arrivano dall'API
/// Electricity Maps (`solar`, `wind`, `hydro`, `nuclear`, `gas`, `coal`,
/// `oil`, `biomass`, `geothermal`, `unknown`) e come valori le percentuali
/// (0–100) oppure i MW (verranno normalizzati a percentuali).
class PowerMixBar extends StatelessWidget {
  final Map<String, num> breakdown;
  final double height;
  final bool showLegend;

  /// Soglia (in %) sotto la quale la fonte non appare in legenda.
  static const double _legendThreshold = 2.0;

  const PowerMixBar({
    super.key,
    required this.breakdown,
    this.height = 8,
    this.showLegend = true,
  });

  @override
  Widget build(BuildContext context) {
    final entries = _normalizedEntries();

    final bar = ClipRRect(
      borderRadius: BorderRadius.circular(height / 2),
      child: SizedBox(
        height: height,
        child: entries.isEmpty
            ? Container(color: Colors.grey.shade200)
            : Row(
                children: [
                  for (final e in entries)
                    Expanded(
                      flex: (e.value * 100).round().clamp(1, 100000),
                      child: Container(color: AppColors.sourceColor(e.key)),
                    ),
                ],
              ),
      ),
    );

    if (!showLegend) return bar;

    final legendItems = [
      for (final e in entries)
        if (e.value >= _legendThreshold) e,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        bar,
        if (legendItems.isNotEmpty) ...[
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final e in legendItems) _LegendChip(source: e.key, pct: e.value),
            ],
          ),
        ],
      ],
    );
  }

  /// Converte la mappa in una lista di entry percentuali > 0, ordinate
  /// decrescenti. Se i valori totali non sembrano essere già percentuali
  /// (ad es. watt), li rinormalizza a somma 100.
  List<MapEntry<String, double>> _normalizedEntries() {
    final filtered = <String, double>{};
    breakdown.forEach((k, v) {
      final d = v.toDouble();
      if (d > 0) filtered[k] = d;
    });
    if (filtered.isEmpty) return const [];

    final total = filtered.values.fold<double>(0, (a, b) => a + b);
    final needsNormalization = total > 105 || total < 95;

    final list = filtered.entries
        .map((e) => MapEntry(
              e.key,
              needsNormalization ? (e.value / total) * 100 : e.value,
            ))
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return list;
  }
}

class _LegendChip extends StatelessWidget {
  final String source;
  final double pct;
  const _LegendChip({required this.source, required this.pct});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: AppColors.sourceColor(source),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          '${AppColors.sourceLabel(source)} ${pct.round()}%',
          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}
