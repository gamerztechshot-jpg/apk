// features/astro/views/widgets/kundli_types_section.dart
import 'package:flutter/material.dart';
import 'package:karmasu/l10n/app_localizations.dart';
import '../../models/kundli_type_model.dart';
import '../kundli_payment_screen.dart';

class KundliTypesSection extends StatelessWidget {
  final List<KundliTypeModel> kundliTypes;

  const KundliTypesSection({super.key, required this.kundliTypes});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            l10n.ourKundliReports,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Kundli Types Horizontal List
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: kundliTypes.length,
            itemBuilder: (context, index) {
              final kundliType = kundliTypes[index];
              return Padding(
                padding: EdgeInsets.only(
                  right: index < kundliTypes.length - 1 ? 16 : 0,
                ),
                child: _buildKundliCard(context, kundliType),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildKundliCard(BuildContext context, KundliTypeModel kundliType) {
    return Container(
      width: 160,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          Container(
            height: 80,
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: kundliType.imageUrl != null
                ? ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                    child: Image.network(
                      kundliType.imageUrl!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) => Center(
                        child: Icon(
                          Icons.star,
                          color: Colors.orange.shade600,
                          size: 32,
                        ),
                      ),
                    ),
                  )
                : Center(
                    child: Icon(
                      Icons.star,
                      color: Colors.orange.shade600,
                      size: 32,
                    ),
                  ),
          ),

          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    kundliType.title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),

                  // Description
                  Expanded(
                    child: Text(
                      kundliType.description,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Download Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _onDownloadTap(context, kundliType),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        kundliType.getDownloadButtonText(),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onDownloadTap(BuildContext context, KundliTypeModel kundliType) {
    final l10n = AppLocalizations.of(context)!;

    if (kundliType.price == 0) {
      // Free download
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.downloading(kundliType.title)),
          backgroundColor: Colors.orange.shade600,
        ),
      );
    } else {
      // Paid purchase - navigate directly to payment screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => KundliPaymentScreen(kundliType: kundliType),
        ),
      );
    }
  }
}
