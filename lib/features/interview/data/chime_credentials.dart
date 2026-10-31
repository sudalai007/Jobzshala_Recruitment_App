class ChimeCredentials {
  const ChimeCredentials({required this.meeting, required this.attendee});

  final Map<String, dynamic> meeting;
  final Map<String, dynamic> attendee;

  factory ChimeCredentials.fromJson(Map<String, dynamic> json) {
    final meeting = json['Meeting'];
    final attendee = json['Attendee'];
    if (meeting is! Map || attendee is! Map) {
      throw const FormatException(
        'The join response must contain Meeting and Attendee objects.',
      );
    }
    return ChimeCredentials(
      meeting: Map<String, dynamic>.from(meeting),
      attendee: Map<String, dynamic>.from(attendee),
    );
  }

  Map<String, dynamic> toJson() => {'Meeting': meeting, 'Attendee': attendee};
}
