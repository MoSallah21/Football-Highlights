import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/models/highlight_model.dart';
import '../../../data/repositories/youtube_repository.dart';

part 'highlights_state.dart';

/// Cubit managing highlights data from YouTube API with filters
class HighlightsCubit extends Cubit<HighlightsState> {
  final YouTubeRepository _repository;

  // Current filter state
  String? _currentLeague;
  String? _currentTeam;
  bool _showOnlyTopTeams = false;

  HighlightsCubit(this._repository) : super(HighlightsLoading());

  // Getters for current filters
  String? get currentLeague => _currentLeague;
  String? get currentTeam => _currentTeam;
  bool get showOnlyTopTeams => _showOnlyTopTeams;

  /// Load recent football highlights with optional filters
  Future<void> loadHighlights({
    String? leagueFilter,
    String? teamName,
    bool onlyTopTeams = false,
  }) async {
    emit(HighlightsLoading());

    // Save current filter state
    _currentLeague = leagueFilter;
    _currentTeam = teamName;
    _showOnlyTopTeams = onlyTopTeams;

    try {
      List<HighlightModel> highlights;

      if (onlyTopTeams) {
        // Get only top teams highlights
        highlights = await _repository.fetchTopTeamsHighlights(
          league: leagueFilter,
          maxResults: 50,
        );
      } else if (teamName != null && teamName.isNotEmpty) {
        // Search for specific team
        highlights = await _repository.fetchTeamHighlights(
          teamName: teamName,
          maxResults: 50,
        );
      } else if (leagueFilter != null) {
        // Filter by league
        highlights = await _repository.fetchLeagueHighlights(
          league: leagueFilter,
          maxResults: 50,
        );
      } else {
        // Default: all highlights
        highlights = await _repository.fetchHighlights(
          maxResults: 50,
        );
      }

      emit(HighlightsLoaded(highlights));
    } catch (e) {
      emit(HighlightsError(e.toString()));
    }
  }

  /// Load highlights for a specific team
  Future<void> loadTeamHighlights(String teamName) async {
    await loadHighlights(teamName: teamName);
  }

  /// Load highlights for a specific league
  Future<void> loadLeagueHighlights(String league) async {
    await loadHighlights(leagueFilter: league);
  }

  /// Load highlights for top teams only
  Future<void> loadTopTeamsHighlights({String? league}) async {
    await loadHighlights(leagueFilter: league, onlyTopTeams: true);
  }

  /// Load highlights with league and team filter
  Future<void> loadLeagueTeamHighlights(String league, String team) async {
    emit(HighlightsLoading());
    _currentLeague = league;
    _currentTeam = team;
    _showOnlyTopTeams = false;

    try {
      final highlights = await _repository.fetchLeagueHighlights(
        league: league,
        teamFilter: team,
        maxResults: 50,
      );
      emit(HighlightsLoaded(highlights));
    } catch (e) {
      emit(HighlightsError(e.toString()));
    }
  }

  /// Load live football streams
  Future<void> loadLiveStreams({String? teamName}) async {
    emit(HighlightsLoading());
    _currentTeam = teamName;

    try {
      final highlights = await _repository.fetchLiveStreams(
        maxResults: 50,
        teamName: teamName,
      );
      emit(HighlightsLoaded(highlights, isLive: true));
    } catch (e) {
      emit(HighlightsError(e.toString()));
    }
  }

  /// Load highlights from specific channel
  Future<void> loadChannelHighlights(String channelId) async {
    emit(HighlightsLoading());
    try {
      final highlights = await _repository.fetchHighlightsByChannel(
        channelId: channelId,
        maxResults: 50,
      );
      emit(HighlightsLoaded(highlights));
    } catch (e) {
      emit(HighlightsError(e.toString()));
    }
  }

  /// Clear all filters and load all highlights
  Future<void> clearFilters() async {
    _currentLeague = null;
    _currentTeam = null;
    _showOnlyTopTeams = false;
    await loadHighlights();
  }

  /// Refresh with current filters
  Future<void> refresh() async {
    await loadHighlights(
      leagueFilter: _currentLeague,
      teamName: _currentTeam,
      onlyTopTeams: _showOnlyTopTeams,
    );
  }

  /// Get available leagues
  List<String> getAvailableLeagues() {
    return YouTubeRepository.getAvailableLeagues();
  }

  /// Get teams for a specific league
  List<String> getTeamsForLeague(String league) {
    return YouTubeRepository.getTeamsForLeague(league);
  }

  /// Get all top teams
  List<String> getAllTopTeams() {
    return YouTubeRepository.getAllTopTeams();
  }
}