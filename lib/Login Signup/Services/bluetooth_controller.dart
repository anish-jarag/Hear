import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:hear_aid/Login Signup/Services/NotificationService.dart';

class BluetoothController extends ChangeNotifier {
  bool isBluetoothOn = false;
  bool isScanning = false;
  List<ScanResult> scanResults = [];
  List<BluetoothDevice> connectedDevices = [];

  // 🔌 Writable characteristic reference
  BluetoothCharacteristic? writeCharacteristic;

  Function(BluetoothDevice)? onDeviceConnected;

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

  Future<bool> _requestPermissions() async {
    final status = await [
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();

    return status[Permission.bluetooth]?.isGranted == true &&
        status[Permission.bluetoothScan]?.isGranted == true &&
        status[Permission.bluetoothConnect]?.isGranted == true &&
        status[Permission.location]?.isGranted == true;
  }

  Future<void> startScan() async {
    if (!await _requestPermissions()) {
      print("Bluetooth permissions not granted");
      return;
    }

    scanResults.clear();
    isScanning = true;
    notifyListeners();

    FlutterBluePlus.startScan(timeout: const Duration(seconds: 10));

    FlutterBluePlus.scanResults.listen((results) {
      scanResults = results;
      notifyListeners();
    }).onDone(() {
      stopScan();
    });
  }

  void stopScan() {
    FlutterBluePlus.stopScan();
    isScanning = false;
    notifyListeners();
  }

  Future<void> connectToDevice(BluetoothDevice device, BuildContext context) async {
    if (connectedDevices.any((d) => d.remoteId == device.remoteId)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Already connected to ${device.platformName}")),
      );
      return;
    }

    try {
      await device.connect();
      connectedDevices = await FlutterBluePlus.connectedDevices;
      notifyListeners();

      onDeviceConnected?.call(device);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Connected to ${device.platformName}")),
      );

      NotificationService().showNotification(
        "HearMate",
        "HearMate is now connected.",
      );


      // 🔍 Discover services and find write characteristic
      await discoverServices(device);

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to connect to ${device.platformName}: $e")),
      );
    }
  }

  Future<void> discoverServices(BluetoothDevice device) async {
    List<BluetoothService> services = await device.discoverServices();
    for (var service in services) {
      print("🔹 Service: ${service.uuid}");

      for (var characteristic in service.characteristics) {
        print("   ↪ Characteristic: ${characteristic.uuid}");
        print("     Properties: ${characteristic.properties}");

        if (characteristic.properties.write || characteristic.properties.writeWithoutResponse) {
          print("     ✨ This characteristic is writeable!");
          // you can keep a reference to this characteristic
        }
      }
    }
  }

  Future<void> sendToWatch(BluetoothDevice device) async {
    try {
      final services = await device.discoverServices();
      for (var service in services) {
        for (var char in service.characteristics) {
          if (char.properties.write) {
            await char.write(utf8.encode("🔔 Alert: Sound Detected!"), withoutResponse: true);
            print("✅ Message sent to watch via ${char.uuid}");
            return;
          }
        }
      }
      print("❌ No writable characteristic found");
    } catch (e) {
      print("❌ Error sending to watch: $e");
    }
  }


  Future<void> disconnectFromDevice(BluetoothDevice device, BuildContext context) async {
    try {
      await device.disconnect();
      connectedDevices = await FlutterBluePlus.connectedDevices;
      notifyListeners();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Disconnected from ${device.platformName}")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to disconnect: $e")),
      );
    }
  }

  Future<void> turnBluetoothOn() async {
    try {
      await FlutterBluePlus.turnOn();
      isBluetoothOn = true;
      notifyListeners();
    } catch (e) {
      print("Failed to turn on Bluetooth: $e");
    }
  }

  Future<void> turnBluetoothOff() async {
    try {
      await FlutterBluePlus.turnOff();
      isBluetoothOn = false;
      stopScan();
      notifyListeners();
    } catch (e) {
      print("Failed to turn off Bluetooth: $e");
    }
  }
}