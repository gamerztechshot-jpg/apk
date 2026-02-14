// core/widgets/cache_test_widget.dart
import 'package:flutter/material.dart';
import '../services/cache_test_service.dart';
import '../services/cache_service.dart';
import '../services/panchang_service.dart';

/// Widget to test caching functionality (for development/debugging)
class CacheTestWidget extends StatefulWidget {
  final String? userId;

  const CacheTestWidget({super.key, this.userId});

  @override
  State<CacheTestWidget> createState() => _CacheTestWidgetState();
}

class _CacheTestWidgetState extends State<CacheTestWidget> {
  bool _isLoading = false;
  String _testResults = '';
  Map<String, dynamic> _cacheStats = {};

  @override
  void initState() {
    super.initState();
    _loadCacheStats();
  }

  Future<void> _loadCacheStats() async {
    final stats = await CacheService.getCacheStats();
    setState(() {
      _cacheStats = stats;
    });
  }

  Future<void> _runBasicTests() async {
    setState(() {
      _isLoading = true;
      _testResults = '';
    });

    try {
      await CacheTestService.testBasicCache();
      await _loadCacheStats();
      setState(() {
        _testResults = 'Basic cache tests completed successfully!';
      });
    } catch (e) {
      setState(() {
        _testResults = 'Basic cache tests failed: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _runUserTests() async {
    if (widget.userId == null) {
      setState(() {
        _testResults = 'User ID required for user-specific tests';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _testResults = '';
    });

    try {
      await CacheTestService.testUserCache(widget.userId!);
      await _loadCacheStats();
      setState(() {
        _testResults = 'User cache tests completed successfully!';
      });
    } catch (e) {
      setState(() {
        _testResults = 'User cache tests failed: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _runAllTests() async {
    setState(() {
      _isLoading = true;
      _testResults = '';
    });

    try {
      await CacheTestService.runAllTests(userId: widget.userId);
      await _loadCacheStats();
      setState(() {
        _testResults = 'All cache tests completed successfully!';
      });
    } catch (e) {
      setState(() {
        _testResults = 'All cache tests failed: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _runPerformanceTest() async {
    setState(() {
      _isLoading = true;
      _testResults = '';
    });

    try {
      await CacheTestService.performanceTest();
      setState(() {
        _testResults = 'Performance test completed successfully!';
      });
    } catch (e) {
      setState(() {
        _testResults = 'Performance test failed: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _clearAllCache() async {
    setState(() {
      _isLoading = true;
      _testResults = '';
    });

    try {
      await CacheService.clearAllCache();
      await _loadCacheStats();
      setState(() {
        _testResults = 'All cache cleared successfully!';
      });
    } catch (e) {
      setState(() {
        _testResults = 'Failed to clear cache: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testPanchangCache() async {
    setState(() {
      _isLoading = true;
      _testResults = '';
    });

    try {
      final panchangService = PanchangService();

      // Test the caching fix
      await panchangService.testCachingFix();

      // Test English panchang

      final englishData = await panchangService.fetchPanchangData(false);

      // Test Hindi panchang

      final hindiData = await panchangService.fetchPanchangData(true);

      // Get cache stats
      final stats = await panchangService.getPanchangCacheStats();

      await _loadCacheStats();
      setState(() {
        _testResults =
            'Panchang cache test completed!\n'
            'English: ${englishData.length} entries\n'
            'Hindi: ${hindiData.length} entries\n'
            'Cache Stats: $stats\n'
            'Check console for detailed test results.';
      });
    } catch (e) {
      setState(() {
        _testResults = 'Panchang cache test failed: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cache Test'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Cache Statistics Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Cache Statistics',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('Total Entries: ${_cacheStats['total_entries'] ?? 0}'),
                    Text('Valid Entries: ${_cacheStats['valid_entries'] ?? 0}'),
                    Text(
                      'Expired Entries: ${_cacheStats['expired_entries'] ?? 0}',
                    ),
                    Text(
                      'Timestamp Entries: ${_cacheStats['timestamp_entries'] ?? 0}',
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: _loadCacheStats,
                      child: const Text('Refresh Stats'),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Test Buttons
            const Text(
              'Cache Tests',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton(
                  onPressed: _isLoading ? null : _runBasicTests,
                  child: const Text('Basic Tests'),
                ),
                ElevatedButton(
                  onPressed: _isLoading ? null : _runUserTests,
                  child: const Text('User Tests'),
                ),
                ElevatedButton(
                  onPressed: _isLoading ? null : _runAllTests,
                  child: const Text('All Tests'),
                ),
                ElevatedButton(
                  onPressed: _isLoading ? null : _runPerformanceTest,
                  child: const Text('Performance'),
                ),
                ElevatedButton(
                  onPressed: _isLoading ? null : _testPanchangCache,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Panchang Cache'),
                ),
                ElevatedButton(
                  onPressed: _isLoading ? null : _clearAllCache,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Clear Cache'),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Test Results
            if (_testResults.isNotEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Test Results',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(_testResults),
                    ],
                  ),
                ),
              ),

            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(),
                ),
              ),

            const Spacer(),

            // Info
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Cache Implementation Info',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'This widget tests the caching implementation to ensure it\'s working correctly. '
                      'Check the console for detailed test logs.',
                      style: TextStyle(fontSize: 14),
                    ),
                    if (widget.userId != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Testing with User ID: ${widget.userId}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
