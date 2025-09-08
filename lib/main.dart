import 'package:flutter/material.dart';
import 'package:flutter_callkit_incoming/entities/android_params.dart';
import 'package:flutter_callkit_incoming/entities/call_kit_params.dart';
import 'package:flutter_callkit_incoming/entities/notification_params.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'services/call_service.dart';
import 'services/twilio_service.dart';

// Screens
import 'screens/call_screen.dart';
import 'screens/missed_call_screen.dart';
import 'screens/incomingcallscreen.dart';

// Firebase Background Handler

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  if (message.data['type'] == 'twilio_call') {
    print("Background FCM: Incoming Twilio call");
    await TwilioService.showIncomingCall(message.data);
  }
}

//  Main Function

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Register background FCM handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  await requestPermissions();

  // Identity of this device (change to "userB" on second device)
  const String currentIdentity = "userA";
  await TwilioService.init(currentIdentity);

  // Setup CallKit event listener
  _setupCallkitListener();

  runApp(const MyApp());
}

// Request notification and call-related permissions

Future<void> requestPermissions() async {
  await Permission.notification.request();
  await Permission.phone.request();
  await Permission.microphone.request();
  await Permission.bluetooth.request(); // Needed for Android 12/13+
}

// Global navigator key for navigation inside listener callbacks

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// MyApp

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      home: const HomeScreen(),
    );
  }
}

// HomeScreen with test buttons

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Call Notification")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 20),

            // Test: Show manual incoming call
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

            // Test: Show missed call notification
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

            // Outgoing call via Twilio (works on two devices)
            ElevatedButton(
              onPressed: () async {
                await CallService().makeCall("client:userB");

                // Navigate to call screen for caller immediately
                if (navigatorKey.currentContext != null) {
                  Navigator.of(navigatorKey.currentContext!).push(
                    MaterialPageRoute(
                      builder: (_) => const CallScreen(
                        callerName: "Calling userB",
                        callerNumber: "client:userB",
                      ),
                    ),
                  );
                }
              },
              child: const Text("Outgoing Call (to userB)"),
            ),
          ],
        ),
      ),
    );
  }
}

// CallKit Listener
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

// Navigation Helpers

void _navigateToCallScreen(String callerName, String callerNumber) {
  if (navigatorKey.currentContext != null) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.of(navigatorKey.currentContext!).push(
        MaterialPageRoute(
          builder: (_) =>
              CallScreen(callerName: callerName, callerNumber: callerNumber),
        ),
      );
    });
  }
}

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

void _popCurrentScreen() {
  if (navigatorKey.currentContext != null &&
      Navigator.canPop(navigatorKey.currentContext!)) {
    Navigator.pop(navigatorKey.currentContext!);
  }
}
