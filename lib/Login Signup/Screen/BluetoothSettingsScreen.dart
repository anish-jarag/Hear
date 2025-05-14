import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import '../Services/bluetooth_controller.dart';
import 'bluetooth_settings_ui.dart';

class BluetoothSettingsScreen extends ConsumerStatefulWidget  {
  @override
  ConsumerState<BluetoothSettingsScreen> createState() => _BluetoothSettingsScreenState();}

class _BluetoothSettingsScreenState extends ConsumerState<BluetoothSettingsScreen> {
  final BluetoothController _bluetoothController = BluetoothController();

  @override
  void initState() {
    super.initState();
    _requestPermissions();
    _bluetoothController.addListener(() {
      setState(() {});
    });
  }

  Future<void> _requestPermissions() async {
    await [
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();
  }

  @override
  void dispose() {
    _bluetoothController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bluetooth Settings'),
      ),
      body: BluetoothSettingsUI(bluetoothController: _bluetoothController),
    );
  }
}