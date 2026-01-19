import 'package:flutter/material.dart';

class HighlightTextController extends TextEditingController {
  List<Map<String, String>> matchedAllergies;

  HighlightTextController({
    required this.matchedAllergies,
    required String text,
  }) : super(text: text);

  @override
  TextSpan buildTextSpan({required BuildContext context, TextStyle? style, bool? withComposing}) {
    List<InlineSpan> children = [];
    String lowerFullText = text.toLowerCase();

    int currentIndex = 0;

    List<List<int>> matchIndices = [];

    for (final allergy in matchedAllergies) {
      currentIndex = 0;
      final synonym = allergy['synonym']!.toLowerCase();
      int matchIndex = lowerFullText.indexOf(synonym, currentIndex);

      while (matchIndex != -1) {
        matchIndices.add([matchIndex, matchIndex + synonym.length]);

        currentIndex = matchIndex + synonym.length;
        matchIndex = lowerFullText.indexOf(synonym, currentIndex);
      }
    }

    // Sort and merge overlapping indices
    matchIndices.sort((a, b) => a[0].compareTo(b[0]));

    List<List<int>> mergedIndices = [];
    for (final indices in matchIndices) {
      if (mergedIndices.isEmpty || mergedIndices.last[1] < indices[0]) {
        mergedIndices.add(indices);
      } else {
        mergedIndices.last[1] = indices[1];
      }
    }

    currentIndex = 0;
    for (final indices in mergedIndices) {
      if (indices[0] > currentIndex) {
        children.add(TextSpan(
          text: text.substring(currentIndex, indices[0]),
          style: style,
        ));
      }

      children.add(TextSpan(
        text: text.substring(indices[0], indices[1]),
        style: style?.copyWith(
          decoration: TextDecoration.underline,
          decorationColor: Colors.red,
          decorationThickness: 3,
        ),
      ));

      currentIndex = indices[1];
    }

    if (currentIndex < text.length) {
      children.add(TextSpan(
        text: text.substring(currentIndex),
        style: style,
      ));
    }

    return TextSpan(style: style, children: children);
  }

}