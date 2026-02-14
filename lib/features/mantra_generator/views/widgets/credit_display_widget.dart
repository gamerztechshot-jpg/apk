// features/mantra_generator/views/widgets/credit_display_widget.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:karmasu/core/services/language_service.dart';

class CreditDisplayWidget extends StatelessWidget {
  final int credits;
  final bool isLow;

  const CreditDisplayWidget({
    super.key,
    required this.credits,
    this.isLow = false,
  });

  @override
  Widget build(BuildContext context) {
    final languageService = Provider.of<LanguageService>(context, listen: true);
    final isHindi = languageService.isHindi;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isLow ? Colors.red.shade50 : Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isLow ? Colors.red.shade200 : Colors.orange.shade200,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Credit Icon
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: isLow ? Colors.red.shade100 : Colors.orange.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.stars,
              size: 18,
              color: isLow ? Colors.red.shade700 : Colors.orange.shade700,
            ),
          ),
          const SizedBox(width: 8),
          // Credit Text
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isHindi ? 'क्रेडिट' : 'Credits',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '$credits',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isLow ? Colors.red.shade700 : Colors.orange.shade700,
                ),
              ),
            ],
          ),
          // Low Credit Warning
          if (isLow) ...[
            const SizedBox(width: 8),
            Icon(
              Icons.warning_amber_rounded,
              size: 16,
              color: Colors.red.shade700,
            ),
          ],
        ],
      ),
    );
  }
}
