import 'package:flutter/material.dart';
import 'package:form_fields/form_fields.dart';
import 'package:provider/provider.dart';
import 'package:form_fields_example/state/pages/examples_tabs_view_model.dart';
import 'checkbox_examples_page.dart';
import 'custom_class_examples_page.dart';
import 'dropdown_examples_page.dart';
import 'dropdown_multi_examples_page.dart';
import 'form_fields_examples_page.dart';
import 'null_non_null_validation_examples_page.dart';
import 'radio_button_examples_page.dart';

class ExamplesTabsPage extends StatelessWidget {
  const ExamplesTabsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ExamplesTabsViewModel(),
      child: Consumer<ExamplesTabsViewModel>(
        builder: (context, viewModel, _) {
          final l = FormFieldsLocalizations.of(context);
          final currentLocale = Localizations.localeOf(context);
          final tabs = viewModel.buildTabs(l);
          final menuItems = viewModel.buildMenuItems(l);

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
                              item.icon,
                              color: item.color,
                            ),
                            title: Text(
                              item.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            onTap: () {
                              DefaultTabController.of(context).animateTo(
                                item.index,
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
                            viewModel.showLanguageDialog(context);
                            Navigator.pop(context);
                          },
                          icon: Text(
                            currentLocale.languageCode == 'id'
                                ? '🇮🇩'
                                : '🇺🇸',
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
                      onPressed: () => viewModel.showLanguageDialog(context),
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
        },
      ),
    );
  }
}
