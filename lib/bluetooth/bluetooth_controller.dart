import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

class BluetoothController extends ChangeNotifier {
  bool isBluetoothOn = false;
  bool isScanning = false;
  List<ScanResult> scanResults = [];
  List<BluetoothDevice> connectedDevices = [];

  BluetoothCharacteristic? writeCharacteristic;
  BluetoothCharacteristic? notifyCharacteristic;

  BluetoothController() {
    _initializeBluetooth();
  }

  /// Initializes Bluetooth status and discovers already connected devices
  Future<void> _initializeBluetooth() async {
    final adapterState = await FlutterBluePlus.adapterState.first;
    isBluetoothOn = adapterState == BluetoothAdapterState.on;
    notifyListeners();

    FlutterBluePlus.adapterState.listen((state) {
      isBluetoothOn = state == BluetoothAdapterState.on;
      notifyListeners();
    });

    connectedDevices = await FlutterBluePlus.connectedDevices;
    for (var device in connectedDevices) {
      writeCharacteristic = await _findWritableCharacteristic(device);
      notifyCharacteristic = await _findNotifiableCharacteristic(device);
      if (notifyCharacteristic != null) {
        await listenToNotifications(notifyCharacteristic!);
      }
      _monitorConnectionState(device);
    }

    notifyListeners();
  }

  /// Requests necessary permissions
  Future<bool> _requestPermissions() async {
    final statuses = await [
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();

    return statuses.values.every((status) => status.isGranted);
  }

  /// Starts scanning for BLE devices
  Future<void> startScan() async {
    if (!await _requestPermissions() || isScanning) return;

    scanResults.clear();
    isScanning = true;
    notifyListeners();

    FlutterBluePlus.startScan();

    FlutterBluePlus.scanResults.listen((results) {
      scanResults = results;
      notifyListeners();
    });

    Future.delayed(const Duration(seconds: 10), stopScan);
  }

  /// Stops scanning for BLE devices
  void stopScan() {
    FlutterBluePlus.stopScan();
    isScanning = false;
    notifyListeners();
  }

  /// Connects to a selected BLE device
  Future<void> connectToDevice(BluetoothDevice device, BuildContext context) async {
    if (connectedDevices.any((d) => d.remoteId == device.remoteId)) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Already connected to ${device.platformName}")));
      return;
    }

    try {
      await device.connect(timeout: const Duration(seconds: 15));
      connectedDevices.add(device);
      notifyListeners();

      writeCharacteristic = await _findWritableCharacteristic(device);
      notifyCharacteristic = await _findNotifiableCharacteristic(device);

      if (notifyCharacteristic != null) {
        await listenToNotifications(notifyCharacteristic!);
      }

      if (writeCharacteristic != null) {
        await writeCharacteristic!.write(utf8.encode("🔔 HearMate Connected!"), withoutResponse: true);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Message sent to ${device.platformName}")));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Connected but no write characteristic found")));
      }

      _monitorConnectionState(device);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Connection failed: $e")));
    }
  }

  /// Disconnects from a BLE device
  Future<void> disconnectFromDevice(BluetoothDevice device, BuildContext context) async {
    try {
      await device.disconnect();
      connectedDevices.removeWhere((d) => d.remoteId == device.remoteId);
      notifyListeners();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Disconnected from ${device.platformName}")));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to disconnect: $e")));
    }
  }

  /// Finds a writable characteristic on the device
  Future<BluetoothCharacteristic?> _findWritableCharacteristic(BluetoothDevice device) async {
    List<BluetoothService> services = await device.discoverServices();
    for (var service in services) {
      for (var characteristic in service.characteristics) {
        if (characteristic.properties.write) {
          return characteristic;
        }
      }
    }
    return null;
  }

  /// Finds a notifiable characteristic on the device
  Future<BluetoothCharacteristic?> _findNotifiableCharacteristic(BluetoothDevice device) async {
    List<BluetoothService> services = await device.discoverServices();
    for (var service in services) {
      for (var characteristic in service.characteristics) {
        if (characteristic.properties.notify) {
          return characteristic;
        }
      }
    }
    return null;
  }

  /// Starts listening to notifications from a characteristic
  Future<void> listenToNotifications(BluetoothCharacteristic characteristic) async {
    if (characteristic.properties.notify) {
      await characteristic.setNotifyValue(true);
      characteristic.lastValueStream.listen((value) {
        final data = utf8.decode(value);
        print("📥 Incoming Data: $data");
        // TODO: Add your data handling logic here
      });
    }
  }

  /// Monitors the connection state of a device and auto-cleans on disconnect
  void _monitorConnectionState(BluetoothDevice device) {
    device.connectionState.listen((state) {
      if (state == BluetoothConnectionState.disconnected) {
        print("🔌 Disconnected from ${device.platformName}");
        connectedDevices.removeWhere((d) => d.remoteId == device.remoteId);
        notifyListeners();
      }
    });
  }

  /// Public method to send custom message to connected device
  Future<void> sendToDevice(String message, BuildContext context) async {
    try {
      if (writeCharacteristic != null) {
        await writeCharacteristic!.write(utf8.encode(message), withoutResponse: true);
        print("✅ Sent: $message");
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("No writable characteristic available")));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to send: $e")));
    }
  }
}
