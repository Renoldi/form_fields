import 'package:flutter/material.dart';

class GridItemData {
  final String label;
  final IconData icon;
  final Color color;
  final String? badge;

  const GridItemData({
    required this.label,
    required this.icon,
    required this.color,
    this.badge,
  });
}

class ViewModel extends ChangeNotifier {
  // ── Demo datasets ────────────────────────────────────────────────────────

  static const List<GridItemData> sampleApps = [
    GridItemData(label: 'Messages', icon: Icons.message, color: Colors.blue),
    GridItemData(label: 'Camera', icon: Icons.camera_alt, color: Colors.green),
    GridItemData(label: 'Music', icon: Icons.music_note, color: Colors.purple),
    GridItemData(label: 'Maps', icon: Icons.map, color: Colors.teal),
    GridItemData(
        label: 'Calendar', icon: Icons.calendar_today, color: Colors.orange),
    GridItemData(label: 'Settings', icon: Icons.settings, color: Colors.grey),
    GridItemData(
        label: 'Photos', icon: Icons.photo_library, color: Colors.pink),
    GridItemData(label: 'Weather', icon: Icons.wb_sunny, color: Colors.amber),
    GridItemData(label: 'Notes', icon: Icons.note, color: Colors.brown),
    GridItemData(label: 'Files', icon: Icons.folder, color: Colors.indigo),
    GridItemData(label: 'Clock', icon: Icons.access_time, color: Colors.red),
    GridItemData(label: 'News', icon: Icons.newspaper, color: Colors.cyan),
  ];

  static const List<GridItemData> sampleMenu = [
    GridItemData(
        label: 'Profile', icon: Icons.person, color: Colors.blue, badge: null),
    GridItemData(
        label: 'Orders',
        icon: Icons.shopping_bag,
        color: Colors.green,
        badge: '3'),
    GridItemData(
        label: 'Wallet',
        icon: Icons.account_balance_wallet,
        color: Colors.purple),
    GridItemData(
        label: 'Voucher',
        icon: Icons.local_offer,
        color: Colors.red,
        badge: 'New'),
    GridItemData(label: 'History', icon: Icons.history, color: Colors.teal),
    GridItemData(label: 'Help', icon: Icons.help_outline, color: Colors.orange),
  ];

  // ── State ─────────────────────────────────────────────────────────────────

  double itemSize = 80;
  double horizontalMargin = 16;
  double verticalSpacing = 16;
  bool alignLeft = false;

  String? lastTapped;

  void updateItemSize(double v) {
    itemSize = v;
    notifyListeners();
  }

  void updateHorizontalMargin(double v) {
    horizontalMargin = v;
    notifyListeners();
  }

  void updateVerticalSpacing(double v) {
    verticalSpacing = v;
    notifyListeners();
  }

  void toggleAlignLeft(bool v) {
    alignLeft = v;
    notifyListeners();
  }

  void tap(String label) {
    lastTapped = label;
    notifyListeners();
  }
}
