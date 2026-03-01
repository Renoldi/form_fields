import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:form_fields_example/localization/example_localizations.dart';
import 'package:form_fields_example/state/app_state_notifier.dart';
import 'package:form_fields_example/config/app_routes.dart';

// Scaffold with Drawer wrapper
class ScaffoldWithDrawer extends StatelessWidget {
  final Widget child;

  const ScaffoldWithDrawer({super.key, required this.child});

  String _getTitle(String location, ExampleLocalizations l10n) {
    if (location == AppRoute.formFields.path) {
      return l10n.get('formFieldsExamples');
    } else if (location == AppRoute.dropdown.path) {
      return l10n.get('dropdownExamples');
    } else if (location == AppRoute.dropdownMulti.path) {
      return l10n.get('multiSelectDropdownExamples');
    } else if (location == AppRoute.radioButton.path) {
      return l10n.get('radioButtonExamples');
    } else if (location == AppRoute.checkbox.path) {
      return l10n.get('checkboxExamples');
    } else if (location == AppRoute.customClass.path) {
      return l10n.get('customClassExamples');
    } else if (location == AppRoute.validation.path) {
      return l10n.get('validationExamples');
    } else {
      return l10n.get('formFieldsExamples');
    }
  }

  void _showLanguageDialog(BuildContext context) {
    final currentLocale = Localizations.localeOf(context);
    final l10n = ExampleLocalizations.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.language, color: Colors.blue),
            const SizedBox(width: 12),
            Text(l10n.get('selectLanguage')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _LanguageOption(
              flag: '🇺🇸',
              language: l10n.get('english'),
              subtitle: l10n.get('unitedStates'),
              locale: const Locale('en', 'US'),
              isSelected: currentLocale.languageCode == 'en',
            ),
            const Divider(),
            _LanguageOption(
              flag: '🇮🇩',
              language: l10n.get('indonesian'),
              subtitle: l10n.get('indonesia'),
              locale: const Locale('id', 'ID'),
              isSelected: currentLocale.languageCode == 'id',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.get('close')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentLocation = GoRouterState.of(context).uri.toString();
    final currentLocale = Localizations.localeOf(context);
    final l10n = ExampleLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.goNamed(AppRoute.menu.name);
            }
          },
          tooltip: l10n.get('back'),
        ),
        title: Text(_getTitle(currentLocation, l10n)),
        backgroundColor: const Color(0xFF1F2937),
        foregroundColor: Colors.white,
        actions: [
          // Language indicator button
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton.icon(
              onPressed: () => _showLanguageDialog(context),
              icon: Text(
                currentLocale.languageCode == 'id' ? '🇮🇩' : '🇺🇸',
                style: const TextStyle(fontSize: 20),
              ),
              label: Text(
                currentLocale.languageCode == 'id' ? 'ID' : 'EN',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: TextButton.styleFrom(
                backgroundColor: Colors.white.withValues(alpha: 0.1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ),
        ],
      ),
      drawer: AppDrawer(l10n: l10n),
      body: child,
    );
  }
}

class _LanguageOption extends StatelessWidget {
  final String flag;
  final String language;
  final String subtitle;
  final Locale locale;
  final bool isSelected;

  const _LanguageOption({
    required this.flag,
    required this.language,
    required this.subtitle,
    required this.locale,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Text(
        flag,
        style: const TextStyle(fontSize: 32),
      ),
      title: Text(
        language,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      subtitle: Text(subtitle),
      trailing: isSelected
          ? const Icon(Icons.check_circle, color: Colors.blue)
          : null,
      selected: isSelected,
      onTap: () {
        context.read<AppStateNotifier>().setLocale(locale);
        Navigator.pop(context);
      },
    );
  }
}

// Custom Drawer Widget
class AppDrawer extends StatelessWidget {
  final ExampleLocalizations l10n;

