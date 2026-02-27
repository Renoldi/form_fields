import 'package:flutter/material.dart';
import 'package:form_fields/form_fields.dart';
import 'package:provider/provider.dart';
import '../providers/app_state_notifier.dart';
import 'checkbox_examples_page.dart';
import 'custom_class_examples_page.dart';
import 'dropdown_examples_page.dart';
import 'dropdown_multi_examples_page.dart';
import 'form_fields_examples_page.dart';
import 'null_non_null_validation_examples_page.dart';
import 'radio_button_examples_page.dart';

class ExamplesTabsPage extends StatelessWidget {
  const ExamplesTabsPage({Key? key}) : super(key: key);

  void _showLanguageDialog(BuildContext context) {
    final l = FormFieldsLocalizations.of(context);
    final currentLocale = Localizations.localeOf(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.language, color: Colors.blue),
            const SizedBox(width: 12),
            Text(l.get('selectLanguageTitle')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _LanguageOption(
              flag: '🇺🇸',
              language: l.get('languageEnglish'),
              subtitle: l.get('languageEnglishRegion'),
              locale: const Locale('en', 'US'),
              isSelected: currentLocale.languageCode == 'en',
            ),
            const Divider(),
            _LanguageOption(
              flag: '🇮🇩',
              language: l.get('languageIndonesian'),
              subtitle: l.get('languageIndonesianRegion'),
              locale: const Locale('id', 'ID'),
              isSelected: currentLocale.languageCode == 'id',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l.get('closeButton')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = FormFieldsLocalizations.of(context);
    final currentLocale = Localizations.localeOf(context);

    final tabs = [
      Tab(text: l.get('tabFormFields')),
      Tab(text: l.get('tabDropdown')),
      Tab(text: l.get('tabDropdownMulti')),
      Tab(text: l.get('tabRadioButton')),
      Tab(text: l.get('tabCheckbox')),
      Tab(text: l.get('tabCustomClass')),
      Tab(text: l.get('tabValidation')),
    ];

    final menuItems = [
      {
        'title': l.get('tabFormFields'),
        'icon': Icons.input,
        'index': 0,
        'color': Colors.blue,
      },
      {
        'title': l.get('tabDropdown'),
        'icon': Icons.arrow_drop_down,
        'index': 1,
        'color': Colors.green,
      },
      {
        'title': l.get('tabDropdownMulti'),
        'icon': Icons.list_alt,
        'index': 2,
        'color': Colors.purple,
      },
      {
        'title': l.get('tabRadioButton'),
        'icon': Icons.radio_button_checked,
        'index': 3,
        'color': Colors.orange,
      },
      {
        'title': l.get('tabCheckbox'),
        'icon': Icons.check_box,
        'index': 4,
        'color': Colors.pink,
      },
      {
        'title': l.get('tabCustomClass'),
        'icon': Icons.dashboard_customize,
        'index': 5,
        'color': Colors.teal,
      },
      {
        'title': l.get('tabValidation'),
        'icon': Icons.verified_user,
        'index': 6,
        'color': Colors.red,
      },
    ];

    return DefaultTabController(
      length: tabs.length,
      child: Scaffold(
        drawer: Drawer(
          child: Column(
            children: [
              DrawerHeader(
                decoration: const BoxDecoration(
                  color: Color(0xFF1F2937),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.dashboard,
                      size: 40,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      l.get('examplesTitle'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: EdgeInsets.zero,
                  itemCount: menuItems.length,
                  itemBuilder: (context, index) {
                    final item = menuItems[index];
                    return ListTile(
                      leading: Icon(
                        item['icon'] as IconData,
                        color: item['color'] as Color,
                      ),
                      title: Text(
                        item['title'] as String,
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      onTap: () {
                        DefaultTabController.of(context).animateTo(
                          item['index'] as int,
                        );
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
              const Divider(),
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      _showLanguageDialog(context);
                      Navigator.pop(context);
                    },
                    icon: Text(
                      currentLocale.languageCode == 'id' ? '🇮🇩' : '🇺🇸',
                      style: const TextStyle(fontSize: 18),
                    ),
                    label: Text(
                      currentLocale.languageCode == 'id'
                          ? 'Bahasa Indonesia'
                          : 'English',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1F2937),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        appBar: AppBar(
          title: Text(l.get('examplesTitle')),
          backgroundColor: const Color(0xFF1F2937),
          foregroundColor: Colors.white,
          actions: [
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
          bottom: TabBar(
            isScrollable: true,
            tabs: tabs,
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
          ),
        ),
        body: const TabBarView(
          children: [
            FormFieldsExamplesPage(),
            DropdownExamplesPage(),
            DropdownMultiExamplesPage(),
            RadioButtonExamplesPage(),
            CheckboxExamplesPage(),
            CustomClassExamplesPage(),
            NullNonNullValidationExamplesPage(),
          ],
        ),
      ),
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
