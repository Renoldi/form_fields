// Re-export FCM helpers for consumers of the optional package.
export 'src/service/fcm_service.dart'
    show FCMService, fcmBackgroundHandler, FCMOptions;
export 'model/fcm_models.dart'
    show FCMMessage, FCMNotification, FCMMessageHandler;
