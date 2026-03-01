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
            title: Text(context.tr('appInfo')),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: widget.onBack,
              tooltip: context.tr('back'),
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(context.tr('version')),
                subtitle: Text(viewModel.appVersion),
              ),
            ],
          ),
        );
      },
    );
  }
}
