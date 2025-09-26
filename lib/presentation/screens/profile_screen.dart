import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/auth_provider.dart';
import '../providers/user_provider.dart';
import '../widgets/tmdb_auth_webview.dart';
import '../widgets/rated_movies_list.dart';
import '../../data/models/movie.dart';

/// Profile screen for TMDb authentication and profile setup
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  final _imdbController = TextEditingController();
  final _letterboxdController = TextEditingController();
  bool _isLoadingRatedMovies = false;
  List<Movie> _ratedMovies = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadUserProfiles();
    _loadRatedMovies();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _imdbController.dispose();
    _letterboxdController.dispose();
    super.dispose();
  }

  void _loadUserProfiles() {
    final userProvider = context.read<UserProvider>();
    final profile = userProvider.userProfile;
    
    if (profile?.imdbUsername != null) {
      _imdbController.text = profile!.imdbUsername!;
    }
    if (profile?.letterboxdUsername != null) {
      _letterboxdController.text = profile!.letterboxdUsername!;
    }
  }

  Future<void> _loadRatedMovies() async {
    final authProvider = context.read<AuthProvider>();
    if (!authProvider.isAuthenticated) return;

    setState(() {
      _isLoadingRatedMovies = true;
    });

    try {
      final userProvider = context.read<UserProvider>();
      final movies = await userProvider.getRatedMovies();
      setState(() {
        _ratedMovies = movies;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load rated movies: $e')),
        );
      }
    } finally {
      setState(() {
        _isLoadingRatedMovies = false;
      });
    }
  }

  Future<void> _startTMDbAuthentication() async {
    final authProvider = context.read<AuthProvider>();
    
    final requestToken = await authProvider.startAuthentication();
    if (requestToken == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to start authentication: ${authProvider.error}')),
        );
      }
      return;
    }

    if (mounted) {
      final result = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (context) => TMDbAuthWebView(
            requestToken: requestToken,
            authProvider: authProvider,
          ),
        ),
      );

      if (result == true) {
        await _loadRatedMovies();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Successfully authenticated with TMDb!')),
          );
        }
      }
    }
  }

  Future<void> _logout() async {
    final authProvider = context.read<AuthProvider>();
    await authProvider.logout();
    setState(() {
      _ratedMovies = [];
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Logged out successfully')),
      );
    }
  }

  Future<void> _saveIMDbProfile() async {
    final userProvider = context.read<UserProvider>();
    final username = _imdbController.text.trim();
    
    if (username.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid IMDb username')),
      );
      return;
    }

    try {
      await userProvider.updateIMDbProfile(username);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('IMDb profile saved successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save IMDb profile: $e')),
        );
      }
    }
  }

  Future<void> _saveLetterboxdProfile() async {
    final userProvider = context.read<UserProvider>();
    final username = _letterboxdController.text.trim();
    
    if (username.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid Letterboxd username')),
      );
      return;
    }

    try {
      await userProvider.updateLetterboxdProfile(username);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Letterboxd profile saved successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save Letterboxd profile: $e')),
        );
      }
    }
  }

  Future<void> _openIMDbProfile() async {
    final userProvider = context.read<UserProvider>();
    final username = userProvider.userProfile?.imdbUsername;
    
    if (username == null || username.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No IMDb profile configured')),
      );
      return;
    }

    final url = Uri.parse('https://www.imdb.com/user/$username/');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open IMDb profile')),
        );
      }
    }
  }

  Future<void> _openLetterboxdProfile() async {
    final userProvider = context.read<UserProvider>();
    final username = userProvider.userProfile?.letterboxdUsername;
    
    if (username == null || username.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No Letterboxd profile configured')),
      );
      return;
    }

    final url = Uri.parse('https://letterboxd.com/$username/');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open Letterboxd profile')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'TMDb', icon: Icon(Icons.movie)),
            Tab(text: 'External', icon: Icon(Icons.link)),
            Tab(text: 'Ratings', icon: Icon(Icons.star)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTMDbTab(),
          _buildExternalProfilesTab(),
          _buildRatedMoviesTab(),
        ],
      ),
    );
  }

  Widget _buildTMDbTab() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        if (authProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!authProvider.isAuthenticated) {
          return _buildTMDbLoginSection(authProvider);
        }

        return _buildTMDbProfileSection(authProvider);
      },
    );
  }

  Widget _buildTMDbLoginSection(AuthProvider authProvider) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.movie,
            size: 80,
            color: Colors.blue,
          ),
          const SizedBox(height: 24),
          const Text(
            'Connect to TMDb',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          const Text(
            'Connect your TMDb account to rate movies and get personalized recommendations.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _startTMDbAuthentication,
            icon: const Icon(Icons.login),
            label: const Text('Connect TMDb Account'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
          ),
          if (authProvider.error != null) ...[
            const SizedBox(height: 16),
            Card(
              color: Theme.of(context).colorScheme.errorContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      Icons.error,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        authProvider.error!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTMDbProfileSection(AuthProvider authProvider) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.account_circle, size: 40),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              authProvider.accountName ?? authProvider.username ?? 'TMDb User',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (authProvider.username != null)
                              Text(
                                '@${authProvider.username}',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                              ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: _logout,
                        icon: const Icon(Icons.logout),
                        tooltip: 'Logout',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: Theme.of(context).colorScheme.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      const Text('Connected to TMDb'),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Features',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.star),
                  title: const Text('Rate Movies'),
                  subtitle: const Text('Rate movies to improve recommendations'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    // Navigate to rating interface (could be implemented in home screen)
                    Navigator.of(context).pop();
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.list),
                  title: const Text('View Rated Movies'),
                  subtitle: const Text('See all your movie ratings'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    _tabController.animateTo(2);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExternalProfilesTab() {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'External Profiles',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Connect your external movie profiles for easy access.',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 24),
              
              // IMDb Profile Section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.movie, color: Colors.orange),
                          const SizedBox(width: 8),
                          const Text(
                            'IMDb Profile',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const Spacer(),
                          if (userProvider.userProfile?.imdbUsername != null)
                            IconButton(
                              onPressed: _openIMDbProfile,
                              icon: const Icon(Icons.open_in_browser),
                              tooltip: 'Open IMDb Profile',
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _imdbController,
                        decoration: const InputDecoration(
                          labelText: 'IMDb Username',
                          hintText: 'Enter your IMDb username',
                          prefixIcon: Icon(Icons.person),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          ElevatedButton(
                            onPressed: _saveIMDbProfile,
                            child: const Text('Save'),
                          ),
                          const SizedBox(width: 8),
                          if (userProvider.userProfile?.imdbUsername != null)
                            OutlinedButton.icon(
                              onPressed: _openIMDbProfile,
                              icon: const Icon(Icons.open_in_browser),
                              label: const Text('Open Profile'),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Letterboxd Profile Section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.local_movies, color: Colors.green),
                          const SizedBox(width: 8),
                          const Text(
                            'Letterboxd Profile',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const Spacer(),
                          if (userProvider.userProfile?.letterboxdUsername != null)
                            IconButton(
                              onPressed: _openLetterboxdProfile,
                              icon: const Icon(Icons.open_in_browser),
                              tooltip: 'Open Letterboxd Profile',
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _letterboxdController,
                        decoration: const InputDecoration(
                          labelText: 'Letterboxd Username',
                          hintText: 'Enter your Letterboxd username',
                          prefixIcon: Icon(Icons.person),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          ElevatedButton(
                            onPressed: _saveLetterboxdProfile,
                            child: const Text('Save'),
                          ),
                          const SizedBox(width: 8),
                          if (userProvider.userProfile?.letterboxdUsername != null)
                            OutlinedButton.icon(
                              onPressed: _openLetterboxdProfile,
                              icon: const Icon(Icons.open_in_browser),
                              label: const Text('Open Profile'),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRatedMoviesTab() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        if (!authProvider.isAuthenticated) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.star_border, size: 80, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'Connect to TMDb to view your rated movies',
                  style: TextStyle(fontSize: 16),
                ),
              ],
            ),
          );
        }

        if (_isLoadingRatedMovies) {
          return const Center(child: CircularProgressIndicator());
        }

        if (_ratedMovies.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.star_border, size: 80, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No rated movies yet',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  'Start rating movies to see them here',
                  style: TextStyle(fontSize: 16),
                ),
              ],
            ),
          );
        }

        return RatedMoviesList(
          movies: _ratedMovies,
          onRefresh: _loadRatedMovies,
          onRatingChanged: (movieId, newRating) async {
            // Update the rating and refresh the list
            final userProvider = context.read<UserProvider>();
            try {
              if (newRating == null) {
                await userProvider.deleteMovieRating(movieId);
              } else {
                await userProvider.rateMovie(movieId, newRating);
              }
              await _loadRatedMovies();
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to update rating: $e')),
                );
              }
            }
          },
        );
      },
    );
  }
}