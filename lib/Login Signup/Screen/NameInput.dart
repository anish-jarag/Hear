import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hear_aid/Login%20Signup/Screen/sound_on_start.dart';

class NameInputScreen extends StatefulWidget {
  const NameInputScreen({super.key});

  @override
  _NameInputScreenState createState() => _NameInputScreenState();
}

class _NameInputScreenState extends State<NameInputScreen> {
  final TextEditingController _nameController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        iconTheme: IconThemeData(color: Colors.grey[800]), // Dark icon color
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              "Welcome to Hear Aid",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              "Your deaf assistant.\nWhat should I call you?",
              style: TextStyle(
                fontSize: 18,
                color: Colors.black54,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            TextField(
              controller: _nameController,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.grey[100],
                labelText: "Enter your name",
                labelStyle: TextStyle(
                  color: Colors.grey[700],
                  fontSize: 16,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity, // Button takes full width
              child: ElevatedButton(
                onPressed: () async {
                  String name = _nameController.text.trim();

                  if (name.isNotEmpty) {
                    try {
                      // Get current user
                      User? user = FirebaseAuth.instance.currentUser;

                      if (user != null) {
                        // Store data in Firestore
                        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
                          'name': name,
                          'email': user.email,
                          'uid': user.uid,
                          'timestamp': FieldValue.serverTimestamp(),
                        });

                        // Navigate to the next screen
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (context) => const SoundSelectorScreen(),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("User not authenticated.")),
                        );
                      }
                    } catch (e) {
                      // Handle errors, if any
                      print("Error uploading data: $e");
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Failed to save data. Please try again.")),
                      );
                    }
                  } else {
                    // Show error if name is empty
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Please enter your name.")),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  backgroundColor: Colors.blueAccent,
                  shadowColor: Colors.blueAccent.withOpacity(0.3),
                  elevation: 5,
                ),
                child: const Text(
                  "Submit",
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
