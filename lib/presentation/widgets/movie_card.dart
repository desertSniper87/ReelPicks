import 'package:flutter/material.dart';
import '../../data/models/movie.dart';

/// Movie card widget for swipe interface
class MovieCard extends StatelessWidget {
  final Movie movie;
  final VoidCallback? onSwipeLeft;
  final VoidCallback? onSwipeRight;
  final Function(double)? onRate;

  const MovieCard({
    super.key,
    required this.movie,
    this.onSwipeLeft,
    this.onSwipeRight,
    this.onRate,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 8,
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Movie poster placeholder
          Container(
            height: 300,
            width: double.infinity,
            color: Colors.grey[300],
            child: const Icon(
              Icons.movie,
              size: 64,
              color: Colors.grey,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  movie.title,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  movie.genres.map((g) => g.name).join(', '),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  movie.overview,
                  style: Theme.of(context).textTheme.bodySmall,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}