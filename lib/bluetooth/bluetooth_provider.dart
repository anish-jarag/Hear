// lib/bluetooth/bluetooth_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'bluetooth_controller.dart';

final bluetoothProvider = ChangeNotifierProvider<BluetoothController>(
  (ref) => BluetoothController(),
);
