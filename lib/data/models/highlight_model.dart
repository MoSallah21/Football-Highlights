import 'package:equatable/equatable.dart';

/// Model representing a football highlight video
class HighlightModel extends Equatable {
  final String id;
  final String title;
  final String thumbnail;
  final String videoUrl;
  final String channelTitle;
  final String channelId;
  final String duration;
  final int viewCount;
  final DateTime? publishedAt;
  final String description; // ✅ added

  const HighlightModel({
    required this.id,
    required this.title,
    required this.thumbnail,
    required this.videoUrl,
    this.channelTitle = '',
    this.channelId = '',
    this.duration = '',
    this.viewCount = 0,
    this.publishedAt,
    this.description = '', // ✅ added default
  });

  /// Create HighlightModel from YouTube API search response
  factory HighlightModel.fromYouTubeApi(Map<String, dynamic> json) {
    final id = json['id'] is Map
        ? json['id']['videoId'] as String
        : json['id'] as String;

    final snippet = json['snippet'] as Map<String, dynamic>;
    final thumbnails = snippet['thumbnails'] as Map<String, dynamic>;

    final thumbnail = (thumbnails['high'] ??
        thumbnails['medium'] ??
        thumbnails['default']) as Map<String, dynamic>;

    return HighlightModel(
      id: id,
      title: snippet['title'] as String? ?? 'Untitled',
      thumbnail: thumbnail['url'] as String? ?? '',
      videoUrl: 'https://www.youtube.com/watch?v=$id',
      channelTitle: snippet['channelTitle'] as String? ?? '',
      channelId: snippet['channelId'] as String? ?? '',
      publishedAt: DateTime.parse(
        snippet['publishedAt'] as String? ?? DateTime.now().toIso8601String(),
      ),
      description: snippet['description'] as String? ?? '', // ✅ added
    );
  }

  /// Create a copy with updated statistics
  HighlightModel copyWithStats({
    String? duration,
    int? viewCount,
  }) {
    return HighlightModel(
      id: id,
      title: title,
      thumbnail: thumbnail,
      videoUrl: videoUrl,
      channelTitle: channelTitle,
      channelId: channelId,
      duration: duration ?? this.duration,
      viewCount: viewCount ?? this.viewCount,
      publishedAt: publishedAt,
      description: description, // ✅ keep same
    );
  }

  /// Create a copy with any field updated
  HighlightModel copyWith({
    String? id,
    String? title,
    String? thumbnail,
    String? videoUrl,
    String? channelTitle,
    String? channelId,
    String? duration,
    int? viewCount,
    DateTime? publishedAt,
    String? description,
  }) {
    return HighlightModel(
      id: id ?? this.id,
      title: title ?? this.title,
      thumbnail: thumbnail ?? this.thumbnail,
      videoUrl: videoUrl ?? this.videoUrl,
      channelTitle: channelTitle ?? this.channelTitle,
      channelId: channelId ?? this.channelId,
      duration: duration ?? this.duration,
      viewCount: viewCount ?? this.viewCount,
      publishedAt: publishedAt ?? this.publishedAt,
      description: description ?? this.description,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'thumbnail': thumbnail,
      'videoUrl': videoUrl,
      'channelTitle': channelTitle,
      'channelId': channelId,
      'duration': duration,
      'viewCount': viewCount,
      'publishedAt': publishedAt?.toIso8601String(),
      'description': description, // ✅ added
    };
  }

  /// Create from JSON
  factory HighlightModel.fromJson(Map<String, dynamic> json) {
    return HighlightModel(
      id: json['id'] as String,
      title: json['title'] as String,
      thumbnail: json['thumbnail'] as String,
      videoUrl: json['videoUrl'] as String,
      channelTitle: json['channelTitle'] as String? ?? '',
      channelId: json['channelId'] as String? ?? '',
      duration: json['duration'] as String? ?? '',
      viewCount: json['viewCount'] as int? ?? 0,
      publishedAt: DateTime.tryParse(json['publishedAt'] as String? ?? ''),
      description: json['description'] as String? ?? '', // ✅ added
    );
  }

  @override
  List<Object?> get props => [
    id,
    title,
    thumbnail,
    videoUrl,
    channelTitle,
    channelId,
    duration,
    viewCount,
    publishedAt,
    description, // ✅ added
  ];

  @override
  String toString() {
    return 'HighlightModel(id: $id, title: $title, channelTitle: $channelTitle, viewCount: $viewCount)';
  }
}
