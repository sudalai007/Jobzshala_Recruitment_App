/// The test endpoint base URL is supplied by the assignment team. Never commit
/// access codes or endpoint credentials. The service appends `/join`.
class ChimeEndpointConfig {
  ChimeEndpointConfig._();

  static const String endpoint = String.fromEnvironment(
    'CHIME_TEST_ENDPOINT',
    defaultValue: '',
  );

  static const String accessCode = String.fromEnvironment(
    'CHIME_TEST_ACCESS_CODE',
    defaultValue: '',
  );

  static const String meetingCode = String.fromEnvironment(
    'CHIME_MEETING_CODE',
    defaultValue: '',
  );
}
