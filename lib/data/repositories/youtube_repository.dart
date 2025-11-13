import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/highlight_model.dart';

/// Repository to fetch football highlights and live streams from YouTube
class YouTubeRepository {
  static const String _apiKey = 'AIzaSyC1NcIyvKvQdjFP0Etl1nNeZwtUkoayKFc';
  static const String _baseUrl = 'https://www.googleapis.com/youtube/v3';

  static const Map<String, String> topLeagues = {
    'all': 'Premier League OR La Liga OR Serie A OR Bundesliga OR Ligue 1',
    'premier': 'Premier League',
    'laliga': 'La Liga',
    'serieA': 'Serie A',
    'bundesliga': 'Bundesliga',
    'ligue1': 'Ligue 1',
    'champions': 'UEFA Champions League',
    'europa': 'UEFA Europa League',
  };

  static const Map<String, List<String>> topTeams = {
    'premier': [
      'Manchester City',
      'Arsenal',
      'Liverpool',
      'Manchester United',
      'Chelsea',
      'Tottenham',
      'Newcastle',
      'Brighton'
    ],
    'laliga': [
      'Real Madrid',
      'Barcelona',
      'Atletico Madrid',
      'Real Sociedad',
      'Athletic Bilbao',
      'Real Betis',
      'Villarreal',
      'Sevilla'
    ],
    'serieA': [
      'Inter Milan',
      'AC Milan',
      'Juventus',
      'Napoli',
      'Roma',
      'Lazio',
      'Atalanta',
      'Fiorentina'
    ],
    'bundesliga': [
      'Bayern Munich',
      'Borussia Dortmund',
      'RB Leipzig',
      'Bayer Leverkusen',
      'Union Berlin',
      'Eintracht Frankfurt',
      'Wolfsburg',
      'Borussia Monchengladbach'
    ],
    'ligue1': [
      'PSG',
      'Paris Saint-Germain',
      'Marseille',
      'Monaco',
      'Lyon',
      'Lille',
      'Lens',
      'Rennes'
    ],
  };

  String _buildSearchUrl({
    required String query,
    int maxResults = 50,
    String type = 'video',
    String order = 'date',
    String eventType = '',
  }) {
    final buffer = StringBuffer(
        '$_baseUrl/search?part=snippet&q=$query&type=$type&maxResults=$maxResults&key=$_apiKey');

    if (order.isNotEmpty) buffer.write('&order=$order');
    if (eventType.isNotEmpty) buffer.write('&eventType=$eventType');
    buffer.write('&videoDuration=medium&videoDefinition=high');

    return buffer.toString();
  }

  /// Fetch recent football highlights with league filter
  Future<List<HighlightModel>> fetchHighlights({
    int maxResults = 50,
    String? leagueFilter, // 'all', 'premier', 'laliga', etc.
    String? teamName, // اسم الفريق للبحث المحدد
  }) async {
    try {
      String query;

      if (teamName != null && teamName.isNotEmpty) {
        // البحث عن فريق محدد
        query = 'football highlights $teamName';
      } else {
        // البحث حسب الدوري
        final leagues = leagueFilter != null && topLeagues.containsKey(leagueFilter)
            ? topLeagues[leagueFilter]!
            : topLeagues['all']!;
        query = 'football highlights $leagues';
      }

      final url = Uri.parse(_buildSearchUrl(query: query, maxResults: maxResults));

      final response = await http.get(url);
      if (response.statusCode != 200) {
        throw Exception('Failed to fetch highlights: ${response.statusCode}');
      }

      final data = json.decode(response.body) as Map<String, dynamic>;
      final items = data['items'] as List<dynamic>? ?? [];

      final highlights = items
          .map((item) => HighlightModel.fromYouTubeApi(item as Map<String, dynamic>))
          .toList();

      return await _enrichWithStatistics(highlights);
    } catch (e) {
      throw Exception('Failed to fetch highlights: $e');
    }
  }

  /// Fetch highlights for specific team
  Future<List<HighlightModel>> fetchTeamHighlights({
    required String teamName,
    int maxResults = 50,
  }) async {
    return fetchHighlights(teamName: teamName, maxResults: maxResults);
  }

  /// Fetch highlights filtered by league and optional team
  Future<List<HighlightModel>> fetchLeagueHighlights({
    required String league, // 'premier', 'laliga', etc.
    String? teamFilter, // optional: filter by specific team
    int maxResults = 50,
  }) async {
    try {
      final leagueQuery = topLeagues[league] ?? topLeagues['all']!;
      final query = teamFilter != null && teamFilter.isNotEmpty
          ? 'football highlights $leagueQuery $teamFilter'
          : 'football highlights $leagueQuery';

      final url = Uri.parse(_buildSearchUrl(query: query, maxResults: maxResults));

      final response = await http.get(url);
      if (response.statusCode != 200) {
        throw Exception('Failed to fetch league highlights: ${response.statusCode}');
      }

      final data = json.decode(response.body) as Map<String, dynamic>;
      final items = data['items'] as List<dynamic>? ?? [];

      final highlights = items
          .map((item) => HighlightModel.fromYouTubeApi(item as Map<String, dynamic>))
          .toList();

      return await _enrichWithStatistics(highlights);
    } catch (e) {
      throw Exception('Failed to fetch league highlights: $e');
    }
  }

