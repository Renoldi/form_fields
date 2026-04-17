import 'package:flutter/material.dart';
import 'package:form_fields/form_fields.dart';
import 'package:provider/provider.dart';
import 'package:form_fields_example/localization/localizations.dart';

import 'presenter.dart';
import 'view_model.dart';

class View extends PresenterState {
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
            buildActions(context, vm),
          ],
        );
      },
    );
  }

  Widget _buildOptionsCard(BuildContext context, ViewModel vm) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            Text('Loading Back Behavior'),
            const SizedBox(height: 8),
            SegmentedButton<AppDialogLoadingBackBehavior>(
              segments: [
                ButtonSegment(
                    value: AppDialogLoadingBackBehavior.block,
                    label: Text('Block')),
                ButtonSegment(
                    value: AppDialogLoadingBackBehavior.allow,
                    label: Text('Dismissible')),
                ButtonSegment(
                    value: AppDialogLoadingBackBehavior.confirmCancel,
                    label: Text('Confirm Cancel')),
              ],
              selected: {vm.loadingBackBehavior},
              onSelectionChanged: (set) => vm.setLoadingBackBehavior(set.first),
            ),
            Text('Loading Dialog Position'),
            const SizedBox(height: 8),
            SegmentedButton<AppDialogLoadingContainer>(
              segments: [
                ButtonSegment(
                    value: AppDialogLoadingContainer.card, label: Text('Card')),
                ButtonSegment(
                    value: AppDialogLoadingContainer.nonCard,
                    label: Text('Non-Card')),
              ],
              selected: {vm.loadingContainer},
              onSelectionChanged: (set) => vm.setLoadingContainer(set.first),
            ),
            const SizedBox(height: 10),
            Text('Loading Dialog Position'),
            const SizedBox(height: 8),
            SegmentedButton<AppDialogPosition>(
              segments: [
                ButtonSegment(value: AppDialogPosition.top, label: Text('Top')),
                ButtonSegment(
                    value: AppDialogPosition.center, label: Text('Center')),
                ButtonSegment(
                    value: AppDialogPosition.bottom, label: Text('Bottom')),
              ],
              selected: {vm.loadingPosition},
              onSelectionChanged: (set) => vm.setLoadingPosition(set.first),
            ),
            const SizedBox(height: 10),
            Text('Result Dialog Position'),
            const SizedBox(height: 8),
            SegmentedButton<AppDialogPosition>(
              segments: [
                ButtonSegment(value: AppDialogPosition.top, label: Text('Top')),
                ButtonSegment(
                    value: AppDialogPosition.center, label: Text('Center')),
                ButtonSegment(
                    value: AppDialogPosition.bottom, label: Text('Bottom')),
              ],
              selected: {vm.resultPosition},
              onSelectionChanged: (set) => vm.setResultPosition(set.first),
            ),
            const SizedBox(height: 10),
            Text('Loading Visual'),
            const SizedBox(height: 8),
            SegmentedButton<AppDialogLoadingVisual>(
              segments: [
                ButtonSegment(
                    value: AppDialogLoadingVisual.indicator,
                    label: Text('Indicator')),
                ButtonSegment(
                    value: AppDialogLoadingVisual.progress,
                    label: Text('Progress')),
              ],
              selected: {vm.loadingVisual},
              onSelectionChanged: (set) => vm.setLoadingVisual(set.first),
            ),
            if (vm.loadingVisual == AppDialogLoadingVisual.indicator) ...[
              const SizedBox(height: 8),
              SegmentedButton<AppLoadingVariant>(
                segments: [
                  ButtonSegment(
                      value: AppLoadingVariant.spinner, label: Text('Spinner')),
                  ButtonSegment(
                      value: AppLoadingVariant.pulse, label: Text('Pulse')),
                  ButtonSegment(
                      value: AppLoadingVariant.dots, label: Text('Dots')),
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
                      value: AppProgressType.circular, label: Text('Circular')),
                  ButtonSegment(
                      value: AppProgressType.linear, label: Text('Linear')),
                ],
                selected: {vm.progressType},
                onSelectionChanged: (set) => vm.setProgressType(set.first),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget buildActions(BuildContext context, ViewModel vm) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    type: AppButtonType.filled,
                    text: 'Show text Loading',
                    onPressed: () async {
                      await AppDialogService(context).showLoading(
                        loadingContainer: vm.loadingContainer,
                        loadingVisual: vm.loadingVisual,
                        loadingVariant: vm.loadingVariant,
                        progressType: vm.progressType,
                        position: vm.loadingPosition,
                        loadingBackBehavior: vm.loadingBackBehavior,
                      );
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: AppButton(
                    type: AppButtonType.filled,
                    text: 'Show Loading',
                    onPressed: () async {
                      await AppDialogService(context).showLoading(
                        message: "",
                        loadingContainer: vm.loadingContainer,
                        loadingVisual: vm.loadingVisual,
                        loadingVariant: vm.loadingVariant,
                        progressType: vm.progressType,
                        position: vm.loadingPosition,
                        loadingBackBehavior: vm.loadingBackBehavior,
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    type: AppButtonType.filled,
                    text: 'Success',
                    onPressed: () async {
                      await AppDialogService(context).guard(
                        task: () async {
                          await Future.delayed(const Duration(seconds: 2));
                          return 'Success';
                        },
                        errorTitle: 'Error',
                        mapError: AppDialogService.defaultErrorMapper,
                        loadingPosition: vm.loadingPosition,
                        resultPosition: vm.resultPosition,
                        showBlockingLoading: true,
                        loadingMessage: 'Processing...',
                        loadingVisual: vm.loadingVisual,
                        loadingVariant: vm.loadingVariant,
                        progressType: vm.progressType,
                        loadingBackBehavior: vm.loadingBackBehavior,
                        showSuccessDialog: true,
                        successTitle: 'Success',
                        successMessage: 'Task completed successfully!',
                      );
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: AppButton(
                    type: AppButtonType.filled,
                    text: 'Error',
                    onPressed: () async {
                      await AppDialogService(context).guard(
                        task: () async {
                          await Future.delayed(const Duration(seconds: 2));
                          throw Exception('Simulated failure');
                        },
                        errorTitle: 'Error',
                        mapError: AppDialogService.defaultErrorMapper,
                        loadingPosition: vm.loadingPosition,
                        resultPosition: vm.resultPosition,
                        showBlockingLoading: true,
                        loadingMessage: 'Processing...',
                        loadingVisual: vm.loadingVisual,
                        loadingVariant: vm.loadingVariant,
                        progressType: vm.progressType,
                        loadingBackBehavior: vm.loadingBackBehavior,
                        showSuccessDialog: false,
                      );
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: AppButton(
                    type: AppButtonType.filled,
                    text: 'Warning',
                    onPressed: () async {
                      await AppDialogService(context).guard(
                        task: () async {
                          await Future.delayed(const Duration(seconds: 2));
                          throw ValidationException(
                              'Simulated validation warning: Please fill all required fields.');
                        },
                        errorTitle: 'Warning',
                        mapError: AppDialogService.defaultErrorMapper,
                        loadingPosition: vm.loadingPosition,
                        resultPosition: vm.resultPosition,
                        showBlockingLoading: true,
                        loadingMessage: 'Processing...',
                        loadingVisual: vm.loadingVisual,
                        loadingVariant: vm.loadingVariant,
                        progressType: vm.progressType,
                        loadingBackBehavior: vm.loadingBackBehavior,
                        showSuccessDialog: false,
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
