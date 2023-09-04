import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';

class NotificationService {
  static const platform = MethodChannel("com.example.patient_alert/bluetooth");

  static Future<String?> getNotifications() async {
    try {
      final String? notifications = await platform.invokeMethod('getNotifications');
      return notifications;
    } on PlatformException catch (e) {
      Fluttertoast.showToast(msg: "Failed to get notifications.");
      return null;
    }
  }
}
