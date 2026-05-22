# CustomSearchBar Widget - Usage Guide

## Overview
The `CustomSearchBar` is a reusable, modular search bar widget that uses the `search.svg` icon from assets. It's designed to be flexible and customizable for various use cases throughout the app.

## Features
- ✅ SVG search icon (search.svg from assets)
- ✅ Customizable hint text
- ✅ Optional text controller for programmatic access
- ✅ Callbacks for text changes and tap events
- ✅ Customizable styling (colors, border radius, padding)
- ✅ Focus management
- ✅ Optional suffix icon support
- ✅ Fully reusable across the app

## Basic Usage

### Simple Search Bar (Default Styling)
```dart
import 'package:star_sitter_family/widgets/search_bar.dart';

CustomSearchBar(
  hintText: 'Search Babysitters',
)
```

### With Text Controller
```dart
final TextEditingController _searchController = TextEditingController();

CustomSearchBar(
  hintText: 'Search Babysitters',
  controller: _searchController,
  onChanged: (value) {
    print('Search query: $value');
  },
)
```

### With Tap Callback
```dart
CustomSearchBar(
  hintText: 'Search Babysitters',
  onTap: () {
    // Navigate to search results screen
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => SearchResultsScreen(),
    ));
  },
)
```

## Advanced Customization

### Custom Colors and Styling
```dart
CustomSearchBar(
  hintText: 'Search',
  borderRadius: 16,
  borderColor: Color(0x26FFFFFF),
  focusedBorderColor: Color(0x66FFFFFF),
  fillColor: Colors.transparent,
  hintColor: Color(0x61FFFFFF),
  textColor: Colors.white,
  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
)
```

### With Suffix Icon
```dart
CustomSearchBar(
  hintText: 'Search',
  suffixIconPath: 'assests/filter.svg', // Add your filter icon
  onSuffixIconTap: () {
    // Handle filter button tap
    print('Filter tapped');
  },
)
```

### Complete Example with All Features
```dart
final TextEditingController _searchController = TextEditingController();

CustomSearchBar(
  hintText: 'Search Babysitters',
  controller: _searchController,
  onChanged: (value) {
    setState(() {
      // Update search results
    });
  },
  onTap: () {
    // Handle search bar focus
  },
  borderRadius: 12,
  borderColor: Color(0x26FFFFFF),
  focusedBorderColor: Color(0x66FFFFFF),
  fillColor: Colors.transparent,
  hintColor: Color(0x61FFFFFF),
  textColor: Colors.white,
  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  suffixIconPath: 'assests/filter.svg',
  onSuffixIconTap: () {
    // Show filter options
  },
)
```

## Integration in Home Screen

The search bar is already integrated in the home screen:

```dart
// In home_screen.dart
import 'package:star_sitter_family/widgets/search_bar.dart' as search_bar;

// Inside the build method
search_bar.CustomSearchBar(
  hintText: 'Search Babysitters',
)
```

## Customization Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `hintText` | String | 'Search' | Placeholder text |
| `controller` | TextEditingController? | null | Optional text controller |
| `onChanged` | ValueChanged<String>? | null | Callback when text changes |
| `onTap` | VoidCallback? | null | Callback when search bar is tapped |
| `borderRadius` | double | 12 | Border radius in pixels |
| `borderColor` | Color | Color(0x26FFFFFF) | Border color when not focused |
| `focusedBorderColor` | Color | Color(0x66FFFFFF) | Border color when focused |
| `fillColor` | Color | Colors.transparent | Background fill color |
| `hintColor` | Color | Color(0x61FFFFFF) | Hint text color |
| `textColor` | Color | Colors.white | Input text color |
| `contentPadding` | EdgeInsets | EdgeInsets.symmetric(horizontal: 16, vertical: 12) | Internal padding |
| `suffixIconPath` | String? | null | Optional suffix icon SVG path |
| `onSuffixIconTap` | VoidCallback? | null | Callback for suffix icon tap |

## Best Practices

1. **Reuse the widget** - Use this widget consistently across all search interfaces
2. **Provide meaningful hints** - Use context-specific hint text (e.g., "Search Babysitters", "Search Jobs")
3. **Handle callbacks** - Implement `onChanged` for real-time search or `onTap` for navigation
4. **Maintain consistency** - Keep the default styling unless there's a specific design requirement
5. **Use controllers** - Use TextEditingController when you need programmatic access to the search text

## Dependencies

- `flutter_svg: ^2.0.10` - For SVG icon rendering
- `assests/search.svg` - Search icon asset (already included)

## Notes

- The search icon is automatically colored to match the hint text color
- The widget manages its own FocusNode internally
- The SVG icon is rendered with proper color filtering for consistency
- All styling parameters have sensible defaults matching the app's design system
