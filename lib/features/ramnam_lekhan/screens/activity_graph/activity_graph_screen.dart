// features/ramnam_lekhan/screens/activity_graph/activity_graph_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/services/language_service.dart';
import '../../../../core/services/daily_targets_service.dart';

class ActivityGraphScreen extends StatefulWidget {
  final DateTime? userRegistrationDate;

  const ActivityGraphScreen({super.key, this.userRegistrationDate});

  @override
  State<ActivityGraphScreen> createState() => _ActivityGraphScreenState();
}

class _ActivityGraphScreenState extends State<ActivityGraphScreen> {
  String _selectedPeriod = '7days';
  List<Map<String, dynamic>> _activityData = [];
  bool _isLoading = true;
  int _totalJapaInPeriod = 0;
  int _activeDaysInPeriod = 0;

  @override
  void initState() {
    super.initState();
    _loadActivityData();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadActivityData() async {
    setState(() {
      _isLoading = true;
    });

    final dailyTargetsService = Provider.of<DailyTargetsService>(
      context,
      listen: false,
    );
    final now = DateTime.now();
    DateTime startDate;

    switch (_selectedPeriod) {
      case '7days':
        startDate = now.subtract(const Duration(days: 7));
        break;
      case '1month':
        startDate = now.subtract(const Duration(days: 30));
        break;
      case '6months':
        startDate = now.subtract(const Duration(days: 180));
        break;
      case '1year':
        startDate = now.subtract(const Duration(days: 365));
        break;
      default:
        startDate = now.subtract(const Duration(days: 7));
    }

    // Ensure start date is not before user registration
    if (widget.userRegistrationDate != null &&
        startDate.isBefore(widget.userRegistrationDate!)) {
      startDate = widget.userRegistrationDate!;
    }

    try {
      final data = await dailyTargetsService.getDailyJapaData(startDate, now);

      if (mounted) {
        setState(() {
          _activityData = data;
          _totalJapaInPeriod = data.fold(
            0,
            (sum, item) => sum + ((item['japa_count'] as int?) ?? 0),
          );
          _activeDaysInPeriod = data
              .where((item) => ((item['japa_count'] as int?) ?? 0) > 0)
              .length;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _activityData = [];
          _totalJapaInPeriod = 0;
          _activeDaysInPeriod = 0;
          _isLoading = false;
        });
      }
    }
  }

  List<FlSpot> _getChartSpots() {
    return _activityData.asMap().entries.map((entry) {
      return FlSpot(
        entry.key.toDouble(),
        ((entry.value['japa_count'] as int?) ?? 0).toDouble(),
      );
    }).toList();
  }

  String _formatDate(String dateString) {
    final date = DateTime.parse(dateString);
    return '${date.day}/${date.month}';
  }

  String _formatNumber(int number) {
    if (number < 1000) {
      return number.toString();
    } else if (number < 100000) {
      // For thousands (10k, 20k, etc.)
      double kValue = number / 1000;
      if (kValue == kValue.toInt()) {
        return '${kValue.toInt()}k';
      } else {
        return '${kValue.toStringAsFixed(1)}k';
      }
    } else if (number < 10000000) {
      // For lakhs (1L, 2L, etc.)
      double lValue = number / 100000;
      if (lValue == lValue.toInt()) {
        return '${lValue.toInt()}L';
      } else {
        return '${lValue.toStringAsFixed(1)}L';
      }
    } else {
      // For crores (1C, 2C, etc.)
      double cValue = number / 10000000;
      if (cValue == cValue.toInt()) {
        return '${cValue.toInt()}C';
      } else {
        return '${cValue.toStringAsFixed(1)}C';
      }
    }
  }

  String _getPeriodTitle() {
    final languageService = Provider.of<LanguageService>(
      context,
      listen: false,
    );
    final isHindi = languageService.isHindi;

    switch (_selectedPeriod) {
      case '7days':
        return isHindi ? 'पिछले 7 दिन' : 'Last 7 Days';
      case '1month':
        return isHindi ? 'पिछले 30 दिन' : 'Last 30 Days';
      case '6months':
        return isHindi ? 'पिछले 6 महीने' : 'Last 6 Months';
      case '1year':
        return isHindi ? 'पिछले 365 दिन' : 'Last 365 Days';
      default:
        return isHindi ? 'पिछले 7 दिन' : 'Last 7 Days';
    }
  }

  @override
  Widget build(BuildContext context) {
    final languageService = Provider.of<LanguageService>(context);
    final isHindi = languageService.isHindi;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          isHindi ? 'सक्रियता ग्राफ' : 'Activity Graph',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.white,
            fontSize: 18,
          ),
        ),
        backgroundColor: const Color(0xFFFFB366),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _loadActivityData,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: isHindi ? 'रिफ्रेश करें' : 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  // Header section
                  Container(
                    width: double.infinity,
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          children: [
                            Text(
                              _getPeriodTitle(),
                              style: const TextStyle(
                                color: Color(0xFF2C3E50),
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildStatCard(
                                    isHindi ? 'कुल जाप' : 'Total Japa',
                                    _formatNumber(_totalJapaInPeriod),
                                    Icons.self_improvement_rounded,
                                    Colors.blue,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildStatCard(
                                    isHindi ? 'सक्रिय दिन' : 'Active Days',
                                    '$_activeDaysInPeriod',
                                    Icons.calendar_today_rounded,
                                    Colors.green,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Period selection
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isHindi ? 'अवधि चुनें' : 'Select Period',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2C3E50),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildPeriodButton(
                                '7days',
                                isHindi ? '7 दिन' : '7 Days',
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildPeriodButton(
                                '1month',
                                isHindi ? '1 महीना' : '1 Month',
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildPeriodButton(
                                '6months',
                                isHindi ? '6 महीने' : '6 Months',
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildPeriodButton(
                                '1year',
                                isHindi ? '1 साल' : '1 Year',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Chart section
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.all(20.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isHindi ? 'दैनिक जाप ग्राफ' : 'Daily Japa Graph',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2C3E50),
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 350,
                          child: _activityData.isEmpty
                              ? Center(
                                  child: Text(
                                    isHindi
                                        ? 'कोई डेटा नहीं मिला'
                                        : 'No data found',
                                    style: const TextStyle(
                                      color: Color(0xFF6C757D),
                                      fontSize: 16,
                                    ),
                                  ),
                                )
                              : LineChart(
                                  LineChartData(
                                    gridData: FlGridData(
                                      show: true,
                                      drawVerticalLine: false,
                                      horizontalInterval: 1,
                                      getDrawingHorizontalLine: (value) {
                                        return FlLine(
                                          color: const Color(0xFFE8F4FD),
                                          strokeWidth: 1.5,
                                          dashArray: [5, 5],
                                        );
                                      },
                                    ),
                                    titlesData: FlTitlesData(
                                      show: true,
                                      rightTitles: const AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: false,
                                        ),
                                      ),
                                      topTitles: const AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: false,
                                        ),
                                      ),
                                      bottomTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: true,
                                          reservedSize: 35,
                                          interval: _activityData.length > 10
                                              ? 2
                                              : 1,
                                          getTitlesWidget:
                                              (double value, TitleMeta meta) {
                                                if (value.toInt() <
                                                    _activityData.length) {
                                                  return Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 4,
                                                          vertical: 2,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: const Color(
                                                        0xFFF8F9FA,
                                                      ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            4,
                                                          ),
                                                    ),
                                                    child: Text(
                                                      _formatDate(
                                                        _activityData[value
                                                            .toInt()]['date'],
                                                      ),
                                                      style: const TextStyle(
                                                        color: Color(
                                                          0xFF495057,
                                                        ),
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        fontSize: 10,
                                                      ),
                                                    ),
                                                  );
                                                }
                                                return const Text('');
                                              },
                                        ),
                                      ),
                                      leftTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: true,
                                          interval: 1,
                                          getTitlesWidget:
                                              (double value, TitleMeta meta) {
                                                return Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 4,
                                                        vertical: 2,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: const Color(
                                                      0xFFF8F9FA,
                                                    ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          4,
                                                        ),
                                                  ),
                                                  child: Text(
                                                    _formatNumber(
                                                      value.toInt(),
                                                    ),
                                                    style: const TextStyle(
                                                      color: Color(0xFF495057),
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      fontSize: 10,
                                                    ),
                                                  ),
                                                );
                                              },
                                          reservedSize: 60,
                                        ),
                                      ),
                                    ),
                                    borderData: FlBorderData(
                                      show: true,
                                      border: Border.all(
                                        color: const Color(0xFFE8F4FD),
                                        width: 2,
                                      ),
                                    ),
                                    minX: 0,
                                    maxX: (_activityData.length - 1).toDouble(),
                                    minY: 0,
                                    maxY: _activityData.isNotEmpty
                                        ? _activityData
                                                  .map(
                                                    (e) =>
                                                        (e['japa_count']
                                                            as int?) ??
                                                        0,
                                                  )
                                                  .reduce(
                                                    (a, b) => a > b ? a : b,
                                                  )
                                                  .toDouble() *
                                              1.15
                                        : 10,
                                    lineTouchData: LineTouchData(
                                      enabled: true,
                                      touchTooltipData: LineTouchTooltipData(
                                        tooltipPadding: const EdgeInsets.all(
                                          16,
                                        ),
                                        tooltipMargin: 12,
                                        getTooltipItems:
                                            (
                                              List<LineBarSpot> touchedBarSpots,
                                            ) {
                                              return touchedBarSpots.map((
                                                barSpot,
                                              ) {
                                                final index = barSpot.x.toInt();
                                                if (index <
                                                    _activityData.length) {
                                                  final data =
                                                      _activityData[index];
                                                  final date = DateTime.parse(
                                                    data['date'],
                                                  );
                                                  final japaCount =
                                                      (data['japa_count']
                                                          as int?) ??
                                                      0;

                                                  return LineTooltipItem(
                                                    '${date.day}/${date.month}/${date.year}\n${isHindi ? 'जाप' : 'Japa'}: ${_formatNumber(japaCount)}',
                                                    const TextStyle(
                                                      color: Colors.white,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      fontSize: 13,
                                                      height: 1.4,
                                                    ),
                                                  );
                                                }
                                                return null;
                                              }).toList();
                                            },
                                      ),
                                      handleBuiltInTouches: true,
                                      getTouchedSpotIndicator:
                                          (
                                            LineChartBarData barData,
                                            List<int> spotIndexes,
                                          ) {
                                            return spotIndexes.map((spotIndex) {
                                              return TouchedSpotIndicatorData(
                                                FlLine(
                                                  color: const Color(
                                                    0xFFFF6B35,
                                                  ),
                                                  strokeWidth: 3,
                                                  dashArray: [3, 3],
                                                ),
                                                FlDotData(
                                                  getDotPainter:
                                                      (
                                                        spot,
                                                        percent,
                                                        barData,
                                                        index,
                                                      ) {
                                                        return FlDotCirclePainter(
                                                          radius: 8,
                                                          color: Colors.white,
                                                          strokeWidth: 4,
                                                          strokeColor:
                                                              const Color(
                                                                0xFFFF6B35,
                                                              ),
                                                        );
                                                      },
                                                ),
                                              );
                                            }).toList();
                                          },
                                    ),
                                    lineBarsData: [
                                      LineChartBarData(
                                        spots: _getChartSpots(),
                                        isCurved: true,
                                        curveSmoothness: 0.4,
                                        gradient: const LinearGradient(
                                          colors: [
                                            Color(0xFFFF6B35),
                                            Color(0xFFFFB366),
                                            Color(0xFFFFD93D),
                                          ],
                                          stops: [0.0, 0.6, 1.0],
                                        ),
                                        barWidth: 4,
                                        isStrokeCapRound: true,
                                        dotData: FlDotData(
                                          show: true,
                                          getDotPainter:
                                              (spot, percent, barData, index) {
                                                return FlDotCirclePainter(
                                                  radius: 5,
                                                  color: const Color(
                                                    0xFFFF6B35,
                                                  ),
                                                  strokeWidth: 3,
                                                  strokeColor: Colors.white,
                                                );
                                              },
                                        ),
                                        belowBarData: BarAreaData(
                                          show: true,
                                          gradient: const LinearGradient(
                                            colors: [
                                              Color(0xFFFF6B35),
                                              Color(0xFFFFB366),
                                              Color(0xFFFFD93D),
                                            ],
                                            stops: [0.0, 0.6, 1.0],
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                          ),
                                          applyCutOffY: true,
                                          cutOffY: 0,
                                        ),
                                        aboveBarData: BarAreaData(show: false),
                                      ),
                                    ],
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFF6C757D),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodButton(String period, String label) {
    final isSelected = _selectedPeriod == period;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPeriod = period;
        });
        _loadActivityData();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFB366) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFFFB366)
                : const Color(0xFFE9ECEF),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : const Color(0xFF6C757D),
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
