import 'package:twilio_voice/_internal/platform_interface/twilio_voice_platform_interface.dart';
import 'package:twilio_voice/twilio_voice.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class CallService {
  static final CallService _instance = CallService._internal();
  factory CallService() => _instance;
  CallService._internal();

  Future<void> init(String accessToken) async {
    final fcmToken = await FirebaseMessaging.instance.getToken();
    if (fcmToken == null) return;
    await TwilioVoice.instance.set(accessToken, fcmToken);
  }

  Future<void> makeCall(String to, {required String from}) async {
    await TwilioVoice.instance.call;
  }

  Future<void> hangUp() async {
    await TwilioVoice.instance.hangup();
  }

  Stream<CallEvent>? get callEvents => TwilioVoice.instance.callEvents;

  static void showincoming(CallEvent event) {}
}

extension on TwilioVoicePlatform {
  Stream<CallEvent>? get callEvents => null;

  Future<void> set(String accessToken, String fcmToken) async {}
  
  Future<void> hangup() async {}
}
