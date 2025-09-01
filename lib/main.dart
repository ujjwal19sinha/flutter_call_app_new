import 'package:flutter/material.dart';
import 'package:flutter_callkit_incoming/entities/android_params.dart';
import 'package:flutter_callkit_incoming/entities/call_event.dart';
import 'package:flutter_callkit_incoming/entities/call_kit_params.dart';
import 'package:flutter_callkit_incoming/entities/notification_params.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:permission_handler/permission_handler.dart';
import 'services/call_service.dart';
import 'services/twilio_service.dart';
// Screens
import 'screens/call_screen.dart';
import 'screens/missed_call_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await requestPermissions();

  // Initialize Twilio Service with your identity (user id)
  await TwilioService.init("userB");

  // Setup CallKit listener
  _setupCallkitListener();

  runApp(const MyApp());
}

// Request notification and phone permissions
Future<void> requestPermissions() async {
  await Permission.notification.request();
  await Permission.phone.request();
}

// Global navigator key for navigation from listener
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

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

            // Show incoming call notification manually
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
              child: const Text("Show Incoming"),
            ),
            const SizedBox(height: 20),

            // Show missed call
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

            // Outgoing call via Twilio
            ElevatedButton(
              onPressed: () async {
                await CallService().makeCall(
                  "client:userB",
                ); // replace with real Twilio identity
              },
              child: const Text("Outgoing Call"),
            ),
          ],
        ),
      ),
    );
  }
}

// ========================
// CallKit listener
// ========================
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
      case Event.actionCallIncoming:
        print("Incoming call notification from $callerName ($callerNumber)");
        break;

      case Event.actionCallAccept:
        print("Call accepted from $callerName ($callerNumber)");
        _navigateToCallScreen(callerName, callerNumber);
        break;

      case Event.actionCallDecline:
        print("Call declined from $callerName ($callerNumber)");
        _navigateToMissedCall(callerName, callerNumber);
        break;

      case Event.actionCallEnded:
        print("Call ended with $callerName ($callerNumber)");
        CallService().hangUp(); // hang up active Twilio call
        _popCurrentScreen();
        break;

      default:
        print("Other CallKit Event: ${event.event}");
    }
  });
}

// ========================
// Navigation helpers
// ========================

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
