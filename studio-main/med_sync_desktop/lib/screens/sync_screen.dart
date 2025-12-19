import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'package:med_sync_desktop/providers/sync_provider.dart';
import 'package:path/path.dart' as p;

class SyncScreen extends StatelessWidget {
  const SyncScreen({super.key});

  Future<String?> _pickDirectory({required String dialogTitle}) async {
    return await FilePicker.platform.getDirectoryPath(
        dialogTitle: dialogTitle,
    );
  }

  Future<String?> _pickSingleFile({required String dialogTitle}) async {
    final result = await FilePicker.platform.pickFiles(
       dialogTitle: dialogTitle,
       type: FileType.any, // Allow all files as requested
    );
    return result?.files.single.path;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SyncProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Med Sync Desktop - Auto Sync'),
        actions: [
            IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: provider.refreshFiles,
                tooltip: "Rescan Folders",
            )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Marg Section
            _buildDirectorySection(
              title: "Marg Setup (Medicine 1)",
              path: provider.margDirectory,
              detectedFile: provider.margDetectedFile,
              hint: "Folder containing stock*.xls / hsncodemaster*.xls",
              onBrowseFolder: () async {
                  final p = await _pickDirectory(dialogTitle: 'Select Marg Folder');
                  if (p != null) provider.setMargDirectory(p);
              },
              onManualFile: () async {
                  final f = await _pickSingleFile(dialogTitle: "Select Marg File (.xls)");
                  if (f != null) provider.setMargFileManual(f);
              }
            ),
            
            const SizedBox(height: 16),
            
            // PMBI Section
            _buildDirectorySection(
              title: "PMBI Setup (Medicine 2)",
              path: provider.pmbiDirectory,
              detectedFile: provider.pmbiDetectedFile,
              hint: "Folder containing StockReport*.xlsx",
              onBrowseFolder: () async {
                  final p = await _pickDirectory(dialogTitle: 'Select PMBI Folder');
                  if (p != null) provider.setPmbiDirectory(p);
              },
              onManualFile: () async {
                  final f = await _pickSingleFile(dialogTitle: "Select PMBI File");
                  if (f != null) provider.setPmbiFileManual(f);
              }
            ),
            
            const SizedBox(height: 20),

             // Delete choice
            CheckboxListTile(
              title: const Text("Delete Excel files after successful sync"),
              value: provider.deleteFilesAfterSync,
              onChanged: (val) => provider.setDeleteFilesAfterSync(val ?? false),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
            
            const SizedBox(height: 20),

            // Sync button
            ElevatedButton.icon(
              icon: const Icon(Icons.cloud_upload),
              label: const Text('Start Sync'),
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

  Widget _buildDirectorySection({
      required String title,
      required String? path,
      required String? detectedFile,
      required String hint,
      required VoidCallback onBrowseFolder,
      required VoidCallback onManualFile,
  }) {
      return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
              color: Colors.grey.shade50
          ),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 8),
                  
                  // Folder Row
                  Row(
                      children: [
                          Expanded(
                              child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                                  decoration: BoxDecoration(
                                      color: Colors.white,
                                      border: Border.all(color: Colors.grey.shade400),
                                      borderRadius: BorderRadius.circular(4)
                                  ),
                                  child: Text(
                                      path ?? "No Folder Selected",
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(color: path == null ? Colors.grey : Colors.black87)
                                  )
                              )
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                              onPressed: onBrowseFolder,
                              child: const Text("Folder"),
                          )
                      ]
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Status & File Row
                  Row(
                      children: [
                          Icon(
                              detectedFile != null ? Icons.check_circle : Icons.warning_amber_rounded,
                              size: 18,
                              color: detectedFile != null ? Colors.green : Colors.orange
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                      Text(
                                          detectedFile != null ? "Found: ${p.basename(detectedFile)}" : "File not found in folder",
                                          style: TextStyle(
                                              fontWeight: FontWeight.w500,
                                              fontSize: 13,
                                              color: detectedFile != null ? Colors.green.shade700 : Colors.orange.shade800
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                      ),
                                  ]
                              )
                          ),
                          TextButton(
                              onPressed: onManualFile,
                              child: const Text("Select File", style: TextStyle(fontSize: 12)),
                          )
                      ]
                  )
              ]
          )
      );
  }
}