  /// Fetch highlights for top teams only
  Future<List<HighlightModel>> fetchTopTeamsHighlights({
    String? league, // null = all leagues, or specific league
    int maxResults = 50,
  }) async {
    try {
      List<String> teams = [];

      if (league != null && topTeams.containsKey(league)) {
        teams = topTeams[league]!;
      } else {
        // جمع كل الفرق الكبرى من جميع الدوريات
        topTeams.values.forEach((teamList) => teams.addAll(teamList));
      }

      final teamsQuery = teams.join(' OR ');
      final query = 'football highlights ($teamsQuery)';

      final url = Uri.parse(_buildSearchUrl(query: query, maxResults: maxResults));

      final response = await http.get(url);
      if (response.statusCode != 200) {
        throw Exception('Failed to fetch top teams highlights: ${response.statusCode}');
      }

      final data = json.decode(response.body) as Map<String, dynamic>;
      final items = data['items'] as List<dynamic>? ?? [];

      final highlights = items
          .map((item) => HighlightModel.fromYouTubeApi(item as Map<String, dynamic>))
          .toList();

      return await _enrichWithStatistics(highlights);
    } catch (e) {
      throw Exception('Failed to fetch top teams highlights: $e');
    }
  }

  /// Fetch live football streams
  Future<List<HighlightModel>> fetchLiveStreams({
    int maxResults = 50,
    String? teamName,
  }) async {
    try {
      final query = teamName != null && teamName.isNotEmpty
          ? 'football live $teamName'
          : 'football live';

      final url = Uri.parse(_buildSearchUrl(
        query: query,
        maxResults: maxResults,
        order: 'viewCount',
        eventType: 'live',
      ));

      final response = await http.get(url);
      if (response.statusCode != 200) {
        throw Exception('Failed to fetch live streams: ${response.statusCode}');
      }

      final data = json.decode(response.body) as Map<String, dynamic>;
      final items = data['items'] as List<dynamic>? ?? [];

      return items
          .map((item) => HighlightModel.fromYouTubeApi(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch live streams: $e');
    }
  }

  /// Optional: Fetch highlights from a specific football channel
  Future<List<HighlightModel>> fetchHighlightsByChannel({
    required String channelId,
    int maxResults = 50,
  }) async {
    try {
      final url = Uri.parse('${_buildSearchUrl(
        query: 'football',
        maxResults: maxResults,
        type: 'video',
        order: 'date',
      )}&channelId=$channelId');

      final response = await http.get(url);
      if (response.statusCode != 200) {
        throw Exception('Failed to fetch channel highlights: ${response.statusCode}');
      }

      final data = json.decode(response.body) as Map<String, dynamic>;
      final items = data['items'] as List<dynamic>? ?? [];

      final highlights = items
          .map((item) => HighlightModel.fromYouTubeApi(item as Map<String, dynamic>))
          .toList();

      return await _enrichWithStatistics(highlights);
    } catch (e) {
      throw Exception('Failed to fetch channel highlights: $e');
    }
  }

  /// Add video duration and view count to highlights
  Future<List<HighlightModel>> _enrichWithStatistics(
      List<HighlightModel> highlights) async {
    if (highlights.isEmpty) return highlights;

    try {
      final videoIds = highlights.map((h) => h.id).join(',');
      final detailsUrl = Uri.parse(
          '$_baseUrl/videos?part=contentDetails,statistics&id=$videoIds&key=$_apiKey');

      final response = await http.get(detailsUrl);
      if (response.statusCode != 200) return highlights;

      final data = json.decode(response.body) as Map<String, dynamic>;
      final items = data['items'] as List<dynamic>? ?? [];

      final statsMap = <String, Map<String, dynamic>>{};
      for (final item in items) {
        statsMap[item['id'] as String] = item as Map<String, dynamic>;
      }

      return highlights.map((highlight) {
        final stats = statsMap[highlight.id];
        if (stats == null) return highlight;

        final contentDetails = stats['contentDetails'] as Map<String, dynamic>? ?? {};
        final statistics = stats['statistics'] as Map<String, dynamic>? ?? {};

        return highlight.copyWithStats(
          duration: _parseDuration(contentDetails['duration'] as String? ?? ''),
          viewCount: int.tryParse(statistics['viewCount'] as String? ?? '0') ?? 0,
        );
      }).toList();
    } catch (e) {
      return highlights;
    }
  }

  /// Convert ISO 8601 duration to readable format
  String _parseDuration(String isoDuration) {
    final regex = RegExp(r'PT(?:(\d+)H)?(?:(\d+)M)?(?:(\d+)S)?');
    final match = regex.firstMatch(isoDuration);

    if (match == null) return '';

    final hours = int.tryParse(match.group(1) ?? '0') ?? 0;
    final minutes = int.tryParse(match.group(2) ?? '0') ?? 0;
    final seconds = int.tryParse(match.group(3) ?? '0') ?? 0;

    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      return '$minutes:${seconds.toString().padLeft(2, '0')}';
    }
  }

  /// Get list of available leagues
  static List<String> getAvailableLeagues() {
    return topLeagues.keys.toList();
  }

  /// Get teams for a specific league
  static List<String> getTeamsForLeague(String league) {
    return topTeams[league] ?? [];
  }

  /// Get all top teams
  static List<String> getAllTopTeams() {
    final allTeams = <String>[];
    topTeams.values.forEach((teams) => allTeams.addAll(teams));
    return allTeams;
  }
}