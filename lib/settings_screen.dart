import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "About",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 35
            ),
          ),
          SizedBox(height: 20,),
          Text(
            "This app is built for continuous monitoring of patients whose vitals like blood pressure, heart rate tend to get in critical region for organ failure and death. It is solely made for dengue patient's continuous monitoring and notification for doctors about the condition of a critical patient.",
            style: TextStyle(
                fontWeight: FontWeight.normal,
                fontSize: 18
            ),
            textAlign: TextAlign.justify,
          ),
        ],
      ),
    );
  }
}
