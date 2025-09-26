import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/recommendation_provider.dart';
import '../providers/user_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/genre_filter.dart';
import '../widgets/movie_card.dart';
import '../widgets/movie_list_view.dart';
import 'profile_screen.dart';

/// Main navigation screen with bottom navigation between different views
class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
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
      appBar: _buildAppBar(),
      body: _buildBody(),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    String title;
    List<Widget> actions = [];

    switch (_currentIndex) {
      case 0:
        title = 'Discover Movies';
        actions = [
          IconButton(
            icon: Icon(_showGenreFilter ? Icons.filter_list_off : Icons.filter_list),
            onPressed: () {
              setState(() {
                _showGenreFilter = !_showGenreFilter;
              });
            },
            tooltip: _showGenreFilter ? 'Hide Filters' : 'Show Filters',
          ),
        ];
        break;
      case 1:
        title = 'Movie List';
        actions = [
          IconButton(
            icon: Icon(_showGenreFilter ? Icons.filter_list_off : Icons.filter_list),
            onPressed: () {
              setState(() {
                _showGenreFilter = !_showGenreFilter;
              });
            },
            tooltip: _showGenreFilter ? 'Hide Filters' : 'Show Filters',
          ),
        ];
        break;
      case 2:
        title = 'Profile';
        break;
      case 3:
        title = 'Settings';
        break;
      default:
        title = 'Movie Recommendations';
    }

    return AppBar(
      title: Text(title),
      actions: actions,
    );
  }

  Widget _buildBody() {
    return Column(
      children: [
        // Genre Filter Section (shown for swipe and list views)
        if ((_currentIndex == 0 || _currentIndex == 1) && _showGenreFilter) ...[
          Consumer<RecommendationProvider>(
            builder: (context, recommendationProvider, child) {
              return Container(
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
                    final userProvider = context.read<UserProvider>();
                    await recommendationProvider.applyGenreFilterRealTime(
                      selectedGenres,
                      userProvider.userProfile,
                    );
                  },
                ),
              );
            },
          ),
        ],
        
        // Main Content Area
        Expanded(
          child: _buildCurrentScreen(),
        ),
      ],
    );
  }

  Widget _buildCurrentScreen() {
    switch (_currentIndex) {
      case 0:
        return _buildSwipeView();
      case 1:
        return _buildListView();
      case 2:
        return const ProfileScreen();
      case 3:
        return _buildSettingsView();
      default:
        return _buildSwipeView();
    }
  }

  Widget _buildSwipeView() {
    return Consumer2<RecommendationProvider, UserProvider>(
      builder: (context, recommendationProvider, userProvider, child) {
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
      },
    );
  }

  Widget _buildListView() {
    return Consumer2<RecommendationProvider, UserProvider>(
      builder: (context, recommendationProvider, userProvider, child) {
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

        return MovieListView(
          movies: recommendationProvider.recommendations,
          onMovieTap: (movie) {
            // Navigate to swipe view and set current movie
            final index = recommendationProvider.recommendations.indexOf(movie);
            if (index != -1) {
              recommendationProvider.setCurrentIndex(index);
              setState(() {
                _currentIndex = 0; // Switch to swipe view
              });
            }
          },
          onRate: (rating, movie) async {
            await recommendationProvider.rateMovie(movie.id, rating);
          },
          onLoadMore: () async {
            // Load more recommendations if available
            final userProfile = userProvider.userProfile;
            if (userProfile?.isAuthenticated == true) {
              await recommendationProvider.loadPersonalizedRecommendations(userProfile!);
            } else {
              await recommendationProvider.loadPopularMovies();
            }
          },
          isLoading: recommendationProvider.isLoading,
          hasMore: true, // Could be enhanced with pagination logic
        );
      },
    );
  }

  Widget _buildSettingsView() {
    return Consumer2<UserProvider, ThemeProvider>(
      builder: (context, userProvider, themeProvider, child) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Settings',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 24),
              
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: Icon(themeProvider.currentThemeIcon),
                      title: const Text('Theme'),
                      subtitle: Text('${themeProvider.currentThemeName} theme'),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () {
                        _showThemeDialog(context, themeProvider);
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.notifications),
                      title: const Text('Notifications'),
                      subtitle: const Text('Manage notification preferences'),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Notification settings coming soon')),
                        );
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.language),
                      title: const Text('Language'),
                      subtitle: const Text('English'),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Language selection coming soon')),
                        );
                      },
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.info),
                      title: const Text('About'),
                      subtitle: const Text('App version and information'),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () {
                        showAboutDialog(
                          context: context,
                          applicationName: 'Movie Recommendations',
                          applicationVersion: '1.0.0',
                          applicationIcon: const Icon(Icons.movie),
                          children: [
                            const Text('Discover your next favorite movie with personalized recommendations.'),
                          ],
                        );
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.help),
                      title: const Text('Help & Support'),
                      subtitle: const Text('Get help using the app'),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Help & Support coming soon')),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBottomNavigationBar() {
    return NavigationBar(
      selectedIndex: _currentIndex,
      onDestinationSelected: (index) {
        setState(() {
          _currentIndex = index;
          // Hide genre filter when switching to profile or settings
          if (index >= 2) {
            _showGenreFilter = false;
          }
        });
      },
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.swipe),
          selectedIcon: Icon(Icons.swipe),
          label: 'Discover',
        ),
        NavigationDestination(
          icon: Icon(Icons.list),
          selectedIcon: Icon(Icons.list),
          label: 'List',
        ),
        NavigationDestination(
          icon: Icon(Icons.person),
          selectedIcon: Icon(Icons.person),
          label: 'Profile',
        ),
        NavigationDestination(
          icon: Icon(Icons.settings),
          selectedIcon: Icon(Icons.settings),
          label: 'Settings',
        ),
      ],
    );
  }

  void _showThemeDialog(BuildContext context, ThemeProvider themeProvider) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Choose Theme'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<ThemeMode>(
                title: const Text('Light'),
                subtitle: const Text('Always use light theme'),
                value: ThemeMode.light,
                groupValue: themeProvider.themeMode,
                onChanged: (ThemeMode? value) {
                  if (value != null) {
                    themeProvider.setThemeMode(value);
                    Navigator.of(context).pop();
                  }
                },
                secondary: const Icon(Icons.light_mode),
              ),
              RadioListTile<ThemeMode>(
                title: const Text('Dark'),
                subtitle: const Text('Always use dark theme'),
                value: ThemeMode.dark,
                groupValue: themeProvider.themeMode,
                onChanged: (ThemeMode? value) {
                  if (value != null) {
                    themeProvider.setThemeMode(value);
                    Navigator.of(context).pop();
                  }
                },
                secondary: const Icon(Icons.dark_mode),
              ),
              RadioListTile<ThemeMode>(
                title: const Text('System'),
                subtitle: const Text('Follow system theme'),
                value: ThemeMode.system,
                groupValue: themeProvider.themeMode,
                onChanged: (ThemeMode? value) {
                  if (value != null) {
                    themeProvider.setThemeMode(value);
                    Navigator.of(context).pop();
                  }
                },
                secondary: const Icon(Icons.brightness_auto),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }
}