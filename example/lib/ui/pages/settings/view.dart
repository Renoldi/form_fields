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
            title: Text(context.tr('settings')),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: widget.onBack,
              tooltip: context.tr('back'),
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _SectionCard(
                title: context.tr('accountAndSecurity'),
                icon: Icons.security,
                child: Column(
                  children: [
                    _SettingsTile(
                      title: context.tr('editProfile'),
                      subtitle: context.tr('updatePersonalInformation'),
                      icon: Icons.person,
                      onTap: widget.onOpenProfile,
                    ),
                    _SettingsTile(
                      title: context.tr('changePassword'),
                      subtitle: context.tr('updateAccountPassword'),
                      icon: Icons.lock,
                      onTap: widget.onOpenChangePassword,
                    ),
                    _SettingsTile(
                      title: context.tr('logout'),
                      subtitle: context.tr('signOutOfYourAccount'),
                      icon: Icons.logout,
                      onTap: () => handleLogout(viewModel),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _SectionCard(
                title: context.tr('preferences'),
                icon: Icons.tune,
                child: _SettingsTile(
                  title: context.tr('language'),
                  subtitle: viewModel.languageLabel,
                  icon: Icons.language,
                  onTap: widget.onOpenLanguage,
                ),
              ),
              const SizedBox(height: 16),
              _SectionCard(
                title: context.tr('about'),
                icon: Icons.info_outline,
                child: _SettingsTile(
                  title: context.tr('appInfo'),
                  subtitle: context.tr('aboutDescription'),
                  icon: Icons.info_outline,
                  onTap: widget.onOpenAppInfo,
                ),
              ),
            ],
          ),
        );
      },
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
