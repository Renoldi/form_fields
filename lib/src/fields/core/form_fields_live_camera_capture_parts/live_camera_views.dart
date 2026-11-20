part of '../form_fields_live_camera_capture.dart';

// Placeholder and captured-photo views for the live camera preview.

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

class _CapturedPhoto extends StatelessWidget {
  final MyImageResult result;
  final Map<String, String>? headers;
  const _CapturedPhoto({required this.result, this.headers});

  @override
  Widget build(BuildContext context) {
    if (kDebugMode) {
      debugLog(
        '[FormFieldsLiveCameraCapture._CapturedPhoto] '
        'path=${result.path}, link=${result.link}, base64Len=${result.base64.length}, headers=${headers?.keys.toList()}',
      );
    }

    // Build local fallback (file -> base64 -> placeholder)
    // Prefer local content: file -> base64. Only if neither exists use network
    // link. This avoids triggering an immediate GET after upload when we
    // already have the bytes locally.
    final hasLocalPath =
        result.path.isNotEmpty && File(result.path).existsSync();
    final bytes = decodeBase64Image(result.base64);
    final hasBase64 = bytes != null && bytes.isNotEmpty;

    if (hasLocalPath) {
      return Image.file(
        File(result.path),
        fit: BoxFit.cover,
        width: double.infinity,
      );
    }

    if (hasBase64) {
      return Image.memory(bytes, fit: BoxFit.cover, width: double.infinity);
    }

    if (result.link.isNotEmpty) {
      return Image(
        image: NetworkImage(result.link, headers: headers),
        fit: BoxFit.cover,
        width: double.infinity,
        errorBuilder: (_, error, stackTrace) => Center(
          child: Icon(
            Icons.broken_image_outlined,
            size: 32,
            color: resolveTextColor(context, muted: true),
          ),
        ),
      );
    }

    return Center(
      child: Icon(
        Icons.broken_image_outlined,
        size: 32,
        color: resolveTextColor(context, muted: true),
      ),
    );
  }
}
