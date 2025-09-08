import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_callkit_incoming/entities/call_kit_params.dart';
import 'package:twilio_voice/_internal/platform_interface/twilio_voice_platform_interface.dart';
import 'package:twilio_voice/twilio_voice.dart';
import 'package:dio/dio.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class TwilioService {
  static final TwilioVoicePlatform _twilioVoice = TwilioVoicePlatform.instance;

  /// Get FCM Device Token (for push notification)

  static Future<String> getDeviceToken() async {
    try {
      FirebaseMessaging messaging = FirebaseMessaging.instance;
      String? token = await messaging.getToken();
      if (token != null) {
        if (kDebugMode) print("Device Token: $token");
        return token;
      }
    } catch (e) {
      if (kDebugMode) print("Failed to get device token: $e");
    }
    return "";
  }

  /// Get OAuth2 API access token from backend
  static Future<String> getAPIAccessToken() async {
    try {
      // Get Api Credentials from Flutter Secure Storage
      String clientId = "nkhaiubVTdOLGd4oEVHH4N007zqxPy0Ko1yLI3kN";
      String secretId =
          "jto8hBONRzjDz43TjK6dZcIBkFhrEozWU4dm3P8kYUGDL8iEskn1PX5dyE7jfqcfSGWdSDqAEshRNkWs0ykeu0jO8V1PXeyyRXYdFwpIIywHn6yU5PkW88aSwE7CeivZ";

      var headers = {
        'Content-Type': 'application/x-www-form-urlencoded',
        'Authorization':
            'Basic ${base64Encode(utf8.encode('$clientId:$secretId'))}'
      };

      var dio = Dio();
      var response = await dio.post(
        'https://dev-epaycop-api.azurewebsites.net/o/token/',
        data: {'grant_type': 'client_credentials'},
        options: Options(headers: headers),
      );

      if (kDebugMode) print("API Access Token Response: ${response.data}");
      return response.data["access_token"];
    } catch (e) {
      if (kDebugMode) print("Error in getAPIAccessToken: $e");
      return "error";
    }
  }


  /// Generate Twilio token from backend for a given identity
  
  static Future<String> generateTwilioToken({
    required String apiAccessToken,
    String identity = "demo@xpectro.co",
  }) async {
    try {
      var dio = Dio();
      var headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiAccessToken',
      };

      var response = await dio.post(
        'https://dev-epaycop-api.azurewebsites.net/api/comm-server/token',
        data: jsonEncode({'identity': identity}),
        options: Options(headers: headers),
      );

      if (kDebugMode) print("Generate Twilio Token Response: ${response.data}");

      if (response.statusCode == 200 && response.data != null) {
      String twilioToken = response.data['twilio_token'];
      return twilioToken;
      } else {
        return "error";
      }
    } catch (e) {
      if (kDebugMode) print("Error in generateTwilioToken: $e");
      return "error";
    }
  }


  /// Initialize Twilio SDK
  
  static Future<void> init(String identity) async {
    final apiAccessToken = await getAPIAccessToken();
    if (apiAccessToken == "error") {
      if (kDebugMode) print("Failed to get API Access Token");
      return;
    }

    final token = await generateTwilioToken(
        apiAccessToken: apiAccessToken, identity: identity);

    if (token == "error") {
      if (kDebugMode) print("Failed to generate Twilio Token");
      return;
    }

    final deviceToken = await getDeviceToken();
    if (deviceToken.isEmpty) {
      if (kDebugMode) print("Warning: Device token is empty");
    }

    // Register Twilio SDK with tokens
    await _twilioVoice.setTokens(
      accessToken: token,
      deviceToken: deviceToken,
    );

    /// ------------------------------
    /// Twilio Call Events Listener
    /// ------------------------------
    _twilioVoice.callEventsListener.listen((event) async {
      if (kDebugMode) {
        print("RAW Twilio Event: ${event.runtimeType}");
        print("Event details: $event");
      }

      final type = event.runtimeType.toString();

      if (type == 'CallInvite') {
        if (kDebugMode) print("Incoming call detected");
        await showIncomingCall(event);
      } else if (type == 'CancelledCallInvite') {
        if (kDebugMode) print("Call cancelled by caller");
      } else if (type == 'CallConnected') {
        if (kDebugMode) print("Call connected");
      } else if (type == 'CallDisconnected') {
        if (kDebugMode) print("Call disconnected");
      }
    });
  }

  /// ------------------------------
  /// Show Incoming Call UI (CallKit)
  /// ------------------------------
  static Future<void> showIncomingCall(dynamic event) async {
    final params = CallKitParams.fromJson({
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'nameCaller': 'Demo Caller',
      'appName': 'Flutter Call App',
      'avatar': 'https://i.pravatar.cc/100',
      'handle': 'demo_handle',
      'type': 0,
      'duration': 30000,
      'textAccept': 'Accept',
      'textDecline': 'Decline',
      'textMissedCall': 'Missed call',
      'textCallback': 'Call back',
      'extra': {
        'userId': '123456',
        'callTime': DateTime.now().toIso8601String(),
      },
      'headers': {'apiKey': 'Abc@123'},
      'android': {
        'isCustomNotification': true,
        'isShowLogo': false,
        'ringtonePath': 'system_ringtone_default',
        'backgroundColor': '#0955fa',
        'backgroundUrl': 'https://i.pravatar.cc/500',
        'actionColor': '#4CAF50',
        'incomingCallNotificationChannelName': 'Incoming Calls',
      },
      'ios': {
        'iconName': 'CallKitLogo',
        'handleType': 'generic',
        'supportsVideo': true,
        'maximumCallGroups': 2,
        'maximumCallsPerCallGroup': 1,
        'audioSessionMode': 'default',
        'audioSessionActive': true,
        'audioSessionPreferredSampleRate': 44100.0,
        'audioSessionPreferredIOBufferDuration': 0.005,
        'supportsDTMF': true,
        'supportsHolding': true,
        'supportsGrouping': false,
        'supportsUngrouping': false,
        'ringtonePath': 'system_ringtone_default',
      },
    });

    await FlutterCallkitIncoming.showCallkitIncoming(params);
  }

  /// Make an outgoing call
  static Future<void> makeCall(String to,
      {String from = "demo@xpectro.co"}) async {
    try {
      await TwilioVoice.instance.call.place(
        from: from, //current user identity
        to: to, //to
      );
      if (kDebugMode) print("Calling $to...");
    } catch (e) {
      if (kDebugMode) print("Error in makeCall: $e");
    }
  }
}
