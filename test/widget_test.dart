import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jobzshala_assignment/features/jobs/domain/entities/benefits.dart';
import 'package:jobzshala_assignment/features/jobs/domain/entities/job.dart';
import 'package:jobzshala_assignment/features/jobs/presentation/widgets/job_card.dart';

void main() {
  testWidgets('JobCard displays title, employer, salary, match score and skill chips', (WidgetTester tester) async {
    final testJob = Job(
      id: 'job_1042',
      title: 'Heavy Truck Driver',
      employerDisplay: 'Logistics company, UAE',
      country: 'UAE',
      city: 'Dubai',
      salaryMinAed: 2800,
      salaryMaxAed: 3500,
      matchScore: 87.5,
      matchReason: '6 years heavy vehicle experience',
      skills: const ['Heavy vehicle', 'GCC licence', 'Route planning'],
      benefits: const Benefits(accommodation: true, food: false, visa: true),
      description: 'Drive 18-wheelers on inter-emirate routes...',
      requirements: const ['Valid GCC heavy licence'],
      postedAt: DateTime(2026, 9, 20),
      isApplied: false,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: JobCard(
            job: testJob,
            onTap: () {},
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Heavy Truck Driver'), findsOneWidget);
    expect(find.text('Logistics company, UAE'), findsOneWidget);
    expect(find.text('Dubai, UAE'), findsOneWidget);
    expect(find.textContaining('87.5% Match'), findsOneWidget);
    expect(find.textContaining('2,800 – 3,500 AED/mo'), findsOneWidget);
    expect(find.text('Heavy vehicle'), findsOneWidget);
    expect(find.text('GCC licence'), findsOneWidget);
    expect(find.text('Route planning'), findsOneWidget);
  });
}
