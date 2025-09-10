import 'package:flutter/material.dart';
import '../services/call_service.dart';
import '../main.dart';
import 'call_screen.dart';

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

                  // Outgoing call via Twilio
                  await CallService().makeCall("client:$toUser", from: '');

                  // Navigate to call screen
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
      appBar: AppBar(title: const Text("Home")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
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
