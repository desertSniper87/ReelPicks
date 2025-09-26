import 'package:flutter/material.dart';
import '../../data/models/movie.dart';

/// A widget that displays genre filter chips with multi-select functionality
class GenreFilter extends StatefulWidget {
  final List<Genre> availableGenres;
  final List<String> selectedGenres;
  final Function(List<String>) onGenresChanged;
  final bool isLoading;

  const GenreFilter({
    super.key,
    required this.availableGenres,
    required this.selectedGenres,
    required this.onGenresChanged,
    this.isLoading = false,
  });

  @override
  State<GenreFilter> createState() => _GenreFilterState();
}

class _GenreFilterState extends State<GenreFilter> {
  late List<String> _selectedGenres;

  @override
  void initState() {
    super.initState();
    _selectedGenres = List.from(widget.selectedGenres);
  }

  @override
  void didUpdateWidget(GenreFilter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedGenres != oldWidget.selectedGenres) {
      _selectedGenres = List.from(widget.selectedGenres);
    }
  }

  void _toggleGenre(String genreName) {
    setState(() {
      if (_selectedGenres.contains(genreName)) {
        _selectedGenres.remove(genreName);
      } else {
        _selectedGenres.add(genreName);
      }
    });
    widget.onGenresChanged(_selectedGenres);
  }

  void _clearAllGenres() {
    setState(() {
      _selectedGenres.clear();
    });
    widget.onGenresChanged(_selectedGenres);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (widget.isLoading) {
      return const SizedBox(
        height: 60,
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (widget.availableGenres.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with clear button
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Filter by Genre',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            if (_selectedGenres.isNotEmpty)
              TextButton(
                onPressed: _clearAllGenres,
                child: Text(
                  'Clear All',
                  style: TextStyle(
                    color: colorScheme.primary,
                    fontSize: 14,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        
        // Genre chips
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: widget.availableGenres.map((genre) {
            final isSelected = _selectedGenres.contains(genre.name);
            
            return FilterChip(
              label: Text(
                genre.name,
                style: TextStyle(
                  color: isSelected 
                    ? colorScheme.onSecondaryContainer
                    : colorScheme.onSurfaceVariant,
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                ),
              ),
              selected: isSelected,
              onSelected: (_) => _toggleGenre(genre.name),
              backgroundColor: colorScheme.surface,
              selectedColor: colorScheme.secondaryContainer,
              checkmarkColor: colorScheme.onSecondaryContainer,
              side: BorderSide(
                color: isSelected 
                  ? colorScheme.secondaryContainer
                  : colorScheme.outline,
                width: 1,
              ),
              elevation: isSelected ? 2 : 0,
              pressElevation: 4,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            );
          }).toList(),
        ),
        
        // Selected genres count
        if (_selectedGenres.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            '${_selectedGenres.length} genre${_selectedGenres.length == 1 ? '' : 's'} selected',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}