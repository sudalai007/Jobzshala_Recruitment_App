class ChimeEvent {
  const ChimeEvent({required this.type, this.data = const {}});
  final String type;
  final Map<String, dynamic> data;

  factory ChimeEvent.fromDynamic(dynamic value) {
    if (value is! Map) throw const FormatException('Invalid Chime event.');
    return ChimeEvent(
      type: value['type']?.toString() ?? 'unknown',
      data: value['data'] is Map
          ? Map<String, dynamic>.from(value['data'] as Map)
          : const {},
    );
  }
}
