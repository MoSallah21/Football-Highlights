import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../logic/cubits/highlights/highlights_cubit.dart';
import '../widgets/highlight_card.dart';

class HighlightsScreen extends StatefulWidget {
  const HighlightsScreen({super.key});

  @override
  State<HighlightsScreen> createState() => _HighlightsScreenState();
}

class _HighlightsScreenState extends State<HighlightsScreen>
    with AutomaticKeepAliveClientMixin {
  // Controllers
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // Focus nodes
  final FocusNode _searchFocusNode = FocusNode();
  final FocusNode _leagueFocusNode = FocusNode();
  final FocusNode _teamFocusNode = FocusNode();
  final FocusNode _refreshFocusNode = FocusNode();
  final FocusNode _clearFocusNode = FocusNode();

  // Grid focus tracking
  final List<FocusNode> _cardFocusNodes = [];
  int _currentCardIndex = 0;

  // State
  String? _selectedLeague;
  String? _selectedTeam;
  bool _isSearching = false;
  List<String> _cachedTeams = [];

  static const Map<String, String> _leagueNames = {
    'all': 'All Leagues',
    'premier': 'Premier League',
    'laliga': 'La Liga',
    'serieA': 'Serie A',
    'bundesliga': 'Bundesliga',
    'ligue1': 'Ligue 1',
    'champions': 'UEFA Champions League',
    'europa': 'UEFA Europa League',
  };

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HighlightsCubit>().loadHighlights();
      _searchFocusNode.requestFocus();
    });

    _searchController.addListener(_onSearchTextChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _searchFocusNode.dispose();
    _leagueFocusNode.dispose();
    _teamFocusNode.dispose();
    _refreshFocusNode.dispose();
    _clearFocusNode.dispose();

    for (var node in _cardFocusNodes) {
      node.dispose();
    }
    _cardFocusNodes.clear();

    super.dispose();
  }

  void _onSearchTextChanged() {
    if (!mounted) return;
    final isSearching = _searchController.text.isNotEmpty;
    if (_isSearching != isSearching) {
      setState(() {
        _isSearching = isSearching;
      });
    }
  }

  void _onLeagueChanged(String? league) {
    setState(() {
      _selectedLeague = league;
      _selectedTeam = null;
      _cachedTeams = [];
      _searchController.clear();
      _currentCardIndex = 0;
    });

    if (league == null || league == 'all') {
      context.read<HighlightsCubit>().loadHighlights();
    } else {
      context.read<HighlightsCubit>().loadLeagueHighlights(league);
      _cachedTeams = context.read<HighlightsCubit>().getTeamsForLeague(league);
    }
  }

  void _onTeamChanged(String? team) {
    setState(() {
      _selectedTeam = team;
      _searchController.clear();
      _currentCardIndex = 0;
    });

    if (team == null || team.isEmpty) {
      if (_selectedLeague != null && _selectedLeague != 'all') {
        context.read<HighlightsCubit>().loadLeagueHighlights(_selectedLeague!);
      } else {
        context.read<HighlightsCubit>().loadHighlights();
      }
    } else {
      if (_selectedLeague != null && _selectedLeague != 'all') {
        context.read<HighlightsCubit>().loadLeagueTeamHighlights(_selectedLeague!, team);
      } else {
        context.read<HighlightsCubit>().loadTeamHighlights(team);
      }
    }
  }

  void _onSearch() {
    final searchText = _searchController.text.trim();
    if (searchText.isEmpty) {
      _applyCurrentFilters();
      return;
    }

    setState(() {
      _selectedTeam = searchText;
      _currentCardIndex = 0;
    });

    if (_selectedLeague != null && _selectedLeague != 'all') {
      context.read<HighlightsCubit>().loadLeagueTeamHighlights(
        _selectedLeague!,
        searchText,
      );
    } else {
      context.read<HighlightsCubit>().loadTeamHighlights(searchText);
    }
  }

  void _applyCurrentFilters() {
    final cubit = context.read<HighlightsCubit>();

    if (_selectedTeam != null && _selectedTeam!.isNotEmpty) {
      if (_selectedLeague != null && _selectedLeague != 'all') {
        cubit.loadLeagueTeamHighlights(_selectedLeague!, _selectedTeam!);
      } else {
        cubit.loadTeamHighlights(_selectedTeam!);
      }
    } else if (_selectedLeague != null && _selectedLeague != 'all') {
      cubit.loadLeagueHighlights(_selectedLeague!);
    } else {
      cubit.loadHighlights();
    }
  }

  void _clearFilters() {
    setState(() {
      _selectedLeague = null;
      _selectedTeam = null;
      _searchController.clear();
      _isSearching = false;
      _cachedTeams = [];
      _currentCardIndex = 0;
    });

    context.read<HighlightsCubit>().clearFilters();
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) _searchFocusNode.requestFocus();
    });
  }

  void _clearSearch() {
    _searchController.clear();
    _searchFocusNode.unfocus();

    setState(() {
      _isSearching = false;
      if (_selectedTeam != null && !_getTeamsForSelectedLeague().contains(_selectedTeam)) {
        _selectedTeam = null;
      }
    });

    _applyCurrentFilters();
  }

  List<String> _getTeamsForSelectedLeague() {
    if (_cachedTeams.isNotEmpty) return _cachedTeams;
    if (_selectedLeague == null || _selectedLeague == 'all') {
      return [];
    }
    _cachedTeams = context.read<HighlightsCubit>().getTeamsForLeague(_selectedLeague!);
    return _cachedTeams;
  }

  void _focusCard(int index) {
    if (index >= 0 && index < _cardFocusNodes.length) {
      setState(() {
        _currentCardIndex = index;
      });
      _cardFocusNodes[index].requestFocus();

      // Auto-scroll to keep focused card visible
      _scrollToCard(index);
    }
  }

  void _scrollToCard(int index) {
    final crossAxisCount = MediaQuery.of(context).size.width > 1200 ? 4 : 3;
    final row = index ~/ crossAxisCount;

    // Calculate approximate position
    final itemHeight = (MediaQuery.of(context).size.width > 1200 ? 300.0 : 250.0);
    final targetPosition = row * itemHeight;

    _scrollController.animateTo(
      targetPosition,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _ensureCardFocusNodes(int count) {
    while (_cardFocusNodes.length < count) {
      _cardFocusNodes.add(FocusNode());
    }

    while (_cardFocusNodes.length > count) {
      _cardFocusNodes.removeLast().dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth > 1200;

    // CRITICAL FIX: Handle back button to exit app
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          // Exit the app when back is pressed
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Column(
          children: [
            _buildHeader(isLargeScreen),
            Expanded(
              child: BlocConsumer<HighlightsCubit, HighlightsState>(
                listener: (context, state) {
                  if (state is HighlightsLoaded) {
                    _ensureCardFocusNodes(state.highlights.length);
                  }
                },
                builder: (context, state) {
                  return _buildContent(state, isLargeScreen);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isLargeScreen) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isLargeScreen ? 60 : 40,
        vertical: 30,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black,
            Colors.black.withOpacity(0.8),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Image.asset(
                'assets/images/logo.png',
                width: 60,
                height: 60,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(
                    Icons.sports_soccer,
                    size: 60,
                    color: Colors.white,
                  );
                },
              ),
              const SizedBox(width: 20),
              const Text(
                'Football Highlights',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 42,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (_selectedLeague != null || _selectedTeam != null)
                _buildActiveFiltersIndicator(),
              const SizedBox(width: 20),
              _buildRefreshButton(),
            ],
          ),
          const SizedBox(height: 30),
          _buildFiltersRow(isLargeScreen),
        ],
      ),
    );
  }

  Widget _buildActiveFiltersIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.blue.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.filter_alt, color: Colors.blue, size: 20),
          const SizedBox(width: 8),
          Text(
            'Active Filters: ${_getActiveFiltersCount()}',
            style: const TextStyle(
              color: Colors.blue,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  int _getActiveFiltersCount() {
    int count = 0;
    if (_selectedLeague != null && _selectedLeague != 'all') count++;
    if (_selectedTeam != null) count++;
    return count;
  }

  Widget _buildRefreshButton() {
    return _FocusableButton(
      focusNode: _refreshFocusNode,
      onTap: () => context.read<HighlightsCubit>().refresh(),
      onKeyEvent: (event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.arrowDown ||
              event.logicalKey == LogicalKeyboardKey.arrowLeft) {
            _searchFocusNode.requestFocus();
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      builder: (hasFocus) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: hasFocus
              ? Colors.blue.withOpacity(0.3)
              : Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasFocus ? Colors.blue : Colors.white.withOpacity(0.3),
            width: 2,
          ),
        ),
        child: const Icon(Icons.refresh, color: Colors.white, size: 32),
      ),
    );
  }

  Widget _buildFiltersRow(bool isLargeScreen) {
    return Row(
      children: [
        Expanded(flex: 2, child: _buildSearchBar()),
        const SizedBox(width: 20),
        Expanded(child: _buildLeagueDropdown()),
        const SizedBox(width: 20),
        if (_selectedLeague != null &&
            _selectedLeague != 'all' &&
            _getTeamsForSelectedLeague().isNotEmpty) ...[
          Expanded(child: _buildTeamDropdown()),
          const SizedBox(width: 20),
        ],
        if (_selectedLeague != null || _selectedTeam != null)
          _buildClearButton(),
      ],
    );
  }

  Widget _buildSearchBar() {
    return _SearchBarWidget(
      controller: _searchController,
      focusNode: _searchFocusNode,
      selectedLeague: _selectedLeague,
      leagueNames: _leagueNames,
      isSearching: _isSearching,
      onClearSearch: _clearSearch,
      onSubmitted: (_) {
        _onSearch();
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted && _cardFocusNodes.isNotEmpty) {
            _focusCard(0);
          }
        });
      },
      onArrowRight: () => _leagueFocusNode.requestFocus(),
      onArrowUp: () => _refreshFocusNode.requestFocus(),
      onArrowDown: () {
        if (_cardFocusNodes.isNotEmpty) {
          _focusCard(0);
        }
      },
    );
  }

  Widget _buildLeagueDropdown() {
    return _FocusableContainer(
      focusNode: _leagueFocusNode,
      onKeyEvent: (event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
            _searchFocusNode.requestFocus();
            return KeyEventResult.handled;
          }
          if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
            if (_selectedLeague != null &&
                _selectedLeague != 'all' &&
                _getTeamsForSelectedLeague().isNotEmpty) {
              _teamFocusNode.requestFocus();
            } else if (_selectedLeague != null || _selectedTeam != null) {
              _clearFocusNode.requestFocus();
            }
            return KeyEventResult.handled;
          }
          if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
            if (_cardFocusNodes.isNotEmpty) {
              _focusCard(0);
              return KeyEventResult.handled;
            }
          }
          if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
            _refreshFocusNode.requestFocus();
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      builder: (hasFocus) => Container(
        height: 70,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasFocus ? Colors.blue : Colors.white.withOpacity(0.3),
            width: 2,
          ),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: _selectedLeague,
            hint: const Text(
              'Select League',
              style: TextStyle(color: Colors.white70, fontSize: 20),
            ),
            isExpanded: true,
            icon: const Icon(Icons.arrow_drop_down, color: Colors.white, size: 32),
            dropdownColor: Colors.grey[900],
            style: const TextStyle(color: Colors.white, fontSize: 20),
            items: _leagueNames.entries.map((entry) {
              return DropdownMenuItem<String>(
                value: entry.key,
                child: Text(entry.value),
              );
            }).toList(),
            onChanged: (value) {
              _onLeagueChanged(value);
              Future.delayed(const Duration(milliseconds: 100), () {
                if (mounted) _leagueFocusNode.requestFocus();
              });
            },
          ),
        ),
      ),
    );
  }

  Widget _buildTeamDropdown() {
    return _FocusableContainer(
      focusNode: _teamFocusNode,
      onKeyEvent: (event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
            _leagueFocusNode.requestFocus();
            return KeyEventResult.handled;
          }
          if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
            if (_selectedLeague != null || _selectedTeam != null) {
              _clearFocusNode.requestFocus();
            }
            return KeyEventResult.handled;
          }
          if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
            if (_cardFocusNodes.isNotEmpty) {
              _focusCard(0);
              return KeyEventResult.handled;
            }
          }
          if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
            _refreshFocusNode.requestFocus();
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      builder: (hasFocus) => Container(
        height: 70,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasFocus ? Colors.blue : Colors.white.withOpacity(0.3),
            width: 2,
          ),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: _selectedTeam,
            hint: const Text(
              'Select Team',
              style: TextStyle(color: Colors.white70, fontSize: 20),
            ),
            isExpanded: true,
            icon: const Icon(Icons.arrow_drop_down, color: Colors.white, size: 32),
            dropdownColor: Colors.grey[900],
            style: const TextStyle(color: Colors.white, fontSize: 20),
            items: [
              const DropdownMenuItem<String>(
                value: null,
                child: Text(
                  'All Teams',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              ..._getTeamsForSelectedLeague().map((team) {
                return DropdownMenuItem<String>(
                  value: team,
                  child: Text(team),
                );
              }),
            ],
            onChanged: (value) {
              _onTeamChanged(value);
              Future.delayed(const Duration(milliseconds: 100), () {
                if (mounted) _teamFocusNode.requestFocus();
              });
            },
          ),
        ),
      ),
    );
  }

  Widget _buildClearButton() {
    return _FocusableButton(
      focusNode: _clearFocusNode,
      onTap: _clearFilters,
      onKeyEvent: (event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
            if (_selectedLeague != null &&
                _selectedLeague != 'all' &&
                _getTeamsForSelectedLeague().isNotEmpty) {
              _teamFocusNode.requestFocus();
            } else {
              _leagueFocusNode.requestFocus();
            }
            return KeyEventResult.handled;
          }
          if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
            if (_cardFocusNodes.isNotEmpty) {
              _focusCard(0);
              return KeyEventResult.handled;
            }
          }
          if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
            _refreshFocusNode.requestFocus();
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      builder: (hasFocus) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        decoration: BoxDecoration(
          color: hasFocus
              ? Colors.red.withOpacity(0.3)
              : Colors.red.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasFocus ? Colors.red : Colors.red.withOpacity(0.5),
            width: 2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.clear_all, color: Colors.red, size: 28),
            SizedBox(width: 8),
            Text(
              'Clear',
              style: TextStyle(
                color: Colors.red,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(HighlightsState state, bool isLargeScreen) {
    if (state is HighlightsLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Colors.white,
          strokeWidth: 5,
        ),
      );
    }

    if (state is HighlightsError) {
      return _buildErrorState(state.message);
    }

    if (state is HighlightsLoaded) {
      if (state.highlights.isEmpty) {
        return _buildEmptyState();
      }

      return _buildGrid(state, isLargeScreen);
    }

    return const SizedBox.shrink();
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 100, color: Colors.red),
          const SizedBox(height: 30),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 100),
            child: Text(
              'Error: $message',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24, color: Colors.white),
            ),
          ),
          const SizedBox(height: 30),
          Focus(
            autofocus: true,
            onKeyEvent: (node, event) {
              if (event is KeyDownEvent &&
                  event.logicalKey == LogicalKeyboardKey.arrowUp) {
                _searchFocusNode.requestFocus();
                return KeyEventResult.handled;
              }
              return KeyEventResult.ignored;
            },
            child: ElevatedButton(
              onPressed: () {
                context.read<HighlightsCubit>().refresh();
                _searchFocusNode.requestFocus();
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                textStyle: const TextStyle(fontSize: 22),
              ),
              child: const Text('Retry'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    String message = 'Try changing the filters';

    if (_selectedTeam != null) {
      message = _selectedLeague != null && _selectedLeague != 'all'
          ? 'No videos found for "$_selectedTeam" in ${_leagueNames[_selectedLeague]}'
          : 'No videos found for "$_selectedTeam"';
    } else if (_selectedLeague != null && _selectedLeague != 'all') {
      message = 'No videos found for ${_leagueNames[_selectedLeague]}';
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.video_library_outlined, size: 100, color: Colors.grey),
          const SizedBox(height: 30),
          const Text(
            'No Videos Found',
            style: TextStyle(fontSize: 28, color: Colors.white),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 100),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20, color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid(HighlightsLoaded state, bool isLargeScreen) {
    final crossAxisCount = isLargeScreen ? 4 : 3;

    return GridView.builder(
      controller: _scrollController,
      padding: EdgeInsets.all(isLargeScreen ? 60 : 40),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: 16 / 11,
        crossAxisSpacing: 24,
        mainAxisSpacing: 24,
      ),
      cacheExtent: 1000,
      itemCount: state.highlights.length,
      itemBuilder: (context, index) {
        final highlight = state.highlights[index];
        final row = index ~/ crossAxisCount;
        final col = index % crossAxisCount;

        return Focus(
          focusNode: _cardFocusNodes[index],
          onKeyEvent: (node, event) {
            if (event is KeyDownEvent) {
              // Up arrow
              if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
                if (row == 0) {
                  if (_selectedLeague != null || _selectedTeam != null) {
                    _clearFocusNode.requestFocus();
                  } else {
                    _leagueFocusNode.requestFocus();
                  }
                } else {
                  final targetIndex = index - crossAxisCount;
                  if (targetIndex >= 0) {
                    _focusCard(targetIndex);
                  }
                }
                return KeyEventResult.handled;
              }

              // Down arrow
              if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
                final targetIndex = index + crossAxisCount;
                if (targetIndex < state.highlights.length) {
                  _focusCard(targetIndex);
                }
                return KeyEventResult.handled;
              }

              // Left arrow
              if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
                if (col > 0) {
                  _focusCard(index - 1);
                }
                return KeyEventResult.handled;
              }

              // Right arrow
              if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
                if (col < crossAxisCount - 1 && index + 1 < state.highlights.length) {
                  _focusCard(index + 1);
                }
                return KeyEventResult.handled;
              }
            }
            return KeyEventResult.ignored;
          },
          child: HighlightCard(
            highlight: highlight,
            focusOrder: index,
          ),
        );
      },
    );
  }
}

