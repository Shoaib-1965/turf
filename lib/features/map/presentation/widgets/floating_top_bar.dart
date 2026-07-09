import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:turf_app/core/services/geocoding_service.dart';

class FloatingTopBar extends StatefulWidget {
  final void Function(Position coordinates, String label)? onLocationSelected;

  const FloatingTopBar({super.key, this.onLocationSelected});

  @override
  State<FloatingTopBar> createState() => _FloatingTopBarState();
}

class _FloatingTopBarState extends State<FloatingTopBar> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final GeocodingService _geocodingService = GeocodingService();
  Timer? _debounce;
  List<GeocodingResult> _suggestions = [];
  bool _isSearching = false;
  bool _showResults = false;

  /// User's current location for biasing results — set externally if available
  double? focusLat;
  double? focusLng;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    if (query.trim().length < 2) {
      setState(() {
        _suggestions = [];
        _showResults = false;
      });
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 400), () async {
      setState(() => _isSearching = true);
      final results = await _geocodingService.autocomplete(
        query: query,
        focusLat: focusLat,
        focusLng: focusLng,
      );
      if (mounted) {
        setState(() {
          _suggestions = results;
          _showResults = results.isNotEmpty;
          _isSearching = false;
        });
      }
    });
  }

  void _onResultTap(GeocodingResult result) {
    _searchController.clear();
    _focusNode.unfocus();
    setState(() {
      _suggestions = [];
      _showResults = false;
    });
    widget.onLocationSelected?.call(result.coordinates, result.label);
  }

  void _onSubmitted(String query) async {
    if (query.trim().isEmpty) return;
    _focusNode.unfocus();
    setState(() => _isSearching = true);

    try {
      final results = await _geocodingService.search(query: query);
      if (results.isNotEmpty && mounted) {
        _searchController.clear();
        setState(() {
          _suggestions = [];
          _showResults = false;
          _isSearching = false;
        });
        widget.onLocationSelected?.call(
          results.first.coordinates,
          results.first.label,
        );
      } else if (mounted) {
        setState(() => _isSearching = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No results found'),
            backgroundColor: Color(0xFF1C1C1E),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isSearching = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Search unavailable'),
            backgroundColor: Color(0xFF1C1C1E),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Search Bar
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1C1C1E).withOpacity(0.8),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      _isSearching
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFF00E676),
                              ),
                            )
                          : const Icon(Icons.search, color: Colors.white70),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          focusNode: _focusNode,
                          onChanged: _onSearchChanged,
                          onSubmitted: _onSubmitted,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                          cursorHeight: 18.0,
                          cursorWidth: 1.5,
                          cursorColor: const Color(0xFF00E676),
                          cursorRadius: const Radius.circular(2),
                          decoration: const InputDecoration(
                            hintText: 'Search territories...',
                            hintStyle: TextStyle(
                              color: Colors.white54,
                              fontSize: 16,
                            ),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ),
                      if (_searchController.text.isNotEmpty)
                        GestureDetector(
                          onTap: () {
                            _searchController.clear();
                            setState(() {
                              _suggestions = [];
                              _showResults = false;
                            });
                          },
                          child: const Icon(
                            Icons.close,
                            color: Colors.white54,
                            size: 20,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),

            // Autocomplete Results Dropdown
            if (_showResults && _suggestions.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(top: 4),
                constraints: const BoxConstraints(maxHeight: 240),
                decoration: BoxDecoration(
                  color: const Color(0xFF1C1C1E).withOpacity(0.95),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF00E676).withOpacity(0.2),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: ListView.separated(
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    itemCount: _suggestions.length,
                    separatorBuilder: (_, _) =>
                        const Divider(height: 1, color: Colors.white12),
                    itemBuilder: (context, index) {
                      final result = _suggestions[index];
                      return ListTile(
                        dense: true,
                        leading: const Icon(
                          Icons.location_on_outlined,
                          color: Color(0xFF00E676),
                          size: 20,
                        ),
                        title: Text(
                          result.name.isNotEmpty ? result.name : result.label,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          [
                            result.locality,
                            result.region,
                            result.country,
                          ].where((s) => s != null && s.isNotEmpty).join(', '),
                          style: const TextStyle(
                            color: Colors.white38,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onTap: () => _onResultTap(result),
                      );
                    },
                  ),
                ),
              ),

            // Filter Pills removed as per PHASE A
          ],
        ),
      ),
    );
  }
}
