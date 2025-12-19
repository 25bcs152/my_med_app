import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/app_state.dart';
import '../models/medicine.dart';
import '../widgets/medicine_list.dart';
import '../widgets/search_input.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController1 = TextEditingController();
  final TextEditingController _searchController2 = TextEditingController();
  final TextEditingController _searchController3 = TextEditingController();

  late Stream<List<Medicine1>> _medicine1Stream;
  late Stream<List<Medicine2>> _medicine2Stream;


  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    // OPTIMIZATION: Initialize streams ONCE to avoid re-reads on setState
    // OPTIMIZATION: Listen to a SINGLE document instead of a whole collection
    _medicine1Stream = FirebaseFirestore.instance
        .collection('metadata')
        .doc('medicine_1_data')
        .snapshots()
        .map((snapshot) {
          final data = snapshot.data();
          if (data == null || !data.containsKey('items')) return [];
          final List<dynamic> items = data['items'];
          return items.map((item) => Medicine1.fromJson(item)).toList();
        });

    _medicine2Stream = FirebaseFirestore.instance
        .collection('metadata')
        .doc('medicine_2_data')
        .snapshots()
        .map((snapshot) {
          final data = snapshot.data();
          if (data == null || !data.containsKey('items')) return [];
          final List<dynamic> items = data['items'];
          return items.map((item) => Medicine2.fromJson(item)).toList();
        });
  }



  @override
  void dispose() {
    _tabController.dispose();
    _searchController1.dispose();
    _searchController2.dispose();
    _searchController3.dispose();
    super.dispose();
  }

  void _launchLocation() async {
    const url = "https://www.google.com/maps/search/?api=1&query=F12,+1st+Floor,+Madhava+Square,+Station+Road,+Malmaddi,+Dharwad+–+580007,+Karnataka,+India";
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA), // Light greyish blue background
      body: Column(
        children: [
          // Custom Header
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Column(
              children: [
                 // Top Bar: Address & Actions
                 Row(
                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                   children: [
                      Flexible(
                        child: InkWell(
                          onTap: _launchLocation,
                          child: const Text(
                            "F12, 1st Floor, Madhava Square, Station Road, Malmaddi, Dharwad...",
                             style: TextStyle(fontSize: 12, color: Colors.grey, overflow: TextOverflow.ellipsis),
                          ),
                        ),
                      ),
                      Row(
                        children: [

                          TextButton.icon(
                             onPressed: () => _tabController.animateTo(2),
                             icon: const Icon(LucideIcons.shoppingCart, size: 16),
                             label: Text(appState.t('my_medicines')),
                             style: TextButton.styleFrom(foregroundColor: Colors.grey.shade800),
                          ),
                          const SizedBox(width: 8),
                          PopupMenuButton<String>(
                            child: Row(
                              children: [
                                const Icon(LucideIcons.languages, size: 16, color: Colors.grey),
                                const SizedBox(width: 4),
                                Text(appState.language == 'english' ? 'English' : 'ಕನ್ನಡ', style: const TextStyle(color: Colors.grey)),
                              ],
                            ),
                            onSelected: (value) => appState.setLanguage(value),
                            itemBuilder: (context) => [
                              const PopupMenuItem(value: 'english', child: Text('English')),
                              const PopupMenuItem(value: 'kannada', child: Text('ಕನ್ನಡ')),
                            ],
                          ),
                        ],
                      )
                   ],
                 ),
                 const SizedBox(height: 32),
                 // Logo & Title
                 // Placeholder for Logo - In real app use Image.asset
                 const Icon(LucideIcons.pill, size: 40, color: Colors.teal), 
                 const SizedBox(height: 16),
                 Text(appState.t('app_title') + " - Dharwad", 
                    style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF4B5563))),
                 const Text("Welcome to Jan Aushadhi", 
                    style: TextStyle(fontSize: 14, color: Colors.grey)),
                 const SizedBox(height: 32),
                 
                 // Tabs (Segmented Control Style)
                 Container(
                   decoration: BoxDecoration(
                     color: Colors.grey.shade100,
                     borderRadius: BorderRadius.circular(8),
                   ),
                   padding: const EdgeInsets.all(4),
                   child: TabBar(
                     controller: _tabController,
                     indicator: BoxDecoration(
                       color: Colors.white,
                       borderRadius: BorderRadius.circular(6),
                       boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 2, offset: const Offset(0, 1))],
                     ),
                     indicatorSize: TabBarIndicatorSize.tab,
                     labelColor: Colors.black,
                     unselectedLabelColor: Colors.grey,
                     dividerColor: Colors.transparent,
                     tabs: [
                       Tab(text: appState.t('tab1_title')), // Generic
                       Tab(text: appState.t('tab2_title')), // Jan Aushadhi
                       Tab(text: appState.t('my_medicines')),
                     ],
                   ),
                 ),
              ],
            ),
          ),
          
          // Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              // physics: const NeverScrollableScrollPhysics(), // Allow swiping or keep logic? Desktop web usually doesn't swipe tabs.
              // Logic: _buildSearchTab has a Column with Expanded List. 
              // TabBarView needs to be in Expanded to give height to children.
              children: [
                _buildSearchTab(
                  controller: _searchController1,
                  placeholder: appState.t('search_placeholder_product'),
                  stream: _medicine1Stream,
                  filter: (medicines, query) => medicines.where((m) {
                        final q = query.toLowerCase();
                        return m.productName.toLowerCase().contains(q) ||
                            m.productNameKn.toLowerCase().contains(q);
                      }).toList(),
                  appState: appState,
                ),
                 _buildSearchTab(
                  controller: _searchController2,
                  placeholder: appState.t('search_placeholder_drug'),
                  stream: _medicine2Stream,
                   filter: (medicines, query) => medicines.where((m) {
                        final q = query.toLowerCase();
                        return m.drugName.toLowerCase().contains(q) ||
                            m.drugNameKn.toLowerCase().contains(q);
                      }).toList(),
                   appState: appState,
                ),
                _buildMyMedicinesTab(appState),
              ],
            ),
          ),
        ],
      ),
      // Removed generic FAB to match Web UI clean look
    );
  }

  Widget _buildSearchTab<T extends Medicine>({
    required TextEditingController controller,
    required String placeholder,
    required Stream<List<T>> stream,
    required List<T> Function(List<T>, String) filter,
    required AppState appState,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: SearchInput(controller: controller, hint: placeholder, onChanged: (val) => setState((){})),
        ),
        Expanded(
          child: StreamBuilder<List<T>>(
            stream: stream,
            builder: (context, snapshot) {
              if (snapshot.hasError) return const Center(child: Text("Error loading data"));
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

              final filtered = filter(snapshot.data!, controller.text);
              return MedicineList(medicines: filtered, showAdd: true);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMyMedicinesTab(AppState appState) {
     final filtered = appState.myMedicines.where((m) {
       final q = _searchController3.text.toLowerCase();
       if(m is Medicine1) {
          return m.productName.toLowerCase().contains(q) || m.productNameKn.toLowerCase().contains(q);
       }
       if(m is Medicine2) {
         return m.drugName.toLowerCase().contains(q) || m.drugNameKn.toLowerCase().contains(q);
       }
       return false;
     }).toList();
     
     return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: SearchInput(controller: _searchController3, hint: appState.t('search_my_medicines'), onChanged: (val)=>setState((){})),
        ),
        Expanded(
          child: MedicineList(medicines: filtered, showAdd: false),
        ),
      ],
    );
  }
}
