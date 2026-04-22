import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:audioplayers/audioplayers.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import '../app/data/model/body/notification_body.dart';
import '../app/data/model/body/payload_model.dart';
import '../app/modules/order/controllers/order_controller.dart';
import '../app/modules/order/views/order_view.dart';

@pragma('vm:entry-point')
Future<void> myBackgroundMessageHandler(RemoteMessage message) async {
  if (message.notification != null) return;

  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >()
      ?.createNotificationChannel(
        AndroidNotificationChannel(
          'high_importance_channel',
          'High Importance Notifications',
          importance: Importance.max,
          playSound: true,
          sound: RawResourceAndroidNotificationSound('notification'),
          enableVibration: true,
        ),
      );

  final androidInitialize = AndroidInitializationSettings(
    '@mipmap/ic_launcher',
  );
  final iOSInitialize = DarwinInitializationSettings();
  final initializationsSettings = InitializationSettings(
    android: androidInitialize,
    iOS: iOSInitialize,
  );

  await flutterLocalNotificationsPlugin.initialize(initializationsSettings);

  await NotificationHelper.showNotification(
    message,
    flutterLocalNotificationsPlugin,
    true,
  );
}

class NotificationHelper {
  static const String _channelId = 'high_importance_channel';
  static const String _channelName = 'High Importance Notifications';

  void notificationPermission() async {
    FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
    NotificationSettings settings = await FirebaseMessaging.instance
        .requestPermission(
          alert: true,
          announcement: false,
          badge: true,
          carPlay: false,
          criticalAlert: false,
          provisional: false,
          sound: true,
        );
    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint("User granted permission");
    } else if (settings.authorizationStatus ==
        AuthorizationStatus.provisional) {
      debugPrint("User granted provisional permission");
    } else {
      debugPrint("User denied permission");
    }
  }

  static Future<void> initialize(
    FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin,
  ) async {
    if (GetPlatform.isAndroid) {
      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(
            AndroidNotificationChannel(
              _channelId,
              _channelName,
              importance: Importance.max,
              playSound: true,
              sound: RawResourceAndroidNotificationSound('notification'),
              enableVibration: true,
            ),
          );
    }

    var androidInitialize = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    var iOSInitialize = DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );
    var initializationsSettings = InitializationSettings(
      android: androidInitialize,
      iOS: iOSInitialize,
    );

    await flutterLocalNotificationsPlugin.initialize(
      initializationsSettings,
      onDidReceiveNotificationResponse: (payload) async {
        try {
          if (payload.payload != null && payload.payload != '') {
            PayLoadBody payLoadBody = PayLoadBody.fromJson(
              jsonDecode(payload.payload!),
            );
            if (payLoadBody.topicName == 'Order Notification') {
              Get.to(() => OrderView());
            }
          }
        } catch (e) {}
        return;
      },
    );

    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      await NotificationHelper.showNotification(
        message,
        flutterLocalNotificationsPlugin,
        false,
      );

      try {
        final AudioPlayer player = AudioPlayer();
        await player.play(AssetSource('sound/notification.mp3'));
      } catch (e) {
        print('Audio play error: $e');
      }

      try {
        var orderController = Get.put(OrderController());
        final orderId = message.data["order_id"]?.toString() ?? "";
        orderController.orderNotificationId.value = orderId;
        orderController.orderNotfyLoader.value = orderId.isNotEmpty;
      } catch (e) {
        print('Order controller error: $e');
      }

      try {
        if (message.data.isNotEmpty) {
          NotificationBody notificationBody = convertNotification(message.data);
          if (notificationBody.topic == 'Order Notification') {
            Get.to(() => OrderView());
          }
        }
      } catch (e) {
        print('Navigation error: $e');
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage? message) async {
      try {
        if (message != null && message.data.isNotEmpty) {
          NotificationBody notificationBody = convertNotification(message.data);
          if (notificationBody.topic == 'Order Notification' ||
              notificationBody.topic == 'general') {
            Get.to(() => OrderView());
          }
        }
      } catch (e) {
        print('onMessageOpenedApp error: $e');
      }
    });
  }

  static Future<void> showNotification(
    RemoteMessage message,
    FlutterLocalNotificationsPlugin fln,
    bool data,
  ) async {
    if (GetPlatform.isIOS) return;

    if (!data && message.notification != null) {}

    String? title = message.data['title'] ?? message.notification?.title;
    String? body = message.data['body'] ?? message.notification?.body;
    String? image =
        (message.data['image'] != null &&
            message.data['image'].toString().isNotEmpty)
        ? message.data['image']
        : null;

    if (title == null || body == null) return;

    String playLoad = jsonEncode(message.data);

    try {
      if (image != null && image.isNotEmpty) {
        await showBigPictureNotificationHiddenLargeIcon(
          title,
          body,
          playLoad,
          image,
          fln,
        );
      } else {
        await showBigTextNotification(title, body, playLoad, fln);
      }
    } catch (e) {
      await showBigTextNotification(title, body, playLoad, fln);
    }
  }

  static Future<void> showBigTextNotification(
    String title,
    String body,
    String payload,
    FlutterLocalNotificationsPlugin fln,
  ) async {
    BigTextStyleInformation bigTextStyleInformation = BigTextStyleInformation(
      body,
      htmlFormatBigText: true,
      contentTitle: title,
      htmlFormatContentTitle: true,
    );

    AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          _channelId,
          _channelName,
          importance: Importance.max,
          priority: Priority.max,
          styleInformation: bigTextStyleInformation,
          playSound: true,
          sound: RawResourceAndroidNotificationSound('notification'),
        );

    NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    await fln.show(
      Random.secure().nextInt(100000),
      title,
      body,
      platformChannelSpecifics,
      payload: payload,
    );
  }

  static Future<void> showBigPictureNotificationHiddenLargeIcon(
    String title,
    String body,
    String payload,
    String image,
    FlutterLocalNotificationsPlugin fln,
  ) async {
    final String largeIconPath = await _downloadAndSaveFile(image, 'largeIcon');
    final String bigPicturePath = await _downloadAndSaveFile(
      image,
      'bigPicture',
    );

    final BigPictureStyleInformation bigPictureStyleInformation =
        BigPictureStyleInformation(
          FilePathAndroidBitmap(bigPicturePath),
          hideExpandedLargeIcon: true,
          contentTitle: title,
          htmlFormatContentTitle: true,
          summaryText: body,
          htmlFormatSummaryText: true,
        );

    AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          _channelId,
          _channelName,
          importance: Importance.max,
          priority: Priority.max,
          largeIcon: FilePathAndroidBitmap(largeIconPath),
          styleInformation: bigPictureStyleInformation,
          playSound: true,
          sound: RawResourceAndroidNotificationSound('notification'),
        );

    NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    await fln.show(
      Random.secure().nextInt(100000),
      title,
      body,
      platformChannelSpecifics,
      payload: payload,
    );
  }

  static NotificationBody convertNotification(Map<String, dynamic> data) {
    return NotificationBody.fromJson(data);
  }

  static Future<String> _downloadAndSaveFile(
    String url,
    String fileName,
  ) async {
    final Directory directory = await getApplicationDocumentsDirectory();
    final String filePath = '${directory.path}/$fileName';
    final http.Response response = await http.get(Uri.parse(url));
    final File file = File(filePath);
    await file.writeAsBytes(response.bodyBytes);
    return filePath;
  }
}
