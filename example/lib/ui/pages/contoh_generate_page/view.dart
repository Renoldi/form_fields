import 'package:flutter/material.dart';
import 'package:form_fields/form_fields.dart';
import 'presenter.dart';
import 'view_model.dart';
import 'package:provider/provider.dart';
import 'package:form_fields_example/localization/localizations.dart';

class View extends PresenterState {
  @override
  Widget build(BuildContext context) {
    return Consumer<ViewModel>(
      builder: (context, viewModel, _) {
        return SafeScaffold(
            appBar: AppBar(
              title: Text(context.tr('settings')),
            ),
            body: SingleChildScrollView());
      },
    );
  }
}
