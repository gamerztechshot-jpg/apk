// features/pandit/screens/pandit_list_screen.dart
import 'package:flutter/material.dart';
import '../models/pandit_model.dart';
import '../services/pandit_service.dart';
import '../widgets/pandit_card.dart';
import 'pandit_detail_screen.dart';
import 'pandit_packages_list.dart';

class PanditListScreen extends StatefulWidget {
  const PanditListScreen({super.key});

  @override
  State<PanditListScreen> createState() => _PanditListScreenState();
}

class _PanditListScreenState extends State<PanditListScreen>
    with SingleTickerProviderStateMixin {
  final PanditService _panditService = PanditService();
  final TextEditingController _searchController = TextEditingController();

  List<PanditModel> _pandits = [];
  List<PanditModel> _filteredPandits = [];
  bool _isLoading = true;
  bool _isSearching = false;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadPandits();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _isSearching = _searchController.text.isNotEmpty;
      _filterPandits();
    });
  }

  void _filterPandits() {
    if (_searchController.text.isEmpty) {
      _filteredPandits = _pandits;
    } else {
      final query = _searchController.text.toLowerCase();
      _filteredPandits = _pandits.where((pandit) {
        return pandit.name.toLowerCase().contains(query) ||
            pandit.specializations.any(
              (spec) => spec.toLowerCase().contains(query),
            ) ||
            pandit.location.toLowerCase().contains(query);
      }).toList();
    }
  }

  Future<void> _loadPandits() async {
    try {
      setState(() => _isLoading = true);
      final pandits = await _panditService.getApprovedPandits();
      setState(() {
        _pandits = pandits;
        _filteredPandits = pandits;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading pandits: $e')));
      }
    }
  }

  Future<void> _refreshPandits() async {
    await _panditService.clearPanditCache();
    await _loadPandits();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Book Pandit Ji'),
        backgroundColor: Colors.orange.shade600,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicator: const UnderlineTabIndicator(
            borderSide: BorderSide(color: Colors.white, width: 3),
          ),
          indicatorSize: TabBarIndicatorSize.label,
          labelStyle: const TextStyle(fontWeight: FontWeight.w700),
          tabs: const [
            Tab(text: 'Pandit'),
            Tab(text: 'Packages'),
          ],
        ),
        // Removed reload icon per request
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Pandit tab (existing list + search)
          Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.white,
                child: Column(
                  children: [
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search pandits...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _isSearching
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _searchController.clear();
                                },
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _filteredPandits.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _refreshPandits,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredPandits.length,
                          itemBuilder: (context, index) {
                            final pandit = _filteredPandits[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: PanditCard(
                                pandit: pandit,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          PanditDetailScreen(pandit: pandit),
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        ),
                      ),
              ),
            ],
          ),
          // Packages tab (read-only list)
          const PanditPackagesList(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_search, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            _isSearching ? 'No pandits found' : 'No pandits available',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _isSearching
                ? 'Try adjusting your search terms'
                : 'Check back later for available pandits',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
          ),
          if (_isSearching) ...[
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                _searchController.clear();
              },
              child: const Text('Clear Search'),
            ),
          ],
        ],
      ),
    );
  }
}
