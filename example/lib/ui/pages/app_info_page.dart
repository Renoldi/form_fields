import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:form_fields_example/localization/example_localizations.dart';
import 'package:form_fields_example/state/pages/app_info_view_model.dart';

class AppInfoPage extends StatelessWidget {
  final VoidCallback onBack;

  const AppInfoPage({
    super.key,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppInfoViewModel(),
      child: Consumer<AppInfoViewModel>(
        builder: (context, viewModel, _) {
          return Scaffold(
            appBar: AppBar(
              title: Text(ExampleLocalizations.of(context).get('appInfo')),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: onBack,
                tooltip: ExampleLocalizations.of(context).get('back'),
              ),
            ),
            body: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(ExampleLocalizations.of(context).get('version')),
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
