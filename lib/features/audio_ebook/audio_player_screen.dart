// features/audio_ebook/audio_player_screen.dart
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:async';
import 'dart:math' as math;
import '../../core/services/audio_ebook_service.dart';
import '../../core/models/audio_ebook_model.dart';
import '../../core/services/url_processing_service.dart';
import 'audio_ebook_detail_screen.dart';

class AudioPlayerScreen extends StatefulWidget {
  final String audioUrl;
  final String title;
  final String? coverImage;
  final String? author;
  final String? language;
  final double? rating;
  final String? duration;
  final String category;
  final int audioId;

  const AudioPlayerScreen({
    super.key,
    required this.audioUrl,
    required this.title,
    this.coverImage,
    this.author,
    this.language,
    this.rating,
    this.duration,
    required this.category,
    required this.audioId,
  });

  @override
  State<AudioPlayerScreen> createState() => _AudioPlayerScreenState();
}

class _AudioPlayerScreenState extends State<AudioPlayerScreen> {
  late AudioPlayer _audioPlayer;
  bool _isPlaying = false;
  bool _isLoading = true;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  String _errorMessage = '';
  List<AudioEbookModel> _suggestedAudios = [];
  final AudioEbookService _audioEbookService = AudioEbookService();
  final UrlProcessingService _urlService = UrlProcessingService();
  String? _processedAudioUrl;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _initializePlayer();
    _loadSuggestedSongs();
  }

  Future<void> _initializePlayer() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      // Process URL to handle Google Drive and other external links
      _processedAudioUrl = await _urlService.processUrl(widget.audioUrl);

      // Check if URL is accessible
      final isAccessible = await _urlService.isUrlAccessible(
        _processedAudioUrl!,
      );
      if (!isAccessible) {
        setState(() {
          _errorMessage =
              'Audio file is not accessible. Please check the link.';
          _isLoading = false;
        });
        return;
      }

      // Set up event listeners
      _audioPlayer.onDurationChanged.listen((duration) {
        if (mounted) {
          setState(() {
            _duration = duration;
          });
        }
      });

      _audioPlayer.onPositionChanged.listen((position) {
        if (mounted) {
          setState(() {
            _position = position;
          });
        }
      });

      _audioPlayer.onPlayerStateChanged.listen((state) {
        if (mounted) {
          setState(() {
            _isPlaying = state == PlayerState.playing;
          });
        }
      });

      _audioPlayer.onPlayerComplete.listen((event) {
        if (mounted) {
          setState(() {
            _isPlaying = false;
            _position = Duration.zero;
          });
        }
      });

      // Load the audio file using processed URL
      await _audioPlayer.setSourceUrl(_processedAudioUrl!);

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error loading audio: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _playPause() async {
    if (_isPlaying) {
      await _audioPlayer.pause();
    } else {
      await _audioPlayer.resume();
    }
  }

  Future<void> _seek(Duration position) async {
    await _audioPlayer.seek(position);
  }

  Future<void> _seekBackward() async {
    final newPosition = _position - const Duration(seconds: 10);
    await _seek(newPosition < Duration.zero ? Duration.zero : newPosition);
  }

  Future<void> _seekForward() async {
    final newPosition = _position + const Duration(seconds: 10);
    await _seek(newPosition > _duration ? _duration : newPosition);
  }

  Future<void> _loadSuggestedSongs() async {
    try {
      // Get related audios using the service
      final relatedAudios = await _audioEbookService.getRelatedAudios(
        currentAudioCategory: widget.category,
        currentAudioId: widget.audioId,
        limit: 5,
      );

      setState(() {
        _suggestedAudios = relatedAudios;
      });
    } catch (e) {
      setState(() {
        _suggestedAudios = [];
      });
    }
  }

  void _playSuggestedAudio(AudioEbookModel audio) {
    // Navigate to the detail screen first, then user can play from there
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AudioEbookDetailScreen(item: audio),
      ),
    );
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Audio book'),
        backgroundColor: Colors.orange.shade600,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading audio...'),
          ],
        ),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red.shade400),
              const SizedBox(height: 16),
              Text(
                'Error',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.red.shade600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _initializePlayer,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange.shade600,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),

          // Book Cover with FREE tag
          Center(
            child: Stack(
              children: [
                Container(
                  width: 200,
                  height: 280,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child:
                        widget.coverImage != null &&
                            widget.coverImage!.isNotEmpty
                        ? Image.network(
                            widget.coverImage!,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return const Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey.shade200,
                                child: Icon(
                                  Icons.book,
                                  size: 80,
                                  color: Colors.grey.shade400,
                                ),
                              );
                            },
                          )
                        : Container(
                            color: Colors.grey.shade200,
                            child: Icon(
                              Icons.book,
                              size: 80,
                              color: Colors.grey.shade400,
                            ),
                          ),
                  ),
                ),
                // FREE COURSE tag
                // Positioned(
                //   top: 8,
                //   left: 8,
                //   child: Container(
                //     padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                //     decoration: BoxDecoration(
                //       color: Colors.green,
                //       borderRadius: BorderRadius.circular(4),
                //     ),
                //     child: const Text(
                //       'FREE COURSE',
                //       style: TextStyle(
                //         color: Colors.white,
                //         fontSize: 10,
                //         fontWeight: FontWeight.bold,
                //       ),
                //     ),
                //   ),
                // ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Metadata Row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildMetadataItem(
                icon: Icons.language,
                value: widget.language ?? 'Unknown',
                color: Colors.blue,
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Title
          Text(
            widget.title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),

          const SizedBox(height: 32),

          // Waveform Visualization (simplified)
          _buildWaveformVisualization(),

          const SizedBox(height: 16),

          // Progress Bar with Time
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatDuration(_position),
                style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
              ),
              Text(
                _formatDuration(_duration),
                style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Horizontal Control Bar
          _buildHorizontalControlBar(),

          const SizedBox(height: 40),

          // More from this section
          _buildMoreFromSection(),
        ],
      ),
    );
  }

  Widget _buildMetadataItem({
    required IconData icon,
    required String value,
    required Color color,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade700,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildWaveformVisualization() {
    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.grey.shade200, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200.withOpacity(0.5),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: CustomPaint(
        painter: WaveformPainter(
          progress: _duration.inMilliseconds > 0
              ? _position.inMilliseconds / _duration.inMilliseconds
              : 0.0,
        ),
        size: Size.infinite,
      ),
    );
  }

  Widget _buildHorizontalControlBar() {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: const Color(0xFF8B4513), // Dark brown color
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildControlButton(
            icon: Icons.replay_10,
            onPressed: _seekBackward,
            color: Colors.white,
            size: 24,
          ),
          _buildControlButton(
            icon: _isPlaying ? Icons.pause : Icons.play_arrow,
            onPressed: _playPause,
            color: Colors.orange,
            size: 32,
            isMain: true,
          ),
          _buildControlButton(
            icon: Icons.forward_10,
            onPressed: _seekForward,
            color: Colors.white,
            size: 24,
          ),
        ],
      ),
    );
  }

  Widget _buildMoreFromSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'More from this',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        if (_suggestedAudios.isEmpty)
          const Text(
            'Loading suggestions...',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          )
        else
          ...(_suggestedAudios
              .map(
                (audio) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildMoreItem(
                    title: audio.title,
                    description: audio.description.isNotEmpty
                        ? audio.description
                        : 'Audio content from ${audio.category}',
                    audio: audio,
                  ),
                ),
              )
              .toList()),
      ],
    );
  }

  Widget _buildMoreItem({
    required String title,
    required String description,
    required AudioEbookModel audio,
  }) {
    return GestureDetector(
      onTap: () => _playSuggestedAudio(audio),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.orange.shade100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.play_arrow,
                color: Colors.orange.shade600,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onPressed,
    required Color color,
    double size = 24,
    bool isMain = false,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: isMain ? 40 : 32,
        height: isMain ? 40 : 32,
        decoration: BoxDecoration(
          color: isMain ? color : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: isMain ? Colors.white : color, size: size),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${twoDigits(hours)}:${twoDigits(minutes)}:${twoDigits(seconds)}';
    } else {
      return '${twoDigits(minutes)}:${twoDigits(seconds)}';
    }
  }
}

