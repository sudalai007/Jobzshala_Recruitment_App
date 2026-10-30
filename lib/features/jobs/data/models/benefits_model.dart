import '../../domain/entities/benefits.dart';

class BenefitsModel extends Benefits {
  const BenefitsModel({
    required super.accommodation,
    required super.food,
    required super.visa,
  });

  factory BenefitsModel.fromJson(Map<String, dynamic> json) {
    return BenefitsModel(
      accommodation: json['accommodation'] == true,
      food: json['food'] == true,
      visa: json['visa'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'accommodation': accommodation,
      'food': food,
      'visa': visa,
    };
  }
}

