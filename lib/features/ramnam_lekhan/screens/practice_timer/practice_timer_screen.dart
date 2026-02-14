import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:async';
import '../../../../core/services/language_service.dart';
import '../../../../core/services/daily_targets_service.dart';
import '../../../../core/services/certificate_service.dart';
import '../../../../core/services/streak_service.dart';
import '../../models/mantra_model.dart';
import '../../models/deity_model.dart';
import '../profile_section/profile_section.dart';
import '../ramnam_lekhan/ramnam_lekhan_screen.dart';

class PracticeTimerScreen extends StatefulWidget {
  final MantraModel mantra;
  final int japaCount;

  const PracticeTimerScreen({
    super.key,
    required this.mantra,
    required this.japaCount,
  });

  @override
  State<PracticeTimerScreen> createState() => _PracticeTimerScreenState();
}

class _PracticeTimerScreenState extends State<PracticeTimerScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  Timer? _timer;
  int _currentCount = 0;
  bool _isRunning = false;
  DateTime? _startTime;
  Duration _elapsedTime = Duration.zero;

  // 🎵 Audio player
  late AudioPlayer _audioPlayer;
  bool _isMuted = false;

  // âœ¨ Om particles
  final List<OmParticle> _omParticles = [];

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _fadeController.forward();

    // Initialize audio
    _audioPlayer = AudioPlayer();
    _initAudio();

    // Auto-start timer when screen loads
    _startTimer();
  }

  Future<void> _initAudio() async {
    try {
      await _audioPlayer.setSource(AssetSource('audio/audio.mpeg'));
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer.resume();
    } catch (e) {
    }
  }

  void _toggleMute() {
    setState(() {
      _isMuted = !_isMuted;
    });
    if (_isMuted) {
      _audioPlayer.pause();
    } else {
      _audioPlayer.resume();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _fadeController.dispose();
    _audioPlayer.dispose();
    for (var particle in _omParticles) {
      particle.dispose();
    }
    super.dispose();
  }

  void _startTimer() {
    if (!_isRunning) {
      setState(() {
        _isRunning = true;
        if (_elapsedTime != Duration.zero) {
          _startTime = DateTime.now().subtract(_elapsedTime);
        } else {
          _startTime = DateTime.now();
        }
      });

      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          _elapsedTime = DateTime.now().difference(_startTime!);
        });
      });
    }
  }

  void _resetTimer() {
    final languageService = Provider.of<LanguageService>(
      context,
      listen: false,
    );
    final isHindi = languageService.isHindi;

    if (_currentCount > 0) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(isHindi ? 'रीसेट करें' : 'Reset Timer'),
          content: Text(
            isHindi ? 'क्या आप वाकई टाइमर रीसेट करना चाहते हैं? आपकी प्रगति सहेजी जाएगी।' : 'Are you sure you want to reset the timer? Your progress will be saved.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(isHindi ? 'रद्द करें' : 'Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _performReset();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: Text(isHindi ? 'रीसेट करें' : 'Reset'),
            ),
          ],
        ),
      );
    } else {
      _performReset();
    }
  }

  void _performReset() {
    _saveCurrentProgress();
    setState(() {
      _isRunning = false;
      _currentCount = 0;
      _elapsedTime = Duration.zero;
    });
    _timer?.cancel();
  }

  void _incrementCount() {
    if (!_isRunning) return;

    if (_currentCount < widget.japaCount) {
      setState(() {
        _currentCount++;
      });

      HapticFeedback.lightImpact();

      if (_currentCount >= widget.japaCount) {
        _completeJapa();
      }
    }
  }

  // âœ¨ Create Om particle at tap location
  void _createOmParticle(Offset position) {
    final particle = OmParticle(
      position: position,
      vsync: this,
    );

    setState(() {
      _omParticles.add(particle);
    });

    // Remove after animation completes (15 seconds - very slow, meditative animation)
    Future.delayed(const Duration(seconds: 15), () { // Match animation duration
      if (mounted) {
        setState(() {
          _omParticles.remove(particle);
        });
        particle.dispose();
      }
    });
  }

  void _completeJapa() {
    setState(() {
      _isRunning = false;
    });
    _timer?.cancel();
    
    // 🎵 Stop the audio when japa is completed
    _audioPlayer.stop();

    final dailyTargetsService = Provider.of<DailyTargetsService>(
      context,
      listen: false,
    );
    final certificateService = Provider.of<CertificateService>(
      context,
      listen: false,
    );
    final streakService = Provider.of<StreakService>(context, listen: false);

    dailyTargetsService.recordJapaCount(
      widget.mantra.id,
      _currentCount,
      certificateService: certificateService,
      streakService: streakService,
    );

    streakService.checkStreakUpdate();
    _showCompletionDialog();
  }

  void _saveCurrentProgress() async {
    // 🎵 Stop the audio when saving and exiting
    _audioPlayer.stop();
    
    if (_currentCount > 0) {
      final languageService = Provider.of<LanguageService>(
        context,
        listen: false,
      );
      final isHindi = languageService.isHindi;

      try {
        final dailyTargetsService = Provider.of<DailyTargetsService>(
          context,
          listen: false,
        );
        final certificateService = Provider.of<CertificateService>(
          context,
          listen: false,
        );
        final streakService = Provider.of<StreakService>(
          context,
          listen: false,
        );

        await dailyTargetsService.recordJapaCount(
          widget.mantra.id,
          _currentCount,
          certificateService: certificateService,
          streakService: streakService,
        );

        await streakService.checkStreakUpdate();

        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              title: Text(isHindi ? 'सफल!' : 'Success!'),
              content: Text(
                isHindi ? '$_currentCount जप सहेजे गए!' : '$_currentCount japa saved!',
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const NaamJapaProfileSection(),
                      ),
                    );
                  },
                  child: Text(isHindi ? 'ठीक है' : 'OK'),
                ),
              ],
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const NaamJapaProfileSection(),
            ),
          );
        }
      }
    }
  }

  String _getDeityImageUrl(String? deityId) {
    if (deityId == null || deityId.isEmpty || DeityModel.deities.isEmpty) {
      return 'https://via.placeholder.com/150';
    }
    final deity = DeityModel.deities.firstWhere(
      (d) => d.id == deityId,
      orElse: () => DeityModel.deities.first,
    );
    return deity.imageUrl ?? 'https://via.placeholder.com/150';
  }

  void _showCompletionDialog() {
    final languageService = Provider.of<LanguageService>(
      context,
      listen: false,
    );
    final isHindi = languageService.isHindi;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(isHindi ? 'जप पूर्ण!' : 'Japa Complete!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isHindi ? 'आपने $_currentCount जप सफलतापूर्वक पूरे किए!' : 'You have successfully completed $_currentCount japa!',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 12),
            Text(
              isHindi ? 'समय लगा: ${_formatDuration(_elapsedTime)}' : 'Time taken: ${_formatDuration(_elapsedTime)}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.blue,
              ),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _navigateToStartPractice();
            },
            icon: const Icon(
              Icons.play_circle_outline_rounded,
              color: Color(0xFFFFB366),
            ),
            label: Text(
              isHindi ? 'अभ्यास शुरू करें' : 'Start Practice',
              style: const TextStyle(
                color: Color(0xFFFFB366),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _navigateToSadhakProfile();
            },
            icon: const Icon(Icons.person_rounded, color: Color(0xFF2C3E50)),
            label: Text(
              isHindi ? 'साधक प्रोफाइल' : 'SADHAK PROFILE',
              style: const TextStyle(
                color: Color(0xFF2C3E50),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToStartPractice() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) =>
            NaamJapaScreen(initialDeityId: widget.mantra.deityId),
      ),
    );
  }

  void _navigateToSadhakProfile() {
    Navigator.pushNamed(context, '/sadhna-dashboard');
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }

  // Helper widget for stats bar items
  Widget _buildStatItem({
    required String icon,
    required String label,
    required String value,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          icon,
          style: const TextStyle(fontSize: 20),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Color(0xFFFF9500),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final languageService = Provider.of<LanguageService>(context);
    final isHindi = languageService.isHindi;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          isHindi ? 'जप अभ्यास' : 'Japa Practice',
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 20),
        ),
        backgroundColor: const Color(0xFFFF9500),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        actions: [
          // 🔊 Mute/Unmute button
          IconButton(
            onPressed: _toggleMute,
            icon: Icon(
              _isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
            ),
            tooltip: _isMuted 
                ? (isHindi ? 'अनम्यूट करें' : 'Unmute')
                : (isHindi ? 'म्यूट करें' : 'Mute'),
          ),
          if (_currentCount > 0)
            IconButton(
              onPressed: _saveCurrentProgress,
              icon: const Icon(Icons.save_rounded),
              tooltip: isHindi ? 'प्रगति सहेजें' : 'Save Progress',
            ),
          IconButton(
            onPressed: _resetTimer,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: isHindi ? 'रीसेट करें' : 'Reset',
          ),
        ],
      ),
      body: GestureDetector(
        onTapDown: (details) {
          _incrementCount();
          _createOmParticle(details.globalPosition);
        },
        behavior: HitTestBehavior.translucent,
        child: Stack(
          children: [
            // Main content
            FadeTransition(
              opacity: _fadeAnimation,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 24),
                    // 📷 Deity Image with Floating Streak Badge (BIGGER!)
                    Center(
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          // Deity Photo - 150x150 (almost 2x bigger!)
                          Container(
                            width: 150,
                            height: 150,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFFFF9500),
                                width: 4,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFFF9500).withOpacity(0.3),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: Image.network(
                                _getDeityImageUrl(widget.mantra.deityId),
                                width: 150,
                                height: 150,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Center(
                                    child: Icon(
                                      Icons.broken_image,
                                      color: Color(0xFFFF9500),
                                      size: 60,
                                    ),
                                  );
                                },
                                loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return const Center(
                                    child: CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Color(0xFFFF9500),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          
                          // 🔥 Floating Streak Badge (Top-Right)
                          Positioned(
                            top: -5,
                            right: -5,
                            child: Consumer<StreakService>(
                              builder: (context, streakService, child) {
                                final currentStreak = streakService.currentStreak;
                                if (currentStreak == 0) return const SizedBox.shrink();
                                
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFFFF6B00), Color(0xFFFF9500)],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFFFF6B00).withOpacity(0.4),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Text(
                                        '🔥',
                                        style: TextStyle(fontSize: 16),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '$currentStreak',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w900,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    
                    // Mantra Card
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFFE9ECEF),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 20,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            // Mantra - Language-aware display
                            Text(
                              isHindi
                                  ? widget.mantra.hindiMantra
                                  : widget.mantra.mantra,
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFFFF9500),
                                height: 1.4,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 20),
                            // Meaning - Language-aware display
                            Text(
                              isHindi
                                  ? widget.mantra.hindiMeaning
                                  : widget.mantra.meaning,
                              style: const TextStyle(
                                fontSize: 15,
                                color: Color(0xFF666666),
                                height: 1.5,
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    // Timer (smaller, less prominent)
                    Text(
                      _formatDuration(_elapsedTime),
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    // 🏷 CENTRAL COUNTER with Circular Progress (MAIN FOCUS!)
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        // Circular Progress Indicator
                        SizedBox(
                          width: 220,
                          height: 220,
                          child: CircularProgressIndicator(
                            value: widget.japaCount > 0
                                ? _currentCount / widget.japaCount
                                : 0,
                            strokeWidth: 8,
                            backgroundColor: const Color(0xFFE9ECEF),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Color(0xFFFF9500),
                            ),
                          ),
                        ),
                        // Counter Circle
                        Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFF9500).withOpacity(0.2),
                                blurRadius: 30,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Center(
                            child: RichText(
                              text: TextSpan(
                                children: [
                                  // Current count
                                  TextSpan(
                                    text: '$_currentCount',
                                    style: const TextStyle(
                                      fontSize: 52,
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFFFF9500),
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  // Separator
                                  TextSpan(
                                    text: ' / ',
                                    style: TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey[400],
                                    ),
                                  ),
                                  // Total count
                                  TextSpan(
                                    text: '${widget.japaCount}',
                                    style: TextStyle(
                                      fontSize: 36,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    
                    // 📊 Bottom Stats Bar
                    Consumer<StreakService>(
                      builder: (context, streakService, child) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 16,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  const Color(0xFFFF9500).withOpacity(0.1),
                                  const Color(0xFFFFB366).withOpacity(0.1),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(0xFFFF9500).withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                // Today's Progress
                                Expanded(
                                  child: _buildStatItem(
                                    icon: '📊',
                                    label: isHindi ? 'आज' : 'Today',
                                    value: '${streakService.todayProgress}/${streakService.currentTarget}',
                                  ),
                                ),
                                Container(
                                  width: 1,
                                  height: 40,
                                  color: const Color(0xFFFF9500).withOpacity(0.2),
                                ),
                                // Current Streak
                                Expanded(
                                  child: _buildStatItem(
                                    icon: '🔥',
                                    label: isHindi ? 'स्ट्रीक' : 'Streak',
                                    value: '${streakService.currentStreak} ${isHindi ? "दिन" : "days"}',
                                  ),
                                ),
                                Container(
                                  width: 1,
                                  height: 40,
                                  color: const Color(0xFFFF9500).withOpacity(0.2),
                                ),
                                // Best Streak
                                Expanded(
                                  child: _buildStatItem(
                                    icon: '🏆',
                                    label: isHindi ? 'सर्वश्रेष्ठ' : 'Best',
                                    value: '${streakService.longestStreak} ${isHindi ? "दिन" : "days"}',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
            
            // âœ¨ Om particles overlay
            ..._omParticles.map((particle) {
              return Positioned(
                left: particle.position.dx - 20,
                top: particle.position.dy - 20,
                child: SlideTransition(
                  position: particle.slideAnimation,
                  child: FadeTransition(
                    opacity: particle.fadeAnimation,
                    child: const Text(
                      'à¥',
                      style: TextStyle(
                        fontSize: 40,
                        color: Color(0xFFFF9500),
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                            color: Colors.black26,
                            blurRadius: 4,
                            offset: Offset(2, 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

// âœ¨ Om Particle class for animation
class OmParticle {
  final Offset position;
  final AnimationController controller;
  late Animation<Offset> slideAnimation;
  late Animation<double> fadeAnimation;

  OmParticle({
    required this.position,
    required TickerProvider vsync,
  }) : controller = AnimationController(
          duration: const Duration(milliseconds: 15000), // 🐌🐌 Very slow, meditative animation (15 seconds)
          vsync: vsync,
        ) {
    // Float up animation - very slow and steady movement you can see
    slideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0, -300), // Float much higher
    ).animate(CurvedAnimation(
      parent: controller,
      curve: Curves.linear, // Linear for constant visible movement
    ));

    // Fade out animation - only at the very end so Om stays visible
    fadeAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: const Interval(0.75, 1.0, curve: Curves.easeIn), // Fade only in last 25%
    ));

    controller.forward();
  }

  void dispose() {
    controller.dispose();
  }
}
