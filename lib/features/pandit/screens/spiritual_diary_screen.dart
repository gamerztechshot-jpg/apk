// features/pandit/screens/spiritual_diary_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/spiritual_diary_service.dart';
import '../widgets/spiritual_activity_card.dart';
import '../widgets/spiritual_stats_card.dart';
import '../../../core/services/auth_service.dart';

class SpiritualDiaryScreen extends StatefulWidget {
  const SpiritualDiaryScreen({super.key});

  @override
  State<SpiritualDiaryScreen> createState() => _SpiritualDiaryScreenState();
}

class _SpiritualDiaryScreenState extends State<SpiritualDiaryScreen> {
  final SpiritualDiaryService _diaryService = SpiritualDiaryService();

  List<Map<String, dynamic>> _activities = [];
  Map<String, dynamic> _stats = {};
  bool _isLoading = true;
  String _selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    _loadSpiritualDiary();
  }

  Future<void> _loadSpiritualDiary() async {
    try {
      setState(() => _isLoading = true);

      // Get current user ID from auth service
      final authService = Provider.of<AuthService>(context, listen: false);
      final currentUser = authService.getCurrentUser();

      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      final userId = currentUser.id;

      final activities = await _diaryService.getSpiritualDiaryActivities(
        userId,
      );
      final stats = await _diaryService.getSpiritualDiaryStats(userId);

      setState(() {
        _activities = activities;
        _stats = stats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading spiritual diary: $e')),
        );
      }
    }
  }

  Future<void> _refreshDiary() async {
    // Get current user ID from auth service
    final authService = Provider.of<AuthService>(context, listen: false);
    final currentUser = authService.getCurrentUser();

    if (currentUser != null) {
      await _diaryService.clearSpiritualDiaryCache(currentUser.id);
    }

    await _loadSpiritualDiary();
  }

  List<Map<String, dynamic>> get _filteredActivities {
    if (_selectedFilter == 'All') {
      return _activities;
    }
    return _activities
        .where((activity) => activity['type'] == _selectedFilter)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Digital Spiritual Diary'),
        backgroundColor: Colors.orange.shade600,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _refreshDiary),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Stats Section
                if (_stats.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    child: SpiritualStatsCard(stats: _stats),
                  ),
                // Filter Section
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip('All'),
                        const SizedBox(width: 8),
                        _buildFilterChip('naam_japa'),
                        const SizedBox(width: 8),
                        _buildFilterChip('puja_booked'),
                        const SizedBox(width: 8),
                        _buildFilterChip('audio_ebook_purchased'),
                      ],
                    ),
                  ),
                ),
                // Activities List
                Expanded(
                  child: _filteredActivities.isEmpty
                      ? _buildEmptyState()
                      : RefreshIndicator(
                          onRefresh: _refreshDiary,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _filteredActivities.length,
                            itemBuilder: (context, index) {
                              final activity = _filteredActivities[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: SpiritualActivityCard(
                                  activity: activity,
                                ),
                              );
                            },
                          ),
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildFilterChip(String filter) {
    final isSelected = _selectedFilter == filter;
    final displayName = _getFilterDisplayName(filter);

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = filter;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.orange.shade600 : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          displayName,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey.shade700,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  String _getFilterDisplayName(String filter) {
    switch (filter) {
      case 'All':
        return 'सभी';
      case 'naam_japa':
        return 'Naam Japa';
      case 'puja_booked':
        return 'Puja Booked';
      case 'audio_ebook_purchased':
        return 'Audio/Ebook';
      default:
        return filter;
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.book_outlined, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            _selectedFilter == 'All'
                ? 'No spiritual activities yet'
                : 'No ${_getFilterDisplayName(_selectedFilter).toLowerCase()} activities',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _selectedFilter == 'All'
                ? 'Start your spiritual journey by performing naam japa, booking pujas, or purchasing spiritual content'
                : 'Try selecting a different filter or start your spiritual journey',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              // Navigate to relevant screens
              Navigator.pop(context);
            },
            icon: const Icon(Icons.explore),
            label: const Text('Explore Spiritual Content'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange.shade600,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
