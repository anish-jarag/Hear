// lib/screens/bluetooth_settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../bluetooth/bluetooth_provider.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BluetoothSettingsScreen extends ConsumerWidget {
  const BluetoothSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(bluetoothProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Bluetooth Settings')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ElevatedButton.icon(
              onPressed: controller.isScanning ? null : controller.startScan,
              icon: const Icon(Icons.bluetooth_searching),
              label: const Text("Scan for Devices"),
            ),
            const SizedBox(height: 20),

            if (controller.isScanning) ...[
              const Center(child: CircularProgressIndicator()),
              const SizedBox(height: 10),
              const Center(child: Text("Scanning...")),
            ] else if (controller.scanResults.isEmpty) ...[
              const Center(child: Text("No devices found. Please scan.")),
            ] else ...[
              const Text("Devices Found:", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Expanded(
                child: ListView.builder(
                  itemCount: controller.scanResults.length,
                  itemBuilder: (context, index) {
                    final result = controller.scanResults[index];
                    final device = result.device;
                    final deviceName = result.advertisementData.advName.isNotEmpty
                      ? result.advertisementData.advName
                      : (result.device.platformName.isNotEmpty
                          ? result.device.platformName
                          : "Unknown Device");

                    return Card(
                      child: ListTile(
                        title: Text(deviceName),
                        subtitle: Text("ID: ${result.device.remoteId.str}"),
                        trailing: ElevatedButton(
                          onPressed: () => controller.connectToDevice(device, context),
                          child: const Text("Connect"),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
