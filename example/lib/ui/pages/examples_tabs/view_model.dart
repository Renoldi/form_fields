import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:form_fields_example/localization/localizations.dart' as loc;
import 'package:form_fields_example/state/app_state_notifier.dart';

class ExamplesTabItem {
  final String title;
  final IconData icon;
  final int index;
  final Color color;

  const ExamplesTabItem({
    required this.title,
    required this.icon,
    required this.index,
    required this.color,
  });
}

class ExamplesTabsViewModel extends ChangeNotifier {
  List<Tab> buildTabs(loc.Localizations l) => [
        Tab(text: l.get('tabFormFields')),
        Tab(text: l.get('tabDropdown')),
        Tab(text: l.get('tabDropdownMulti')),
        Tab(text: l.get('tabRadioButton')),
        Tab(text: l.get('tabCheckbox')),
        Tab(text: l.get('tabCustomClass')),
        Tab(text: l.get('tabValidation')),
      ];

  List<ExamplesTabItem> buildMenuItems(loc.Localizations l) => [
        ExamplesTabItem(
          title: l.get('tabFormFields'),
          icon: Icons.input,
          index: 0,
          color: Colors.blue,
        ),
        ExamplesTabItem(
          title: l.get('tabDropdown'),
          icon: Icons.arrow_drop_down,
          index: 1,
          color: Colors.green,
        ),
        ExamplesTabItem(
          title: l.get('tabDropdownMulti'),
          icon: Icons.list_alt,
          index: 2,
          color: Colors.purple,
        ),
        ExamplesTabItem(
          title: l.get('tabRadioButton'),
          icon: Icons.radio_button_checked,
          index: 3,
          color: Colors.orange,
        ),
        ExamplesTabItem(
          title: l.get('tabCheckbox'),
          icon: Icons.check_box,
          index: 4,
          color: Colors.pink,
        ),
        ExamplesTabItem(
          title: l.get('tabCustomClass'),
          icon: Icons.dashboard_customize,
          index: 5,
          color: Colors.teal,
        ),
        ExamplesTabItem(
          title: l.get('tabValidation'),
          icon: Icons.verified_user,
          index: 6,
          color: Colors.red,
        ),
      ];

  void showLanguageDialog(BuildContext context) {
    final l = loc.Localizations.of(context);
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
              flag: 'US',
              language: l.get('languageEnglish'),
              subtitle: l.get('languageEnglishRegion'),
              locale: const Locale('en', 'US'),
              isSelected: currentLocale.languageCode == 'en',
            ),
            const Divider(),
            _LanguageOption(
              flag: 'ID',
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
}

class _LanguageOption extends StatefulWidget {
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
  State<_LanguageOption> createState() => _LanguageOptionView();
}

abstract class _LanguageOptionPresenterState extends State<_LanguageOption> {
  late final _LanguageOptionViewModel viewModel;

  @override
  void initState() {
    super.initState();
    viewModel = _LanguageOptionViewModel();
  }
}

class _LanguageOptionView extends _LanguageOptionPresenterState {
  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Text(
        widget.flag,
        style: const TextStyle(fontSize: 18),
      ),
      title: Text(
        widget.language,
        style: TextStyle(
          fontWeight: widget.isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      subtitle: Text(widget.subtitle),
      trailing: widget.isSelected
          ? const Icon(Icons.check_circle, color: Colors.blue)
          : null,
      selected: widget.isSelected,
      onTap: () {
        context.read<AppStateNotifier>().setLocale(widget.locale);
        Navigator.pop(context);
      },
    );
  }
}

class _LanguageOptionViewModel {}
