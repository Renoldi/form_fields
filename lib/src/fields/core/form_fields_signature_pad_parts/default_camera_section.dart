part of '../form_fields_signature_pad.dart';

/// Default visual wrapper for the live camera section.
class _DefaultCameraSection extends StatelessWidget {
  final Widget child;
  const _DefaultCameraSection({required this.child});

  @override
  Widget build(BuildContext context) {
    final localizations = FormFieldsLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Wrap(
          spacing: 6,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Icon(
              Icons.camera_front_outlined,
              size: 18,
              color: colorScheme.primary,
            ),
            Text(
              localizations.get('liveCaptureTitle'),
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: .12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                localizations.get('liveCaptureAutoOnSign'),
                style: TextStyle(
                  fontSize: 10,
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}
