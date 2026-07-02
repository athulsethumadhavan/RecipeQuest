import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';

class VideoPlayerScreen extends StatefulWidget {
  final String videoUrl;
  final String title;

  const VideoPlayerScreen({
    super.key,
    required this.videoUrl,
    required this.title,
  });

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late YoutubePlayerController _controller;

  @override
  void initState() {
    super.initState();

    final videoId = YoutubePlayer.convertUrlToId(widget.videoUrl) ?? '';
    _controller = YoutubePlayerController(
      initialVideoId: videoId,
      flags: const YoutubePlayerFlags(
        autoPlay: true,
        mute: false,
        enableCaption: true,
        forceHD: true,
        hideControls: false,
        controlsVisibleAtStart: true,
      ),
    );

    _controller.addListener(_onPlayerStateChanged);

    // Force landscape + hide system UI
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  void _onPlayerStateChanged() {
    if (_controller.value.hasError) {
      _openInYouTube();
    }
  }

  Future<void> _close() async {
    _restorePortrait();
    if (mounted) Navigator.pop(context);
  }

  void _restorePortrait() {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  Future<void> _openInYouTube() async {
    _controller.removeListener(_onPlayerStateChanged);
    if (!mounted) return;
    _restorePortrait();

    final uri = Uri.parse(widget.videoUrl);
    final ytAppUri = Uri.parse(
      widget.videoUrl.replaceFirst('https://www.youtube.com', 'youtube://'),
    );

    bool launched = false;
    try {
      launched = await launchUrl(ytAppUri, mode: LaunchMode.externalApplication);
    } catch (_) {}

    if (!launched) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }

    if (mounted) Navigator.pop(context);
  }

  @override
  void dispose() {
    _controller.removeListener(_onPlayerStateChanged);
    _controller.dispose();
    _restorePortrait();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    // In landscape, fit video to screen height; in portrait fit to width
    final isLandscape = size.width > size.height;
    final playerWidth = isLandscape
        ? size.height * (16 / 9)
        : size.width;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Video centered, fills landscape screen
          Center(
            child: SizedBox(
              width: playerWidth,
              child: YoutubePlayer(
                controller: _controller,
                showVideoProgressIndicator: true,
                width: playerWidth,
                progressIndicatorColor: AppColors.primary,
                progressColors: const ProgressBarColors(
                  playedColor: AppColors.primary,
                  handleColor: AppColors.primary,
                ),
                onEnded: (_) => _close(),
              ),
            ),
          ),

          // Close button top-left
          Positioned(
            top: 12,
            left: 12,
            child: SafeArea(
              child: GestureDetector(
                onTap: _close,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.close_rounded,
                      color: Colors.white, size: 22),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
