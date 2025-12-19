Med Sync System
This repository contains the source code for the Med Sync System, a comprehensive solution for synchronizing and managing medicine inventory data from local sources (like Marg ERP and PMBI) to a cloud database and a mobile application.

The system consists of three main components:
1)Desktop Application (med_sync_desktop): For synchronizing data from local PCs to Firebase.

2)Mobile Application (my_med_app): For viewing medicine availability and details on Android devices.

3)Firebase Backend: Acts as the central data store and synchronization hub.

1. Desktop Application (med_sync_desktop)
The Desktop Application is a Windows-based tool built with Flutter. It serves as the "bridge" between local inventory systems and the cloud.

Key Features:
Data Synchronization: Reads inventory data from local Excel (.xlsx, .xls) or database files.
Secure Upload: Uses a Google Service Account (serviceAccount.json) to securely authenticate and upload data to Firebase Firestore.
Batch Processing: Efficiently handles large datasets by uploading in batches to respect Firestore limits.
Data Management: Automatically cleans old collections and updates metadata for tracking.
Multi-Source Support: Handles multiple medicine data sources (Marg, PMBI).
Tech Stack
Framework: Flutter (Windows)
Language: Dart
Key Libraries: googleapis, file_picker, excel, dbf_reader, provider.

2. Mobile Application (my_med_app)
The Mobile Application is an Android app built with Flutter, designed for end-users to check medicine stock.

Key Features
Real-time Availability: Displays up-to-date medicine information synced from the desktop app.
My Medicines: Personal list feature for tracking specific medicines.
Search & Filter: Fast search functionality.
Modern UI: Material 3 design with Instrument Sans typography.
Tech Stack
Framework: Flutter (Android)
Language: Dart
Key Libraries: firebase_core, cloud_firestore, provider, shared_preferences.

3. Firebase Backend
The system uses Google Firebase (Cloud Firestore) as the central NoSQL database.

Collections: medicine_1_data, medicine_2_data, metadata.
