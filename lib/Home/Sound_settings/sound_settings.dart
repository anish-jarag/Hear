import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SoundSettingsScreen extends StatefulWidget {
  const SoundSettingsScreen({super.key});

  @override
  _SoundSettingsScreenState createState() => _SoundSettingsScreenState();
}

class _SoundSettingsScreenState extends State<SoundSettingsScreen> {
  // Variables for each sound option
  final List<String> sounds = [
    "Infant Crying",
    "Dog Barking",
    "Crack Sound",
    "Fire alarm",
    "Gunshot",
    "Car horn",
    "Name",
  ];

  late List<bool> selected;

  late Future<void> _loadSettingsFuture;

  @override
  void initState() {
    super.initState();
    selected = List.filled(sounds.length, false);
    _loadSettingsFuture = _loadSettings(); // Load settings on initialization
  }

  // Load the saved preferences for the sound settings
  Future<void> _loadSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    for (int i = 0; i < sounds.length; i++) {
      setState(() {
        selected[i] = prefs.getBool(sounds[i]) ?? false;
      });
    }
  }

  // Save preferences whenever a toggle switch is changed
  Future<void> _saveSetting(int index, bool value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(sounds[index], value); // Save the state for specific sound
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.blue),
        title: const Text(
          'Sound Settings',
          style: TextStyle(
            color: Colors.blue,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
      ),
      body: FutureBuilder(
        future: _loadSettingsFuture, // Load preferences before building UI
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                const Text(
                  "Select the sounds you will like notifications for:",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  "Toggle sounds",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 35),
                Expanded(
                  child: ListView.builder(
                    itemCount: sounds.length,
                    itemBuilder: (context, index) {
                      return SwitchListTile(
                        title: Text(sounds[index]),
                        value: selected[index],
                        onChanged: (bool value) {
                          setState(() {
                            selected[index] = value;
                          });
                          _saveSetting(index, value); // Save the state for specific sound
                        },
                        secondary: Icon(
                          _getIconForSound(sounds[index]),
                          color: selected[index] ? Colors.blue : Colors.grey,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  IconData _getIconForSound(String sound) {
    switch (sound) {
      case "Infant Crying":
        return Icons.child_care;
      case "Dog Barking":
        return Icons.pets;
      case "Crack Sound":
        return Icons.construction;
      case "Fire alarm":
        return Icons.fireplace;
      case "Gunshot":
        return Icons.gps_fixed;
      case "Car horn":
        return Icons.directions_car;
      case "Name":
        return Icons.badge;
      default:
        return Icons.help;
    }
  }
}
