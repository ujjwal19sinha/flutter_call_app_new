import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:call_notification/services/call_service.dart';

/// This function will handle background/terminated incoming messages
Future<void> firebaseMessagingHandler(RemoteMessage message) async {
  if (message.data["type"] == "INCOMING_CALL") {
    final accessToken = message.data["accessToken"];
    final from = message.data["from"];

    print("Incoming call from $from");

    // Initialize Twilio with the token received from server
    await CallService().init(accessToken);
  }
}
