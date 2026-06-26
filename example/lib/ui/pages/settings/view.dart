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

class _SectionCard extends StatefulWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  State<_SectionCard> createState() => _SectionCardView();
}

abstract class _SectionCardPresenterState extends State<_SectionCard> {
  late final _SectionCardViewModel viewModel;

  @override
  void initState() {
    super.initState();
    viewModel = _SectionCardViewModel();
  }
}

class _SectionCardView extends _SectionCardPresenterState {
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
                Icon(widget.icon, color: const Color(0xFF1F2937)),
                const SizedBox(width: 8),
                Text(
                  widget.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            widget.child,
          ],
        ),
      ),
    );
  }
}

class _SettingsTile extends StatefulWidget {
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
  State<_SettingsTile> createState() => _SettingsTileView();
}

abstract class _SettingsTilePresenterState extends State<_SettingsTile> {
  late final _SettingsTileViewModel viewModel;

  @override
  void initState() {
    super.initState();
    viewModel = _SettingsTileViewModel();
  }
}

class _SettingsTileView extends _SettingsTilePresenterState {
  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(widget.icon, color: const Color(0xFF1F2937)),
      title: Text(widget.title),
      subtitle: Text(widget.subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: widget.onTap,
    );
  }
}

class _SectionCardViewModel {}

class _SettingsTileViewModel {}
