// features/pandit/screens/my_family_pandit_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/pandit_service.dart';

class MyFamilyPanditScreen extends StatefulWidget {
  const MyFamilyPanditScreen({super.key});

  @override
  State<MyFamilyPanditScreen> createState() => _MyFamilyPanditScreenState();
}

class _MyFamilyPanditScreenState extends State<MyFamilyPanditScreen> {
  Map<String, dynamic>? _pandit;
  bool _loading = true;
  String? _error;
  final PanditService _panditService = PanditService();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool forceRefresh = false}) async {
    try {
      final auth = context.read<AuthService>();
      final user = auth.getCurrentUser();

      if (user == null) {
        setState(() {
          _error = 'Not logged in';
          _loading = false;
        });
        return;
      }

      // Use the cached pandit service
      final panditData = await _panditService.fetchAssignedPanditForUser(
        user.id,
        forceRefresh: forceRefresh,
      );

      setState(() {
        _pandit = panditData;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Family Pandit'),
        centerTitle: true,
        backgroundColor: Colors.orange.shade600,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _loading = true;
                _error = null;
                _pandit = null;
              });
              _load(forceRefresh: true);
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(_error!),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _loading = true;
                        _error = null;
                        _pandit = null;
                      });
                      _load(forceRefresh: true);
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          : _pandit == null
          ? _buildNoPanditAssigned()
          : _buildPanditDetails(_pandit!),
    );
  }

  Widget _buildNoPanditAssigned() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.self_improvement, size: 56, color: Colors.orange),
            const SizedBox(height: 12),
            Text(
              _isHindi
                  ? 'अभी कोई परिवार पंडित असाइन नहीं है'
                  : 'No Family Pandit assigned yet',
              style: const TextStyle(
                fontSize: 18,
                color: Colors.black87,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            _buildBilingualText(
              'Book your Family Pandit to get guidance for rituals and pujas.',
              'अपने परिवार के पंडित को बुक करें और पूजा/व्रत में मार्गदर्शन पाएं।',
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).maybePop();
              },
              icon: const Icon(Icons.volunteer_activism),
              label: Text(
                _isHindi ? 'फैमिली पंडित बुक करें' : 'Book Family Pandit',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPanditDetails(Map<String, dynamic> pandit) {
    final String name = pandit['name']?.toString() ?? 'Unknown';
    final String bio = pandit['bio']?.toString() ?? '';
    final int exp = _safeParseInt(pandit['experience_years']) ?? 0;
    final int validityDays = _safeParseInt(pandit['validity_days']) ?? 0;
    final String imageUrl = pandit['photo_url']?.toString() ?? '';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Single attractive card
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.orange.shade50, Colors.white],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
              border: Border.all(color: Colors.orange.shade100),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.orange.shade200,
                            width: 2,
                          ),
                        ),
                        child: ClipOval(
                          child: imageUrl.isNotEmpty
                              ? Image.network(
                                  imageUrl,
                                  fit: BoxFit.cover,
                                  loadingBuilder:
                                      (context, child, loadingProgress) {
                                        if (loadingProgress == null)
                                          return child;
                                        return const Center(
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        );
                                      },
                                  errorBuilder: (context, _, __) => Icon(
                                    Icons.person,
                                    color: Colors.orange.shade600,
                                    size: 40,
                                  ),
                                )
                              : Icon(
                                  Icons.person,
                                  color: Colors.orange.shade600,
                                  size: 40,
                                ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 6),
                            if (exp > 0)
                              Text(
                                exp.toString() + ' years experience',
                                style: TextStyle(color: Colors.grey.shade700),
                              ),
                            const SizedBox(height: 8),
                            if (validityDays > 0)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.orange.shade50,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: Colors.orange.shade200,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.calendar_month,
                                      size: 16,
                                      color: Colors.orange.shade800,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Validity: ' +
                                          validityDays.toString() +
                                          ' days',
                                      style: TextStyle(
                                        color: Colors.orange.shade800,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (bio.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.orange.shade600),
                        const SizedBox(width: 8),
                        const Text(
                          'About',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(bio, style: const TextStyle(fontSize: 15)),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Removed old info tile (now integrated into the single card)

  // Safe int parse for dynamic values
  int? _safeParseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  // Bilingual helper (simple toggle based on locale.languageCode == 'hi')
  bool get _isHindi =>
      Localizations.localeOf(context).languageCode.toLowerCase() == 'hi';

  Widget _buildBilingualText(String en, String hi) {
    return Text(
      _isHindi ? hi : en,
      textAlign: TextAlign.center,
      style: const TextStyle(fontSize: 13, color: Colors.grey),
    );
  }
}
