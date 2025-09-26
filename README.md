# Movie Recommendation App

A Flutter application that provides personalized movie recommendations using The Movie Database (TMDb) API. The app features a clean, swipe-based interface following Material Design 3 principles.

## Features

- **Personalized Recommendations**: Get movie suggestions based on your TMDb ratings and preferences
- **Swipe Interface**: Browse movies one at a time with intuitive swipe gestures
- **Genre Filtering**: Filter recommendations by preferred genres
- **TMDb Integration**: Rate movies and sync with your TMDb account
- **Profile Connections**: Link IMDb and Letterboxd profiles
- **Material Design 3**: Clean, modern UI following Google's design guidelines

## Project Structure

The project follows clean architecture principles with clear separation of concerns:

```
lib/
├── core/                     # Core functionality
│   ├── config/              # App configuration
│   ├── constants/           # App and API constants
│   ├── error/               # Error handling
│   └── utils/               # Utility classes
├── data/                    # Data layer
│   └── models/              # Data models
├── domain/                  # Business logic layer
│   ├── repositories/        # Repository interfaces
│   └── services/            # Service interfaces
└── presentation/            # UI layer
    ├── providers/           # State management
    ├── screens/             # App screens
    └── widgets/             # Reusable widgets
```

## Setup

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd movie_recommendation_app
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure TMDb API**
   - Get your API key from [The Movie Database](https://www.themoviedb.org/settings/api)
   - Copy `.env.example` to `.env`
   - Add your TMDb API key to the `.env` file:
     ```
     TMDB_API_KEY=your_api_key_here
     ```

4. **Run the app**
   ```bash
   flutter run
   ```

## Dependencies

- **http**: HTTP client for API calls
- **provider**: State management
- **shared_preferences**: Local storage for user preferences
- **cached_network_image**: Cached network images for movie posters
- **flutter_dotenv**: Environment variable management

## Development Status

This project is currently in development. The basic project structure and dependencies have been set up. Implementation of features will follow the tasks outlined in the project specification.

## Contributing

Please follow the established architecture patterns and ensure all new code includes appropriate tests.
