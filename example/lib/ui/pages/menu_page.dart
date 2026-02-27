import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:form_fields_example/state/app_state_notifier.dart';
import 'package:form_fields_example/state/pages/menu_view_model.dart';
import 'package:form_fields_example/ui/widgets/blocking_dialogs.dart';

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
  late final MenuViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = MenuViewModel(context.read<AppStateNotifier>());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _viewModel.loadUser();
    });
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _openSettings() async {
    await widget.onOpenSettings();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _viewModel,
      child: Consumer<MenuViewModel>(
        builder: (context, viewModel, _) {
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
                      viewModel.appState.logout();
                      widget.onLogout();
                    },
                    tooltip: 'Logout',
                    icon: const Icon(Icons.logout),
                  ),
                ],
              ),
              body: SingleChildScrollView(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (viewModel.appState.currentUser != null)
                        InkWell(
                          onTap: () async {
                            await widget.onOpenProfile();
                            if (!context.mounted) return;
                            final error =
                                await viewModel.loadUser(forceRefresh: true);
                            if (error != null) {
                              if (!context.mounted) return;
                              await showBlockingResult(
                                context,
                                title: 'Load Failed',
                                message: error,
                                isSuccess: false,
                              );
                            }
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
                                    viewModel.displayName.isNotEmpty
                                        ? viewModel.displayName[0].toUpperCase()
                                        : '?',
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        viewModel.displayName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        viewModel.email,
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
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          mainAxisSpacing: 32,
                          crossAxisSpacing: 16,
                          childAspectRatio: 0.9,
                        ),
                        itemCount: viewModel.menuItems.length,
                        itemBuilder: (context, index) {
                          final item = viewModel.menuItems[index];
                          return _MenuItem(
                            title: item.title,
                            subtitle: item.subtitle,
                            icon: item.icon,
                            color: item.color,
                            onTap: () => widget.onMenuItemTap(item.routeName),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
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