class _FocusableContainer extends StatefulWidget {
  final FocusNode focusNode;
  final Widget Function(bool hasFocus) builder;
  final KeyEventResult Function(KeyEvent)? onKeyEvent;

  const _FocusableContainer({
    required this.focusNode,
    required this.builder,
    this.onKeyEvent,
  });

  @override
  State<_FocusableContainer> createState() => _FocusableContainerState();
}

class _FocusableContainerState extends State<_FocusableContainer> {
  bool _hasFocus = false;

  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_onFocusChange);
    _hasFocus = widget.focusNode.hasFocus;
  }

  @override
  void didUpdateWidget(_FocusableContainer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      oldWidget.focusNode.removeListener(_onFocusChange);
      widget.focusNode.addListener(_onFocusChange);
      _hasFocus = widget.focusNode.hasFocus;
    }
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_onFocusChange);
    super.dispose();
  }

  void _onFocusChange() {
    if (mounted && _hasFocus != widget.focusNode.hasFocus) {
      setState(() {
        _hasFocus = widget.focusNode.hasFocus;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: widget.focusNode,
      onKeyEvent: widget.onKeyEvent != null
          ? (node, event) => widget.onKeyEvent!(event)
          : null,
      child: widget.builder(_hasFocus),
    );
  }
}

class _FocusableButton extends StatefulWidget {
  final FocusNode focusNode;
  final VoidCallback onTap;
  final Widget Function(bool hasFocus) builder;
  final KeyEventResult Function(KeyEvent)? onKeyEvent;

  const _FocusableButton({
    required this.focusNode,
    required this.onTap,
    required this.builder,
    this.onKeyEvent,
  });

  @override
  State<_FocusableButton> createState() => _FocusableButtonState();
}

class _FocusableButtonState extends State<_FocusableButton> {
  bool _hasFocus = false;

  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_onFocusChange);
    _hasFocus = widget.focusNode.hasFocus;
  }

  @override
  void didUpdateWidget(_FocusableButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      oldWidget.focusNode.removeListener(_onFocusChange);
      widget.focusNode.addListener(_onFocusChange);
      _hasFocus = widget.focusNode.hasFocus;
    }
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_onFocusChange);
    super.dispose();
  }

  void _onFocusChange() {
    if (mounted && _hasFocus != widget.focusNode.hasFocus) {
      setState(() {
        _hasFocus = widget.focusNode.hasFocus;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: widget.focusNode,
      onKeyEvent: widget.onKeyEvent != null
          ? (node, event) => widget.onKeyEvent!(event)
          : null,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(12),
          child: widget.builder(_hasFocus),
        ),
      ),
    );
  }
}

