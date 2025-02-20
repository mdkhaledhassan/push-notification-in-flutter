import 'package:firebase_messaging/firebase_messaging.dart';

class DeviceToken {
  Future<String?> getDeviceToken() async {
    String? deviceToken = '@';
    try {
      deviceToken = await FirebaseMessaging.instance.getToken();
    } catch (e) {
      print(e.toString());
    }
    if (deviceToken != null) {
      // controller.postDeviceToken(deviceToken);
    }
    return deviceToken;
  }
}
