import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/job.dart';
import '../bloc/job_detail/job_detail_bloc.dart';
import '../bloc/job_detail/job_detail_event.dart';
import '../bloc/job_detail/job_detail_state.dart';
import '../bloc/job_matches/job_matches_bloc.dart';
import '../bloc/job_matches/job_matches_event.dart';
import '../widgets/match_score_badge.dart';
import '../widgets/offline_banner.dart';
import '../widgets/salary_badge.dart';
import '../widgets/voice_note_recorder_dialog.dart';

class JobDetailPage extends StatelessWidget {
  final String jobId;
  final Job? initialJob;

  const JobDetailPage({
    super.key,
    required this.jobId,
    this.initialJob,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider<JobDetailBloc>(
      create: (_) => sl<JobDetailBloc>()
        ..add(LoadJobDetailEvent(jobId)),
      child: _JobDetailView(initialJob: initialJob),
    );
  }
}

class _JobDetailView extends StatefulWidget {
  final Job? initialJob;

  const _JobDetailView({this.initialJob});

  @override
  State<_JobDetailView> createState() => _JobDetailViewState();
}

class _JobDetailViewState extends State<_JobDetailView> {
  bool _voiceNoteReady = false;

  void _onApplyPressed(BuildContext context, Job job, bool isOffline) {
    if (isOffline) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Apply is disabled while offline. Connect to internet to apply.'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    // Dispatch optimistic apply to matches bloc as well so list is updated immediately
    context.read<JobMatchesBloc>().add(ApplyJobOptimisticEvent(job.id));

    // Dispatch apply to detail bloc
    context.read<JobDetailBloc>().add(ApplyJobDetailEvent(job.id));
  }