class _SearchBarWidget extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String? selectedLeague;
  final Map<String, String> leagueNames;
  final bool isSearching;
  final VoidCallback onClearSearch;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onArrowRight;
  final VoidCallback onArrowUp;
  final VoidCallback onArrowDown;

  const _SearchBarWidget({
    required this.controller,
    required this.focusNode,
    required this.selectedLeague,
    required this.leagueNames,
    required this.isSearching,
    required this.onClearSearch,
    required this.onSubmitted,
    required this.onArrowRight,
    required this.onArrowUp,
    required this.onArrowDown,
  });

  @override
  State<_SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<_SearchBarWidget> {
  bool _hasFocus = false;

  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_onFocusChange);
    _hasFocus = widget.focusNode.hasFocus;
  }

  @override
  void didUpdateWidget(_SearchBarWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      oldWidget.focusNode.removeListener(_onFocusChange);
      widget.focusNode.addListener(_onFocusChange);
      _hasFocus = widget.focusNode.hasFocus;
    }
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_onFocusChange);
    super.dispose();
  }

  void _onFocusChange() {
    if (mounted && _hasFocus != widget.focusNode.hasFocus) {
      setState(() {
        _hasFocus = widget.focusNode.hasFocus;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _hasFocus ? Colors.blue : Colors.white.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: TextField(
        controller: widget.controller,
        focusNode: widget.focusNode,
        style: const TextStyle(color: Colors.white, fontSize: 20),
        decoration: InputDecoration(
          hintText: widget.selectedLeague != null && widget.selectedLeague != 'all'
              ? 'Search in ${widget.leagueNames[widget.selectedLeague]}...'
              : 'Search for a team...',
          hintStyle: TextStyle(
            color: Colors.white.withOpacity(0.5),
            fontSize: 20,
          ),
          prefixIcon: const Icon(Icons.search, color: Colors.white, size: 32),
          suffixIcon: widget.isSearching
              ? IconButton(
            icon: const Icon(Icons.clear, color: Colors.white, size: 32),
            onPressed: widget.onClearSearch,
          )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 20,
          ),
        ),
        onSubmitted: widget.onSubmitted,
      ),
    );
  }
}