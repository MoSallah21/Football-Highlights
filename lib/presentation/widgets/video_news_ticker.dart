import 'dart:async';
import 'package:flutter/material.dart';

class VideoNewsTicker extends StatefulWidget {
  const VideoNewsTicker({super.key});

  @override
  State<VideoNewsTicker> createState() => _VideoNewsTickerState();
}

class _VideoNewsTickerState extends State<VideoNewsTicker> {
  final ScrollController _scrollController = ScrollController();
  final List<String> _images = [
    'assets/images/1.jpg',
    'assets/images/2.jpg',
    'assets/images/3.jpg',
    'assets/images/4.jpg',
    'assets/images/5.jpg',
  ];

  late Timer _timer;
  double _scrollSpeed = 2.0; // سرعة التحرك، يمكن تعديلها

  @override
  void initState() {
    super.initState();

    _timer = Timer.periodic(const Duration(milliseconds: 16), (_) {
      if (_scrollController.hasClients) {
        double maxScroll = _scrollController.position.maxScrollExtent / 2;
        double newPosition = _scrollController.offset + _scrollSpeed;

        if (newPosition >= maxScroll) {
          _scrollController.jumpTo(0);
        } else {
          _scrollController.jumpTo(newPosition);
        }
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        height: 120, // ارتفاع أكبر لتوضيح اللوغوهات
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.6), // خلفية شفافة قليلاً
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.6),
              blurRadius: 12,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: ListView.builder(
          controller: _scrollController,
          scrollDirection: Axis.horizontal,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _images.length * 4, // تكرار الصور لجعل الحركة مستمرة
          itemBuilder: (context, index) {
            final image = _images[index % _images.length];
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 16),
              child: Container(
                width: 100,
                height: 90,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.2), // خلفية شفافة لكل شعار
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.5),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    image,
                    fit: BoxFit.contain, // مهم للوغوهات
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey.shade900,
                        child: const Icon(
                          Icons.image_not_supported,
                          color: Colors.white54,
                          size: 28,
                        ),
                      );
                    },
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
