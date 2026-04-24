import 'package:flutter/material.dart';
import 'package:form_fields/form_fields.dart';
import 'package:provider/provider.dart';
import 'package:form_fields_example/localization/localizations.dart';

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
              context.tr('loadingProgress'),
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
              text: vm.isSimulating
                  ? context.tr('lpSimulating')
                  : context.tr('lpSimulateProgress'),
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
      title: context.tr('lpDialogServiceExamplesTitle'),
      subtitle: context.tr('lpDialogServiceExamplesSubtitle'),
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
              title: Text(context.tr('lpUseBlockingLoadingInGuard')),
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
              title: Text(context.tr('lpSimulateGuardError')),
              value: _simulateGuardError,
              onChanged: (value) {
                setState(() {
                  _simulateGuardError = value;
                });
              },
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
              selected: {_dialogPosition},
              onSelectionChanged: (value) {
                setState(() {
                  _dialogPosition = value.first;
                });
              },
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
                    text: context.tr('lpShowSuccess'),
                    onPressed: () => _showSuccess(context),
                  ),
                ),
                SizedBox(
                  width: 180,
                  child: AppButton(
                    type: AppButtonType.outlined,
                    text: context.tr('lpShowError'),
                    onPressed: () => _showError(context),
                  ),
                ),
                SizedBox(
                  width: 180,
                  child: AppButton(
                    type: AppButtonType.text,
                    text: _isGuardRunning
                        ? context.tr('lpRunningGuard')
                        : context.tr('lpRunGuardDemo'),
                    onPressed: _isGuardRunning
                        ? null
                        : () => _runGuardFailDemo(context),
                  ),
                ),
                SizedBox(
                  width: 180,
                  child: AppButton(
                    type: AppButtonType.outlined,
                    text: '${context.tr('lpTapTest')} ($_tapCounter)',
                    onPressed: _incrementTapCounter,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              _isGuardRunning
                  ? context.tr('lpGuardRunningHint')
                  : context.tr('lpRunGuardComparisonHint'),
            ),
            const SizedBox(height: 6),
            Text('${context.tr('lpLastGuardResult')}: $_lastGuardResult'),
          ],
        ),
      ),
    );
  }

  Future<void> _showSuccess(BuildContext context) {
    return AppDialogService(context).showSuccess(
      title: context.tr('success'),
      message: context.tr('lpOperationCompletedSuccessfully'),
      position: _dialogPosition,
      onComplete: () {
        if (!mounted) return;
      },
    );
  }

  Future<void> _showError(BuildContext context) {
    return AppDialogService(context).showError(
      title: context.tr('updateFailed'),
      message: context.tr('errorSomethingWentWrong'),
      dialogType: AppDialogType.server,
      position: _dialogPosition,
      onComplete: () {
        if (!mounted) return;
      },
    );
  }

  Future<void> _runGuardFailDemo(BuildContext context) async {
    if (_isGuardRunning) return;

    setState(() {
      _isGuardRunning = true;
    });

    final localTr = context.tr;
    final result = await AppDialogService(context).guard<String>(
      task: () async {
        await Future<void>.delayed(const Duration(seconds: 3));
        if (_simulateGuardError) {
          throw Exception('lpErrorRequestTimeoutSync');
        }
        // Hindari akses context langsung setelah await
        return localTr('lpSyncCompleted');
      },
      errorTitle: context.tr('lpGuardErrorDemoTitle'),
      mapError: (error) => (
        message: context.tr(error.toString().replaceFirst('Exception: ', '')),
        type: AppDialogType.network,
        details: null,
      ),
      loadingPosition: _dialogPosition,
      resultPosition: _dialogPosition,
      showBlockingLoading: _useBlockingLoading,
      loadingMessage: context.tr('lpSyncingData'),
      loadingVisual: _loadingVisual,
      loadingVariant: _loadingVariant,
      progressType: _progressType,
    );

    if (!mounted) return;
    setState(() {
      _isGuardRunning = false;
      _lastGuardResult = result ?? context.tr('lpGuardFailedHandledByDialog');
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
      title: context.tr('lpLoadingIndicatorTitle'),
      subtitle: context.tr('lpLoadingIndicatorSubtitle'),
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
      title: context.tr('lpProgressIndicatorsTitle'),
      subtitle: context.tr('lpProgressIndicatorsSubtitle'),
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
