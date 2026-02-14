import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/services/language_service.dart';
import '../../models/mantra_model.dart';
import '../../models/deity_model.dart';
import '../practice_timer/practice_timer_screen.dart';

class PracticeSetupScreen extends StatefulWidget {
  final MantraModel mantra;

  const PracticeSetupScreen({
    super.key,
    required this.mantra,
  });

  @override
  State<PracticeSetupScreen> createState() => _PracticeSetupScreenState();
}

class _PracticeSetupScreenState extends State<PracticeSetupScreen> {
  int _selectedJapaCount = 108;
  final TextEditingController _customCountController = TextEditingController();

  final List<int> _japaCounts = [11, 21, 54, 108];

  @override
  void dispose() {
    _customCountController.dispose();
    super.dispose();
  }

  String? _getDeityImageUrl(String deityId) {
    if (deityId.isEmpty || DeityModel.deities.isEmpty) {
      return null;
    }
    final deity = DeityModel.deities.firstWhere(
      (d) => d.id == deityId,
      orElse: () => DeityModel.deities.first,
    );
    return deity.imageUrl;
  }

  void _showCustomCountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          Provider.of<LanguageService>(context, listen: false).isHindi
              ? 'कस्टम गिनती दर्ज करें'
              : 'Enter Custom Count',
        ),
        content: TextField(
          controller: _customCountController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: Provider.of<LanguageService>(context, listen: false).isHindi
                ? 'गिनती दर्ज करें'
                : 'Enter count',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              Provider.of<LanguageService>(context, listen: false).isHindi
                  ? 'रद्द करें'
                  : 'Cancel',
            ),
          ),
          TextButton(
            onPressed: () {
              final count = int.tryParse(_customCountController.text);
              if (count != null && count > 0) {
                setState(() {
                  _selectedJapaCount = count;
                });
                Navigator.pop(context);
                _customCountController.clear();
              }
            },
            child: Text(
              Provider.of<LanguageService>(context, listen: false).isHindi
                  ? 'ठीक है'
                  : 'OK',
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final languageService = Provider.of<LanguageService>(context);
    final isHindi = languageService.isHindi;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          isHindi ? 'अभ्यास शुरू करें' : 'Start Practice',
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
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Clean header section
            Container(
              width: double.infinity,
              color: Colors.white,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      // Deity image
                      Center(
                        child: Container(
                          width: 90,
                          height: 90,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFFFFB366),
                              width: 3,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFFB366).withOpacity(0.2),
                                blurRadius: 15,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: Image.network(
                              _getDeityImageUrl(widget.mantra.deityId ?? '') ?? '',
                              width: 90,
                              height: 90,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  width: 90,
                                  height: 90,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFF8F9FA),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.person_rounded,
                                    color: Color(0xFFFFB366),
                                    size: 45,
                                  ),
                                );
                              },
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Container(
                                  width: 90,
                                  height: 90,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFF8F9FA),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Center(
                                    child: CircularProgressIndicator(
                                      color: Color(0xFFFFB366),
                                      strokeWidth: 2,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Mantra text
                      Text(
                        isHindi ? widget.mantra.hindiMantra : widget.mantra.mantra,
                        style: const TextStyle(
                          color: Color(0xFF2C3E50),
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          height: 1.3,
                          letterSpacing: 0.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Content section
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Japa count selection
                  Text(
                    isHindi ? 'आप कितनी जप गिनती चाहते हैं?' : 'Select how many japa counts you want to chant',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Japa count options
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: _japaCounts.map((count) {
                      final isSelected = _selectedJapaCount == count;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedJapaCount = count;
                          });
                        },
                        child: Container(
                          width: 65,
                          height: 65,
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFFFFB366) : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected ? const Color(0xFFFFB366) : const Color(0xFFE9ECEF),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF2C3E50).withOpacity(0.05),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              count.toString(),
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: isSelected ? Colors.white : const Color(0xFF2C3E50),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  // Custom count button
                  Center(
                    child: GestureDetector(
                      onTap: _showCustomCountDialog,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFFFFB366), width: 2),
                          borderRadius: BorderRadius.circular(25),
                          color: Colors.white,
                        ),
                        child: Text(
                          isHindi ? '+ कस्टम गिनती जोड़ें' : '+ Add Custom Count',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFFFB366),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  // Start Japa button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PracticeTimerScreen(
                              mantra: widget.mantra,
                              japaCount: _selectedJapaCount,
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFB366),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        shadowColor: const Color(0xFFFFB366).withOpacity(0.3),
                      ),
                      child: Text(
                        isHindi ? 'जप शुरू करें' : 'Start Japa',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
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
}
