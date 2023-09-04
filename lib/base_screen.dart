import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:patient_alert/available_device_screen.dart';
import 'package:patient_alert/notifications_screen.dart';
import 'package:patient_alert/settings_screen.dart';

class BaseScreen extends StatefulWidget {
  const BaseScreen({super.key});

  @override
  State<BaseScreen> createState() => _BaseScreenState();
}

class _BaseScreenState extends State<BaseScreen> {

  int index = 0;
  final List<Widget> _widgetList = [
    const AvailableDeviceScreen(),
    const NotificationsScreen(),
    const SettingsScreen(),
  ];



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Patient Alert"),
      ),
      body: _widgetList[index],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              blurRadius: 20,
              color: Colors.black.withOpacity(.1),
            )
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 15),
            child: GNav(
              rippleColor: Colors.grey[300]!,
              hoverColor: Colors.grey[100]!,
              gap: 0,
              activeColor: Colors.black,
              iconSize: 24,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              duration: const Duration(milliseconds: 300),
              tabBackgroundColor: Colors.grey[100]!,
              color: Colors.black,
              tabs: const [
                GButton(
                  icon: Icons.bluetooth_connected,
                  text: 'Devices',
                ),
                GButton(
                  icon: Icons.notifications_active,
                  text: 'Notifications',
                ),

                GButton(
                  icon: Icons.info_outline,
                  text: 'About',
                ),
              ],
              selectedIndex: index,
              onTabChange: (value) {
                setState(() {
                  index = value;
                });
              },
            ),
          ),
        ),
      ),
    );
  }
}
