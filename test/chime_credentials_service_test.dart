import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jobzshala_assignment/features/interview/data/chime_credentials_service.dart';

void main() {
  const responseBody = {
    'Meeting': {
      'MeetingId': 'meeting-123',
      'MediaPlacement': {
        'AudioHostUrl': 'https://audio.example.test',
        'SignalingUrl': 'https://signal.example.test',
      },
    },
    'Attendee': {
      'AttendeeId': 'attendee-456',
      'ExternalUserId': 'Candidate One',
      'JoinToken': 'join-token',
    },
  };

  test('posts join details and parses Meeting and Attendee objects', () async {
    RequestOptions? request;
    final dio = Dio()
      ..interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            request = options;
            handler.resolve(
              Response(
                requestOptions: options,
                data: responseBody,
                statusCode: 200,
              ),
            );
          },
        ),
      );
    final service = ChimeCredentialsService(
      dio: dio,
      endpoint: 'https://interviews.example.test/api/',
      accessCode: 'test-access-code',
    );

    final credentials = await service.requestJoinInfo(
      meetingCode: ' shared-room ',
      name: ' Candidate One ',
    );

    expect(request?.uri.toString(), 'https://interviews.example.test/api/join');
    expect(request?.data, {
      'meeting_code': 'shared-room',
      'name': 'Candidate One',
    });
    expect(request?.headers['X-Access-Code'], 'test-access-code');
    expect(credentials.meeting['MeetingId'], 'meeting-123');
    expect(credentials.attendee['JoinToken'], 'join-token');
  });

  test('fails clearly when endpoint is not configured', () async {
    final service = ChimeCredentialsService(endpoint: '');
    await expectLater(
      service.requestJoinInfo(meetingCode: 'room', name: 'Candidate'),
      throwsA(isA<StateError>()),
    );
  });

  test('rejects a response without both Chime objects', () async {
    final dio = Dio()
      ..interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            handler.resolve(
              Response(
                requestOptions: options,
                data: {'Meeting': responseBody['Meeting']},
                statusCode: 200,
              ),
            );
          },
        ),
      );
    final service = ChimeCredentialsService(
      dio: dio,
      endpoint: 'https://interviews.example.test',
    );

    await expectLater(
      service.requestJoinInfo(meetingCode: 'room', name: 'Candidate'),
      throwsA(isA<FormatException>()),
    );
  });
}
