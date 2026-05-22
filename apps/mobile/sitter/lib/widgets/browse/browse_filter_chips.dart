import 'package:flutter/material.dart';

class BrowseFilterChips extends StatelessWidget {
  final String activeFilter;
  final ValueChanged<String> onFilterChanged;

  const BrowseFilterChips({
    super.key,
    required this.activeFilter,
    required this.onFilterChanged,
  });

  static const List<String> filters = ['All Jobs', 'Nearby', 'Today', 'Weekend'];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(filters.length, (index) {
          final bool isSelected = activeFilter == filters[index];
          return Padding(
            padding: EdgeInsets.only(right: index < filters.length - 1 ? 8 : 0),
            child: GestureDetector(
              onTap: () => onFilterChanged(filters[index]),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFFA8D8EA)
                      : const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFFA8D8EA)
                        : const Color(0xFF1E293B),
                    width: 1,
                  ),
                ),
                child: Text(
                  filters[index],
                  style: TextStyle(
                    fontSize: 13,
                    color: isSelected
                        ? const Color(0xFF1E293B)
                        : const Color(0xB2A8D8EA),
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
