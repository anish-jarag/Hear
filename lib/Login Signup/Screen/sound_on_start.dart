import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../Home/home_screen.dart';

class SoundSelectorScreen extends StatefulWidget {
  const SoundSelectorScreen({Key? key}) : super(key: key);

  @override
  State<SoundSelectorScreen> createState() => _SoundSelectorScreenState();
}

class _SoundSelectorScreenState extends State<SoundSelectorScreen> {
  final List<String> sounds = [
    "Infant Crying",
    "Crack Sound",
    "Fire alarm",
    "Gunshot",
    "Car horn",
    "Name",
  ];

  final List<bool> selected = List.filled(6, false);

  Future<void> _saveSelections() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    for (int i = 0; i < sounds.length; i++) {
      await prefs.setBool(sounds[i], selected[i]);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              const Text(
                "Tell me\nwhat you wanna hear",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "So I can show you what you want to hear.",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 40),
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 20,
                    crossAxisSpacing: 20,
                    childAspectRatio: 1.0,
                  ),
                  itemCount: sounds.length,
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          selected[index] = !selected[index];
                        });
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: selected[index] ? Colors.blue : Colors.white,
                          border: Border.all(
                            color: selected[index] ? Colors.blue : Colors.grey,
                            width: 1.5,
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _getIconForSound(sounds[index]),
                              color: selected[index] ? Colors.white : Colors.black,
                              size: 28,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              sounds[index],
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color:
                                selected[index] ? Colors.white : Colors.black,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  await _saveSelections(); // Save preferences
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (context) => const HomeScreen(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  "Done",
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getIconForSound(String sound) {
    switch (sound) {
      case "Infant Crying":
        return Icons.child_care;
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
