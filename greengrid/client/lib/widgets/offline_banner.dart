import 'package:flutter/material.dart';

import '../config/app_colors.dart';

/// Banner compatto mostrato quando il dispositivo è offline.
///
/// Specifiche: sfondo [AppColors.warning], pallino arancione [AppColors.solar],
/// testo [AppColors.warningText] "Offline — dati dalla cache locale".
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.warning,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          _Dot(),
          SizedBox(width: 8),
          Text(
            'Offline — dati dalla cache locale',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.warningText,
            ),
          ),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: const BoxDecoration(
        color: AppColors.solar,
        shape: BoxShape.circle,
      ),
    );
  }
}
