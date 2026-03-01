import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:form_fields_example/localization/localizations.dart';
import 'presenter.dart';
import 'view_model.dart';

class View extends PresenterState {
  @override
  Widget build(BuildContext context) {
    return Consumer<ViewModel>(
      builder: (context, viewModel, _) {
        return Scaffold(
          appBar: AppBar(
            title: Text(context.tr('language')),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: widget.onBack,
              tooltip: context.tr('back'),
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _LanguageTile(
                title: context.tr('englishUS'),
                selected: viewModel.isEnglish,
                onTap: () => handleSetEnglish(viewModel),
              ),
              _LanguageTile(
                title: context.tr('indonesianID'),
                selected: viewModel.isIndonesian,
                onTap: () => handleSetIndonesian(viewModel),
              ),
            ],
          ),
        );
      },
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
