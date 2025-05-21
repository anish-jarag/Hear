import 'package:flutter/material.dart';
import '../Services/bluetooth_controller.dart';

class BluetoothSettingsUI extends StatelessWidget {
  final BluetoothController bluetoothController;

  const BluetoothSettingsUI({Key? key, required this.bluetoothController}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // Bluetooth Toggle
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Bluetooth", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Switch(
                value: bluetoothController.isBluetoothOn,
                onChanged: (value) {
                  if (value) {
                    bluetoothController.turnBluetoothOn();
                  } else {
                    bluetoothController.turnBluetoothOff();
                  }
                },
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Connected Devices
          Text("Connected Devices", style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (bluetoothController.connectedDevices.isNotEmpty)
            Column(
              children: bluetoothController.connectedDevices.map((device) {
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  child: ListTile(
                    leading: const Icon(Icons.bluetooth_connected),
                    title: Text(device.platformName.isNotEmpty ? device.platformName : "Unknown Device"),
                    trailing: ElevatedButton(
                      onPressed: () {
                        bluetoothController.disconnectFromDevice(device, context);
                      },
                      child: const Text("Disconnect"),
                    ),
                  ),
                );
              }).toList(),
            )
          else
            const Text("No devices connected", style: TextStyle(color: Colors.grey)),

          const SizedBox(height: 24),

          // Scan Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Nearby Devices", style: Theme.of(context).textTheme.titleMedium),
              ElevatedButton.icon(
                icon: const Icon(Icons.search),
                label: const Text("Scan"),
                onPressed: bluetoothController.isScanning ? null : bluetoothController.startScan,
              ),
            ],
          ),

          const SizedBox(height: 8),

          if (bluetoothController.isScanning)
            const Center(child: Padding(
              padding: EdgeInsets.symmetric(vertical: 12.0),
              child: CircularProgressIndicator(),
            ))
          else if (bluetoothController.scanResults.isNotEmpty)
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: bluetoothController.scanResults.length,
              itemBuilder: (context, index) {
                final result = bluetoothController.scanResults[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  child: ListTile(
                    leading: const Icon(Icons.bluetooth),
                    title: Text(result.device.platformName.isNotEmpty ? result.device.platformName : "Incompatible Device"),
                    subtitle: Text("RSSI: ${result.rssi}"),
                    trailing: ElevatedButton(
                      onPressed: () {
                        bluetoothController.connectToDevice(result.device, context);
                      },
                      child: const Text("Connect"),
                    ),
                  ),
                );
              },
            )
          else
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Text("No devices found yet.", style: TextStyle(color: Colors.grey)),
            ),
        ],
      ),
    );
  }
}