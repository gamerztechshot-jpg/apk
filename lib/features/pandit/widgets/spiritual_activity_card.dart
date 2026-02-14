// features/pandit/widgets/spiritual_activity_card.dart
import 'package:flutter/material.dart';

class SpiritualActivityCard extends StatelessWidget {
  final Map<String, dynamic> activity;

  const SpiritualActivityCard({super.key, required this.activity});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Activity Icon
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: _getActivityColor().withOpacity(0.1),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: _getActivityColor().withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: Icon(
                _getActivityIcon(),
                color: _getActivityColor(),
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            // Activity Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    activity['title'] as String? ?? 'Spiritual Activity',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Description
                  Text(
                    activity['description'] as String? ?? '',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  // Date and Additional Info
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 14,
                        color: Colors.grey.shade500,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatDate(activity['date'] as String?),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                      const Spacer(),
                      // Activity Type Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getActivityColor().withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _getActivityColor().withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          _getActivityTypeText(),
                          style: TextStyle(
                            fontSize: 11,
                            color: _getActivityColor(),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  // Additional details based on activity type
                  if (_hasAdditionalDetails()) ...[
                    const SizedBox(height: 8),
                    _buildAdditionalDetails(),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getActivityColor() {
    switch (activity['type']) {
      case 'naam_japa':
        return Colors.blue.shade600;
      case 'puja_booked':
        return Colors.orange.shade600;
      case 'audio_ebook_purchased':
        return Colors.purple.shade600;
      default:
        return Colors.grey.shade600;
    }
  }

  IconData _getActivityIcon() {
    switch (activity['type']) {
      case 'naam_japa':
        return Icons.self_improvement;
      case 'puja_booked':
        return Icons.temple_hindu;
      case 'audio_ebook_purchased':
        return Icons.headphones;
      default:
        return Icons.book;
    }
  }

  String _getActivityTypeText() {
    switch (activity['type']) {
      case 'naam_japa':
        return 'Naam Japa';
      case 'puja_booked':
        return 'Puja Booked';
      case 'audio_ebook_purchased':
        return 'Audio/Ebook';
      default:
        return 'Activity';
    }
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'Unknown date';

    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date).inDays;

      if (difference == 0) {
        return 'Today';
      } else if (difference == 1) {
        return 'Yesterday';
      } else if (difference < 7) {
        return '$difference days ago';
      } else {
        return '${date.day}/${date.month}/${date.year}';
      }
    } catch (e) {
      return dateString;
    }
  }

  bool _hasAdditionalDetails() {
    return activity['count'] != null ||
        activity['amount'] != null ||
        activity['item_title'] != null;
  }

  Widget _buildAdditionalDetails() {
    final details = <Widget>[];

    // Naam Japa count
    if (activity['count'] != null) {
      details.add(
        Row(
          children: [
            Icon(Icons.repeat, size: 12, color: Colors.blue.shade600),
            const SizedBox(width: 4),
            Text(
              '${activity['count']} repetitions',
              style: TextStyle(
                fontSize: 11,
                color: Colors.blue.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    // Amount for puja or purchase
    if (activity['amount'] != null) {
      details.add(
        Row(
          children: [
            Icon(Icons.currency_rupee, size: 12, color: Colors.green.shade600),
            const SizedBox(width: 4),
            Text(
              '₹${activity['amount']}',
              style: TextStyle(
                fontSize: 11,
                color: Colors.green.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    // Item title for audio/ebook
    if (activity['item_title'] != null) {
      details.add(
        Row(
          children: [
            Icon(Icons.title, size: 12, color: Colors.purple.shade600),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                activity['item_title'] as String,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.purple.shade600,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: details,
    );
  }
}


