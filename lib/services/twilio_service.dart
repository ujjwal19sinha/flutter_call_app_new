import 'package:call_notification/screens/call_screen.dart';
import 'package:call_notification/services/call_service.dart';
import 'package:call_notification/services/token_service.dart';
import 'package:flutter/foundation.dart';
import 'package:twilio_voice/_internal/platform_interface/twilio_voice_platform_interface.dart';
import 'package:twilio_voice/twilio_voice.dart';

class TwilioService {
  static final TwilioVoicePlatform _twilioVoice = TwilioVoicePlatform.instance;

  static Future<void> init(String identity) async {
    // Token fetch kar lo
    final token = await TokenService.fetchAccessToken(identify: identity);

    // Register user with Twilio
    await _twilioVoice.setTokens(accessToken:token
    );

    // Listen for call events
    _twilioVoice.callEventsListener.listen((event) {
      if (event is CallEvent) {
        if (kDebugMode) {
          print("Incoming call from: ${event.from}");
        }
        CallService.showincoming(event);
      } else if (event is CancelledCallInvite) {
        print("Call cancelled by caller");
      } else if (event is CallConnected) {
        print("Call connected");
      } else if (event is CallDisconnected) {
        print("Call disconnected");
      }
    });
  }
}
