// features/onboarding/widgets/onboarding_media.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../models/onboarding_item.dart';
import '../../../core/services/onboarding_cache_service.dart';

class OnboardingMedia extends StatefulWidget {
  final OnboardingItem item;
  final bool isActive;

  const OnboardingMedia({
    super.key,
    required this.item,
    required this.isActive,
  });

  @override
  State<OnboardingMedia> createState() => _OnboardingMediaState();
}

class _OnboardingMediaState extends State<OnboardingMedia> {
  VideoPlayerController? _controller;
  bool _hasError = false;
  bool _isDownloading = false;

  @override
  void initState() {
    super.initState();
    if (widget.item.type == OnboardingMediaType.video) {
      _initializeVideo();
    }
  }

  @override
  void didUpdateWidget(covariant OnboardingMedia oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.item.type != oldWidget.item.type ||
        widget.item.url != oldWidget.item.url) {
      _hasError = false;
      _disposeVideo();
      if (widget.item.type == OnboardingMediaType.video) {
        _initializeVideo();
      }
      return;
    }

    final ctrl = _controller;
    if (ctrl != null && ctrl.value.isInitialized) {
      if (widget.isActive) {
        ctrl.play();
      } else {
        ctrl.pause();
      }
    }
  }

  Future<void> _initializeVideo() async {
    try {
      _hasError = false;
      File? cachedFile =
          await OnboardingCacheService.getFileFromCache(widget.item.url);

      if (!mounted) return;
      if (cachedFile == null) {
        _isDownloading = true;
        setState(() {});
        cachedFile = await OnboardingCacheService.getFile(widget.item.url);
      }

      if (!mounted) return;
      final controller = VideoPlayerController.file(cachedFile);
      _controller = controller;
      await controller.initialize();
      if (!mounted || _controller != controller) {
        controller.dispose();
        return;
      }
      await controller.setLooping(true);
      if (widget.isActive) {
        await controller.play();
      }
      if (mounted) setState(() {});
    } catch (_) {
      _hasError = true;
      _disposeVideo();
    } finally {
      if (mounted) {
        _isDownloading = false;
        setState(() {});
      }
    }
  }

  void _disposeVideo() {
    _controller?.dispose();
    _controller = null;
  }

  @override
  void dispose() {
    _disposeVideo();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.item.type == OnboardingMediaType.video) {
      if (_hasError) {
        return const Center(
          child: Icon(Icons.broken_image, size: 48, color: Colors.grey),
        );
      }
      if (_isDownloading) {
        return const Center(
          child: CircularProgressIndicator(color: Colors.orange),
        );
      }
      final ctrl = _controller;
      if (ctrl == null || !ctrl.value.isInitialized) {
        return const Center(
          child: CircularProgressIndicator(color: Colors.orange),
        );
      }

      final aspect = ctrl.value.aspectRatio;
      return Center(
        child: AspectRatio(
          aspectRatio: aspect == 0 ? 16 / 9 : aspect,
          child: VideoPlayer(ctrl),
        ),
      );
    }

    return CachedNetworkImage(
      imageUrl: widget.item.url,
      fit: BoxFit.cover,
      placeholder: (context, url) => const Center(
        child: CircularProgressIndicator(color: Colors.orange),
      ),
      errorWidget: (context, url, error) => const Center(
        child: Icon(Icons.broken_image, size: 48, color: Colors.grey),
      ),
    );
  }
}
