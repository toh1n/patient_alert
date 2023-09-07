import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bluetooth_serial_ble/flutter_bluetooth_serial_ble.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:patient_alert/data/utils.dart';
import 'package:permission_handler/permission_handler.dart';

class AvailableDeviceScreen extends StatefulWidget {
  const AvailableDeviceScreen({super.key});

  @override
  State<AvailableDeviceScreen> createState() => _AvailableDeviceScreenState();
}

class _AvailableDeviceScreenState extends State<AvailableDeviceScreen> {
  BluetoothConnection? connection;
  final FlutterBluetoothSerial _bluetoothSerial =
      FlutterBluetoothSerial.instance;
  BluetoothState _bluetoothState = BluetoothState.UNKNOWN;
  StreamSubscription<BluetoothDiscoveryResult>? _streamSubscription;
  List<DeviceWithAvailability> devices = [];
  List<BluetoothDiscoveryResult> results = [];
  String connectedDeviceAddress = "";
  bool isBluetoothEnabled = false;
  late Timer _timer;

  static const platform = MethodChannel("com.example.patient_alert/bluetooth");

  Future<String> _getStoredMessage() async {
    String storedMessage;

    try {
      final result = await platform.invokeMethod('getStoredMessage');
      storedMessage = result;
      connectedDeviceAddress = storedMessage.toString();
      setState(() {});
    } on PlatformException catch (e) {
      storedMessage = "Failed to get stored message: '${e.message}'.";
    }
    setState(() {});

    return storedMessage;
  }

  void _timerCallback(Timer timer) {
    setState(() {
      _getStoredMessage();
    });
  }

  void _startDiscovery() {
    _streamSubscription =
        FlutterBluetoothSerial.instance.startDiscovery().listen((r) {
      setState(() {
        final existingIndex = results.indexWhere(
            (element) => element.device.address == r.device.address);
        if (existingIndex >= 0) {
          results[existingIndex] = r;
        } else {
          results.add(r);
        }
      });
    });
    setState(() {});

    _streamSubscription!.onDone(() {
      // Setup a list of the bonded devices
    });
    FlutterBluetoothSerial.instance
        .getBondedDevices()
        .then((List<BluetoothDevice> bondedDevices) {
      setState(() {
        devices = bondedDevices
            .map(
              (device) => DeviceWithAvailability(
                device,
                DeviceAvailability.yes,
              ),
            )
            .toList();
      });
    });
    setState(() {});
  }

  @override
  void initState() {
    super.initState();

    _getStoredMessage();
    _timer = Timer.periodic(const Duration(seconds: 1), _timerCallback);
    _bluetoothSerial.state.then((state) {
      setState(() {
        _bluetoothState = state;
      });
    });
    _bluetoothSerial.onStateChanged().listen((BluetoothState state) {
      _bluetoothState = state;
      if (_bluetoothState.isEnabled) {
        isBluetoothEnabled = true;
      } else {
        isBluetoothEnabled = false;
      }
      setState(() {});
    });

    _startDiscovery();
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  Future<void> _startService(String address) async {
    try {
          await platform.invokeMethod('startService', {"address": address});
    } catch (e) {
      Fluttertoast.showToast(msg: "Failed to start service");
    }
  }

  _requestForNotifications() {
    Permission.notification.isDenied.then((value) => {
          if (value) {Permission.notification.request()}
        });
  }

  @override
  Widget build(BuildContext context) {
    return Visibility(
      visible: _bluetoothState.isEnabled == true,
      replacement: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text("Turn on Bluetooth"),
            const SizedBox(height: 20,),
            ElevatedButton(
                onPressed: () {
                  _bluetoothSerial.openSettings();
                },
                child: const Text("Open Settings")),
          ],
        ),
      ),
      child: Visibility(
        visible: devices.isNotEmpty == true,
        replacement: Center(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    "No paired devices found",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueGrey,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      "Tap 'Pair devices' to pair a device.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      "If you already paired a device from settings, tap 'Refresh'.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontStyle: FontStyle.italic,
                        color: Colors.lightGreen,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      "If the device is still not showing, ensure all necessary permissions are enabled.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.normal,
                        color: Colors.redAccent,
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  Card(
                    child: ListTile(
                      onTap: () {
                        Fluttertoast.showToast(msg: "Refreshing...");
                        _startDiscovery();
                        setState(() {});
                      },
                      trailing: const Icon(Icons.navigate_next_outlined),
                      leading: const Icon(Icons.refresh),
                      subtitle: const Text(
                        "Tap to Refresh",
                        textAlign: TextAlign.justify,
                        style: TextStyle(
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      title: const Text("Refresh"),
                    ),
                  ),
                  Card(
                    child: ListTile(
                      onTap: () {
                        _bluetoothSerial.openSettings();
                      },
                      trailing: const Icon(Icons.navigate_next_outlined),
                      leading: const Icon(Icons.bluetooth),
                      subtitle: const Text(
                        "Tap to pair devices from System Settings",
                        textAlign: TextAlign.justify,
                        style: TextStyle(
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      title: const Text("Pair Devices"),
                    ),
                  ),
                  Card(
                    child: ListTile(
                      onTap: () async {
                        try {
                          await platform.invokeMethod("openAppSettings");
                        } catch (e) {
                          Fluttertoast.showToast(msg: "Failed to launch settings. Please set permission manually.");
                        }
                      },
                      trailing: const Icon(Icons.navigate_next_outlined),
                      leading: const Icon(Icons.settings),
                      subtitle: const Text(
                        "Tap to set permissions from System Settings",
                        textAlign: TextAlign.justify,
                        style: TextStyle(
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      title: const Text("Set Permissions"),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        child: ListView.builder(
          itemCount: devices.length,
          itemBuilder: (context, index) {
            bool isConnected = connectedDeviceAddress == devices[index].device.address;

            return Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 4, 16, 4),
              child: Card(
                elevation: 4,
                color: isConnected ? Colors.green : Colors.white, // change color based on connection status
                child: SizedBox(
                  height: 72,
                  child: ListTile(
                    onTap: () {
                      // Logic for requesting notifications and starting service
                      _requestForNotifications();
                      _startService(devices[index].device.address).then((value) {
                        // After successfully connecting, set the connected device address
                        setState(() {
                          connectedDeviceAddress = devices[index].device.address;
                        });
                      });
                    },
                    leading: const Icon(Icons.devices),
                    title: Text("${devices[index].device.name}"),
                    subtitle: Text(devices[index].device.address),
                    trailing: const Icon(Icons.bluetooth_connected),
                  ),
                ),
              ),
            );
          },
        ),

      ),
    );
  }
}
