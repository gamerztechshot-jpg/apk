// features/ramnam_lekhan/screens/deity_writing/deity_writing_screen.dart
import 'package:flutter/material.dart';
import 'package:karmasu/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import '../../../../core/services/language_service.dart';
import '../../../../core/services/mantra_service.dart';
import '../../models/deity_model.dart';
import '../../models/mantra_model.dart';
import '../mantras/mantras_screen.dart';

class DeityWritingScreen extends StatefulWidget {
  final DeityModel deity;

  const DeityWritingScreen({super.key, required this.deity});

  @override
  State<DeityWritingScreen> createState() => _DeityWritingScreenState();
}

class _DeityWritingScreenState extends State<DeityWritingScreen> {
  final TextEditingController _writingController = TextEditingController();
  final MantraService _mantraService = MantraService();

  int _wordCount = 0;
  bool _isWriting = false;
  List<MantraModel> _deityMantras = [];
  bool _isLoadingMantras = true;

  @override
  void initState() {
    super.initState();
    _writingController.addListener(_updateWordCount);
    _checkForMantras();
  }

  /// Check if this deity has any mantras in the database
  Future<void> _checkForMantras() async {
    try {
      _deityMantras = await _mantraService.getMantrasByDeity(widget.deity.id);
      setState(() {
        _isLoadingMantras = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingMantras = false;
      });
    }
  }

  @override
  void dispose() {
    _writingController.removeListener(_updateWordCount);
    _writingController.dispose();
    super.dispose();
  }

  void _updateWordCount() {
    setState(() {
      _wordCount = _writingController.text
          .trim()
          .split(RegExp(r'\s+'))
          .where((word) => word.isNotEmpty)
          .length;
    });
  }

  void _startWriting() {
    setState(() {
      _isWriting = true;
    });
  }

  void _saveWriting(bool isHindi) {
    // TODO: Implement save functionality
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          l10n.writingSavedFor(
            isHindi ? widget.deity.hindiName : widget.deity.englishName,
          ),
        ),
        backgroundColor: const Color(0xFFFFB366),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 🌍 Get localization and language service
    final l10n = AppLocalizations.of(context)!;
    final languageService = Provider.of<LanguageService>(context);
    final isHindi = languageService.isHindi;

    // Show loading while checking for mantras
    if (_isLoadingMantras) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            isHindi ? widget.deity.hindiName : widget.deity.englishName,
          ),
          backgroundColor: const Color(0xFFFFB366),
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFFB366)),
          ),
        ),
      );
    }

    // Generic redirect: if this deity has any mantras, go to Mantras screen
    if (_deityMantras.isNotEmpty) {
      final String category = _deityMantras.first.category;
      return MantrasScreen(initialCategory: category);
    }
    final isDurga = widget.deity.id == 'durga';
    final isGanesha = widget.deity.id == 'ganesha';
    final isHanuman = widget.deity.id == 'hanuman';
    final isKrishna = widget.deity.id == 'krishna';
    final isLakshmi = widget.deity.id == 'lakshmi';
    final isNarasimha = widget.deity.id == 'narasimha';
    final isParvati = widget.deity.id == 'parvati';
    final isRadha = widget.deity.id == 'radha';
    final isRam = widget.deity.id == 'ram';
    final isSaraswati = widget.deity.id == 'saraswati';
    final isShani = widget.deity.id == 'shani';
    final isShiva = widget.deity.id == 'shiv';
    final isSita = widget.deity.id == 'sita';
    final isVishnu = widget.deity.id == 'vishnu';

    // If it's Durga, Ganesha, Hanuman, Krishna, Lakshmi, Narasimha, Parvati, Radha, Ram, Saraswati, Shani, Shiva, Sita, or Vishnu, show only mantras
    if (isDurga ||
        isGanesha ||
        isHanuman ||
        isKrishna ||
        isLakshmi ||
        isNarasimha ||
        isParvati ||
        isRadha ||
        isRam ||
        isSaraswati ||
        isShani ||
        isShiva ||
        isSita ||
        isVishnu) {
      String category = 'All';
      if (isDurga) {
        category = 'Durga';
      } else if (isGanesha) {
        category = 'Ganesha';
      } else if (isHanuman) {
        category = 'Hanuman';
      } else if (isKrishna) {
        category = 'Krishna';
      } else if (isLakshmi) {
        category = 'Lakshmi';
      } else if (isNarasimha) {
        category = 'Narasimha';
      } else if (isParvati) {
        category = 'Parvati';
      } else if (isRadha) {
        category = 'Radha';
      } else if (isRam) {
        category = 'Ram';
      } else if (isSaraswati) {
        category = 'Saraswati';
      } else if (isShani) {
        category = 'Shani';
      } else if (isShiva) {
        category = 'Shiv';
      } else if (isSita) {
        category = 'Sita';
      } else if (isVishnu) {
        category = 'Vishnu';
      }

      return MantrasScreen(initialCategory: category);
    }

    // For other deities, show the writing functionality
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          isHindi ? widget.deity.hindiName : widget.deity.englishName,
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
          if (_isWriting)
            IconButton(
              icon: const Icon(Icons.save_rounded),
              onPressed: () => _saveWriting(isHindi),
            ),
        ],
      ),
      body: Column(
        children: [
          // Clean header section
          Container(
            width: double.infinity,
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  // Deity icon and name
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8F9FA),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0xFFFFB366),
                            width: 2,
                          ),
                        ),
                        child: Text(
                          widget.deity.icon,
                          style: const TextStyle(fontSize: 32),
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isHindi
                                  ? widget.deity.hindiName
                                  : widget.deity.englishName,
                              style: const TextStyle(
                                color: Color(0xFF2C3E50),
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              isHindi
                                  ? widget.deity.hindiDescription
                                  : widget.deity.description,
                              style: const TextStyle(
                                color: Color(0xFF6C757D),
                                fontSize: 16,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Writing stats
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F9FA),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFFE9ECEF),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatItem(
                          l10n.words,
                          _wordCount.toString(),
                          Icons.text_fields_rounded,
                        ),
                        _buildStatItem(l10n.time, '0:00', Icons.timer_rounded),
                        _buildStatItem(
                          l10n.days,
                          '1',
                          Icons.calendar_today_rounded,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Writing area
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.ramRamLekhan,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFFE9ECEF),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF2C3E50).withOpacity(0.05),
                            blurRadius: 15,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _writingController,
                        maxLines: null,
                        expands: true,
                        textAlignVertical: TextAlignVertical.top,
                        decoration: InputDecoration(
                          hintText: l10n.writeRamRamHere,
                          hintStyle: const TextStyle(
                            color: Color(0xFFADB5BD),
                            fontSize: 16,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.all(20),
                        ),
                        style: const TextStyle(
                          fontSize: 18,
                          height: 1.5,
                          color: Color(0xFF2C3E50),
                        ),
                        onTap: _startWriting,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isWriting
                              ? () => _saveWriting(isHindi)
                              : null,
                          icon: const Icon(Icons.save_rounded),
                          label: Text(l10n.save),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFFB366),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            _writingController.clear();
                            setState(() {
                              _wordCount = 0;
                              _isWriting = false;
                            });
                          },
                          icon: const Icon(Icons.clear_rounded),
                          label: Text(l10n.clear),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFFFB366),
                            side: const BorderSide(
                              color: Color(0xFFFFB366),
                              width: 2,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFF93C572), size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFF2C3E50),
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF6C757D),
            fontSize: 12,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }
}
