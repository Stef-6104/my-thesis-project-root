import 'dart:convert';

import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

class GoogleCalendarService {
  static const List<String> calendarScopes = [
    'https://www.googleapis.com/auth/calendar.events',
  ];

  Future<String?> _getAccessToken() async {
    try {
      final user = await GoogleSignIn.instance.authenticate();

      final authorization =
      await user.authorizationClient.authorizeScopes(
        calendarScopes,
      );

      return authorization.accessToken;
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
    final accessToken = await _getAccessToken();

    if (accessToken == null) {
      return false;
    }

    final event = {
      'summary': title,
      'description': description,
      'start': {
        'date': deadline,
      },
      'end': {
        'date': _nextDay(deadline),
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

    print('Calendar response: ${response.statusCode}');
    print(response.body);

    return response.statusCode == 200 ||
        response.statusCode == 201;
  }

  String _nextDay(String date) {
    final parsedDate = DateTime.parse(date);

    final nextDay = parsedDate.add(
      const Duration(days: 1),
    );

    return nextDay.toIso8601String().substring(0, 10);
  }
}