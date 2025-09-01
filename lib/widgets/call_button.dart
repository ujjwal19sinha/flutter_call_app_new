import 'package:flutter/material.dart';
import 'package:flutter_callkit_incoming/entities/entities.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';

class CallButton extends StatelessWidget {
  final String callerId;
  final String callerName;
  final String phoneNumber;

  const CallButton({
    super.key,
    required this.callerId,
    required this.callerName,
    required this.phoneNumber,
  });

  Future<void> _startCall() async {
    CallKitParams params = CallKitParams(
      id: callerId,
      nameCaller: callerName,
      handle: phoneNumber,
      type: 0, // 0 = audio, 1 = video
      extra: {"userId": callerId},
    );
    await FlutterCallkitIncoming.startCall(params);
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: _startCall,
      icon: const Icon(Icons.phone),
      label: Text("Call $callerName"),
    );
  }
}
