import Flutter
import UIKit
import workmanager_apple

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // BGTaskScheduler rejects (and crashes on) a task request whose identifier has
    // no launch handler yet. Register every identifier listed in
    // BGTaskSchedulerPermittedIdentifiers here, before launch finishes. Keep this
    // list in sync with the `taskName` values passed in WorkerRegistration.
    for identifier in ["form_fields_flush", "send_current_location", "send_random_event"] {
      WorkmanagerPlugin.registerPeriodicTask(withIdentifier: identifier)
      WorkmanagerPlugin.registerBGProcessingTask(withIdentifier: identifier)
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}
