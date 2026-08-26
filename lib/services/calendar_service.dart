import 'dart:convert';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

class GoogleCalendarService {
  static const List<String> _calendarScopes = [
    'https://www.googleapis.com/auth/calendar.events',
  ];

  Future<String?> _getAccessToken() async {
    try {
      print('STEP 1: Starting Google authentication...');

      final GoogleSignInAccount? googleUser =
      await GoogleSignIn.instance.authenticate();

      print('STEP 2: authenticate() finished');

      if (googleUser == null) {
        print('STEP 2 ERROR: googleUser is null');
        return null;
      }

      print('STEP 3: Google user: ${googleUser.email}');
      print('STEP 4: Requesting Calendar permission...');

      final auths =
      await googleUser.authorizationClient.authorizeScopes(
        _calendarScopes,
      );

      print('STEP 5: Calendar authorization finished');
      print('STEP 6: Access token received: ${auths.accessToken != null}');

      return auths.accessToken;
    } catch (e, stackTrace) {
      print('GOOGLE SIGN-IN ERROR: $e');
      print('STACK TRACE: $stackTrace');
      return null;
    }
  }

  // 👇 REPLACE YOUR OLD addDeadline() WITH THIS
  Future<bool> addDeadline({
    required String title,
    required String deadline,
    required String description,
  }) async {
    print('=== ADDING CALENDAR EVENT ===');
    print('Title: $title');
    print('Deadline: $deadline');

    final cleanDate = _formatDate(deadline);

    if (cleanDate == null) {
      print('ERROR: Invalid date format: $deadline');
      return false;
    }

    print('Formatted date: $cleanDate');

    final accessToken = await _getAccessToken();

    if (accessToken == null) {
      print('ERROR: No access token');
      return false;
    }

    print('Got Calendar access token');

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

    print('Event JSON: ${jsonEncode(event)}');

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

    print('Calendar HTTP status: ${response.statusCode}');
    print('Calendar response: ${response.body}');

    if (response.statusCode == 200 ||
        response.statusCode == 201) {
      print('SUCCESS: Calendar event created');

      final responseData = jsonDecode(response.body);

      print('Event ID: ${responseData['id']}');
      print('Event link: ${responseData['htmlLink']}');

      return true;
    }

    print('FAILED TO CREATE CALENDAR EVENT');

    return false;
  }

  String? _formatDate(String input) {
    try {
      final date = DateTime.parse(input.trim());

      return date.toIso8601String().substring(0, 10);
    } catch (_) {
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