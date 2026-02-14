import 'package:flutter/material.dart';
import '../../../model/webinar.dart';

class WebinarSliverAppBar extends StatelessWidget {
  final Webinar webinar;

  const WebinarSliverAppBar({super.key, required this.webinar});

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 250,
      pinned: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          shape: BoxShape.circle,
        ),
        child: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Hero(
          tag: 'webinar_image_${webinar.webinarId}',
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.orange.shade600, Colors.orange.shade800],
              ),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (webinar.thumbnail.startsWith('http'))
                  Image.network(
                    webinar.thumbnail,
                    fit: BoxFit.cover,
                    color: Colors.black.withOpacity(0.3),
                    colorBlendMode: BlendMode.multiply,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(
                        Icons.broken_image,
                        size: 40,
                        color: Colors.white,
                      );
                    },
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const Center(child: CircularProgressIndicator());
                    },
                  )
                else
                  Container(
                    color: Colors.orange.shade100,
                    child: Icon(
                      Icons.video_camera_front,
                      size: 80,
                      color: Colors.orange.shade600,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
