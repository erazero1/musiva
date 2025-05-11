import 'package:flutter/material.dart';

class CategorySelector extends StatelessWidget {
  final List<String> categories;
  final String selectedCategory;
  final Function(String) onCategorySelected;

  const CategorySelector({
    super.key,
    required this.categories,
    required this.selectedCategory,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = category == selectedCategory;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              child: TextButton(
                onPressed: () => onCategorySelected(category),
                style: TextButton.styleFrom(
                  backgroundColor: isSelected
                      ? Theme.of(context).primaryColor
                      : Theme.of(context).cardColor.withOpacity(0.9),
                  foregroundColor: isSelected
                      ? Colors.white
                      : Theme.of(context).textTheme.bodyMedium?.color,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: isSelected 
                          ? Colors.white.withOpacity(0.3)
                          : Colors.white.withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                  elevation: isSelected ? 4 : 2,
                  shadowColor: Colors.black.withOpacity(0.3),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                child: Text(category),
              ),
            ),
          );
        },
      ),
    );
  }
}
