import 'package:material_ui/material_ui.dart';
import 'package:form_fields/form_fields.dart';
import 'package:permission_handler/permission_handler.dart';

/// Widget that checks and requests camera, gallery, and internet permissions before showing [child].
class PermissionGate extends StatefulWidget {
  final Widget child;
  final Widget? deniedWidget;
  final VoidCallback? onPermissionGranted;

  /// Optional callback to open the app's custom settings page.
  /// If not provided, falls back to [openAppSettings()].
  final VoidCallback? onOpenSettings;

  const PermissionGate({
    super.key,
    required this.child,
    this.deniedWidget,
    this.onPermissionGranted,
    this.onOpenSettings,
  });

  /// Convenience helper to request camera permission immediately from code
  /// (for example in a page's `initState`) so permission flow runs before
  /// building widgets that depend on it.
  static Future<bool> ensureCameraPermission(
    BuildContext context, {
    VoidCallback? onOpenSettings,
  }) async {
    try {
      final status = await Permission.camera.status;
      if (status.isGranted) return true;
      final result = await Permission.camera.request();
      if (result.isGranted) return true;
      if (result.isPermanentlyDenied && context.mounted) {
        await _showSettingsDialog(
          context,
          message: 'permissionCameraContent',
          onOpenSettings: onOpenSettings,
        );
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Ensure permissions for image picker source.
  /// `source` may be 'camera' or 'gallery'. Returns true when permission is granted.
  ///
  /// Use `PermissionGate.ensurePickerPermission(context, source: 'camera')`
  /// before opening camera picker, or `source: 'gallery'` for gallery.
  static Future<bool> ensurePickerPermission(
    BuildContext context, {
    String? source,
    VoidCallback? onOpenSettings,
  }) async {
    if (source == 'camera') {
      return ensureCameraPermission(context, onOpenSettings: onOpenSettings);
    }

    // Gallery. If the permission plugin itself fails, let the picker decide
    // instead of blocking the user here.
    try {
      if (Theme.of(context).platform == TargetPlatform.iOS) {
        final s = await Permission.photos.request();
        return s.isGranted;
      }
      // Android/other: try storage first, then photos
      final s1 = await Permission.storage.request();
      if (s1.isGranted) return true;
      final s2 = await Permission.photos.request();
      return s2.isGranted;
    } catch (_) {
      return true;
    }
  }

  /// Shows the "permission required" dialog with Cancel and Open settings
  /// actions. Opening settings uses [onOpenSettings] when given, otherwise the
  /// platform settings page.
  static Future<void> _showSettingsDialog(
    BuildContext context, {
    required String message,
    VoidCallback? onOpenSettings,
    Future<void> Function()? afterSettings,
  }) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final l = FormFieldsLocalizations.of(dialogContext);
        return AlertDialog(
          title: Text(l.get('permissionRequiredTitle')),
          content: Text(l.get(message)),
          actions: [
            SizedBox(
              width: 92,
              child: AppButton(
                type: AppButtonType.outlined,
                size: AppSize.small,
                text: l.get('cancel'),
                useSafeArea: false,
                onPressed: () => Navigator.of(dialogContext).pop(),
              ),
            ),
            SizedBox(
              width: 92,
              child: AppButton(
                type: AppButtonType.filled,
                size: AppSize.small,
                text: l.get('openSettings'),
                useSafeArea: false,
                onPressed: () async {
                  Navigator.of(dialogContext).pop();
                  if (onOpenSettings != null) {
                    try {
                      onOpenSettings();
                    } catch (_) {}
                  } else {
                    await openAppSettings();
                  }
                  await afterSettings?.call();
                },
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  State<PermissionGate> createState() => _PermissionGateState();
}

class _PermissionGateState extends State<PermissionGate> {
  bool _granted = false;
  bool _checking = true;

  bool _didRequest = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didRequest) {
      _didRequest = true;
      _checkPermissions();
    }
  }

  Future<void> _checkPermissions() async {
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;
    final perms = <Permission>[
      Permission.camera,
      if (isIOS)
        Permission.photos
      else ...[
        Permission.storage,
        Permission.photos,
        Permission.videos,
        Permission.audio,
      ],
    ];

    bool granted = false;
    bool permanentlyDenied = false;
    try {
      final statuses = await perms.request().timeout(
        const Duration(seconds: 8),
      );
      // Only camera gates the camera UI. Other permissions do not reveal it.
      final cameraStatus = statuses[Permission.camera];
      granted = cameraStatus != null && cameraStatus.isGranted;
      permanentlyDenied =
          cameraStatus != null && cameraStatus.isPermanentlyDenied;
    } catch (_) {
      // Timeout or error: fall back to the current camera status.
      final camStatus = await Permission.camera.status;
      granted = camStatus.isGranted;
      permanentlyDenied = camStatus.isPermanentlyDenied;
    }

    // The awaits above may have run after the widget was removed.
    if (!mounted) return;

    final wasGranted = _granted;
    setState(() {
      _granted = granted;
      _checking = false;
    });

    if (permanentlyDenied && !_granted) {
      // Explain how to enable permissions from Settings, after this frame.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        PermissionGate._showSettingsDialog(
          context,
          message: 'permissionGenericContent',
          onOpenSettings: widget.onOpenSettings,
          // Re-check after returning from settings.
          afterSettings: () async {
            if (!mounted) return;
            setState(() => _checking = true);
            await _checkPermissions();
          },
        );
      });
    }

    if (_granted && !wasGranted) {
      try {
        widget.onPermissionGranted?.call();
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_granted) {
      return widget.child;
    }
    return widget.deniedWidget ??
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                FormFieldsLocalizations.of(
                  context,
                ).get('permissionsRequiredShort'),
              ),
              const SizedBox(height: 16),
              AppButton(
                type: AppButtonType.filled,
                size: AppSize.medium,
                text: FormFieldsLocalizations.of(context).get('requestAgain'),
                onPressed: _checkPermissions,
              ),
            ],
          ),
        );
  }
}
