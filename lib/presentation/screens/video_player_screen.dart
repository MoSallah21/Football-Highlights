import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../../data/models/highlight_model.dart';
import 'dart:async';
import '../widgets/video_news_ticker.dart';

/// Fullscreen video player with YouTube support - Optimized for TV
class VideoPlayerScreen extends StatefulWidget {
  final HighlightModel highlight;

  const VideoPlayerScreen({
    super.key,
    required this.highlight,
  });

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> with WidgetsBindingObserver {
  late YoutubePlayerController _controller;
  bool _isYouTubeVideo = false;
  bool _isPlayerReady = false;
  bool _showControls = true;
  bool _showTicker = true;
  Timer? _hideTimer;
  final FocusNode _keyboardFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Set fullscreen mode for TV
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    // Lock landscape orientation
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    _initializePlayer();
    _startHideTimer();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  void _initializePlayer() {
    final videoId = YoutubePlayer.convertUrlToId(widget.highlight.videoUrl);

    if (videoId != null) {
      _isYouTubeVideo = true;
      _controller = YoutubePlayerController(
        initialVideoId: videoId,
        flags: const YoutubePlayerFlags(
          autoPlay: true,
          mute: false,
          enableCaption: false,
          controlsVisibleAtStart: false,
          hideControls: true,
          forceHD: true,
          showLiveFullscreenButton: false,
          useHybridComposition: true,
          isLive: false,
          disableDragSeek: false,
        ),
      )..addListener(_listener);
    }
  }

  void _listener() {
    if (_controller.value.isReady && !_isPlayerReady) {
      setState(() {
        _isPlayerReady = true;
      });
    }
  }

  void _startHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          _showControls = false;
        });
      }
    });
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });

    if (_showControls) {
      _startHideTimer();
    } else {
      _hideTimer?.cancel();
    }
  }

  void _toggleTicker() {
    setState(() {
      _showTicker = !_showTicker;
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _hideTimer?.cancel();
    _keyboardFocusNode.dispose();

    if (_isYouTubeVideo) {
      _controller.removeListener(_listener);
      _controller.pause();
      _controller.dispose();
    }

    super.dispose();
  }

  Future<void> _exitPlayer() async {
    if (_isYouTubeVideo && _controller.value.isReady) {
      _controller.pause();
    }

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final width = size.width;
    final height = size.height;

    return PopScope(
      // تعطيل زر الخلف العادي من النظام
      canPop: false,
      onPopInvoked: (bool didPop) {
        // لا تفعل شيء عند الضغط على زر الخلف
        // الخروج يكون فقط من خلال زر الخلف في الواجهة
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: KeyboardListener(
          focusNode: _keyboardFocusNode..requestFocus(),
          autofocus: true,
          onKeyEvent: (event) {
            if (event is KeyDownEvent) {
              // تم إزالة أزرار الخلف من الكيبورد/الريموت
              // الآن فقط زر Select/Enter يعمل لإظهار/إخفاء الكنترولات
              if (event.logicalKey == LogicalKeyboardKey.select ||
                  event.logicalKey == LogicalKeyboardKey.enter) {
                _toggleControls();
              } else if (event.logicalKey == LogicalKeyboardKey.keyI) {
                _toggleTicker();
              }
            }
          },
          child: GestureDetector(
            onTap: _toggleControls,
            child: Stack(
              children: [
                // Video player
                if (_isYouTubeVideo)
                  SizedBox(
                    width: width,
                    height: height,
                    child: FittedBox(
                      fit: BoxFit.cover,
                      child: SizedBox(
                        width: width,
                        height: width * 9 / 16,
                        child: YoutubePlayer(
                          controller: _controller,
                          aspectRatio: 16 / 9,
                          showVideoProgressIndicator: false,
                          onReady: () {
                            debugPrint('Player is ready.');
                            setState(() {
                              _isPlayerReady = true;
                            });
                          },
                          onEnded: (metaData) {
                            setState(() {
                              _showControls = true;
                            });
                            _hideTimer?.cancel();
                          },
                        ),
                      ),
                    ),
                  )
                else
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Colors.red,
                          size: 80,
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Invalid video URL',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Only YouTube videos are supported',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 20,
                          ),
                        ),
                        const SizedBox(height: 32),
                        ElevatedButton.icon(
                          onPressed: _exitPlayer,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 16,
                            ),
                          ),
                          icon: const Icon(Icons.arrow_back, size: 28),
                          label: const Text(
                            'Go Back',
                            style: TextStyle(fontSize: 20),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Loading indicator
                if (_isYouTubeVideo && !_isPlayerReady)
                  Container(
                    color: Colors.black,
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: Colors.red,
                        strokeWidth: 5,
                      ),
                    ),
                  ),

                // Custom Controls Overlay
                if (_isPlayerReady)
                  AnimatedOpacity(
                    opacity: _showControls ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 300),
                    child: IgnorePointer(
                      ignoring: !_showControls,
                      child: Stack(
                        children: [
                          // Semi-transparent background
                          Container(
                            color: Colors.black.withOpacity(0.3),
                          ),

                          // Top bar with back button and title
                          Positioned(
                            top: 0,
                            left: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 32,
                                vertical: 24,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.black.withOpacity(0.8),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                              child: Row(
                                children: [
                                  // Back button - هذا الزر الوحيد الذي يعمل للخروج
                                  Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: _exitPlayer,
                                      borderRadius: BorderRadius.circular(40),
                                      child: Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.5),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.arrow_back,
                                          color: Colors.white,
                                          size: 32,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 24),
                                  // Title and channel
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          widget.highlight.title,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 1,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          widget.highlight.channelTitle,
                                          style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 16,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 1,
                                        ),
                                      ],
                                    ),
                                  ),
                                  // زر إخفاء الشريط الإخباري
                                  Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: _toggleTicker,
                                      borderRadius: BorderRadius.circular(40),
                                      child: Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.5),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          _showTicker
                                              ? Icons.info
                                              : Icons.info_outline,
                                          color: Colors.white,
                                          size: 28,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Play/Pause button
                          Center(
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  setState(() {
                                    _controller.value.isPlaying
                                        ? _controller.pause()
                                        : _controller.play();
                                  });
                                },
                                borderRadius: BorderRadius.circular(50),
                                child: Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.5),
                                        blurRadius: 20,
                                        spreadRadius: 5,
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    _controller.value.isPlaying
                                        ? Icons.pause
                                        : Icons.play_arrow,
                                    color: Colors.white,
                                    size: 48,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // News Ticker
                if (_isPlayerReady && _showTicker)
                  const VideoNewsTicker(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}