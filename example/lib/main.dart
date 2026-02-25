import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'pages/form_fields_examples_page.dart';
import 'pages/dropdown_examples_page.dart';
import 'pages/radio_button_examples_page.dart';
import 'pages/checkbox_examples_page.dart';

void main() {
  runApp(const MyApp());
}

// GoRouter configuration
final GoRouter _router = GoRouter(
  initialLocation: '/',
  routes: [
    ShellRoute(
      builder: (context, state, child) {
        return ScaffoldWithDrawer(child: child);
      },
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const FormFieldsExamplesPage(),
        ),
        GoRoute(
          path: '/dropdown',
          builder: (context, state) => const DropdownExamplesPage(),
        ),
        GoRoute(
          path: '/radio-button',
          builder: (context, state) => const RadioButtonExamplesPage(),
        ),
        GoRoute(
          path: '/checkbox',
          builder: (context, state) => const CheckboxExamplesPage(),
        ),
      ],
    ),
  ],
);

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'FormFields - Complete Examples',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1F2937),
          foregroundColor: Colors.white,
        ),
      ),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', 'US'),
        Locale('en', 'GB'),
      ],
      routerConfig: _router,
    );
  }
}

// Scaffold with Drawer wrapper
class ScaffoldWithDrawer extends StatelessWidget {
  final Widget child;

  const ScaffoldWithDrawer({Key? key, required this.child}) : super(key: key);

  String _getTitle(String location) {
    switch (location) {
      case '/':
        return 'FormFields Examples';
      case '/dropdown':
        return 'Dropdown Examples';
      case '/radio-button':
        return 'Radio Button Examples';
      case '/checkbox':
        return 'Checkbox Examples';
      default:
        return 'FormFields Examples';
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentLocation = GoRouterState.of(context).uri.toString();

    return Scaffold(
      appBar: AppBar(
        title: Text(_getTitle(currentLocation)),
        backgroundColor: const Color(0xFF1F2937),
        foregroundColor: Colors.white,
      ),
      drawer: const AppDrawer(),
      body: child,
    );
  }
}

// Custom Drawer Widget
class AppDrawer extends StatelessWidget {
  const AppDrawer({Key? key}) : super(key: key);

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
                  const Text(
                    'FormFields',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Complete Examples',
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
              title: 'FormFields',
              subtitle: 'Text, Number, Date & Time',
              route: '/',
              isSelected: currentLocation == '/',
              color: Colors.blue,
            ),
            const Divider(color: Colors.white24, height: 1),
            _buildDrawerItem(
              context: context,
              icon: Icons.arrow_drop_down_circle,
              title: 'Dropdown',
              subtitle: 'All Dropdown Examples',
              route: '/dropdown',
              isSelected: currentLocation == '/dropdown',
              color: Colors.green,
            ),
            const Divider(color: Colors.white24, height: 1),
            _buildDrawerItem(
              context: context,
              icon: Icons.radio_button_checked,
              title: 'Radio Button',
              subtitle: 'All Radio Button Examples',
              route: '/radio-button',
              isSelected: currentLocation == '/radio-button',
              color: Colors.orange,
            ),
            const Divider(color: Colors.white24, height: 1),
            _buildDrawerItem(
              context: context,
              icon: Icons.check_box,
              title: 'Checkbox',
              subtitle: 'All Checkbox Examples',
              route: '/checkbox',
              isSelected: currentLocation == '/checkbox',
              color: Colors.pink,
            ),
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
                    const Row(
                      children: [
                        Icon(Icons.info_outline,
                            color: Colors.white70, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'About',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Comprehensive examples showcasing all properties and features of the FormFields package.',
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

  Widget _buildDrawerItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required String route,
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
          context.go(route);
          Navigator.pop(context);
        },
      ),
    );
  }
}
