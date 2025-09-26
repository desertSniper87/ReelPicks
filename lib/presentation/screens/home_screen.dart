import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/recommendation_provider.dart';
import '../providers/user_provider.dart';
import '../widgets/genre_filter.dart';
import '../widgets/movie_card.dart';

/// Home screen with swipe interface for movie recommendations
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _showGenreFilter = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeData();
    });
  }

  Future<void> _initializeData() async {
    final recommendationProvider = context.read<RecommendationProvider>();
    final userProvider = context.read<UserProvider>();
    
    // Load genres first
    await recommendationProvider.loadGenres();
    
    // Load initial recommendations
    final userProfile = userProvider.userProfile;
    if (userProfile?.isAuthenticated == true) {
      await recommendationProvider.loadPersonalizedRecommendations(userProfile!);
    } else {
      await recommendationProvider.loadPopularMovies();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Movie Recommendations'),
        actions: [
          IconButton(
            icon: Icon(_showGenreFilter ? Icons.filter_list_off : Icons.filter_list),
            onPressed: () {
              setState(() {
                _showGenreFilter = !_showGenreFilter;
              });
            },
            tooltip: _showGenreFilter ? 'Hide Filters' : 'Show Filters',
          ),
        ],
      ),
      body: Consumer2<RecommendationProvider, UserProvider>(
        builder: (context, recommendationProvider, userProvider, child) {
          return Column(
            children: [
              // Genre Filter Section
              if (_showGenreFilter) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                    border: Border(
                      bottom: BorderSide(
                        color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                      ),
                    ),
                  ),
                  child: GenreFilter(
                    availableGenres: recommendationProvider.availableGenres,
                    selectedGenres: recommendationProvider.selectedGenres,
                    isLoading: recommendationProvider.isLoadingGenres,
                    onGenresChanged: (selectedGenres) async {
                      await recommendationProvider.applyGenreFilterRealTime(
                        selectedGenres,
                        userProvider.userProfile,
                      );
                    },
                  ),
                ),
              ],
              
              // Main Content Area
              Expanded(
                child: _buildMainContent(recommendationProvider, userProvider),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMainContent(RecommendationProvider recommendationProvider, UserProvider userProvider) {
    if (recommendationProvider.isLoading && recommendationProvider.recommendations.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading recommendations...'),
          ],
        ),
      );
    }

    if (recommendationProvider.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Error loading recommendations',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              recommendationProvider.error!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _initializeData(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (recommendationProvider.recommendations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.movie_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'No recommendations found',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your genre filters or check back later',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                await recommendationProvider.clearGenreFilters(userProvider.userProfile);
              },
              child: const Text('Clear Filters'),
            ),
          ],
        ),
      );
    }

    // Display current movie with swipe interface
    final currentMovie = recommendationProvider.currentMovie;
    if (currentMovie == null) {
      return const Center(child: Text('No movie to display'));
    }

    return Column(
      children: [
        // Movie navigation info
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${recommendationProvider.currentIndex + 1} of ${recommendationProvider.recommendations.length}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              if (recommendationProvider.selectedGenres.isNotEmpty)
                Chip(
                  label: Text(
                    '${recommendationProvider.selectedGenres.length} filter${recommendationProvider.selectedGenres.length == 1 ? '' : 's'}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
        ),
        
        // Movie card
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: MovieCard(
              movie: currentMovie,
              onRate: (rating) async {
                await recommendationProvider.rateMovie(currentMovie.id, rating);
              },
              onSwipeLeft: () {
                recommendationProvider.previousMovie();
              },
              onSwipeRight: () {
                recommendationProvider.nextMovie();
              },
            ),
          ),
        ),
        
        // Navigation buttons
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                onPressed: recommendationProvider.currentIndex > 0
                    ? () => recommendationProvider.previousMovie()
                    : null,
                icon: const Icon(Icons.arrow_back),
                label: const Text('Previous'),
              ),
              ElevatedButton.icon(
                onPressed: recommendationProvider.currentIndex < recommendationProvider.recommendations.length - 1
                    ? () => recommendationProvider.nextMovie()
                    : null,
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Next'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}