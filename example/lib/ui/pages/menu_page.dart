import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/models/user.dart';
import '../../state/notifiers/app_state_notifier.dart';
import '../../config/app_routes.dart';
import '../widgets/blocking_dialogs.dart';

class MenuPage extends StatefulWidget {
  final VoidCallback onLogout;
  final void Function(String routeName) onMenuItemTap;
  final Future<void> Function() onOpenSettings;
  final Future<void> Function() onOpenProfile;

  const MenuPage({
    Key? key,
    required this.onLogout,
    required this.onMenuItemTap,
    required this.onOpenSettings,
    required this.onOpenProfile,
  }) : super(key: key);

  @override
  State<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUser();
    });
  }

  Future<void> _loadUser({bool showDialogs = false}) async {
    final appState = context.read<AppStateNotifier>();
    if (!appState.isLoggedIn) {
      return;
    }

    final accessToken = appState.accessToken;
    if (accessToken.isEmpty) {
      return;
    }

    // If user is already loaded and we're not explicitly refreshing, skip
    if (appState.currentUser != null && !showDialogs) {
      return;
    }

    if (showDialogs) {
      showBlockingLoading(
        context,
        message: 'Loading user...',
      );
    }

    try {
      // Call User.getMe() directly
      final user = await User.getMe(accessToken: accessToken);

      if (!mounted) return;

      // Update app state with user data
      appState.updateUserData(user);

      if (showDialogs) {
        hideBlockingDialog(context);
      }
    } catch (error) {
      if (!mounted) return;

      if (showDialogs) {
        hideBlockingDialog(context);

        final errorMessage = error.toString().contains('DioException')
            ? 'Unable to load user data'
            : error.toString();

        await showBlockingResult(
          context,
          title: 'Load Failed',
          message: errorMessage,
          isSuccess: false,
        );
      }
    }
  }

  Future<void> _openSettings() async {
    await widget.onOpenSettings();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppStateNotifier>();
    final displayName = appState.currentUser?.displayName ?? '';
    final email = appState.currentUser?.email ?? '';

    final menuItems = [
      {
        'title': 'FormFields',
        'subtitle': 'Text, Number, Date & Time',
        'icon': Icons.text_fields,
        'color': Colors.blue,
        'routeName': AppRoute.formFields.name,
      },
      {
        'title': 'Dropdown',
        'subtitle': 'Single Select',
        'icon': Icons.arrow_drop_down_circle,
        'color': Colors.green,
        'routeName': AppRoute.dropdown.name,
      },
      {
        'title': 'Dropdown Multi',
        'subtitle': 'Multi-Select',
        'icon': Icons.library_add_check,
        'color': Colors.purple,
        'routeName': AppRoute.dropdownMulti.name,
      },
      {
        'title': 'Radio Button',
        'subtitle': 'Radio Options',
        'icon': Icons.radio_button_checked,
        'color': Colors.orange,
        'routeName': AppRoute.radioButton.name,
      },
      {
        'title': 'Checkbox',
        'subtitle': 'Checkbox Options',
        'icon': Icons.check_box,
        'color': Colors.pink,
        'routeName': AppRoute.checkbox.name,
      },
      {
        'title': 'Custom Class',
        'subtitle': 'Generic Types',
        'icon': Icons.class_,
        'color': Colors.teal,
        'routeName': AppRoute.customClass.name,
      },
      {
        'title': 'Validation',
        'subtitle': 'Null/Non-Null',
        'icon': Icons.rule,
        'color': Colors.indigo,
        'routeName': AppRoute.validation.name,
      },
    ];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await showExitConfirmDialog(context);
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        appBar: AppBar(
          title: const Text('FormFields Examples'),
          backgroundColor: const Color(0xFF1F2937),
          foregroundColor: Colors.white,
          centerTitle: true,
          elevation: 0,
          actions: [
            IconButton(
              onPressed: _openSettings,
              tooltip: 'Settings',
              icon: const Icon(Icons.settings),
            ),
            IconButton(
              onPressed: () {
                appState.logout();
                widget.onLogout();
              },
              tooltip: 'Logout',
              icon: const Icon(Icons.logout),
            ),
          ],
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (appState.currentUser != null)
                  InkWell(
                    onTap: () async {
                      widget.onOpenProfile().whenComplete(() async {
                        if (!mounted) return;
                        await _loadUser(showDialogs: false);
                      });
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 20),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: const Color(0xFF1F2937),
                            child: Text(
                              displayName.isNotEmpty
                                  ? displayName[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  displayName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  email,
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.edit,
                            color: Colors.grey.shade400,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 32,
                    crossAxisSpacing: 16,
                    childAspectRatio: 0.9,
                  ),
                  itemCount: menuItems.length,
                  itemBuilder: (context, index) {
                    final item = menuItems[index];
                    return _MenuItem(
                      title: item['title'] as String,
                      subtitle: item['subtitle'] as String,
                      icon: item['icon'] as IconData,
                      color: item['color'] as Color,
                      onTap: () =>
                          widget.onMenuItemTap(item['routeName'] as String),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _MenuItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.1),
              border: Border.all(
                color: color,
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              icon,
              size: 36,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Flexible(
            child: Text(
              subtitle,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade600,
                height: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
