import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:karmasu/l10n/app_localizations.dart';
import '../../../core/services/language_service.dart';
import '../../../core/services/daily_targets_service.dart';

class DailyTargetsSection extends StatefulWidget {
  const DailyTargetsSection({super.key});

  @override
  State<DailyTargetsSection> createState() => _DailyTargetsSectionState();
}

class _DailyTargetsSectionState extends State<DailyTargetsSection> {
  final TextEditingController _targetController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Force refresh the service data when widget initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshData();
    });
  }

  @override
  void dispose() {
    _targetController.dispose();
    super.dispose();
  }

  Future<void> _refreshData() async {
    final dailyTargetsService = Provider.of<DailyTargetsService>(context, listen: false);
    await dailyTargetsService.refreshDailyTarget();
    await dailyTargetsService.getTodayJapaCount();
    await dailyTargetsService.getDaysActive();
  }

  Future<void> _setTarget() async {
    final targetText = _targetController.text.trim();
    if (targetText.isEmpty) return;

    final target = int.tryParse(targetText);
    if (target == null || target <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter a valid target number'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final dailyTargetsService = Provider.of<DailyTargetsService>(context, listen: false);
    await dailyTargetsService.setDailyTarget(target);
    
    // Refresh the data to ensure UI updates
    await _refreshData();
    
    _targetController.clear();
    
    if (mounted) {
      Navigator.of(context).pop();
      
      ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Daily target set to $target'),
        backgroundColor: Colors.green,
      ),
    );
    }
  }

  void _showSetTargetDialog() {
    final l10n = AppLocalizations.of(context)!;
    final languageService = Provider.of<LanguageService>(context, listen: false);
    final isHindi = languageService.isHindi;
    final dailyTargetsService = Provider.of<DailyTargetsService>(context, listen: false);
    final currentTarget = dailyTargetsService.currentTarget;

    _targetController.text = currentTarget?.targetCount.toString() ?? '108';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isHindi ? 'दैनिक लक्ष्य निर्धारित करें' : 'Set Daily Target'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isHindi 
                  ? 'प्रतिदिन कितने जाप करना चाहते हैं?'
                  : 'How many japa do you want to do daily?',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _targetController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: isHindi ? 'लक्ष्य संख्या' : 'Target Number',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.flag_rounded),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: _setTarget,
            child: Text(l10n.setTarget),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final languageService = Provider.of<LanguageService>(context);
    final dailyTargetsService = Provider.of<DailyTargetsService>(context);
    final isHindi = languageService.isHindi;
    final currentTarget = dailyTargetsService.currentTarget;

    if (currentTarget == null) {
      return Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final todayJapaCount = dailyTargetsService.todayJapaCount;
    final isTargetMet = todayJapaCount >= currentTarget.targetCount;
    final progress = currentTarget.targetCount > 0 
        ? (todayJapaCount / currentTarget.targetCount).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE9ECEF),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2C3E50).withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.flag_rounded,
                color: const Color(0xFFFFB366),
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                l10n.dailyTargets,
                style: const TextStyle(
                  color: Color(0xFF2C3E50),
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: _refreshData,
                icon: const Icon(
                  Icons.refresh_rounded,
                  color: Color(0xFF6C757D),
                  size: 20,
                ),
                tooltip: 'Refresh Data',
              ),
              IconButton(
                onPressed: _showSetTargetDialog,
                icon: const Icon(
                  Icons.edit_rounded,
                  color: Color(0xFFFFB366),
                  size: 20,
                ),
                tooltip: 'Set Target',
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Today's Progress
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isTargetMet 
                  ? Colors.green.withValues(alpha: 0.1)
                  : const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isTargetMet 
                    ? Colors.green.withValues(alpha: 0.3)
                    : const Color(0xFFE9ECEF),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      isTargetMet ? Icons.check_circle_rounded : Icons.track_changes_rounded,
                      color: isTargetMet ? Colors.green : const Color(0xFFFFB366),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      l10n.todayProgress,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2C3E50),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      isTargetMet ? l10n.targetMet : l10n.targetNotMet,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isTargetMet ? Colors.green : Colors.orange,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  '$todayJapaCount / ${currentTarget.targetCount}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2C3E50),
                  ),
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: progress,
                  backgroundColor: const Color(0xFFE9ECEF),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isTargetMet ? Colors.green : const Color(0xFFFFB366),
                  ),
                  minHeight: 8,
                ),
                const SizedBox(height: 8),
                Text(
                  '${(progress * 100).toInt()}% ${isHindi ? 'पूरा' : 'Complete'}',
                  style: TextStyle(
                    fontSize: 12,
                    color: isTargetMet ? Colors.green : const Color(0xFF6C757D),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Streak Information
          Row(
            children: [
              Expanded(
                child: _buildStreakCard(
                  l10n.currentStreak,
                  currentTarget.currentStreak,
                  Icons.local_fire_department_rounded,
                  Colors.orange,
                  isHindi,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStreakCard(
                  l10n.longestStreak,
                  currentTarget.longestStreak,
                  Icons.emoji_events_rounded,
                  Colors.amber,
                  isHindi,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStreakCard(String title, int count, IconData icon, Color color, bool isHindi) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 24,
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2C3E50),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            '$count ${isHindi ? 'दिन' : 'days'}',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
