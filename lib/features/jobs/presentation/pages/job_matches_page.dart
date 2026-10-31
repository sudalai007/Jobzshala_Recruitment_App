import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/navigation/custom_navigation_helper.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../bloc/job_matches/job_matches_bloc.dart';
import '../bloc/job_matches/job_matches_event.dart';
import '../bloc/job_matches/job_matches_state.dart';
import '../widgets/country_filter_chips.dart';
import '../widgets/job_card.dart';
import '../widgets/offline_banner.dart';
import '../widgets/skeleton_loading.dart';
import '../../../interview/presentation/interview_pages.dart';

class JobMatchesPage extends StatefulWidget {
  const JobMatchesPage({super.key});

  @override
  State<JobMatchesPage> createState() => _JobMatchesPageState();
}

class _JobMatchesPageState extends State<JobMatchesPage> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    context.read<JobMatchesBloc>().add(const LoadJobMatchesEvent());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 250) {
      context.read<JobMatchesBloc>().add(LoadMoreJobMatchesEvent());
    }
  }

  void _showServerSettingsDialog() {
    final controller = TextEditingController(text: ApiEndpoints.baseUrl);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('API Base URL Settings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Mock server running on your computer:\n'
              '• Android Emulator: http://10.0.2.2:3000\n'
              '• Physical device: http://<YOUR_LAN_IP>:3000\n'
              '• Windows/iOS: http://localhost:3000',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Base URL',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final newUrl = controller.text.trim();
              if (newUrl.isNotEmpty) {
                ApiEndpoints.setBaseUrl(newUrl);
                context.read<JobMatchesBloc>().add(
                  const LoadJobMatchesEvent(forceRefresh: true),
                );
              }
              Navigator.pop(ctx);
            },
            child: const Text('Save & Reload'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Job Matches',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            Text(
              'Verified Gulf Jobs',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w400,
                color: Colors.white70,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Server Settings',
            icon: const Icon(Icons.settings_outlined, size: 20),
            onPressed: _showServerSettingsDialog,
          ),
        ],
      ),
      body: BlocConsumer<JobMatchesBloc, JobMatchesState>(
        listener: (context, state) {
          if (state.errorMessage != null && state.jobs.isNotEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage!),
                backgroundColor: AppColors.error,
                action: SnackBarAction(
                  label: 'Retry',
                  textColor: Colors.white,
                  onPressed: () {
                    context.read<JobMatchesBloc>().add(
                      const LoadJobMatchesEvent(forceRefresh: true),
                    );
                  },
                ),
              ),
            );
          }
        },
        builder: (context, state) {
          return Column(
            children: [
              // Offline banner
              OfflineBanner(isOffline: state.isOffline),

              // Country filter chips
              CountryFilterChips(
                selectedCountry: state.selectedCountry,
                onSelected: (country) {
                  context.read<JobMatchesBloc>().add(
                    FilterCountryChangedEvent(country),
                  );
                },
              ),

              // Main content
              Expanded(
                child: RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () async {
                    context.read<JobMatchesBloc>().add(
                      const LoadJobMatchesEvent(forceRefresh: true),
                    );
                  },
                  child: _buildContent(context, state),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, JobMatchesState state) {
    // 1. Loading state (Skeleton)
    if (state.status == JobMatchesStatus.loading && state.jobs.isEmpty) {
      return const SingleChildScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        child: SkeletonLoadingList(),
      );
    }

    // 2. Error state (if no cached jobs)
    if (state.status == JobMatchesStatus.failure && state.jobs.isEmpty) {
      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: AppColors.errorLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.cloud_off_rounded,
                  size: 48,
                  color: AppColors.error,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Could not load jobs. Please check your connection and retry.',
                textAlign: TextAlign.center,
                style: AppTextStyles.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                state.errorMessage ?? '',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  context.read<JobMatchesBloc>().add(
                    const LoadJobMatchesEvent(forceRefresh: true),
                  );
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(180, 46),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // 3. Empty state
    if (state.jobs.isEmpty) {
      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: AppColors.primaryLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.work_outline_rounded,
                  size: 48,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 16),
              const Text('No matches yet', style: AppTextStyles.titleMedium),
              const SizedBox(height: 8),
              const Text(
                'We could not find matching jobs for your selected filter. Pull to refresh or try another country.',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium,
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () {
                  context.read<JobMatchesBloc>().add(
                    const FilterCountryChangedEvent('All'),
                  );
                },
                icon: const Icon(Icons.clear_all),
                label: const Text('All'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(160, 44),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // 4. Success List state
    final totalCount = 1 + state.jobs.length + (state.isLoadingMore ? 1 : 0);

    return ListView.builder(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: totalCount,
      itemBuilder: (context, index) {
        if (index == 0) {
          return InterviewEntryCard(
            onJoin: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const InterviewPreJoinPage(),
              ),
            ),
          );
        }
        final jobIndex = index - 1;
        if (jobIndex >= state.jobs.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }

        final job = state.jobs[jobIndex];
        return JobCard(
          job: job,
          onTap: () {
            CustomNavigationHelper.instance.pushJobDetail(job.id, job: job);
          },
        );
      },
    );
  }
}
