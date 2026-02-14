import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/services/streak_service.dart';
import '../../../../core/services/language_service.dart';
import '../../../../core/services/auth_service.dart';

class StreakSection extends StatefulWidget {
  const StreakSection({super.key});

  @override
  State<StreakSection> createState() => _StreakSectionState();
}

class _StreakSectionState extends State<StreakSection> {
  final TextEditingController _targetController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Don't force refresh - let the service handle initialization
  }

  @override
  void dispose() {
    _targetController.dispose();
    super.dispose();
  }

  Future<void> _setTarget() async {
    final targetText = _targetController.text.trim();
    if (targetText.isEmpty) return;

    final target = int.tryParse(targetText);
    if (target == null || target <= 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please enter a valid target number'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    final streakService = Provider.of<StreakService>(context, listen: false);
    final result = await streakService.setDailyTarget(target);
    
    _targetController.clear();
    
    if (mounted) {
      Navigator.of(context).pop();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result?['success'] == true
                ? 'Daily target set to $target'
                : (result?['message'] ?? 'Failed to set target'),
          ),
          backgroundColor: result?['success'] == true ? Colors.green : Colors.red,
        ),
      );
    }
  }

  void _showSetTargetDialog() {
    final languageService = Provider.of<LanguageService>(context, listen: false);
    final isHindi = languageService.isHindi;
    final streakService = Provider.of<StreakService>(context, listen: false);

    _targetController.text = streakService.currentTarget.toString();

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
                labelText: isHindi ? 'जाप की संख्या' : 'Number of japas',
                border: const OutlineInputBorder(),
                suffixText: isHindi ? 'जाप' : 'japas',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(isHindi ? 'रद्द करें' : 'Cancel'),
          ),
          ElevatedButton(
            onPressed: _setTarget,
            child: Text(isHindi ? 'सेट करें' : 'Set'),
          ),
        ],
      ),
    );
  }

  void _shareStreak() {
    final languageService = Provider.of<LanguageService>(context, listen: false);
    final authService = Provider.of<AuthService>(context, listen: false);
    final streakService = Provider.of<StreakService>(context, listen: false);
    final isHindi = languageService.isHindi;
    
    // Get user name
    final currentUser = authService.getCurrentUser();
    final userName = currentUser?.userMetadata?['name'] ?? 
                     currentUser?.email?.split('@')[0] ?? 
                     'User';
    
    // Create share message
    final shareMessage = isHindi
        ? '''🔥 मेरा स्ट्रीक रिकॉर्ड!

🏆 वर्तमान स्ट्रीक: ${streakService.currentStreak} दिन
⭐ सबसे लंबा स्ट्रीक: ${streakService.longestStreak} दिन
📊 आज का लक्ष्य: ${streakService.todayProgress}/${streakService.currentTarget} जाप

📿 KARMASU - Digital Hindu Gurukul के साथ मेरी आध्यात्मिक यात्रा में शामिल हों!
🔗 Download: https://play.google.com/store/apps/details?id=com.digital.hindugurukul'''
        : '''🔥 My Streak Record!

🏆 Current Streak: ${streakService.currentStreak} days
⭐ Longest Streak: ${streakService.longestStreak} days
📊 Today's Progress: ${streakService.todayProgress}/${streakService.currentTarget} japas

📿 Join me on KARMASU - Digital Hindu Gurukul!
🔗 Download: https://play.google.com/store/apps/details?id=com.digital.hindugurukul''';
    
    Share.share(
      shareMessage,
      subject: isHindi ? 'मेरा स्ट्रीक चैलेंज' : 'My Streak Challenge',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<StreakService, LanguageService>(
      builder: (context, streakService, languageService, child) {
        final isHindi = languageService.isHindi;
        
        // Show a simple loading indicator only if it's the first load
        if (streakService.isLoading && streakService.todayProgress == 0) {
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
            ),
            child: const Center(
              child: SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  color: Color(0xFFFFB366),
                  strokeWidth: 2,
                ),
              ),
            ),
          );
        }
        
        final progressPercentage = streakService.getProgressPercentage();
        final isTargetMet = streakService.todayAchieved;
        
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
                    Icons.local_fire_department_rounded,
                    color: const Color(0xFFFFB366),
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isHindi ? 'स्ट्रीक चैलेंज' : 'Streak Challenge',
                    style: const TextStyle(
                      color: Color(0xFF2C3E50),
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: _shareStreak,
                    icon: const Icon(
                      Icons.share_rounded,
                      color: Color(0xFF4CAF50),
                      size: 20,
                    ),
                    tooltip: isHindi ? 'शेयर करें' : 'Share',
                  ),
                  IconButton(
                    onPressed: _showSetTargetDialog,
                    icon: const Icon(
                      Icons.edit_rounded,
                      color: Color(0xFFFFB366),
                      size: 20,
                    ),
                    tooltip: isHindi ? 'लक्ष्य सेट करें' : 'Set Target',
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Streak Stats Row
              Row(
                children: [
                  // Current Streak
                  Expanded(
                    child: _buildStatCard(
                      context,
                      isHindi ? 'वर्तमान स्ट्रीक' : 'Current Streak',
                      '${streakService.currentStreak}',
                      isHindi ? 'दिन' : 'days',
                      Icons.whatshot_rounded,
                      Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Longest Streak
                  Expanded(
                    child: _buildStatCard(
                      context,
                      isHindi ? 'सबसे लंबा स्ट्रीक' : 'Longest Streak',
                      '${streakService.longestStreak}',
                      isHindi ? 'दिन' : 'days',
                      Icons.emoji_events_rounded,
                      Colors.amber,
                    ),
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
                          isHindi ? 'आज का लक्ष्य' : 'Today\'s Target',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2C3E50),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          isTargetMet 
                              ? (isHindi ? 'लक्ष्य पूरा!' : 'Target Met!')
                              : (isHindi ? 'चालू है' : 'In Progress'),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isTargetMet ? Colors.green : Colors.orange,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${streakService.todayProgress}/${streakService.currentTarget}',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2C3E50),
                                ),
                              ),
                              Text(
                                isHindi ? 'जाप पूरे किए' : 'japas completed',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF6C757D),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Container(
                                height: 8,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE9ECEF),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: FractionallySizedBox(
                                  alignment: Alignment.centerLeft,
                                  widthFactor: progressPercentage,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: isTargetMet ? Colors.green : const Color(0xFFFFB366),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                isTargetMet
                                    ? (isHindi ? '100% पूरा!' : '100% Complete!')
                                    : '${(progressPercentage * 100).round()}%',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isTargetMet ? Colors.green : const Color(0xFFFFB366),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (!isTargetMet && streakService.daysUntilTarget > 0) ...[
                      const SizedBox(height: 8),
                      Text(
                        isHindi 
                            ? 'बचे हुए जाप: ${streakService.daysUntilTarget}'
                            : 'Remaining: ${streakService.daysUntilTarget} japas',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6C757D),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              
              const SizedBox(height: 12),
              
              // Motivational Message
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFFE9ECEF),
                  ),
                ),
                child: Text(
                  streakService.getMotivationalMessage(),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF2C3E50),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    String unit,
    IconData icon,
    Color iconColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE9ECEF),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: iconColor,
            size: 24,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C3E50),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFF6C757D),
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            unit,
            style: const TextStyle(
              fontSize: 10,
              color: Color(0xFF6C757D),
            ),
          ),
        ],
      ),
    );
  }
}