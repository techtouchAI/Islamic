import 'package:flutter/material.dart';

class HtmlContentRenderer extends StatefulWidget {
  final String content;
  final TextStyle baseStyle;
  final TextAlign textAlign;

  const HtmlContentRenderer({
    super.key,
    required this.content,
    required this.baseStyle,
    this.textAlign = TextAlign.center,
  });

  @override
  State<HtmlContentRenderer> createState() => _HtmlContentRendererState();
}

class _HtmlContentRendererState extends State<HtmlContentRenderer> {
  late Widget _parsedWidget;

  @override
  void initState() {
    super.initState();
    _parsedWidget = _parseContentRobust(widget.content, widget.baseStyle, widget.textAlign);
  }

  @override
  void didUpdateWidget(HtmlContentRenderer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.content != widget.content ||
        oldWidget.baseStyle != widget.baseStyle ||
        oldWidget.textAlign != widget.textAlign) {
      _parsedWidget = _parseContentRobust(widget.content, widget.baseStyle, widget.textAlign);
    }
  }

  Color? _parseColor(String colorString) {
    try {
      if (colorString.startsWith('#')) {
        return Color(int.parse(colorString.substring(1), radix: 16) + 0xFF000000);
      }
    } catch (_) {}
    return null;
  }

  Widget _parseContentRobust(String content, TextStyle baseStyle, TextAlign textAlign) {
    String processed = content.replaceFirst(RegExp(r'^html\s*', caseSensitive: false), '');

    if (!processed.contains('<')) {
      return Text(
        processed,
        textAlign: textAlign,
        style: baseStyle,
      );
    }

    final List<TextSpan> spans = [];
    final RegExp tagRegex = RegExp(r'(<p>|</p>|<br>|<b>|</b>|<c=(#[a-zA-Z0-9]{6})>|</c>)', caseSensitive: false);

    int lastMatchEnd = 0;
    bool isBold = false;
    Color? currentColor;

    for (final match in tagRegex.allMatches(processed)) {
      if (match.start > lastMatchEnd) {
        spans.add(TextSpan(
          text: processed.substring(lastMatchEnd, match.start),
          style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : baseStyle.fontWeight,
            color: currentColor ?? baseStyle.color,
            fontFamily: baseStyle.fontFamily,
            fontSize: baseStyle.fontSize,
            height: baseStyle.height,
          ),
        ));
      }

      final String tag = match.group(1)!.toLowerCase();
      if (tag == '<p>') {
        // Only add newline if it's not the very beginning
        if (spans.isNotEmpty) spans.add(const TextSpan(text: '\n\n'));
      } else if (tag == '</p>') {
        // Do nothing for </p> to avoid excessive newlines
      } else if (tag == '<br>') {
        spans.add(const TextSpan(text: '\n'));
      } else if (tag == '<b>') {
        isBold = true;
      } else if (tag == '</b>') {
        isBold = false;
      } else if (tag.startsWith('<c=')) {
        currentColor = _parseColor(match.group(2)!);
      } else if (tag == '</c>') {
        currentColor = null;
      }

      lastMatchEnd = match.end;
    }

    if (lastMatchEnd < processed.length) {
      spans.add(TextSpan(
        text: processed.substring(lastMatchEnd),
        style: TextStyle(
          fontWeight: isBold ? FontWeight.bold : baseStyle.fontWeight,
          color: currentColor ?? baseStyle.color,
          fontFamily: baseStyle.fontFamily,
          fontSize: baseStyle.fontSize,
          height: baseStyle.height,
        ),
      ));
    }

    return RichText(
      textAlign: textAlign,
      textDirection: TextDirection.rtl,
      text: TextSpan(
        style: baseStyle,
        children: spans,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _parsedWidget;
  }
}
