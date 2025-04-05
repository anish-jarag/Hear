import 'package:flutter/material.dart';
import '../Services/bluetooth_controller.dart';

class BluetoothSettingsUI extends StatelessWidget {
  final BluetoothController bluetoothController;

  const BluetoothSettingsUI({Key? key, required this.bluetoothController}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bluetooth toggle status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Bluetooth", style: TextStyle(fontSize: 18)),
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
          const SizedBox(height: 20),
          // Connected devices section
          const Text("Connected Devices", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          if (bluetoothController.connectedDevices.isNotEmpty)
            ...bluetoothController.connectedDevices.map((device) {
              return ListTile(
                leading: const Icon(Icons.bluetooth_connected),
                title: Text(device.platformName.isNotEmpty ? device.platformName : "Unknown Device"),
                // subtitle: Text(device.id.toString()),
                trailing: ElevatedButton(
                  onPressed: () {
                    bluetoothController.disconnectFromDevice(device, context);
                  },
                  child: const Text("Disconnect"),
                ),
              );
            }).toList()
          else
            const Text("No devices connected", style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 20),
          // Nearby devices section
          const Text("Nearby Devices", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          if (bluetoothController.isScanning)
            const Center(child: CircularProgressIndicator())
          else
            ElevatedButton(
              onPressed: bluetoothController.startScan,
              child: const Text("Start Scanning"),
            ),
          const SizedBox(height: 10),
          if (bluetoothController.scanResults.isNotEmpty)
            Expanded(
              child: ListView.builder(
                itemCount: bluetoothController.scanResults.length,
                itemBuilder: (context, index) {
                  final result = bluetoothController.scanResults[index];
                  return ListTile(
                    leading: const Icon(Icons.bluetooth),
                    title: Text(result.device.platformName.isNotEmpty ? result.device.platformName : "Incompatible Device"),
                    // subtitle: Text(result.device.id.toString()),
                    trailing: ElevatedButton(
                      onPressed: () {
                        bluetoothController.connectToDevice(result.device, context);
                      },
                      child: const Text("Connect"),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
