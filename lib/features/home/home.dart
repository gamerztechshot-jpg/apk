// features/home/home.dart
import 'package:flutter/material.dart';
import 'package:karmasu/l10n/app_localizations.dart';
import '../dharma_store/screens/store_home_screen.dart';
import '../puja_booking/puja_list.dart';
import '../teacher/views/acharya_screen.dart';
import 'explore_tab.dart';
import 'home_content.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  late AnimationController _gradientController;
  late Animation<double> _gradientAnimation;

  final List<Widget> _screens = [
    const HomeContent(),
    const ExploreScreen(),
    const AcharyaScreen(),
    const StoreHomeScreen(),
    const PujaListScreen(hideBackButton: true),
  ];

  @override
  void initState() {
    super.initState();
    _gradientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
    _gradientAnimation =
        Tween<double>(begin: 0.0, end: 1.0).animate(_gradientController);
  }

  @override
  void dispose() {
    _gradientController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Theme(
          data: Theme.of(context).copyWith(
            bottomNavigationBarTheme: BottomNavigationBarThemeData(
              selectedLabelStyle: const TextStyle(fontSize: 11),
              unselectedLabelStyle: const TextStyle(fontSize: 10),
            ),
          ),
          child: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            currentIndex: _currentIndex,
            onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          selectedItemColor: Colors.orange.shade600,
          unselectedItemColor: Colors.grey.shade600,
          backgroundColor: Colors.white,
          elevation: 0,
          items: [
            _navItem(Icons.home, l10n.home),
            _navItem(Icons.supervisor_account, l10n.localeName == 'hi' ? 'पुरोहित' : 'Purohit'),
            BottomNavigationBarItem(
              icon: _buildAnimatedGurukulIcon(false),
              activeIcon: _buildAnimatedGurukulIcon(true),
              label: l10n.gururkul,
            ),
            _navItem(Icons.store, l10n.store),
            _navItem(Icons.temple_hindu, l10n.pujaPath),
          ],
          ),
        ),
      ),
    );
  }

  BottomNavigationBarItem _navItem(IconData icon, String label) {
    return BottomNavigationBarItem(
      icon: Icon(icon),
      label: label,
    );
  }

  Widget _buildAnimatedGurukulIcon(bool isSelected) {
    return AnimatedBuilder(
      animation: _gradientController,
      builder: (context, child) {
        final value = _gradientAnimation.value;
        final angle = value * 2 * 3.14159;

        return Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: SweepGradient(
                  startAngle: angle,
                  endAngle: angle + 3.14159,
                  colors: [
                    Colors.orange.shade600,
                    Colors.white,
                    Colors.orange.shade600,
                    Colors.white,
                    Colors.orange.shade600,
                  ],
                  stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.orange.withOpacity(0.5),
                    spreadRadius: 2,
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
            Icon(
              Icons.school,
              color: isSelected ? Colors.orange.shade600 : Colors.grey.shade700,
              size: 24,
            ),
          ],
        );
      },
    );
  }
}
