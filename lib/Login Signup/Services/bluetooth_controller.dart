import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

class BluetoothController extends ChangeNotifier {
  bool isBluetoothOn = false;
  bool isScanning = false;
  List<ScanResult> scanResults = [];
  List<BluetoothDevice> connectedDevices = [];

  BluetoothController() {
    initializeBluetooth();
  }

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

  /// Request necessary permissions
  Future<bool> _requestPermissions() async {
    final status = await [
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();

    return status[Permission.bluetooth]!.isGranted &&
           status[Permission.bluetoothScan]!.isGranted &&
           status[Permission.bluetoothConnect]!.isGranted &&
           status[Permission.location]!.isGranted;
  }

  /// Start scanning for nearby Bluetooth devices
  Future<void> startScan() async {
    if (!await _requestPermissions()) {
      print("Bluetooth permissions not granted");
      return;
    }

    scanResults.clear(); // Clear previous scan results
    isScanning = true;
    notifyListeners();

    FlutterBluePlus.startScan(timeout: const Duration(seconds: 10)); // Set timeout to 10 seconds

    FlutterBluePlus.scanResults.listen((results) {
      scanResults = results;
      notifyListeners();
    }).onDone(() {
      stopScan();
    });
  }

  /// Stop scanning for devices
  void stopScan() {
    FlutterBluePlus.stopScan();
    isScanning = false;
    notifyListeners();
  }

  /// Connect to a selected Bluetooth device
  Future<void> connectToDevice(BluetoothDevice device, BuildContext context) async {
    if (connectedDevices.contains(device)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Already connected to ${device.name}")),
      );
      return;
    }

    try {
      await device.connect();
      connectedDevices = await FlutterBluePlus.connectedDevices;
      notifyListeners();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Connected to ${device.name}")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to connect to ${device.name}: $e")),
      );
    }
  }

  /// Disconnect from a Bluetooth device
  Future<void> disconnectFromDevice(BluetoothDevice device, BuildContext context) async {
    try {
      await device.disconnect();
      connectedDevices = await FlutterBluePlus.connectedDevices;
      notifyListeners();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Disconnected from ${device.name}")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to disconnect from ${device.name}: $e")),
      );
    }
  }

  /// Toggle Bluetooth On/Off (Only works on Android)
  Future<void> turnBluetoothOn() async {
    await FlutterBluePlus.turnOn();
    isBluetoothOn = true;
    notifyListeners();
  }

  Future<void> turnBluetoothOff() async {
    await FlutterBluePlus.turnOff();
    isBluetoothOn = false;
    stopScan(); // Stop scanning when Bluetooth is turned off
    notifyListeners();
  }
}