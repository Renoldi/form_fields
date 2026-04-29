import 'package:flutter/material.dart';
import 'package:form_fields/form_fields.dart';
import 'package:provider/provider.dart';
import 'package:form_fields_example/state/app_state_notifier.dart';
import 'package:form_fields_example/localization/localizations.dart';
import 'presenter.dart';
import 'view_model.dart';

class View extends PresenterState {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: viewModel,
      child: Consumer<ViewModel>(
        builder: (context, viewModel, _) {
          final appState = context.watch<AppStateNotifier>();
          final user = appState.currentUser;

          return Scaffold(
            appBar: AppBar(
              title: Text(context.tr('editProfile')),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: widget.onBack,
                tooltip: context.tr('back'),
              ),
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: viewModel.formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundImage: user?.image != null
                                ? NetworkImage(user!.image!)
                                : null,
                            child: user?.image == null
                                ? const Icon(Icons.person, size: 50)
                                : null,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: CircleAvatar(
                              radius: 18,
                              backgroundColor: Theme.of(context).primaryColor,
                              child: IconButton(
                                icon: const Icon(Icons.camera_alt, size: 18),
                                color: Colors.white,
                                padding: EdgeInsets.zero,
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        context.tr('imageUploadComingSoon'),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    FormFields<String>(
                      label: context.tr('firstName'),
                      currentValue: viewModel.user.firstName ?? '',
                      labelPosition: LabelPosition.inBorder,
                      prefixIcon: const Icon(Icons.person_outline),
                      onChanged: (value) {
                        viewModel.user =
                            viewModel.user.copyWith(firstName: value);
                      },
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return context.tr('pleaseEnterFirstName');
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    FormFields<String>(
                      label: context.tr('lastName'),
                      currentValue: viewModel.user.lastName ?? '',
                      labelPosition: LabelPosition.inBorder,
                      prefixIcon: const Icon(Icons.person_outline),
                      onChanged: (value) {
                        viewModel.user =
                            viewModel.user.copyWith(lastName: value);
                      },
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return context.tr('pleaseEnterLastName');
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    FormFields<String>(
                      label: context.tr('email'),
                      currentValue: viewModel.user.email ?? '',
                      formType: FormType.email,
                      labelPosition: LabelPosition.inBorder,
                      prefixIcon: const Icon(Icons.email_outlined),
                      onChanged: (value) {
                        viewModel.user = viewModel.user.copyWith(email: value);
                      },
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return context.tr('pleaseEnterEmail');
                        }
                        if (!value.contains('@')) {
                          return context.tr('pleaseEnterValidEmail');
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    IgnorePointer(
                      child: FormFields<String>(
                        label: context.tr('username'),
                        currentValue: viewModel.user.username ?? '',
                        labelPosition: LabelPosition.inBorder,
                        prefixIcon: const Icon(Icons.account_circle_outlined),
                        inputDecoration: InputDecoration(
                          helperText: context.tr('usernameCannotBeChanged'),
                        ),
                        onChanged: (value) {},
                      ),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: viewModel.isLoading
                            ? null
                            : () => handleUpdateProfile(appState),
                        icon: viewModel.isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : const Icon(Icons.save),
                        label: Text(
                          viewModel.isLoading
                              ? context.tr('updating')
                              : context.tr('updateProfile'),
                        ),
                        style: ElevatedButton.styleFrom(
                          textStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
