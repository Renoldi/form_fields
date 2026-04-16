import 'dart:async';

import 'package:flutter/material.dart';
import 'package:form_fields/form_fields.dart';
import 'package:provider/provider.dart';
import 'package:form_fields_example/localization/localizations.dart';

import 'presenter.dart';
import 'view_model.dart';

class View extends PresenterState {
  int _tapCounter = 0;

  @override
  Widget build(BuildContext context) {
    return Consumer<ViewModel>(
      builder: (context, vm, _) {
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              context.tr('appDialogService'),
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              context.tr('adsFocusedDemoSubtitle'),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            _buildOptionsCard(context, vm),
            const SizedBox(height: 16),
            _buildActionsCard(context, vm),
          ],
        );
      },
    );
  }

  Widget _buildOptionsCard(BuildContext context, ViewModel vm) {
    return _Card(
      title: context.tr('adsOptionsTitle'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: Text(context.tr('adsUseBlockingLoadingInGuard')),
            value: vm.useBlockingLoading,
            onChanged: vm.setBlockingLoading,
          ),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: Text(context.tr('adsSimulateErrorOnGuard')),
            value: vm.simulateError,
            onChanged: vm.setSimulateError,
          ),
          const SizedBox(height: 8),
          Text(context.tr('lpDialogPosition')),
          const SizedBox(height: 8),
          SegmentedButton<AppDialogPosition>(
            segments: [
              ButtonSegment(
                  value: AppDialogPosition.top,
                  label: Text(context.tr('positionTop'))),
              ButtonSegment(
                  value: AppDialogPosition.center,
                  label: Text(context.tr('positionCenter'))),
              ButtonSegment(
                  value: AppDialogPosition.bottom,
                  label: Text(context.tr('positionBottom'))),
            ],
            selected: {vm.position},
            onSelectionChanged: (set) => vm.setPosition(set.first),
          ),
          const SizedBox(height: 10),
          Text('Loading Position'),
          const SizedBox(height: 8),
          SegmentedButton<AppDialogPosition>(
            segments: [
              ButtonSegment(
                  value: AppDialogPosition.top,
                  label: Text(context.tr('positionTop'))),
              ButtonSegment(
                  value: AppDialogPosition.center,
                  label: Text(context.tr('positionCenter'))),
              ButtonSegment(
                  value: AppDialogPosition.bottom,
                  label: Text(context.tr('positionBottom'))),
            ],
            selected: {vm.loadingPosition},
            onSelectionChanged: (set) => vm.setLoadingPosition(set.first),
          ),
          const SizedBox(height: 10),
          Text(context.tr('lpLoadingVisual')),
          const SizedBox(height: 8),
          SegmentedButton<AppDialogLoadingVisual>(
            segments: [
              ButtonSegment(
                value: AppDialogLoadingVisual.indicator,
                label: Text(context.tr('lpIndicator')),
              ),
              ButtonSegment(
                value: AppDialogLoadingVisual.progress,
                label: Text(context.tr('lpProgress')),
              ),
            ],
            selected: {vm.loadingVisual},
            onSelectionChanged: (set) => vm.setLoadingVisual(set.first),
          ),
          if (vm.loadingVisual == AppDialogLoadingVisual.indicator) ...[
            const SizedBox(height: 8),
            SegmentedButton<AppLoadingVariant>(
              segments: [
                ButtonSegment(
                  value: AppLoadingVariant.spinner,
                  label: Text(context.tr('lpSpinner')),
                ),
                ButtonSegment(
                  value: AppLoadingVariant.pulse,
                  label: Text(context.tr('lpPulse')),
                ),
                ButtonSegment(
                  value: AppLoadingVariant.dots,
                  label: Text(context.tr('lpDots')),
                ),
              ],
              selected: {vm.loadingVariant},
              onSelectionChanged: (set) => vm.setLoadingVariant(set.first),
            ),
          ],
          if (vm.loadingVisual == AppDialogLoadingVisual.progress) ...[
            const SizedBox(height: 8),
            SegmentedButton<AppProgressType>(
              segments: [
                ButtonSegment(
                  value: AppProgressType.circular,
                  label: Text(context.tr('lpCircular')),
                ),
                ButtonSegment(
                  value: AppProgressType.linear,
                  label: Text(context.tr('lpLinear')),
                ),
              ],
              selected: {vm.progressType},
              onSelectionChanged: (set) => vm.setProgressType(set.first),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionsCard(BuildContext context, ViewModel vm) {
    return _Card(
      title: context.tr('adsActionsTitle'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              SizedBox(
                width: 180,
                child: AppButton(
                  type: AppButtonType.filled,
                  text: context.tr('lpShowSuccess'),
                  onPressed: () => _showSuccess(context, vm, onComplete: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Success dialog closed')),
                    );
                  }),
                ),
              ),
              SizedBox(
                width: 180,
                child: AppButton(
                  type: AppButtonType.outlined,
                  text: context.tr('lpShowError'),
                  onPressed: () => _showError(context, vm, onComplete: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Error dialog closed')),
                    );
                  }),
                ),
              ),
              SizedBox(
                width: 180,
                child: AppButton(
                  type: AppButtonType.text,
                  text: vm.isRunning
                      ? context.tr('adsRunning')
                      : context.tr('lpRunGuardDemo'),
                  onPressed: vm.isRunning ? null : () => _runGuard(context, vm),
                ),
              ),
              SizedBox(
                width: 180,
                child: AppButton(
                  type: AppButtonType.filledTonal,
                  text: context.tr('adsGlobalSuccess'),
                  onPressed: () => _showGlobalSuccess(vm),
                ),
              ),
              SizedBox(
                width: 180,
                child: AppButton(
                  type: AppButtonType.elevated,
                  text: vm.isRunning
                      ? context.tr('adsGlobalRunning')
                      : context.tr('adsGlobalGuardDemo'),
                  onPressed: vm.isRunning ? null : () => _runGlobalGuard(vm),
                ),
              ),
              SizedBox(
                width: 180,
                child: AppButton(
                  type: AppButtonType.fab,
                  text: vm.isRunning
                      ? context.tr('adsGlobalLoading')
                      : context.tr('adsGlobalLoadingCancelDemo'),
                  onPressed: vm.isRunning
                      ? null
                      : () => _runGlobalLoadingConfirmCancelDemo(vm),
                ),
              ),
              SizedBox(
                width: 180,
                child: AppButton(
                  type: AppButtonType.filled,
                  text: 'Show Visual-Only Loading',
                  onPressed: () async {
                    await AppDialogService(context).showLoadingVisualOnly(
                      loadingVisual: vm.loadingVisual,
                      loadingVariant: vm.loadingVariant,
                      progressType: vm.progressType,
                      position: vm.loadingPosition,
                      onComplete: () {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Visual-only loading closed')),
                        );
                      },
                    );
                  },
                ),
              ),
              SizedBox(
                width: 180,
                child: AppButton(
                  type: AppButtonType.outlined,
                  text: 'Show Visual-Only (unguarded)',
                  onPressed: () {
                    AppDialogService(context).unguardedLoadingVisualOnly(
                      show: true,
                      loadingVisual: vm.loadingVisual,
                      loadingVariant: vm.loadingVariant,
                      progressType: vm.progressType,
                      position: vm.loadingPosition,
                    );
                    Future.delayed(const Duration(seconds: 2), () {
                      AppDialogService(context)
                          .unguardedLoadingVisualOnly(show: false);
                    });
                  },
                ),
              ),
              SizedBox(
                width: 180,
                child: AppButton(
                  type: AppButtonType.outlined,
                  text: '${context.tr('lpTapTest')} ($_tapCounter)',
                  onPressed: () {
                    setState(() {
                      _tapCounter += 1;
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(vm.isRunning
              ? context.tr('adsGuardRunningHint')
              : context.tr('adsReady')),
          const SizedBox(height: 6),
          Text('${context.tr('lpLastGuardResult')}: ${vm.lastResult}'),
        ],
      ),
    );
  }

  Future<void> _showSuccess(BuildContext context, ViewModel vm,
      {VoidCallback? onComplete}) {
    return AppDialogService(context).showSuccess(
      title: context.tr('success'),
      message: context.tr('adsOperationCompletedSuccessfully'),
      position: vm.position,
      onComplete: () {
        if (!mounted) return;
        if (onComplete != null) onComplete();
      },
    );
  }

  Future<void> _showError(BuildContext context, ViewModel vm,
      {VoidCallback? onComplete}) {
    return AppDialogService(context).showError(
      title: context.tr('updateFailed'),
      message: context.tr('adsUnableToCompleteOperation'),
      dialogType: AppDialogType.server,
      position: vm.position,
      onComplete: () {
        if (!mounted) return;
        if (onComplete != null) onComplete();
      },
    );
  }

  Future<void> _runGuard(BuildContext context, ViewModel vm) async {
    vm.setRunning(true);

    final result = await AppDialogService(context).guard<String>(
      task: () async {
        await Future<void>.delayed(const Duration(seconds: 2));
        if (vm.simulateError) {
          throw Exception('adsNetworkTimeoutSync');
        }
        return context.tr('lpSyncCompleted');
      },
      errorTitle: context.tr('adsGuardDemoTitle'),
      mapError: (error) => (
        message: context.tr(error.toString().replaceFirst('Exception: ', '')),
        type: AppDialogType.network,
      ),
      loadingPosition: vm.loadingPosition,
      resultPosition: AppDialogPosition.bottom, // Hasil di bawah
      showBlockingLoading: vm.useBlockingLoading,
      loadingMessage: context.tr('adsSyncing'),
      loadingVisual: vm.loadingVisual,
      loadingVariant: vm.loadingVariant,
      progressType: vm.progressType,
    );

    if (!mounted) return;
    vm.setRunning(false);
    vm.setLastResult(result ?? context.tr('lpGuardFailedHandledByDialog'));
  }

  Future<void> _showGlobalSuccess(ViewModel vm) {
    return AppGlobalDialogService.instance.showSuccess(
      title: context.tr('adsGlobalSuccess'),
      message: context.tr('adsGlobalDialogWithoutLocalContext'),
      position: vm.position,
    );
  }

  Future<void> _runGlobalGuard(ViewModel vm) async {
    vm.setRunning(true);

    final result = await AppGlobalDialogService.instance.guard<String>(
      task: () async {
        await Future<void>.delayed(const Duration(seconds: 2));
        if (vm.simulateError) {
          throw Exception('adsGlobalRequestTimeoutSync');
        }
        return context.tr('adsGlobalSyncCompleted');
      },
      errorTitle: context.tr('adsGlobalGuardDemoTitle'),
      mapError: (error) => (
        message: context.tr(error.toString().replaceFirst('Exception: ', '')),
        type: AppDialogType.network,
      ),
      loadingPosition: vm.loadingPosition,
      resultPosition: AppDialogPosition.bottom, // Hasil di bawah
      showBlockingLoading: vm.useBlockingLoading,
      loadingMessage: context.tr('adsGlobalSyncing'),
      loadingVisual: vm.loadingVisual,
      loadingVariant: vm.loadingVariant,
      progressType: vm.progressType,
    );

    if (!mounted) return;
    vm.setRunning(false);
    vm.setLastResult(
      result ?? context.tr('adsGlobalFailedHandledByDialog'),
    );
  }

  Future<void> _runGlobalLoadingConfirmCancelDemo(ViewModel vm) async {
    vm.setRunning(true);
    var cancelledByUser = false;

    // Auto-complete simulation so demo can finish even without back interaction.
    unawaited(
      Future<void>.delayed(const Duration(seconds: 4), () {
        if (cancelledByUser) return;
        if (!mounted) return;
        AppGlobalDialogService.instance.hide();
        vm.setLastResult(
          context.tr('adsGlobalLoadingAutoCompletedHint'),
        );
      }),
    );

    try {
      await AppGlobalDialogService.instance.showLoading(
        message: context.tr('adsGlobalLoadingPressBackHint'),
        loadingVisual: vm.loadingVisual,
        loadingVariant: vm.loadingVariant,
        progressType: vm.progressType,
        loadingBackBehavior: AppDialogLoadingBackBehavior.confirmCancel,
        cancelTitle: context.tr('adsCancelGlobalLoadingTitle'),
        cancelMessage: context.tr('adsCancelGlobalLoadingMessage'),
        stayLabel: context.tr('stay'),
        cancelLabel: context.tr('cancel'),
        onCancelRequested: () async {
          cancelledByUser = true;
          if (!mounted) return false;
          vm.setLastResult(context.tr('adsCancelRequestedFromBackButton'));
          return true;
        },
        onCancelled: () async {
          if (!mounted) return;
          vm.setLastResult(context.tr('adsGlobalLoadingCanceledByUser'));
        },
      );
    } finally {
      if (!mounted) return;
      vm.setRunning(false);
    }
  }
}

class _Card extends StatelessWidget {
  final String title;
  final Widget child;

  const _Card({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }
}
