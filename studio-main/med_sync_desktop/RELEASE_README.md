# Deployment Instructions

To run this application on another PC, follow these steps:

## 1. Copy Files
You cannot copy just the `.exe` file. You must copy the entire `Release` folder (or its contents).
Location: `build\windows\x64\runner\Release`

The folder should contain:
- `med_sync_desktop.exe`
- `flutter_windows.dll`
- `data\` (folder)
- `permission_handler_windows_plugin.dll` (and other plugins if present)

## 2. Prerequisites
The target PC must have the **Microsoft Visual C++ Redistributable** installed.
Most Windows PCs already have this, but if the app fails to start (or shows a "missing dll" error), download and install it from Microsoft:

- [Download Visual C++ Redistributable](https://aka.ms/vs/17/release/vc_redist.x64.exe)

## 3. Run
Open the folder on the new PC and double-click `med_sync_desktop.exe`.
