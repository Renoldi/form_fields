import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:form_fields_example/state/app_state_notifier.dart';
import 'package:form_fields_example/state/pages/language_view_model.dart';

class LanguagePage extends StatelessWidget {
  final VoidCallback onBack;

  const LanguagePage({
    Key? key,
    required this.onBack,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => LanguageViewModel(context.read<AppStateNotifier>()),
      child: Consumer<LanguageViewModel>(
        builder: (context, viewModel, _) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Language'),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: onBack,
                tooltip: 'Back',
              ),
            ),
            body: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _LanguageTile(
                  title: 'English (US)',
                  selected: viewModel.isEnglish,
                  onTap: viewModel.setEnglish,
                ),
                _LanguageTile(
                  title: 'Indonesian (ID)',
                  selected: viewModel.isIndonesian,
                  onTap: viewModel.setIndonesian,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _LanguageTile extends StatelessWidget {
  final String title;
  final bool selected;
  final VoidCallback onTap;

  const _LanguageTile({
    required this.title,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title),
      trailing: selected
          ? const Icon(Icons.check_circle, color: Colors.green)
          : const Icon(Icons.circle_outlined, color: Colors.grey),
      onTap: onTap,
    );
  }
}
