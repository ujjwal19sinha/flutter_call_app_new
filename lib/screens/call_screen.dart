import 'package:flutter/material.dart';
import 'dart:math';

class CallScreen extends StatefulWidget {
  final String callerName;
  final String callerNumber;

  const CallScreen({
    super.key,
    required this.callerName,
    required this.callerNumber,
  });

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  bool isMuted = false;
  bool isSpeakerOn = false;
  bool isOnHold = false;
  bool showKeypad = false; // Keypad toggle
  String dialedNumber = ""; // Dialed number store karega

  // Random highlight effect for buttons (future use)
  Color _randomHighlight() {
    final random = Random();
    return Colors.white.withOpacity(0.5 + random.nextDouble() * 0.5);
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Main Call Screen
            Visibility(
              visible: !showKeypad,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(height: 50),

                  // Caller Info Section
                  Column(
                    children: [
                      const CircleAvatar(
                        radius: 60,
                        backgroundImage: NetworkImage(
                          "https://randomuser.me/api/portraits/men/2.jpg",
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        widget.callerName.isNotEmpty
                            ? widget.callerName
                            : widget.callerNumber,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        widget.callerNumber,
                        style: const TextStyle(
                            color: Colors.grey, fontSize: 18),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        "00:25",
                        style: TextStyle(
                            color: Colors.white70, fontSize: 16),
                      ),
                    ],
                  ),

                  // Control Buttons Section
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 40, vertical: 20),
                    child: GridView.count(
                      shrinkWrap: true,
                      crossAxisCount: 3,
                      crossAxisSpacing: 20,
                      mainAxisSpacing: 20,
                      children: [
                        _buildControlButton(
                          icon: isMuted ? Icons.mic_off : Icons.mic,
                          label: "Mute",
                          onPressed: () {
                            setState(() {
                              isMuted = !isMuted;
                            });
                          },
                        ),
                        _buildControlButton(
                          icon: Icons.dialpad,
                          label: "Keypad",
                          onPressed: () {
                            setState(() {
                              showKeypad = true;
                            });
                          },
                        ),
                        _buildControlButton(
                          icon: isSpeakerOn
                              ? Icons.volume_up
                              : Icons.volume_mute,
                          label: "Speaker",
                          onPressed: () {
                            setState(() {
                              isSpeakerOn = !isSpeakerOn;
                            });
                          },
                        ),
                        _buildControlButton(
                          icon: Icons.person_add,
                          label: "Add Call",
                          onPressed: () {},
                        ),
                        _buildControlButton(
                          icon: Icons.pause,
                          label: "Hold",
                          onPressed: () {
                            setState(() {
                              isOnHold = !isOnHold;
                            });
                          },
                        ),
                        _buildControlButton(
                          icon: Icons.record_voice_over,
                          label: "Record",
                          onPressed: () {},
                        ),
                      ],
                    ),
                  ),

                  // End Call Button Section
                  Padding(
                    padding: const EdgeInsets.only(bottom: 30),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        shape: const CircleBorder(),
                        padding: const EdgeInsets.all(20),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Icon(Icons.call_end,
                          color: Colors.white, size: 32),
                    ),
                  ),
                ],
              ),
            ),

            // Keypad Screen
            Visibility(
              visible: showKeypad,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  height: screenHeight * 0.6, // 60% of screen height
                  color: Colors.black,
                  child: Column(
                    children: [
                      const SizedBox(height: 10),

                      // Dialed number display line
                      Container(
                        padding: const EdgeInsets.all(12),
                        alignment: Alignment.center,
                        child: Text(
                          dialedNumber,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold),
                        ),
                      ),

                      const SizedBox(height: 10),

                      // Keypad Buttons
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _buildKeypadButton("1"),
                                _buildKeypadButton("2"),
                                _buildKeypadButton("3"),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _buildKeypadButton("4"),
                                _buildKeypadButton("5"),
                                _buildKeypadButton("6"),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _buildKeypadButton("7"),
                                _buildKeypadButton("8"),
                                _buildKeypadButton("9"),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _buildKeypadButton("*"),
                                _buildKeypadButton("0"),
                                _buildKeypadButton("#"),
                              ],
                            ),
                          ],
                        ),
                      ),


                      // Back Button Section (properly visible now)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 20, top: 10),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[800],
                            shape: const CircleBorder(),
                            padding: const EdgeInsets.all(20),
                          ),
                          onPressed: () {
                            setState(() {
                              showKeypad = false; // Back to call screen
                            });
                          },
                          child: const Icon(Icons.arrow_back,
                              color: Colors.white, size: 28),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Control Buttons Widget (Mute, Speaker, Hold etc.)
  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTapUp: (_) {
        onPressed();
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey[800],
            ),
            padding: const EdgeInsets.all(20),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
        ],
      ),
    );
  }

  // Keypad Button Widget
  Widget _buildKeypadButton(String text) {
    return GestureDetector(
      onTap: () {
        setState(() {
          dialedNumber += text; // Pressed number show in display
        });
      },
      child: Container(
        margin: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.grey[900],
        ),
        child: Center(
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