// Custom painter for waveform visualization
class WaveformPainter extends CustomPainter {
  final double progress;

  WaveformPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final centerY = size.height / 2;
    final barWidth = 2.5;
    final spacing = 1.5;
    final totalBars = (size.width / (barWidth + spacing)).floor();

    // Create gradient for inactive bars
    final inactiveGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Colors.grey.shade200,
        Colors.grey.shade300,
        Colors.grey.shade200,
      ],
    );

    // Create gradient for active bars
    final activeGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Colors.orange.shade400,
        Colors.orange.shade600,
        Colors.orange.shade800,
      ],
    );

    for (int i = 0; i < totalBars; i++) {
      final x = i * (barWidth + spacing);

      // Create more dynamic bar heights with sine wave pattern
      final normalizedPosition = i / totalBars;
      final sineWave = (math.sin(normalizedPosition * math.pi * 4) + 1) / 2;
      final baseHeight = 8.0;
      final maxHeight = 28.0;
      final barHeight = baseHeight + (sineWave * (maxHeight - baseHeight));

      final startY = centerY - barHeight / 2;

      final isActive = x / size.width <= progress;

      // Create rounded rectangle for each bar
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, startY, barWidth, barHeight),
        const Radius.circular(1.25),
      );

      // Apply gradient based on active state
      final gradient = isActive ? activeGradient : inactiveGradient;
      final shader = gradient.createShader(
        Rect.fromLTWH(x, startY, barWidth, barHeight),
      );

      final paint = Paint()
        ..shader = shader
        ..style = PaintingStyle.fill;

      canvas.drawRRect(rect, paint);

      // Add subtle shadow for depth
      if (isActive) {
        final shadowPaint = Paint()
          ..color = Colors.orange.shade200.withOpacity(0.3)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.0);

        final shadowRect = RRect.fromRectAndRadius(
          Rect.fromLTWH(x + 0.5, startY + 0.5, barWidth, barHeight),
          const Radius.circular(1.25),
        );
        canvas.drawRRect(shadowRect, shadowPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return oldDelegate is WaveformPainter && oldDelegate.progress != progress;
  }
}
