import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../data/models/movie.dart';
import '../../core/constants/api_constants.dart';

/// Widget to display and manage user's rated movies
class RatedMoviesList extends StatelessWidget {
  final List<Movie> movies;
  final VoidCallback onRefresh;
  final Function(int movieId, double? newRating) onRatingChanged;

  const RatedMoviesList({
    super.key,
    required this.movies,
    required this.onRefresh,
    required this.onRatingChanged,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: movies.length,
        itemBuilder: (context, index) {
          final movie = movies[index];
          return _RatedMovieCard(
            movie: movie,
            onRatingChanged: (newRating) => onRatingChanged(movie.id, newRating),
          );
        },
      ),
    );
  }
}

class _RatedMovieCard extends StatefulWidget {
  final Movie movie;
  final Function(double? newRating) onRatingChanged;

  const _RatedMovieCard({
    required this.movie,
    required this.onRatingChanged,
  });

  @override
  State<_RatedMovieCard> createState() => _RatedMovieCardState();
}

class _RatedMovieCardState extends State<_RatedMovieCard> {
  bool _isUpdating = false;

  Future<void> _updateRating(double? newRating) async {
    setState(() {
      _isUpdating = true;
    });

    try {
      await widget.onRatingChanged(newRating);
    } finally {
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
      }
    }
  }

  void _showRatingDialog() {
    showDialog(
      context: context,
      builder: (context) => _RatingDialog(
        movie: widget.movie,
        currentRating: widget.movie.userRating,
        onRatingChanged: _updateRating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: _showRatingDialog,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Movie Poster
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 80,
                  height: 120,
                  child: widget.movie.posterPath != null
                      ? CachedNetworkImage(
                          imageUrl: '${ApiConstants.tmdbImageBaseUrl}${widget.movie.posterPath}',
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: theme.colorScheme.surfaceVariant,
                            child: const Center(
                              child: CircularProgressIndicator(),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: theme.colorScheme.surfaceVariant,
                            child: const Icon(Icons.movie),
                          ),
                        )
                      : Container(
                          color: theme.colorScheme.surfaceVariant,
                          child: const Icon(Icons.movie),
                        ),
                ),
              ),
              
              const SizedBox(width: 16),
              
              // Movie Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.movie.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    if (widget.movie.releaseDate.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        widget.movie.releaseDate.split('-')[0], // Extract year
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                    
                    if (widget.movie.genres.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: widget.movie.genres.take(2).map((genre) {
                          return Chip(
                            label: Text(
                              genre.name,
                              style: theme.textTheme.bodySmall,
                            ),
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            visualDensity: VisualDensity.compact,
                          );
                        }).toList(),
                      ),
                    ],
                    
                    const SizedBox(height: 12),
                    
                    // Rating Display
                    Row(
                      children: [
                        Icon(
                          Icons.star,
                          color: Colors.amber,
                          size: 20,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          widget.movie.userRating?.toStringAsFixed(1) ?? 'Not rated',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '/ 10',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const Spacer(),
                        if (_isUpdating)
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        else
                          Icon(
                            Icons.edit,
                            size: 16,
                            color: theme.colorScheme.onSurfaceVariant,
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
    );
  }
}

class _RatingDialog extends StatefulWidget {
  final Movie movie;
  final double? currentRating;
  final Function(double? newRating) onRatingChanged;

  const _RatingDialog({
    required this.movie,
    required this.currentRating,
    required this.onRatingChanged,
  });

  @override
  State<_RatingDialog> createState() => _RatingDialogState();
}

class _RatingDialogState extends State<_RatingDialog> {
  late double _rating;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _rating = widget.currentRating ?? 5.0;
  }

  Future<void> _saveRating() async {
    setState(() {
      _isUpdating = true;
    });

    try {
      await widget.onRatingChanged(_rating);
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update rating: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
      }
    }
  }

  Future<void> _deleteRating() async {
    setState(() {
      _isUpdating = true;
    });

    try {
      await widget.onRatingChanged(null);
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete rating: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return AlertDialog(
      title: Text(
        'Rate "${widget.movie.title}"',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Rating: ${_rating.toStringAsFixed(1)} / 10',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          Slider(
            value: _rating,
            min: 0.5,
            max: 10.0,
            divisions: 19, // 0.5 increments
            onChanged: _isUpdating ? null : (value) {
              setState(() {
                _rating = value;
              });
            },
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('0.5', style: theme.textTheme.bodySmall),
              Text('10.0', style: theme.textTheme.bodySmall),
            ],
          ),
        ],
      ),
      actions: [
        if (widget.currentRating != null)
          TextButton(
            onPressed: _isUpdating ? null : _deleteRating,
            child: Text(
              'Delete',
              style: TextStyle(color: theme.colorScheme.error),
            ),
          ),
        TextButton(
          onPressed: _isUpdating ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isUpdating ? null : _saveRating,
          child: _isUpdating
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save'),
        ),
      ],
    );
  }
}