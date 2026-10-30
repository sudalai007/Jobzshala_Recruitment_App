import '../../domain/entities/job.dart';
import 'benefits_model.dart';

class JobModel extends Job {
  const JobModel({
    required super.id,
    required super.title,
    required super.employerDisplay,
    required super.country,
    required super.city,
    required super.salaryMinAed,
    required super.salaryMaxAed,
    required super.matchScore,
    required super.matchReason,
    required super.skills,
    required super.benefits,
    required super.description,
    required super.requirements,
    required super.postedAt,
    super.isApplied,
  });

  factory JobModel.fromJson(Map<String, dynamic> json) {
    return JobModel(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      employerDisplay: json['employer_display'] as String? ?? '',
      country: json['country'] as String? ?? '',
      city: json['city'] as String? ?? '',
      salaryMinAed: (json['salary_min_aed'] as num?)?.toInt() ?? 0,
      salaryMaxAed: (json['salary_max_aed'] as num?)?.toInt() ?? 0,
      matchScore: (json['match_score'] as num?)?.toDouble() ?? 0.0,
      matchReason: json['match_reason'] as String? ?? '',
      skills: (json['skills'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      benefits: json['benefits'] != null
          ? BenefitsModel.fromJson(json['benefits'] as Map<String, dynamic>)
          : const BenefitsModel(accommodation: false, food: false, visa: false),
      description: json['description'] as String? ?? '',
      requirements: (json['requirements'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      postedAt: json['posted_at'] != null
          ? DateTime.tryParse(json['posted_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      isApplied: json['is_applied'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'employer_display': employerDisplay,
      'country': country,
      'city': city,
      'salary_min_aed': salaryMinAed,
      'salary_max_aed': salaryMaxAed,
      'match_score': matchScore,
      'match_reason': matchReason,
      'skills': skills,
      'benefits': (benefits as BenefitsModel).toJson(),
      'description': description,
      'requirements': requirements,
      'posted_at': postedAt.toIso8601String(),
      'is_applied': isApplied,
    };
  }

  JobModel toModelWithApplied(bool applied) {
    return JobModel(
      id: id,
      title: title,
      employerDisplay: employerDisplay,
      country: country,
      city: city,
      salaryMinAed: salaryMinAed,
      salaryMaxAed: salaryMaxAed,
      matchScore: matchScore,
      matchReason: matchReason,
      skills: skills,
      benefits: benefits,
      description: description,
      requirements: requirements,
      postedAt: postedAt,
      isApplied: applied,
    );
  }
}

