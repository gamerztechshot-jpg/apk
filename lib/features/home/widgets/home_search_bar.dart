// features/home/widgets/home_search_bar.dart
import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';

class HomeSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final AppLocalizations l10n;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;

  const HomeSearchBar({
    super.key,
    required this.controller,
    required this.l10n,
    this.onChanged,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final horizontalMargin = isTablet ? 40.0 : 20.0;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: horizontalMargin, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: l10n.searchPlaceholder,
          hintStyle: TextStyle(
            color: Colors.grey.shade400,
            fontSize: isTablet ? 16 : 14,
          ),
          prefixIcon: Icon(
            Icons.search,
            color: Colors.grey.shade400,
            size: isTablet ? 24 : 20,
          ),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    Icons.clear,
                    color: Colors.grey.shade400,
                    size: isTablet ? 24 : 20,
                  ),
                  onPressed: onClear,
                )
              : null,
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: isTablet ? 24 : 20,
            vertical: isTablet ? 18 : 15,
          ),
        ),
        onChanged: onChanged,
      ),
    );
  }
}
