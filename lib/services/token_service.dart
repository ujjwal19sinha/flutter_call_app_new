import 'dart:convert';
import 'package:http/http.dart' as http;

class TokenService {
  // Backend server base URL
  static const String baseUrl = "http://localhost:3000"; 
  // Use http://10.0.2.2:3000 for Android emulator
  // Use your machine IP for real device testing

static Future<String?> fetchAccessToken(String identity, {required String identify}) async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/token?identity=$identity"),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data["token"];
      } else {
        print("Failed to fetch token: ${response.body}");
        return null;
      }
    } catch (e) {
      print("Error fetching token: $e");
      return null;
    }
  }
}