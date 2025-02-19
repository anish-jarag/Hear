import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BluetoothController extends ChangeNotifier {
  bool isBluetoothOn = false;
  bool isScanning = false;
  List<ScanResult> scanResults = [];
  List<BluetoothDevice> connectedDevices = [];

  Future<void> initializeBluetooth() async {
    final adapterState = await FlutterBluePlus.adapterState.first;
    isBluetoothOn = adapterState == BluetoothAdapterState.on;
    notifyListeners();

    FlutterBluePlus.adapterState.listen((state) {
      isBluetoothOn = state == BluetoothAdapterState.on;
      notifyListeners();
    });

    connectedDevices = await FlutterBluePlus.connectedDevices;
    notifyListeners();
  }

  void startScan() {
    isScanning = true;
    scanResults.clear();
    notifyListeners();

    FlutterBluePlus.startScan(timeout: const Duration(seconds: 5));

    FlutterBluePlus.scanResults.listen((results) {
      scanResults = results;
      notifyListeners();
    }).onDone(() {
      isScanning = false;
      notifyListeners();
    });
  }

  void stopScan() {
    FlutterBluePlus.stopScan();
    isScanning = false;
    notifyListeners();
  }

  Future<void> connectToDevice(BluetoothDevice device, BuildContext context) async {
    try {
      await device.connect();
      connectedDevices = await FlutterBluePlus.connectedDevices;
      notifyListeners();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Connected to \${device.platformName}")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to connect to \${device.platformName}: \$e")),
      );
    }
  }

  Future<void> disconnectFromDevice(BluetoothDevice device, BuildContext context) async {
    try {
      await device.disconnect();
      connectedDevices = await FlutterBluePlus.connectedDevices;
      notifyListeners();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Disconnected from \${device.platformName}")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to disconnect from \${device.platformName}: \$e")),
      );
    }
  }
}
