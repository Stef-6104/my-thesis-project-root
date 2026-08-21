import 'dart:io';
import 'package:flutter/material.dart';
import 'package:my_thesis_project/data/models/memory_item.dart';
import 'package:my_thesis_project/presentation/theme/app_theme.dart';

class MemoryItemCard extends StatelessWidget {
  final MemoryItem item;
  final VoidCallback onTap;

  const MemoryItemCard({
    super.key,
    required this.item,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final task = item.todoTask.target;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.darkGray,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.lightYellow, width: 1),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (task != null && task.image.isNotEmpty)
                Image.file(
                  File(task.image),
                  fit: BoxFit.cover,
                )
              else
                const Center(
                  child: Icon(Icons.description, color: AppColors.cascadingWhite, size: 40),
                ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.7),
                    ],
                  ),
                ),
              ),
              Positioned(
                bottom: 12,
                left: 12,
                right: 12,
                child: Text(
                  task?.taskTitle ?? 'Untitled',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.cascadingWhite,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
