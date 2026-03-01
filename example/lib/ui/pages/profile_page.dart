import 'package:flutter/material.dart';
import 'package:form_fields/form_fields.dart';
import 'package:provider/provider.dart';
import 'package:form_fields_example/localization/localizations.dart';
import 'package:form_fields_example/state/app_state_notifier.dart';
import 'package:form_fields_example/state/pages/profile_view_model.dart';
import 'package:form_fields_example/ui/widgets/blocking_dialogs.dart';

class ProfilePage extends StatefulWidget {
  final VoidCallback onBack;

  const ProfilePage({
    super.key,
    required this.onBack,
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late final ProfileViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = ProfileViewModel();
    _viewModel.loadUserData(context.read<AppStateNotifier>());
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _viewModel,
      child: Consumer<ProfileViewModel>(
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
                    // Profile Image
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
                                          context.tr('imageUploadComingSoon')),
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

                    // First Name Field
                    FormFields<String>(
                      label: context.tr('firstName'),
                      currrentValue: viewModel.firstNameController.text,
                      formType: FormType.string,
                      labelPosition: LabelPosition.inBorder,
                      enterText: '',
                      prefixIcon: const Icon(Icons.person_outline),
                      onChanged: (value) {
                        viewModel.firstNameController.text = value;
                      },
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return context.tr('pleaseEnterFirstName');
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Last Name Field
                    FormFields<String>(
                      label: context.tr('lastName'),
                      currrentValue: viewModel.lastNameController.text,
                      formType: FormType.string,
                      labelPosition: LabelPosition.inBorder,
                      enterText: '',
                      prefixIcon: const Icon(Icons.person_outline),
                      onChanged: (value) {
                        viewModel.lastNameController.text = value;
                      },
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return context.tr('pleaseEnterLastName');
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Email Field
                    FormFields<String>(
                      label: context.tr('email'),
                      currrentValue: viewModel.emailController.text,
                      formType: FormType.email,
                      labelPosition: LabelPosition.inBorder,
                      enterText: '',
                      prefixIcon: const Icon(Icons.email_outlined),
                      onChanged: (value) {
                        viewModel.emailController.text = value;
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

                    // Username Field (read-only)
                    IgnorePointer(
                      child: FormFields<String>(
                        label: context.tr('username'),
                        currrentValue: viewModel.usernameController.text,
                        formType: FormType.string,
                        labelPosition: LabelPosition.inBorder,
                        enterText: '',
                        prefixIcon: const Icon(Icons.account_circle_outlined),
                        inputDecoration: InputDecoration(
                          helperText: context.tr('usernameCannotBeChanged'),
                        ),
                        onChanged: (value) {
                          viewModel.usernameController.text = value;
                        },
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Update Button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: viewModel.isLoading
                            ? null
                            : () async {
                                final dialog = BlockingDialog(context);

                                dialog.showLoading(
                                  message: context.tr('updatingProfile'),
                                );
                                final error =
                                    await viewModel.updateProfile(appState);
                                if (!context.mounted) return;

                                dialog.hide();
                                if (error == null) {
                                  await dialog.showResult(
                                    isSuccess: true,
                                    title: context.tr('success'),
                                    message: context
                                        .tr('profileUpdatedSuccessfully'),
                                  );
                                  if (context.mounted) {
                                    Navigator.of(context).pop();
                                  }
                                } else {
                                  await dialog.showResult(
                                    isSuccess: false,
                                    title: context.tr('updateFailed'),
                                    message: error,
                                  );
                                }
                              },
                        icon: viewModel.isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                ),
                              )
                            : const Icon(Icons.save),
                        label: Text(viewModel.isLoading
                            ? context.tr('updating')
                            : context.tr('updateProfile')),
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
