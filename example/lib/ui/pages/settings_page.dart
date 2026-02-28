import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:form_fields_example/state/app_state_notifier.dart';
import 'package:form_fields_example/state/pages/settings_view_model.dart';

class SettingsPage extends StatelessWidget {
  final VoidCallback onBack;
  final VoidCallback onLogout;
  final VoidCallback onOpenProfile;
  final VoidCallback onOpenChangePassword;
  final VoidCallback onOpenLanguage;
  final VoidCallback onOpenAppInfo;

  const SettingsPage({
    super.key,
    required this.onBack,
    required this.onLogout,
    required this.onOpenProfile,
    required this.onOpenChangePassword,
    required this.onOpenLanguage,
    required this.onOpenAppInfo,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SettingsViewModel(context.read<AppStateNotifier>()),
      child: Consumer<SettingsViewModel>(
        builder: (context, viewModel, _) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Settings'),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: onBack,
                tooltip: 'Back',
              ),
            ),
            body: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _SectionCard(
                  title: 'Account & Security',
                  icon: Icons.security,
                  child: Column(
                    children: [
                      _SettingsTile(
                        title: 'Edit Profile',
                        subtitle: 'Update your personal information',
                        icon: Icons.person,
                        onTap: onOpenProfile,
                      ),
                      _SettingsTile(
                        title: 'Change Password',
                        subtitle: 'Update your account password',
                        icon: Icons.lock,
                        onTap: onOpenChangePassword,
                      ),
                      _SettingsTile(
                        title: 'Logout',
                        subtitle: 'Sign out of your account',
                        icon: Icons.logout,
                        onTap: () => viewModel.logout(onLogout),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _SectionCard(
                  title: 'Preferences',
                  icon: Icons.tune,
                  child: _SettingsTile(
                    title: 'Language',
                    subtitle: viewModel.languageLabel,
                    icon: Icons.language,
                    onTap: onOpenLanguage,
                  ),
                ),
                const SizedBox(height: 16),
                _SectionCard(
                  title: 'About',
                  icon: Icons.info_outline,
                  child: _SettingsTile(
                    title: 'App Info',
                    subtitle: 'Version and application details',
                    icon: Icons.info_outline,
                    onTap: onOpenAppInfo,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: const Color(0xFF1F2937)),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: const Color(0xFF1F2937)),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
