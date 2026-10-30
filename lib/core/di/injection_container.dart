import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get_it/get_it.dart';
import 'package:jobzshala_assignment/core/network/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../network/network_info.dart';
import '../../features/jobs/data/datasources/jobs_local_data_source.dart';
import '../../features/jobs/data/datasources/jobs_remote_data_source.dart';
import '../../features/jobs/data/repositories/jobs_repository_impl.dart';
import '../../features/jobs/domain/repositories/jobs_repository.dart';
import '../../features/jobs/domain/usecases/apply_to_job.dart';
import '../../features/jobs/domain/usecases/get_job_detail.dart';
import '../../features/jobs/domain/usecases/get_job_matches.dart';
import '../../features/jobs/presentation/bloc/job_detail/job_detail_bloc.dart';
import '../../features/jobs/presentation/bloc/job_matches/job_matches_bloc.dart';

final sl = GetIt.instance;

Future<void> initDependencies() async {
  // External
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton<SharedPreferences>(() => sharedPreferences);
  sl.registerLazySingleton<Connectivity>(() => Connectivity());

  // Dio HTTP Client
  sl.registerSingleton<ApiClient>(ApiClient());

  // sl.registerLazySingleton<Dio>(() {
  //   final dio = Dio(
  //     BaseOptions(
  //       connectTimeout: const Duration(seconds: 30),
  //       receiveTimeout: const Duration(seconds: 30),
  //       sendTimeout: const Duration(seconds: 30),
  //       headers: {
  //         'Accept': 'application/json',
  //         'Content-Type': 'application/json',
  //       },
  //     ),
  //   );
  //   return dio;
  // });

  // Core
  sl.registerLazySingleton<NetworkInfo>(() => NetworkInfoImpl(sl()));

  // Data Sources
  sl.registerLazySingleton<JobsRemoteDataSource>(
    () => JobsRemoteDataSourceImpl(apiClient: sl()),
  );
  sl.registerLazySingleton<JobsLocalDataSource>(
    () => JobsLocalDataSourceImpl(sharedPreferences: sl()),
  );

  // Repository
  sl.registerLazySingleton<JobsRepository>(
    () => JobsRepositoryImpl(
      remoteDataSource: sl(),
      localDataSource: sl(),
      networkInfo: sl(),
    ),
  );

  // Use cases
  sl.registerLazySingleton(() => GetJobMatches(sl()));
  sl.registerLazySingleton(() => GetJobDetail(sl()));
  sl.registerLazySingleton(() => ApplyToJob(sl()));

  // Blocs
  sl.registerFactory(
    () => JobMatchesBloc(getJobMatchesUseCase: sl(), repository: sl()),
  );
  sl.registerFactory(
    () => JobDetailBloc(
      getJobDetailUseCase: sl(),
      applyToJobUseCase: sl(),
      repository: sl(),
    ),
  );
}
