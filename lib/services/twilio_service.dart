import 'dart:convert';

//import 'package:call_notification/services/call_service.dart';
//import 'package:call_notification/services/token_service.dart';
import 'package:flutter/foundation.dart';
import 'package:twilio_voice/_internal/platform_interface/twilio_voice_platform_interface.dart';
import 'package:twilio_voice/twilio_voice.dart';
// Removed invalid import: 'package:twilio_voice/events/call_invite.dart';
import 'package:dio/dio.dart';

class TwilioService {
  static final TwilioVoicePlatform _twilioVoice = TwilioVoicePlatform.instance;

  static Future<String> getAPIAccessToken() async {
    try {
      // Get Api Credentials from Flutter Secure Storage
      String clientId = "nkhaiubVTdOLGd4oEVHH4N007zqxPy0Ko1yLI3kN";
      String secretId = "jto8hBONRzjDz43TjK6dZcIBkFhrEozWU4dm3P8kYUGDL8iEskn1PX5dyE7jfqcfSGWdSDqAEshRNkWs0ykeu0jO8V1PXeyyRXYdFwpIIywHn6yU5PkW88aSwE7CeivZ";

      var headers = {
        'Content-Type': 'application/x-www-form-urlencoded',
        'Authorization':
            'Basic ${base64Encode(utf8.encode('${clientId}:${secretId}'))}'
      };
      var dio = Dio();
      var response = await dio.post(
        'https://https://dev-epaycop-api.azurewebsites.net/o/token/', // Replace with your endpoint
        data: {
          'grant_type': 'client_credentials',
        },
        options: Options(
          headers: headers,
        ),
      );
      String access_token = response.data["access_token"];
      print("access_token = $access_token");

      return access_token;
    } catch (e) {
      return "error";
    }
  }


  static Future<String> generateTwilioToken({required String apiAccessToken, String identity = "demo@xpectro.co"}) async {
  try {
    var dio = Dio();
    var headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $apiAccessToken',
    };

    var response = await dio.post(
      'https://https://dev-epaycop-api.azurewebsites.net/api/comm-server/token', // Replace with your actual endpoint
      data: jsonEncode({'identity': identity}),
      options: Options(headers: headers),
    );

    if (response.statusCode == 200 && response.data != null) {
      String twilioToken = response.data['twilio_token'];
      return twilioToken;
    } else {
      return "error";
    }
  } catch (e) {
    return "error";
  }

  }

  static Future<void> init(String identity) async {
    // Token fetch kar lo
    final apiAccessToken = await getAPIAccessToken();
    final token = await generateTwilioToken(apiAccessToken: apiAccessToken, identity: identity);

    // Register user with Twilio
    await _twilioVoice.setTokens(accessToken: token);

    // Listen for call events
    _twilioVoice.callEventsListener.listen((CallEvent event) {
      if (kDebugMode) {
        if (event.runtimeType.toString() == 'CallInvite') {
          print("Incoming call");
        }
      }
      //CallService.showincoming(event);
      if (event.runtimeType.toString() == 'CancelledCallInvite') {
        print("Call cancelled by caller");
      } else if (event.runtimeType.toString() == 'CallConnected') {
        print("Call connected");
      } else if (event.runtimeType.toString() == 'CallDisconnected') {
        print("Call disconnected");
      }
    });
  }
}
