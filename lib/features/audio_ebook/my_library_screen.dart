// features/audio_ebook/my_library_screen.dart
import 'package:flutter/material.dart';
import '../../core/models/audio_ebook_model.dart';
import '../../core/services/audio_ebook_access_service.dart';
import '../../core/services/audio_ebook_service.dart';
import 'audio_ebook_detail_screen.dart';

class MyLibraryScreen extends StatefulWidget {
  final String userId;

  const MyLibraryScreen({super.key, required this.userId});

  @override
  State<MyLibraryScreen> createState() => _MyLibraryScreenState();
}

class _MyLibraryScreenState extends State<MyLibraryScreen>
    with SingleTickerProviderStateMixin {
  final AudioEbookAccessService _accessService = AudioEbookAccessService();
  final AudioEbookService _audioEbookService = AudioEbookService();

  late TabController _tabController;
  List<AudioEbookModel> _purchasedAudios = [];
  List<AudioEbookModel> _purchasedEbooks = [];
  Map<String, dynamic> _accessSummary = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadLibraryData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadLibraryData() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Fetch all audio/ebook data
      final allData = await _audioEbookService.fetchAllData();
      final allAudios = allData['audiobooks'] ?? <AudioEbookModel>[];
      final allEbooks = allData['ebooks'] ?? <AudioEbookModel>[];

      // Get purchased items
      final purchasedAudios = await _accessService.getPurchasedItems(
        userId: widget.userId,
        allItems: allAudios,
      );

      final purchasedEbooks = await _accessService.getPurchasedItems(
        userId: widget.userId,
        allItems: allEbooks,
      );

      // Get access summary
      final accessSummary = await _accessService.getAccessSummary(
        userId: widget.userId,
        allItems: [...allAudios, ...allEbooks],
      );

      setState(() {
        _purchasedAudios = purchasedAudios;
        _purchasedEbooks = purchasedEbooks;
        _accessSummary = accessSummary;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Failed to load library data');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _navigateToAudioDetail(AudioEbookModel audio) {
    // For paid/purchased audios, redirect to description screen first
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AudioEbookDetailScreen(item: audio),
      ),
    );
  }

  void _navigateToEbookDetail(AudioEbookModel ebook) {
    // For paid/purchased ebooks, redirect to description screen first
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AudioEbookDetailScreen(item: ebook),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('My Library'),
        backgroundColor: Colors.orange.shade600,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.audiotrack), text: 'Audios'),
            Tab(icon: Icon(Icons.book), text: 'Ebooks'),
          ],
        ),
      ),
      body: _isLoading ? _buildLoadingWidget() : _buildLibraryContent(),
    );
  }

  Widget _buildLoadingWidget() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Loading your library...'),
        ],
      ),
    );
  }

  Widget _buildLibraryContent() {
    return Column(
      children: [
        _buildLibrarySummary(),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [_buildAudioLibrary(), _buildEbookLibrary()],
          ),
        ),
      ],
    );
  }

  Widget _buildLibrarySummary() {
    final totalPurchased = _accessSummary['purchased_items'] ?? 0;
    final totalAccessible = _accessSummary['accessible_items'] ?? 0;
    final totalItems = _accessSummary['total_items'] ?? 0;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.orange.shade50, Colors.orange.shade100],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildSummaryItem(
              icon: Icons.library_books,
              title: 'Total Items',
              value: totalItems.toString(),
              color: Colors.blue,
            ),
          ),
          Expanded(
            child: _buildSummaryItem(
              icon: Icons.check_circle,
              title: 'Purchased',
              value: totalPurchased.toString(),
              color: Colors.green,
            ),
          ),
          Expanded(
            child: _buildSummaryItem(
              icon: Icons.accessibility,
              title: 'Accessible',
              value: totalAccessible.toString(),
              color: Colors.purple,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          title,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildAudioLibrary() {
    if (_purchasedAudios.isEmpty) {
      return _buildEmptyState(
        icon: Icons.audiotrack,
        title: 'No Purchased Audios',
        subtitle: 'Your purchased audio content will appear here',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadLibraryData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _purchasedAudios.length,
        itemBuilder: (context, index) {
          final audio = _purchasedAudios[index];
          return _buildAudioItem(audio);
        },
      ),
    );
  }

  Widget _buildEbookLibrary() {
    if (_purchasedEbooks.isEmpty) {
      return _buildEmptyState(
        icon: Icons.book,
        title: 'No Purchased Ebooks',
        subtitle: 'Your purchased ebook content will appear here',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadLibraryData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _purchasedEbooks.length,
        itemBuilder: (context, index) {
          final ebook = _purchasedEbooks[index];
          return _buildEbookItem(ebook);
        },
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAudioItem(AudioEbookModel audio) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: audio.displayImage.isNotEmpty
              ? Image.network(
                  audio.displayImage,
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 60,
                      height: 60,
                      color: Colors.blue.shade100,
                      child: Icon(
                        Icons.audiotrack,
                        color: Colors.blue.shade600,
                        size: 30,
                      ),
                    );
                  },
                )
              : Container(
                  width: 60,
                  height: 60,
                  color: Colors.blue.shade100,
                  child: Icon(
                    Icons.audiotrack,
                    color: Colors.blue.shade600,
                    size: 30,
                  ),
                ),
        ),
        title: Text(
          audio.title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              audio.category,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.headphones, size: 16, color: Colors.grey.shade500),
                const SizedBox(width: 4),
                Text(
                  audio.countText,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
              ],
            ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.green.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle, size: 14, color: Colors.green.shade700),
              const SizedBox(width: 4),
              Text(
                'PURCHASED',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade700,
                ),
              ),
            ],
          ),
        ),
        onTap: () => _navigateToAudioDetail(audio),
      ),
    );
  }

  Widget _buildEbookItem(AudioEbookModel ebook) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: ebook.displayImage.isNotEmpty
              ? Image.network(
                  ebook.displayImage,
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 60,
                      height: 60,
                      color: Colors.green.shade100,
                      child: Icon(
                        Icons.book,
                        color: Colors.green.shade600,
                        size: 30,
                      ),
                    );
                  },
                )
              : Container(
                  width: 60,
                  height: 60,
                  color: Colors.green.shade100,
                  child: Icon(
                    Icons.book,
                    color: Colors.green.shade600,
                    size: 30,
                  ),
                ),
        ),
        title: Text(
          ebook.title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              ebook.category,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.visibility, size: 16, color: Colors.grey.shade500),
                const SizedBox(width: 4),
                Text(
                  ebook.countText,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
              ],
            ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.green.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle, size: 14, color: Colors.green.shade700),
              const SizedBox(width: 4),
              Text(
                'PURCHASED',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade700,
                ),
              ),
            ],
          ),
        ),
        onTap: () => _navigateToEbookDetail(ebook),
      ),
    );
  }
}
