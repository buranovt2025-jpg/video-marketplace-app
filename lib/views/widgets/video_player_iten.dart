import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:video_player/video_player.dart';
import 'package:tiktok_tutorial/utils/media_url.dart';

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
  String? _initError;

  @override
  void initState() {
    super.initState();
    final url = widget.videoUrl.trim();
    if (!looksLikeAbsoluteHttpUrl(url)) {
      _initError = 'Некорректный URL (нужен http/https): $url';
      _isPausedByUser = true;
      return;
    }
    videoPlayerController = VideoPlayerController.networkUrl(Uri.parse(url));

    videoPlayerController.addListener(() {
      final v = videoPlayerController.value;
      if (v.hasError && mounted) {
        setState(() {
          _initError ??= v.errorDescription ?? 'Video playback error';
          _isPausedByUser = true;
        });
      }
    });

    videoPlayerController.initialize().then((_) {
      if (!mounted) return;
      setState(() {
        _initialized = true;
      });

      // Browsers often block autoplay with sound. TikTok/IG autoplay muted.
      _isMuted = kIsWeb;
      videoPlayerController.setLooping(true);
      videoPlayerController.setVolume(_isMuted ? 0 : 1);

      // Attempt autoplay. If blocked, user can start via tap gesture.
      videoPlayerController.play().catchError((e) {
        if (!mounted) return;
        setState(() {
          _isPausedByUser = true;
          _initError ??= e.toString();
        });
      });
    }).catchError((e) {
      if (!mounted) return;
      setState(() {
        _initError = e.toString();
        _isPausedByUser = true;
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
          if (_initError != null) return;
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
            if (_initError != null)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.videocam_off, size: 64, color: Colors.grey[600]),
                      const SizedBox(height: 12),
                      Text(
                        'Не удалось воспроизвести видео',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.videoUrl,
                        style: TextStyle(color: Colors.grey[400], fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _initError!,
                        style: TextStyle(color: Colors.grey[500], fontSize: 12),
                        textAlign: TextAlign.center,
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (kIsWeb && widget.videoUrl.trim().startsWith('http://')) ...[
                        const SizedBox(height: 10),
                        Text(
                          'Подсказка: браузер может блокировать http-видео на https-странице. Нужен https URL или корректные CORS/Range заголовки.',
                          style: TextStyle(color: Colors.orange[200], fontSize: 12),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ],
                  ),
                ),
              )
            else if (!_initialized)
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
            if (_initialized && _isMuted && _initError == null)
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
