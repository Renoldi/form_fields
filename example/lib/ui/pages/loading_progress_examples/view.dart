import 'package:flutter/material.dart';
import 'package:form_fields/form_fields.dart';
import 'package:provider/provider.dart';

import 'presenter.dart';
import 'view_model.dart';

class View extends PresenterState {
  bool _useBlockingLoading = false;
  bool _simulateGuardError = false;
  AppDialogPosition _dialogPosition = AppDialogPosition.top;
  AppDialogLoadingVisual _loadingVisual = AppDialogLoadingVisual.indicator;
  AppProgressType _progressType = AppProgressType.circular;
  AppLoadingVariant _loadingVariant = AppLoadingVariant.spinner;
  String _lastGuardResult = '-';
  bool _isGuardRunning = false;
  int _tapCounter = 0;

  @override
  Widget build(BuildContext context) {
    return Consumer<ViewModel>(
      builder: (context, vm, _) {
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Loading & progress',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 760;
                final cards = [
                  _LoadingCard(isLoading: vm.isSimulating),
                  _ProgressCard(progress: vm.progress),
                ];

                if (isNarrow) {
                  return Column(
                    children: [
                      cards[0],
                      const SizedBox(height: 12),
                      cards[1],
                    ],
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: cards[0]),
                    const SizedBox(width: 12),
                    Expanded(child: cards[1]),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            AppButton(
              type: AppButtonType.filled,
              text: vm.isSimulating ? 'Simulating...' : 'Simulate Progress',
              icon: const Icon(Icons.play_arrow_outlined),
              isLoading: vm.isSimulating,
              onPressed: vm.simulateProgress,
            ),
            const SizedBox(height: 16),
            _buildDialogServiceSection(context),
          ],
        );
      },
    );
  }

  Widget _buildDialogServiceSection(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return _CardShell(
      title: 'Dialog service examples',
      subtitle:
          'Reusable success/error/guard dialogs with optional loading mode',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const Text('Use blocking loading dialog in guard()'),
              value: _useBlockingLoading,
              onChanged: (value) {
                setState(() {
                  _useBlockingLoading = value;
                });
              },
            ),
            const SizedBox(height: 8),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const Text('Simulate guard error (show error dialog)'),
              value: _simulateGuardError,
              onChanged: (value) {
                setState(() {
                  _simulateGuardError = value;
                });
              },
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
              selected: {_dialogPosition},
              onSelectionChanged: (value) {
                setState(() {
                  _dialogPosition = value.first;
                });
              },
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
              selected: {_loadingVisual},
              onSelectionChanged: (value) {
                setState(() {
                  _loadingVisual = value.first;
                });
              },
            ),
            if (_loadingVisual == AppDialogLoadingVisual.indicator) ...[
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
                selected: {_loadingVariant},
                onSelectionChanged: (value) {
                  setState(() {
                    _loadingVariant = value.first;
                  });
                },
              ),
            ],
            if (_loadingVisual == AppDialogLoadingVisual.progress) ...[
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
                selected: {_progressType},
                onSelectionChanged: (value) {
                  setState(() {
                    _progressType = value.first;
                  });
                },
              ),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                SizedBox(
                  width: 180,
                  child: AppButton(
                    type: AppButtonType.filled,
                    text: 'Show Success',
                    onPressed: () => _showSuccess(context),
                  ),
                ),
                SizedBox(
                  width: 180,
                  child: AppButton(
                    type: AppButtonType.outlined,
                    text: 'Show Error',
                    onPressed: () => _showError(context),
                  ),
                ),
                SizedBox(
                  width: 180,
                  child: AppButton(
                    type: AppButtonType.text,
                    text: _isGuardRunning
                        ? 'Running guard...'
                        : 'Run guard() demo',
                    onPressed: _isGuardRunning
                        ? null
                        : () => _runGuardFailDemo(context),
                  ),
                ),
                SizedBox(
                  width: 180,
                  child: AppButton(
                    type: AppButtonType.outlined,
                    text: 'Tap test ($_tapCounter)',
                    onPressed: _incrementTapCounter,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              _isGuardRunning
                  ? 'Guard is running: try tapping "Tap test". In non-blocking mode it should increment.'
                  : 'Run guard demo to compare blocking vs non-blocking interaction.',
            ),
            const SizedBox(height: 6),
            Text('Last guard result: $_lastGuardResult'),
          ],
        ),
      ),
    );
  }

  Future<void> _showSuccess(BuildContext context) {
    return AppDialogService(context).showSuccess(
      title: 'Success',
      message: 'Your operation completed successfully.',
      position: _dialogPosition,
    );
  }

  Future<void> _showError(BuildContext context) {
    return AppDialogService(context).showError(
      title: 'Error',
      message: 'Something went wrong. Please retry.',
      dialogType: AppDialogType.server,
      position: _dialogPosition,
    );
  }

  Future<void> _runGuardFailDemo(BuildContext context) async {
    if (_isGuardRunning) return;

    setState(() {
      _isGuardRunning = true;
    });

    final result = await AppDialogService(context).guard<String>(
      task: () async {
        await Future<void>.delayed(const Duration(seconds: 3));
        if (_simulateGuardError) {
          throw Exception('Request timeout while syncing data.');
        }
        return 'sync completed';
      },
      errorTitle: 'Guard error demo',
      mapError: (error) => (
        message: error.toString().replaceFirst('Exception: ', ''),
        type: AppDialogType.network,
      ),
      position: _dialogPosition,
      showBlockingLoading: _useBlockingLoading,
      loadingMessage: 'Syncing data...',
      loadingVisual: _loadingVisual,
      loadingVariant: _loadingVariant,
      progressType: _progressType,
    );

    if (!mounted) return;
    setState(() {
      _isGuardRunning = false;
      _lastGuardResult = result ?? 'null (failed and handled by dialog)';
    });
  }

  void _incrementTapCounter() {
    setState(() {
      _tapCounter += 1;
    });
  }
}

class _LoadingCard extends StatelessWidget {
  final bool isLoading;

  const _LoadingCard({required this.isLoading});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return _CardShell(
      title: 'Loading indicator',
      subtitle: 'Reusable loading states for async actions',
      child: Container(
        height: 180,
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AppLoadingIndicator(
              variant: AppLoadingVariant.dots,
              size: 42,
              color: cs.primary,
            ),
            const SizedBox(width: 28),
            AppLoadingIndicator(
              variant: isLoading
                  ? AppLoadingVariant.pulse
                  : AppLoadingVariant.spinner,
              size: 70,
              color: cs.primary,
              trackColor: cs.primary.withValues(alpha: 0.25),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  final double progress;

  const _ProgressCard({required this.progress});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return _CardShell(
      title: 'Progress indicators',
      subtitle: 'Shows current completion in real-time',
      child: Container(
        height: 180,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AppProgressIndicator(value: progress * 0.7, showValueLabel: true),
            const SizedBox(height: 12),
            AppProgressIndicator(value: progress, showValueLabel: true),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: AppProgressIndicator(
                    value: null,
                    minHeight: 6,
                    trackColor: cs.primary.withValues(alpha: 0.1),
                  ),
                ),
                const SizedBox(width: 12),
                AppProgressIndicator(
                  type: AppProgressType.circular,
                  value: progress,
                  size: 28,
                  strokeWidth: 3,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CardShell extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const _CardShell({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            child,
            const SizedBox(height: 12),
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
