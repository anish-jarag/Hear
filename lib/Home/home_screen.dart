import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibration/vibration.dart';

import '../Login Signup/Screen/AccountManagementScreen.dart';
import '../Login Signup/Screen/BluetoothSettingsScreen.dart';
import '../Login Signup/Services/NotificationService.dart';
import '../Login Signup/Services/bluetooth_controller_provider.dart';
import 'Sound_settings/sound_settings.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool isRecording = false;
  bool isSmartWatchConnected = false;

  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  late final NotificationService _notificationService;
  final StreamController<Uint8List> _audioStreamController = StreamController<Uint8List>();
  late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

  String? _lastAlertLabel;
  DateTime? _lastAlertTime;
  static const Duration cooldownDuration = Duration(seconds: 10);

  WebSocketChannel? _channel;

  final Map<String, String> labelToToggleMap = {
    "Dog Barking": "Dog Barking",
    "Crying Baby": "Infant Crying",
    "Gunshot": "Gunshot",
    "Car Horn": "Car horn",
    "Glass Breaking": "Crack Sound",
    "Siren": "Fire alarm",
    "Name": "Name",
  };

  @override
  void initState() {
    super.initState();
    _initialize();
    _connectToWebSocket();
  }

  @override
  void dispose() {
    _recorder.closeRecorder();
    _audioStreamController.close();
    _channel?.sink.close();
    super.dispose();
  }

  Future<void> _initialize() async {
    _notificationService = NotificationService();

    await _initRecorder();
    await _initializeNotifications();
    await _notificationService.initialize();
    await Permission.notification.request();

    _setupBluetoothConnectionListener();
  }

  void _setupBluetoothConnectionListener() {
    final bluetoothController = ref.read(bluetoothControllerProvider.notifier);

    bluetoothController.onDeviceConnected = (device) async {
      bluetoothController.connectedDevices = await FlutterBluePlus.connectedDevices;
      final devices = bluetoothController.connectedDevices;

      if (devices.isNotEmpty) {
        await sendToWatch(devices.first, "Smartwatch Connected");
        setState(() {
          isSmartWatchConnected = true;
        });
      } else {
        setState(() {
          isSmartWatchConnected = false;
        });
      }
    };
  }

  Future<void> _initRecorder() async {
    await _recorder.openRecorder();
  }

  Future<void> _initializeNotifications() async {
    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

    final androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    final initSettings = InitializationSettings(android: androidSettings);

    await flutterLocalNotificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        debugPrint("🔔 Notification tapped: ${details.payload}");
      },
    );
  }

  Future<void> _requestPermission() async {
    final status = await Permission.microphone.request();

    if (status.isPermanentlyDenied) {
      openAppSettings();
    } else if (!status.isGranted) {
      print("Microphone permission denied");
    }
  }

  Future<void> _startRecording() async {
    await _requestPermission();

    if (await Permission.microphone.isGranted) {
      setState(() => isRecording = true);

      _showNotification("Recording Started", "Your app is running in the background");

      await _recorder.startRecorder(
        codec: Codec.pcm16,
        sampleRate: 44100,
        numChannels: 1,
        toStream: _audioStreamController.sink,
      );

      List<int> audioBuffer = [];
      const int bufferThreshold = 88200; // 1 second at 44100Hz * 2 bytes/sample

      _audioStreamController.stream.listen((audioChunk) {
        audioBuffer.addAll(audioChunk);

        while (audioBuffer.length >= bufferThreshold) {
          final fullChunk = Uint8List.fromList(audioBuffer.sublist(0, bufferThreshold));
          audioBuffer = audioBuffer.sublist(bufferThreshold); // Keep remainder

          if (_channel != null) {
            print("🎧 Sending buffered chunk of ${fullChunk.length} bytes");
            _channel!.sink.add(fullChunk);
          }
        }
      });

    }
  }

  Future<void> _stopRecording() async {
    await _recorder.stopRecorder();
    setState(() => isRecording = false);
    print("⛔ Recording stopped.");
  }

  Future<void> _showNotification(String title, String body) async {
    const androidDetails = AndroidNotificationDetails(
      'hearmate_channel',
      'HearMate Sound Alerts',
      channelDescription: 'Alerts for important environmental sounds',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      ticker: 'HearMate Alert',
    );

    const notificationDetails = NotificationDetails(android: androidDetails);

    try {
      await flutterLocalNotificationsPlugin.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000, // unique ID
        title,
        body,
        notificationDetails,
      );
      print("🔔 Notification shown: $title");
    } catch (e) {
      print("❌ Notification error: $e");
    }
  }

  void _connectToWebSocket() {
    _channel = WebSocketChannel.connect(
      Uri.parse('ws://172.20.10.4:8000/ws/audio'),
    );

    _channel!.stream.listen(
          (message) {
        _handleWebSocketMessage(message);
      },
      onError: (error) {
        print("❌ WebSocket error: $error");
      },
      onDone: () {
        print("🔌 WebSocket closed");
      },
    );
  }

  String _normalizeLabel(String rawLabel) {
    rawLabel = rawLabel.toLowerCase();
    if (rawLabel.contains("dog")) return "Dog Barking";
    if (rawLabel.contains("baby") || rawLabel.contains("cry")) return "Crying Baby";
    if (rawLabel.contains("gunshot")) return "Gunshot";
    if (rawLabel.contains("car") || rawLabel.contains("horn")) return "Car Horn";
    if (rawLabel.contains("glass") || rawLabel.contains("break")) return "Glass Breaking";
    if (rawLabel.contains("siren") || rawLabel.contains("alarm")) return "Siren";
    if (rawLabel.contains("speech") || rawLabel.contains("name") || rawLabel.contains("talk"))
      return "Name";
    return rawLabel; // fallback
  }

  Future<void> _handleWebSocketMessage(String message) async {
    print("🎯 Raw prediction result: $message");

    try {
      final decoded = jsonDecode(message);

      if (decoded is List && decoded.isNotEmpty) {
        final label = decoded[0]['label'].toString();
        final confidence = double.tryParse(decoded[0]['confidence'].toString()) ?? 0.0;

        final normalizedLabel = _normalizeLabel(label);
        final now = DateTime.now();

        final isDuplicate = (_lastAlertLabel == normalizedLabel) &&
            (_lastAlertTime != null) &&
            (now.difference(_lastAlertTime!) < cooldownDuration);

        final prefs = await SharedPreferences.getInstance();
        final toggleLabel = labelToToggleMap[normalizedLabel];
        final isAllowed = toggleLabel != null && (prefs.getBool(toggleLabel) ?? false);

        print("📈 Raw Label: $label | Normalized: $normalizedLabel | Confidence: $confidence");
        print("🔍 Is allowed: $isAllowed for toggleLabel: $toggleLabel");

        if (isAllowed && !isDuplicate && confidence > 0.50) {
          print("✅ Threshold met. Triggering alert...");

          await _triggerAlert(normalizedLabel, confidence.toStringAsFixed(2));
          _lastAlertLabel = normalizedLabel;
          _lastAlertTime = now;

          if (await Vibration.hasVibrator() ?? false) {
            Vibration.vibrate(duration: 300);
            print("📳 Vibrated");
          }

          final devices = ref.read(bluetoothControllerProvider.notifier).connectedDevices;
          if (devices.isNotEmpty) {
            await sendToWatch(devices.first, normalizedLabel);
          }
        } else {
          print("⚠ Sound ignored (duplicate, disallowed, or low confidence)");
        }
      }
    } catch (e) {
      print("❌ Error decoding message: $e");
    }
  }


  Future<void> _triggerAlert(String label, String confidence) async {
    await _showNotification("Detected: $label", "Confidence: $confidence");

    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(duration: 300);
      print("📳 Phone vibrated");
    }

    final devices = ref.read(bluetoothControllerProvider.notifier).connectedDevices;
    if (devices.isNotEmpty) {
      await sendToWatch(devices.first, label);
    }
  }

  Future<void> sendToWatch(BluetoothDevice device, String label) async {
    try {
      final services = await device.discoverServices();
      for (var service in services) {
        for (var char in service.characteristics) {
          if (char.properties.write) {
            final message = "🔔 $label Detected!";
            await char.write(utf8.encode(message), withoutResponse: true);
            print("✅ Sent to watch via ${char.uuid}: $message");
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
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const SoundSettingsScreen()),
                      ),
                      icon: const Icon(Icons.speaker, size: 30, color: Colors.blue),
                    ),
                    _appBarIconButton(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => BluetoothSettingsScreen()),
                      ),
                      icon: Icon(
                        Icons.bluetooth,
                        size: 30,
                        color: isSmartWatchConnected ? Colors.blue : Colors.grey,
                      ),
                    ),
                    _appBarIconButton(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const AccountManagementScreen()),
                      ),
                      icon: const Icon(Icons.grid_view_rounded, size: 30, color: Colors.blue),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              _recordButton(),
              const SizedBox(height: 20),
              Center(
                child: Text(
                  isRecording ? "Listening..." : "Start Listening",
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const Spacer(),
              // ElevatedButton(
              //   onPressed: () {
              //     _showNotification("Test Notification", "This is a test.");
              //     Vibration.vibrate(duration: 300);
              //   },
              //   child: const Text("🔔 Test Notification"),
              // ),

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
          isRecording ? _stopRecording() : _startRecording();
        },
        child: Container(
          width: 180,
          height: 180,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isRecording ? Colors.red : Colors.blue,
            boxShadow: const [
              BoxShadow(color: Colors.black12, blurRadius: 10, spreadRadius: 5),
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
