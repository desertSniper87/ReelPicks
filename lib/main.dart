import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/config/app_config.dart';
import 'presentation/providers/recommendation_provider.dart';
import 'presentation/providers/user_provider.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/screens/main_navigation_screen.dart';
import 'data/datasources/tmdb_client.dart';
import 'data/services/authentication_service_impl.dart';
import 'data/services/recommendation_service_impl.dart';
import 'data/repositories/user_repository_impl.dart';
import 'data/repositories/movie_repository_impl.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize app configuration
  await AppConfig.initialize();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<SharedPreferences>(
      future: SharedPreferences.getInstance(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const MaterialApp(
            home: Scaffold(
              body: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        // Initialize dependencies
        const secureStorage = FlutterSecureStorage();
        final sharedPreferences = snapshot.data!;
        final tmdbClient = TMDbClient();
        
        // Initialize repositories
        final userRepository = UserRepositoryImpl(
          sharedPreferences: sharedPreferences,
          secureStorage: secureStorage,
        );
        final movieRepository = MovieRepositoryImpl(tmdbClient: tmdbClient);
        
        // Initialize services
        final authService = AuthenticationServiceImpl(
          tmdbClient: tmdbClient,
          secureStorage: secureStorage,
        );
        final recommendationService = RecommendationServiceImpl(
          movieRepository: movieRepository,
        );

        return MultiProvider(
          providers: [
            ChangeNotifierProvider(
              create: (_) => RecommendationProvider(
                recommendationService: recommendationService,
                movieRepository: movieRepository,
              ),
            ),
            ChangeNotifierProvider(
              create: (_) => UserProvider(
                userRepository: userRepository,
                movieRepository: movieRepository,
              ),
            ),
            ChangeNotifierProvider(
              create: (_) => AuthProvider(
                authService: authService,
              ),
            ),
          ],
          child: MaterialApp(
            title: 'Movie Recommendations',
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
              useMaterial3: true,
            ),
            home: const MainNavigationScreen(),
          ),
        );
      },
    );
  }
}


