// core/widgets/streak_certificate_card_widget.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/streak_certificate_model.dart';
import '../services/certificate_service.dart';
import '../services/language_service.dart';

class StreakCertificateCardWidget extends StatelessWidget {
  final StreakCertificateModel certificate;
  final int currentStreakDays;
  final VoidCallback? onDownload;

  const StreakCertificateCardWidget({
    super.key,
    required this.certificate,
    required this.currentStreakDays,
    this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    final languageService = Provider.of<LanguageService>(context);
    final isHindi = languageService.isHindi;

    final isUnlocked = CertificateService.hasAchievedStreakCertificateModel(
      certificate,
      currentStreakDays,
    );

    final progressPercentage = _getProgressPercentage(
      currentStreakDays: currentStreakDays,
      requiredStreakDays: certificate.requiredStreakDays,
    );

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isUnlocked
                ? _getCertificateColor(certificate.level)
                : Colors.grey.shade300,
            width: isUnlocked ? 2 : 1,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: isUnlocked
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      _getCertificateColor(certificate.level).withOpacity(0.1),
                      Colors.white,
                    ],
                  )
                : null,
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row with level and status
                Row(
                  children: [
                    // Level badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isUnlocked
                            ? _getCertificateColor(certificate.level)
                            : Colors.grey.shade400,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        isHindi
                            ? 'स्तर ${certificate.level}'
                            : 'Level ${certificate.level}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const Spacer(),
                    // Status indicator
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isUnlocked ? Colors.green : Colors.orange,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isUnlocked ? Icons.check_circle : Icons.lock,
                            color: Colors.white,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isUnlocked
                                ? (isHindi ? 'खुला!' : 'Unlocked!')
                                : (isHindi ? 'बंद' : 'Locked'),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Certificate name
                Text(
                  certificate.getName(isHindi: isHindi),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isUnlocked
                        ? _getCertificateColor(certificate.level)
                        : Colors.grey.shade600,
                  ),
                ),

                const SizedBox(height: 8),

                // Description
                Text(
                  certificate.getDescription(isHindi: isHindi),
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    height: 1.4,
                  ),
                ),

                const SizedBox(height: 16),

                // Progress section
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isHindi ? 'प्रगति' : 'Progress',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        Text(
                          '${currentStreakDays}/${certificate.requiredStreakDays} ${isHindi ? 'दिन' : 'days'}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isUnlocked
                                ? _getCertificateColor(certificate.level)
                                : Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: progressPercentage / 100,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isUnlocked
                            ? _getCertificateColor(certificate.level)
                            : Colors.grey.shade400,
                      ),
                      minHeight: 6,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${progressPercentage.toStringAsFixed(0)}% ${isHindi ? 'पूर्ण' : 'complete'}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Action button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isUnlocked ? onDownload : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isUnlocked
                          ? _getCertificateColor(certificate.level)
                          : Colors.grey.shade300,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: isUnlocked ? 2 : 0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isUnlocked ? Icons.download : Icons.lock,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isUnlocked
                              ? (isHindi ? 'डाउनलोड करें' : 'Download')
                              : (isHindi
                                    ? 'अभी तक नहीं खुला'
                                    : 'Not Unlocked Yet'),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                if (!isUnlocked) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Colors.orange.shade600,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            isHindi
                                ? 'अनलॉक करने के लिए ${(certificate.requiredStreakDays - currentStreakDays)} और दिनों का अभ्यास करें'
                                : 'Practice ${(certificate.requiredStreakDays - currentStreakDays)} more days to unlock',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.orange.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getCertificateColor(int level) {
    switch (level) {
      case 1:
        return Colors.green; // Green for 7 days
      case 2:
        return Colors.blue; // Blue for 21 days
      case 3:
        return Colors.purple; // Purple for 108 days
      default:
        return Colors.grey;
    }
  }

  double _getProgressPercentage({
    required int currentStreakDays,
    required int requiredStreakDays,
  }) {
    if (currentStreakDays >= requiredStreakDays) return 100.0;
    return (currentStreakDays / requiredStreakDays) * 100;
  }
}
