import 'package:flutter/material.dart';

class AppInfoPage extends StatelessWidget {
  final VoidCallback onBack;

  const AppInfoPage({
    Key? key,
    required this.onBack,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const appVersion = '1.0.0';

    return Scaffold(
      appBar: AppBar(
        title: const Text('App Info'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: onBack,
          tooltip: 'Back',
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text('Version'),
            subtitle: Text(appVersion),
          ),
        ],
      ),
    );
  }
}
