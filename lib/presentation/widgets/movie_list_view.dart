import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../data/models/movie.dart';
import 'movie_card.dart'; // Import for StarRatingWidget

/// Movie list view widget with scrollable list of recommendations
class MovieListView extends StatefulWidget {
  final List<Movie> movies;
  final Function(Movie)? onMovieTap;
  final Function(double, Movie)? onRate;
  final VoidCallback? onLoadMore;
  final bool isLoading;
  final bool hasMore;
  final ScrollController? scrollController;

  const MovieListView({
    super.key,
    required this.movies,
    this.onMovieTap,
    this.onRate,
    this.onLoadMore,
    this.isLoading = false,
    this.hasMore = true,
    this.scrollController,
  });

  @override
  State<MovieListView> createState() => _MovieListViewState();
}

class _MovieListViewState extends State<MovieListView> {
  late ScrollController _scrollController;
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _scrollController = widget.scrollController ?? ScrollController();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    if (widget.scrollController == null) {
      _scrollController.dispose();
    } else {
      _scrollController.removeListener(_onScroll);
    }
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        widget.hasMore &&
        widget.onLoadMore != null) {
      setState(() {
        _isLoadingMore = true;
      });
      widget.onLoadMore!();
      // Reset loading state after a delay to prevent multiple calls
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          setState(() {
            _isLoadingMore = false;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (widget.movies.isEmpty && !widget.isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.movie_outlined,
              size: 64,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'No movies found',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your filters or check back later',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        // Trigger refresh by calling onLoadMore if available
        widget.onLoadMore?.call();
      },
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(8),
        itemCount: widget.movies.length + (widget.isLoading || _isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          // Show loading indicator at the end
          if (index >= widget.movies.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }

          final movie = widget.movies[index];
          return MovieListItem(
            movie: movie,
            onTap: () => widget.onMovieTap?.call(movie),
            onRate: (rating) => widget.onRate?.call(rating, movie),
          );
        },
      ),
    );
  }
}

/// Individual movie list item widget
class MovieListItem extends StatefulWidget {
  final Movie movie;
  final VoidCallback? onTap;
  final Function(double)? onRate;

  const MovieListItem({
    super.key,
    required this.movie,
    this.onTap,
    this.onRate,
  });

  @override
  State<MovieListItem> createState() => _MovieListItemState();
}

class _MovieListItemState extends State<MovieListItem> {
  double? _currentRating;

  @override
  void initState() {
    super.initState();
    _currentRating = widget.movie.userRating;
  }

  void _handleRating(double rating) {
    setState(() {
      _currentRating = rating;
    });
    widget.onRate?.call(rating);
  }

  String _getPosterUrl(String? posterPath) {
    if (posterPath == null || posterPath.isEmpty) {
      return '';
    }
    return 'https://image.tmdb.org/t/p/w300$posterPath';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: widget.onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Movie poster
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 80,
                  height: 120,
                  child: widget.movie.posterPath != null && widget.movie.posterPath!.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: _getPosterUrl(widget.movie.posterPath),
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: colorScheme.surfaceContainerHighest,
                            child: Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: colorScheme.primary,
                                ),
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: colorScheme.surfaceContainerHighest,
                            child: Icon(
                              Icons.movie,
                              color: colorScheme.onSurfaceVariant,
                              size: 32,
                            ),
                          ),
                        )
                      : Container(
                          color: colorScheme.surfaceContainerHighest,
                          child: Icon(
                            Icons.movie,
                            color: colorScheme.onSurfaceVariant,
                            size: 32,
                          ),
                        ),
                ),
              ),
              
              const SizedBox(width: 12),
              
              // Movie information
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      widget.movie.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    const SizedBox(height: 4),
                    
                    // Release year and rating
                    Row(
                      children: [
                        if (widget.movie.releaseDate.isNotEmpty) ...[
                          Text(
                            widget.movie.releaseDate.split('-')[0],
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Icon(
                          Icons.star,
                          size: 16,
                          color: Colors.amber,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          widget.movie.voteAverage.toStringAsFixed(1),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Genres
                    if (widget.movie.genres.isNotEmpty)
                      Wrap(
                        spacing: 4,
                        runSpacing: 2,
                        children: widget.movie.genres.take(2).map((genre) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: colorScheme.secondaryContainer,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              genre.name,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSecondaryContainer,
                                fontSize: 10,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    
                    const SizedBox(height: 8),
                    
                    // User rating section
                    Row(
                      children: [
                        Text(
                          'Rate:',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: StarRatingWidget(
                            rating: _currentRating ?? 0.0,
                            onRatingChanged: _handleRating,
                            starCount: 5, // Use 5 stars for compact list view
                            size: 18,
                          ),
                        ),
                        if (_currentRating != null && _currentRating! > 0) ...[
                          const SizedBox(width: 8),
                          Text(
                            '${_currentRating!.toStringAsFixed(1)}/5',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}