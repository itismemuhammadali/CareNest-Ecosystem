import 'package:flutter/material.dart';
import 'search_bar.dart';

/// Example implementations of the CustomSearchBar widget
/// This file demonstrates various use cases and customizations

class SearchBarExamples {
  /// Example 1: Basic search bar with hint text
  static Widget basicSearchBar() {
    return CustomSearchBar(
      hintText: 'Search Babysitters',
    );
  }

  /// Example 2: Search bar with text controller and onChanged callback
  static Widget searchBarWithController(
    TextEditingController controller,
    Function(String) onSearchChanged,
  ) {
    return CustomSearchBar(
      hintText: 'Search Babysitters',
      controller: controller,
      onChanged: (value) {
        onSearchChanged(value);
      },
    );
  }

  /// Example 3: Search bar with navigation on tap
  static Widget searchBarWithNavigation(BuildContext context) {
    return CustomSearchBar(
      hintText: 'Search Babysitters',
      onTap: () {
        // Navigate to search results screen
        // Navigator.push(context, MaterialPageRoute(
        //   builder: (_) => SearchResultsScreen(),
        // ));
      },
    );
  }

  /// Example 4: Search bar with custom styling
  static Widget customStyledSearchBar() {
    return CustomSearchBar(
      hintText: 'Find a Babysitter',
      borderRadius: 16,
      borderColor: const Color(0x26FFFFFF),
      focusedBorderColor: const Color(0x99FFFFFF),
      fillColor: const Color(0x1A1E293B),
      hintColor: const Color(0x80FFFFFF),
      textColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
    );
  }

  /// Example 5: Search bar with suffix icon (filter)
  static Widget searchBarWithFilter(VoidCallback onFilterTap) {
    return CustomSearchBar(
      hintText: 'Search Babysitters',
      suffixIconPath: 'assets/filter.svg',
      onSuffixIconTap: onFilterTap,
    );
  }

  /// Example 6: Complete example with all features
  static Widget completeSearchBarExample(
    BuildContext context,
    TextEditingController controller,
    Function(String) onSearchChanged,
    VoidCallback onFilterTap,
  ) {
    return CustomSearchBar(
      hintText: 'Search Babysitters',
      controller: controller,
      onChanged: (value) {
        onSearchChanged(value);
      },
      onTap: () {
        // Handle focus
      },
      borderRadius: 12,
      borderColor: const Color(0x26FFFFFF),
      focusedBorderColor: const Color(0x66FFFFFF),
      fillColor: Colors.transparent,
      hintColor: const Color(0x61FFFFFF),
      textColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      suffixIconPath: 'assets/filter.svg',
      onSuffixIconTap: onFilterTap,
    );
  }
}

/// Example screen showing search bar usage
class SearchBarExampleScreen extends StatefulWidget {
  const SearchBarExampleScreen({super.key});

  @override
  State<SearchBarExampleScreen> createState() => _SearchBarExampleScreenState();
}

class _SearchBarExampleScreenState extends State<SearchBarExampleScreen> {
  late TextEditingController _searchController;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text('Search Bar Examples'),
        backgroundColor: const Color(0xFF1E293B),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Example 1: Basic
            const Text(
              'Example 1: Basic Search Bar',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            SearchBarExamples.basicSearchBar(),
            const SizedBox(height: 32),

            // Example 2: With Controller
            const Text(
              'Example 2: With Controller & Callback',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            SearchBarExamples.searchBarWithController(
              _searchController,
              (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
            if (_searchQuery.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  'Search query: $_searchQuery',
                  style: const TextStyle(color: Colors.white70),
                ),
              ),
            const SizedBox(height: 32),

            // Example 3: Custom Styled
            const Text(
              'Example 3: Custom Styled',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            SearchBarExamples.customStyledSearchBar(),
            const SizedBox(height: 32),

            // Example 4: With Filter
            const Text(
              'Example 4: With Filter Icon',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            SearchBarExamples.searchBarWithFilter(() {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Filter tapped!')),
              );
            }),
            const SizedBox(height: 32),

            // Example 5: Complete
            const Text(
              'Example 5: Complete Example',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            SearchBarExamples.completeSearchBarExample(
              context,
              _searchController,
              (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Filter tapped!')),
                );
              },
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
