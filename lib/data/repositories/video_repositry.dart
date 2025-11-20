import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/video_model.dart';

class VideoRepository {
  final String token =
      "fxjmkalkxb5jlnm:LCbHAhym44Ttva6ORuiC";

  /// Fetch all videos
  Future<List<VideoModel>> fetchVideos() async {
    final url =
        "https://api.majidapi.ir/varzesh3?action=videos&token=$token";

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => VideoModel.fromJson(e)).toList();
    } else {
      throw Exception("Failed to load videos list");
    }
  }

  /// Fetch single video by ID
  Future<VideoModel> fetchVideoById(int id) async {
    final url =
        "https://api.majidapi.ir/varzesh3?action=video&id=$id&token=$token";

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return VideoModel.fromJson(data);
    } else {
      throw Exception("Failed to load video");
    }
  }
}
