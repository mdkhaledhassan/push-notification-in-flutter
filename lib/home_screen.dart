import 'package:firebase_push_notification/services/device_token.dart';
import 'package:firebase_push_notification/services/notification_service.dart';
import 'package:flutter/material.dart';
import '../../../style.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  NotificationHelper notificationHelper = NotificationHelper();
  DeviceToken deviceToken = DeviceToken();

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      checkAndShowSoundDialog(context);
    });
    notificationHelper.notificationPermission();
    deviceToken.getDeviceToken();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold();
  }
}
