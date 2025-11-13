import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/highlight_model.dart';
import '../models/banner_model.dart';

/// Repository handling Firestore data operations
class FirestoreRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Fetch all highlight documents from Firestore
  Future<List<HighlightModel>> fetchHighlights() async {
    try {
      final snapshot = await _firestore.collection('highlights').get();
      return snapshot.docs
          .map((doc) => HighlightModel.fromYouTubeApi(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch highlights: $e');
    }
  }

  /// Fetch all banner documents from Firestore
  Future<List<BannerModel>> fetchBanners() async {
    try {
      final snapshot = await _firestore.collection('banners').get();
      return snapshot.docs
          .map((doc) => BannerModel.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch banners: $e');
    }
  }
}