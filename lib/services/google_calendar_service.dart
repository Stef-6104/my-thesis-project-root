import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/calendar/v3.dart' as calendar;
import 'package:http/http.dart' as http;

class GoogleCalendarService {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: <String>[
      calendar.CalendarApi.calendarEventsScope,
    ],
  );

  Future<void> createCalendarEvent({
    required String title,
    required String description,
    required DateTime deadline,
  }) async {
    // Sign in to Google
    final GoogleSignInAccount? account =
    await _googleSignIn.signIn();

    if (account == null) {
      throw Exception('Google Sign-In was cancelled.');
    }

    // Get authentication information
    final GoogleSignInAuthentication authentication =
    await account.authentication;

    final String? accessToken = authentication.accessToken;

    if (accessToken == null) {
      throw Exception('Could not obtain Google access token.');
    }

    // HTTP client that adds the Google access token
    final authenticatedClient = _GoogleAuthClient(accessToken);

    try {
      final calendarApi =
      calendar.CalendarApi(authenticatedClient);

      // Create the Calendar event
      final event = calendar.Event(
        summary: title,
        description: description,
        start: calendar.EventDateTime(
          dateTime: deadline,
          timeZone: 'Asia/Manila',
        ),
        end: calendar.EventDateTime(
          dateTime: deadline.add(const Duration(hours: 1)),
          timeZone: 'Asia/Manila',
        ),
      );

      await calendarApi.events.insert(
        event,
        'primary',
      );
    } finally {
      authenticatedClient.close();
    }
  }
}

class _GoogleAuthClient extends http.BaseClient {
  final String accessToken;
  final http.Client _client = http.Client();

  _GoogleAuthClient(this.accessToken);

  @override
  Future<http.StreamedResponse> send(
      http.BaseRequest request) {
    request.headers['Authorization'] =
    'Bearer $accessToken';

    return _client.send(request);
  }

  @override
  void close() {
    _client.close();
  }
}