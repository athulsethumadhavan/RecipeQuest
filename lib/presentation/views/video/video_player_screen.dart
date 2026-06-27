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
  bool _isFullScreen = false;

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
      ),
    );

    // Listen for embedding errors (e.g. Error 150 = playback disabled by owner)
    _controller.addListener(_onPlayerStateChanged);

    // Force landscape fullscreen on open
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _isFullScreen = true;
  }

  void _onPlayerStateChanged() {
    if (_controller.value.hasError) {
      // Any playback error (incl. Error 150) → open in YouTube app/browser
      _openInYouTube();
    }
  }

  Future<void> _openInYouTube() async {
    _controller.removeListener(_onPlayerStateChanged);
    if (!mounted) return;

    // Restore orientation before leaving
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    final uri = Uri.parse(widget.videoUrl);
    // Try YouTube app first, fall back to browser
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
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return YoutubePlayerBuilder(
      onEnterFullScreen: () {
        setState(() => _isFullScreen = true);
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]);
      },
      onExitFullScreen: () {
        setState(() => _isFullScreen = false);
        SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
      },
      player: YoutubePlayer(
        controller: _controller,
        showVideoProgressIndicator: true,
        progressIndicatorColor: AppColors.primary,
        progressColors: const ProgressBarColors(
          playedColor: AppColors.primary,
          handleColor: AppColors.primary,
        ),
      ),
      builder: (context, player) {
        return Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            children: [
              // Full-screen video fills entire screen
              SizedBox.expand(child: player),

              // Close button top-left
              Positioned(
                top: 16,
                left: 16,
                child: SafeArea(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.55),
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
      },
    );
  }
}
