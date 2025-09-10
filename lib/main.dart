import 'package:flutter/material.dart';
import 'package:flutter_callkit_incoming/entities/android_params.dart';
import 'package:flutter_callkit_incoming/entities/call_kit_params.dart';
import 'package:flutter_callkit_incoming/entities/notification_params.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'services/call_service.dart';
import 'services/twilio_service.dart';

import 'screens/call_screen.dart';
import 'screens/missed_call_screen.dart';
import 'screens/incomingcallscreen.dart';

// Background FCM handler
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  if (message.data['type'] == 'twilio_call') {
    print("Background FCM: Incoming Twilio call detected");
    await TwilioService.showIncomingCall(message.data);
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  await _requestPermissions();

  final prefs = await SharedPreferences.getInstance();
  final savedIdentity = prefs.getString("user_identity");

  if (savedIdentity != null && savedIdentity.isNotEmpty) {
    await TwilioService.init(savedIdentity);
    _setupCallkitListener();
    runApp(MyApp(initialScreen: const HomeScreen()));
  } else {
    runApp(MyApp(initialScreen: const InputScreen()));
  }
}

Future<void> _requestPermissions() async {
  await Permission.notification.request();
  await Permission.phone.request();
  await Permission.microphone.request();
  await Permission.bluetooth.request();
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class MyApp extends StatelessWidget {
  final Widget initialScreen;
  const MyApp({super.key, required this.initialScreen});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      home: initialScreen,
    );
  }
}

// Input screen for username
class InputScreen extends StatefulWidget {
  const InputScreen({super.key});
  @override
  State<InputScreen> createState() => _InputScreenState();
}

class _InputScreenState extends State<InputScreen> {
  final TextEditingController _controller = TextEditingController();

  Future<void> _saveIdentity() async {
    final username = _controller.text.trim();
    if (username.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("user_identity", username);

    await TwilioService.init(username);
    _setupCallkitListener();

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Enter Username")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: "Username",
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveIdentity,
              child: const Text("Continue"),
            ),
          ],
        ),
      ),
    );
  }
}

// Home screen with call actions
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> _showCallDialog(BuildContext context) async {
    final controller = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text("Enter Username to Call"),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: "e.g. userB",
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                final toUser = controller.text.trim();
                if (toUser.isNotEmpty) {
                  Navigator.pop(ctx);

                  // Outgoing call via TwilioService
                  await TwilioService.makeCall("client:$toUser");
                  print("Outgoing call triggered to $toUser");

                  if (navigatorKey.currentContext != null) {
                    Navigator.of(navigatorKey.currentContext!).push(
                      MaterialPageRoute(
                        builder: (_) => CallScreen(
                          callerName: "Calling $toUser",
                          callerNumber: "client:$toUser",
                        ),
                      ),
                    );
                  }
                }
              },
              child: const Text("Call"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Call Notification")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                CallKitParams params = CallKitParams(
                  id: "999",
                  nameCaller: "Xpectro Solution",
                  handle: "9876543210",
                  type: 0,
                  android: const AndroidParams(
                    isCustomNotification: true,
                    isShowLogo: false,
                    ringtonePath: "system_ringtone_default",
                    backgroundColor: "#0955fa",
                    backgroundUrl: "https://i.pravatar.cc/500",
                    actionColor: "#4CAF50",
                  ),
                );
                await FlutterCallkitIncoming.showCallkitIncoming(params);
              },
              child: const Text("Show Incoming (Test)"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                CallKitParams params = CallKitParams(
                  id: "123",
                  nameCaller: "Xpectro Solution",
                  handle: "9876543210",
                  type: 0,
                  extra: {"userId": "1234567"},
                  missedCallNotification: const NotificationParams(
                    showNotification: true,
                    isShowCallback: true,
                    subtitle: "Missed Call",
                    callbackText: "Call Back",
                  ),
                );
                await FlutterCallkitIncoming.showMissCallNotification(params);
              },
              child: const Text("Missed Call"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                await _showCallDialog(context);
              },
              child: const Text("Outgoing Call"),
            ),
          ],
        ),
      ),
    );
  }
}

// CallKit listener setup
void _setupCallkitListener() {
  FlutterCallkitIncoming.onEvent.listen((event) {
    if (event == null) return;

    final callerName =
        event.body?["nameCaller"]?.toString() ?? "Unknown Caller";
    final callerNumber = event.body?["handle"]?.toString() ?? "Unknown";

    print(
      "CallKit Event: ${event.event}, Caller: $callerName, Number: $callerNumber",
    );

    switch (event.event) {
      case 'ACTION_CALL_INCOMING':
        print("Incoming call from $callerName ($callerNumber)");
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (navigatorKey.currentContext != null) {
            Navigator.of(navigatorKey.currentContext!).push(
              MaterialPageRoute(
                builder: (_) => IncomingCallScreen(
                  callerName: callerName,
                  callerNumber: callerNumber,
                ),
              ),
            );
          }
        });
        break;

      case 'ACTION_CALL_ACCEPT':
        print("Call accepted: $callerName ($callerNumber)");
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (navigatorKey.currentContext != null) {
            Navigator.of(navigatorKey.currentContext!).push(
              MaterialPageRoute(
                builder: (_) => CallScreen(
                  callerName: callerName,
                  callerNumber: callerNumber,
                ),
              ),
            );
          }
        });
        break;

      case 'ACTION_CALL_DECLINE':
        print("Call declined: $callerName ($callerNumber)");
        _navigateToMissedCall(callerName, callerNumber);
        break;

      case 'ACTION_CALL_ENDED':
        print("Call ended with $callerName ($callerNumber)");
        CallService().hangUp();
        _popCurrentScreen();
        break;

      default:
        print("Other CallKit Event: ${event.event}");
    }
  });
}

// Navigate to missed call screen
void _navigateToMissedCall(String callerName, String callerNumber) {
  if (navigatorKey.currentContext != null) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.of(navigatorKey.currentContext!).push(
        MaterialPageRoute(
          builder: (_) => MissedCallScreen(
            callerName: callerName,
            callerNumber: callerNumber,
          ),
        ),
      );
    });
  }
}

// Pop current screen safely
void _popCurrentScreen() {
  if (navigatorKey.currentContext != null &&
      Navigator.canPop(navigatorKey.currentContext!)) {
    Navigator.pop(navigatorKey.currentContext!);
  }
}
