import 'package:flutter/material.dart';

class HierarchicalSection {
  final String title;
  final List<String> items;

  const HierarchicalSection({required this.title, required this.items});
}

class HierarchicalList extends StatelessWidget {
  final List<HierarchicalSection> sections;
  final String? selectedItem;
  final ValueChanged<String>? onItemSelected;

  const HierarchicalList({
    super.key,
    required this.sections,
    this.selectedItem,
    this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        for (final section in sections) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 14, 12, 4),
            child: Text(
              section.title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ),
          for (final item in section.items)
            InkWell(
              onTap: () => onItemSelected?.call(item),
              child: Container(
                color: selectedItem == item ? Colors.grey.shade300 : null,
                padding: const EdgeInsets.fromLTRB(28, 9, 12, 9),
                child: Text(item, style: const TextStyle(fontSize: 14)),
              ),
            ),
        ],
      ],
    );
  }
}
