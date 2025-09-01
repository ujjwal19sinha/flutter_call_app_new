import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'call_screen.dart';

class IncomingCallScreen extends StatelessWidget {
  final String callerNumber;
  final String callerName;

  const IncomingCallScreen({
    super.key,
    required this.callerNumber,
    required this.callerName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Caller Info Section
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 90),

                // Profile Picture
                const CircleAvatar(
                  radius: 90,
                  backgroundImage: CachedNetworkImageProvider(
                    "https://randomuser.me/api/portraits/men/2.jpg",
                  ),
                ),

                const SizedBox(height: 30),

                // Show caller name or number
                Text(
                  callerName.isNotEmpty ? callerName : callerNumber,
                  style: const TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                // Subtitle line
                Text(
                  "Incoming call from $callerNumber",
                  style: const TextStyle(color: Colors.grey, fontSize: 20),
                ),
              ],
            ),

            // Action Buttons (Accept / Reject / ePay)
            Padding(
              padding: const EdgeInsets.only(bottom: 40),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildActionButton(
                    icon: Icons.call_end,
                    color: Colors.red,
                    label: "Reject",
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                  _buildActionButton(
                    icon: Icons.call,
                    color: Colors.green,
                    label: "Accept",
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CallScreen(
                            callerName: callerName,
                            callerNumber: callerNumber,
                          ),
                        ),
                      );
                    },
                  ),
                  _buildActionButton(
                    icon: Icons.payment,
                    color: Colors.blue,
                    label: "ePay",
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper for buttons (Accept / Reject / ePay)
  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            shape: const CircleBorder(),
            padding: const EdgeInsets.all(20),
            elevation: 4,
          ),
          onPressed: onPressed,
          child: Icon(icon, color: Colors.white, size: 32),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
