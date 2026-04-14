import 'package:flutter/material.dart';

class ChapterSelector extends StatelessWidget {
  const ChapterSelector({
    super.key,
    required this.chapterCount,
    required this.currentChapter,
    required this.onChapterSelected,
  });

  final int chapterCount;
  final int currentChapter;
  final ValueChanged<int> onChapterSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemCount: chapterCount,
        itemBuilder: (context, index) {
          final chapter = index + 1;
          final isSelected = chapter == currentChapter;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: ChoiceChip(
              label: Text('$chapter'),
              selected: isSelected,
              onSelected: (_) => onChapterSelected(chapter),
              padding: EdgeInsets.zero,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          );
        },
      ),
    );
  }
}
