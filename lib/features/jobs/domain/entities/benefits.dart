import 'package:equatable/equatable.dart';

class Benefits extends Equatable {
  final bool accommodation;
  final bool food;
  final bool visa;

  const Benefits({
    required this.accommodation,
    required this.food,
    required this.visa,
  });

  @override
  List<Object?> get props => [accommodation, food, visa];
}

