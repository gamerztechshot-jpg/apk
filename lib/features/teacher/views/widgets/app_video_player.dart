import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class AppVideoPlayer extends StatefulWidget {
  final String url;
  final String title;

  const AppVideoPlayer({super.key, required this.url, required this.title});

  @override
  State<AppVideoPlayer> createState() => _AppVideoPlayerState();
}

class _AppVideoPlayerState extends State<AppVideoPlayer> {
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  YoutubePlayerController? _youtubeController;

  bool _isYoutube = false;
  String? _youtubeId;

  @override
  void initState() {
    super.initState();
    _checkVideoType();
    _initializePlayer();
  }

  void _checkVideoType() {
    _youtubeId = YoutubePlayer.convertUrlToId(widget.url);
    _isYoutube = _youtubeId != null;
  }

  void _initializePlayer() {
    if (_isYoutube && _youtubeId != null) {
      _youtubeController = YoutubePlayerController(
        initialVideoId: _youtubeId!,
        flags: const YoutubePlayerFlags(
          autoPlay: false,
          controlsVisibleAtStart: true,
          enableCaption: true,
        ),
      );
    } else {
      _videoController = VideoPlayerController.networkUrl(
        Uri.parse(widget.url),
      );

      _chewieController = ChewieController(
        videoPlayerController: _videoController!,
        autoInitialize: true,
        autoPlay: true,
        looping: false,
        allowFullScreen: true,
        allowMuting: true,
        showControls: true,
        aspectRatio: 16 / 9,
      );
    }
    setState(() {});
  }

  @override
  void dispose() {
    _youtubeController?.dispose();
    _chewieController?.dispose();
    _videoController?.dispose();

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isYoutube && _youtubeController != null) {
      return YoutubePlayerBuilder(
        player: YoutubePlayer(
          controller: _youtubeController!,
          showVideoProgressIndicator: true,
          progressIndicatorColor: Colors.orange,
        ),
        builder: (context, player) {
          return player;
        },
      );
    }

    if (_chewieController != null) {
      return Chewie(controller: _chewieController!);
    }

    return const Center(child: CircularProgressIndicator(color: Colors.orange));
  }
}
