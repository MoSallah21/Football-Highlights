import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../data/models/highlight_model.dart';
import '../screens/video_player_screen.dart';

/// Card widget for displaying a football highlight - optimized for Android TV
class HighlightCard extends StatelessWidget {
  final HighlightModel highlight;
  final int focusOrder;

  const HighlightCard({
    super.key,
    required this.highlight,
    required this.focusOrder,
  });

  /// Open video player screen
  void _playVideo(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => VideoPlayerScreen(
          highlight: highlight,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // استخدم Focus.of للحصول على حالة التركيز من Parent Focus
    return Builder(
      builder: (context) {
        final isFocused = Focus.of(context).hasFocus;

        return GestureDetector(
          onTap: () => _playVideo(context),
          child: RepaintBoundary(
            child: AnimatedScale(
              scale: isFocused ? 1.05 : 1.0,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isFocused ? Colors.blue : Colors.transparent,
                    width: 3,
                  ),
                  boxShadow: isFocused
                      ? [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.5),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ]
                      : null,
                ),
                child: Card(
                  clipBehavior: Clip.antiAlias,
                  elevation: isFocused ? 8 : 2,
                  margin: EdgeInsets.zero,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Thumbnail image مع حماية إضافية
                      _buildThumbnail(),

                      // Duration badge (top-right)
                      if (highlight.duration.isNotEmpty)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.8),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              highlight.duration,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),

                      // Dark gradient overlay for text readability
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.85),
                              ],
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                highlight.title,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              if (highlight.channelTitle.isNotEmpty)
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.account_circle,
                                      size: 14,
                                      color: Colors.white60,
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        highlight.channelTitle,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.white70,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              if (highlight.viewCount > 0) ...[
                                const SizedBox(height: 2),
                                Text(
                                  '${_formatViews(highlight.viewCount)} views',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.white54,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),

                      // Play icon overlay when focused
                      if (isFocused)
                        Center(
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.7),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.blue,
                                width: 3,
                              ),
                            ),
                            child: const Icon(
                              Icons.play_arrow,
                              size: 50,
                              color: Colors.blue,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// بناء الصورة المصغرة مع معالجة آمنة للأخطاء
  Widget _buildThumbnail() {
    return RepaintBoundary(
      child: CachedNetworkImage(
        imageUrl: highlight.thumbnail,
        fit: BoxFit.cover,
        memCacheWidth: 500,
        memCacheHeight: 281,
        maxWidthDiskCache: 500,
        maxHeightDiskCache: 281,
        placeholder: (context, url) => Container(
          color: Colors.black26,
          child: const Center(
            child: CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 2,
            ),
          ),
        ),
        errorWidget: (context, url, error) {
          return Container(
            color: Colors.black38,
            child: const Icon(
              Icons.sports_soccer,
              size: 64,
              color: Colors.white38,
            ),
          );
        },
        // معالجة إضافية للصور
        fadeInDuration: const Duration(milliseconds: 200),
        fadeOutDuration: const Duration(milliseconds: 200),
      ),
    );
  }

  /// Format view count (e.g., 1000000 -> "1M")
  String _formatViews(int views) {
    if (views >= 1000000) {
      return '${(views / 1000000).toStringAsFixed(1)}M';
    } else if (views >= 1000) {
      return '${(views / 1000).toStringAsFixed(1)}K';
    }
    return views.toString();
  }
}