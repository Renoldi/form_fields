import 'package:flutter/material.dart';
import 'package:form_fields/form_fields.dart';
import 'package:provider/provider.dart';
import 'package:form_fields_example/localization/localizations.dart';
import 'presenter.dart';
import 'view_model.dart';

class View extends PresenterState {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: viewModel,
      child: Consumer<ViewModel>(
        builder: (context, viewModel, _) {
          return PopScope(
            canPop: false,
            onPopInvokedWithResult: (didPop, result) async {
              if (didPop) return;
              await AppDialogService(context).showExitConfirm(
                title: context.tr('exitApplication'),
                message: context.tr('exitWarning'),
                stayLabel: context.tr('stay'),
                exitLabel: context.tr('exit'),
              );
            },
            child: Scaffold(
              backgroundColor: const Color(0xFFF5F5F5),
              appBar: AppBar(
                title: Text(context.tr('formFieldsExamples')),
                backgroundColor: const Color(0xFF1F2937),
                foregroundColor: Colors.white,
                centerTitle: true,
                elevation: 0,
                actions: [
                  IconButton(
                    onPressed: handleOpenSettings,
                    tooltip: context.tr('settings'),
                    icon: const Icon(Icons.settings),
                  ),
                  IconButton(
                    onPressed: handleLogout,
                    tooltip: context.tr('logout'),
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
                          onTap: handleOpenProfile,
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
                      ResponsiveMenuGrid(
                        widgets: viewModel.menuItems
                            .map((item) => Column(
                                  mainAxisSize: MainAxisSize.max,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Material(
                                      color: item.color.withValues(alpha: 0.1),
                                      shape: const CircleBorder(),
                                      child: InkWell(
                                        customBorder: const CircleBorder(),
                                        onTap: () =>
                                            handleMenuItemTap(item.routeName),
                                        child: SizedBox(
                                          width: 64,
                                          height: 64,
                                          child: Icon(
                                            item.icon,
                                            size: 36,
                                            color: item.color,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Flexible(
                                      child: Text(
                                        item.title,
                                        textAlign: TextAlign.center,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ))
                            .toList(),
                        itemSize: 110,
                        horizontalMargin: 8,
                        verticalSpacing: 32,
                        alignLeft: true,
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
