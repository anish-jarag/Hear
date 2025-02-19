import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthMethod {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Sign Up User
  Future<String> signupUser({
    required String email,
    required String password,
    required String name,
  }) async {
    String res = "Some error occurred";
    try {
      // Check if inputs are not empty
      if (email.isNotEmpty && password.isNotEmpty && name.isNotEmpty) {
        // Register user in auth with email and password
        UserCredential cred = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );

        // Add user details to Firestore database
        await _firestore.collection("users").doc(cred.user!.uid).set({
          'name': name,
          'uid': cred.user!.uid,
          'email': email,
        });

        res = "success";  // Successfully signed up
      } else {
        res = "Please fill all the fields";  // Error for empty fields
      }
    } catch (err) {
      // Handle any error from Firebase
      res = err.toString();
    }
    return res;
  }

  // Log In User
  Future<String> loginUser({
    required String email,
    required String password,
  }) async {
    String res = "Some error occurred";
    try {
      // Check if inputs are not empty
      if (email.isNotEmpty && password.isNotEmpty) {
        // Logging in user with email and password
        await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );

        res = "success";  // Successfully logged in
      } else {
        res = "Please fill all the fields";  // Error for empty fields
      }
    } catch (err) {
      // Handle any error from Firebase
      res = err.toString();
    }
    return res;
  }

  // Sign Out User
  Future<void> signOut() async {
    try {
      await _auth.signOut();  // Sign out from Firebase Auth
    } catch (err) {
      print("Sign out error: $err");
    }
  }
}
