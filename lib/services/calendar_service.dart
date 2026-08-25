import 'dart:convert';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

class GoogleCalendarService {
  static const List<String> _calendarScopes = [
    'https://www.googleapis.com/auth/calendar.events',
  ];

  Future<String?> _getAccessToken() async {
    try {
      final GoogleSignInAccount? googleUser =
      await GoogleSignIn.instance.authenticate();
      if (googleUser == null) return null;

      final auths =
      await googleUser.authorizationClient.authorizeScopes(_calendarScopes);


      return auths.accessToken;
    } catch (e) {
      print('Google Sign-In error: $e');
      return null;
    }
  }

  Future<bool> addDeadline({
    required String title,
    required String deadline,
    required String description,
  }) async {
    final cleanDate = _formatDate(deadline);
    if (cleanDate == null){
      print("Error: Invalid date format received: $deadline ");
      return false;
    }
    final accessToken = await _getAccessToken();

    if (accessToken == null) {
      return false;
    }

    final event = {
      'summary': title,
      'description': description,
      'start': {
        'date': cleanDate,
      },
      'end': {
        'date': _nextDay(cleanDate),
      },
    };

    final response = await http.post(
      Uri.parse(
        'https://www.googleapis.com/calendar/v3/calendars/primary/events',
      ),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(event),
    );

    if (response.statusCode != 200 && response.statusCode != 201){
      print('Calendar API Error: ${response.body}');
    }


    return response.statusCode == 200 ||
        response.statusCode == 201;
  }

  String? _formatDate(String input){
    try{
      final date = DateTime.parse(input.trim());
      return date.toIso8601String().substring(0, 10);
    }
    catch (_){
      return null;
    }
  }



  String _nextDay(String dateString) {
    final date = DateTime.parse(dateString);

    final nextDay = date.add(
      const Duration(days: 1),
    );

    return nextDay.toIso8601String().substring(0, 10);
  }
}