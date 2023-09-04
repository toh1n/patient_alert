import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:patient_alert/notification_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<String> notifications = [""];
  late Timer _timer;

  static const platform = MethodChannel("com.example.patient_alert/bluetooth");

  Future<void> _clearPrefs() async {
    try {
      final bool result = await platform.invokeMethod("clearPrefs");
      Fluttertoast.showToast(msg: "Notifications Cleared.");
    } on PlatformException catch (e) {
      Fluttertoast.showToast(msg: "Failed to clear notifications.");
    }
  }

  Future<void> fetchNotifications() async {
    String? notificationData = await NotificationService.getNotifications();
    if (notificationData != null) {
      setState(() {
        notifications = notificationData
            .split('\n')
            .where((element) => element.trim().isNotEmpty)  // Remove empty or whitespace-only strings
            .map((element) => element.trim())  // Trim each element
            .toList();
      });
    }
  }

  void _timerCallback(Timer timer) {
    setState(() {
      fetchNotifications();
    });
  }
  @override
  void initState() {
    super.initState();
    fetchNotifications();
    _timer = Timer.periodic(const Duration(seconds: 1), _timerCallback);
  }
  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      body: Visibility(
        visible: notifications.isEmpty == false,
        replacement: const Center(child: Text(
          "No Notifications",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),),
        child: ListView.builder(
          itemCount: notifications.length,
          itemBuilder: (context, index) {
            if (notifications[notifications.length - 1 - index].length > 5) {
              String text = notifications[notifications.length - 1 - index].toString();

              // Check if the string contains ": "
              if (text.contains(" #")) {
                List<String> parts = text.split(" #");

                // Check if parts have at least 2 elements
                if (parts.length >= 2) {
                  String eventDateAndTime = parts[0];

                  // Verify that text is long enough before performing a substring
                  if (text.length > eventDateAndTime.length + 2) {
                    String message = text.substring(eventDateAndTime.length + 2);

                    return Padding(
                      padding: const EdgeInsets.fromLTRB(16.0, 4, 16, 4),
                      child: Card(
                        elevation: 4,
                        color: Colors.white,
                        child: SizedBox(
                          height: 72,
                          child: ListTile(
                            onTap: () {
                              setState(() {});
                            },
                            leading: const Icon(Icons.notifications_active),
                            title: Text(
                              message,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(eventDateAndTime),
                          ),
                        ),
                      ),
                    );
                  } else {
                    print("Text is not long enough for substring operation");
                  }
                } else {
                  print("Invalid string format, expected at least 2 parts");
                }
              } else {
                print("String doesn't contain ': '");
              }
            }

            // return Padding(
            //   padding: const EdgeInsets.fromLTRB(16.0, 4, 16, 4),
            //   child: Card(
            //     elevation: 4,
            //     color: Colors.white,
            //     child: SizedBox(
            //       height: 72,
            //       child: ListTile(
            //         onTap: () {
            //           setState(() {});
            //         },
            //         leading: const Icon(Icons.notifications_active),
            //         title:  Text(
            //           notifications[notifications.length - 1 - index], // Reverse order
            //           style: const TextStyle(
            //             fontSize: 16,
            //             fontWeight: FontWeight.bold,
            //           ),
            //         ),
            //       ),
            //     ),
            //   ),
            // );
          },
        ),
      ),

      floatingActionButton: Visibility(
        visible: notifications.isEmpty == false,
        child: FloatingActionButton.extended(onPressed: (){_clearPrefs();setState(() {

        });}, label: const Text("Clear Notifications")),
      ),
    );
  }
}
