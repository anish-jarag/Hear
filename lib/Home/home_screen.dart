import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../Login Signup/Screen/AccountManagementScreen.dart';
import '../Login Signup/Screen/BluetoothSettingsScreen.dart';
import 'Sound_settings/sound_settings.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool isRecording = false;
  bool isModelLoaded = false;
  bool isSmartWatchConnected = false;
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  late Interpreter _interpreter;

  final StreamController<Uint8List> _audioStreamController = StreamController<Uint8List>();
  late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  @override
  void dispose() {
    _recorder.closeRecorder(); // Close the recorder session
    _audioStreamController.close(); // Close the stream controller
    _interpreter.close(); // Close the TFLite interpreter
    super.dispose();
  }

  Future<void> _initialize() async {
    await _initRecorder();
    await _loadModel();
    await _initializeNotifications();
    _checkSmartWatchConnection();
  }

  void _checkSmartWatchConnection() {
    // Replace this logic with actual smartwatch connection check
    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        isSmartWatchConnected = true; // Change this dynamically
      });
    });
  }

  Future<void> _initRecorder() async {
    await _recorder.openRecorder();
  }

  Future<void> _loadModel() async {
    try {
      print("Loading model...");
      _interpreter = await Interpreter.fromAsset('models/Sound_Recognition.tflite');
      print("Model loaded successfully");
      setState(() {
        isModelLoaded = true;
      });
    } catch (e, stacktrace) {
      print("Error loading model: $e");
      print("Stacktrace: $stacktrace");
      setState(() {
        isModelLoaded = false;
      });
    }
  }

  Future<void> _initializeNotifications() async {
    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');
    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  Future<void> _requestPermission() async {
    final status = await Permission.microphone.request();

    if (status.isGranted) {
      print("Microphone permission granted");
    } else if (status.isDenied) {
      print("Microphone permission denied");
    } else if (status.isPermanentlyDenied) {
      openAppSettings();
    }
  }

  Future<void> _startRecording() async {
    if (!isModelLoaded) {
      print("Model is not loaded yet.");
      return;
    }

    await _requestPermission();

    if (await Permission.microphone.isGranted) {
      setState(() {
        isRecording = true;
      });

      // Show notification when recording starts
      _showNotification("Recording Started", "Your app is running in the background");

      // Start recording and stream data to the StreamController
      await _recorder.startRecorder(
        codec: Codec.pcm16, // PCM codec for raw audio
        sampleRate: 16000,  // Match your model's sample rate
        numChannels: 1,     // Mono audio
        toStream: _audioStreamController.sink, // Stream audio data
      );

      // Listen to the audio stream
      _audioStreamController.stream.listen((audioChunk) {
        if (isModelLoaded) { // Ensure the model is loaded before processing
          _processAudioChunk(audioChunk);
        } else {
          print("Model is not loaded yet. Skipping audio chunk processing.");
        }
      });
    }
  }

  Future<void> _stopRecording() async {
    await _recorder.stopRecorder();
    setState(() {
      isRecording = false;
    });
    print("Recording stopped.");
  }

  void _processAudioChunk(Uint8List audioChunk) async {
    if (!isModelLoaded || _interpreter == null) {
      print("Interpreter is not initialized.");
      return;
    }

    try {
      // Preprocess audio data
      var inputTensor = _preprocessAudio(audioChunk);

      // Prepare output tensor
      var outputTensor = List<double>.filled(10, 0.0).reshape([1, 10]); // Adjust output size based on your model

      // Run inference
      _interpreter!.run(inputTensor, outputTensor);

      // Ensure outputTensor is of type List<List<double>>
      List<List<double>> typedOutputTensor = outputTensor.cast<List<double>>();

      // Handle the prediction
      _handlePrediction(typedOutputTensor);
    } catch (e) {
      print("Error processing audio chunk: $e");
    }
  }

  List<List<double>> _preprocessAudio(Uint8List audioChunk) {
    // Convert Uint8List to List<double> and normalize
    List<double> normalizedAudio = audioChunk.map((e) => e / 255.0).toList();

    // Reshape to match the model's input shape (e.g., [1, audioLength])
    return [normalizedAudio];
  }

  void _handlePrediction(List<List<double>> prediction) {
    // Example: print prediction or trigger notifications/vibrations
    print("Prediction: $prediction");
  }

  Future<void> _showNotification(String title, String body) async {
    const AndroidNotificationDetails androidNotificationDetails =
    AndroidNotificationDetails(
      'your_channel_id',
      'your_channel_name',
      channelDescription: 'your_channel_description',
      importance: Importance.high,
      priority: Priority.high,
    );
    const NotificationDetails notificationDetails =
    NotificationDetails(android: androidNotificationDetails);

    await flutterLocalNotificationsPlugin.show(
      0,
      title,
      body,
      notificationDetails,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // AppBar Row
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _appBarIconButton(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const SoundSettingsScreen(),
                          ),
                        );
                      },
                      icon: const Icon(
                        Icons.speaker,
                        size: 30,
                        color: Colors.blue,
                      ),
                    ),
                    _appBarIconButton(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => BluetoothSettingsScreen(),
                          ),
                        );
                      },
                      icon: Icon(
                        Icons.bluetooth,
                        size: 30,
                        color: isSmartWatchConnected ? Colors.blue : Colors.grey,
                      ),
                    ),
                    _appBarIconButton(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) =>
                            const AccountManagementScreen(),
                          ),
                        );
                      },
                      icon: const Icon(
                        Icons.grid_view_rounded,
                        size: 30,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              _recordButton(),
              const SizedBox(height: 20),
              Center(
                child: Text(isRecording ? "Listening" : "Start Listening"),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _recordButton() {
    return Center(
      child: GestureDetector(
        onTap: () {
          if (isRecording) {
            _stopRecording();
          } else {
            _startRecording();
          }
        },
        child: Container(
          width: 180,
          height: 180,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isRecording ? Colors.red : Colors.blue,
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 10,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Icon(
            isRecording ? Icons.stop : Icons.mic,
            color: Colors.white,
            size: 50,
          ),
        ),
      ),
    );
  }

  // AppBar Icon Button
  Widget _appBarIconButton({required VoidCallback onTap, required Icon icon}) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: icon,
      ),
    );
  }
}
