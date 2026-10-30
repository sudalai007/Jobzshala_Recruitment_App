import 'package:equatable/equatable.dart';
import 'benefits.dart';

class Job extends Equatable {
  final String id;
  final String title;
  final String employerDisplay;
  final String country;
  final String city;
  final int salaryMinAed;
  final int salaryMaxAed;
  final double matchScore;
  final String matchReason;
  final List<String> skills;
  final Benefits benefits;
  final String description;
  final List<String> requirements;
  final DateTime postedAt;
  final bool isApplied;

  const Job({
    required this.id,
    required this.title,
    required this.employerDisplay,
    required this.country,
    required this.city,
    required this.salaryMinAed,
    required this.salaryMaxAed,
    required this.matchScore,
    required this.matchReason,
    required this.skills,
    required this.benefits,
    required this.description,
    required this.requirements,
    required this.postedAt,
    this.isApplied = false,
  });

  Job copyWith({
    String? id,
    String? title,
    String? employerDisplay,
    String? country,
    String? city,
    int? salaryMinAed,
    int? salaryMaxAed,
    double? matchScore,
    String? matchReason,
    List<String>? skills,
    Benefits? benefits,
    String? description,
    List<String>? requirements,
    DateTime? postedAt,
    bool? isApplied,
  }) {
    return Job(
      id: id ?? this.id,
      title: title ?? this.title,
      employerDisplay: employerDisplay ?? this.employerDisplay,
      country: country ?? this.country,
      city: city ?? this.city,
      salaryMinAed: salaryMinAed ?? this.salaryMinAed,
      salaryMaxAed: salaryMaxAed ?? this.salaryMaxAed,
      matchScore: matchScore ?? this.matchScore,
      matchReason: matchReason ?? this.matchReason,
      skills: skills ?? this.skills,
      benefits: benefits ?? this.benefits,
      description: description ?? this.description,
      requirements: requirements ?? this.requirements,
      postedAt: postedAt ?? this.postedAt,
      isApplied: isApplied ?? this.isApplied,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        employerDisplay,
        country,
        city,
        salaryMinAed,
        salaryMaxAed,
        matchScore,
        matchReason,
        skills,
        benefits,
        description,
        requirements,
        postedAt,
        isApplied,
      ];
}

