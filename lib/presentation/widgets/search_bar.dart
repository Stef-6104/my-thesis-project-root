import 'package:flutter/material.dart';
import 'package:my_thesis_project/presentation/theme/app_theme.dart';

class CustomSearchBar extends StatelessWidget {
  final Function(String)? onChanged;
  const CustomSearchBar({super.key, this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.lightYellow,
        borderRadius: BorderRadius.circular(30),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: TextField(
        onChanged: onChanged,
        style: const TextStyle(color: Colors.black),
        decoration: const InputDecoration(
          hintText: 'Search...',
          hintStyle: TextStyle(color: Colors.black54),
          border: InputBorder.none,
          suffixIcon: Icon(Icons.search, color: Colors.black),
        ),
      ),
    );
  }
}
