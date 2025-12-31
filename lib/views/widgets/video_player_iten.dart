import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoPlayerItem extends StatefulWidget {
  final String videoUrl;
  final bool looping;
  final VoidCallback? onDoubleTap;
  const VideoPlayerItem({
    Key? key,
    required this.videoUrl,
    this.looping = true,
    this.onDoubleTap,
  }) : super(key: key);

  @override
  _VideoPlayerItemState createState() => _VideoPlayerItemState();
}

class _VideoPlayerItemState extends State<VideoPlayerItem> {
  late VideoPlayerController videoPlayerController;
  bool _isInitialized = false;
  bool _isPlaying = true;

  @override
  void initState() {
    super.initState();
    videoPlayerController = VideoPlayerController.network(widget.videoUrl)
      ..initialize().then((value) {
        if (!mounted) return;
        videoPlayerController.setLooping(widget.looping);
        videoPlayerController.play();
        videoPlayerController.setVolume(1);
        setState(() {
          _isInitialized = true;
          _isPlaying = videoPlayerController.value.isPlaying;
        });
      });
  }

  @override
  void dispose() {
    super.dispose();
    videoPlayerController.dispose();
  }

  void _togglePlayPause() {
    if (!_isInitialized) return;
    if (videoPlayerController.value.isPlaying) {
      videoPlayerController.pause();
    } else {
      videoPlayerController.play();
    }
    setState(() {
      _isPlaying = videoPlayerController.value.isPlaying;
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _togglePlayPause,
      onDoubleTap: widget.onDoubleTap,
      child: Container(
        width: size.width,
        height: size.height,
        decoration: const BoxDecoration(color: Colors.black),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (_isInitialized)
              FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: videoPlayerController.value.size.width,
                  height: videoPlayerController.value.size.height,
                  child: VideoPlayer(videoPlayerController),
                ),
              )
            else
              const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            if (_isInitialized && !_isPlaying)
              const Center(
                child: Icon(
                  Icons.play_arrow_rounded,
                  color: Colors.white70,
                  size: 84,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
