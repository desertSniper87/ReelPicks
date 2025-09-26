import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../data/models/movie.dart';

/// Movie card widget for swipe interface with rating and gesture support
class MovieCard extends StatefulWidget {
  final Movie movie;
  final VoidCallback? onSwipeLeft;
  final VoidCallback? onSwipeRight;
  final Function(double)? onRate;
  final bool isRatingEnabled;

  const MovieCard({
    super.key,
    required this.movie,
    this.onSwipeLeft,
    this.onSwipeRight,
    this.onRate,
    this.isRatingEnabled = true,
  });

  @override
  State<MovieCard> createState() => _MovieCardState();
}

class _MovieCardState extends State<MovieCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;
  
  double _dragOffset = 0.0;
  bool _isDragging = false;
  double? _currentRating;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0.0, 0.02),
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _currentRating = widget.movie.userRating;
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handlePanStart(DragStartDetails details) {
    setState(() {
      _isDragging = true;
    });
    _animationController.forward();
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    setState(() {
      _dragOffset += details.delta.dx;
    });
  }

  void _handlePanEnd(DragEndDetails details) {
    setState(() {
      _isDragging = false;
    });
    _animationController.reverse();

    const double threshold = 100.0;
    
    if (_dragOffset > threshold) {
      // Swipe right
      widget.onSwipeRight?.call();
    } else if (_dragOffset < -threshold) {
      // Swipe left
      widget.onSwipeLeft?.call();
    }
    
    // Reset drag offset with animation
    setState(() {
      _dragOffset = 0.0;
    });
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
    return 'https://image.tmdb.org/t/p/w500$posterPath';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: SlideTransition(
            position: _slideAnimation,
            child: Transform.translate(
              offset: Offset(_dragOffset * 0.5, 0),
              child: GestureDetector(
                onPanStart: _handlePanStart,
                onPanUpdate: _handlePanUpdate,
                onPanEnd: _handlePanEnd,
                child: Card(
                  elevation: _isDragging ? 12 : 8,
                  margin: const EdgeInsets.all(16),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Movie poster
                      SizedBox(
                        height: 300,
                        width: double.infinity,
                        child: widget.movie.posterPath != null && widget.movie.posterPath!.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: _getPosterUrl(widget.movie.posterPath),
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(
                                  color: colorScheme.surfaceVariant,
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      color: colorScheme.primary,
                                    ),
                                  ),
                                ),
                                errorWidget: (context, url, error) => Container(
                                  color: colorScheme.surfaceVariant,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.movie,
                                        size: 64,
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Image not available',
                                        style: theme.textTheme.bodyMedium?.copyWith(
                                          color: colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            : Container(
                                color: colorScheme.surfaceVariant,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.movie,
                                      size: 64,
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'No poster available',
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                      ),
                      
                      // Movie information
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Title
                            Text(
                              widget.movie.title,
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            
                            // Genres
                            if (widget.movie.genres.isNotEmpty)
                              Wrap(
                                spacing: 8,
                                runSpacing: 4,
                                children: widget.movie.genres.take(3).map((genre) {
                                  return Chip(
                                    label: Text(
                                      genre.name,
                                      style: theme.textTheme.bodySmall,
                                    ),
                                    backgroundColor: colorScheme.secondaryContainer,
                                    side: BorderSide.none,
                                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  );
                                }).toList(),
                              ),
                            
                            const SizedBox(height: 12),
                            
                            // Overview
                            Text(
                              widget.movie.overview,
                              style: theme.textTheme.bodyMedium,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            
                            const SizedBox(height: 16),
                            
                            // Rating section
                            if (widget.isRatingEnabled) ...[
                              Text(
                                'Rate this movie:',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              StarRatingWidget(
                                rating: _currentRating ?? 0.0,
                                onRatingChanged: _handleRating,
                                starCount: 10,
                                size: 28,
                              ),
                              if (_currentRating != null) ...[
                                const SizedBox(height: 8),
                                Text(
                                  'Your rating: ${_currentRating!.toStringAsFixed(1)}/10',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colorScheme.primary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ],
                            
                            const SizedBox(height: 16),
                            
                            // Swipe instructions
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.swipe_left,
                                  color: colorScheme.onSurfaceVariant,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Swipe to navigate',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Icon(
                                  Icons.swipe_right,
                                  color: colorScheme.onSurfaceVariant,
                                  size: 20,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Star rating widget for 1-10 scale rating
class StarRatingWidget extends StatefulWidget {
  final double rating;
  final Function(double) onRatingChanged;
  final int starCount;
  final double size;
  final Color? activeColor;
  final Color? inactiveColor;

  const StarRatingWidget({
    super.key,
    required this.rating,
    required this.onRatingChanged,
    this.starCount = 10,
    this.size = 24,
    this.activeColor,
    this.inactiveColor,
  });

  @override
  State<StarRatingWidget> createState() => _StarRatingWidgetState();
}

class _StarRatingWidgetState extends State<StarRatingWidget> {
  double _currentRating = 0.0;

  @override
  void initState() {
    super.initState();
    _currentRating = widget.rating;
  }

  @override
  void didUpdateWidget(StarRatingWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.rating != widget.rating) {
      _currentRating = widget.rating;
    }
  }

  void _handleRating(double rating) {
    setState(() {
      _currentRating = rating;
    });
    widget.onRatingChanged(rating);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final activeColor = widget.activeColor ?? colorScheme.primary;
    final inactiveColor = widget.inactiveColor ?? colorScheme.outline;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(widget.starCount, (index) {
        final starValue = index + 1.0;
        final isActive = starValue <= _currentRating;
        final isHalfActive = starValue - 0.5 <= _currentRating && _currentRating < starValue;

        return GestureDetector(
          onTap: () => _handleRating(starValue),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Icon(
              isActive
                  ? Icons.star
                  : isHalfActive
                      ? Icons.star_half
                      : Icons.star_border,
              color: isActive || isHalfActive ? activeColor : inactiveColor,
              size: widget.size,
            ),
          ),
        );
      }),
    );
  }
}