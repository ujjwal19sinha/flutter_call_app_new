import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/twilio_service.dart';

class IdentityScreen extends StatefulWidget {
  const IdentityScreen({super.key});

  @override
  State<IdentityScreen> createState() => _IdentityScreenState();
}

class _IdentityScreenState extends State<IdentityScreen> {
  final TextEditingController _controller = TextEditingController();

  Future<void> _saveIdentity() async {
    if (_controller.text.isNotEmpty) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString("identity", _controller.text.trim());

      // Init Twilio with entered identity
      await TwilioService.init(_controller.text.trim());

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, "/home");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Set Identity")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                labelText: "Enter your identity",
                hintText: "e.g. userA, userB, phone/email",
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
