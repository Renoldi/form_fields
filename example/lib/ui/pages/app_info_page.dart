import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:form_fields_example/state/pages/app_info_view_model.dart';

class AppInfoPage extends StatelessWidget {
  final VoidCallback onBack;

  const AppInfoPage({
    Key? key,
    required this.onBack,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppInfoViewModel(),
      child: Consumer<AppInfoViewModel>(
        builder: (context, viewModel, _) {
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
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Version'),
                  subtitle: Text(viewModel.appVersion),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
