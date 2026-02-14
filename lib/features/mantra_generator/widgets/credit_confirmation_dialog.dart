// features/mantra_generator/widgets/credit_confirmation_dialog.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/services/language_service.dart';

class CreditConfirmationDialog extends StatelessWidget {
  final int remainingCredits;
  final int creditCost;
  final String problemTitle;
  final VoidCallback onConfirm;
  final VoidCallback? onCancel;

  const CreditConfirmationDialog({
    super.key,
    required this.remainingCredits,
    required this.creditCost,
    required this.problemTitle,
    required this.onConfirm,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final languageService = Provider.of<LanguageService>(context, listen: false);
    final isHindi = languageService.isHindi;

    final creditsAfterAccess = remainingCredits - creditCost;

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Row(
        children: [
          Icon(
            Icons.account_balance_wallet_rounded,
            color: Colors.orange.shade600,
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              isHindi ? 'क्रेडिट पुष्टि' : 'Credit Confirmation',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Problem title
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
                  Icons.info_outline_rounded,
                  color: Colors.orange.shade700,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    problemTitle,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          
          // Credit cost
          _buildCreditRow(
            icon: Icons.remove_circle_outline,
            iconColor: Colors.red.shade400,
            label: isHindi ? 'क्रेडिट लागत' : 'Credit Cost',
            value: '$creditCost ${isHindi ? 'क्रेडिट' : creditCost == 1 ? 'credit' : 'credits'}',
            valueColor: Colors.red.shade700,
          ),
          
          const SizedBox(height: 12),
          
          // Remaining credits
          _buildCreditRow(
            icon: Icons.account_balance_wallet_outlined,
            iconColor: Colors.blue.shade400,
            label: isHindi ? 'शेष क्रेडिट' : 'Remaining Credits',
            value: '$remainingCredits ${isHindi ? 'क्रेडिट' : remainingCredits == 1 ? 'credit' : 'credits'}',
            valueColor: Colors.blue.shade700,
          ),
          
          const SizedBox(height: 12),
          
          // Credits after access
          _buildCreditRow(
            icon: Icons.check_circle_outline,
            iconColor: Colors.green.shade400,
            label: isHindi ? 'पहुंच के बाद शेष' : 'Credits After Access',
            value: '$creditsAfterAccess ${isHindi ? 'क्रेडिट' : creditsAfterAccess == 1 ? 'credit' : 'credits'}',
            valueColor: Colors.green.shade700,
          ),
          
          const SizedBox(height: 20),
          
          // Warning if low credits
          if (creditsAfterAccess < 5)
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.orange.shade700,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isHindi
                          ? 'कम क्रेडिट! पहुंच के बाद आपके पास कम क्रेडिट होंगे।'
                          : 'Low credits! You will have few credits remaining after access.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange.shade800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          
          const SizedBox(height: 16),
          
          // Confirmation message
          Text(
            isHindi
                ? 'क्या आप इस सब-समस्या तक पहुंचना चाहते हैं?'
                : 'Do you want to access this sub-problem?',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
      actions: [
        // Cancel button
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            onCancel?.call();
          },
          child: Text(
            isHindi ? 'रद्द करें' : 'Cancel',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        
        // Confirm button
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
            onConfirm();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange.shade600,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            elevation: 2,
          ),
          child: Text(
            isHindi ? 'पुष्टि करें' : 'Confirm',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCreditRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required Color valueColor,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          color: iconColor,
          size: 20,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}
