import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/medicine.dart';
import '../providers/app_state.dart';

class MedicineList extends StatelessWidget {
  final List<Medicine> medicines;
  final bool showAdd;

  const MedicineList({super.key, required this.medicines, required this.showAdd});

  @override
  Widget build(BuildContext context) {
    if (medicines.isEmpty) {
      return const Center(child: Text("No medicines found"));
    }

    // Use LayoutBuilder to decide between List (mobile) and Grid (Tablet/Web)
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 600) {
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 300,
              childAspectRatio: 0.6, // Adjusted to prevent overflow
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: medicines.length,
            itemBuilder: (context, index) {
              return MedicineCard(medicine: medicines[index], showAdd: showAdd);
            },
          );
        } else {
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: medicines.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              return MedicineCard(medicine: medicines[index], showAdd: showAdd);
            },
          );
        }
      },
    );
  }
}

class MedicineCard extends StatelessWidget {
  final Medicine medicine;
  final bool showAdd;

  const MedicineCard({super.key, required this.medicine, required this.showAdd});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final isEnglish = appState.language == 'english';

    String title = '';
    String subtitle = '';
    Map<String, String> details = {};
    String? id;

    if (medicine is Medicine1) {
      final m = medicine as Medicine1;
      title = isEnglish ? m.productName : m.productNameKn;
      if (title.isEmpty) title = m.productName;
      subtitle = 'Jan Aushadhi - ${m.id}';
      if(m.currentStock != null) details['Quantity'] = m.currentStock!; // Mapping 'Stock' to 'Quantity' as per screenshot visual
      // Screenshot shows "UOM", "Batch No", "MRP", "Expiry"
      // Medicine1 has MRP and EXP. It might usually map to Product Name.
      if(m.mrp != null) details['MRP'] = m.mrp!;
       
    } else if (medicine is Medicine2) {
      final m = medicine as Medicine2;
      title = isEnglish ? m.drugName : m.drugNameKn;
      if (title.isEmpty) title = m.drugName;
      subtitle = 'Jan Aushadhi - ${m.drugCode}'; // Using Drug Code as ID
      
      // Matching Screenshot fields
      if(m.qty != null) details['Quantity'] = m.qty!;
      if(m.uom != null) details['UOM'] = m.uom!;
      if(m.batchNo != null) details['Batch No'] = m.batchNo!;
      if(m.mrp != null) details['MRP'] = m.mrp!;
    }
    
    final expiry = medicine.expiryDateAsString;
    if (expiry != null) details['Expiry'] = expiry;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            // Subtitle (ID)
            Text(
              subtitle,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            // Details Grid
            Expanded(
              child: Column(
                children: details.entries.map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    children: [
                      _getIcon(e.key),
                      const SizedBox(width: 8),
                      Text(appState.t(e.key), style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                      const Spacer(),
                      Text(e.value, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12)),
                    ],
                  ),
                )).toList(),
              ),
            ),
             if (showAdd) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                       context.read<AppState>().addToMyMedicines(medicine);
                       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${title} ${appState.t('added')}')));
                    },
                    icon: const Icon(LucideIcons.plusCircle, size: 16),
                    label: Text(appState.t('add') + " to My Medicines"), // Simplified localized string combination
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.teal,
                      side: const BorderSide(color: Colors.teal),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      textStyle: const TextStyle(fontSize: 12),
                    ),
                  ),
                )
             ] else ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                       context.read<AppState>().removeFromMyMedicines(medicine);
                       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${title} removed')));
                    },
                    icon: const Icon(LucideIcons.trash2, size: 16),
                    label: const Text("Remove"),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      textStyle: const TextStyle(fontSize: 12),
                    ),
                  ),
                )
             ]
          ],
        ),
      ),
    );
  }

  Widget _getIcon(String key) {
    IconData icon = LucideIcons.circle;
    switch (key) {
      case 'Quantity':
      case 'Qty':
        icon = LucideIcons.package; 
        break;
      case 'UOM':
        icon = LucideIcons.scale;
        break;
      case 'Batch No':
        icon = LucideIcons.box;
        break;
      case 'MRP':
        icon = LucideIcons.indianRupee;
        break;
      case 'Expiry':
        icon = LucideIcons.calendar;
        break;
    }
    return Icon(icon, size: 14, color: Colors.grey.shade400);
  }
}
