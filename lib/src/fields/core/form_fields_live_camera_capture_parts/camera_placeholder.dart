part of '../form_fields_live_camera_capture.dart';

class _CameraPlaceholder extends StatelessWidget {
  final double height;
  final IconData icon;
  final String message;
  final bool showSpinner;

  const _CameraPlaceholder({
    required this.height,
    required this.icon,
    required this.message,
    this.showSpinner = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showSpinner)
              CircularProgressIndicator(
                color: Theme.of(
                  context,
                ).colorScheme.onPrimary.withValues(alpha: 0.54),
              )
            else
              Icon(
                icon,
                color: Theme.of(
                  context,
                ).colorScheme.onPrimary.withValues(alpha: 0.54),
                size: 40,
              ),
            const SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(
                color: Theme.of(
                  context,
                ).colorScheme.onPrimary.withValues(alpha: 0.54),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
