class VideoModel {
  final int id;
  final String title;
  final String image;

  VideoModel({
    required this.id,
    required this.title,
    required this.image,
  });

  factory VideoModel.fromJson(Map<String, dynamic> json) {
    return VideoModel(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      image: json['image'] ?? '',
    );
  }
}
