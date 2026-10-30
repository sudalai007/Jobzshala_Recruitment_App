import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/di/injection_container.dart';
import 'core/navigation/custom_navigation_helper.dart';
import 'core/theme/app_theme.dart';
import 'features/jobs/presentation/bloc/job_matches/job_matches_bloc.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initDependencies();

  // Initialize navigation helper singleton
  CustomNavigationHelper.instance;

  runApp(const JobzshalaApp());
}

class JobzshalaApp extends StatelessWidget {
  const JobzshalaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<JobMatchesBloc>(
      create: (_) => sl<JobMatchesBloc>(),
      child: MaterialApp.router(
        title: 'Jobzshala GCC',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        routerConfig: CustomNavigationHelper.router,
      ),
    );
  }
}