  const AppDrawer({super.key, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final currentLocation = GoRouterState.of(context).uri.toString();

    return Drawer(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF1F2937),
              Colors.grey.shade900,
            ],
          ),
        ),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.blue.shade700,
                    Colors.blue.shade500,
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.max,
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.widgets,
                      size: 40,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.get('formFields'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    l10n.get('completeExamples'),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            _buildDrawerItem(
              context: context,
              icon: Icons.text_fields,
              title: l10n.get('formFields'),
              subtitle: l10n.get('formFieldsDesc'),
              routeName: AppRoute.formFields.name,
              isSelected: currentLocation == AppRoute.formFields.path,
              color: Colors.blue,
            ),
            const Divider(color: Colors.white24, height: 1),
            _buildDrawerItem(
              context: context,
              icon: Icons.arrow_drop_down_circle,
              title: l10n.get('dropdown'),
              subtitle: l10n.get('singleSelectDropdown'),
              routeName: AppRoute.dropdown.name,
              isSelected: currentLocation == AppRoute.dropdown.path,
              color: Colors.green,
            ),
            const Divider(color: Colors.white24, height: 1),
            _buildDrawerItem(
              context: context,
              icon: Icons.library_add_check,
              title: l10n.get('dropdownMulti'),
              subtitle: l10n.get('multiSelectDropdown'),
              routeName: AppRoute.dropdownMulti.name,
              isSelected: currentLocation == AppRoute.dropdownMulti.path,
              color: Colors.purple,
            ),
            const Divider(color: Colors.white24, height: 1),
            _buildDrawerItem(
              context: context,
              icon: Icons.radio_button_checked,
              title: l10n.get('radioButton'),
              subtitle: l10n.get('allRadioButtonExamples'),
              routeName: AppRoute.radioButton.name,
              isSelected: currentLocation == AppRoute.radioButton.path,
              color: Colors.orange,
            ),
            const Divider(color: Colors.white24, height: 1),
            _buildDrawerItem(
              context: context,
              icon: Icons.check_box,
              title: l10n.get('checkbox'),
              subtitle: l10n.get('allCheckboxExamples'),
              routeName: AppRoute.checkbox.name,
              isSelected: currentLocation == AppRoute.checkbox.path,
              color: Colors.pink,
            ),
            const Divider(color: Colors.white24, height: 1),
            _buildDrawerItem(
              context: context,
              icon: Icons.class_,
              title: l10n.get('customClass'),
              subtitle: l10n.get('genericTypesWithModels'),
              routeName: AppRoute.customClass.name,
              isSelected: currentLocation == AppRoute.customClass.path,
              color: Colors.teal,
            ),
            const Divider(color: Colors.white24, height: 1),
            _buildDrawerItem(
              context: context,
              icon: Icons.rule,
              title: l10n.get('nullNonNullValidation'),
              subtitle: l10n.get('nullableVsNonNullable'),
              routeName: AppRoute.validation.name,
              isSelected: currentLocation == AppRoute.validation.path,
              color: Colors.indigo,
            ),
            const SizedBox(height: 16),
            _buildLanguageSection(context, l10n),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.info_outline,
                            color: Colors.white70, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          l10n.get('about'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.get('aboutDescription'),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageSection(
      BuildContext context, ExampleLocalizations l10n) {
    final currentLocale = Localizations.localeOf(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.indigo.shade700, Colors.indigo.shade500],
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.indigo.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.language,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.get('language'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          currentLocale.languageCode == 'id'
                              ? '🇮🇩 ${l10n.get("indonesian")}'
                              : '🇺🇸 ${l10n.get("english")}',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              decoration: const BoxDecoration(
                color: Colors.black12,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        context
                            .read<AppStateNotifier>()
                            .setLocale(const Locale('en', 'US'));
                      },
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(12),
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: currentLocale.languageCode == 'en'
                              ? Colors.white.withValues(alpha: 0.2)
                              : Colors.transparent,
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(12),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('🇺🇸', style: TextStyle(fontSize: 20)),
                            const SizedBox(width: 8),
                            Text(
                              l10n.get('english'),
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: currentLocale.languageCode == 'en'
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                            if (currentLocale.languageCode == 'en')
                              const SizedBox(width: 4),
                            if (currentLocale.languageCode == 'en')
                              const Icon(Icons.check,
                                  color: Colors.white, size: 16),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 44,
                    color: Colors.white24,
                  ),
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        context
                            .read<AppStateNotifier>()
                            .setLocale(const Locale('id', 'ID'));
                      },
                      borderRadius: const BorderRadius.only(
                        bottomRight: Radius.circular(12),
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: currentLocale.languageCode == 'id'
                              ? Colors.white.withValues(alpha: 0.2)
                              : Colors.transparent,
                          borderRadius: const BorderRadius.only(
                            bottomRight: Radius.circular(12),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('🇮🇩', style: TextStyle(fontSize: 20)),
                            const SizedBox(width: 8),
                            Text(
                              l10n.get('indonesian'),
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: currentLocale.languageCode == 'id'
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                            if (currentLocale.languageCode == 'id')
                              const SizedBox(width: 4),
                            if (currentLocale.languageCode == 'id')
                              const Icon(Icons.check,
                                  color: Colors.white, size: 16),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required String routeName,
    required bool isSelected,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected ? color.withValues(alpha: 0.2) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? color : Colors.transparent,
          width: 2,
        ),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: color,
            size: 24,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: Colors.white,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 12,
          ),
        ),
        trailing: isSelected
            ? Icon(Icons.check_circle, color: color, size: 24)
            : const Icon(Icons.arrow_forward_ios,
                color: Colors.white38, size: 16),
        onTap: () {
          context.pushNamed(routeName);
          Navigator.pop(context);
        },
      ),
    );
  }
}
