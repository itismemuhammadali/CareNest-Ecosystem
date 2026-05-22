# Widgets Directory

This directory contains reusable UI components for the Star Sitter Family app.

## Available Widgets

### CustomSearchBar
A modular, reusable search bar widget with SVG icon support.

**Location:** `search_bar.dart`

**Features:**
- Uses `search.svg` icon from assets
- Fully customizable styling
- Support for text controller and callbacks
- Optional suffix icon (e.g., for filters)
- Built-in focus management

**Quick Start:**
```dart
import 'package:star_sitter_family/widgets/search_bar.dart';

CustomSearchBar(
  hintText: 'Search Babysitters',
)
```

**Documentation:**
- See `SEARCH_BAR_USAGE.md` for complete usage guide
- See `search_bar_examples.dart` for code examples

### Other Widgets
- `bottom_nav_bar.dart` - Bottom navigation bar
- `home_header.dart` - Home screen header
- `primary_button.dart` - Primary action button
- `secondary_button.dart` - Secondary action button
- `custom_text_field.dart` - Custom text input field
- `card_container.dart` - Reusable card container
- `badge.dart` - Badge component
- `info_box.dart` - Information box
- `menu_card.dart` - Menu card component
- `pagination_dots.dart` - Pagination indicator
- `progress_indicator_with_label.dart` - Progress indicator
- `header_container.dart` - Header container
- `header2.dart` - Alternative header
- `hire_header.dart` - Hire screen header
- `app_background.dart` - App background

## Widget Guidelines

### Naming Convention
- Use `Custom` prefix for custom widgets (e.g., `CustomSearchBar`)
- Use descriptive names that indicate the widget's purpose

### Documentation
- Include docstring comments explaining the widget's purpose
- Document all parameters with their types and defaults
- Provide usage examples in the widget's docstring

### Reusability
- Design widgets to be reusable across multiple screens
- Avoid hardcoding values; use parameters instead
- Keep styling customizable through parameters

### Performance
- Use `const` constructors where possible
- Avoid unnecessary rebuilds
- Use `StatefulWidget` only when state management is needed

## Best Practices

1. **Keep it Simple** - Each widget should have a single responsibility
2. **Make it Reusable** - Design for use across multiple screens
3. **Document Well** - Include clear documentation and examples
4. **Test Thoroughly** - Ensure widgets work in various contexts
5. **Follow Conventions** - Maintain consistency with existing widgets

## Adding New Widgets

When creating a new widget:

1. Create a new file with a descriptive name
2. Add comprehensive documentation
3. Include parameter documentation
4. Provide usage examples
5. Test in multiple contexts
6. Update this README

## Dependencies

- `flutter_svg: ^2.0.10` - For SVG rendering (used in CustomSearchBar)

## Related Files

- `SEARCH_BAR_USAGE.md` - Complete CustomSearchBar usage guide
- `search_bar_examples.dart` - CustomSearchBar code examples
- `../SEARCH_BAR_IMPLEMENTATION.md` - Implementation details
