import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:twilio_voice/_internal/platform_interface/twilio_voice_platform_interface.dart';
import 'package:twilio_voice/twilio_voice.dart';
import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:flutter_callkit_incoming/entities/call_kit_params.dart';

class TwilioService {
  static final TwilioVoicePlatform _twilioVoice = TwilioVoice.instance;
  static String? _currentIdentity;

  /// Get current saved identity
  static Future<String?> getCurrentIdentity() async {
    if (_currentIdentity != null) return _currentIdentity;
    final prefs = await SharedPreferences.getInstance();
    _currentIdentity = prefs.getString("user_identity");
    return _currentIdentity;
  }

  /// Save current identity
  static Future<void> setCurrentIdentity(String identity) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("user_identity", identity);
    _currentIdentity = identity;
  }

  /// Get FCM Device Token
  static Future<String> getDeviceToken() async {
    try {
      String? token = await FirebaseMessaging.instance.getToken();
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

      return response.data["access_token"] ?? "error";
    } catch (e) {
      if (kDebugMode) print("Error in getAPIAccessToken: $e");
      return "error";
    }
  }

  /// Generate Twilio token from backend
  static Future<String> generateTwilioToken({
    required String apiAccessToken,
    required String identity,
  }) async {
    try {
      var dio = Dio();
      var headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiAccessToken',
      };

      var response = await dio.post(
        'https://dev-epaycop-api.azurewebsites.net/api/comm-server/token',
        data: jsonEncode({'username': identity}),
        options: Options(headers: headers),
      );

      if (response.statusCode == 200 && response.data != null) {
        final token = response.data['token'] as String?;
        return token ?? "error";
      }
      return "error";
    } catch (e) {
      if (kDebugMode) print("Error in generateTwilioToken: $e");
      return "error";
    }
  }

  /// Initialize Twilio SDK (app-to-app)
  static Future<void> init(String identity) async {
    _currentIdentity = identity;
    await setCurrentIdentity(identity);

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
    if (deviceToken.isEmpty && kDebugMode)
      print("Warning: Device token is empty");

    try {
      await _twilioVoice.setTokens(
          accessToken: token, deviceToken: deviceToken);
      if (kDebugMode) print("Twilio initialized (app-to-app calls)");
    } catch (e) {
      if (kDebugMode) print("Error initializing Twilio SDK: $e");
    }

    // Listen to incoming call events
    _twilioVoice.callEventsListener.listen((event) async {
      final type = event.runtimeType.toString();
      if (type == 'CallInvite') await showIncomingCall(event);
    });
  }

  /// Show incoming call UI
  static Future<void> showIncomingCall(dynamic event) async {
    final params = CallKitParams.fromJson({
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'nameCaller': 'Demo Caller',
      'appName': 'Flutter Call App',
      'handle': 'demo_handle',
      'type': 0,
      'duration': 30000,
      'textAccept': 'Accept',
      'textDecline': 'Decline',
      'textMissedCall': 'Missed call',
      'extra': {'callTime': DateTime.now().toIso8601String()},
      'android': {
        'isCustomNotification': true,
        'ringtonePath': 'system_ringtone_default'
      },
      'ios': {'supportsVideo': true},
    });

    await FlutterCallkitIncoming.showCallkitIncoming(params);
  }

  /// Make an outgoing app-to-app call
  static Future<void> makeCall(String to) async {
    try {
      final fromIdentity = await getCurrentIdentity() ?? "unknown_user";
      await _twilioVoice.call.place(
        from: "client:$fromIdentity",
        to: to.startsWith("client:") ? to : "client:$to",
      );
      if (kDebugMode) print("Calling $to from $fromIdentity...");
    } catch (e) {
      if (kDebugMode) print("Error in makeCall: $e");
    }
  }
}
