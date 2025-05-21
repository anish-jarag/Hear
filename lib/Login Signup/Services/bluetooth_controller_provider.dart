import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'bluetooth_controller.dart';

final bluetoothControllerProvider =
ChangeNotifierProvider<BluetoothController>((ref) => BluetoothController());