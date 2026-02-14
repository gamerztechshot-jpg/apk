// features/home/widgets/home_header.dart
import 'package:flutter/material.dart';
import '../../../core/widgets/cached_network_image_widget.dart';
import '../../../l10n/app_localizations.dart';
import '../../notifications/notifications_screen.dart';
import '../../profile/profile.dart';

class HomeHeader extends StatelessWidget {
  final String userName;
  final String? profileImageUrl;
  final AppLocalizations l10n;

  const HomeHeader({
    super.key,
    required this.userName,
    required this.profileImageUrl,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    // Responsive sizing based on screen dimensions
    final horizontalPadding = isTablet ? 40.0 : 20.0;
    final profileSize = screenWidth * 0.12; // 12% of screen width
    final fontSize = screenWidth * 0.045; // 4.5% of screen width for text
    final iconSize = screenWidth * 0.06; // 6% of screen width for icons

    return SafeArea(
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: horizontalPadding,
          vertical: 16,
        ),
        child: Row(
          children: [
            const SizedBox(width: 8),
            // Profile Icon - Clickable to open profile drawer
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProfileScreen(),
                  ),
                );
              },
              child: Container(
                width: profileSize,
                height: profileSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.orange.shade100,
                  border: Border.all(color: Colors.orange.shade300, width: 2),
                ),
                child: profileImageUrl != null
                    ? ClipOval(
                        child: CachedNetworkImageWidget(
                          imageUrl: profileImageUrl!,
                          width: profileSize,
                          height: profileSize,
                          fit: BoxFit.cover,
                          cacheDuration: const Duration(hours: 12),
                          placeholder: Container(
                            width: profileSize,
                            height: profileSize,
                            color: Colors.grey.shade200,
                            child: Icon(
                              Icons.person,
                              color: Colors.grey.shade400,
                              size: profileSize * 0.6,
                            ),
                          ),
                          errorWidget: Icon(
                            Icons.person,
                            color: Colors.orange.shade600,
                            size: profileSize * 0.6,
                          ),
                        ),
                      )
                    : Icon(
                        Icons.person,
                        color: Colors.orange.shade600,
                        size: profileSize * 0.6,
                      ),
              ),
            ),
            SizedBox(width: isTablet ? 20 : 16),
            // User Name and Greeting
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Namaste $userName',
                    style: TextStyle(
                      fontSize: fontSize,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    l10n.radheRadhe,
                    style: TextStyle(
                      fontSize: fontSize * 0.7,
                      color: Colors.grey,
                      fontStyle: FontStyle.italic,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // Notifications
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NotificationsScreen(),
                  ),
                );
              },
              child: Container(
                padding: EdgeInsets.all(isTablet ? 10 : 8),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.notifications_outlined,
                  color: Colors.orange.shade600,
                  size: iconSize,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
