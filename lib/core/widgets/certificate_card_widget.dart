// core/widgets/certificate_card_widget.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/certificate_model.dart';
import '../services/certificate_service.dart';
import '../services/language_service.dart';

class CertificateCardWidget extends StatelessWidget {
  final CertificateModel certificate;
  final int userJapaCount;
  final VoidCallback? onDownload;

  const CertificateCardWidget({
    super.key,
    required this.certificate,
    required this.userJapaCount,
    this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    final languageService = Provider.of<LanguageService>(context);
    final isHindi = languageService.isHindi;

    final isUnlocked = CertificateService.hasAchievedCertificate(
      certificate,
      userJapaCount,
    );

    final progressPercentage = CertificateService.getProgressPercentage(
      certificate,
      userJapaCount,
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
                ? Color(
                    int.parse(certificate.colorHex.substring(1), radix: 16) +
                        0xFF000000,
                  )
                : Colors.grey.shade300,
            width: isUnlocked ? 2 : 1,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isUnlocked
                  ? [
                      Color(
                        int.parse(
                              certificate.colorHex.substring(1),
                              radix: 16,
                            ) +
                            0xFF000000,
                      ).withOpacity(0.1),
                      Colors.white,
                    ]
                  : [Colors.grey.shade50, Colors.grey.shade100],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with level and status
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Level badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isUnlocked
                            ? Color(
                                int.parse(
                                      certificate.colorHex.substring(1),
                                      radix: 16,
                                    ) +
                                    0xFF000000,
                              )
                            : Colors.grey.shade400,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        isHindi
                            ? 'स्तर ${certificate.level}'
                            : 'Level ${certificate.level}',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    // Status icon
                    Icon(
                      isUnlocked ? Icons.check_circle : Icons.lock,
                      color: isUnlocked
                          ? Color(
                              int.parse(
                                    certificate.colorHex.substring(1),
                                    radix: 16,
                                  ) +
                                  0xFF000000,
                            )
                          : Colors.grey.shade400,
                      size: 24,
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
                    color: isUnlocked ? Colors.black87 : Colors.grey.shade600,
                  ),
                ),

                const SizedBox(height: 8),

                // Description
                Text(
                  certificate.getDescription(isHindi: isHindi),
                  style: TextStyle(
                    fontSize: 14,
                    color: isUnlocked
                        ? Colors.grey.shade700
                        : Colors.grey.shade500,
                  ),
                ),

                const SizedBox(height: 16),

                // Japa count requirement
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isUnlocked
                        ? Color(
                            int.parse(
                                  certificate.colorHex.substring(1),
                                  radix: 16,
                                ) +
                                0xFF000000,
                          ).withOpacity(0.1)
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isUnlocked
                          ? Color(
                              int.parse(
                                    certificate.colorHex.substring(1),
                                    radix: 16,
                                  ) +
                                  0xFF000000,
                            ).withOpacity(0.3)
                          : Colors.grey.shade300,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.favorite,
                        color: isUnlocked
                            ? Color(
                                int.parse(
                                      certificate.colorHex.substring(1),
                                      radix: 16,
                                    ) +
                                    0xFF000000,
                              )
                            : Colors.grey.shade400,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${certificate.requiredJapaCount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} ${isHindi ? 'जप' : 'Japas'}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isUnlocked
                              ? Color(
                                  int.parse(
                                        certificate.colorHex.substring(1),
                                        radix: 16,
                                      ) +
                                      0xFF000000,
                                )
                              : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Progress bar (for locked certificates)
                if (!isUnlocked) ...[
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
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            '${progressPercentage.toStringAsFixed(1)}%',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: progressPercentage / 100,
                        backgroundColor: Colors.grey.shade300,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color(
                            int.parse(
                                  certificate.colorHex.substring(1),
                                  radix: 16,
                                ) +
                                0xFF000000,
                          ),
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${userJapaCount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} / ${certificate.requiredJapaCount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} ${isHindi ? 'जप' : 'Japas'}',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ],

                // Unlocked status and download button
                if (isUnlocked) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: Colors.green.shade600,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isHindi ? 'खुला!' : 'Unlocked!',
                          style: TextStyle(
                            color: Colors.green.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: onDownload,
                          icon: Icon(
                            Icons.download,
                            color: Color(
                              int.parse(
                                    certificate.colorHex.substring(1),
                                    radix: 16,
                                  ) +
                                  0xFF000000,
                            ),
                            size: 18,
                          ),
                          label: Text(
                            isHindi ? 'डाउनलोड' : 'Download',
                            style: TextStyle(
                              color: Color(
                                int.parse(
                                      certificate.colorHex.substring(1),
                                      radix: 16,
                                    ) +
                                    0xFF000000,
                              ),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: TextButton.styleFrom(
                            backgroundColor: Color(
                              int.parse(
                                    certificate.colorHex.substring(1),
                                    radix: 16,
                                  ) +
                                  0xFF000000,
                            ).withOpacity(0.1),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 8),

                // Locked status message
                if (!isUnlocked)
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
                          Icons.lock,
                          color: Colors.orange.shade600,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            isHindi
                                ? 'अनलॉक करने के लिए ${(certificate.requiredJapaCount - userJapaCount).toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} और जप पूरे करें'
                                : 'Complete ${(certificate.requiredJapaCount - userJapaCount).toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} more Japas to unlock',
                            style: TextStyle(
                              color: Colors.orange.shade700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
