import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'package:med_sync_desktop/providers/sync_provider.dart';

class SyncScreen extends StatefulWidget {
  const SyncScreen({super.key});

  @override
  State<SyncScreen> createState() => _SyncScreenState();
}

class _SyncScreenState extends State<SyncScreen> {
  @override
  void initState() {
    super.initState();
    // Trigger auto-detection on app start
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SyncProvider>().autoDetectXlsxFolder();
    });
  }

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
  
  Future<String?> _pickDirectory({required String dialogTitle}) async {
    return await FilePicker.platform.getDirectoryPath(
        dialogTitle: dialogTitle,
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SyncProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Med Sync Desktop - Excel Upload'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Auto-detection info
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Auto-Sync Mode',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    const Text('This app automatically looks for an "xlsx" folder in the app directory.'),
                    const SizedBox(height: 4),
                    Text(
                      'xlsx Folder: ${provider.xlsxFolderPath ?? "Not found"}',
                      style: TextStyle(
                        color: provider.xlsxFolderPath != null ? Colors.green : Colors.red,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Manual folder selection button
            if (provider.xlsxFolderPath == null)
              ElevatedButton.icon(
                icon: const Icon(Icons.folder_open),
                label: const Text('Select xlsx Folder Manually'),
                onPressed: () async {
                  final p = await _pickDirectory(dialogTitle: 'Select xlsx Folder');
                  if (p != null) {
                    provider.setXlsxFolder(p);
                    await provider.autoDetectXlsxFolder();
                  }
                },
              ),
            const SizedBox(height: 12),

            // Detected files display
            if (provider.margFilePath != null || provider.pmbiFilePath != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Detected Files:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      if (provider.margFilePath != null)
                        Text('✓ Marg: ${provider.margFilePath!.split('\\').last}'),
                      if (provider.pmbiFilePath != null)
                        Text('✓ PMBI: ${provider.pmbiFilePath!.split('\\').last}'),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 20),

            // Sync button
            ElevatedButton.icon(
              icon: const Icon(Icons.cloud_upload),
              label: const Text('Start Sync (Upload Excel Data)'),
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
    String? hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
           children: [
             Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
             if (hint != null) ...[
                 const SizedBox(width: 8),
                 Expanded(child: Text(hint, style: TextStyle(fontSize: 10, color: Colors.indigo[900], fontStyle: FontStyle.italic), overflow: TextOverflow.ellipsis)),
             ]
           ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade400),
                      borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    path ?? 'Not Selected',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: path != null ? Colors.black87 : Colors.grey.shade500,
                    ),
                  )
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: onBrowse,
              style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              ),
              child: const Text('Browse'),
            ),
          ],
        ),
      ],
    );
  }
}
