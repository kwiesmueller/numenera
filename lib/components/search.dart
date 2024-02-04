import 'package:cypher_sheet/components/text.dart';
import 'package:flutter/material.dart';

class AppSearchBar extends StatelessWidget {
  const AppSearchBar({super.key, required this.onSearch});

  final Function(String) onSearch;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: AppTextEdit(
        value: "",
        showCursor: true,
        startFocused: true,
        textAlign: TextAlign.left,
        customPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        onEditingComplete: onSearch,
      ),
    );
  }
}
