import 'package:flutter_bluetooth_serial_ble/flutter_bluetooth_serial_ble.dart';

enum DeviceAvailability {
  maybe,
  no,
  yes,
}

class DeviceWithAvailability {
  BluetoothDevice device;
  DeviceAvailability availability;
  int? rssi;

  DeviceWithAvailability(this.device, this.availability, [this.rssi]);
}