import 'package:flutter/material.dart';
import '../model/course.dart';
import 'widgets/app_video_player.dart';
import 'widgets/lesson_player/lesson_app_bar.dart';
import 'widgets/lesson_player/lesson_info.dart';
import 'widgets/lesson_player/lesson_resources_list.dart';
import 'widgets/lesson_player/lesson_up_next.dart';

class LessonPlayerScreen extends StatefulWidget {
  final Course course;
  final int initialLessonIndex;

  const LessonPlayerScreen({
    super.key,
    required this.course,
    required this.initialLessonIndex,
  });

  @override
  State<LessonPlayerScreen> createState() => _LessonPlayerScreenState();
}

class _LessonPlayerScreenState extends State<LessonPlayerScreen> {
  late int _currentIndex;
  late Lesson _currentLesson;
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialLessonIndex;
    if (widget.course.playlist.isNotEmpty) {
      _currentLesson = widget.course.playlist[_currentIndex];
    } else {
      // Handle empty playlist edge case?
      // Should likely not happen if entered from valid course
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_pageController.hasClients) {
        _pageController.jumpToPage(_currentIndex);
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _switchLesson(int index) {
    if (index < 0 || index >= widget.course.playlist.length) return;

    setState(() {
      _currentIndex = index;
      _currentLesson = widget.course.playlist[_currentIndex];
    });

    if (_pageController.hasClients) {
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _goToNextLesson() {
    if (_currentIndex < widget.course.playlist.length - 1) {
      _switchLesson(_currentIndex + 1);
    }
  }

  void _goToPreviousLesson() {
    if (_currentIndex > 0) {
      _switchLesson(_currentIndex - 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: Column(
        children: [
          LessonAppBar(
            courseTitle: widget.course.title,
            currentIndex: _currentIndex,
            totalLessons: widget.course.playlist.length,
          ),
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                  _currentLesson = widget.course.playlist[index];
                });
              },
              itemCount: widget.course.playlist.length,
              physics:
                  const NeverScrollableScrollPhysics(), // Disable swipe if "forward error" implies accidental swipes or state issues
              itemBuilder: (context, index) {
                final lesson = widget.course.playlist[index];
                return SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AspectRatio(
                        aspectRatio: 16 / 9,
                        child: Container(
                          color: Colors.black,
                          child: lesson.link != null && lesson.link!.isNotEmpty
                              ? AppVideoPlayer(
                                  url: lesson.link!,
                                  title: lesson.title,
                                )
                              : _buildPlaceholderVideo(),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          children: [
                            LessonInfo(lesson: lesson, index: index),
                            const SizedBox(height: 24),

                            // Resources List (PDF/Quiz)
                            LessonResourcesList(lesson: lesson),
                            const SizedBox(height: 24),

                            LessonUpNext(
                              nextLesson:
                                  index < widget.course.playlist.length - 1
                                  ? widget.course.playlist[index + 1]
                                  : null,
                              onNextTap: _goToNextLesson,
                            ),
                            const SizedBox(height: 24), // Reduced from 100
                          ],
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
      bottomNavigationBar: SafeArea(child: _buildBottomBar()),
    );
  }

  Widget _buildPlaceholderVideo() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.lock_clock, color: Colors.white, size: 32),
          ),
          const SizedBox(height: 16),
          const Text(
            'Content Locked or Unavailable',
            style: TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Row(
        children: [
          if (_currentIndex > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: _goToPreviousLesson,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Previous'),
              ),
            )
          else
            const Spacer(),

          const SizedBox(width: 12),

          Expanded(
            child: ElevatedButton(
              onPressed: _currentIndex < widget.course.playlist.length - 1
                  ? _goToNextLesson
                  : () {
                      Navigator.pop(context);
                    }, // Or complete acton
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                _currentIndex < widget.course.playlist.length - 1
                    ? 'Next Lesson'
                    : 'Finish Course',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