  void _showSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: AppColors.successLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: AppColors.success,
                size: 52,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Application Successful!',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: AppColors.success,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Your profile has been forwarded directly to the employer. We will notify you when shortlisted.',
              style: AppTextStyles.bodyMedium,
              textAlign: TextAlign.center,
            ),
            if (_voiceNoteReady) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.mic, size: 16, color: AppColors.primary),
                    SizedBox(width: 6),
                    Text(
                      'Voice note attached (30s max)',
                      style: TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              minimumSize: const Size.fromHeight(44),
            ),
            child: const Text('Back to Matches'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<JobDetailBloc, JobDetailState>(
      listener: (context, state) {
        if (state.applyStatus == ApplyStatus.confirmed) {
          _showSuccessDialog(context);
        } else if (state.applyStatus == ApplyStatus.failed) {
          // Rollback in matches bloc as well
          if (state.job != null) {
            context.read<JobMatchesBloc>().add(ApplyJobRollbackEvent(state.job!.id));
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                state.applyErrorMessage ?? 'Failed to apply due to server error. Optimistic update rolled back.',
              ),
              backgroundColor: AppColors.error,
              action: SnackBarAction(
                label: 'Retry',
                textColor: Colors.white,
                onPressed: () {
                  if (state.job != null) {
                    _onApplyPressed(context, state.job!, state.isOffline);
                  }
                },
              ),
            ),
          );
        }
      },
      builder: (context, state) {
        final job = state.job ?? widget.initialJob;
        final isOffline = state.isOffline;

        return Scaffold(
          appBar: AppBar(
            title: Text(job?.title ?? 'Job Details'),
          ),
          body: Column(
            children: [
              OfflineBanner(isOffline: isOffline),
              Expanded(
                child: job == null
                    ? const Center(child: CircularProgressIndicator())
                    : _buildJobDetails(context, job),
              ),
              if (job != null)
                _buildStickyBottomBar(context, job, isOffline, state),
            ],
          ),
        );
      },
    );
  }

  Widget _buildJobDetails(BuildContext context, Job job) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        job.title,
                        style: AppTextStyles.titleLarge,
                      ),
                    ),
                    MatchScoreBadge(score: job.matchScore),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.business_outlined, size: 16, color: AppColors.textSecondary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        job.employerDisplay,
                        style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 16, color: AppColors.textTertiary),
                    const SizedBox(width: 6),
                    Text(
                      '${job.city}, ${job.country}',
                      style: AppTextStyles.bodyMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SalaryBadge(
                  minSalary: job.salaryMinAed,
                  maxSalary: job.salaryMaxAed,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // AI Match Reason Sentence Highlight Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.highMatch.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.psychology_alt_rounded, color: AppColors.highMatch, size: 20),
                    SizedBox(width: 6),
                    Text(
                      'AI Match Reason',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.highMatch,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  job.matchReason,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: const Color(0xFF14532D),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Benefits Section (accommodation, food, visa)
          _buildBenefitsSection(job),
          const SizedBox(height: 16),

          // Job Description
          const Text(
            'Job Description',
            style: AppTextStyles.titleMedium,
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: Text(
              job.description,
              style: AppTextStyles.bodyLarge,
            ),
          ),
          const SizedBox(height: 16),

          // Requirements Section
          const Text(
            'Requirements',
            style: AppTextStyles.titleMedium,
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: job.requirements.map((req) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.check_circle_outline, color: AppColors.primary, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          req,
                          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),

          // Voice Note Bonus Section (Only if not applied yet)
          if (!job.isApplied) ...[
            VoiceNoteRecorderDialog(
              onVoiceNoteReady: (ready) {
                setState(() {
                  _voiceNoteReady = ready;
                });
              },
            ),
            const SizedBox(height: 24),
          ],
        ],
      ),
    );
  }

  Widget _buildBenefitsSection(Job job) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Benefits Provided',
          style: AppTextStyles.titleMedium,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _benefitItem(
                icon: Icons.hotel_outlined,
                title: 'Accommodation',
                provided: job.benefits.accommodation,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _benefitItem(
                icon: Icons.restaurant_outlined,
                title: 'Food',
                provided: job.benefits.food,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _benefitItem(
                icon: Icons.badge_outlined,
                title: 'Visa',
                provided: job.benefits.visa,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _benefitItem({
    required IconData icon,
    required String title,
    required bool provided,
  }) {
    final color = provided ? AppColors.success : AppColors.textTertiary;
    final bgColor = provided ? AppColors.successLight : const Color(0xFFF1F5F9);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: provided ? AppColors.success.withValues(alpha: 0.3) : AppColors.border,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                provided ? Icons.check : Icons.close,
                size: 13,
                color: color,
              ),
              const SizedBox(width: 2),
              Text(
                provided ? 'Provided' : 'Not Provided',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStickyBottomBar(
    BuildContext context,
    Job job,
    bool isOffline,
    JobDetailState state,
  ) {
    final isApplied = job.isApplied;
    final isOptimisticSubmitting = state.applyStatus == ApplyStatus.optimisticApplied;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
        border: const Border(
          top: BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isOffline && !isApplied) ...[
              const Padding(
                padding: EdgeInsets.only(bottom: 8.0),
                child: Text(
                  'Apply is disabled while offline. Connect to internet to apply.',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.warning,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: (isApplied || isOffline || isOptimisticSubmitting)
                    ? null
                    : () => _onApplyPressed(context, job, isOffline),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isApplied ? AppColors.success : AppColors.primary,
                  disabledBackgroundColor: isApplied
                      ? AppColors.success.withValues(alpha: 0.8)
                      : (isOffline ? Colors.grey.shade400 : AppColors.primary),
                  disabledForegroundColor: Colors.white,
                  elevation: isApplied ? 0 : 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: isOptimisticSubmitting
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          ),
                          SizedBox(width: 10),
                          Text('Submitting...'),
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            isApplied ? Icons.check_circle_rounded : Icons.send_rounded,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            isApplied ? 'Already Applied' : 'Apply Now',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
