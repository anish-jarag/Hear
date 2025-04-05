import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:vibration/vibration.dart';

import '../Login Signup/Screen/AccountManagementScreen.dart';
import '../Login Signup/Screen/BluetoothSettingsScreen.dart';
import '../Login Signup/Services/NotificationService.dart';
import '../Login Signup/Services/bluetooth_controller_provider.dart';
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
  late final NotificationService _notificationService;

  final StreamController<Uint8List> _audioStreamController = StreamController<Uint8List>();
  late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  @override
  void dispose() {
    _recorder.closeRecorder();
    _audioStreamController.close();
    _interpreter.close();
    super.dispose();
  }

  Future<void> _initialize() async {
    _notificationService = NotificationService();

    await _initRecorder();
    await _loadModel();
    await _initializeNotifications();
    await _notificationService.initialize();

    _setupBluetoothConnectionListener();
  }

  void _setupBluetoothConnectionListener() {
    final bluetoothController = ref.read(bluetoothControllerProvider.notifier);

    bluetoothController.onDeviceConnected = (device) async {
      final bluetoothController = ref.read(bluetoothControllerProvider.notifier);
      bluetoothController.connectedDevices = await FlutterBluePlus.connectedDevices;

      final devices = bluetoothController.connectedDevices;

      if (devices.isNotEmpty) {
        sendToWatch(devices.first);
      } else {
        print("❌ No connected smartwatch found");
      }
    };
  }

  void _sendTestNotification() {
    _showNotification("Test Alert", "This is a manual test notification.");
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

      _showNotification("Recording Started", "Your app is running in the background");

      await _recorder.startRecorder(
        codec: Codec.pcm16,
        sampleRate: 16000,
        numChannels: 1,
        toStream: _audioStreamController.sink,
      );

      _audioStreamController.stream.listen((audioChunk) {
        if (isModelLoaded) {
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
      var inputTensor = _preprocessAudio(audioChunk);
      var outputTensor = List<double>.filled(10, 0.0).reshape([1, 10]);

      _interpreter.run(inputTensor, outputTensor);
      List<List<double>> typedOutputTensor = outputTensor.cast<List<double>>();
      _handlePrediction(typedOutputTensor);
    } catch (e) {
      print("Error processing audio chunk: $e");
    }
  }

  List<List<double>> _preprocessAudio(Uint8List audioChunk) {
    List<double> normalizedAudio = audioChunk.map((e) => e / 255.0).toList();
    return [normalizedAudio];
  }

  void _handlePrediction(List<List<double>> prediction) {
    print("Prediction: $prediction");
  }

  Future<void> _showNotification(String title, String body) async {
    const AndroidNotificationDetails androidNotificationDetails = AndroidNotificationDetails(
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

  Future<void> sendToWatch(BluetoothDevice device) async {
    try {
      final services = await device.discoverServices();
      for (var service in services) {
        for (var char in service.characteristics) {
          if (char.properties.write) {
            await char.write(utf8.encode("Hello Watch!"), withoutResponse: true);
            print("✅ Message sent to watch via ${char.uuid}");
            return;
          }
        }
      }
      print("❌ No writable characteristic found");
    } catch (e) {
      print("❌ Error sending to watch: $e");
    }
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
                            builder: (context) => const AccountManagementScreen(),
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
              ElevatedButton(
                onPressed: () async {
                  _notificationService.showNotification("HearMate", "🔔 Hello from HearMate");
                  if (await Vibration.hasVibrator() ?? false) {
                  Vibration.vibrate(duration: 100);  // 100ms vibration
                  }
                },
                child: const Text("Send Test Notification to Smartwatch Local"),
              ),

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
