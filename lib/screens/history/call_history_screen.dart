import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../models/call_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/call_provider.dart';

/// Real Call History screen — replaces the Phase-4 placeholder. Reads
/// from the same /calls collection that CallService has been writing to
/// since Phase 5, so every real call made in the app already has a
/// history entry; this screen is purely a read + display layer.
class CallHistoryScreen extends ConsumerWidget {
  const CallHistoryScreen({super.key});

  String _formatWhen(DateTime dt) {
    final now = DateTime.now();
    final isToday = dt.year == now.year && dt.month == now.month && dt.day == now.day;
    final yesterday = now.subtract(const Duration(days: 1));
    final isYesterday =
        dt.year == yesterday.year && dt.month == yesterday.month && dt.day == yesterday.day;

    final time = DateFormat('h:mm a').format(dt);
    if (isToday) return 'Today, $time';
    if (isYesterday) return 'Yesterday, $time';
    return '${DateFormat('MMM d').format(dt)}, $time';
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(callHistoryProvider);
    final currentUid = ref.watch(authStateProvider).value?.uid;

    return Scaffold(
      appBar: AppBar(title: const Text('Calls')),
      body: currentUid == null
          ? const SizedBox.shrink()
          : historyAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Could not load call history. Check your connection and try again.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                ),
              ),
              data: (calls) {
                if (calls.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.history, size: 48, color: AppColors.textSecondary),
                          const SizedBox(height: 12),
                          Text(
                            'No calls yet',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Calls you make or receive will show up here.',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  itemCount: calls.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final call = calls[index];
                    final isOutgoing = call.wasOutgoing(currentUid);
                    final otherName = call.otherPartyName(currentUid);
                    final isMissed = call.wasMissed;
                    final isRejected = call.wasRejected;

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      leading: CircleAvatar(
                        radius: 22,
                        backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                        child: Text(
                          otherName.isNotEmpty ? otherName[0].toUpperCase() : '?',
                          style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                        ),
                      ),
                      title: Text(
                        otherName,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: (isMissed && !isOutgoing) ? AppColors.error : null,
                        ),
                      ),
                      subtitle: Row(
                        children: [
                          Icon(
                            isOutgoing ? Icons.call_made : Icons.call_received,
                            size: 14,
                            color: (isMissed && !isOutgoing) ? AppColors.error : AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            call.type == CallType.video ? 'Video call' : 'Audio call',
                            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                          ),
                          const Text(' • ', style: TextStyle(color: Colors.grey)),
                          Text(
                            _formatWhen(call.startedAt),
                            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Icon(
                            call.type == CallType.video ? Icons.videocam_outlined : Icons.call_outlined,
                            size: 18,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isMissed
                                ? 'Missed'
                                : isRejected
                                    ? 'Declined'
                                    : _formatDuration(call.duration),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: (isMissed || isRejected) ? FontWeight.bold : FontWeight.normal,
                              color: (isMissed || isRejected)
                                  ? AppColors.error
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}