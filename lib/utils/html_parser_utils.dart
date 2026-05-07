import 'package:flutter/material.dart';

extension HtmlParserExt on String {
  String stripHtmlTags() {
    String processed = replaceFirst(RegExp(r'^html\s*', caseSensitive: false), '');
    return processed.replaceAll(RegExp(r'<[^>]*>'), '');
  }

  String extractColoredWords() {
    String processed = replaceFirst(RegExp(r'^html\s*', caseSensitive: false), '');
    final RegExp colorTagRegex = RegExp(r'<c=(#[a-zA-Z0-9]{6})>(.*?)</c>', caseSensitive: false);
    List<String> coloredWords = [];
    for (final match in colorTagRegex.allMatches(processed)) {
      coloredWords.add(match.group(2)!.trim());
    }
    return coloredWords.join(' ');
  }
}
