import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:med_sync_desktop/providers/sync_provider.dart';
import 'package:med_sync_desktop/screens/sync_screen.dart';

void main() {
  runApp(const MedSyncApp());
}

class MedSyncApp extends StatelessWidget {
  const MedSyncApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SyncProvider(),
      child: MaterialApp(
        title: 'Med Sync Desktop',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        ),
        home: const SyncScreen(),
      ),
    );
  }
}
