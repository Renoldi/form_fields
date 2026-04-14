import 'dart:async';

import 'package:flutter/material.dart';
import 'package:form_fields/form_fields.dart';
import 'package:provider/provider.dart';

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
              'AppDialogService',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Focused demo for local and global dialog flows.',
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
      title: 'Options',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: const Text('Use blocking loading in guard()'),
            value: vm.useBlockingLoading,
            onChanged: vm.setBlockingLoading,
          ),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: const Text('Simulate error on guard()'),
            value: vm.simulateError,
            onChanged: vm.setSimulateError,
          ),
          const SizedBox(height: 8),
          const Text('Dialog position'),
          const SizedBox(height: 8),
          SegmentedButton<AppDialogPosition>(
            segments: const [
              ButtonSegment(value: AppDialogPosition.top, label: Text('Top')),
              ButtonSegment(
                  value: AppDialogPosition.center, label: Text('Center')),
              ButtonSegment(
                  value: AppDialogPosition.bottom, label: Text('Bottom')),
            ],
            selected: {vm.position},
            onSelectionChanged: (set) => vm.setPosition(set.first),
          ),
          const SizedBox(height: 10),
          const Text('Loading visual'),
          const SizedBox(height: 8),
          SegmentedButton<AppDialogLoadingVisual>(
            segments: const [
              ButtonSegment(
                value: AppDialogLoadingVisual.indicator,
                label: Text('Indicator'),
              ),
              ButtonSegment(
                value: AppDialogLoadingVisual.progress,
                label: Text('Progress'),
              ),
            ],
            selected: {vm.loadingVisual},
            onSelectionChanged: (set) => vm.setLoadingVisual(set.first),
          ),
          if (vm.loadingVisual == AppDialogLoadingVisual.indicator) ...[
            const SizedBox(height: 8),
            SegmentedButton<AppLoadingVariant>(
              segments: const [
                ButtonSegment(
                  value: AppLoadingVariant.spinner,
                  label: Text('Spinner'),
                ),
                ButtonSegment(
                  value: AppLoadingVariant.pulse,
                  label: Text('Pulse'),
                ),
                ButtonSegment(
                  value: AppLoadingVariant.dots,
                  label: Text('Dots'),
                ),
              ],
              selected: {vm.loadingVariant},
              onSelectionChanged: (set) => vm.setLoadingVariant(set.first),
            ),
          ],
          if (vm.loadingVisual == AppDialogLoadingVisual.progress) ...[
            const SizedBox(height: 8),
            SegmentedButton<AppProgressType>(
              segments: const [
                ButtonSegment(
                  value: AppProgressType.circular,
                  label: Text('Circular'),
                ),
                ButtonSegment(
                  value: AppProgressType.linear,
                  label: Text('Linear'),
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
      title: 'Actions',
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
                  text: 'Show Success',
                  onPressed: () => _showSuccess(context, vm),
                ),
              ),
              SizedBox(
                width: 180,
                child: AppButton(
                  type: AppButtonType.outlined,
                  text: 'Show Error',
                  onPressed: () => _showError(context, vm),
                ),
              ),
              SizedBox(
                width: 180,
                child: AppButton(
                  type: AppButtonType.text,
                  text: vm.isRunning ? 'Running...' : 'Run guard() demo',
                  onPressed: vm.isRunning ? null : () => _runGuard(context, vm),
                ),
              ),
              SizedBox(
                width: 180,
                child: AppButton(
                  type: AppButtonType.filledTonal,
                  text: 'Global Success',
                  onPressed: () => _showGlobalSuccess(vm),
                ),
              ),
              SizedBox(
                width: 180,
                child: AppButton(
                  type: AppButtonType.elevated,
                  text: vm.isRunning
                      ? 'Global Running...'
                      : 'Global guard() demo',
                  onPressed: vm.isRunning ? null : () => _runGlobalGuard(vm),
                ),
              ),
              SizedBox(
                width: 180,
                child: AppButton(
                  type: AppButtonType.fab,
                  text: vm.isRunning
                      ? 'Global Loading...'
                      : 'Global loading cancel demo',
                  onPressed: vm.isRunning
                      ? null
                      : () => _runGlobalLoadingConfirmCancelDemo(vm),
                ),
              ),
              SizedBox(
                width: 180,
                child: AppButton(
                  type: AppButtonType.outlined,
                  text: 'Tap test ($_tapCounter)',
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
              ? 'Guard running: tap test should only be blocked in blocking mode.'
              : 'Ready.'),
          const SizedBox(height: 6),
          Text('Last guard result: ${vm.lastResult}'),
        ],
      ),
    );
  }

  Future<void> _showSuccess(BuildContext context, ViewModel vm) {
    return AppDialogService(context).showSuccess(
      title: 'Success',
      message: 'Operation completed successfully.',
      position: vm.position,
    );
  }

  Future<void> _showError(BuildContext context, ViewModel vm) {
    return AppDialogService(context).showError(
      title: 'Error',
      message: 'Unable to complete operation.',
      dialogType: AppDialogType.server,
      position: vm.position,
    );
  }

  Future<void> _runGuard(BuildContext context, ViewModel vm) async {
    vm.setRunning(true);

    final result = await AppDialogService(context).guard<String>(
      task: () async {
        await Future<void>.delayed(const Duration(seconds: 2));
        if (vm.simulateError) {
          throw Exception('Network timeout while syncing data.');
        }
        return 'sync completed';
      },
      errorTitle: 'Guard demo',
      mapError: (error) => (
        message: error.toString().replaceFirst('Exception: ', ''),
        type: AppDialogType.network,
      ),
      position: vm.position,
      showBlockingLoading: vm.useBlockingLoading,
      loadingMessage: 'Syncing...',
      loadingVisual: vm.loadingVisual,
      loadingVariant: vm.loadingVariant,
      progressType: vm.progressType,
    );

    vm.setRunning(false);
    vm.setLastResult(result ?? 'null (failed and handled by dialog)');
  }

  Future<void> _showGlobalSuccess(ViewModel vm) {
    return AppGlobalDialogService.instance.showSuccess(
      title: 'Global Success',
      message: 'This dialog is shown without passing local BuildContext.',
      position: vm.position,
    );
  }

  Future<void> _runGlobalGuard(ViewModel vm) async {
    vm.setRunning(true);

    final result = await AppGlobalDialogService.instance.guard<String>(
      task: () async {
        await Future<void>.delayed(const Duration(seconds: 2));
        if (vm.simulateError) {
          throw Exception('Global request timeout while syncing data.');
        }
        return 'global sync completed';
      },
      errorTitle: 'Global guard demo',
      mapError: (error) => (
        message: error.toString().replaceFirst('Exception: ', ''),
        type: AppDialogType.network,
      ),
      position: vm.position,
      showBlockingLoading: vm.useBlockingLoading,
      loadingMessage: 'Global syncing...',
      loadingVisual: vm.loadingVisual,
      loadingVariant: vm.loadingVariant,
      progressType: vm.progressType,
    );

    vm.setRunning(false);
    vm.setLastResult(result ?? 'null (global failed and handled by dialog)');
  }

  Future<void> _runGlobalLoadingConfirmCancelDemo(ViewModel vm) async {
    vm.setRunning(true);
    var cancelledByUser = false;

    // Auto-complete simulation so demo can finish even without back interaction.
    unawaited(
      Future<void>.delayed(const Duration(seconds: 4), () {
        if (cancelledByUser) return;
        AppGlobalDialogService.instance.hide();
        vm.setLastResult(
          'Global loading auto-completed. Press back next run to test cancel flow.',
        );
      }),
    );

    try {
      await AppGlobalDialogService.instance.showLoading(
        message: 'Global loading... press device back to test confirm cancel.',
        loadingVisual: vm.loadingVisual,
        loadingVariant: vm.loadingVariant,
        progressType: vm.progressType,
        loadingBackBehavior: AppDialogLoadingBackBehavior.confirmCancel,
        cancelTitle: 'Cancel Global Loading?',
        cancelMessage: 'The global operation is still running. Cancel it now?',
        stayLabel: 'Stay',
        cancelLabel: 'Cancel',
        onCancelRequested: () async {
          cancelledByUser = true;
          vm.setLastResult('Cancel requested from back button.');
          return true;
        },
        onCancelled: () async {
          vm.setLastResult('Global loading canceled by user via device back.');
        },
      );
    } finally {
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
