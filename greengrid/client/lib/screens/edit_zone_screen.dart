import 'package:flutter/material.dart';

import '../config/app_colors.dart';
import '../models/zone_monitored.dart';
import '../services/api_service.dart';
import '../services/connectivity_service.dart';
import '../services/database_helper.dart';


class EditZoneScreen extends StatefulWidget {
  final ZoneMonitored zone;
  final ApiService apiService;

  const EditZoneScreen({
    super.key,
    required this.zone,
    required this.apiService,
  });

  @override
  State<EditZoneScreen> createState() => _EditZoneScreenState();
}

class _EditZoneScreenState extends State<EditZoneScreen> {
  late final TextEditingController _labelCtrl;
  late final TextEditingController _notesCtrl;
  bool _saving = false;
  bool _deleting = false;

  @override
  void initState() {
    super.initState();
    _labelCtrl = TextEditingController(text: widget.zone.userLabel ?? '');
    _notesCtrl = TextEditingController(text: widget.zone.notes ?? '');
  }

  @override
  void dispose() {
    _labelCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<bool> _ensureOnline() async {
    final online = await ConnectivityService().isOnline();
    if (online) return true;
    if (!mounted) return false;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Impossibile modificare, controlla la connessione')),
    );
    return false;
  }

  Future<void> _save() async {
    if (!await _ensureOnline()) return;
    setState(() => _saving = true);
    try {
      final updated = await widget.apiService.patchZone(widget.zone.id!, {
        'user_label': _labelCtrl.text.trim().isEmpty ? null : _labelCtrl.text.trim(),
        'notes':      _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      });
      await DatabaseHelper.instance.cacheZone(updated);
      if (!mounted) return;
      Navigator.of(context).pop(updated);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Errore: ${e.message}')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _confirmDelete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Elimina zona'),
        content: const Text('Sei sicuro di voler eliminare questa zona?'),
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
    if (ok != true) return;
    if (!await _ensureOnline()) return;

    setState(() => _deleting = true);
    try {
      await widget.apiService.deleteZone(widget.zone.id!);
      await DatabaseHelper.instance.removeCachedZone(widget.zone.id!);
      if (!mounted) return;
      Navigator.of(context).pop('deleted');
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Errore: ${e.message}')),
      );
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Modifica zona')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.zone.zoneName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: AppColors.primaryDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.zone.zoneKey,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF085041),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _labelCtrl,
              decoration: const InputDecoration(
                labelText: 'La tua etichetta',
                hintText: 'es. Casa, Ufficio…',
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _notesCtrl,
              maxLines: 4,
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
                onPressed: _saving || _deleting ? null : _save,
                child: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Salva modifiche'),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: _saving || _deleting ? null : _confirmDelete,
                child: _deleting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.error,
                        ),
                      )
                    : const Text('Elimina zona'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
