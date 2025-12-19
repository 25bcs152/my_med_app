import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'package:med_sync_marg_pmbi/providers/sync_provider.dart';

class SyncScreen extends StatelessWidget {
  const SyncScreen({super.key});

  Future<String?> _pickFile({
    required List<String> allowedExtensions,
    required String dialogTitle,
  }) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: allowedExtensions,
      dialogTitle: dialogTitle,
    );
    if (result != null && result.files.isNotEmpty) {
      return result.files.single.path;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SyncProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Med Sync Desktop'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Service Account picker
            _buildPathRow(
              label: 'Service Account JSON',
              path: provider.serviceAccountPath,
              onBrowse: () async {
                final p = await _pickFile(
                  allowedExtensions: ['json'],
                  dialogTitle: 'Select Firebase Service Account JSON',
                );
                if (p != null) provider.setServiceAccount(p);
              },
            ),
            const SizedBox(height: 12),

            // Marg Excel picker (defaults to xlsx folder)
            _buildPathRow(
              label: 'Marg Excel (.xlsx)',
              path: provider.margPath,
              onBrowse: () async {
                final p = await _pickFile(
                  allowedExtensions: ['xlsx'],
                  dialogTitle: 'Select Marg Excel file',
                );
                if (p != null) provider.setMargPath(p);
              },
            ),
            const SizedBox(height: 12),

            // PMBI Excel picker
            _buildPathRow(
              label: 'PMBI Excel (.xlsx)',
              path: provider.pmbiPath,
              onBrowse: () async {
                final p = await _pickFile(
                  allowedExtensions: ['xlsx'],
                  dialogTitle: 'Select PMBI Excel file',
                );
                if (p != null) provider.setPmbiPath(p);
              },
            ),
            const SizedBox(height: 20),

            // Sync button
            ElevatedButton.icon(
              icon: const Icon(Icons.sync),
              label: const Text('Start Sync (Upload to Firebase)'),
              onPressed: provider.isSyncing ? null : provider.startSync,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                backgroundColor: const Color(0xFF1976D2),
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 20),

            // Log view
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(4),
                ),
                padding: const EdgeInsets.all(8),
                child: SingleChildScrollView(
                  child: Text(
                    provider.log.join('\n'),
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPathRow({
    required String label,
    required String? path,
    required VoidCallback onBrowse,
  }) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        ),
        Expanded(
          flex: 5,
          child: Text(
            path ?? '',
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.black87),
          ),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: onBrowse,
          child: const Text('Browse'),
        ),
      ],
    );
  }
}
