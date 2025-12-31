import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:video_player/video_player.dart';

class VideoPlayerItem extends StatefulWidget {
  final String videoUrl;
  const VideoPlayerItem({
    Key? key,
    required this.videoUrl,
  }) : super(key: key);

  @override
  _VideoPlayerItemState createState() => _VideoPlayerItemState();
}

class _VideoPlayerItemState extends State<VideoPlayerItem> {
  late VideoPlayerController videoPlayerController;
  bool _initialized = false;
  bool _isPausedByUser = false;
  bool _isMuted = false;

  @override
  void initState() {
    super.initState();
    videoPlayerController = VideoPlayerController.network(widget.videoUrl)
      ..initialize().then((value) {
        if (!mounted) return;
        setState(() {
          _initialized = true;
        });
        // Browsers often block autoplay with sound. TikTok/IG autoplay muted.
        _isMuted = kIsWeb;
        videoPlayerController.setLooping(true);
        videoPlayerController.setVolume(_isMuted ? 0 : 1);

        // Attempt autoplay. If blocked, user can start via tap gesture.
        videoPlayerController.play().catchError((_) {
          if (!mounted) return;
          setState(() {
            _isPausedByUser = true;
          });
        });
      });
  }

  @override
  void dispose() {
    super.dispose();
    videoPlayerController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Container(
      width: size.width,
      height: size.height,
      decoration: const BoxDecoration(
        color: Colors.black,
      ),
      child: GestureDetector(
        onTap: () {
          if (!_initialized) return;
          setState(() {
            _isPausedByUser = !_isPausedByUser;
          });
          if (_isPausedByUser) {
            videoPlayerController.pause();
          } else {
            videoPlayerController.play();
          }
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (!_initialized)
              const Center(
                child: SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                ),
              )
            else
              FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: videoPlayerController.value.size.width,
                  height: videoPlayerController.value.size.height,
                  child: VideoPlayer(videoPlayerController),
                ),
              ),
            if (_initialized && _isPausedByUser)
              const Center(
                child: Icon(
                  Icons.pause_circle_filled,
                  color: Colors.white70,
                  size: 84,
                ),
              ),

            // Mute indicator (web autoplay starts muted)
            if (_initialized && _isMuted)
              Positioned(
                right: 12,
                bottom: 12,
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _isMuted = !_isMuted;
                    });
                    videoPlayerController.setVolume(_isMuted ? 0 : 1);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Icon(
                      _isMuted ? Icons.volume_off : Icons.volume_up,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
