import 'package:flutter/material.dart';
import '../Services/bluetooth_controller.dart';

class BluetoothSettingsScreen extends StatefulWidget {
  @override
  State<BluetoothSettingsScreen> createState() => _BluetoothSettingsScreenState();
}

class _BluetoothSettingsScreenState extends State<BluetoothSettingsScreen> {
  final BluetoothController _bluetoothController = BluetoothController();

  @override
  void initState() {
    super.initState();
    _bluetoothController.initializeBluetooth();
    _bluetoothController.addListener(() {
      setState(() {});
    });
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
      body: Padding(
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
                  value: _bluetoothController.isBluetoothOn,
                  onChanged: (value) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Bluetooth toggle must be done via system settings.")),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Connected devices section
            const Text("Connected Devices", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            if (_bluetoothController.connectedDevices.isNotEmpty)
              ..._bluetoothController.connectedDevices.map((device) {
                return ListTile(
                  leading: const Icon(Icons.bluetooth_connected),
                  title: Text(device.platformName.isNotEmpty ? device.platformName : "Unknown Device"),
                  subtitle: Text(device.remoteId.toString()),
                  trailing: ElevatedButton(
                    onPressed: () {
                      _bluetoothController.disconnectFromDevice(device, context);
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
            if (_bluetoothController.isScanning)
              const Center(child: CircularProgressIndicator())
            else
              ElevatedButton(
                onPressed: _bluetoothController.startScan,
                child: const Text("Start Scanning"),
              ),
            const SizedBox(height: 10),
            if (_bluetoothController.scanResults.isNotEmpty)
              Expanded(
                child: ListView.builder(
                  itemCount: _bluetoothController.scanResults.length,
                  itemBuilder: (context, index) {
                    final result = _bluetoothController.scanResults[index];
                    return ListTile(
                      leading: const Icon(Icons.bluetooth),
                      title: Text(result.device.platformName.isNotEmpty ? result.device.platformName : "Unknown Device"),
                      subtitle: Text(result.device.remoteId.toString()),
                      trailing: ElevatedButton(
                        onPressed: () {
                          _bluetoothController.connectToDevice(result.device, context);
                        },
                        child: const Text("Connect"),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}