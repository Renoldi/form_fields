import 'package:flutter/material.dart';
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
    List<Permission> perms = [Permission.camera];
    if (Theme.of(context).platform == TargetPlatform.iOS) {
      perms.add(Permission.photos);
    } else {
      perms.add(Permission.storage);
      perms.addAll([Permission.photos, Permission.videos, Permission.audio]);
    }
    bool granted = false;
    bool permanentlyDenied = false;
    try {
      final statuses = await perms.request().timeout(
            const Duration(seconds: 8),
          );
      granted = statuses.values.any((s) => s.isGranted);
      permanentlyDenied = statuses.values.any((s) => s.isPermanentlyDenied);
    } catch (_) {
      // Timeout or error: fallback to checking current status
      final statuses = await Future.wait(perms.map((p) => p.status));
      granted = statuses.any((s) => s.isGranted);
      permanentlyDenied = statuses.any((s) => s.isPermanentlyDenied);
    }
    setState(() {
      final wasGranted = _granted;
      _granted = granted;
      _checking = false;
      if (permanentlyDenied && !_granted) {
        // Show a dialog explaining how to enable permissions from Settings.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          showDialog<void>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Permission required'),
              content: const Text(
                  'This feature requires permission. Please enable it in the app settings.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    Navigator.of(context).pop();
                    if (widget.onOpenSettings != null) {
                      try {
                        widget.onOpenSettings!.call();
                      } catch (_) {}
                    } else {
                      await openAppSettings();
                    }
                    // After returning from settings (or navigation), re-check permissions.
                    if (mounted) {
                      setState(() {
                        _checking = true;
                      });
                      _checkPermissions();
                    }
                  },
                  child: const Text('Buka Pengaturan'),
                ),
              ],
            ),
          );
        });
      }
      if (_granted && !wasGranted) {
        try {
          widget.onPermissionGranted?.call();
        } catch (_) {}
      }
    });
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
              const Text('Permissions are required to use this feature.'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _checkPermissions,
                child: const Text('Request Again'),
              ),
            ],
          ),
        );
  }
}
