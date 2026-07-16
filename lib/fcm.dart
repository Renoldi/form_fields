// Optional FCM entrypoint for consumers who want to opt-in to FCM helpers.

// This file re-exports the internal FCM helpers so consumers can import
// `package:form_fields/fcm.dart` and add the required Firebase deps only
// when they actually use FCM.

export 'src/service/fcm_service.dart'
    show FCMService, fcmBackgroundHandler, FCMOptions;
export 'model/fcm_models.dart' show FCMMessage, FCMNotification;
