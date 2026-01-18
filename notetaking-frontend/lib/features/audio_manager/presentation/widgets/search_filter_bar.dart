import 'package:flutter/material.dart';

class SearchFilterBar extends StatelessWidget {
  final TextEditingController searchController;
  final VoidCallback onFilterPressed;
  final ValueChanged<String> onSearchChanged;
  final bool hasActiveFilters;

  const SearchFilterBar({
    super.key,
    required this.searchController,
    required this.onFilterPressed,
    required this.onSearchChanged,
    this.hasActiveFilters = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: searchController,
              onChanged: onSearchChanged,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search audio files...',
                hintStyle: TextStyle(color: Colors.grey[500]),
                prefixIcon: Icon(Icons.search, color: Colors.grey[500]),
                filled: true,
                fillColor: const Color(0xFF282E39),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            decoration: BoxDecoration(
              color:
                  hasActiveFilters
                      ? const Color(0xFF3B82F6)
                      : const Color(0xFF282E39),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: Icon(
                Icons.filter_list,
                color:
                    hasActiveFilters ? Colors.white : Colors.grey[500],
              ),
              onPressed: onFilterPressed,
            ),
          ),
        ],
      ),
    );
  }
}
